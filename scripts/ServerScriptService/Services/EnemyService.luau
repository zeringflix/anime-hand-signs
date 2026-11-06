--!strict
-- Server-authoritative stage enemies. 10 Hz brains, distance-gated per stage (LihFolk: NPC AI and Behaviour).
-- HP lives in this table (not Humanoid.Health) so huge late-game numbers stay exact.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local GameService = require(script.Parent.GameService)

local EnemyService = {}
export type Enemy = {Id: number, Model: Model, Root: BasePart, Hum: Humanoid, Stage: number, IsBoss: boolean, Name: string,
	MaxHp: number, Hp: number, Damage: number, Credit: {[Player]: boolean}, RootedUntil: number, NextAttack: number,
	Home: Vector3, Dead: boolean, Bar: Frame, HpText: TextLabel, Burning: number, SpawnName: string}
EnemyService.Enemies = {} :: {[number]: Enemy}
local byModel: {[Model]: Enemy} = {}
local nextId = 1
local folder = Instance.new("Folder")
folder.Name = "Enemies"
folder.Parent = workspace
local activeStages: {[number]: boolean} = {}
local spawnedStages: {[number]: boolean} = {}

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
		-- hood + mask
		weldPart(model, head, Vector3.new(1.45, 1.35, 1.45), CFrame.new(0, 0.12, 0.08), outfit)
		weldPart(model, head, Vector3.new(1.05, 0.45, 0.1), CFrame.new(0, -0.25, -0.62), Color3.fromRGB(30, 30, 35))
	else
		-- straw hat / animal mask
		weldPart(model, head, Vector3.new(2.6, 0.25, 2.6), CFrame.new(0, 0.75, 0), Color3.fromRGB(200, 170, 100))
		weldPart(model, head, Vector3.new(1, 0.5, 1), CFrame.new(0, 1, 0), Color3.fromRGB(190, 160, 90))
		weldPart(model, head, Vector3.new(0.95, 0.75, 0.1), CFrame.new(0, -0.05, -0.62), Color3.fromRGB(245, 245, 245))
	end
	if isBoss then
		weldPart(model, torso, Vector3.new(2.4, 3, 0.2), CFrame.new(0, -1.2, 0.7) * CFrame.Angles(0.15, 0, 0), st.Gate)
		local aura = Instance.new("ParticleEmitter")
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
	hum.WalkSpeed = isBoss and 13 or 15
	local animate = model:FindFirstChild("Animate")
	if animate then animate:Destroy() end
	return model
end

local function makeBillboard(e: Enemy)
	local bb = Instance.new("BillboardGui")
	bb.Name = "Info"
	bb.Size = UDim2.fromOffset(170, 44)
	bb.StudsOffsetWorldSpace = Vector3.new(0, e.IsBoss and 4.6 or 3.4, 0)
	bb.MaxDistance = 120
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
	fill.BackgroundColor3 = e.IsBoss and Color3.fromRGB(255, 70, 70) or Color3.fromRGB(80, 230, 80)
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
	fill.Parent = back
	local txt = Instance.new("TextLabel")
	txt.BackgroundTransparency = 1
	txt.Size = UDim2.fromScale(1, 1)
	txt.Font = Enum.Font.FredokaOne
	txt.TextScaled = true
	txt.TextColor3 = Color3.new(1, 1, 1)
	txt.ZIndex = 2
	local s2 = Instance.new("UIStroke"); s2.Thickness = 1.5; s2.Parent = txt
	txt.Parent = back
	back.Parent = bb
	bb.Parent = e.Root
	e.Bar = fill
	e.HpText = txt
end

local function updateBar(e: Enemy)
	local f = math.clamp(e.Hp / e.MaxHp, 0, 1)
	e.Bar.Size = UDim2.fromScale(f, 1)
	e.HpText.Text = Config.Format(math.ceil(e.Hp)) .. " / " .. Config.Format(e.MaxHp)
	e.Model:SetAttribute("Hp", math.max(0, e.Hp))
	e.Model:SetAttribute("MaxHp", e.MaxHp)
	e.Model:SetAttribute("EnemyName", e.Name)
end

function EnemyService.Spawn(stage: number, spawnPart: BasePart)
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
		Bar = nil :: any, HpText = nil :: any, Burning = 0, SpawnName = spawnPart.Name,
	}
	nextId += 1
	model:SetAttribute("EnemyId", e.Id)
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
	return e
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

local function ensureStage(stage: number)
	if spawnedStages[stage] then return end
	spawnedStages[stage] = true
	local sf = stageFolder(stage)
	local spawns = sf and sf:FindFirstChild("EnemySpawns")
	if not spawns then return end
	for _, sp in spawns:GetChildren() do
		if sp:IsA("BasePart") then task.spawn(EnemyService.Spawn, stage, sp) end
	end
end

local function despawnStage(stage: number)
	if not spawnedStages[stage] then return end
	spawnedStages[stage] = nil
	for id, e in EnemyService.Enemies do
		if e.Stage == stage then
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
	GameService.Remotes.Vfx:FireAllClients("Hit", e.Model)
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
	GameService.Remotes.Vfx:FireAllClients("Death", e.Model.Name, e.Root.Position, Config.Stages[e.Stage].Gate)
	for player in e.Credit do
		if player.Parent then GameService.CreditKill(player, e.Stage, e.IsBoss) end
	end
	e.Model:Destroy()
	local stage = e.Stage
	local spawnName = e.SpawnName
	task.delay(e.IsBoss and 6 or 3, function()
		if not spawnedStages[stage] then return end
		local sf = stageFolder(stage)
		local sp = sf and sf:FindFirstChild("EnemySpawns") and (sf :: any).EnemySpawns:FindFirstChild(spawnName)
		if sp then EnemyService.Spawn(stage, sp) end
	end)
end

function EnemyService.InRadius(pos: Vector3, radius: number, stageHint: number?): {Enemy}
	local out = {}
	for _, e in EnemyService.Enemies do
		if not e.Dead and (e.Root.Position - pos).Magnitude <= radius + (e.IsBoss and 3 or 1.5) then table.insert(out, e) end
	end
	return out
end

function EnemyService.Nearest(pos: Vector3, range: number, facing: Vector3?): Enemy?
	local best, bestScore = nil, math.huge
	for _, e in EnemyService.Enemies do
		if not e.Dead then
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
	if now < e.RootedUntil then
		e.Hum:MoveTo(e.Root.Position)
		return
	end
	-- leash
	if (e.Root.Position - e.Home).Magnitude > 55 then
		e.Hum:MoveTo(e.Home)
		return
	end
	local target, tdist = nil, math.huge
	for _, p in Players:GetPlayers() do
		local char = p.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hrp and hum and hum.Health > 0 and playerStage(p) == e.Stage then
			local d = (hrp.Position - e.Root.Position).Magnitude
			if d < tdist and d < (e.IsBoss and 60 or 38) then target, tdist = p, d end
		end
	end
	if not target then
		if (e.Root.Position - e.Home).Magnitude > 4 then e.Hum:MoveTo(e.Home) end
		return
	end
	local hrp = (target.Character :: Model):FindFirstChild("HumanoidRootPart") :: BasePart
	local hum = (target.Character :: Model):FindFirstChildOfClass("Humanoid") :: Humanoid
	local reach = e.IsBoss and 9 or 5.5
	if tdist > reach then
		e.Hum:MoveTo(hrp.Position)
	else
		e.Hum:MoveTo(e.Root.Position)
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
				GameService.Remotes.Vfx:FireAllClients("Explosion", "GiantRasengan", e.Root.Position, 16)
				for _, p in Players:GetPlayers() do if playerStage(p) == e.Stage then GameService.Notify(p, "BossPhase", phase) end end
			end
		end
		if phase >= 2 and now >= (ex.NextPattern or 0) then
			ex.NextPattern = now + (phase == 3 and 4 or 6)
			local count = phase == 3 and 6 or 4
			local center = hrp.Position
			for k = 1, count do
				local a = (k / count) * math.pi * 2 + now
				local at = center + Vector3.new(math.cos(a) * 10, 0, math.sin(a) * 10)
				GameService.Remotes.Vfx:FireAllClients("BossBlast", e.Model, at, st.Element, st.Gate)
				task.delay(1, function()
					if e.Dead then return end
					for _, p in Players:GetPlayers() do
						local c = p.Character
						local r = c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
						local h = c and c:FindFirstChildOfClass("Humanoid")
						if r and h and (r.Position - at).Magnitude < 9 then hurtPlayer(p, h, e.Damage) end
					end
				end)
			end
		end
		if phase == 3 and now >= (ex.NextUlt or 0) then
			ex.NextUlt = now + 10
			local at = e.Root.Position
			GameService.Remotes.Vfx:FireAllClients("Telegraph", "TailedBeastBomb", at, 30, 1.8)
			task.delay(1.8, function()
				if e.Dead then return end
				GameService.Remotes.Vfx:FireAllClients("Explosion", "TailedBeastBomb", at, 30)
				for _, p in Players:GetPlayers() do
					local c = p.Character
					local r = c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
					local h = c and c:FindFirstChildOfClass("Humanoid")
					if r and h and (r.Position - at).Magnitude < 30 then
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
			e.NextAttack = now + (e.IsBoss and 1.6 or 1.4)
			e.Model:SetAttribute("AttackAt", workspace:GetServerTimeNow())
			GameService.Remotes.Vfx:FireAllClients("EnemyMelee", e.Model, st.Element)
			task.delay(0.25, function()
				if e.Dead or hum.Health <= 0 then return end
				if (hrp.Position - e.Root.Position).Magnitude <= reach + 2 then hurtPlayer(target, hum, e.Damage) end
			end)
		elseif e.IsBoss and tdist < 50 then
			-- boss ranged elemental blast, telegraphed
			e.NextAttack = now + 3.5
			local at = hrp.Position
			GameService.Remotes.Vfx:FireAllClients("BossBlast", e.Model, at, st.Element, st.Gate)
			task.delay(1, function()
				if e.Dead then return end
				for _, p in Players:GetPlayers() do
					local c = p.Character
					local r = c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
					local h = c and c:FindFirstChildOfClass("Humanoid")
					if r and h and (r.Position - at).Magnitude < 12 then hurtPlayer(p, h, e.Damage * 1.5) end
				end
			end)
			if e.Stage == Config.StageCount and math.random() < 0.4 then
				-- final boss teleports behind the player
				task.delay(1.2, function()
					if e.Dead or not hrp.Parent then return end
					GameService.Remotes.Vfx:FireAllClients("Flicker", e.Root.Position, st.Gate)
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
	-- activation: spawn enemies only in stages with players nearby, despawn after they leave
	local emptySince: {[number]: number} = {}
	task.spawn(function()
		while true do
			task.wait(0.5)
			local want: {[number]: boolean} = {}
			for _, p in Players:GetPlayers() do
				local s = playerStage(p)
				if s then
					want[s] = true
					if s + 1 <= Config.StageCount and s + 1 <= (p:GetAttribute("Highest") or 1) then want[s + 1] = true end
				end
			end
			for s in want do emptySince[s] = nil; ensureStage(s) end
			for s in spawnedStages do
				if not want[s] then
					emptySince[s] = emptySince[s] or os.clock()
					if os.clock() - emptySince[s] > 20 then despawnStage(s); emptySince[s] = nil end
				end
			end
			activeStages = want
		end
	end)
	task.spawn(function()
		while true do
			task.wait(0.1)
			local now = os.clock()
			for _, e in EnemyService.Enemies do
				if activeStages[e.Stage] then
					local ok, err = pcall(think, e, now)
					if not ok then warn("[EnemyService]", err) end
				end
			end
		end
	end)
end

return EnemyService
