--!strict
-- Simulator systems: pets/eggs, auras, upgrades, rebirth, offline gains, daily/playtime/milestone rewards, codes,
-- leaderboards, game passes + developer products. Every action is validated here; the client only asks.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local SC = require(ReplicatedStorage.Shared.SystemsConfig)
local DataService = require(script.Parent.DataService)
local GameService = require(script.Parent.GameService)

local SystemsService = {}
local R = GameService.Remotes
local sessionStart: {[Player]: number} = {}
local playtimeClaimed: {[Player]: {[number]: boolean}} = {}
local ownedPasses: {[Player]: {[string]: boolean}} = {}
local freeAutoUntil: {[Player]: number} = {}
local freeAutoReady: {[Player]: number} = {}
local giftReady: {[Player]: {[string]: number}} = {} -- Free Gifts: session timers (absolute os.time)
local dailyNextDayRef: (any, number) -> number = function() return 1 end -- set below (the snapshot hook is defined first)
local giftDayRef: () -> number = function() return 0 end

---------------------------------------------------------------- multipliers
local function petMultiplier(data: any): number
	local sum = 0
	for _, uid in data.EquippedPets do
		local rec = data.Pets[uid]
		local def = rec and SC.Pets[rec.Pet]
		if def then
			local tier = rec.Tier and SC.FuseTiers[rec.Tier]
			sum += def.Boost * (tier and tier.Mult or 1)
		end
	end
	return 1 + sum * (1 + 0.1 * GameService.UpgradeLevel(data, "PetBoost"))
end
SystemsService.PetMultiplier = petMultiplier

local function hasPass(p: Player, key: string): boolean
	local t = ownedPasses[p]
	return t ~= nil and t[key] == true
end

GameService.MultiplierProviders.Pets = function(_p, data) return petMultiplier(data) end
GameService.MultiplierProviders.Aura = function(_p, data)
	local a = SC.Auras[data.EquippedAura]
	return (a and data.Auras[a.Id]) and a.Mult or 1
end
GameService.MultiplierProviders.Passes = function(p, data)
	local m = 1
	if hasPass(p, "DoubleSigns") then m *= 2 end
	if hasPass(p, "VIP") then m *= 1.25 end
	if (data.BoostUntil or 0) > os.time() then m *= 2 end
	return m
end
SystemsService.HasPass = hasPass
GameService.HasPass = hasPass
GameService.TrophyBonus = function(p, data, excludeDoublePass)
	local m = 1
	if (data and data.TrophyBoostUntil or 0) > os.time() then m *= 2 end
	if hasPass(p, "DoubleTrophies") and not excludeDoublePass then m *= 2 end -- win pads apply it via the x2 pad instead
	if hasPass(p, "VIP") then m *= 1.25 end
	return m
end

local function petSlots(p: Player, data: any): number
	return SC.BasePetSlots + GameService.UpgradeLevel(data, "PetSlots") + (hasPass(p, "ExtraPets") and 3 or 0)
end

---------------------------------------------------------------- replication for visuals (other clients render pets/auras)
local function publishLooks(p: Player, data: any)
	local shown = {}
	for _, uid in data.EquippedPets do
		local rec = data.Pets[uid]
		if rec then table.insert(shown, rec.Pet) end
	end
	p:SetAttribute("PetsShown", table.concat(shown, ","))
	p:SetAttribute("Aura", (data.Auras[data.EquippedAura] and data.EquippedAura) or "")
	p:SetAttribute("KyubiCoins", data.KyubiCoins or 0)
end
SystemsService.Changed = function(p) local d = DataService.Get(p); if d then publishLooks(p, d) end; GameService.Refresh(p) end

GameService.SnapshotExtras[#GameService.SnapshotExtras + 1] = function(p, data, snap)
	snap.PetSlots = petSlots(p, data)
	snap.PetMult = petMultiplier(data)
	snap.PendingOffline = data.PendingOffline
	snap.BoostUntil = data.BoostUntil
	snap.ClaimedMilestones = data.ClaimedMilestones
	local pt = {}
	for k, v in playtimeClaimed[p] or {} do pt[tostring(k)] = v end
	snap.Playtime = pt
	snap.SessionStart = sessionStart[p] and (os.time() - math.floor(os.clock() - sessionStart[p])) or os.time()
	snap.Passes = ownedPasses[p] or {}
	snap.RedeemedCodes = data.RedeemedCodes
	snap.RebirthCost = SC.RebirthCost(data.Rebirths)
	snap.FreeAutoUntil = freeAutoUntil[p] or 0
	snap.FreeAutoReady = freeAutoReady[p] or 0
	snap.KyubiCoins = data.KyubiCoins or 0
	snap.TrophyBoostUntil = data.TrophyBoostUntil or 0
	snap.DailyNextDay = dailyNextDayRef(data, os.time())
	snap.GiftReady = giftReady[p] or {}
	snap.GiftCounts = (data.GiftDay == giftDayRef()) and data.GiftCounts or {}
end

local function changed(p: Player)
	local data = DataService.Get(p)
	if data then publishLooks(p, data) end
	GameService.Refresh(p)
end

local function spend(data: any, amount: number): boolean
	if amount ~= amount or amount < 0 or data.Trophies < amount then return false end
	data.Trophies -= amount
	return true
end

local function countPets(data: any): number
	local n = 0
	for _ in data.Pets do n += 1 end
	return n
end

---------------------------------------------------------------- actions
local A: {[string]: (Player, any, any) -> any} = {}

-- give a pet record (purchases / rewards may exceed the inventory cap; trophy hatching checks it first)
local function grantPet(p: Player, data: any, petId: string): string
	local uid = "p" .. data.NextPetId
	data.NextPetId += 1
	data.Pets[uid] = {Pet = petId, Locked = false}
	if #data.EquippedPets < petSlots(p, data) then table.insert(data.EquippedPets, uid) end
	return uid
end
-- server-side roll with the same odds the UI shows
local function rollEgg(egg: any): string
	local roll = Random.new():NextNumber() * 100
	local acc, chosen = 0, egg.Odds[#egg.Odds].Pet
	for _, row in egg.Odds do
		acc += row.Chance
		if roll <= acc then chosen = row.Pet; break end
	end
	return chosen
end
local function freeHatch(p: Player, data: any, eggId: string, count: number): {string}
	local egg = SC.Eggs[eggId]
	local got = {}
	if not egg then return got end
	for _ = 1, count do
		local petId = rollEgg(egg)
		grantPet(p, data, petId)
		table.insert(got, petId)
		GameService.Notify(p, "Hatched", {Egg = eggId, Pet = petId})
	end
	return got
end

function A.Hatch(p, data, eggId)
	local egg = typeof(eggId) == "string" and SC.Eggs[eggId]
	if not egg then return {ok = false, msg = "Unknown egg"} end
	if egg.Robux then -- Robux egg: one hatch per developer-product purchase (granted in ProcessReceipt)
		local dp = SC.DevProducts[egg.Product]
		if not dp or dp.Id == 0 then return {ok = false, msg = egg.Name .. ": not available yet"} end
		MarketplaceService:PromptProductPurchase(p, dp.Id)
		return {ok = true, prompted = true}
	end
	if data.HighestUnlockedStage < egg.Stage then return {ok = false, msg = "Reach Stage " .. egg.Stage .. " first"} end
	if countPets(data) >= SC.MaxPetsOwned then return {ok = false, msg = "Pet inventory full - delete some pets"} end
	if not spend(data, egg.Cost) then return {ok = false, msg = "Not enough Trophies"} end
	local chosen = rollEgg(egg)
	local uid = grantPet(p, data, chosen)
	changed(p)
	return {ok = true, pet = chosen, uid = uid}
end

function A.EquipPet(p, data, uid)
	if typeof(uid) ~= "string" or not data.Pets[uid] then return {ok = false} end
	local i = table.find(data.EquippedPets, uid)
	if i then
		table.remove(data.EquippedPets, i)
	else
		if #data.EquippedPets >= petSlots(p, data) then return {ok = false, msg = "All pet slots are full"} end
		table.insert(data.EquippedPets, uid)
	end
	changed(p)
	return {ok = true}
end

function A.EquipBest(p, data)
	local list = {}
	for uid, rec in data.Pets do if SC.Pets[rec.Pet] then table.insert(list, uid) end end
	table.sort(list, function(a, b) return SC.Pets[data.Pets[a].Pet].Boost > SC.Pets[data.Pets[b].Pet].Boost end)
	data.EquippedPets = {}
	for i = 1, math.min(#list, petSlots(p, data)) do table.insert(data.EquippedPets, list[i]) end
	changed(p)
	return {ok = true}
end

function A.LockPet(p, data, uid)
	local rec = typeof(uid) == "string" and data.Pets[uid]
	if not rec then return {ok = false} end
	rec.Locked = not rec.Locked
	changed(p)
	return {ok = true}
end

function A.DeletePet(p, data, uid)
	local rec = typeof(uid) == "string" and data.Pets[uid]
	if not rec then return {ok = false} end
	if rec.Locked then return {ok = false, msg = "Unlock the pet first"} end
	local i = table.find(data.EquippedPets, uid)
	if i then table.remove(data.EquippedPets, i) end
	data.Pets[uid] = nil
	changed(p)
	return {ok = true}
end

-- showcase / menu: buy a hand sign with Trophies ONLY (owner 2026-11-02: no stage / hand-sign requirement), then equip it
function A.BuySign(p, data, id)
	local s = typeof(id) == "string" and Config.HandSigns[id]
	if not s then return {ok = false} end
	if data.UnlockedHandSigns[id] then return {ok = true, owned = true} end
	if not spend(data, s.Price) then return {ok = false, msg = "Need " .. Config.Format(s.Price) .. " Trophies"} end
	data.UnlockedHandSigns[id] = true
	data.EquippedHandSign = id
	GameService.Notify(p, "SignUnlocked", id)
	for _, cb in GameService.OnEquipChanged do task.spawn(cb, p, id) end
	changed(p)
	DataService.SaveNow(p)
	return {ok = true, bought = true}
end

-- boss shop (Kyubi Coins from the lobby raid)
function A.BossShop(p, data, id)
	local item
	for _, it in SC.BossShop do if it.Id == id then item = it end end
	if not item then return {ok = false} end
	if (data.KyubiCoins or 0) < item.Cost then return {ok = false, msg = "Need " .. item.Cost .. " Kyubi Coins"} end
	if item.Aura and data.Auras[item.Aura] then return {ok = false, msg = "Already owned"} end
	if item.Pet and countPets(data) >= SC.MaxPetsOwned then return {ok = false, msg = "Pet inventory full"} end
	data.KyubiCoins -= item.Cost
	if item.Pet then
		local uid = "p" .. data.NextPetId
		data.NextPetId += 1
		data.Pets[uid] = {Pet = item.Pet, Locked = false}
		if #data.EquippedPets < petSlots(p, data) then table.insert(data.EquippedPets, uid) end
	elseif item.Aura then
		data.Auras[item.Aura] = true
		data.EquippedAura = item.Aura
	elseif item.Boost then
		data.BoostUntil = math.max(os.time(), data.BoostUntil or 0) + item.Boost
	elseif item.TrophyBoost then
		data.TrophyBoostUntil = math.max(os.time(), data.TrophyBoostUntil or 0) + item.TrophyBoost
	end
	changed(p)
	return {ok = true, item = item.Id}
end

-- fuse machine: FuseCount copies of the same pet + tier -> one pet of the next tier
function A.Fuse(p, data, petId, tier)
	if typeof(petId) ~= "string" or not SC.Pets[petId] then return {ok = false} end
	tier = typeof(tier) == "number" and math.floor(tier) or 0
	if tier < 0 or tier >= #SC.FuseTiers then return {ok = false, msg = "Max tier"} end
	local picks = {}
	for uid, rec in data.Pets do
		if rec.Pet == petId and (rec.Tier or 0) == tier and not rec.Locked then table.insert(picks, uid) end
		if #picks >= SC.FuseCount then break end
	end
	if #picks < SC.FuseCount then return {ok = false, msg = "Need " .. SC.FuseCount .. " unlocked copies"} end
	for _, uid in picks do
		data.Pets[uid] = nil
		local i = table.find(data.EquippedPets, uid)
		if i then table.remove(data.EquippedPets, i) end
	end
	local uid = "p" .. data.NextPetId
	data.NextPetId += 1
	data.Pets[uid] = {Pet = petId, Locked = false, Tier = tier + 1}
	if #data.EquippedPets < petSlots(p, data) then table.insert(data.EquippedPets, uid) end
	changed(p)
	return {ok = true, uid = uid, tier = tier + 1}
end

function A.BuyAura(p, data, id)
	local a = typeof(id) == "string" and SC.Auras[id]
	if not a then return {ok = false} end
	if SC.ShopOnlyAuras[id] and not data.Auras[id] then return {ok = false, msg = "Buy it in the Boss Shop"} end
	if data.Auras[id] then -- already owned: toggle equip
		data.EquippedAura = data.EquippedAura == id and "" or id
		changed(p)
		return {ok = true}
	end
	if data.HighestUnlockedStage < a.Stage then return {ok = false, msg = "Reach Stage " .. a.Stage .. " first"} end
	if not spend(data, a.Cost) then return {ok = false, msg = "Not enough Trophies"} end
	data.Auras[id] = true
	data.EquippedAura = id
	changed(p)
	return {ok = true, bought = true}
end

function A.BuyUpgrade(p, data, id)
	local u = typeof(id) == "string" and SC.Upgrades[id]
	if not u then return {ok = false} end
	local lvl = data.Upgrades[id] or 0
	if lvl >= u.Max then return {ok = false, msg = "Maxed"} end
	if not spend(data, SC.UpgradeCost(id, lvl)) then return {ok = false, msg = "Not enough Trophies"} end
	data.Upgrades[id] = lvl + 1
	changed(p)
	return {ok = true}
end

function A.Rebirth(p, data)
	local cost = SC.RebirthCost(data.Rebirths)
	if data.HandSigns < cost then return {ok = false, msg = "Need " .. Config.Format(cost) .. " Hand Signs"} end
	data.HandSigns = 0 -- only Hand Signs reset (see SystemsConfig.RebirthResets)
	data.Rebirths += 1
	GameService.Notify(p, "Rebirth", data.Rebirths)
	changed(p)
	DataService.SaveNow(p)
	return {ok = true}
end

function A.ClaimOffline(p, data)
	local amt = data.PendingOffline or 0
	if amt <= 0 then return {ok = false} end
	data.PendingOffline = 0
	GameService.AddHandSigns(p, amt)
	return {ok = true, amount = amt}
end

-- one reward row (Daily week / Free Gifts) -> grants it, returns a short description for the toast
local function grantReward(p: Player, data: any, row: any): string
	local st = Config.Stages[data.HighestUnlockedStage] or Config.Stages[1]
	if row.Kind == "Trophies" then
		local amt = math.max(5, math.floor(st.Trophies * row.Mult))
		GameService.AddTrophies(p, amt)
		return "+" .. Config.Format(amt) .. " Trophies"
	elseif row.Kind == "Boost" then
		data.BoostUntil = math.max(os.time(), data.BoostUntil or 0) + row.Minutes * 60
		return "x2 Hand Signs " .. row.Minutes .. "m"
	elseif row.Kind == "TrophyBoost" then
		data.TrophyBoostUntil = math.max(os.time(), data.TrophyBoostUntil or 0) + row.Minutes * 60
		return "x2 Trophies " .. row.Minutes .. "m"
	elseif row.Kind == "Hatch" then
		freeHatch(p, data, row.Egg, row.Count or 1)
		return "x" .. (row.Count or 1) .. " " .. SC.Eggs[row.Egg].Name
	elseif row.Kind == "Aura" then
		if data.Auras[row.Aura] then return grantReward(p, data, {Kind = "Trophies", Mult = row.Mult or 20}) end
		data.Auras[row.Aura] = true
		return SC.Auras[row.Aura].Name
	elseif row.Kind == "Pet" then
		grantPet(p, data, row.Pet)
		return SC.Pets[row.Pet].Name
	end
	return ""
end

-- DAILY REWARDS: a 7-day week. DailyStreak counts claims in the current chain (day = ((streak - 1) % 7) + 1);
-- one claim per cooldown; missing 48h starts the chain again at Day 1.
local function dailyNextDay(data: any, now: number): number
	if (data.LastDaily or 0) <= 0 or now - data.LastDaily > SC.DailyStreakReset then return 1 end
	return (data.DailyStreak % 7) + 1
end
dailyNextDayRef = dailyNextDay
function A.ClaimDaily(p, data)
	local now = os.time()
	if now - data.LastDaily < SC.DailyCooldown then return {ok = false, msg = "Come back later"} end
	local reset = (data.LastDaily or 0) <= 0 or now - data.LastDaily > SC.DailyStreakReset
	data.DailyStreak = reset and 1 or data.DailyStreak + 1
	local day = ((data.DailyStreak - 1) % 7) + 1
	data.LastDaily = now
	local what = grantReward(p, data, SC.DailyWeek[day])
	changed(p)
	return {ok = true, day = day, what = what}
end

-- FREE GIFTS: three timers (5 / 15 / 60 min of play), each with a daily cap; the prize is rolled on the server
local function giftDayKey(): number local t = os.date("!*t") return t.year * 10000 + t.month * 100 + t.day end
giftDayRef = giftDayKey
local function giftCounts(data: any): {[string]: number}
	local today = giftDayKey()
	if data.GiftDay ~= today then data.GiftDay = today; data.GiftCounts = {} end
	return data.GiftCounts
end
function A.ClaimGift(p, data, giftId)
	local g
	for _, row in SC.Gifts do if row.Id == giftId then g = row end end
	if not g then return {ok = false} end
	local counts = giftCounts(data)
	if (counts[g.Id] or 0) >= g.PerDay then return {ok = false, msg = "No " .. g.Title .. " gifts left today"} end
	local timers = giftReady[p]
	if not timers or os.time() < (timers[g.Id] or math.huge) then return {ok = false, msg = "Not ready yet"} end
	counts[g.Id] = (counts[g.Id] or 0) + 1
	timers[g.Id] = os.time() + g.Minutes * 60
	local roll, acc, pick = Random.new():NextNumber() * 100, 0, g.Pool[#g.Pool]
	for _, row in g.Pool do acc += row.Chance; if roll <= acc then pick = row; break end end
	local what = grantReward(p, data, pick)
	changed(p)
	return {ok = true, what = what}
end

function A.ClaimPlaytime(p, data, idx)
	local row = typeof(idx) == "number" and SC.PlaytimeRewards[idx]
	if not row then return {ok = false} end
	local claimed = playtimeClaimed[p] or {}
	playtimeClaimed[p] = claimed
	if claimed[idx] then return {ok = false} end
	if (os.clock() - (sessionStart[p] or os.clock())) < row.Minutes * 60 then return {ok = false, msg = "Not yet"} end
	claimed[idx] = true
	local amt = Config.Stages[data.HighestUnlockedStage].Trophies * row.Mult
	GameService.AddTrophies(p, amt)
	changed(p)
	return {ok = true, amount = amt}
end

function A.ClaimMilestone(p, data, stage)
	if typeof(stage) ~= "number" or not table.find(SC.MilestoneStages, stage) then return {ok = false} end
	local key = tostring(stage)
	if data.ClaimedMilestones[key] or not data.CompletedStages[key] then return {ok = false} end
	data.ClaimedMilestones[key] = true
	local amt = Config.Stages[stage].Trophies * 50
	GameService.AddTrophies(p, amt)
	changed(p)
	return {ok = true, amount = amt}
end

function A.Redeem(p, data, code)
	if typeof(code) ~= "string" or #code > 30 then return {ok = false, msg = "Invalid code"} end
	code = string.upper(code:gsub("%s", ""))
	local c = SC.Codes[code]
	if not c then return {ok = false, msg = "Invalid code"} end
	if c.Expires > 0 and os.time() > c.Expires then return {ok = false, msg = "Code expired"} end
	if data.RedeemedCodes[code] then return {ok = false, msg = "Already redeemed"} end
	data.RedeemedCodes[code] = true
	GameService.AddTrophies(p, c.Trophies)
	changed(p)
	return {ok = true, amount = c.Trophies}
end

local SETTINGS = {ReduceEffects = true, Music = true, AutoTrain = true, HideOtherPets = true, Sfx = true} -- booleans only
function A.Setting(p, data, key, value)
	if typeof(key) ~= "string" or not SETTINGS[key] or typeof(value) ~= "boolean" then return {ok = false} end
	data.Settings[key] = value
	changed(p)
	return {ok = true}
end

function A.FreeAuto(p, _data)
	local now = os.time()
	if now < (freeAutoReady[p] or 0) then return {ok = false, msg = "Free Auto Clicker recharging"} end
	freeAutoUntil[p] = now + SC.FreeAuto.ActiveSeconds
	freeAutoReady[p] = now + SC.FreeAuto.ActiveSeconds + SC.FreeAuto.CooldownSeconds
	changed(p)
	return {ok = true}
end

-- "DON'T LEAVE YET!" popup: x2 Hand Signs (15 min) + 3 levels, once per 20h
function A.ClaimStayBonus(p, data)
	local now = os.time()
	if now - (data.LastLeaveBonus or 0) < 20 * 3600 then return {ok = false, msg = "Already claimed today"} end
	data.LastLeaveBonus = now
	data.BoostUntil = math.max(now, data.BoostUntil or 0) + 15 * 60
	for _ = 1, 3 do GameService.AddXP(p, Config.XPForLevel(data.Level) - data.XP) end
	changed(p)
	return {ok = true}
end

function A.Leaderboards()
	return {ok = true, boards = SystemsService.Boards}
end

-- "Collect your wins" popup buttons: identical to touching the stage's win pad (pending reward is server-side;
-- the player must be standing in that stage)
function A.ClaimWins(p, _data, stage, double)
	if typeof(stage) ~= "number" then return {ok = false} end
	stage = math.floor(stage)
	if p:GetAttribute("InStage") ~= stage or p:GetAttribute("InLobby") then return {ok = false, msg = "Collect your wins in the stage"} end
	local ok = if double == true then GameService.ClaimPadX2(p, stage) else GameService.ClaimPad(p, stage)
	return {ok = ok}
end

function A.BuyPass(p, _data, key)
	local gp = typeof(key) == "string" and SC.GamePasses[key]
	if not gp or gp.Id == 0 then return {ok = false, msg = "Not available yet"} end
	MarketplaceService:PromptGamePassPurchase(p, gp.Id)
	return {ok = true}
end

function A.BuyProduct(p, _data, key)
	local dp = typeof(key) == "string" and SC.DevProducts[key]
	if not dp or dp.Id == 0 then return {ok = false, msg = "Not available yet"} end
	MarketplaceService:PromptProductPurchase(p, dp.Id)
	return {ok = true}
end

R.Action.OnServerInvoke = function(p: Player, kind: any, a1: any, a2: any)
	if not GameService.RateOk(p, "action", 6) then return {ok = false, msg = "Slow down"} end
	if typeof(kind) ~= "string" then return {ok = false} end
	local f = A[kind]
	local data = DataService.Get(p)
	if not f or not data then return {ok = false} end
	if kind ~= "Leaderboards" and not DataService.CanMutate(p) then return {ok = false, msg = "Data not ready"} end
	local ok, res = pcall(f, p, data, a1, a2)
	if not ok then warn("[SystemsService]", kind, res); return {ok = false} end
	return res
end

---------------------------------------------------------------- offline gains (server clock only)
local function computeOffline(p: Player, data: any)
	if (data.LastSeen or 0) <= 0 then return end
	local away = os.time() - data.LastSeen
	if away < 120 then return end
	local maxSec = (SC.OfflineBaseMaxHours + GameService.UpgradeLevel(data, "Offline")) * 3600
	local secs = math.min(away, maxSec)
	local gain = GameService.TrainGain(p, data) * SC.OfflineTrainsPerSecond * secs * (1 + 0.25 * GameService.UpgradeLevel(data, "Offline"))
	if gain >= 1 then
		data.PendingOffline = math.floor(gain)
		data.LastSeen = os.time() -- consumed: a rejoin cannot claim the same window twice
		GameService.Notify(p, "Offline", {Amount = data.PendingOffline, Seconds = secs})
	end
end

---------------------------------------------------------------- passes + receipts
local function refreshPasses(p: Player)
	local t = {}
	for key, gp in SC.GamePasses do
		if gp.Id ~= 0 then
			local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, p.UserId, gp.Id)
			if ok and owns then t[key] = true end
		end
	end
	ownedPasses[p] = t
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(p, id, bought)
	if bought then refreshPasses(p); changed(p) end
end)

local productHandlers: {[number]: (Player, any) -> ()} = {}
for key, dp in SC.DevProducts do
	if dp.Id ~= 0 and key == "Boost15" then
		productHandlers[dp.Id] = function(_p, data)
			data.BoostUntil = math.max(os.time(), data.BoostUntil or 0) + 15 * 60
		end
	elseif dp.Id ~= 0 and (dp :: any).Egg then
		productHandlers[dp.Id] = function(p, data) freeHatch(p, data, (dp :: any).Egg, 1) end
	elseif dp.Id ~= 0 and (dp :: any).Pet then
		productHandlers[dp.Id] = function(p, data)
			grantPet(p, data, (dp :: any).Pet)
			GameService.Notify(p, "Hatched", {Pet = (dp :: any).Pet})
		end
	elseif dp.Id ~= 0 and (dp :: any).UnlockDaily then
		productHandlers[dp.Id] = function(p, data) -- claim every remaining day of this week at once
			local day = dailyNextDay(data, os.time())
			for d = day, 7 do grantReward(p, data, SC.DailyWeek[d]); data.DailyStreak += 1 end
			data.LastDaily = os.time()
		end
	elseif dp.Id ~= 0 and (dp :: any).Clicks then
		productHandlers[dp.Id] = function(p, data)
			-- pack value tracks the buyer's current per-click gain at purchase time
			local amount = GameService.TrainGain(p, data) * (dp :: any).Clicks
			data.HandSigns += amount
			data.LifetimeHandSigns += amount
		end
	end
end
if next(productHandlers) then
	MarketplaceService.ProcessReceipt = function(info)
		local p = Players:GetPlayerByUserId(info.PlayerId)
		local data = p and DataService.Get(p)
		if not p or not data or not DataService.CanMutate(p) then return Enum.ProductPurchaseDecision.NotProcessedYet end
		if data.Receipts[info.PurchaseId] then return Enum.ProductPurchaseDecision.PurchaseGranted end
		local h = productHandlers[info.ProductId]
		if not h then return Enum.ProductPurchaseDecision.NotProcessedYet end
		h(p, data)
		data.Receipts[info.PurchaseId] = os.time()
		-- keep the receipt log bounded
		local n, oldestK, oldestT = 0, nil, math.huge
		for k, t in data.Receipts do n += 1; if t < oldestT then oldestK, oldestT = k, t end end
		if n > 100 and oldestK then data.Receipts[oldestK] = nil end
		changed(p)
		DataService.SaveNow(p)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
end

---------------------------------------------------------------- leaderboards (log-encoded so huge numbers fit OrderedDataStore integers)
SystemsService.Boards = {} :: {[string]: {{Name: string, Value: number}}}
local BOARD_STATS = {
	LifetimeHandSigns = function(d) return d.LifetimeHandSigns end,
	Trophies = function(d) return d.LifetimeTrophies end,
	Rebirths = function(d) return d.Rebirths end,
	Stage = function(d) return d.HighestUnlockedStage end,
}
local function encode(v: number): number return v <= 0 and 0 or math.floor(math.log10(v + 1) * 1e6) end
local function decode(v: number): number return 10 ^ (v / 1e6) - 1 end
local stores: {[string]: OrderedDataStore} = {}
local function startLeaderboards()
	for stat in BOARD_STATS do
		local ok, s = pcall(DataStoreService.GetOrderedDataStore, DataStoreService, "LB_" .. stat .. "_v1")
		if ok then stores[stat] = s end
	end
	if not next(stores) then return end
	task.spawn(function()
		while true do
			for stat, fn in BOARD_STATS do
				local store = stores[stat]
				if store then
					for _, p in Players:GetPlayers() do
						local d = DataService.Get(p)
						if d then pcall(store.SetAsync, store, tostring(p.UserId), encode(fn(d))) end
					end
					local ok, pages = pcall(store.GetSortedAsync, store, false, 10)
					if ok then
						local list = {}
						for _, row in pages:GetCurrentPage() do
							local okN, name = pcall(Players.GetNameFromUserIdAsync, Players, tonumber(row.key) or 0)
							table.insert(list, {Name = okN and name or ("#" .. row.key), Value = decode(row.value)})
						end
						SystemsService.Boards[stat] = list
					end
				end
				task.wait(5)
			end
			local holder = ReplicatedStorage:FindFirstChild("LeaderboardData") :: StringValue?
			if holder then holder.Value = HttpService:JSONEncode(SystemsService.Boards) end
			task.wait(90)
		end
	end)
end

---------------------------------------------------------------- lifecycle
function SystemsService.Start()
	local holder = Instance.new("StringValue")
	holder.Name = "LeaderboardData"
	holder.Value = "{}"
	holder.Parent = ReplicatedStorage

	DataService.OnLoaded(function(p, data)
		sessionStart[p] = os.clock()
		playtimeClaimed[p] = {}
		local now = os.time()
		giftReady[p] = {}
		for _, g in SC.Gifts do giftReady[p][g.Id] = now + g.Minutes * 60 end
		refreshPasses(p)
		-- drop records for pets that no longer exist in config
		for uid, rec in data.Pets do if not SC.Pets[rec.Pet] then data.Pets[uid] = nil end end
		for i = #data.EquippedPets, 1, -1 do if not data.Pets[data.EquippedPets[i]] then table.remove(data.EquippedPets, i) end end
		computeOffline(p, data)
		changed(p)
	end)
	Players.PlayerRemoving:Connect(function(p)
		sessionStart[p] = nil; playtimeClaimed[p] = nil; giftReady[p] = nil; ownedPasses[p] = nil; freeAutoUntil[p] = nil; freeAutoReady[p] = nil
	end)

	-- auto train (upgrade): 2 trains per second, server-side
	task.spawn(function()
		while true do
			task.wait(1)
			for _, p in Players:GetPlayers() do
				local d = DataService.Get(p)
				if d then
					local rate = 0
					if GameService.UpgradeLevel(d, "AutoTrain") >= 1 and d.Settings.AutoTrain ~= false then rate = 2 end
					if (freeAutoUntil[p] or 0) > os.time() then rate = math.max(rate, SC.FreeAuto.TrainsPerSecond) end
					if hasPass(p, "AutoClicker") and d.Settings.AutoTrain ~= false then rate = math.max(rate, SC.OPAutoTrainsPerSecond) end
					if rate > 0 then GameService.AddHandSigns(p, GameService.TrainGain(p, d) * rate) end
				end
			end
		end
	end)

	if not RunService:IsStudio() then startLeaderboards() end -- Studio playtests must never write production OrderedDataStores
end

return SystemsService
