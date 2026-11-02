--!strict
-- Core simulator rules: remotes, replication, training, hand signs, XP, trophies, stage progression.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Config = require(ReplicatedStorage.Shared.Config)
local DataService = require(script.Parent.DataService)

local GameService = {}

---------------------------------------------------------------- remotes
local remotesFolder = Instance.new("Folder")
remotesFolder.Name = "Remotes"
local function remote(name: string, fn: boolean?): any
	local r = Instance.new(fn and "RemoteFunction" or "RemoteEvent")
	r.Name = name
	r.Parent = remotesFolder
	return r
end
GameService.Remotes = {
	Train = remote("Train"),            -- client -> server (batched count)
	EquipSign = remote("EquipSign"),
	Profile = remote("Profile"),        -- server -> client JSON snapshot of tables
	Notify = remote("Notify"),          -- server -> client toast/celebration
	Attack = remote("Attack"),          -- client -> server (M1)
	Cast = remote("Cast"),              -- client -> server ("E"/"R")
	Vfx = remote("Vfx"),                -- server -> all clients
	DamageNumber = remote("DamageNumber"),
	TeleportStage = remote("TeleportStage"),
	Action = remote("Action", true),    -- generic menu actions (pets, auras, rebirth, upgrades, codes, rewards)
}
remotesFolder.Parent = ReplicatedStorage

---------------------------------------------------------------- rate limiter (rate limit FIRST - LihFolk)
local buckets: {[Player]: {[string]: {n: number, t: number}}} = {}
function GameService.RateOk(player: Player, key: string, perSecond: number, cost: number?): boolean
	local b = buckets[player]
	if not b then b = {}; buckets[player] = b end
	local now = os.clock()
	local s = b[key]
	if not s then s = {n = perSecond, t = now}; b[key] = s end
	s.n = math.min(perSecond, s.n + (now - s.t) * perSecond)
	s.t = now
	local c = cost or 1
	if s.n < c then return false end
	s.n -= c
	return true
end
Players.PlayerRemoving:Connect(function(p) buckets[p] = nil end)

---------------------------------------------------------------- multipliers (systems plug in here)
GameService.MultiplierProviders = {} :: {[string]: (Player, any) -> number}
function GameService.TrainingMultiplier(player: Player, data: any): number
	local sign = Config.HandSigns[data.EquippedHandSign] or Config.HandSigns.Tiger
	local m = sign.Multiplier
	for _, f in GameService.MultiplierProviders do m *= f(player, data) end
	m *= (player:GetAttribute("ZoneMult") or 1) -- lobby training station (set server-side by LobbyService)
	return m
end
function GameService.RebirthMultiplier(data: any): number
	return 1 + data.Rebirths * 0.75
end
GameService.UpgradeLevel = function(data: any, id: string): number return data.Upgrades[id] or 0 end
GameService.TrophyBonus = function(_player: Player, _data: any): number return 1 end -- SystemsService replaces (passes)
GameService.SnapshotExtras = {} :: {(Player, any, any) -> ()}

---------------------------------------------------------------- replication
local dirty: {[Player]: boolean} = {}
function GameService.Refresh(player: Player)
	local data = DataService.Get(player)
	if not data then return end
	player:SetAttribute("HandSigns", data.HandSigns)
	player:SetAttribute("Trophies", data.Trophies)
	player:SetAttribute("Level", data.Level)
	player:SetAttribute("XP", data.XP)
	player:SetAttribute("XPNeed", Config.XPForLevel(data.Level))
	player:SetAttribute("Equipped", data.EquippedHandSign)
	player:SetAttribute("Highest", data.HighestUnlockedStage)
	player:SetAttribute("Rebirths", data.Rebirths)
	player:SetAttribute("Multiplier", GameService.TrainingMultiplier(player, data))
	player:SetAttribute("RebirthMult", GameService.RebirthMultiplier(data))
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		(ls :: any).Signs.Value = Config.Format(data.HandSigns);
		(ls :: any).Rebirths.Value = data.Rebirths;
		(ls :: any).Stage.Value = data.HighestUnlockedStage
	end
	dirty[player] = true
end

-- tables go out as a throttled JSON snapshot
task.spawn(function()
	while true do
		task.wait(0.25)
		for player in dirty do
			dirty[player] = nil
			local data = DataService.Get(player)
			if data and player.Parent then
				local snap = {
					Unlocked = data.UnlockedHandSigns, Completed = data.CompletedStages, StageKills = data.StageKills,
					Pets = data.Pets, EquippedPets = data.EquippedPets, PetSlots = data.PetSlots, Auras = data.Auras, EquippedAura = data.EquippedAura,
					Upgrades = data.Upgrades, Claimed = data.Claimed, LastDaily = data.LastDaily, DailyStreak = data.DailyStreak,
					PendingPads = GameService.PendingPads[player] or {}, Settings = data.Settings, LifetimeHandSigns = data.LifetimeHandSigns,
					ServerTime = os.time(),
				}
				for _, f in GameService.SnapshotExtras do pcall(f, player, data, snap) end
				GameService.Remotes.Profile:FireClient(player, HttpService:JSONEncode(snap))
			end
		end
	end
end)

function GameService.Notify(player: Player, kind: string, payload: any)
	GameService.Remotes.Notify:FireClient(player, kind, payload)
end

---------------------------------------------------------------- currencies / XP
function GameService.AddHandSigns(player: Player, amount: number)
	local data = DataService.Get(player)
	if not data or not DataService.CanMutate(player) or amount ~= amount or amount <= 0 then return end
	data.HandSigns += amount
	data.LifetimeHandSigns += amount
	GameService.CheckUnlocks(player)
	GameService.Refresh(player)
end

function GameService.AddTrophies(player: Player, amount: number)
	local data = DataService.Get(player)
	if not data or not DataService.CanMutate(player) or amount ~= amount or amount <= 0 then return end
	local mult = (1 + 0.25 * GameService.UpgradeLevel(data, "TrophyGain")) * GameService.TrophyBonus(player, data)
	amount = math.floor(amount * mult + 0.5)
	data.Trophies += amount
	data.LifetimeTrophies += amount
	GameService.Refresh(player)
end

function GameService.AddXP(player: Player, amount: number)
	local data = DataService.Get(player)
	if not data or not DataService.CanMutate(player) or amount <= 0 then return end
	data.XP += amount
	data.TotalXP += amount
	local leveled = false
	while data.XP >= Config.XPForLevel(data.Level) do
		data.XP -= Config.XPForLevel(data.Level)
		data.Level += 1
		leveled = true
	end
	if leveled then GameService.Notify(player, "LevelUp", data.Level) end
	GameService.Refresh(player)
end

---------------------------------------------------------------- training
function GameService.TrainGain(player: Player, data: any): number
	local up = 1 + GameService.UpgradeLevel(data, "SignsPerClick")
	return Config.Economy.BaseGain * up * GameService.TrainingMultiplier(player, data) * GameService.RebirthMultiplier(data)
end

GameService.Remotes.Train.OnServerEvent:Connect(function(player: Player, count: any)
	-- client batches taps; server caps taps/sec (LihFolk: Tap Simulator teardown)
	if typeof(count) ~= "number" or count ~= count then return end
	count = math.clamp(math.floor(count), 1, 30)
	local allowed = 0
	for _ = 1, count do
		if GameService.RateOk(player, "train", Config.Economy.MaxTrainsPerSecond) then allowed += 1 else break end
	end
	if allowed == 0 then return end
	local data = DataService.Get(player)
	if not data then return end
	GameService.AddHandSigns(player, GameService.TrainGain(player, data) * allowed)
end)

---------------------------------------------------------------- hand signs
-- signs are bought with Trophies at the showcase (SystemsService BuySign); only free signs auto-unlock
function GameService.CanUnlock(data: any, id: string): boolean
	local s = Config.HandSigns[id]
	if not s then return false end
	return s.Price <= 0 and data.HighestUnlockedStage >= s.Stage
end

function GameService.CheckUnlocks(player: Player)
	local data = DataService.Get(player)
	if not data then return end
	for _, id in Config.HandSignOrder do
		if not data.UnlockedHandSigns[id] and GameService.CanUnlock(data, id) then
			data.UnlockedHandSigns[id] = true
			GameService.Notify(player, "SignUnlocked", id)
			dirty[player] = true
		end
	end
end

GameService.OnEquipChanged = {} :: {(Player, string) -> ()}
local lastEquip: {[Player]: number} = {}
GameService.Remotes.EquipSign.OnServerEvent:Connect(function(player: Player, id: any)
	if not GameService.RateOk(player, "equip", 2) then return end
	if typeof(id) ~= "string" or not Config.HandSigns[id] then return end
	local data = DataService.Get(player)
	if not data or not data.UnlockedHandSigns[id] then return end -- ownership check on every equip
	if data.EquippedHandSign == id then return end
	if os.clock() - (lastEquip[player] or 0) < 1 then return end
	lastEquip[player] = os.clock()
	data.EquippedHandSign = id
	for _, cb in GameService.OnEquipChanged do task.spawn(cb, player, id) end
	GameService.Refresh(player)
end)

---------------------------------------------------------------- stage progression (per player)
GameService.PendingPads = {} :: {[Player]: {[string]: boolean}}
function GameService.RemainingFor(data: any, stage: number): number
	return math.max(0, Config.Economy.KillsToClear - (data.StageKills[tostring(stage)] or 0))
end

function GameService.CreditKill(player: Player, stage: number, isBoss: boolean)
	local data = DataService.Get(player)
	if not data or not DataService.CanMutate(player) then return end
	local st = Config.Stages[stage]
	if not st or stage > data.HighestUnlockedStage then return end
	GameService.AddTrophies(player, isBoss and st.Trophies * 3 or st.Trophies)
	GameService.AddXP(player, isBoss and st.XP * 4 or st.XP)
	GameService.AddHandSigns(player, math.max(1, st.Recommended * (isBoss and 0.02 or 0.005)) * GameService.RebirthMultiplier(data))
	local key = tostring(stage)
	data.StageKills[key] = (data.StageKills[key] or 0) + 1
	if data.StageKills[key] >= Config.Economy.KillsToClear then
		data.StageKills[key] = 0
		local first = not data.CompletedStages[key]
		data.CompletedStages[key] = true
		if stage + 1 <= Config.StageCount and data.HighestUnlockedStage < stage + 1 then
			data.HighestUnlockedStage = stage + 1
		end
		GameService.PendingPads[player] = GameService.PendingPads[player] or {}
		GameService.PendingPads[player][key] = true
		GameService.AddXP(player, st.XP * 6)
		GameService.Notify(player, "StageCleared", {Stage = stage, First = first})
		GameService.CheckUnlocks(player)
		DataService.SaveNow(player)
	end
	GameService.Refresh(player)
end

-- trophy pad: claim the stage-clear reward (once per clear)
function GameService.ClaimPad(player: Player, stage: number)
	local pads = GameService.PendingPads[player]
	local key = tostring(stage)
	if not pads or not pads[key] then return end
	pads[key] = nil
	local st = Config.Stages[stage]
	local amt = st.Trophies * 10
	GameService.AddTrophies(player, amt)
	GameService.Notify(player, "PadClaimed", {Stage = stage, Amount = amt})
end

function GameService.LobbySpawnCFrame(): CFrame?
	local lobby = workspace:FindFirstChild("Lobby")
	local sp = lobby and lobby:FindFirstChild("LobbySpawn") :: BasePart?
	return sp and (sp.CFrame + Vector3.new(0, 4, 0)) or nil
end

function GameService.StageSpawnCFrame(stage: number): CFrame
	if stage <= 0 then
		local l = GameService.LobbySpawnCFrame()
		if l then return l end
		stage = 1
	end
	local folder = workspace:FindFirstChild("StageCourse")
	local st = folder and folder:FindFirstChild(string.format("Stage%02d", stage))
	local spawnPart = st and st:FindFirstChild("Spawn")
	if spawnPart then return (spawnPart :: BasePart).CFrame + Vector3.new(0, 4, 0) end
	return CFrame.new((stage - 1) * Config.StageLength - 60, 8, 0) * CFrame.Angles(0, -math.pi / 2, 0)
end

GameService.Remotes.TeleportStage.OnServerEvent:Connect(function(player: Player, stage: any)
	if not GameService.RateOk(player, "tp", 1) then return end
	if typeof(stage) ~= "number" then return end
	local data = DataService.Get(player)
	if not data then return end
	stage = math.floor(stage)
	if stage < 0 or stage > data.HighestUnlockedStage then return end -- 0 = lobby
	if stage > 0 then data.CurrentStage = stage end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then root.CFrame = GameService.StageSpawnCFrame(stage) end
end)

-- server guard: players cannot stand past their unlocked gate
task.spawn(function()
	while true do
		task.wait(0.5)
		for _, player in Players:GetPlayers() do
			local data = DataService.Get(player)
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if data and root then
				local x = root.Position.X
				local maxX = (data.HighestUnlockedStage - 1) * Config.StageLength + Config.StageLength / 2 - 4
				if x > maxX + 6 then
					root.CFrame = GameService.StageSpawnCFrame(data.HighestUnlockedStage)
					root.AssemblyLinearVelocity = Vector3.zero
				end
				player:SetAttribute("InLobby", x < -Config.StageLength / 2)
				local stageIdx = math.clamp(math.floor((x + Config.StageLength / 2) / Config.StageLength) + 1, 1, Config.StageCount)
				if player:GetAttribute("InStage") ~= stageIdx then
					player:SetAttribute("InStage", stageIdx)
					data.CurrentStage = math.min(stageIdx, data.HighestUnlockedStage)
				end
				if root.Position.Y < -60 then root.CFrame = GameService.StageSpawnCFrame(data.CurrentStage) end
			end
		end
	end
end)

---------------------------------------------------------------- lifecycle
function GameService.Start()
	-- Studio-only QA hook (never exists on live servers): ServerStorage.DevGrant:Invoke(player, {Stage=n, HandSigns=n, Trophies=n})
	if game:GetService("RunService"):IsStudio() then
		local bf = Instance.new("BindableFunction")
		bf.Name = "DevGrant"
		bf.OnInvoke = function(player: Player, t: any)
			local data = DataService.Get(player)
			if not data then return "no data" end
			if t.Stage then data.HighestUnlockedStage = math.clamp(t.Stage, 1, Config.StageCount) end
			if t.HandSigns then GameService.AddHandSigns(player, t.HandSigns) end
			if t.Trophies then GameService.AddTrophies(player, t.Trophies) end
			GameService.CheckUnlocks(player)
			GameService.Refresh(player)
			local u = {}
			for k in data.UnlockedHandSigns do table.insert(u, k) end
			return table.concat(u, ",")
		end
		bf.Parent = game:GetService("ServerStorage")
	end
	DataService.OnLoaded(function(player, data)
		local ls = Instance.new("Folder")
		ls.Name = "leaderstats"
		local a = Instance.new("StringValue"); a.Name = "Signs"; a.Parent = ls
		local b = Instance.new("IntValue"); b.Name = "Rebirths"; b.Parent = ls
		local c = Instance.new("IntValue"); c.Name = "Stage"; c.Parent = ls
		ls.Parent = player
		-- course shrank from 50 to 30 stages: clamp old saves
		data.HighestUnlockedStage = math.clamp(data.HighestUnlockedStage, 1, Config.StageCount)
		data.CurrentStage = math.clamp(data.CurrentStage, 1, data.HighestUnlockedStage)
		GameService.CheckUnlocks(player)
		GameService.Refresh(player)
		local function spawnAt(char: Model)
			local root = char:WaitForChild("HumanoidRootPart", 5) :: BasePart?
			if root then
				task.wait()
				root.CFrame = GameService.StageSpawnCFrame(0) -- everyone spawns in the lobby hub
			end
		end
		player.CharacterAdded:Connect(spawnAt)
		if player.Character then task.spawn(spawnAt, player.Character) end
	end)
	Players.PlayerRemoving:Connect(function(p) GameService.PendingPads[p] = nil; lastEquip[p] = nil end)
end

return GameService

