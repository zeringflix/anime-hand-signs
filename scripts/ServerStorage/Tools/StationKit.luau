--!strict
-- StationKit (edit-time tool): turns the Blender training-station export (tools/blender/training_stations_v2.py ->
-- stations.json, Roblox Y-up space) into Models in ServerStorage.LobbyAssets.BlenderStations.
-- Every part keeps the colour / material / transparency / studs / light authored in Blender.
-- Parts tagged fx (beam / sparkle / fire / smoke / embers / petals) get Roblox particle effects.
-- Parts tagged spin / bob in Blender go into child Models the lobby client animates (Spin = "y" / "bob").
--
--   require(game.ServerStorage.Tools.StationKit).Import(jsonText)  -> {name = partCount}
local HttpService = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")

local K = {}

local function make(d: any): BasePart
	local kind = d.k
	local s = Vector3.new(d.s[1], d.s[2], d.s[3])
	local r = d.r
	local cf = CFrame.new(d.p[1], d.p[2], d.p[3], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9])
	local p: BasePart
	if kind == "Wedge" then
		p = Instance.new("WedgePart")
		p.Size = s
		p.CFrame = cf
	elseif kind == "Cylinder" then
		local c = Instance.new("Part")
		c.Shape = Enum.PartType.Cylinder
		c.Size = Vector3.new(s.Y, s.X, s.Z) -- Roblox cylinders run along local X; Blender's along local Z (-> Roblox Y)
		c.CFrame = cf * CFrame.Angles(0, 0, math.pi / 2)
		p = c
	elseif kind == "Ball" then
		local b = Instance.new("Part")
		if math.abs(s.X - s.Y) < 0.01 and math.abs(s.X - s.Z) < 0.01 then
			b.Shape = Enum.PartType.Ball
			b.Size = s
		else
			b.Size = s
			local m = Instance.new("SpecialMesh"); m.MeshType = Enum.MeshType.Sphere; m.Parent = b
		end
		b.CFrame = cf
		p = b
	else
		local b = Instance.new("Part")
		b.Size = s
		b.CFrame = cf
		p = b
	end
	p.Anchored = true
	p.CanCollide = (d.t or 0) < 0.5 and d.m ~= "Neon"
	p.CastShadow = d.m ~= "Neon" and d.m ~= "Glass"
	p.Color = Color3.fromRGB(d.c[1], d.c[2], d.c[3])
	local ok, mat = pcall(function() return (Enum.Material :: any)[d.m] end)
	p.Material = ok and mat or Enum.Material.SmoothPlastic
	p.Transparency = d.t or 0
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if d.studs == 1 then
		p.Material = Enum.Material.Plastic
		p.TopSurface = Enum.SurfaceType.Studs
	end
	if d.light then
		local l = Instance.new("PointLight")
		l.Color = Color3.fromRGB(d.light[1], d.light[2], d.light[3])
		l.Range = d.light[4] or 12
		l.Brightness = 1.3
		l.Shadows = false
		l.Parent = p
	end
	return p
end

-- Roblox-side effects tagged in Blender (rbx_fx). Textures are the particle images that ship with the client.
local SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local function ns(a: number, b: number, c: number?): NumberSequence
	if c then return NumberSequence.new({NumberSequenceKeypoint.new(0, a), NumberSequenceKeypoint.new(0.5, b), NumberSequenceKeypoint.new(1, c)}) end
	return NumberSequence.new(a, b)
end
local function emitter(p: BasePart, props: {[string]: any})
	local e = Instance.new("ParticleEmitter")
	e.Texture = SPARK
	e.LightEmission = 1
	e.LightInfluence = 0
	for k, v in props do (e :: any)[k] = v end
	e.Parent = p
	return e
end
local FX = {
	beam = function(p: BasePart) -- rising sparkles up the light column
		emitter(p, {Name = "BeamSparkles", Color = ColorSequence.new(p.Color:Lerp(Color3.new(1, 1, 1), 0.4)), Rate = 10, Lifetime = NumberRange.new(2, 3.4),
			Speed = NumberRange.new(4, 9), SpreadAngle = Vector2.new(8, 8), EmissionDirection = Enum.NormalId.Top, Size = ns(0, 0.55, 0),
			Transparency = ns(0.2, 0.9), Shape = Enum.ParticleEmitterShape.Box})
		p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
	end,
	sparkle = function(p: BasePart)
		emitter(p, {Name = "Twinkles", Color = ColorSequence.new(p.Color:Lerp(Color3.new(1, 1, 1), 0.3)), Rate = 12, Lifetime = NumberRange.new(1, 1.8),
			Speed = NumberRange.new(1.5, 4), SpreadAngle = Vector2.new(180, 180), Size = ns(0, 0.6, 0), Rotation = NumberRange.new(0, 360)})
	end,
	fire = function(p: BasePart)
		local f = Instance.new("Fire"); f.Size = 7; f.Heat = 9; f.Color = Color3.fromRGB(255, 120, 30); f.SecondaryColor = Color3.fromRGB(255, 220, 90); f.Parent = p
	end,
	smoke = function(p: BasePart)
		local sm = Instance.new("Smoke"); sm.Color = Color3.fromRGB(110, 104, 112); sm.Opacity = 0.18; sm.RiseVelocity = 4; sm.Size = 3; sm.Parent = p
	end,
	embers = function(p: BasePart)
		emitter(p, {Name = "Embers", Color = ColorSequence.new(Color3.fromRGB(255, 200, 80), Color3.fromRGB(255, 90, 20)), Rate = 18, Lifetime = NumberRange.new(1.4, 2.6),
			Speed = NumberRange.new(3, 7), SpreadAngle = Vector2.new(25, 25), EmissionDirection = Enum.NormalId.Top, Size = ns(0.3, 0),
			Acceleration = Vector3.new(0, 2, 0)})
	end,
	petals = function(p: BasePart) -- sakura petals drifting down from the canopy
		emitter(p, {Name = "Petals", Color = ColorSequence.new(Color3.fromRGB(255, 190, 225)), LightEmission = 0.2, Rate = 7, Lifetime = NumberRange.new(5, 7),
			Speed = NumberRange.new(0.5, 1.5), SpreadAngle = Vector2.new(180, 180), Size = NumberSequence.new(0.35), Acceleration = Vector3.new(0.6, -1.2, 0),
			Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-90, 90), Shape = Enum.ParticleEmitterShape.Box,
			Texture = "rbxasset://textures/particles/sparkles_main.dds"})
	end,
}

function K.Import(jsonText: string): {[string]: number}
	local data = HttpService:JSONDecode(jsonText)
	local assets = ServerStorage:FindFirstChild("LobbyAssets") or Instance.new("Folder")
	assets.Name = "LobbyAssets"; assets.Parent = ServerStorage
	local old = assets:FindFirstChild("BlenderStations")
	if old then old:Destroy() end
	local folder = Instance.new("Folder")
	folder.Name = "BlenderStations"
	local counts = {}
	for name, parts in data do
		local m = Instance.new("Model")
		m.Name = name
		m:SetAttribute("Source", "tools/blender/training_stations_v2.py (Blender 5.2) -> StationKit")
		local spin, bob
		for _, d in parts do
			local p = make(d)
			if d.fx and FX[d.fx] then FX[d.fx](p) end
			if d.spin == 1 then
				if not spin then spin = Instance.new("Model"); spin.Name = "Spinner"; spin:SetAttribute("Spin", "y"); spin.Parent = m end
				p.Parent = spin
			elseif d.bob == 1 then
				if not bob then bob = Instance.new("Model"); bob.Name = "Bobber"; bob:SetAttribute("Spin", "bob"); bob.Parent = m end
				p.Parent = bob
			else
				p.Parent = m
			end
		end
		if spin then spin.WorldPivot = CFrame.new((spin :: Model):GetBoundingBox().Position) end
		m.WorldPivot = CFrame.new(0, 0, 0)
		m.Parent = folder
		counts[name] = #parts
	end
	folder.Parent = assets
	return counts
end

return K
