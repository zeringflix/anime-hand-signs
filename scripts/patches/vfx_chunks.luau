--@@LAYERS
---------------------------------------------------------------- textured particle layers (VFX pass, issue #14)
-- Layered emitters with real textures: flash -> shock ring -> sparks -> embers -> smoke (+ element extras).
local TEX = {
	Glow = "rbxassetid://128833263910353", Spark = "rbxassetid://86449978005965", Smoke = "rbxassetid://98458326422605",
	Flame = "rbxassetid://95443741755652", Ring = "rbxassetid://80958644457713", Star = "rbxassetid://118322217786922",
	Lightning = "rbxassetid://102821096850740", Slash = "rbxassetid://130580971288210", Swirl = "rbxassetid://103825454930921",
	Debris = "rbxassetid://95185375966524",
}
V.TEX = TEX
local NS, NR, CS = NumberSequence.new, NumberRange.new, ColorSequence.new
local function nseq(points: {{number}}): NumberSequence
	local k = {}
	for _, p in points do table.insert(k, NumberSequenceKeypoint.new(p[1], p[2])) end
	return NS(k)
end
local function holder(pos: Vector3): (BasePart, Attachment)
	local a = P(Vector3.one * 0.2, CFrame.new(pos), Color3.new(1, 1, 1), {Transparency = 1})
	local att = Instance.new("Attachment"); att.Parent = a
	return a, att
end
-- one emitter layer, fired once with Emit()
local function layer(att: Attachment, props: {[string]: any}, count: number)
	local e = Instance.new("ParticleEmitter")
	e.Rate = 0
	e.LightEmission = 1
	e.LockedToPart = false
	for k, v in props do (e :: any)[k] = v end
	e.Parent = att
	local n = V.Reduced and math.max(1, math.ceil(count * 0.35)) or count
	e:Emit(n)
	return e
end
local function darker(c: Color3, f: number) return Color3.new(c.R * f, c.G * f, c.B * f) end
local function elementOf(id: string?): string
	local j = id and Config.Jutsu[id]
	local v = j and j.Vfx or ""
	if v == "fireball" or v == "phoenix" or v == "flamebeam" or v == "flamewave" or v == "blackflame" then return "fire" end
	if v == "chidori" or v == "lightningburst" or v == "senbon" or v == "kirin" then return "lightning" end
	if v == "earthwall" or v == "summon" then return "earth" end
	if v == "waterwall" or v == "waterdragon" then return "water" end
	if v == "gust" or v == "rasenshuriken" then return "wind" end
	if v == "shadow" or v == "shadowhands" then return "shadow" end
	return "chakra"
end
V.ElementOf = elementOf

-- the core hit/impact stack; scale ~ radius in studs
local function fxBurst(pos: Vector3, c1: Color3, c2: Color3, scale: number, element: string?, opts: {[string]: any}?)
	local o = opts or {}
	local a, att = holder(pos)
	-- 1 flash
	layer(att, {Texture = TEX.Glow, Color = CS(c2:Lerp(Color3.new(1, 1, 1), 0.5)), Size = nseq({{0, scale * 1.2}, {0.25, scale * 2.6}, {1, scale * 3}}),
		Transparency = nseq({{0, 0}, {0.4, 0.3}, {1, 1}}), Lifetime = NR(0.16, 0.2), Speed = NR(0), ZOffset = 2, Brightness = 3}, 1)
	-- 2 shock ring (camera facing)
	layer(att, {Texture = TEX.Ring, Color = CS(c1:Lerp(Color3.new(1, 1, 1), 0.3)), Size = nseq({{0, scale * 0.6}, {1, scale * 4.2}}),
		Transparency = nseq({{0, 0.05}, {0.6, 0.5}, {1, 1}}), Lifetime = NR(0.28, 0.32), Speed = NR(0), ZOffset = 1, Brightness = 2}, 1)
	-- 3 ground ring (flat): velocity straight up + VelocityPerpendicular
	if not o.NoGround then
		local ga, gatt = holder(Vector3.new(pos.X, pos.Y - (o.GroundDrop or scale * 0.9), pos.Z))
		layer(gatt, {Texture = TEX.Ring, Color = CS(c1), Size = nseq({{0, scale * 0.8}, {1, scale * 5.5}}), Transparency = nseq({{0, 0.1}, {1, 1}}),
			Lifetime = NR(0.45, 0.5), Speed = NR(0.01), EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.zero,
			Orientation = Enum.ParticleOrientation.VelocityPerpendicular, Brightness = 1.5}, 1)
		Debris:AddItem(ga, 1.2)
	end
	-- 4 sparks: streaks aligned to their velocity, slowed by drag
	layer(att, {Texture = TEX.Spark, Color = CS(Color3.new(1, 1, 1), c2), Size = nseq({{0, scale * 0.5}, {1, 0}}), Transparency = nseq({{0, 0}, {1, 0.4}}),
		Lifetime = NR(0.22, 0.42), Speed = NR(scale * 9, scale * 18), SpreadAngle = Vector2.new(180, 180), Drag = 6,
		Orientation = Enum.ParticleOrientation.VelocityParallel, Brightness = 2.5}, o.Sparks or 18)
	-- 5 embers / twinkles falling
	layer(att, {Texture = TEX.Star, Color = CS(c2, c1), Size = nseq({{0, scale * 0.35}, {1, 0}}), Lifetime = NR(0.5, 0.9), Speed = NR(scale * 3, scale * 8),
		SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, -scale * 6, 0), Drag = 2, Rotation = NR(0, 360), RotSpeed = NR(-180, 180)}, o.Embers or 10)
	-- 6 smoke: dark twin of the colour, unlit, rising and spreading
	layer(att, {Texture = TEX.Smoke, Color = CS(darker(c1, 0.45), Color3.fromRGB(60, 60, 66)), LightEmission = 0, LightInfluence = 0.6,
		Size = nseq({{0, scale * 0.8}, {1, scale * 2.6}}), Transparency = nseq({{0, 0.35}, {0.7, 0.7}, {1, 1}}), Lifetime = NR(0.8, 1.3),
		Speed = NR(scale * 1, scale * 3), SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, scale * 1.2, 0), Drag = 1.5,
		Rotation = NR(0, 360), RotSpeed = NR(-40, 40)}, o.Smoke or 6)
	-- element extras
	if element == "fire" then
		layer(att, {Texture = TEX.Flame, Color = CS({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 245, 190)), ColorSequenceKeypoint.new(0.4, c1), ColorSequenceKeypoint.new(1, darker(c1, 0.5))}),
			Size = nseq({{0, scale * 1.4}, {1, scale * 0.3}}), Transparency = nseq({{0, 0}, {1, 1}}), Lifetime = NR(0.35, 0.6), Speed = NR(scale * 2, scale * 7),
			SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, scale * 10, 0), Rotation = NR(-20, 20), Brightness = 2}, 14)
	elseif element == "lightning" then
		layer(att, {Texture = TEX.Lightning, Color = CS(Color3.new(1, 1, 1), c2), Size = nseq({{0, scale * 2.4}, {1, scale * 2.8}}), Transparency = nseq({{0, 0}, {1, 1}}),
			Lifetime = NR(0.08, 0.16), Speed = NR(0), Rotation = NR(0, 360), Brightness = 3}, 6)
	elseif element == "earth" then
		layer(att, {Texture = TEX.Debris, Color = CS(Color3.fromRGB(150, 120, 90), Color3.fromRGB(110, 90, 70)), LightEmission = 0, LightInfluence = 1,
			Size = nseq({{0, scale * 0.5}, {1, scale * 0.4}}), Lifetime = NR(0.7, 1.1), Speed = NR(scale * 6, scale * 12),
			SpreadAngle = Vector2.new(60, 60), EmissionDirection = Enum.NormalId.Top, Acceleration = Vector3.new(0, -scale * 22, 0), Rotation = NR(0, 360), RotSpeed = NR(-300, 300)}, 12)
	elseif element == "water" then
		layer(att, {Texture = TEX.Glow, Color = CS(Color3.fromRGB(220, 245, 255), c1), Size = nseq({{0, scale * 0.45}, {1, 0.05}}), Lifetime = NR(0.5, 0.8),
			Speed = NR(scale * 6, scale * 12), SpreadAngle = Vector2.new(70, 70), EmissionDirection = Enum.NormalId.Top, Acceleration = Vector3.new(0, -scale * 20, 0)}, 22)
	elseif element == "wind" or element == "chakra" then
		layer(att, {Texture = TEX.Swirl, Color = CS(c2, c1), Size = nseq({{0, scale * 1}, {1, scale * 3.4}}), Transparency = nseq({{0, 0.1}, {1, 1}}),
			Lifetime = NR(0.35, 0.45), Speed = NR(0), Rotation = NR(0, 360), RotSpeed = NR(360, 540), Brightness = 2}, 2)
	elseif element == "shadow" then
		layer(att, {Texture = TEX.Smoke, Color = CS(Color3.fromRGB(30, 20, 45)), LightEmission = 0, Size = nseq({{0, scale}, {1, scale * 3}}),
			Transparency = nseq({{0, 0.2}, {1, 1}}), Lifetime = NR(0.6, 1), Speed = NR(scale * 2, scale * 5), SpreadAngle = Vector2.new(180, 180), Rotation = NR(0, 360)}, 10)
	end
	-- a quick light pop
	local l = Instance.new("PointLight"); l.Color = c1; l.Range = scale * 8; l.Brightness = 4; l.Shadows = false; l.Parent = a
	tw(l, 0.35, {Brightness = 0})
	Debris:AddItem(a, 1.6)
end
V.FxBurst = fxBurst

-- shared helpers rebuilt on the textured layers (every jutsu that uses them improves)
local function burst(pos, color, count, speed)
	local a, att = holder(pos)
	local s = (speed or 25) / 25
	layer(att, {Texture = TEX.Spark, Color = CS(Color3.new(1, 1, 1), color), Size = nseq({{0, 0.9 * s + 0.4}, {1, 0}}), Lifetime = NR(0.25, 0.5),
		Speed = NR((speed or 25) * 0.6, speed or 25), SpreadAngle = Vector2.new(180, 180), Drag = 5, Orientation = Enum.ParticleOrientation.VelocityParallel, Brightness = 2}, count)
	layer(att, {Texture = TEX.Star, Color = CS(color), Size = nseq({{0, 0.7 * s + 0.3}, {1, 0}}), Lifetime = NR(0.4, 0.8), Speed = NR((speed or 25) * 0.2, (speed or 25) * 0.5),
		SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, -12, 0), Rotation = NR(0, 360)}, math.ceil(count / 3))
	Debris:AddItem(a, 1.2)
end
local function ring(pos, radius, color, t, thick)
	local a, att = holder(pos + Vector3.new(0, 0.35, 0))
	layer(att, {Texture = TEX.Ring, Color = CS(color:Lerp(Color3.new(1, 1, 1), 0.25)), Size = nseq({{0, radius * 0.3}, {1, radius * 2.2}}), Transparency = nseq({{0, 0.05}, {0.7, 0.5}, {1, 1}}),
		Lifetime = NR(t, t), Speed = NR(0.01), EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.zero,
		Orientation = Enum.ParticleOrientation.VelocityPerpendicular, Brightness = 2}, 1)
	Debris:AddItem(a, t + 0.3)
end

--@@ENDLAYERS
--@@ORB
local function makeOrb(id, pos)
	local c1, c2 = jcol(id)
	local el = elementOf(id)
	local big = id == "Fireball"
	local o
	if id == "ChidoriSenbon" then
		o = P(Vector3.new(0.25, 0.25, 3), CFrame.new(pos), c2)
	else
		o = ball(big and 2.6 or (id == "PhoenixFlower" and 1.2 or 1.8), pos, c2)
		o.Transparency = 0.05
	end
	local att0 = Instance.new("Attachment"); att0.Position = Vector3.new(0, 0.6, 0); att0.Parent = o
	local att1 = Instance.new("Attachment"); att1.Position = Vector3.new(0, -0.6, 0); att1.Parent = o
	local tr = Instance.new("Trail")
	tr.Attachment0, tr.Attachment1 = att0, att1
	tr.Texture = TEX.Glow; tr.TextureMode = Enum.TextureMode.Stretch; tr.LightEmission = 1; tr.Brightness = 2
	tr.Color = CS(c2, c1); tr.Transparency = nseq({{0, 0.1}, {1, 1}}); tr.Lifetime = big and 0.35 or 0.22
	tr.WidthScale = nseq({{0, 1}, {1, 0}}); tr.FaceCamera = true
	tr.Parent = o
	local center = Instance.new("Attachment"); center.Parent = o
	-- glow halo that follows the orb
	local halo = Instance.new("ParticleEmitter")
	halo.Texture = TEX.Glow; halo.Color = CS(c1); halo.LightEmission = 1; halo.Brightness = 2; halo.LockedToPart = true
	halo.Size = NS((big and 6 or 3.5)); halo.Transparency = nseq({{0, 0.3}, {1, 1}}); halo.Lifetime = NR(0.12); halo.Rate = 30; halo.Speed = NR(0)
	halo.Parent = center
	-- body particles by element
	local body = Instance.new("ParticleEmitter")
	body.Rate = V.Reduced and 25 or 70; body.LightEmission = 1; body.SpreadAngle = Vector2.new(25, 25); body.Speed = NR(1, 3)
	if el == "fire" then
		body.Texture = TEX.Flame
		body.Color = CS({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 245, 200)), ColorSequenceKeypoint.new(0.35, c1), ColorSequenceKeypoint.new(1, darker(c1, 0.4))})
		body.Size = nseq({{0, big and 3.2 or 1.6}, {1, 0.2}}); body.Lifetime = NR(0.25, 0.45); body.Acceleration = Vector3.new(0, 6, 0); body.Rotation = NR(-30, 30)
	elseif el == "lightning" then
		body.Texture = TEX.Lightning; body.Color = CS(Color3.new(1, 1, 1), c2); body.Size = nseq({{0, 1.8}, {1, 2.2}}); body.Lifetime = NR(0.06, 0.12); body.Rotation = NR(0, 360)
	else
		body.Texture = TEX.Swirl; body.Color = CS(c2, c1); body.Size = nseq({{0, 2.4}, {1, 0.6}}); body.Lifetime = NR(0.2, 0.3); body.RotSpeed = NR(400, 600); body.Rotation = NR(0, 360)
	end
	body.Transparency = nseq({{0, 0}, {1, 1}})
	body.Parent = center
	local l = Instance.new("PointLight"); l.Color = c1; l.Range = big and 16 or 10; l.Brightness = 2.5; l.Shadows = false; l.Parent = o
	return o
end

--@@ENDORB
--@@OVERRIDES
---------------------------------------------------------------- VFX pass overrides (textured, layered)
local baseImpact, baseExplosion, baseCharge, baseHit, baseDeath = V.Impact, V.Explosion, V.Charge, V.Hit, V.Death
function V.Impact(id, pos, radius)
	local c1, c2 = jcol(id)
	local el = elementOf(id)
	fxBurst(pos, c1, c2, math.clamp(radius / 2, 2, 6), el, {Sparks = 26, Embers = 14, Smoke = 8, GroundDrop = 2.4})
	if el == "lightning" then for _ = 1, 3 do bolt(pos, pos + Vector3.new(math.random(-8, 8), math.random(0, 8), math.random(-8, 8)), c2, 0.3, 0.2) end end
	local cam = workspace.CurrentCamera
	if cam and (cam.CFrame.Position - pos).Magnitude < 70 and not V.Reduced then V.Shake(math.min(radius / 14, 0.8)) end
end
function V.Explosion(id, pos, radius)
	local c1, c2 = jcol(id)
	local el = elementOf(id)
	baseExplosion(id, pos, radius) -- keeps the signature shapes (Kirin head, beast bomb core) + shake
	fxBurst(pos, c1, c2, math.clamp(radius / 2.5, 2, 9), el, {Sparks = 34, Embers = 22, Smoke = 14, GroundDrop = math.max(pos.Y - 0.2, 0.5)})
	-- lingering column of smoke / flame for the big ones
	if radius >= 12 then
		local a, att = holder(Vector3.new(pos.X, pos.Y - math.max(pos.Y - 0.5, 0), pos.Z))
		local e = Instance.new("ParticleEmitter")
		e.Texture = el == "fire" and TEX.Flame or TEX.Smoke
		e.Color = el == "fire" and CS(Color3.fromRGB(255, 220, 140), c1) or CS(darker(c1, 0.5), Color3.fromRGB(70, 70, 76))
		e.LightEmission = el == "fire" and 1 or 0
		e.Size = nseq({{0, radius * 0.25}, {1, radius * 0.6}}); e.Transparency = nseq({{0, 0.3}, {1, 1}})
		e.Lifetime = NR(0.8, 1.2); e.Speed = NR(radius * 0.4, radius * 0.8); e.EmissionDirection = Enum.NormalId.Top; e.SpreadAngle = Vector2.new(25, 25)
		e.Rate = V.Reduced and 8 or 22; e.Rotation = NR(0, 360); e.RotSpeed = NR(-30, 30)
		e.Parent = att
		task.delay(0.7, function() e.Enabled = false end)
		Debris:AddItem(a, 2.2)
	end
end
function V.Charge(id, char, t)
	baseCharge(id, char, t)
	local hand = handOf(char)
	if not hand then return end
	local c1, c2 = jcol(id)
	-- particles gathered INTO the hand from a sphere around it, plus a spinning swirl
	local att = Instance.new("Attachment"); att.Parent = hand
	local gather = Instance.new("ParticleEmitter")
	gather.Texture = TEX.Star; gather.Color = CS(c2, c1); gather.LightEmission = 1; gather.Brightness = 2
	gather.Shape = Enum.ParticleEmitterShape.Sphere; gather.ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward; gather.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
	gather.Size = nseq({{0, 0.6}, {1, 0}}); gather.Lifetime = NR(0.3, 0.45); gather.Speed = NR(10, 16); gather.Rate = V.Reduced and 20 or 60
	gather.Parent = att
	att.CFrame = CFrame.new()
	local sw = Instance.new("ParticleEmitter")
	sw.Texture = TEX.Swirl; sw.Color = CS(c2, c1); sw.LightEmission = 1; sw.LockedToPart = true; sw.Brightness = 2
	sw.Size = nseq({{0, 1.5}, {1, 4}}); sw.Transparency = nseq({{0, 0.2}, {1, 1}}); sw.Lifetime = NR(0.3); sw.Rate = 10; sw.Speed = NR(0); sw.RotSpeed = NR(500, 700); sw.Rotation = NR(0, 360)
	sw.Parent = att
	-- size the gather sphere to the jutsu
	local shape = Instance.new("Part") -- emitter shape scale comes from the parent part, so use a local sizer part welded to the hand
	shape.Size = Vector3.one * 7; shape.Transparency = 1; shape.CanCollide = false; shape.CanQuery = false; shape.CanTouch = false; shape.Massless = true
	shape.CFrame = hand.CFrame; shape.Parent = fxFolder
	local w = Instance.new("WeldConstraint"); w.Part0 = shape; w.Part1 = hand; w.Parent = shape
	shape.Anchored = false
	gather.Parent = shape
	task.delay(t, function()
		gather.Enabled = false; sw.Enabled = false
		fxBurst(hand.Position, c1, c2, 1.2, elementOf(id), {NoGround = true, Sparks = 10, Embers = 6, Smoke = 2})
	end)
	Debris:AddItem(att, t + 0.6)
	Debris:AddItem(shape, t + 0.6)
end
function V.Hit(model)
	baseHit(model)
	if not model or not model.Parent then return end
	local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
	if not root then return end
	local pos = (root :: BasePart).Position + Vector3.new(0, 1, 0)
	local a, att = holder(pos)
	layer(att, {Texture = TEX.Star, Color = CS(Color3.new(1, 1, 1), Color3.fromRGB(255, 230, 140)), Size = nseq({{0, 5}, {0.3, 6}, {1, 0}}), Lifetime = NR(0.22, 0.26), Speed = NR(0), Rotation = NR(0, 90), Brightness = 3, ZOffset = 3}, 1)
	layer(att, {Texture = TEX.Spark, Color = CS(Color3.new(1, 1, 1), Color3.fromRGB(255, 220, 120)), Size = nseq({{0, 1.6}, {1, 0}}), Lifetime = NR(0.2, 0.38),
		Speed = NR(22, 40), SpreadAngle = Vector2.new(180, 180), Drag = 7, Orientation = Enum.ParticleOrientation.VelocityParallel, Brightness = 2.5}, 12)
	Debris:AddItem(a, 0.6)
end
function V.Punch(char, pos)
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local look = root and (root :: BasePart).CFrame.LookVector or Vector3.zAxis
	local a, att = holder(pos)
	-- crescent swoosh facing the swing direction + flash + spark spray
	att.WorldCFrame = CFrame.lookAt(pos, pos + look)
	layer(att, {Texture = TEX.Slash, Color = CS(Color3.new(1, 1, 1), Color3.fromRGB(255, 220, 140)), Size = nseq({{0, 5.5}, {1, 9}}), Transparency = nseq({{0, 0}, {1, 1}}),
		Lifetime = NR(0.22, 0.26), Speed = NR(0.01), EmissionDirection = Enum.NormalId.Front, SpreadAngle = Vector2.zero, Rotation = NR(-30, 30), Brightness = 2.5, ZOffset = 1}, 1)
	layer(att, {Texture = TEX.Glow, Color = CS(Color3.fromRGB(255, 250, 225)), Size = nseq({{0, 2.5}, {1, 6}}), Transparency = nseq({{0, 0.1}, {1, 1}}), Lifetime = NR(0.16), Speed = NR(0), Brightness = 2}, 1)
	layer(att, {Texture = TEX.Spark, Color = CS(Color3.new(1, 1, 1)), Size = nseq({{0, 0.7}, {1, 0}}), Lifetime = NR(0.12, 0.22), Speed = NR(20, 32),
		EmissionDirection = Enum.NormalId.Front, SpreadAngle = Vector2.new(45, 45), Drag = 8, Orientation = Enum.ParticleOrientation.VelocityParallel}, 6)
	Debris:AddItem(a, 0.6)
end
function V.Death(name, pos, color)
	local c = color or Color3.new(1, 1, 1)
	fxBurst(pos, c, c:Lerp(Color3.new(1, 1, 1), 0.5), 1.8, nil, {Sparks = 16, Embers = 14, Smoke = 10, GroundDrop = 2.2})
end
--@@ENDOVERRIDES
