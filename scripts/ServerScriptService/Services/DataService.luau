--!strict
-- Session-locked player data (LihFolk: "Session Locking and Profile Libraries", "Saving Correctly - Autosave and BindToClose")
-- * lease written + checked inside the same UpdateAsync as the data
-- * every save fenced by a per-session token; losing the lease stops all writes
-- * load returns ready / locked / failed - a failed load NEVER saves defaults over real data
-- * autosave (staggered) shorter than the lease; leave-save releases; BindToClose saves in parallel
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local SCHEMA = 1
local LEASE = 150
local AUTOSAVE = 60
local STORE_NAME = "HandSignsPlayerData_v1"

local DataService = {}
DataService.Profiles = {} :: {[Player]: any}
local loadedCallbacks: {(Player, any) -> ()} = {}
local pendingSaves = 0
local sessionToken = HttpService:GenerateGUID(false)

local store: DataStore? = nil
local okStore = pcall(function() store = DataStoreService:GetDataStore(STORE_NAME) end)
local useMemoryOnly = not okStore

function DataService.Default()
	return {
		Schema = SCHEMA,
		HandSigns = 0, LifetimeHandSigns = 0, Trophies = 0, LifetimeTrophies = 0,
		Level = 1, XP = 0, TotalXP = 0,
		EquippedHandSign = "Tiger", UnlockedHandSigns = {Tiger = true},
		CurrentStage = 1, HighestUnlockedStage = 1, CompletedStages = {}, StageKills = {},
		Rebirths = 0,
		Pets = {}, EquippedPets = {}, NextPetId = 1, PetSlots = 3,
		Auras = {}, EquippedAura = "",
		Upgrades = {},
		Claimed = {}, RedeemedCodes = {}, LastDaily = 0, DailyStreak = 0,
		LastSeen = 0, Settings = {ReduceEffects = false, Music = true, AutoTrain = true, HideOtherPets = false},
		PendingOffline = 0, Receipts = {}, BoostUntil = 0, ClaimedMilestones = {},
		KyubiCoins = 0, TrophyBoostUntil = 0, LastLeaveBonus = 0,
		GiftDay = 0, GiftCounts = {},
	}
end

local function migrate(data: any)
	local def = DataService.Default()
	for k, v in def do if data[k] == nil then data[k] = v end end
	if not data.UnlockedHandSigns.Tiger then data.UnlockedHandSigns.Tiger = true end
	data.Schema = SCHEMA
	return data
end

local function keyFor(player: Player): string
	return "p_" .. player.UserId
end

local function retry<T>(fn: () -> T, tries: number): (boolean, any)
	local lastErr
	for i = 1, tries do
		local ok, res = pcall(fn)
		if ok then return true, res end
		lastErr = res
		if typeof(res) == "string" and (res:find("locked") or res:find("permission") or res:find("403") or res:find("publish") or res:find("Studio")) then break end
		task.wait(math.min(2 ^ i, 8) + math.random())
	end
	return false, lastErr
end

-- returns "ready", data | "locked" | "failed"
local function loadAndLock(player: Player): (string, any)
	if useMemoryOnly or not store then return "ready", DataService.Default() end
	local status = "failed"
	local result = nil
	local ok, err = retry(function()
		(store :: DataStore):UpdateAsync(keyFor(player), function(old)
			local data = old or DataService.Default()
			local lock = data._Lock
			local now = os.time()
			if lock and lock.Token ~= sessionToken and now - (lock.Time or 0) < LEASE and not RunService:IsStudio() then
				status = "locked"
				return nil -- cancel write
			end
			data._Lock = {Token = sessionToken, Time = now, Job = game.JobId}
			status = "ready"
			result = data
			return data
		end)
		return true
	end, 4)
	if not ok then
		warn("[DataService] load failed for", player.Name, err)
		return "failed", nil
	end
	if status == "ready" then return "ready", migrate(result) end
	return status, nil
end

-- fenced save; release=true clears the lease
local function save(player: Player, release: boolean): boolean
	local profile = DataService.Profiles[player]
	if not profile or not profile.CanSave then return false end
	if useMemoryOnly or not store or profile.NoPersist then return true end
	profile.Data.LastSeen = os.time()
	local snapshot = table.clone(profile.Data)
	local lost = false
	pendingSaves += 1
	local ok, err = retry(function()
		(store :: DataStore):UpdateAsync(keyFor(player), function(old)
			if old and old._Lock and old._Lock.Token ~= sessionToken then
				lost = true
				return nil
			end
			snapshot._Lock = (not release) and {Token = sessionToken, Time = os.time(), Job = game.JobId} or nil
			return snapshot
		end)
		return true
	end, 3)
	pendingSaves -= 1
	if lost then
		profile.CanSave = false
		warn("[DataService] lease lost for", player.Name, "- writes stopped")
		player:Kick("Your data was opened on another server. Please rejoin.")
	end
	if not ok then warn("[DataService] save failed for", player.Name, err) end
	return ok and not lost
end

function DataService.Get(player: Player): any?
	local p = DataService.Profiles[player]
	return p and p.Data
end

function DataService.CanMutate(player: Player): boolean
	local p = DataService.Profiles[player]
	return p ~= nil and p.CanSave
end

function DataService.OnLoaded(cb: (Player, any) -> ())
	table.insert(loadedCallbacks, cb)
	for plr, prof in DataService.Profiles do task.spawn(cb, plr, prof.Data) end
end

function DataService.SaveNow(player: Player)
	task.spawn(save, player, false)
end

local function onJoin(player: Player)
	local status, data
	for attempt = 1, 4 do
		status, data = loadAndLock(player)
		if status ~= "locked" then break end
		task.wait(6)
		if not player.Parent then return end
	end
	if not player.Parent then
		if status == "ready" then DataService.Profiles[player] = {Data = data, CanSave = true}; save(player, true); DataService.Profiles[player] = nil end
		return
	end
	local noPersist = false
	if status == "failed" and RunService:IsStudio() then
		warn("[DataService] Studio: DataStore unavailable (enable Studio API access). Using a temporary profile that will NOT save.")
		status, data, noPersist = "ready", DataService.Default(), true
	end
	if status ~= "ready" then
		player:Kick(status == "locked" and "Your data is still in use by another server. Please rejoin in a minute." or "Could not load your data (Roblox data service issue). Please rejoin - your progress is safe.")
		return
	end
	DataService.Profiles[player] = {Data = data, CanSave = true, NoPersist = noPersist}
	player:SetAttribute("DataLoaded", true)
	for _, cb in loadedCallbacks do task.spawn(cb, player, data) end
end

local leaving: {[Player]: boolean} = {}
local function onLeave(player: Player)
	if not DataService.Profiles[player] then return end
	leaving[player] = true
	save(player, true)
	DataService.Profiles[player] = nil
	leaving[player] = nil
end

function DataService.Start()
	Players.PlayerAdded:Connect(onJoin)
	for _, p in Players:GetPlayers() do task.spawn(onJoin, p) end
	Players.PlayerRemoving:Connect(onLeave)
	-- staggered autosave
	task.spawn(function()
		while true do
			task.wait(AUTOSAVE)
			local list = {}
			for p in DataService.Profiles do table.insert(list, p) end
			for i, p in list do
				if DataService.Profiles[p] and not leaving[p] then task.spawn(save, p, false) end
				task.wait(AUTOSAVE * 0.5 / math.max(#list, 1))
			end
		end
	end)
	game:BindToClose(function()
		if RunService:IsStudio() then
			-- Studio: save but don't hold the editor for long
			for p in DataService.Profiles do task.spawn(save, p, true) end
			task.wait(1)
			return
		end
		for p in DataService.Profiles do task.spawn(save, p, true) end
		local deadline = os.clock() + 25
		task.wait(0.1)
		while pendingSaves > 0 and os.clock() < deadline do task.wait(0.1) end
	end)
end

return DataService
