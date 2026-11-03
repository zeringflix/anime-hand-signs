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
GameService.HasPass = function(_player: Player, _key: string): boolean return false end -- SystemsService replaces (real game-pass ownership)
GameService.TrophyBonus = function(_player: Player, _data: any, _excludeDoublePass: boolean?): number return 1 end -- SystemsService replaces (passes)
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

function GameService.AddTrophies(player: Player, amount: number, excludeDoublePass: boolean?)
	local data = DataService.Get(player)
	if not data or not DataService.CanMutate(player) or amount ~= amount or amount <= 0 then return end
	local mult = (1 + 0.25 * GameService.UpgradeLevel(data, "TrophyGain")) * GameService.TrophyBonus(player, data, excludeDoublePass)
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
	return (s.Price or 0) <= 0 and data.HighestUnlockedStage >= s.Stage
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
-- GATES (owner request): you can't walk into the next stage until this stage's enemies are dead. GateReach is the
-- furthest stage the player may stand in right now: entering from the lobby = 1, teleporting = that stage, clearing
-- the reach stage opens its gate (reach + 1). Even previously-cleared stages must be cleared again to walk on.
GameService.GateReach = {} :: {[Player]: number}
function GameService.SetReach(player: Player, stage: number)
	stage = math.clamp(stage, 1, Config.StageCount)
	if GameService.GateReach[player] == stage then return end
	GameService.GateReach[player] = stage
	player:SetAttribute("GateReach", stage) -- client colours the gate walls from this; the guard below enforces it
end
function GameService.RemainingFor(data: any, stage: number): number
	return math.max(0, Config.KillsToClear(stage) - (data.StageKills[tostring(stage)] or 0))
end
-- a fresh enemy set was spawned for this player's stage (EnemyService): the kill counter starts again, so the gate
-- opens exactly when every enemy of the current set is dead (enemies no longer respawn inside a set)
function GameService.ResetStageKills(player: Player, stage: number)
	local data = DataService.Get(player)
	if not data then return end
	data.StageKills[tostring(stage)] = 0
	GameService.Refresh(player)
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
	if data.StageKills[key] >= Config.KillsToClear(stage) then
		data.StageKills[key] = 0
		local first = not data.CompletedStages[key]
		data.CompletedStages[key] = true
		if stage + 1 <= Config.StageCount and data.HighestUnlockedStage < stage + 1 then
			data.HighestUnlockedStage = stage + 1
		end
		GameService.PendingPads[player] = GameService.PendingPads[player] or {}
		GameService.PendingPads[player][key] = true
		if (GameService.GateReach[player] or 1) <= stage then GameService.SetReach(player, math.min(stage + 1, data.HighestUnlockedStage)) end
		GameService.AddXP(player, st.XP * 6)
		GameService.Notify(player, "StageCleared", {Stage = stage, First = first})
		GameService.CheckUnlocks(player)
		DataService.SaveNow(player)
	end
	GameService.Refresh(player)
end

-- WIN PADS (owner request): after clearing a stage the player chooses: collect their wins on the pad (which
-- sends them back to the lobby) or keep going to the next stage. Two pads per stage:
--   TrophyPad   -> x1 stage reward, teleport to lobby
--   TrophyPadX2 -> x2 stage reward for owners of the 2x Trophies pass (prompts the pass otherwise), teleport to lobby
-- One pass, no stacking: 2x Trophies doubles trophies everywhere AND unlocks the x2 pad; pad rewards skip the pass's
-- general doubling so the x1 pad pays x1 and the x2 pad pays exactly x2 (never x4).
-- The reward is pending per player per clear (server-side), so touching twice / both pads never pays twice.
function GameService.ClaimPad(player: Player, stage: number, mult: number?): boolean
	local pads = GameService.PendingPads[player]
	local key = tostring(stage)
	if not pads or not pads[key] then return false end
	pads[key] = nil
	local st = Config.Stages[stage]
	local amt = st.Trophies * 10 * (mult or 1)
	GameService.AddTrophies(player, amt, true)
	GameService.Notify(player, "PadClaimed", {Stage = stage, Amount = amt, Mult = mult or 1})
	GameService.Refresh(player)
	task.delay(0.6, function() -- short beat for the reward pop, then back to the hub
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root and player.Parent then
			root.CFrame = GameService.StageSpawnCFrame(0)
			root.AssemblyLinearVelocity = Vector3.zero
		end
	end)
	return true
end

local WIN_PAD_PASS = "DoubleTrophies" -- the single 2x Trophies pass
function GameService.ClaimPadX2(player: Player, stage: number): boolean
	local pads = GameService.PendingPads[player]
	if not pads or not pads[tostring(stage)] then return false end
	if GameService.HasPass(player, WIN_PAD_PASS) then return GameService.ClaimPad(player, stage, 2) end
	local SC = require(ReplicatedStorage.Shared.SystemsConfig)
	local gp = SC.GamePasses[WIN_PAD_PASS]
	if gp and gp.Id ~= 0 then
		game:GetService("MarketplaceService"):PromptGamePassPurchase(player, gp.Id)
	else
		GameService.Notify(player, "Toast", "x2 Wins needs the 2x Trophies pass (not available yet) - use the normal pad")
	end
	return false
end

-- runtime pad setup for every stage (adds the x2 pad beside the existing TrophyPad; stages are not rebuilt)
local function padLabel(pad: BasePart, title: string, sub: string, color: Color3)
	local old = pad:FindFirstChild("PadLabel")
	if old then old:Destroy() end
	local bb = Instance.new("BillboardGui")
	bb.Name = "PadLabel"; bb.Size = UDim2.fromScale(12, 4.6); bb.StudsOffsetWorldSpace = Vector3.new(0, 5, 0)
	bb.MaxDistance = 140; bb.LightInfluence = 0; bb.AlwaysOnTop = false; bb.Parent = pad
	for i, t in {{title, 0, 0.6, color}, {sub, 0.6, 0.4, Color3.new(1, 1, 1)}} do
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1; l.Font = Enum.Font.FredokaOne; l.TextScaled = true; l.Text = t[1]; l.TextColor3 = t[4]
		l.Position = UDim2.fromScale(0, t[2]); l.Size = UDim2.fromScale(1, t[3])
		local st = Instance.new("UIStroke"); st.Thickness = i == 1 and 4 or 3; st.Color = Color3.fromRGB(20, 16, 28); st.Parent = l
		l.Parent = bb
	end
end
local padDebounce: {[Player]: number} = {}
local function buildWinPads()
	local course = workspace:FindFirstChild("StageCourse")
	if not course then return end
	for _, stageModel in course:GetChildren() do
		local pad = stageModel:FindFirstChild("TrophyPad") :: BasePart?
		local stage = pad and (pad:GetAttribute("Stage") or tonumber(stageModel.Name:match("%d+")))
		if pad and stage then
			padLabel(pad, "COLLECT WINS", "Back to lobby", Color3.fromRGB(255, 214, 60))
			if not stageModel:FindFirstChild("TrophyPadX2") then
				local x2 = pad:Clone()
				x2.Name = "TrophyPadX2"
				for _, c in x2:GetChildren() do if not c:IsA("Attachment") then c:Destroy() end end
				x2.Color = Color3.fromRGB(190, 90, 255)
				x2.Material = Enum.Material.Neon
				-- beside the normal pad, towards the path (the outer side runs into the cliff rim)
				local side = pad.Position.Z >= 0 and 1 or -1
				x2.CFrame = pad.CFrame - Vector3.new(0, 0, side * (pad.Size.Z + 3))
				x2:SetAttribute("Stage", stage)
				x2.Parent = stageModel
				padLabel(x2, "x2 WINS", "2x Trophies pass · back to lobby", Color3.fromRGB(220, 150, 255))
				x2.Touched:Connect(function(hit)
					local player = Players:GetPlayerFromCharacter(hit.Parent)
					if not player then return end
					if os.clock() - (padDebounce[player] or 0) < 1.5 then return end
					padDebounce[player] = os.clock()
					GameService.ClaimPadX2(player, stage)
				end)
			end
		end
	end
end
Players.PlayerRemoving:Connect(function(p) padDebounce[p] = nil end)

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
	if typeof(stage) ~= "number" or stage ~= stage or math.abs(stage) == math.huge then return end
	local data = DataService.Get(player)
	if not data then return end
	stage = math.floor(stage)
	if stage < 0 or stage > data.HighestUnlockedStage then return end -- 0 = lobby
	if stage > 0 then data.CurrentStage = stage end
	GameService.SetReach(player, math.max(stage, 1))
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then root.CFrame = GameService.StageSpawnCFrame(stage) end
end)

-- lobby training stations (issue #14): inside a station Zone, training is multiplied if Rebirths >= requirement
function GameService.StationMultiplier(player: Player, data: any, pos: Vector3): number
	local lobby = workspace:FindFirstChild("Lobby")
	local folder = lobby and lobby:FindFirstChild("TrainingStations")
	if not folder then return 1 end
	local stations = require(game:GetService("ReplicatedStorage").Shared.SystemsConfig).TrainingStations
	if not stations then return 1 end
	for _, m in folder:GetChildren() do
		local zone = m:FindFirstChild("Zone") :: BasePart?
		local idx = zone and zone:GetAttribute("StationIndex")
		local st = idx and stations[idx]
		if zone and st then
			local lp = zone.CFrame:PointToObjectSpace(pos)
			local h = zone.Size / 2
			if math.abs(lp.X) <= h.X and math.abs(lp.Y) <= h.Y and math.abs(lp.Z) <= h.Z then
				if st.Pass then return GameService.HasPass(player, st.Pass) and st.Mult or 1 end
				return (data.Rebirths or 0) >= (st.Rebirths or 0) and st.Mult or 1
			end
		end
	end
	return 1
end

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
				local inLobby = x < -Config.StageLength / 2 - 12 -- the lobby arena sits well west of Stage 1's start wall
				player:SetAttribute("InLobby", inLobby)
				if inLobby then GameService.SetReach(player, 1) end
				-- closed gate: stand in front of it until this stage's enemies are dead
				local reach = GameService.GateReach[player] or 1
				local gateX = (reach - 1) * Config.StageLength + Config.StageLength / 2 - 4
				if not inLobby and x > gateX + 3 then
					local p = root.Position
					root.CFrame = CFrame.new(gateX - 8, p.Y + 0.5, p.Z) * root.CFrame.Rotation
					root.AssemblyLinearVelocity = Vector3.zero
					x = gateX - 8
					GameService.Notify(player, "Toast", "Defeat the enemies to open the gate!")
				end
				local okZ, zm = pcall(GameService.StationMultiplier, player, data, root.Position)
				zm = (okZ and inLobby) and zm or 1
				if player:GetAttribute("ZoneMult") ~= zm then
					player:SetAttribute("ZoneMult", zm)
					GameService.Refresh(player) -- keep the displayed multiplier consistent with training gains
				end
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
	task.spawn(buildWinPads)
	-- Studio-only QA hook (never exists on live servers): ServerStorage.DevGrant:Invoke(player, {Stage=n, HandSigns=n, Trophies=n})
	if game:GetService("RunService"):IsStudio() then
		local bf = Instance.new("BindableFunction")
		bf.Name = "DevGrant"
		bf.OnInvoke = function(player: Player, t: any)
			local data = DataService.Get(player)
			if not data then return "no data" end
			-- QA grants must never persist: flag this session's profile as memory-only
			local prof = DataService.Profiles[player]
			if prof then prof.NoPersist = true end
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
		-- clamp old saves to the current course
		data.HighestUnlockedStage = math.clamp(data.HighestUnlockedStage, 1, Config.StageCount)
		data.CurrentStage = math.clamp(data.CurrentStage, 1, data.HighestUnlockedStage)
		GameService.CheckUnlocks(player)
		GameService.Refresh(player)
		local function spawnAt(char: Model)
			local hum = char:WaitForChild("Humanoid", 5) :: Humanoid?
			if hum then hum.WalkSpeed = Config.WalkSpeed end -- 1.75x walk speed (owner request)
			local root = char:WaitForChild("HumanoidRootPart", 5) :: BasePart?
			if root then
				task.wait()
				root.CFrame = GameService.StageSpawnCFrame(0) -- everyone spawns in the lobby hub
			end
		end
		player.CharacterAdded:Connect(spawnAt)
		if player.Character then task.spawn(spawnAt, player.Character) end
	end)
	Players.PlayerRemoving:Connect(function(p) GameService.PendingPads[p] = nil; lastEquip[p] = nil; GameService.GateReach[p] = nil end)
end

return GameService
