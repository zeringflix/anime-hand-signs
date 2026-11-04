--!strict
-- M1 + the 28 hand-sign jutsu. Server decides targets, hits, damage and cooldowns; clients only draw.
-- Cooldowns are stored per JUTSU (not per slot), so swapping signs can never reset them.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local DataService = require(script.Parent.DataService)
local GameService = require(script.Parent.GameService)
local EnemyService = require(script.Parent.EnemyService)

local AbilityService = {}
local R = GameService.Remotes
type Enemy = EnemyService.Enemy

local cooldowns: {[Player]: {[string]: number}} = {}
local slotLockUntil: {[Player]: number} = {}
local buffs: {[Player]: {Invuln: number, Shield: number, Susanoo: number, Walls: {BasePart}}} = {}
local summons: {[Player]: {Model}} = {}
local M1_RANGE = 16
local M1_COOLDOWN = 0.32
local TOLERANCE = 0.12

local function getBuffs(p: Player)
	local b = buffs[p]
	if not b then b = {Invuln = 0, Shield = 0, Susanoo = 0, Walls = {}}; buffs[p] = b end
	return b
end

EnemyService.DamageReduction = function(p: Player): number
	local b = buffs[p]
	if not b then return 0 end
	local now = os.clock()
	if now < b.Invuln then return 1 end
	local red = 0
	if now < b.Shield then red = math.max(red, 0.85) end
	if now < b.Susanoo then red = math.max(red, 0.7) end
	-- standing behind your own earth wall
	local char = p.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if hrp then
		for _, w in b.Walls do
			if w.Parent and (w.Position - hrp.Position).Magnitude < 16 then red = math.max(red, 0.6) end
		end
	end
	return red
end

local function rootOf(p: Player): (BasePart?, Humanoid?)
	local c = p.Character
	if not c then return nil, nil end
	local hrp = c:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = c:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.Health <= 0 then return nil, nil end
	return hrp, hum
end

function AbilityService.BaseDamage(p: Player): number
	local data = DataService.Get(p)
	if not data then return 0 end
	return Config.DamageForPower(data.HandSigns, data.Level, 1 + 0.2 * GameService.UpgradeLevel(data, "JutsuDamage"))
end

local function flat(v: Vector3): Vector3
	local f = Vector3.new(v.X, 0, v.Z)
	return f.Magnitude > 0.01 and f.Unit or Vector3.new(0, 0, -1)
end

local function knock(from: Vector3, e: Enemy, power: number): Vector3
	return flat(e.Root.Position - from) * power + Vector3.new(0, power * 0.5, 0)
end

local function vfx(...) R.Vfx:FireAllClients(...) end

---------------------------------------------------------------- M1 basic attack
local lastM1: {[Player]: number} = {}
R.Attack.OnServerEvent:Connect(function(p: Player)
	if not GameService.RateOk(p, "m1", 5) then return end
	local now = os.clock()
	if now - (lastM1[p] or 0) < M1_COOLDOWN - TOLERANCE then return end
	lastM1[p] = now
	local hrp = rootOf(p)
	if not hrp then return end
	local target = EnemyService.Nearest(hrp.Position, M1_RANGE, hrp.CFrame.LookVector, p)
	p.Character:SetAttribute("PunchAt", workspace:GetServerTimeNow())
	if not target then return end
	local dmg = AbilityService.BaseDamage(p)
	vfx("Punch", p.Character, target.Root.Position)
	EnemyService.Damage(target, dmg, p, knock(hrp.Position, target, 18))
	GameService.AddXP(p, 0.25)
end)

---------------------------------------------------------------- mechanic implementations
local K = {}

-- single homing projectile with small splash
function K.projectile(p, j, hrp, target, dmg)
	if not target then return false end
	local dist = (target.Root.Position - hrp.Position).Magnitude
	vfx("Projectile", j.Id, hrp.Position, target.Model, j.Speed)
	task.delay(dist / j.Speed, function()
		if target.Dead then return end
		vfx("Impact", j.Id, target.Root.Position, j.Radius)
		for _, e in EnemyService.InRadius(target.Root.Position, j.Radius, nil, p) do EnemyService.Damage(e, dmg * (e == target and 1 or 0.5), p, knock(hrp.Position, e, 25)) end
	end)
	return true
end

-- several projectiles distributed over nearby enemies
function K.multiprojectile(p, j, hrp, target, dmg)
	if not target then return false end
	local list = EnemyService.InRadius(hrp.Position, j.Range, nil, p)
	table.sort(list, function(a, b) return (a.Root.Position - hrp.Position).Magnitude < (b.Root.Position - hrp.Position).Magnitude end)
	for i = 1, j.Count do
		local e = list[((i - 1) % #list) + 1]
		task.delay((i - 1) * 0.07, function()
			if e.Dead or not hrp.Parent then return end
			vfx("Projectile", j.Id, hrp.Position + Vector3.new(math.random(-3, 3), math.random(0, 3), math.random(-3, 3)), e.Model, j.Speed)
			task.delay((e.Root.Position - hrp.Position).Magnitude / j.Speed, function()
				if e.Dead then return end
				vfx("Impact", j.Id, e.Root.Position, j.Radius)
				EnemyService.Damage(e, dmg, p, knock(hrp.Position, e, 10))
			end)
		end)
	end
	return true
end

-- charge then lunge into the target (Rasengan, Chidori)
function K.dash(p, j, hrp, target, dmg)
	if not target then return false end
	vfx("Charge", j.Id, p.Character, 0.35)
	task.delay(0.35, function()
		if target.Dead or rootOf(p) ~= hrp or p:GetAttribute("InLobby") or target.Stage ~= p:GetAttribute("InStage") then return end
		local tp = target.Root.Position
		local dir = flat(tp - hrp.Position)
		vfx("Dash", j.Id, hrp.Position, tp - dir * 3)
		hrp.CFrame = CFrame.lookAt(tp - dir * 3.5, tp - dir * 3.5 + dir)
		vfx("Impact", j.Id, tp, j.Radius)
		for _, e in EnemyService.InRadius(tp, j.Radius, nil, p) do EnemyService.Damage(e, dmg * (e == target and 1 or 0.6), p, knock(hrp.Position, e, 55)) end
	end)
	return true
end

-- temporary combat clones (strictly limited count, timed cleanup)
local function cloneModel(p: Player): Model?
	local char = p.Character
	if not char then return nil end
	local wasArchivable = char.Archivable
	char.Archivable = true
	local c = char:Clone()
	char.Archivable = wasArchivable
	if not c then return nil end
	for _, d in c:GetDescendants() do
		if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") then d:Destroy()
		elseif d:IsA("BasePart") then d.CollisionGroup = "Enemies"; d.CanQuery = false end
	end
	c.Name = p.Name .. "_Clone"
	local hum = c:FindFirstChildOfClass("Humanoid")
	if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None; hum.WalkSpeed = 24 end
	c:SetAttribute("IsClone", true)
	return c
end
function K.clones(p, j, hrp, target, dmg)
	local list = summons[p] or {}
	summons[p] = list
	for _, m in list do if m.Parent then m:Destroy() end end
	table.clear(list)
	vfx("Smoke", hrp.Position, j.Count)
	for i = 1, j.Count do
		local c = cloneModel(p)
		if not c then break end
		local ang = (i / j.Count) * math.pi * 2
		c:PivotTo(hrp.CFrame * CFrame.new(math.cos(ang) * 5, 0, math.sin(ang) * 5))
		c.Parent = workspace
		;(c.PrimaryPart :: BasePart):SetNetworkOwner(nil)
		table.insert(list, c)
		vfx("Smoke", (c.PrimaryPart :: BasePart).Position, 1)
		task.spawn(function()
			local stop = os.clock() + j.Duration
			local hum = c:FindFirstChildOfClass("Humanoid")
			while c.Parent and rootOf(p) == hrp and not p:GetAttribute("InLobby") and os.clock() < stop do
				local croot = c.PrimaryPart :: BasePart
				local e = EnemyService.Nearest(croot.Position, j.Range, nil, p)
				if e and hum then
					if (e.Root.Position - croot.Position).Magnitude > 5 then
						hum:MoveTo(e.Root.Position)
					else
						c:SetAttribute("PunchAt", workspace:GetServerTimeNow())
						vfx("Punch", c, e.Root.Position)
						EnemyService.Damage(e, dmg, p, knock(croot.Position, e, 12))
					end
				elseif hum and hrp.Parent then
					hum:MoveTo(hrp.Position + Vector3.new(math.random(-6, 6), 0, math.random(-6, 6)))
				end
				task.wait(0.6)
			end
			if c.Parent then vfx("Smoke", (c.PrimaryPart :: BasePart).Position, 1); c:Destroy() end
		end)
	end
	return true
end

-- instant line (snake hands, dragon flame)
function K.beam(p, j, hrp, target, dmg)
	local dir = target and flat(target.Root.Position - hrp.Position) or flat(hrp.CFrame.LookVector)
	local from = hrp.Position
	vfx("Beam", j.Id, from, dir, j.Range)
	task.delay(0.2, function()
		for _, e in EnemyService.InRadius(from, j.Range, nil, p) do
			local rel = e.Root.Position - from
			local along = rel:Dot(dir)
			if along > 0 and (rel - dir * along).Magnitude <= j.Radius + 2 then EnemyService.Damage(e, dmg, p, dir * 30) end
		end
	end)
	return true
end

-- every enemy inside a frontal cone
function K.cone(p, j, hrp, target, dmg)
	local dir = target and flat(target.Root.Position - hrp.Position) or flat(hrp.CFrame.LookVector)
	local from = hrp.Position
	local cosA = math.cos(math.rad(j.Radius / 2))
	vfx("Cone", j.Id, from, dir, j.Range, j.Radius, j.Count)
	task.delay(0.25, function()
		for _, e in EnemyService.InRadius(from, j.Range, nil, p) do
			local rel = e.Root.Position - from
			if rel.Magnitude < 4 or flat(rel):Dot(dir) >= cosA then EnemyService.Damage(e, dmg, p, knock(from, e, j.Id == "GreatBreakthrough" and 90 or 35)) end
		end
	end)
	return true
end

-- bind target in place (shadow imitation)
function K.root(p, j, hrp, target, dmg)
	if not target then return false end
	vfx("Shadow", j.Id, hrp.Position, target.Model, j.Duration)
	task.delay(0.3, function()
		if target.Dead then return end
		target.RootedUntil = os.clock() + j.Duration
		target.Model:SetAttribute("RootedUntil", workspace:GetServerTimeNow() + j.Duration)
		EnemyService.Damage(target, dmg, p)
	end)
	return true
end

-- heavy single hit, doubled on bound targets (shadow strangle)
function K.execute(p, j, hrp, target, dmg)
	if not target then return false end
	local bound = os.clock() < target.RootedUntil
	vfx("Strangle", j.Id, target.Model, bound)
	task.delay(0.5, function()
		if target.Dead then return end
		target.RootedUntil = math.max(target.RootedUntil, os.clock() + 1)
		EnemyService.Damage(target, dmg * (bound and 2 or 1), p)
	end)
	return true
end

-- radial burst around the caster (chidori stream)
function K.aoe(p, j, hrp, target, dmg)
	vfx("Burst", j.Id, p.Character, j.Radius)
	task.delay(0.15, function()
		if not hrp.Parent then return end
		for _, e in EnemyService.InRadius(hrp.Position, j.Radius, nil, p) do
			e.RootedUntil = os.clock() + 0.8
			EnemyService.Damage(e, dmg, p, knock(hrp.Position, e, 40))
		end
	end)
	return true
end

-- substitution: untouchable, leave a log, reappear behind nearest enemy and counter
function K.evade(p, j, hrp, target, dmg)
	local b = getBuffs(p)
	b.Invuln = os.clock() + j.Duration
	vfx("Log", hrp.Position)
	local e = target or EnemyService.Nearest(hrp.Position, 40, nil, p)
	if e then
		task.delay(0.35, function()
			if e.Dead or not hrp.Parent then return end
			local behind = e.Root.CFrame * CFrame.new(0, 0, 4)
			hrp.CFrame = CFrame.lookAt(behind.Position, e.Root.Position)
			vfx("Impact", j.Id, e.Root.Position, 6)
			EnemyService.Damage(e, dmg, p, knock(hrp.Position, e, 30))
		end)
	end
	return true
end

-- body flicker: instant flash to target (validated: target must be in an unlocked stage)
function K.blink(p, j, hrp, target, dmg)
	if not target then return false end
	local from = hrp.Position
	local dir = flat(target.Root.Position - from)
	local dest = target.Root.Position - dir * 4
	vfx("Flicker", from, j.Color)
	hrp.CFrame = CFrame.lookAt(dest, dest + dir)
	vfx("Flicker", dest, j.Color)
	vfx("Impact", j.Id, target.Root.Position, 6)
	EnemyService.Damage(target, dmg, p, dir * 40)
	return true
end

-- summoning: a giant toad companion that slams enemies
local function buildToad(cf: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "SummonToad"
	local function bp(size, off, color, shape)
		local p = Instance.new("Part")
		p.Anchored = true; p.CanCollide = false; p.CanQuery = false
		p.Size = size; p.Color = color; p.Material = Enum.Material.SmoothPlastic
		if shape then p.Shape = shape end
		p.CFrame = cf * off
		p.Parent = m
		return p
	end
	local body = bp(Vector3.new(12, 8, 12), CFrame.new(0, 5, 0), Color3.fromRGB(230, 110, 40))
	m.PrimaryPart = body
	bp(Vector3.new(11, 3, 11), CFrame.new(0, 1.5, 0), Color3.fromRGB(250, 220, 170))
	bp(Vector3.new(3, 3, 3), CFrame.new(-3.5, 10, -4), Color3.fromRGB(255, 230, 60))
	bp(Vector3.new(3, 3, 3), CFrame.new(3.5, 10, -4), Color3.fromRGB(255, 230, 60))
	bp(Vector3.new(1.2, 1.6, 0.4), CFrame.new(-3.5, 10, -5.6), Color3.new(0, 0, 0))
	bp(Vector3.new(1.2, 1.6, 0.4), CFrame.new(3.5, 10, -5.6), Color3.new(0, 0, 0))
	bp(Vector3.new(10, 0.6, 0.4), CFrame.new(0, 3.5, -6.1), Color3.fromRGB(120, 40, 20))
	bp(Vector3.new(14, 1, 3), CFrame.new(0, 9.2, 2), Color3.fromRGB(80, 50, 120)) -- vest band
	for sx = -1, 1, 2 do bp(Vector3.new(4, 3, 5), CFrame.new(sx * 6, 1.5, -3), Color3.fromRGB(220, 100, 35)) end
	return m
end
function K.summon(p, j, hrp, target, dmg)
	local list = summons[p] or {}
	summons[p] = list
	local cf = CFrame.lookAt(hrp.Position + hrp.CFrame.RightVector * 9 - Vector3.new(0, 3, 0), hrp.Position + hrp.CFrame.RightVector * 9 + hrp.CFrame.LookVector - Vector3.new(0, 3, 0))
	local toad = buildToad(cf)
	toad.Parent = workspace
	table.insert(list, toad)
	vfx("Summon", cf.Position, 14)
	task.spawn(function()
		local stop = os.clock() + j.Duration
		while toad.Parent and os.clock() < stop do
			task.wait(1.3)
			if not toad.Parent then break end
			local pos = (toad.PrimaryPart :: BasePart).Position
			local e = EnemyService.Nearest(pos, j.Range, nil, p)
			if e then
				local land = e.Root.Position - Vector3.new(0, 3, 0)
				vfx("ToadHop", toad, land)
				toad:PivotTo(CFrame.lookAt(land, land + flat(land - pos)) * CFrame.new(0, 0, 0))
				for _, x in EnemyService.InRadius(land, 12, nil, p) do EnemyService.Damage(x, dmg, p, knock(land, x, 40)) end
			end
		end
		if toad.Parent then vfx("Smoke", (toad.PrimaryPart :: BasePart).Position, 4); toad:Destroy() end
	end)
	return true
end

-- earth wall: rises in front, knocks back, protects the caster
function K.wall(p, j, hrp, target, dmg)
	local b = getBuffs(p)
	local dir = target and flat(target.Root.Position - hrp.Position) or flat(hrp.CFrame.LookVector)
	local center = hrp.Position + dir * 8 - Vector3.new(0, hrp.Position.Y, 0)
	local w = Instance.new("Part")
	w.Name = "EarthWall"
	w.Anchored = true
	w.Size = Vector3.new(j.Radius * 2, 12, 3)
	w.CFrame = CFrame.lookAt(center + Vector3.new(0, 6, 0), center + Vector3.new(0, 6, 0) + dir)
	w.Color = Color3.fromRGB(140, 100, 60)
	w.Material = Enum.Material.Slate
	w.CollisionGroup = "Default"
	w.Parent = workspace
	table.insert(b.Walls, w)
	vfx("EarthWall", w)
	for _, e in EnemyService.InRadius(center, j.Radius + 4, nil, p) do EnemyService.Damage(e, dmg, p, dir * 70 + Vector3.new(0, 30, 0)) end
	task.delay(j.Duration, function()
		local i = table.find(b.Walls, w)
		if i then table.remove(b.Walls, i) end
		w:Destroy()
	end)
	return true
end

-- water wall: near-immunity + repelling pulses
function K.shield(p, j, hrp, target, dmg)
	local b = getBuffs(p)
	b.Shield = os.clock() + j.Duration
	p.Character:SetAttribute("ShieldUntil", workspace:GetServerTimeNow() + j.Duration)
	vfx("WaterWall", p.Character, j.Duration, j.Radius)
	task.spawn(function()
		for _ = 1, math.floor(j.Duration) do
			task.wait(1)
			if not hrp.Parent then break end
			for _, e in EnemyService.InRadius(hrp.Position, j.Radius, nil, p) do EnemyService.Damage(e, dmg, p, knock(hrp.Position, e, 35)) end
		end
	end)
	return true
end

-- piercing traveller: hits everything along its whole path (water dragon)
function K.piercing(p, j, hrp, target, dmg)
	local dir = target and flat(target.Root.Position - hrp.Position) or flat(hrp.CFrame.LookVector)
	local from = hrp.Position
	vfx("Traveller", j.Id, from, dir, j.Range, j.Speed)
	local hit: {[Enemy]: boolean} = {}
	task.spawn(function()
		local t0 = os.clock()
		while true do
			local travelled = (os.clock() - t0) * j.Speed
			if travelled > j.Range then break end
			local head = from + dir * travelled
			for _, e in EnemyService.InRadius(head, j.Radius, nil, p) do
				if not hit[e] then hit[e] = true; EnemyService.Damage(e, dmg, p, dir * 50 + Vector3.new(0, 25, 0)) end
			end
			task.wait(0.05)
		end
	end)
	return true
end

-- slow big projectile that detonates in a large sphere (rasenshuriken, beast bomb)
function K.bigprojectile(p, j, hrp, target, dmg)
	local dir = target and (target.Root.Position - hrp.Position) or hrp.CFrame.LookVector * j.Range * 0.6
	local dest = target and target.Root.Position or hrp.Position + dir
	local charge = j.Id == "TailedBeastBomb" and 1.1 or 0.6
	vfx("Charge", j.Id, p.Character, charge)
	task.delay(charge, function()
		if not hrp.Parent then return end
		local from = hrp.Position + Vector3.new(0, 2, 0)
		dest = target and not target.Dead and target.Root.Position or dest
		local t = (dest - from).Magnitude / j.Speed
		vfx("BigProjectile", j.Id, from, dest, t, j.Radius)
		task.delay(t, function()
			vfx("Explosion", j.Id, dest, j.Radius)
			for _, e in EnemyService.InRadius(dest, j.Radius, nil, p) do EnemyService.Damage(e, dmg, p, knock(dest, e, 80)) end
			-- rasenshuriken lingers as a cutting sphere
			if j.Id == "Rasenshuriken" then
				for _ = 1, 3 do
					task.wait(0.35)
					for _, e in EnemyService.InRadius(dest, j.Radius, nil, p) do EnemyService.Damage(e, dmg * 0.15, p) end
				end
			end
		end)
	end)
	return true
end

-- leap + area slam (giant rasengan)
function K.slam(p, j, hrp, target, dmg)
	local dest = target and target.Root.Position or hrp.Position + flat(hrp.CFrame.LookVector) * 15
	vfx("Charge", j.Id, p.Character, 0.5)
	task.delay(0.5, function()
		if not hrp.Parent then return end
		vfx("Leap", p.Character, hrp.Position, dest)
		task.wait(0.35)
		if not hrp.Parent then return end
		hrp.CFrame = CFrame.new(dest + Vector3.new(0, 3, 0)) * (hrp.CFrame - hrp.Position)
		vfx("Explosion", j.Id, dest, j.Radius)
		for _, e in EnemyService.InRadius(dest, j.Radius, nil, p) do EnemyService.Damage(e, dmg, p, knock(dest, e, 90)) end
	end)
	return true
end

-- telegraphed sky strike (kirin)
function K.strike(p, j, hrp, target, dmg)
	local dest = target and target.Root.Position or hrp.Position + flat(hrp.CFrame.LookVector) * 25
	dest = Vector3.new(dest.X, 0, dest.Z)
	vfx("Telegraph", j.Id, dest, j.Radius, j.Duration)
	task.delay(j.Duration, function()
		vfx("Explosion", j.Id, dest, j.Radius)
		for _, e in EnemyService.InRadius(dest, j.Radius, nil, p) do
			e.RootedUntil = os.clock() + 1.5
			EnemyService.Damage(e, dmg, p, Vector3.new(0, 40, 0))
		end
	end)
	return true
end

-- damage over time that sticks to everything near the focus (amaterasu)
function K.dot(p, j, hrp, target, dmg)
	if not target then return false end
	local victims = EnemyService.InRadius(target.Root.Position, j.Radius, nil, p)
	local ticks = math.floor(j.Duration / 0.5)
	for _, e in victims do
		vfx("Burn", j.Id, e.Model, j.Duration)
		task.spawn(function()
			for _ = 1, ticks do
				if e.Dead then break end
				EnemyService.Damage(e, dmg / ticks * 4, p)
				task.wait(0.5)
			end
		end)
	end
	return true
end

-- susanoo: armoured avatar, damage reduction + automatic sword swings
function K.transform(p, j, hrp, target, dmg)
	local b = getBuffs(p)
	b.Susanoo = os.clock() + j.Duration
	p.Character:SetAttribute("SusanooUntil", workspace:GetServerTimeNow() + j.Duration)
	vfx("Susanoo", p.Character, j.Duration)
	task.spawn(function()
		local stop = os.clock() + j.Duration
		while os.clock() < stop and rootOf(p) == hrp and not p:GetAttribute("InLobby") do
			task.wait(1)
			if rootOf(p) ~= hrp or p:GetAttribute("InLobby") then break end
			local e = EnemyService.Nearest(hrp.Position, j.Range, nil, p)
			if e then
				local dir = flat(e.Root.Position - hrp.Position)
				vfx("Swing", p.Character, dir)
				for _, x in EnemyService.InRadius(hrp.Position + dir * (j.Radius * 0.6), j.Radius, nil, p) do EnemyService.Damage(x, dmg, p, dir * 45) end
			end
		end
	end)
	return true
end

-- planetary devastation: pull enemies into a core, tick, then crush (bounded, no free physics)
function K.pull(p, j, hrp, target, dmg)
	local center = (target and target.Root.Position or hrp.Position + flat(hrp.CFrame.LookVector) * 20) + Vector3.new(0, 1, 0)
	vfx("Planetary", center, j.Radius, j.Duration)
	local victims = EnemyService.InRadius(center, j.Radius, nil, p)
	task.spawn(function()
		local steps = math.floor(j.Duration / 0.1)
		for s = 1, steps do
			for _, e in victims do
				if not e.Dead and not e.IsBoss then
					local pos = e.Root.Position
					local to = Vector3.new(center.X, pos.Y, center.Z)
					e.Root.CFrame = CFrame.new(pos:Lerp(to, 0.08)) * (e.Root.CFrame - pos)
					e.RootedUntil = os.clock() + 0.3
				end
			end
			if s % 5 == 0 then for _, e in victims do EnemyService.Damage(e, dmg * 0.05, p) end end
			task.wait(0.1)
		end
		vfx("Explosion", "PlanetaryDevastation", center, j.Radius * 0.6)
		for _, e in EnemyService.InRadius(center, j.Radius * 0.6, nil, p) do EnemyService.Damage(e, dmg * 0.7, p, Vector3.new(0, 60, 0)) end
	end)
	return true
end

---------------------------------------------------------------- cast entry
R.Cast.OnServerEvent:Connect(function(p: Player, slot: any)
	if not GameService.RateOk(p, "cast", 4) then return end
	if slot ~= "E" and slot ~= "R" then return end
	local data = DataService.Get(p)
	if not data then return end
	local sign = Config.HandSigns[data.EquippedHandSign]
	if not sign or not data.UnlockedHandSigns[sign.Id] then return end
	local jid = slot == "E" and sign.E or sign.R -- abilities are derived from the equipped sign, never sent by the client
	local j = Config.Jutsu[jid]
	local now = os.clock()
	if now < (slotLockUntil[p] or 0) then return end
	local cds = cooldowns[p] or {}
	cooldowns[p] = cds
	if now < (cds[jid] or 0) - TOLERANCE then return end
	local hrp = rootOf(p)
	if not hrp then return end
	local target = EnemyService.Nearest(hrp.Position, j.Range > 0 and j.Range or 30, hrp.CFrame.LookVector, p)
	local dmg = AbilityService.BaseDamage(p) * j.DamageMult
	local handler = K[j.Kind]
	if not handler then return end
	p.Character:SetAttribute("CastAt", workspace:GetServerTimeNow())
	p.Character:SetAttribute("CastJutsu", jid)
	local ok, used = pcall(handler, p, j, hrp, target, dmg)
	if not ok then warn("[AbilityService]", jid, used) return end
	if not used then
		GameService.Notify(p, "NoTarget", j.Short)
		return
	end
	local cd = j.Cooldown * (1 - math.min(0.4, 0.04 * GameService.UpgradeLevel(data, "Cooldown")))
	cds[jid] = now + cd
	GameService.Notify(p, "Cooldown", {Jutsu = jid, Ends = workspace:GetServerTimeNow() + cd, Duration = cd})
	GameService.AddXP(p, 1)
end)

GameService.OnEquipChanged[#GameService.OnEquipChanged + 1] = function(p: Player)
	-- short lock after swapping so rapid switching can't chain casts; per-jutsu cooldowns persist
	slotLockUntil[p] = os.clock() + 1.2
	local cds = cooldowns[p] or {}
	local out = {}
	for id, t in cds do if t > os.clock() then out[id] = workspace:GetServerTimeNow() + (t - os.clock()) end end
	GameService.Notify(p, "CooldownSync", out)
end

-- Temporary shields, transformations and companions belong to one character life.
local function clearCharacterEffects(p: Player)
	local b = buffs[p]
	if b then
		for _, wall in b.Walls do if wall.Parent then wall:Destroy() end end
	end
	buffs[p] = nil
	for _, model in summons[p] or {} do if model.Parent then model:Destroy() end end
	summons[p] = nil
end
local function watchCharacter(p: Player)
	p.CharacterRemoving:Connect(function() clearCharacterEffects(p) end)
end
Players.PlayerAdded:Connect(watchCharacter)
for _, p in Players:GetPlayers() do watchCharacter(p) end

Players.PlayerRemoving:Connect(function(p)
	clearCharacterEffects(p)
	cooldowns[p] = nil; slotLockUntil[p] = nil; lastM1[p] = nil
end)

function AbilityService.Start() end
return AbilityService
