--!strict
-- Server-authoritative stage enemies. 10 Hz brains, distance-gated per stage (LihFolk: NPC AI and Behaviour).
-- PER-PLAYER ENEMIES (owner request): every player gets their own set of enemies for the stage they are in.
-- Enemies stay server-simulated (HP, damage, rewards can't be faked), carry an OwnerId attribute, only target,
-- hurt and reward their owner, and only their owner's client renders them (Client.EnemyVisibility hides the rest).
-- HP lives in this table (not Humanoid.Health) so huge late-game numbers stay exact.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local GameService = require(script.Parent.GameService)

local EnemyService = {}
export type Enemy = {Id: number, Model: Model, Root: BasePart, Hum: Humanoid, Stage: number, IsBoss: boolean, Name: string,
	MaxHp: number, Hp: number, Damage: number, Credit: {[Player]: boolean}, RootedUntil: number, NextAttack: number,
	Home: Vector3, Dead: boolean, Bar: Frame, Burning: number, SpawnName: string, Owner: Player?, Anim: {[string]: AnimationTrack}?}
EnemyService.Enemies = {} :: {[number]: Enemy}
local byModel: {[Model]: Enemy} = {}
local nextId = 1
local folder = Instance.new("Folder")
folder.Name = "Enemies"
folder.Parent = workspace
-- spawned sets are keyed per owner: "<UserId>:<stage>"
local spawnedSets: {[string]: boolean} = {}
local function setKey(owner: Player, stage: number): string return owner.UserId .. ":" .. stage end
local activeKeys: {[string]: boolean} = {}

local SKIN = {Color3.fromRGB(255, 205, 160), Color3.fromRGB(234, 184, 146), Color3.fromRGB(198, 143, 104), Color3.fromRGB(150, 100, 70)}
local function shade(c: Color3, f: number) return Color3.new(math.clamp(c.R * f, 0, 1), math.clamp(c.G * f, 0, 1), math.clamp(c.B * f, 0, 1)) end

local function weldPart(model: Model, to: BasePart, size: Vector3, offset: CFrame, color: Color3, mat: Enum.Material?, shape: Enum.PartType?)
	local p = Instance.new("Part")
	p.Size = size
	p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic
	if shape then p.Shape = shape end
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CFrame = to.CFrame * offset
	local w = Instance.new("WeldConstraint")
	w.Part0 = to
	w.Part1 = p
	w.Parent = p
	p.Parent = model
	return p
end

-- build a blocky anime-ninja NPC (no external asset ids; outfit parts welded on)
local function buildRig(stage: number, variant: number, isBoss: boolean, name: string): Model
	local st = Config.Stages[stage]
	local rng = Random.new(stage * 31 + variant)
	local desc = Instance.new("HumanoidDescription")
	local skin = SKIN[rng:NextInteger(1, #SKIN)]
	local outfit = variant == 1 and shade(st.Cliff, 0.7) or variant == 2 and shade(st.Gate, 0.75) or shade(st.Leaf, 0.6)
	if isBoss then outfit = shade(st.Gate, 0.5) end
	desc.HeadColor = skin
	desc.LeftArmColor = skin
	desc.RightArmColor = skin
	desc.TorsoColor = outfit
	desc.LeftLegColor = Color3.fromRGB(30, 30, 40)
	desc.RightLegColor = Color3.fromRGB(30, 30, 40)
	local model = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	model.Name = name
	local head = model:WaitForChild("Head") :: BasePart
	local torso = model:WaitForChild("UpperTorso") :: BasePart
	-- vest + belt
	weldPart(model, torso, Vector3.new(2.15, 1.7, 1.15), CFrame.new(0, -0.05, 0), shade(outfit, 0.8))
	weldPart(model, torso, Vector3.new(2.2, 0.35, 1.2), CFrame.new(0, -0.85, 0), Color3.fromRGB(40, 35, 35))
	-- spiky blocky hair
	local hairCol = ({Color3.fromRGB(25, 25, 30), Color3.fromRGB(90, 60, 40), Color3.fromRGB(240, 220, 120), Color3.fromRGB(200, 60, 60), Color3.fromRGB(220, 220, 230)})[rng:NextInteger(1, 5)]
	weldPart(model, head, Vector3.new(1.35, 0.55, 1.35), CFrame.new(0, 0.55, 0.05), hairCol)
	for k = -1, 1 do weldPart(model, head, Vector3.new(0.45, 0.6, 0.45), CFrame.new(k * 0.4, 0.85, 0.2) * CFrame.Angles(-0.3, 0, k * 0.3), hairCol) end
	if variant == 1 then
		-- headband with metal plate
		weldPart(model, head, Vector3.new(1.3, 0.28, 1.3), CFrame.new(0, 0.2, 0), Color3.fromRGB(30, 50, 110))
		weldPart(model, head, Vector3.new(0.7, 0.3, 0.1), CFrame.new(0, 0.2, -0.66), Color3.fromRGB(200, 205, 215), Enum.Material.Metal)
	elseif variant == 2 then
		-- Open-front hood: side/back pieces preserve the face and eye silhouette.
		weldPart(model, head, Vector3.new(1.45, 0.3, 1.45), CFrame.new(0, 0.75, 0.08), outfit)
		weldPart(model, head, Vector3.new(0.2, 1.15, 1.25), CFrame.new(-0.68, 0.1, 0.16), outfit)
		weldPart(model, head, Vector3.new(0.2, 1.15, 1.25), CFrame.new(0.68, 0.1, 0.16), outfit)
		weldPart(model, head, Vector3.new(1.25, 1.15, 0.2), CFrame.new(0, 0.1, 0.7), outfit)
		weldPart(model, head, Vector3.new(1.05, 0.45, 0.1), CFrame.new(0, -0.25, -0.62), Color3.fromRGB(30, 30, 35))
	else
		-- straw hat / animal mask
		weldPart(model, head, Vector3.new(2.6, 0.25, 2.6), CFrame.new(0, 0.75, 0), Color3.fromRGB(200, 170, 100))
		weldPart(model, head, Vector3.new(1, 0.5, 1), CFrame.new(0, 1, 0), Color3.fromRGB(190, 160, 90))
		weldPart(model, head, Vector3.new(0.95, 0.75, 0.1), CFrame.new(0, -0.05, -0.62), Color3.fromRGB(245, 245, 245))
	end
	-- Original eye details and outfit accents; no borrowed character assets.
	for _, side in {-1, 1} do
		weldPart(model, head, Vector3.new(0.32, 0.18, 0.055), CFrame.new(side * 0.27, 0.04, -0.69), Color3.fromRGB(245, 245, 245))
		weldPart(model, head, Vector3.new(0.11, 0.15, 0.06), CFrame.new(side * 0.27, 0.04, -0.73), isBoss and st.Gate or Color3.fromRGB(205, 45, 65), isBoss and Enum.Material.Neon or Enum.Material.SmoothPlastic)
		weldPart(model, torso, Vector3.new(0.64, 0.82, 0.14), CFrame.new(side * 0.55, -0.15, -0.65), shade(outfit, 1.25))
	end
	-- Fine face and costume details follow existing animated body parts.
	for _, side in {-1, 1} do
		weldPart(model, head, Vector3.new(0.045, 0.12, 0.065), CFrame.new(side * 0.27, 0.04, -0.77), Color3.fromRGB(20, 17, 27))
		weldPart(model, head, Vector3.new(0.34, 0.055, 0.065), CFrame.new(side * 0.27, 0.165, -0.73) * CFrame.Angles(0, 0, side * 0.12), hairCol)
		local arm = model:FindFirstChild(side == -1 and "LeftLowerArm" or "RightLowerArm")
		if arm then
			weldPart(model, arm, Vector3.new(0.87, 0.6, 0.88), CFrame.new(0, -0.18, 0), shade(outfit, 0.55))
			weldPart(model, arm, Vector3.new(0.89, 0.12, 0.9), CFrame.new(0, -0.35, 0), Color3.fromRGB(209, 202, 185))
		end
	end
	weldPart(model, torso, Vector3.new(0.1, 1.2, 0.12), CFrame.new(0, -0.08, -0.68), Color3.fromRGB(190, 185, 169))
	local pouch = weldPart(model, torso, Vector3.new(0.45, 0.5, 0.35), CFrame.new(0.83, -0.7, 0.56), Color3.fromRGB(92, 65, 43))
	pouch.Name = "BeltPouch"
	if isBoss then
		weldPart(model, torso, Vector3.new(2.4, 3, 0.2), CFrame.new(0, -1.2, 0.7) * CFrame.Angles(0.15, 0, 0), st.Gate)
		local aura = Instance.new("ParticleEmitter")
		aura.Texture = "rbxassetid://118322217786922"
		aura.Name = "BossEmbers"
		aura.Color = ColorSequence.new(st.Gate)
		aura.LightEmission = 1
		aura.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0)})
		aura.Lifetime = NumberRange.new(0.6, 1)
		aura.Rate = 18
		aura.Speed = NumberRange.new(2, 4)
		aura.SpreadAngle = Vector2.new(180, 180)
		aura.Parent = torso
	end
	local hum = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.BreakJointsOnDeath = false
	hum.MaxHealth = 100
	hum.Health = 100
	hum.WalkSpeed = isBoss and 16 or 19
	-- real Roblox NPC feel: the stock R15 idle / walk animations (ids read from the Animate script that
	-- CreateHumanoidModelFromDescription generates) are played on the server Animator, which replicates them
	local animate = model:FindFirstChild("Animate")
	local ids: {[string]: string} = {}
	if animate then
		for _, key in {"idle", "walk", "run"} do
			local f = animate:FindFirstChild(key)
			local a = f and f:FindFirstChildOfClass("Animation")
			if a and a.AnimationId ~= "" then ids[key] = a.AnimationId end
		end
		animate:Destroy()
	end
	model:SetAttribute("AnimIdle", ids.idle or "")
	model:SetAttribute("AnimWalk", ids.walk or ids.run or "")
	return model
end

local function makeBillboard(e: Enemy)
	local bb = Instance.new("BillboardGui")
	bb.Name = "Info"
	bb.Size = UDim2.fromOffset(e.IsBoss and 176 or 132, e.IsBoss and 44 or 36)
	bb.StudsOffsetWorldSpace = Vector3.new(0, e.IsBoss and 4.6 or 3.4, 0)
	bb.MaxDistance = e.IsBoss and 100 or 65
	bb.LightInfluence = 0
	local nameL = Instance.new("TextLabel")
	nameL.BackgroundTransparency = 1
	nameL.Size = UDim2.fromScale(1, 0.5)
	nameL.Font = Enum.Font.FredokaOne
	nameL.TextScaled = true
	nameL.TextColor3 = e.IsBoss and Color3.fromRGB(255, 220, 80) or Color3.new(1, 1, 1)
	nameL.Text = e.Name
	local s = Instance.new("UIStroke"); s.Thickness = 2; s.Parent = nameL
	nameL.Parent = bb
	local back = Instance.new("Frame")
	back.Size = UDim2.fromScale(1, 0.34)
	back.Position = UDim2.fromScale(0, 0.58)
	back.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	Instance.new("UICorner", back).CornerRadius = UDim.new(1, 0)
	local st = Instance.new("UIStroke"); st.Thickness = 2; st.Color = Color3.fromRGB(15, 15, 15); st.Parent = back
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(60, 235, 70)
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
	local shine = Instance.new("UIGradient") -- glossy top highlight; the hue still reads clearly
	shine.Rotation = 90
	shine.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(185, 185, 185))
	shine.Parent = fill
	fill.Parent = back
	back.Parent = bb
	bb.Parent = e.Root
	e.Bar = fill
end

-- Roblox-style health colour: bright green when healthy, through yellow, to red when low (no HP numbers)
local GREEN, YELLOW, RED = Color3.fromRGB(60, 235, 70), Color3.fromRGB(255, 220, 40), Color3.fromRGB(235, 40, 40)
local function healthColor(f: number): Color3
	if f > 0.5 then return YELLOW:Lerp(GREEN, (f - 0.5) / 0.5) end
	return RED:Lerp(YELLOW, f / 0.5)
end

local function updateBar(e: Enemy)
	local f = math.clamp(e.Hp / e.MaxHp, 0, 1)
	e.Bar.Size = UDim2.fromScale(f, 1)
	e.Bar.BackgroundColor3 = healthColor(f)
	e.Model:SetAttribute("Hp", math.max(0, e.Hp))
	e.Model:SetAttribute("MaxHp", e.MaxHp)
	e.Model:SetAttribute("EnemyName", e.Name)
end

function EnemyService.Spawn(stage: number, spawnPart: BasePart, owner: Player)
	local st = Config.Stages[stage]
	local isBoss = spawnPart.Name == "Boss"
	local idx = tonumber(spawnPart.Name:sub(2)) or 1
	local variant = isBoss and 3 or ((idx - 1) % 3) + 1
	local name = isBoss and st.Boss or st.Enemies[variant]
	local model = buildRig(stage, variant, isBoss, name)
	if isBoss then model:ScaleTo(stage == Config.StageCount and 2.2 or 1.45) end
	local root = model:WaitForChild("HumanoidRootPart") :: BasePart
	model:PivotTo(CFrame.new(spawnPart.Position + Vector3.new(0, 4, 0)) * CFrame.Angles(0, math.pi / 2, 0))
	local hpMult = isBoss and (stage == Config.StageCount and Config.Economy.BossHpMult * 3 or Config.Economy.BossHpMult) or 1
	local e: Enemy = {
		Id = nextId, Model = model, Root = root, Hum = model:FindFirstChildOfClass("Humanoid") :: Humanoid, Stage = stage, IsBoss = isBoss, Name = name,
		MaxHp = st.EnemyHp * hpMult, Hp = st.EnemyHp * hpMult, Damage = st.EnemyDamage * (isBoss and 2 or 1),
		Credit = {}, RootedUntil = 0, NextAttack = os.clock() + 2, Home = spawnPart.Position, Dead = false,
		Bar = nil :: any, Burning = 0, SpawnName = spawnPart.Name, Owner = owner,
	}
	nextId += 1
	model:SetAttribute("EnemyId", e.Id)
	model:SetAttribute("OwnerId", owner.UserId)
	model.Name = name .. "_" .. owner.UserId
	model:SetAttribute("Stage", stage)
	model:SetAttribute("Boss", isBoss)
	model:SetAttribute("Element", st.Element)
	makeBillboard(e)
	updateBar(e)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then d.CollisionGroup = "Enemies" end
	end
	model.Parent = folder
	root:SetNetworkOwner(nil)
	EnemyService.Enemies[e.Id] = e
	byModel[model] = e
	local animator = e.Hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", e.Hum)
	local tracks = {}
	for key, attr in {Idle = "AnimIdle", Walk = "AnimWalk"} do
		local id = model:GetAttribute(attr)
		if typeof(id) == "string" and id ~= "" then
			local a = Instance.new("Animation"); a.AnimationId = id
			local ok, t = pcall(animator.LoadAnimation, animator, a)
			if ok and t then t.Looped = true; tracks[key] = t end
		end
	end
	e.Anim = tracks
	if tracks.Idle then tracks.Idle:Play(0.2) end
	return e
end

-- idle <-> walk from the root's real velocity (checked by the 10 Hz brain)
local function animate(e: Enemy)
	local t = e.Anim
	if not t or not t.Walk then return end
	local v = e.Root.AssemblyLinearVelocity
	local moving = Vector3.new(v.X, 0, v.Z).Magnitude > 1.5
	if moving and not t.Walk.IsPlaying then
		t.Walk:Play(0.15); t.Walk:AdjustSpeed(e.Hum.WalkSpeed / 16)
		if t.Idle then t.Idle:Stop(0.15) end
	elseif not moving and t.Walk.IsPlaying then
		t.Walk:Stop(0.2)
		if t.Idle then t.Idle:Play(0.2) end
	end
end

-- custom (non-stage) enemies, e.g. the lobby Kyubi raid boss. opts: {Name, MaxHp, Color, OnHit, OnKill}
function EnemyService.SpawnCustom(model: Model, opts: any): Enemy
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart
	local e: any = {
		Id = nextId, Model = model, Root = root, Hum = model:FindFirstChildOfClass("Humanoid"), Stage = 0, IsBoss = true, Name = opts.Name,
		MaxHp = opts.MaxHp, Hp = opts.MaxHp, Damage = 0, Credit = {}, RootedUntil = 0, NextAttack = math.huge, Home = root.Position,
		Dead = false, Burning = 0, SpawnName = "Custom", Custom = true, Color = opts.Color, OnHit = opts.OnHit, OnKill = opts.OnKill,
	}
	nextId += 1
	model:SetAttribute("EnemyId", e.Id)
	model:SetAttribute("Stage", 0)
	model:SetAttribute("Boss", true)
	makeBillboard(e)
	updateBar(e)
	model.Parent = folder
	EnemyService.Enemies[e.Id] = e
	byModel[model] = e
	return e
end

function EnemyService.Remove(e: Enemy)
	if e.Dead then return end
	e.Dead = true
	EnemyService.Enemies[e.Id] = nil
	byModel[e.Model] = nil
	e.Model:Destroy()
end

function EnemyService.FromModel(m: Instance?): Enemy?
	while m and m ~= workspace do
		if byModel[m :: Model] then return byModel[m :: Model] end
		m = m.Parent
	end
	return nil
end

local function stageFolder(stage: number)
	local course = workspace:FindFirstChild("StageCourse")
	return course and course:FindFirstChild(string.format("Stage%02d", stage))
end

local function ensureSet(owner: Player, stage: number)
	local key = setKey(owner, stage)
	if spawnedSets[key] then return end
	spawnedSets[key] = true
	local sf = stageFolder(stage)
	local spawns = sf and sf:FindFirstChild("EnemySpawns")
	if not spawns then spawnedSets[key] = nil; return end
	GameService.ResetStageKills(owner, stage) -- a fresh set: the gate opens when every enemy of THIS set is dead
	local hasBoss = Config.HasBoss(stage)
	local spawnList = spawns:GetChildren()
	table.sort(spawnList, function(a, b) return a.Name < b.Name end)
	for _, sp in spawnList do
		if sp:IsA("BasePart") and (sp.Name ~= "Boss" or hasBoss) then task.spawn(EnemyService.Spawn, stage, sp, owner) end
	end
end

local function despawnSet(ownerId: number, stage: number?)
	for key in spawnedSets do
		local uid, st = key:match("^(%d+):(%d+)$")
		if tonumber(uid) == ownerId and (stage == nil or tonumber(st) == stage) then spawnedSets[key] = nil end
	end
	for id, e in EnemyService.Enemies do
		if e.Owner and e.Owner.UserId == ownerId and (stage == nil or e.Stage == stage) then
			EnemyService.Enemies[id] = nil
			byModel[e.Model] = nil
			e.Dead = true
			e.Model:Destroy()
		end
	end
end

---------------------------------------------------------------- damage
EnemyService.OnPlayerHit = nil :: ((Player, number, Enemy) -> ())?
function EnemyService.Damage(e: Enemy, amount: number, player: Player?, knockback: Vector3?)
	if e.Dead or amount ~= amount or amount <= 0 then return end
	if player then
		-- players may only damage enemies in stages they have unlocked
		local hi = player:GetAttribute("Highest") or 1
		if e.Stage > hi then return end
		if e.Owner and e.Owner ~= player then return end -- someone else's enemy (invisible to this player)
		e.Credit[player] = true
		GameService.Remotes.DamageNumber:FireClient(player, e.Root.Position, amount)
	end
	e.Hp -= amount
	updateBar(e)
	local ex = e :: any
	if ex.OnHit and player then task.spawn(ex.OnHit, player, amount) end
	if knockback and not e.IsBoss then
		e.Root.AssemblyLinearVelocity = knockback
	end
	if e.Owner then GameService.Remotes.Vfx:FireClient(e.Owner, "Hit", e.Model) else GameService.Remotes.Vfx:FireAllClients("Hit", e.Model) end
	if e.Hp <= 0 then EnemyService.Kill(e) end
end

function EnemyService.Kill(e: Enemy)
	if e.Dead then return end
	e.Dead = true
	EnemyService.Enemies[e.Id] = nil
	byModel[e.Model] = nil
	local ex = e :: any
	if ex.Custom then
		GameService.Remotes.Vfx:FireAllClients("Death", e.Model.Name, e.Root.Position, ex.Color or Color3.new(1, 0.5, 0.1))
		e.Model:Destroy()
		if ex.OnKill then task.spawn(ex.OnKill, e) end
		return
	end
	local owner = e.Owner :: Player
	GameService.Remotes.Vfx:FireClient(owner, "Death", e.Model.Name, e.Root.Position, Config.Stages[e.Stage].Gate)
	if owner.Parent and e.Credit[owner] then GameService.CreditKill(owner, e.Stage, e.IsBoss) end
	e.Model:Destroy()
	-- no respawns (owner request): once a player's set is dead the stage stays clear so they can move on.
	-- The set only comes back after the player has been away from the stage for a while (despawnSet -> ensureSet).
end

local function visibleTo(e: Enemy, viewer: Player?): boolean
	return viewer == nil or e.Owner == nil or e.Owner == viewer
end
EnemyService.VisibleTo = visibleTo

function EnemyService.InRadius(pos: Vector3, radius: number, stageHint: number?, viewer: Player?): {Enemy}
	local out = {}
	for _, e in EnemyService.Enemies do
		if not e.Dead and visibleTo(e, viewer) and (e.Root.Position - pos).Magnitude <= radius + (e.IsBoss and 3 or 1.5) then table.insert(out, e) end
	end
	return out
end

function EnemyService.Nearest(pos: Vector3, range: number, facing: Vector3?, viewer: Player?): Enemy?
	local best, bestScore = nil, math.huge
	for _, e in EnemyService.Enemies do
		if not e.Dead and visibleTo(e, viewer) then
			local d = e.Root.Position - pos
			local dist = d.Magnitude
			if dist <= range then
				local score = dist
				if facing and dist > 0 then score = dist * (1.6 - 0.6 * facing:Dot(d.Unit)) end
				if score < bestScore then best, bestScore = e, score end
			end
		end
	end
	return best
end

---------------------------------------------------------------- player damage hook (shields, susanoo etc.)
EnemyService.DamageReduction = nil :: ((Player) -> number)?
local function hurtPlayer(player: Player, hum: Humanoid, amount: number)
	local red = EnemyService.DamageReduction and EnemyService.DamageReduction(player) or 0
	if red >= 1 then return end
	hum:TakeDamage(amount * (1 - red))
end

---------------------------------------------------------------- brains (10 Hz, only for active stages)
local function playerStage(p: Player): number? return p:GetAttribute("InStage") :: number? end

local function think(e: Enemy, now: number)
	if e.Dead or not e.Root.Parent then return end
	animate(e)
	if now < e.RootedUntil then
		e.Hum:MoveTo(e.Root.Position)
		return
	end
	-- leash
	if (e.Root.Position - e.Home).Magnitude > 55 then
		e.Hum:MoveTo(e.Home)
		return
	end
	-- an enemy only ever chases / hits its owner
	local target, tdist = nil, math.huge
	local owner = e.Owner
	if owner and owner.Parent then
		local char = owner.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hrp and hum and hum.Health > 0 and playerStage(owner) == e.Stage then
			local d = (hrp.Position - e.Root.Position).Magnitude
			if d < (e.IsBoss and 34 or 24) then target, tdist = owner, d end -- 85-stud stages: only nearby enemies aggro
		end
	end
	if not target then
		if (e.Root.Position - e.Home).Magnitude > 4 then e.Hum:MoveTo(e.Home) end
		return
	end
	local hrp = (target.Character :: Model):FindFirstChild("HumanoidRootPart") :: BasePart
	local hum = (target.Character :: Model):FindFirstChildOfClass("Humanoid") :: Humanoid
	-- melee reach is measured flat (XZ) root to root; R15 bodies are ~2 studs wide so 4.5 studs is fists touching
	-- (the old 5.5 + 2 grace = 7.5 studs is why enemies hit players from afar)
	local reach = e.IsBoss and (e.Stage == Config.StageCount and 8 or 6.5) or 4.5
	local flat = Vector3.new(hrp.Position.X - e.Root.Position.X, 0, hrp.Position.Z - e.Root.Position.Z)
	tdist = flat.Magnitude
	if tdist > reach - 1 then
		local destination = hrp.Position - (tdist > 0.1 and flat.Unit or Vector3.zero) * (reach - 1.5)
		-- Local separation prevents all five non-colliding rigs occupying one point.
		local separation = Vector3.zero
		for _, other in EnemyService.Enemies do
			if other ~= e and other.Owner == owner and other.Stage == e.Stage and not other.Dead then
				local delta = e.Root.Position - other.Root.Position
				local d = Vector3.new(delta.X, 0, delta.Z)
				if d.Magnitude < 4 then
					local direction = d.Magnitude > 0.1 and d.Unit or Vector3.new(0, 0, e.Id < other.Id and -1 or 1)
					separation += direction * (4 - d.Magnitude)
				end
			end
		end
		if separation.Magnitude > 4 then separation = separation.Unit * 4 end
		e.Hum:MoveTo(destination + separation)
	else
		e.Hum:MoveTo(e.Root.Position)
		if tdist > 0.1 then e.Root.CFrame = CFrame.lookAt(e.Root.Position, e.Root.Position + flat) end -- face the player
	end
	-- final boss: three phases (projectile patterns at 66%, ultimate + faster attacks at 33%)
	if e.Stage == Config.StageCount and e.IsBoss then
		local ex = e :: any
		local st = Config.Stages[e.Stage]
		local frac = e.Hp / e.MaxHp
		local phase = frac > 0.66 and 1 or (frac > 0.33 and 2 or 3)
		if ex.Phase ~= phase then
			ex.Phase = phase
			e.Model:SetAttribute("Phase", phase)
			if phase > 1 then
				GameService.Remotes.Vfx:FireClient(target, "Explosion", "GiantRasengan", e.Root.Position, 16)
				GameService.Notify(target, "BossPhase", phase)
			end
		end
		if phase >= 2 and now >= (ex.NextPattern or 0) then
			ex.NextPattern = now + (phase == 3 and 4 or 6)
			local count = phase == 3 and 6 or 4
			local center = hrp.Position
			for k = 1, count do
				local a = (k / count) * math.pi * 2 + now
				local at = center + Vector3.new(math.cos(a) * 10, 0, math.sin(a) * 10)
				GameService.Remotes.Vfx:FireClient(target, "BossBlast", e.Model, at, st.Element, st.Gate)
				task.delay(1, function()
					if e.Dead then return end
					for _, p in {target} do
						local c = p.Character
						local r = c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
						local h = c and c:FindFirstChildOfClass("Humanoid")
						if r and h and h.Health > 0 and playerStage(p) == e.Stage and (r.Position - at).Magnitude < 9 then hurtPlayer(p, h, e.Damage) end
					end
				end)
			end
		end
		if phase == 3 and now >= (ex.NextUlt or 0) then
			ex.NextUlt = now + 10
			local at = e.Root.Position
			GameService.Remotes.Vfx:FireClient(target, "Telegraph", "TailedBeastBomb", at, 30, 1.8)
			task.delay(1.8, function()
				if e.Dead then return end
				GameService.Remotes.Vfx:FireClient(target, "Explosion", "TailedBeastBomb", at, 30)
				for _, p in {target} do
					local c = p.Character
					local r = c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
					local h = c and c:FindFirstChildOfClass("Humanoid")
					if r and h and h.Health > 0 and playerStage(p) == e.Stage and (r.Position - at).Magnitude < 30 then
						hurtPlayer(p, h, e.Damage * 2.5)
						-- characters are client-owned, so the owner applies the knockback
						local dir = Vector3.new(r.Position.X - at.X, 0, r.Position.Z - at.Z)
						GameService.Remotes.Vfx:FireClient(p, "Knock", (dir.Magnitude > 0.1 and dir.Unit or Vector3.xAxis) * 90 + Vector3.new(0, 45, 0))
					end
				end
			end)
		end
		if phase == 3 and e.NextAttack - now > 1.2 then e.NextAttack = now + 1.2 end
	end
	if now >= e.NextAttack then
		local st = Config.Stages[e.Stage]
		if tdist <= reach then
			e.NextAttack = now + (e.IsBoss and 1.8 or 1.9)
			e.Model:SetAttribute("AttackAt", workspace:GetServerTimeNow())
			GameService.Remotes.Vfx:FireClient(target, "EnemyMelee", e.Model, st.Element)
			task.delay(0.25, function()
				if e.Dead or hum.Health <= 0 or target.Character ~= hum.Parent or playerStage(target) ~= e.Stage then return end
				-- the hit only lands if the player is still in reach, in front of the enemy and at the same height
				local d = hrp.Position - e.Root.Position
				local fl = Vector3.new(d.X, 0, d.Z)
				local inFront = fl.Magnitude < 1 or e.Root.CFrame.LookVector:Dot(fl.Unit) > 0.25
				if fl.Magnitude <= reach + 0.75 and math.abs(d.Y) < 5 and inFront then hurtPlayer(target, hum, e.Damage) end
			end)
		elseif e.IsBoss and tdist < 50 then
			-- boss ranged elemental blast, telegraphed
			e.NextAttack = now + 3.5
			local at = hrp.Position
			GameService.Remotes.Vfx:FireClient(target, "BossBlast", e.Model, at, st.Element, st.Gate)
			task.delay(1, function()
				if e.Dead then return end
				for _, p in {target} do
					local c = p.Character
					local r = c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
					local h = c and c:FindFirstChildOfClass("Humanoid")
					if r and h and h.Health > 0 and playerStage(p) == e.Stage and (r.Position - at).Magnitude < 12 then hurtPlayer(p, h, e.Damage * 1.5) end
				end
			end)
			if e.Stage == Config.StageCount and math.random() < 0.4 then
				-- final boss teleports behind the player
				task.delay(1.2, function()
					if e.Dead or not hrp.Parent or target.Character ~= hrp.Parent or playerStage(target) ~= e.Stage then return end
					GameService.Remotes.Vfx:FireClient(target, "Flicker", e.Root.Position, st.Gate)
					e.Root.CFrame = hrp.CFrame * CFrame.new(0, 0, 8)
				end)
			end
		end
	end
end

function EnemyService.Start()
	local PhysicsService = game:GetService("PhysicsService")
	pcall(function() PhysicsService:RegisterCollisionGroup("Enemies") end)
	pcall(function() PhysicsService:RegisterCollisionGroup("Players") end)
	PhysicsService:CollisionGroupSetCollidable("Enemies", "Players", false)
	PhysicsService:CollisionGroupSetCollidable("Enemies", "Enemies", false)
	Players.PlayerAdded:Connect(function(p)
		p.CharacterAdded:Connect(function(c)
			task.wait()
			for _, d in c:GetDescendants() do if d:IsA("BasePart") then d.CollisionGroup = "Players" end end
			c.DescendantAdded:Connect(function(d) if d:IsA("BasePart") then d.CollisionGroup = "Players" end end)
		end)
	end)
	-- activation: each player gets their own enemies for their current stage (and the next unlocked one, so it is
	-- already populated when they walk through the gate); a player's sets despawn 20 s after they leave
	local emptySince: {[string]: number} = {}
	Players.PlayerRemoving:Connect(function(p) despawnSet(p.UserId, nil) end)
	task.spawn(function()
		while true do
			task.wait(0.5)
			local want: {[string]: boolean} = {}
			for _, p in Players:GetPlayers() do
				local s = playerStage(p)
				if s and not p:GetAttribute("InLobby") then
					want[setKey(p, s)] = true
					ensureSet(p, s)
					if s + 1 <= Config.StageCount and s + 1 <= (p:GetAttribute("Highest") or 1) then
						want[setKey(p, s + 1)] = true
						ensureSet(p, s + 1)
					end
				end
			end
			for key in want do emptySince[key] = nil end
			for key in spawnedSets do
				if not want[key] then
					emptySince[key] = emptySince[key] or os.clock()
					if os.clock() - emptySince[key] > 20 then
						local uid, st = key:match("^(%d+):(%d+)$")
						despawnSet(tonumber(uid) :: number, tonumber(st))
						emptySince[key] = nil
					end
				end
			end
			activeKeys = want
		end
	end)
	task.spawn(function()
		while true do
			task.wait(0.1)
			local now = os.clock()
			for _, e in EnemyService.Enemies do
				if e.Owner == nil or activeKeys[setKey(e.Owner, e.Stage)] then
					local ok, err = pcall(think, e, now)
					if not ok then warn("[EnemyService]", err) end
				end
			end
		end
	end)
end

return EnemyService
