--!nonstrict
-- TrainingFX (client): custom VFX for the 13 lobby training stations (issue #14, owner 2026-11-02).
-- Decorative only: built locally from the server's FxCore anchors (BeamOrigin / BeamTip) and the Blender parts tagged
-- with an "Fx" attribute. Never touches collision, zones, damage or data. Every texture is original
-- (vfx/training/textures.py -> Assets.FX). Each station has its own identity; stronger stations get richer layers.
-- Performance: one shared RenderStepped for orbits/arcs, distance culling (effects off beyond CULL studs), fewer
-- particles on touch devices, short-lived arcs pooled per station.
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Assets = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Assets"))
local T = Assets.FX

local M = {}
local CULL = 165
local MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local RATE = MOBILE and 0.6 or 1

local function C(r, g, b) return Color3.fromRGB(r, g, b) end
local function NS(...) local k = {}; local a = {...}; for i = 1, #a, 2 do table.insert(k, NumberSequenceKeypoint.new(a[i], a[i + 1])) end; return NumberSequence.new(k) end
local function CS(a: Color3, b: Color3?) return ColorSequence.new(a, b or a) end
local function new(cls: string, props: {[string]: any}, parent: Instance?): any
	local i = Instance.new(cls)
	for k, v in props do (i :: any)[k] = v end
	if parent then i.Parent = parent end
	return i
end

-- per-station runtime record
type Station = {root: Folder, center: Vector3, emitters: {ParticleEmitter}, beams: {Beam}, trails: {Trail}, orbits: {any}, arcs: any?, spins: {any}, on: boolean}
local stations: {Station} = {}

local function anchorPart(parent: Instance, cf: CFrame, name: string?): BasePart
	return new("Part", {Name = name or "FxAnchor", Size = Vector3.new(0.2, 0.2, 0.2), CFrame = cf, Anchored = true, CanCollide = false, CanQuery = false,
		CanTouch = false, CastShadow = false, Transparency = 1, Massless = true}, parent)
end
local function emitter(st: Station, parent: Instance, props: {[string]: any}): ParticleEmitter
	props.LightInfluence = props.LightInfluence or 0
	local rate = props.Rate or 5
	props.Rate = rate * RATE
	local e = new("ParticleEmitter", props, parent)
	e:SetAttribute("BaseRate", e.Rate)
	table.insert(st.emitters, e)
	return e
end
local function attach(parent: BasePart, pos: Vector3, name: string?): Attachment
	return new("Attachment", {Name = name or "A", Position = pos}, parent)
end

---------------------------------------------------------------- shared layers
-- textured energy pillar: wide soft body + thin white core, scrolling upward, fading out at the tip
local function pillar(st: Station, core: BasePart, color: Color3, width: number, tier: number)
	local a0, a1 = core:FindFirstChild("BeamOrigin"), core:FindFirstChild("BeamTip")
	if not (a0 and a1) then return end
	local body = new("Beam", {Attachment0 = a0, Attachment1 = a1, Texture = T.Column, TextureMode = Enum.TextureMode.Stretch, TextureSpeed = 0.35 + tier * 0.02,
		Width0 = width, Width1 = width * 0.55, LightEmission = 1, LightInfluence = 0, FaceCamera = true, Segments = 8,
		Color = CS(color:Lerp(C(255, 255, 255), 0.25), color), Transparency = NS(0, 0.15, 0.75, 0.45, 1, 1)}, core)
	local hot = new("Beam", {Attachment0 = a0, Attachment1 = a1, Texture = T.Column, TextureMode = Enum.TextureMode.Stretch, TextureSpeed = 0.8,
		Width0 = width * 0.28, Width1 = width * 0.12, LightEmission = 1, LightInfluence = 0, FaceCamera = true,
		Color = CS(C(255, 255, 255)), Transparency = NS(0, 0.1, 0.8, 0.6, 1, 1)}, core)
	table.insert(st.beams, body); table.insert(st.beams, hot)
	-- motes riding up the pillar
	emitter(st, a0, {Name = "PillarMotes", Texture = T.Glint, Color = CS(color:Lerp(C(255, 255, 255), 0.5)), LightEmission = 1, Rate = 2 + tier * 0.45,
		Lifetime = NumberRange.new(1.6, 2.6), Speed = NumberRange.new(4, 8), SpreadAngle = Vector2.new(6, 6), EmissionDirection = Enum.NormalId.Top,
		Size = NS(0, 0, 0.3, 0.7, 1, 0), Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-60, 60)})
end
-- flat ring / sigil lying on the ground (velocity-perpendicular particles, cross-faded so it reads as one rotating disc)
local function flat(st: Station, parent: Instance, texture: string, color: Color3, size: number, props: {[string]: any}?)
	local p = {Name = "Flat", Texture = texture, Color = CS(color), LightEmission = 1, Rate = 0.9, Lifetime = NumberRange.new(3.2), Speed = NumberRange.new(0.01),
		EmissionDirection = Enum.NormalId.Top, Orientation = Enum.ParticleOrientation.VelocityPerpendicular, Size = NumberSequence.new(size),
		Transparency = NS(0, 1, 0.3, 0.25, 0.7, 0.25, 1, 1), RotSpeed = NumberRange.new(28), Rotation = NumberRange.new(0, 360), LockedToPart = true}
	for k, v in props or {} do p[k] = v end
	return emitter(st, parent, p)
end
-- expanding ground pulse rings
local function pulses(st: Station, parent: Instance, color: Color3, maxSize: number, rate: number)
	return emitter(st, parent, {Name = "Pulse", Texture = T.Ring, Color = CS(color), LightEmission = 1, Rate = rate, Lifetime = NumberRange.new(1.4),
		Speed = NumberRange.new(0.01), EmissionDirection = Enum.NormalId.Top, Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		Size = NS(0, 1, 1, maxSize), Transparency = NS(0, 0.2, 0.6, 0.5, 1, 1), LockedToPart = true})
end
-- glowing bodies orbiting a centre (spark orbs / chakra comets) with trails; animated in the shared stepper
local function orbit(st: Station, centre: Vector3, count: number, radius: number, height: number, bob: number, speed: number, color: Color3, orbTex: string?, orbSize: number?)
	local o = {centre = centre, radius = radius, height = height, bob = bob, speed = speed, parts = {}, phase = math.random() * 6}
	for i = 1, count do
		local p = anchorPart(st.root, CFrame.new(centre), "Orbiter")
		local a0 = attach(p, Vector3.new(0, 0.35, 0), "T0"); local a1 = attach(p, Vector3.new(0, -0.35, 0), "T1")
		local tr = new("Trail", {Attachment0 = a0, Attachment1 = a1, Lifetime = 0.45, LightEmission = 1, LightInfluence = 0, FaceCamera = true, MinLength = 0.05,
			Color = CS(color:Lerp(C(255, 255, 255), 0.4), color), Transparency = NS(0, 0.1, 1, 1), WidthScale = NS(0, 1, 1, 0.1), Texture = T.Column, TextureMode = Enum.TextureMode.Stretch}, p)
		table.insert(st.trails, tr)
		if orbTex then
			emitter(st, p, {Name = "Orb", Texture = orbTex, Color = CS(color:Lerp(C(255, 255, 255), 0.35)), LightEmission = 1, Rate = 6, Lifetime = NumberRange.new(0.35),
				Speed = NumberRange.new(0), Size = NumberSequence.new(orbSize or 1.4), Transparency = NS(0, 0.2, 1, 0.6), LockedToPart = true})
		end
		table.insert(o.parts, {part = p, offset = (i - 1) / count * math.pi * 2})
	end
	table.insert(st.orbits, o)
end
-- lightning arcs: a few textured Beams between points, flashed on briefly at random intervals
local function arcs(st: Station, points: {Vector3}, color: Color3, minGap: number, maxGap: number, width: number)
	local holder = anchorPart(st.root, CFrame.new(points[1]), "ArcHolder")
	local atts = {}
	for i, pt in points do atts[i] = new("Attachment", {Name = "P" .. i, WorldPosition = pt}, holder) end
	local pool = {}
	for i = 1, 3 do
		local b = new("Beam", {Texture = T.Bolt, TextureMode = Enum.TextureMode.Stretch, Width0 = width, Width1 = width * 0.7, LightEmission = 1, LightInfluence = 0,
			FaceCamera = true, Color = CS(C(255, 255, 255), color), Transparency = NumberSequence.new(0), Enabled = false, Segments = 4}, holder)
		table.insert(pool, b)
	end
	local spark = emitter(st, holder, {Name = "ArcSpark", Texture = T.Glint, Color = CS(color:Lerp(C(255, 255, 255), 0.5)), LightEmission = 1, Rate = 0,
		Lifetime = NumberRange.new(0.18, 0.3), Speed = NumberRange.new(0), Size = NS(0, 2.2, 1, 0)})
	st.arcs = {atts = atts, pool = pool, spark = spark, nextAt = 0, minGap = minGap, maxGap = maxGap}
end

---------------------------------------------------------------- station identities (keyed by the Blender model name)
local function tagged(model: Instance, tag: string): {BasePart}
	local out = {}
	for _, d in model:GetDescendants() do if d:IsA("BasePart") and d:GetAttribute("Fx") == tag then table.insert(out, d) end end
	return out
end
local function fire(st: Station, part: BasePart, scale: number, color: Color3?)
	local c = color or C(255, 140, 40)
	emitter(st, part, {Name = "Flame", Texture = T.Flame, FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4, FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
		Color = ColorSequence.new({ColorSequenceKeypoint.new(0, C(255, 236, 140)), ColorSequenceKeypoint.new(0.5, c), ColorSequenceKeypoint.new(1, c:Lerp(C(120, 20, 10), 0.6))}),
		LightEmission = 0.7, Rate = 12, Lifetime = NumberRange.new(0.7, 0.9), Speed = NumberRange.new(1.2, 2.4), SpreadAngle = Vector2.new(12, 12),
		EmissionDirection = Enum.NormalId.Top, Size = NS(0, 1.6 * scale, 1, 2.6 * scale), Rotation = NumberRange.new(-12, 12), Shape = Enum.ParticleEmitterShape.Box})
end
local function embers(st: Station, part: BasePart, color: Color3?, rate: number?)
	emitter(st, part, {Name = "Embers", Texture = T.Ember, Color = CS(color or C(255, 200, 80), (color or C(255, 90, 20)):Lerp(C(255, 60, 20), 0.5)), LightEmission = 1,
		Rate = rate or 8, Lifetime = NumberRange.new(1.4, 2.6), Speed = NumberRange.new(3, 7), SpreadAngle = Vector2.new(30, 30), EmissionDirection = Enum.NormalId.Top,
		Acceleration = Vector3.new(0.6, 1.5, 0), Drag = 0.6, Orientation = Enum.ParticleOrientation.VelocityParallel, Size = NS(0, 0.35, 1, 0)})
end
local function soot(st: Station, part: BasePart, color: Color3?)
	emitter(st, part, {Name = "Soot", Texture = T.Smoke, FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4, FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
		Color = CS(color or C(96, 88, 92)), LightEmission = 0, LightInfluence = 1, Rate = 2.4, Lifetime = NumberRange.new(2.2, 3),
		Speed = NumberRange.new(2.5, 4), SpreadAngle = Vector2.new(15, 15), EmissionDirection = Enum.NormalId.Top, Acceleration = Vector3.new(0.8, 0.4, 0),
		Size = NS(0, 1.6, 1, 4.2), Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-20, 20), Transparency = NS(0, 0.15, 1, 0.5)})
end

local BUILD = {}
BUILD.Dummy = function(st, core, model, c, tier, floor) -- X2: soft blue chakra spiral + glints
	orbit(st, Vector3.new(core.Position.X, floor, core.Position.Z), 2, 3.6, 2.2, 1.6, 2.2, C(110, 200, 255), T.Glow, 0.9)
	emitter(st, anchorPart(st.root, CFrame.new(core.Position.X, floor + 2, core.Position.Z)), {Name = "Glints", Texture = T.Glint, Color = CS(C(170, 225, 255)), LightEmission = 1,
		Rate = 1.6, Lifetime = NumberRange.new(0.5, 0.8), Speed = NumberRange.new(0), Size = NS(0, 0, 0.5, 1.2, 1, 0), Shape = Enum.ParticleEmitterShape.Box})
end
BUILD.Ring = function(st, core, model, c, tier, floor) -- X3: rose-purple pulse rings + sparkles
	local g = anchorPart(st.root, CFrame.new(core.Position.X, floor + 1.4, core.Position.Z))
	pulses(st, g, C(255, 110, 200), 13, 1.1)
	emitter(st, g, {Name = "Sparkles", Texture = T.Glint, Color = CS(C(255, 170, 230)), LightEmission = 1, Rate = 4, Lifetime = NumberRange.new(0.6, 1),
		Speed = NumberRange.new(1, 3), SpreadAngle = Vector2.new(180, 180), Size = NS(0, 0, 0.4, 0.9, 1, 0)})
end
BUILD.ChakraPool = function(st, core, model, c, tier, floor) -- X5: watery ripples + rising mist
	local water = anchorPart(st.root, CFrame.new(core.Position.X, core.Position.Y + 0.1, core.Position.Z))
	pulses(st, water, C(90, 220, 255), 7, 1.6)
	emitter(st, water, {Name = "Mist", Texture = T.Mist, Color = CS(C(170, 240, 255)), LightEmission = 0.5, Rate = 3, Lifetime = NumberRange.new(2.2, 3),
		Speed = NumberRange.new(1, 2), EmissionDirection = Enum.NormalId.Top, Size = NS(0, 1.5, 1, 3.5), Transparency = NS(0, 1, 0.3, 0.55, 1, 1)})
end
-- flames sit just in front of a fire-tagged part (the forge mouth / brazier glow would otherwise hide them)
local function fireFront(st: Station, p: BasePart, centre: Vector3, scale: number)
	local out = Vector3.new(p.Position.X - centre.X, 0, p.Position.Z - centre.Z)
	out = out.Magnitude > 0.1 and out.Unit or Vector3.zAxis
	local a = anchorPart(st.root, CFrame.new(p.Position + out * 0.9 - Vector3.new(0, p.Size.Y * 0.3, 0)), "FlameAnchor")
	a.Size = Vector3.new(math.max(p.Size.X, p.Size.Z) * 0.7, 0.3, 0.6)
	fire(st, a, scale)
end
BUILD.Forge = function(st, core, model, c, tier, floor) -- X7: flame, embers, soot
	for _, p in tagged(model, "fire") do fireFront(st, p, st.center, 1.4) end
	for _, p in tagged(model, "embers") do embers(st, p, nil, 10) end
	for _, p in tagged(model, "smoke") do soot(st, p) end
end
BUILD.GoldenDojo = function(st, core, model, c, tier, floor) -- X8 (pass): warm gold spark orbs circling the roof
	orbit(st, Vector3.new(core.Position.X, core.Position.Y - 4, core.Position.Z), 3, 5.5, 0, 1, 1.4, C(255, 210, 90), T.Orb, 1.6)
	pulses(st, anchorPart(st.root, CFrame.new(core.Position.X, floor + 0.8, core.Position.Z)), C(255, 210, 90), 14, 0.7)
end
BUILD.ScrollTemple = function(st, core, model, c, tier, floor) -- X10: sakura petals + pink glow
	for _, p in tagged(model, "petals") do
		emitter(st, p, {Name = "Petals", Texture = T.Petal, Color = ColorSequence.new(C(255, 200, 228), C(255, 150, 200)), LightEmission = 0.1, LightInfluence = 0.6,
			Rate = 9, Lifetime = NumberRange.new(5, 7), Speed = NumberRange.new(0.4, 1.2), SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0.7, -1.3, 0.3),
			Size = NumberSequence.new(0.42), Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-120, 120), Shape = Enum.ParticleEmitterShape.Box,
			Transparency = NS(0, 1, 0.08, 0, 0.85, 0, 1, 1)})
	end
	flat(st, anchorPart(st.root, CFrame.new(core.Position.X, floor + 0.7, core.Position.Z)), T.Glow, C(255, 140, 210), 14, {RotSpeed = NumberRange.new(0), Rate = 0.5})
end
BUILD.StormPagoda = function(st, core, model, c, tier, floor) -- X12: aqua lightning arcs around the roofs
	local p, pts = core.Position, {}
	for k = 0, 5 do local a = k / 6 * math.pi * 2; table.insert(pts, Vector3.new(p.X + math.cos(a) * 5.5, p.Y - 6 + (k % 2) * 4, p.Z + math.sin(a) * 5.5)) end
	table.insert(pts, Vector3.new(p.X, p.Y + 1, p.Z))
	arcs(st, pts, C(90, 240, 255), 0.35, 1.2, 0.9)
end
BUILD.GravitySeal = function(st, core, model, c, tier, floor) -- X20: purple void swirl, rune flicker, floating shards
	local g = anchorPart(st.root, CFrame.new(core.Position.X, floor + 0.75, core.Position.Z))
	flat(st, g, T.Rune, C(200, 110, 255), 12)
	emitter(st, anchorPart(st.root, CFrame.new(core.Position.X, core.Position.Y - 3, core.Position.Z)), {Name = "Shards", Texture = T.Shard, Color = CS(C(210, 150, 255)),
		LightEmission = 0.6, Rate = 3, Lifetime = NumberRange.new(2.5, 3.5), Speed = NumberRange.new(0.6, 1.4), SpreadAngle = Vector2.new(180, 180),
		Size = NS(0, 0, 0.2, 0.9, 0.8, 0.9, 1, 0), RotSpeed = NumberRange.new(-90, 90), Rotation = NumberRange.new(0, 360), Acceleration = Vector3.new(0, 0.6, 0)})
end
BUILD.ThunderDome = function(st, core, model, c, tier, floor) -- X25 (pass): electric crackle over the dome shell
	local p, pts = Vector3.new(core.Position.X, floor, core.Position.Z), {}
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		local el = (k % 3) * 0.4 + 0.2
		table.insert(pts, p + Vector3.new(math.cos(a) * math.cos(el) * 6.5, 1 + math.sin(el) * 6.5, math.sin(a) * math.cos(el) * 6.5))
	end
	arcs(st, pts, C(110, 190, 255), 0.18, 0.7, 0.7)
	pulses(st, anchorPart(st.root, CFrame.new(p + Vector3.new(0, 0.8, 0))), C(110, 190, 255), 15, 0.8)
end
BUILD.CrimsonAltar = function(st, core, model, c, tier, floor) -- X35: red rune + rising embers
	local g = anchorPart(st.root, CFrame.new(core.Position.X, floor + 0.75, core.Position.Z))
	flat(st, g, T.Rune, C(255, 60, 70), 12, {RotSpeed = NumberRange.new(-22)})
	embers(st, g, C(255, 90, 80), 7)
	for _, p in tagged(model, "embers") do embers(st, p, C(255, 80, 60), 6) end
end
BUILD.VoidTotem = function(st, core, model, c, tier, floor) -- X40: restrained dark-magenta vortex above the gate
	local v = anchorPart(st.root, CFrame.new(core.Position.X, core.Position.Y + 11, core.Position.Z))
	flat(st, v, T.Swirl, C(240, 70, 220), 11, {RotSpeed = NumberRange.new(70), Orientation = Enum.ParticleOrientation.VelocityPerpendicular, EmissionDirection = Enum.NormalId.Bottom})
	flat(st, v, T.Swirl, C(20, 0, 30), 9, {RotSpeed = NumberRange.new(-50), LightEmission = 0, EmissionDirection = Enum.NormalId.Bottom, Transparency = NS(0, 1, 0.3, 0.35, 0.7, 0.35, 1, 1)})
	for _, p in tagged(model, "smoke") do soot(st, p, C(80, 30, 90)) end
end
BUILD.DragonGate = function(st, core, model, c, tier, floor) -- X50 (pass): red-orange fire swirling through the torii
	orbit(st, Vector3.new(core.Position.X, floor + 1, core.Position.Z), 3, 4.2, 4.5, 3, 2.6, C(255, 110, 30), T.Glow, 1.1)
	for _, p in tagged(model, "embers") do embers(st, p, nil, 12) end
	for _, p in tagged(model, "fire") do fireFront(st, p, st.center, 1) end
end
BUILD.SageThrone = function(st, core, model, c, tier, floor) -- X250 (pass): heavenly gold halos + orbiting orbs
	local tip = core:FindFirstChild("BeamTip") :: Attachment
	local h = anchorPart(st.root, CFrame.new(tip.WorldPosition - Vector3.new(0, 5, 0)))
	flat(st, h, T.Halo, C(255, 225, 120), 13, {RotSpeed = NumberRange.new(24)})
	flat(st, anchorPart(st.root, CFrame.new(tip.WorldPosition - Vector3.new(0, 8, 0))), T.Halo, C(255, 245, 190), 9, {RotSpeed = NumberRange.new(-36)})
	orbit(st, Vector3.new(core.Position.X, core.Position.Y + 2, core.Position.Z), 4, 6, 0, 1.2, 1, C(255, 220, 110), T.Orb, 1.8)
	pulses(st, anchorPart(st.root, CFrame.new(core.Position.X, floor + 0.8, core.Position.Z)), C(255, 215, 100), 20, 0.6)
end

---------------------------------------------------------------- lifecycle
local holder: Folder? = nil
local function build()
	if holder then holder:Destroy() end
	table.clear(stations)
	local lobby = workspace:FindFirstChild("Lobby")
	local folder = lobby and lobby:FindFirstChild("TrainingStations")
	if not folder then return end
	holder = new("Folder", {Name = "TrainingFX"}, workspace)
	for _, m in folder:GetChildren() do
		local core = m:FindFirstChild("FxCore") :: BasePart?
		local model = m:FindFirstChild("StationModel")
		if not (core and model) then continue end
		local kind = core:GetAttribute("Kind")
		local tier = core:GetAttribute("Tier") or 1
		local color = core:GetAttribute("Color") or C(255, 255, 255)
		local floor = core:GetAttribute("Floor") or core.Position.Y
		local st: Station = {root = new("Folder", {Name = m.Name}, holder), center = Vector3.new(core:GetAttribute("ZoneX") or core.Position.X, floor, core:GetAttribute("ZoneZ") or core.Position.Z),
			emitters = {}, beams = {}, trails = {}, orbits = {}, arcs = nil, spins = {}, on = true}
		-- the pillar is the station's colour; width grows gently with tier
		pillar(st, core, color, 1.6 + tier * 0.09, tier)
		local ok, err = pcall(function() if BUILD[kind] then BUILD[kind](st, core, model, color, tier, floor) end end)
		if not ok then warn("[TrainingFX] " .. tostring(kind) .. ": " .. tostring(err)) end
		table.insert(stations, st)
	end
end

local function setOn(st: Station, on: boolean)
	if st.on == on then return end
	st.on = on
	for _, e in st.emitters do e.Enabled = on end
	for _, b in st.beams do b.Enabled = on end
	for _, t in st.trails do t.Enabled = on end
	if st.arcs then for _, b in st.arcs.pool do b.Enabled = false end end
end

local cullAcc = 0
local function step(dt: number)
	local cam = workspace.CurrentCamera
	if not cam then return end
	cullAcc += dt
	if cullAcc > 0.4 then
		cullAcc = 0
		local cp = cam.CFrame.Position
		for _, st in stations do setOn(st, (st.center - cp).Magnitude < CULL) end
	end
	local t = os.clock()
	for _, st in stations do
		if not st.on then continue end
		for _, o in st.orbits do
			for _, op in o.parts do
				local a = t * o.speed + op.offset + o.phase
				local y = o.height + math.sin(t * 1.3 + op.offset) * o.bob
				op.part.CFrame = CFrame.new(o.centre + Vector3.new(math.cos(a) * o.radius, y, math.sin(a) * o.radius))
			end
		end
		local ar = st.arcs
		if ar and t >= ar.nextAt then
			ar.nextAt = t + ar.minGap + math.random() * (ar.maxGap - ar.minGap)
			local b = ar.pool[math.random(1, #ar.pool)]
			local i = math.random(1, #ar.atts)
			local j = (i + math.random(1, #ar.atts - 1) - 1) % #ar.atts + 1
			b.Attachment0, b.Attachment1 = ar.atts[i], ar.atts[j]
			b.TextureLength = 4 + math.random() * 3
			b.TextureSpeed = (math.random() - 0.5) * 6
			b.CurveSize0, b.CurveSize1 = (math.random() - 0.5) * 3, (math.random() - 0.5) * 3
			b.Enabled = true
			ar.spark.Parent = ar.atts[j]
			ar.spark:Emit(MOBILE and 1 or 2)
			task.delay(0.08 + math.random() * 0.08, function() b.Enabled = false end)
		end
	end
end

function M.Start()
	build()
	RunService.RenderStepped:Connect(step)
	-- rebuild if the lobby is rebuilt / streamed in later
	workspace.ChildAdded:Connect(function(c) if c.Name == "Lobby" then task.wait(1); build() end end)
end
M.Rebuild = build
return M
