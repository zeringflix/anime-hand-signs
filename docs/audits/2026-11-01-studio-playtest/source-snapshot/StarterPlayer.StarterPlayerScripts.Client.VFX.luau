-- Client-only visual effects for every jutsu and enemy action. Uses built-in Fire/Smoke/ParticleEmitter + parts (no external ids).
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local Config = require(game.ReplicatedStorage.Shared.Config)

local V = {}
V.Reduced = false
local fxFolder = Instance.new("Folder")
fxFolder.Name = "ClientFX"
fxFolder.Parent = workspace

local function jcol(id) local j = Config.Jutsu[id]; return j and j.Color or Color3.new(1, 1, 1), j and j.Color2 or Color3.new(1, 1, 1) end
local function P(size, cf, color, opts)
	local p = Instance.new("Part")
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
	p.Size = size; p.CFrame = cf; p.Color = color
	p.Material = Enum.Material.Neon
	if opts then for k, v in opts do p[k] = v end end
	p.Parent = fxFolder
	return p
end
local function ball(size, pos, color, tr) return P(Vector3.one * size, CFrame.new(pos), color, {Shape = Enum.PartType.Ball, Transparency = tr or 0}) end
local function tw(inst, t, props, style) local x = TweenService:Create(inst, TweenInfo.new(t, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props); x:Play(); return x end
local function fadeGrow(p, t, scale)
	tw(p, t, {Size = p.Size * scale, Transparency = 1})
	Debris:AddItem(p, t + 0.05)
end
local function emitter(parent, color, rate, size, life, speed, light)
	local e = Instance.new("ParticleEmitter")
	e.Color = typeof(color) == "ColorSequence" and color or ColorSequence.new(color)
	e.Rate = V.Reduced and rate * 0.3 or rate
	e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, 0)})
	e.Lifetime = NumberRange.new(life * 0.6, life)
	e.Speed = NumberRange.new(speed * 0.5, speed)
	e.SpreadAngle = Vector2.new(180, 180)
	e.LightEmission = light or 1
	e.Transparency = NumberSequence.new(0.1, 1)
	e.Parent = parent
	return e
end
local function burst(pos, color, count, speed)
	local a = P(Vector3.one * 0.2, CFrame.new(pos), color, {Transparency = 1})
	local e = emitter(a, color, 0, 1.2, 0.6, speed or 25)
	e:Emit(V.Reduced and math.ceil(count * 0.3) or count)
	Debris:AddItem(a, 1)
end
local function ring(pos, radius, color, t, thick)
	local r = P(Vector3.new(thick or 0.6, 1, 1), CFrame.new(pos + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.pi / 2), color, {Shape = Enum.PartType.Cylinder, Transparency = 0.2})
	tw(r, t, {Size = Vector3.new(thick or 0.6, radius * 2, radius * 2), Transparency = 1})
	Debris:AddItem(r, t + 0.05)
end
local function bolt(a, b, color, width, life)
	local segs = 6
	local prev = a
	for i = 1, segs do
		local t = i / segs
		local pt = a:Lerp(b, t)
		if i < segs then pt += Vector3.new(math.random(-20, 20) / 10, math.random(-20, 20) / 10, math.random(-20, 20) / 10) * ((b - a).Magnitude / 25) end
		local len = (pt - prev).Magnitude
		local s = P(Vector3.new(width, width, len), CFrame.lookAt((prev + pt) / 2, pt), color)
		tw(s, life, {Transparency = 1})
		Debris:AddItem(s, life + 0.05)
		prev = pt
	end
end
local function handOf(char)
	return char and (char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm") or char:FindFirstChild("HumanoidRootPart"))
end
local function follow(part, getCF, duration)
	local stop = os.clock() + duration
	local conn
	conn = RunService.RenderStepped:Connect(function()
		if os.clock() > stop or not part.Parent then conn:Disconnect(); if part.Parent then part:Destroy() end; return end
		local cf = getCF()
		if cf then part.CFrame = cf end
	end)
end

---------------------------------------------------------------- projectile looks
local function makeOrb(id, pos)
	local c1, c2 = jcol(id)
	if id == "Fireball" or id == "PhoenixFlower" then
		local o = ball(id == "Fireball" and 3.2 or 1.4, pos, c1)
		local f = Instance.new("Fire"); f.Color = c1; f.SecondaryColor = c2; f.Size = id == "Fireball" and 6 or 3; f.Heat = 0; f.Parent = o
		emitter(o, ColorSequence.new(c2, c1), 40, id == "Fireball" and 1.6 or 0.8, 0.4, 2)
		return o
	elseif id == "ChidoriSenbon" then
		local o = P(Vector3.new(0.25, 0.25, 3), CFrame.new(pos), c2)
		emitter(o, c1, 30, 0.4, 0.2, 1)
		return o
	else
		local o = ball(2, pos, c1)
		emitter(o, c2, 30, 1, 0.3, 2)
		return o
	end
end

function V.Projectile(id, from, targetModel, speed)
	local tgt = targetModel and targetModel:FindFirstChild("HumanoidRootPart")
	if not tgt then return end
	local o = makeOrb(id, from)
	local pos = from
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function(dt)
		if not tgt.Parent or os.clock() - t0 > 3 then conn:Disconnect(); o:Destroy(); return end
		local to = tgt.Position - pos
		if to.Magnitude < speed * dt + 1 then conn:Disconnect(); o:Destroy(); return end
		pos += to.Unit * speed * dt
		-- phoenix flowers weave a little
		local wob = id == "PhoenixFlower" and Vector3.new(0, math.sin((os.clock() - t0) * 20) * 0.6, 0) or Vector3.zero
		o.CFrame = CFrame.lookAt(pos + wob, pos + wob + to.Unit)
	end)
end

function V.Impact(id, pos, radius)
	local c1, c2 = jcol(id)
	local s = ball(2, pos, c2, 0.1)
	fadeGrow(s, 0.35, radius)
	ring(pos - Vector3.new(0, 2.5, 0), radius * 1.3, c1, 0.4)
	burst(pos, c1, 25, 30)
	if id == "Chidori" or id == "ChidoriSenbon" or id == "BodyFlicker" then for _ = 1, 3 do bolt(pos, pos + Vector3.new(math.random(-8, 8), math.random(0, 8), math.random(-8, 8)), c2, 0.3, 0.2) end end
end

---------------------------------------------------------------- charge-ups held in the hand
function V.Charge(id, char, t)
	local hand = handOf(char)
	if not hand then return end
	local c1, c2 = jcol(id)
	local size = (id == "GiantRasengan" and 7) or (id == "TailedBeastBomb" and 6) or (id == "Rasenshuriken" and 3) or 2.2
	local core = ball(0.5, hand.Position, c2, 0)
	local shell = ball(0.6, hand.Position, c1, 0.45)
	local spin = {}
	if id == "Rasengan" or id == "GiantRasengan" or id == "Rasenshuriken" then
		for i = 1, 3 do spin[i] = P(Vector3.new(0.3, 1, 1), CFrame.new(hand.Position), c1, {Shape = Enum.PartType.Cylinder, Transparency = 0.3}) end
	end
	local chidori = id == "Chidori"
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local k = math.clamp((os.clock() - t0) / math.max(t, 0.05), 0, 1)
		if not hand.Parent or os.clock() - t0 > t + 0.6 then
			conn:Disconnect(); core:Destroy(); shell:Destroy(); for _, s in spin do s:Destroy() end; return
		end
		local pos = hand.Position + (id == "GiantRasengan" and Vector3.new(0, size * 0.6, 0) or Vector3.zero)
		core.Size = Vector3.one * size * 0.55 * k + Vector3.one * 0.2
		shell.Size = Vector3.one * size * k + Vector3.one * 0.3
		core.CFrame = CFrame.new(pos); shell.CFrame = CFrame.new(pos)
		for i, s in spin do
			s.Size = Vector3.new(0.25, size * 1.1 * k + 0.4, size * 1.1 * k + 0.4)
			s.CFrame = CFrame.new(pos) * CFrame.Angles(os.clock() * (8 + i * 3), i * 1.1, os.clock() * 6)
		end
		if chidori and math.random() < 0.6 then bolt(pos, pos + Vector3.new(math.random(-4, 4), math.random(-4, 4), math.random(-4, 4)), c2, 0.15, 0.08) end
	end)
end

function V.Dash(id, from, to)
	local c1 = jcol(id)
	local len = (to - from).Magnitude
	local s = P(Vector3.new(1.5, 1.5, len), CFrame.lookAt((from + to) / 2, to), c1, {Transparency = 0.3})
	tw(s, 0.35, {Size = Vector3.new(0.1, 0.1, len), Transparency = 1})
	Debris:AddItem(s, 0.4)
	if id == "Chidori" then bolt(from, to, Color3.new(1, 1, 1), 0.35, 0.25) end
end

function V.Smoke(pos, n)
	for _ = 1, math.min(n * 3, 15) do
		local s = ball(math.random(25, 45) / 10, pos + Vector3.new(math.random(-20, 20) / 10, math.random(0, 25) / 10, math.random(-20, 20) / 10), Color3.fromRGB(235, 235, 240), 0.15)
		s.Material = Enum.Material.SmoothPlastic
		fadeGrow(s, 0.6, 2.2)
	end
end

---------------------------------------------------------------- lines, cones
local function snakeLine(from, dir, range, c1, c2, t)
	local n = 10
	for i = 1, n do
		task.delay(i * t / n, function()
			local pos = from + dir * (range * i / n) + Vector3.new(0, math.sin(i) * 0.8, 0) + dir:Cross(Vector3.yAxis) * math.sin(i * 1.3) * 1.5
			local seg = ball(1.6 - i * 0.05, pos, i == n and c2 or c1)
			seg.Material = Enum.Material.SmoothPlastic
			tw(seg, 0.5, {Transparency = 1})
			Debris:AddItem(seg, 0.55)
		end)
	end
end

function V.Beam(id, from, dir, range)
	local c1, c2 = jcol(id)
	if id == "SnakeHands" then
		for k = -1, 1 do snakeLine(from + dir:Cross(Vector3.yAxis) * k * 1.5, dir, range, c1, c2, 0.25) end
	else -- dragon flame: elongated flame body + head
		local b = P(Vector3.new(4, 4, 2), CFrame.lookAt(from + dir * 2, from + dir * 3), c1, {Transparency = 0.1})
		local f = Instance.new("Fire"); f.Size = 10; f.Color = c1; f.SecondaryColor = c2; f.Parent = b
		tw(b, 0.25, {Size = Vector3.new(5, 5, range), CFrame = CFrame.lookAt(from + dir * (range / 2), from + dir * range)})
		task.delay(0.35, function() tw(b, 0.4, {Transparency = 1}) end)
		Debris:AddItem(b, 0.8)
		local head = ball(6, from + dir * range, c2, 0.1)
		fadeGrow(head, 0.5, 2)
	end
end

function V.Cone(id, from, dir, range, angle, count)
	local c1, c2 = jcol(id)
	if id == "StrikingSnakes" then
		for i = 1, count or 4 do
			local a = math.rad((i - (count + 1) / 2) * (angle / count))
			local d = CFrame.fromAxisAngle(Vector3.yAxis, a):VectorToWorldSpace(dir)
			snakeLine(from, d, range, c1, c2, 0.3)
		end
		return
	end
	local waves = id == "GreatBreakthrough" and 5 or 7
	for i = 1, waves do
		task.delay(i * 0.04, function()
			local a = math.rad((i - (waves + 1) / 2) * (angle / waves))
			local d = CFrame.fromAxisAngle(Vector3.yAxis, a):VectorToWorldSpace(dir)
			local w = P(Vector3.new(id == "GreatBreakthrough" and 8 or 6, 6, 2), CFrame.lookAt(from + d * 3, from + d * 4), id == "GreatBreakthrough" and Color3.new(1, 1, 1) or c1, {Transparency = id == "GreatBreakthrough" and 0.6 or 0.15})
			if id ~= "GreatBreakthrough" then local f = Instance.new("Fire"); f.Size = 12; f.Color = c1; f.SecondaryColor = c2; f.Parent = w end
			tw(w, 0.5, {CFrame = CFrame.lookAt(from + d * range, from + d * (range + 1)), Size = Vector3.new(14, 10, 3), Transparency = 1})
			Debris:AddItem(w, 0.55)
		end)
	end
end

---------------------------------------------------------------- shadow / control
function V.Shadow(id, from, targetModel, dur)
	local tgt = targetModel and targetModel:FindFirstChild("HumanoidRootPart")
	if not tgt then return end
	local strip = P(Vector3.new(1.8, 0.15, 0.1), CFrame.new(from.X, 0.12, from.Z), Color3.fromRGB(15, 15, 20), {Material = Enum.Material.SmoothPlastic})
	local stop = os.clock() + 0.3 + dur
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		if os.clock() > stop or not tgt.Parent then conn:Disconnect(); strip:Destroy(); return end
		local k = math.clamp((os.clock() - t0) / 0.3, 0, 1)
		local a = Vector3.new(from.X, 0.12, from.Z)
		local b = a:Lerp(Vector3.new(tgt.Position.X, 0.12, tgt.Position.Z), k)
		strip.Size = Vector3.new(1.8, 0.15, math.max((b - a).Magnitude, 0.1))
		strip.CFrame = CFrame.lookAt((a + b) / 2, b + Vector3.new(0, 0, 0.001))
	end)
	local pool = P(Vector3.new(0.2, 6, 6), CFrame.new(tgt.Position.X, 0.15, tgt.Position.Z) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(15, 15, 20), {Shape = Enum.PartType.Cylinder, Material = Enum.Material.SmoothPlastic})
	Debris:AddItem(pool, 0.3 + dur)
end

function V.Strangle(id, model, bound)
	local tgt = model and model:FindFirstChild("HumanoidRootPart")
	if not tgt then return end
	local c1, c2 = jcol(id)
	for i = 1, 6 do
		local a = i / 6 * math.pi * 2
		local base = tgt.Position + Vector3.new(math.cos(a) * 3, -3, math.sin(a) * 3)
		local hand = P(Vector3.new(0.6, 0.6, 0.6), CFrame.new(base), c1, {Material = Enum.Material.SmoothPlastic})
		tw(hand, 0.45, {Size = Vector3.new(0.7, 6, 0.7), CFrame = CFrame.lookAt(base + Vector3.new(0, 3, 0), tgt.Position) * CFrame.Angles(math.pi / 2, 0, 0)})
		task.delay(0.6, function() tw(hand, 0.4, {Transparency = 1}) end)
		Debris:AddItem(hand, 1.1)
	end
	task.delay(0.5, function() burst(tgt.Position, c2, bound and 40 or 20, 20) end)
end

---------------------------------------------------------------- areas, buffs
function V.Burst(id, char, radius)
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local c1, c2 = jcol(id)
	for i = 1, V.Reduced and 6 or 14 do
		local a = math.random() * math.pi * 2
		bolt(root.Position, root.Position + Vector3.new(math.cos(a) * radius, math.random(-2, 4), math.sin(a) * radius), i % 2 == 0 and c1 or c2, 0.35, 0.3)
	end
	local s = ball(3, root.Position, c1, 0.4)
	fadeGrow(s, 0.35, radius * 0.8)
	ring(root.Position - Vector3.new(0, 2.6, 0), radius, c2, 0.4)
end

function V.Log(pos)
	V.Smoke(pos, 3)
	local log = P(Vector3.new(5, 2, 2), CFrame.new(pos) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(150, 100, 60), {Shape = Enum.PartType.Cylinder, Material = Enum.Material.Wood})
	task.delay(1, function() tw(log, 0.4, {Transparency = 1}) end)
	Debris:AddItem(log, 1.5)
end

function V.Flicker(pos, color)
	local s = ball(3, pos, color or Color3.new(1, 1, 1), 0.2)
	fadeGrow(s, 0.25, 2.5)
	for _ = 1, 6 do
		local l = P(Vector3.new(0.2, 0.2, 4), CFrame.lookAt(pos, pos + Vector3.new(math.random(-10, 10), math.random(-2, 6), math.random(-10, 10))), Color3.new(1, 1, 1))
		fadeGrow(l, 0.25, 1.5)
	end
end

function V.Summon(pos, size)
	local seal = P(Vector3.new(0.2, size * 1.6, size * 1.6), CFrame.new(pos.X, 0.15, pos.Z) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(20, 20, 20), {Shape = Enum.PartType.Cylinder, Transparency = 0.2})
	tw(seal, 1.2, {Transparency = 1})
	Debris:AddItem(seal, 1.3)
	V.Smoke(pos + Vector3.new(0, 4, 0), 5)
end

function V.ToadHop(toad, land)
	task.delay(0.05, function() ring(land, 12, Color3.fromRGB(200, 160, 100), 0.4, 1); burst(land + Vector3.new(0, 1, 0), Color3.fromRGB(160, 130, 90), 25, 25) end)
end

function V.EarthWall(wall)
	if not wall then return end
	local goal = wall.CFrame
	local debrisColor = Color3.fromRGB(120, 90, 60)
	for _ = 1, V.Reduced and 4 or 12 do
		local d = P(Vector3.one * math.random(6, 14) / 10, wall.CFrame * CFrame.new(math.random(-12, 12), -5, math.random(-2, 2)), debrisColor, {Material = Enum.Material.Slate})
		tw(d, 0.6, {CFrame = d.CFrame + Vector3.new(math.random(-4, 4), math.random(4, 9), math.random(-4, 4)), Transparency = 1})
		Debris:AddItem(d, 0.65)
	end
	burst(goal.Position - Vector3.new(0, 5, 0), Color3.fromRGB(190, 160, 120), 30, 15)
end

function V.WaterWall(char, dur, radius)
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local c = P(Vector3.new(10, radius * 0.9, radius * 0.9), root.CFrame, Color3.fromRGB(60, 160, 255), {Shape = Enum.PartType.Cylinder, Transparency = 0.55, Material = Enum.Material.Glass})
	local inner = P(Vector3.new(11, radius * 0.75, radius * 0.75), root.CFrame, Color3.fromRGB(200, 240, 255), {Shape = Enum.PartType.Cylinder, Transparency = 0.8})
	emitter(c, Color3.fromRGB(180, 230, 255), 25, 0.8, 0.6, 6, 0.5)
	follow(c, function() return root.Parent and CFrame.new(root.Position) * CFrame.Angles(0, os.clock() * 4, math.pi / 2) end, dur)
	follow(inner, function() return root.Parent and CFrame.new(root.Position) * CFrame.Angles(0, -os.clock() * 6, math.pi / 2) end, dur)
end

function V.Traveller(id, from, dir, range, speed)
	local c1, c2 = jcol(id)
	local n = 12
	local segs = {}
	for i = 1, n do segs[i] = ball(5 - i * 0.25, from, i == 1 and c2 or c1, 0.15) ; segs[i].Material = Enum.Material.Glass end
	local eyeL = ball(0.8, from, Color3.fromRGB(255, 240, 120)); local eyeR = ball(0.8, from, Color3.fromRGB(255, 240, 120))
	local side = dir:Cross(Vector3.yAxis)
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		if t * speed > range + 20 then conn:Disconnect(); for _, s in segs do fadeGrow(s, 0.3, 1.5) end; eyeL:Destroy(); eyeR:Destroy(); return end
		for i, s in segs do
			local d = math.max(0, t * speed - (i - 1) * 3)
			s.Position = from + dir * d + side * math.sin(d * 0.15) * 3 + Vector3.new(0, 2 + math.sin(d * 0.1 + i) * 1.5, 0)
		end
		local h = segs[1].Position
		eyeL.Position = h + dir * 2 + side * 1.2 + Vector3.new(0, 1, 0)
		eyeR.Position = h + dir * 2 - side * 1.2 + Vector3.new(0, 1, 0)
	end)
end

---------------------------------------------------------------- big projectiles + explosions
function V.BigProjectile(id, from, dest, t, radius)
	local c1, c2 = jcol(id)
	local parts = {}
	local core = ball(id == "TailedBeastBomb" and 7 or 3, from, id == "TailedBeastBomb" and Color3.fromRGB(20, 0, 30) or c2, 0)
	core.Material = id == "TailedBeastBomb" and Enum.Material.SmoothPlastic or Enum.Material.Neon
	table.insert(parts, core)
	local shell = ball(id == "TailedBeastBomb" and 8.5 or 5, from, c1, 0.5)
	table.insert(parts, shell)
	local blades = {}
	if id == "Rasenshuriken" then
		for i = 1, 4 do blades[i] = P(Vector3.new(12, 0.4, 2.2), CFrame.new(from), Color3.fromRGB(235, 250, 255), {Transparency = 0.25}); table.insert(parts, blades[i]) end
		local ringP = P(Vector3.new(0.4, 9, 9), CFrame.new(from), c1, {Shape = Enum.PartType.Cylinder, Transparency = 0.55}); table.insert(parts, ringP); blades[5] = ringP
	else
		emitter(shell, Color3.fromRGB(255, 80, 200), 40, 2, 0.4, 4)
	end
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local k = math.clamp((os.clock() - t0) / math.max(t, 0.05), 0, 1)
		if k >= 1 then conn:Disconnect(); for _, p in parts do p:Destroy() end; return end
		local pos = from:Lerp(dest, k) + Vector3.new(0, math.sin(k * math.pi) * 4, 0)
		core.Position = pos; shell.Position = pos
		for i = 1, 4 do if blades[i] then blades[i].CFrame = CFrame.new(pos) * CFrame.Angles(0, os.clock() * 25 + i * math.pi / 2, 0) * CFrame.new(5, 0, 0) end end
		if blades[5] then blades[5].CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.pi / 2) end
	end)
end

function V.Explosion(id, pos, radius)
	local c1, c2 = jcol(id)
	if id == "Kirin" then
		for i = 1, 4 do task.delay(i * 0.05, function() bolt(pos + Vector3.new(math.random(-6, 6), 160, math.random(-6, 6)), pos, i % 2 == 0 and c2 or c1, 2.2 - i * 0.3, 0.5) end) end
		-- the lightning beast's head: a big bright wedge diving down
		local head = P(Vector3.new(8, 8, 18), CFrame.lookAt(pos + Vector3.new(0, 60, 0), pos), c2, {Transparency = 0.1})
		tw(head, 0.2, {CFrame = CFrame.lookAt(pos + Vector3.new(0, 4, 0), pos - Vector3.new(0, 1, 0))})
		task.delay(0.2, function() fadeGrow(head, 0.3, 2) end)
	end
	local s = ball(4, pos, c2, 0.05)
	fadeGrow(s, 0.6, radius / 2)
	local s2 = ball(4, pos, c1, 0.3)
	fadeGrow(s2, 0.8, radius / 1.6)
	ring(pos - Vector3.new(0, pos.Y - 0.2, 0), radius * 1.3, c1, 0.7, 1)
	burst(pos, c1, 60, 50)
	if id == "TailedBeastBomb" then
		local dark = ball(6, pos, Color3.fromRGB(30, 0, 40), 0)
		dark.Material = Enum.Material.SmoothPlastic
		fadeGrow(dark, 1, radius / 1.2)
	end
	local cam = workspace.CurrentCamera
	if cam and (cam.CFrame.Position - pos).Magnitude < 120 and not V.Reduced then V.Shake(math.min(radius / 10, 2.5)) end
end

function V.Telegraph(id, pos, radius, dur)
	local c1 = jcol(id)
	local disc = P(Vector3.new(0.2, radius * 2, radius * 2), CFrame.new(pos.X, 0.2, pos.Z) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(255, 60, 60), {Shape = Enum.PartType.Cylinder, Transparency = 0.6})
	tw(disc, dur, {Transparency = 0.2, Color = c1})
	Debris:AddItem(disc, dur + 0.05)
	local cloud = P(Vector3.new(radius * 2.4, 6, radius * 2.4), CFrame.new(pos.X, 75, pos.Z), Color3.fromRGB(40, 40, 55), {Material = Enum.Material.SmoothPlastic, Transparency = 1})
	tw(cloud, dur * 0.6, {Transparency = 0.15})
	task.delay(dur + 0.4, function() tw(cloud, 0.6, {Transparency = 1}) end)
	Debris:AddItem(cloud, dur + 1.1)
	for i = 1, 4 do task.delay(dur * i / 5, function() bolt(Vector3.new(pos.X, 72, pos.Z) + Vector3.new(math.random(-10, 10), 0, math.random(-10, 10)), Vector3.new(pos.X, 40, pos.Z), c1, 0.4, 0.15) end) end
end

function V.Burn(id, model, dur)
	local root = model and model:FindFirstChild("UpperTorso") or (model and model:FindFirstChild("HumanoidRootPart"))
	if not root then return end
	local f = Instance.new("Fire")
	f.Color = Color3.fromRGB(10, 5, 15)
	f.SecondaryColor = Color3.fromRGB(120, 20, 50)
	f.Size = 7
	f.Heat = 9
	f.Parent = root
	Debris:AddItem(f, dur)
end

local function weldTo(part, base, offset)
	part.Anchored = false
	part.Massless = true
	part.CFrame = base.CFrame * offset
	local w = Instance.new("WeldConstraint"); w.Part0 = base; w.Part1 = part; w.Parent = part
	part.Parent = base.Parent
end
function V.Susanoo(char, dur)
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local col = Color3.fromRGB(150, 70, 255)
	local pieces = {}
	local function piece(size, off, shape)
		local p = P(size, root.CFrame * off, col, {Transparency = 0.55, Shape = shape or Enum.PartType.Block})
		weldTo(p, root, off)
		table.insert(pieces, p)
		return p
	end
	piece(Vector3.new(9, 9, 7), CFrame.new(0, 7, 1.5), Enum.PartType.Ball)                -- torso shell
	for i = 0, 3 do piece(Vector3.new(10, 0.6, 0.6), CFrame.new(0, 3.5 + i * 1.6, -2)) end   -- ribs
	piece(Vector3.new(4.5, 4.5, 4.5), CFrame.new(0, 13, 0.5))                              -- head
	piece(Vector3.new(6, 1, 1), CFrame.new(-2, 15.5, 0.5) * CFrame.Angles(0, 0, 0.5))     -- horns
	piece(Vector3.new(6, 1, 1), CFrame.new(2, 15.5, 0.5) * CFrame.Angles(0, 0, -0.5))
	piece(Vector3.new(2.5, 9, 2.5), CFrame.new(-6.5, 6, -1) * CFrame.Angles(0.4, 0, 0.2))   -- arms
	local arm = piece(Vector3.new(2.5, 9, 2.5), CFrame.new(6.5, 6, -1) * CFrame.Angles(0.4, 0, -0.2))
	piece(Vector3.new(1.2, 2, 16), CFrame.new(7.5, 4, -8) * CFrame.Angles(0.3, 0, 0))      -- sword
	for _, p in pieces do p.CanCollide = false end
	local e = emitter(pieces[1], col, 20, 2, 0.8, 3)
	task.delay(dur, function() for _, p in pieces do tw(p, 0.5, {Transparency = 1}); Debris:AddItem(p, 0.55) end end)
end

function V.Swing(char, dir)
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local arc = P(Vector3.new(26, 0.5, 4), CFrame.lookAt(root.Position + dir * 10 + Vector3.new(0, 4, 0), root.Position + dir * 11 + Vector3.new(0, 4, 0)) * CFrame.Angles(0, 0, 0.6), Color3.fromRGB(200, 140, 255), {Transparency = 0.2})
	tw(arc, 0.3, {CFrame = arc.CFrame * CFrame.Angles(0, 0, -1.2), Transparency = 1})
	Debris:AddItem(arc, 0.35)
end

function V.Planetary(center, radius, dur)
	local core = ball(3, center + Vector3.new(0, 8, 0), Color3.fromRGB(30, 10, 40), 0)
	core.Material = Enum.Material.SmoothPlastic
	local glow = ball(5, center + Vector3.new(0, 8, 0), Color3.fromRGB(200, 120, 255), 0.5)
	local rocks = {}
	for i = 1, V.Reduced and 8 or 18 do
		rocks[i] = {p = P(Vector3.one * math.random(10, 30) / 10, CFrame.new(center), Color3.fromRGB(120, 95, 75), {Material = Enum.Material.Slate}), a = math.random() * 6.28, r = math.random(radius * 0.4, radius), y = math.random(1, 14)}
	end
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		if t > dur then
			conn:Disconnect(); fadeGrow(core, 0.4, 4); fadeGrow(glow, 0.4, 4)
			for _, r in rocks do fadeGrow(r.p, 0.4, 0.1) end
			return
		end
		local k = t / dur
		core.Size = Vector3.one * (3 + k * 8); glow.Size = Vector3.one * (5 + k * 12)
		for _, r in rocks do
			local rr = r.r * (1 - k * 0.85)
			r.p.CFrame = CFrame.new(center + Vector3.new(math.cos(r.a + t * 2) * rr, r.y + k * 6, math.sin(r.a + t * 2) * rr)) * CFrame.Angles(t, t * 2, 0)
		end
	end)
end

function V.Leap(char, from, to)
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local trail = ball(2, from, Color3.fromRGB(120, 190, 255), 0.4)
	fadeGrow(trail, 0.4, 3)
end

---------------------------------------------------------------- generic combat feedback
local hitCache = {}
function V.Hit(model)
	if not model or not model.Parent then return end
	if hitCache[model] and os.clock() - hitCache[model] < 0.1 then return end
	hitCache[model] = os.clock()
	local h = model:FindFirstChild("HitFlash")
	if not h then
		h = Instance.new("Highlight")
		h.Name = "HitFlash"
		h.FillColor = Color3.new(1, 1, 1)
		h.OutlineTransparency = 1
		h.DepthMode = Enum.HighlightDepthMode.Occluded
		h.Parent = model
	end
	h.FillTransparency = 0.2
	tw(h, 0.2, {FillTransparency = 1})
end

function V.Death(name, pos, color)
	V.Smoke(pos, 3)
	burst(pos, color or Color3.new(1, 1, 1), 35, 30)
	local s = ball(2, pos, color or Color3.new(1, 1, 1), 0.2)
	fadeGrow(s, 0.4, 4)
end

function V.Punch(char, pos)
	local s = ball(1.2, pos, Color3.fromRGB(255, 250, 220), 0.1)
	fadeGrow(s, 0.2, 3)
	for _ = 1, 4 do
		local l = P(Vector3.new(0.15, 0.15, 2), CFrame.lookAt(pos, pos + Vector3.new(math.random(-10, 10), math.random(-10, 10), math.random(-10, 10))), Color3.new(1, 1, 1))
		fadeGrow(l, 0.18, 1.6)
	end
end

local ELEMENT = {leaf = Color3.fromRGB(110, 220, 90), wind = Color3.fromRGB(220, 255, 240), earth = Color3.fromRGB(200, 160, 100), water = Color3.fromRGB(70, 170, 255),
	ice = Color3.fromRGB(180, 230, 255), lightning = Color3.fromRGB(255, 240, 90), fire = Color3.fromRGB(255, 110, 30), spirit = Color3.fromRGB(150, 255, 210),
	moon = Color3.fromRGB(170, 180, 255), poison = Color3.fromRGB(150, 255, 60), steel = Color3.fromRGB(230, 230, 240), shadow = Color3.fromRGB(110, 70, 170),
	crystal = Color3.fromRGB(220, 140, 255), chakra = Color3.fromRGB(90, 220, 255), nature = Color3.fromRGB(255, 220, 80), light = Color3.fromRGB(255, 245, 190),
	void = Color3.fromRGB(160, 60, 255), divine = Color3.fromRGB(255, 225, 120)}
V.ElementColor = ELEMENT

function V.EnemyMelee(model, element)
	local root = model and model:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local col = ELEMENT[element] or Color3.new(1, 1, 1)
	local pos = root.Position + root.CFrame.LookVector * 3
	local arc = P(Vector3.new(6, 0.3, 1.2), CFrame.lookAt(pos, pos + root.CFrame.LookVector) * CFrame.Angles(0, 0, 0.8), col, {Transparency = 0.2})
	tw(arc, 0.25, {CFrame = arc.CFrame * CFrame.Angles(0, 0, -1.6), Transparency = 1})
	Debris:AddItem(arc, 0.3)
	if element == "lightning" then bolt(root.Position, pos + Vector3.new(0, 1, 0), col, 0.2, 0.15) end
	if element == "fire" or element == "poison" or element == "water" or element == "ice" then burst(pos, col, 10, 12) end
end

function V.BossBlast(model, at, element, color)
	local col = ELEMENT[element] or color
	local disc = P(Vector3.new(0.2, 24, 24), CFrame.new(at.X, 0.25, at.Z) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(255, 50, 50), {Shape = Enum.PartType.Cylinder, Transparency = 0.6})
	tw(disc, 1, {Transparency = 0.25})
	Debris:AddItem(disc, 1)
	local root = model and model:FindFirstChild("HumanoidRootPart")
	if root then
		local orb = ball(3, root.Position + Vector3.new(0, 5, 0), col, 0)
		tw(orb, 1, {Position = Vector3.new(at.X, 2, at.Z), Size = Vector3.one * 5})
		Debris:AddItem(orb, 1)
	end
	task.delay(1, function()
		local s = ball(4, Vector3.new(at.X, 2, at.Z), col, 0.1)
		fadeGrow(s, 0.45, 6)
		burst(Vector3.new(at.X, 2, at.Z), col, 40, 35)
	end)
end

---------------------------------------------------------------- camera shake + floating text
local shakeAmt = 0
function V.Shake(a) shakeAmt = math.max(shakeAmt, a) end
RunService.RenderStepped:Connect(function(dt)
	if shakeAmt > 0.01 then
		local cam = workspace.CurrentCamera
		cam.CFrame *= CFrame.new(math.random(-10, 10) / 10 * shakeAmt * 0.3, math.random(-10, 10) / 10 * shakeAmt * 0.3, 0)
		shakeAmt *= math.exp(-dt * 8)
	end
end)

function V.FloatText(pos, text, color, size)
	local a = P(Vector3.one * 0.1, CFrame.new(pos + Vector3.new(math.random(-15, 15) / 10, 2, math.random(-15, 15) / 10)), Color3.new(), {Transparency = 1})
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(200, size or 40)
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.Text = text
	t.TextColor3 = color
	local s = Instance.new("UIStroke"); s.Thickness = 2.5; s.Parent = t
	t.Parent = bb
	bb.Parent = a
	tw(a, 0.8, {CFrame = a.CFrame + Vector3.new(0, 4, 0)})
	task.delay(0.45, function() tw(t, 0.35, {TextTransparency = 1}); tw(s, 0.35, {Transparency = 1}) end)
	Debris:AddItem(a, 0.85)
end

function V.Dispatch(kind, ...)
	local f = V[kind]
	if f then
		local ok, err = pcall(f, ...)
		if not ok then warn("[VFX]", kind, err) end
	end
end

return V

