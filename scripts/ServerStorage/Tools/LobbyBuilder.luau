--!strict
-- LobbyBuilder v2 (edit-time tool, issue #14 REVISED ORDER) — Workspace.Lobby laid out to match the
-- +1 Anime Eyes lobby's ORGANISATION (see docs/reference/anime-eyes-lobby-comparison.md), built from
-- original parts/signage only (no ripped meshes, textures, logos or UI).
--
--   require(game.ServerStorage.Tools.LobbyBuilder).Build()   -- (re)builds Workspace.Lobby only
--   require(game.ServerStorage.Tools.LobbyBuilder).Revert()  -- removes lobby, restores Stage01 wall + SpawnLocation
--
-- Reference layout (observed in owner screenshots): sunken lavender checker arena ringed by blocky dirt/grass
-- cliffs with pines; spawn on a lantern-lined main path running straight to a dark WORLDS portal; special-pet
-- pedestal + leaderboards left of the portal, boss rift right; a field of gold-trimmed "X.. CHAKRA" training
-- stations priced in rebirths; two rows of 7 eye pads (red buy / green equipped / yellow owned) on a dark
-- platform; an egg walkway that starts with the Fuse Machine and Boss Shop.
-- Hand Signs mapping: CHAKRA -> HAND SIGNS, eyes -> 14 hand signs (Tiger free; Stage + Hand Signs + Trophies),
-- WORLDS portal opens straight into Stage 1 (walk through) and offers the Stages menu ([F]).
-- Special pet, boss rift, Fuse Machine and Boss Shop have no backend here: labelled COMING SOON, no prompts.
-- Station multipliers are applied server-side by GameService (ZoneMult) from SystemsConfig.TrainingStations.

local RS = game:GetService("ReplicatedStorage")
-- edit-time tool: require fresh copies so config edits made this Studio session are picked up (require caches)
local function fresh(mod: ModuleScript): any
	local c = mod:Clone(); c.Name = mod.Name .. "_fresh"; c.Parent = mod.Parent
	local ok, r = pcall(require, c); c:Destroy()
	return ok and r or require(mod)
end
local Config = fresh(RS.Shared.Config)
local SC = fresh(RS.Shared.SystemsConfig)
local Assets = fresh(RS.Shared.Assets)
local ServerStorage = game:GetService("ServerStorage")

local B = {}

-- lobby-local frame: +X runs from spawn toward the WORLDS portal / Stage 1. East floor edge meets Stage 1 (world x = -85).
local ORIGIN = Vector3.new(-235, 0, 0) -- east floor edge (local x = +150) meets Stage 1 at world x = -85
local HX, HZ = 150, 130 -- floor half extents (expanded: room for 13 training zones + egg plaza)
local C = Color3.fromRGB
local PAL = {
	Lav1 = C(196, 182, 238), Lav2 = C(183, 167, 228), Path = C(234, 228, 252), PathEdge = Color3.new(1, 1, 1),
	Lime = C(150, 222, 62), LimeEdge = C(104, 186, 52), Dirt = C(156, 88, 54), Dirt2 = C(138, 76, 46), GrassTop = C(112, 196, 64),
	Pine = C(40, 140, 66), Pine2 = C(58, 164, 78), Trunk = C(96, 62, 40),
	Stone = C(44, 42, 54), Stone2 = C(64, 60, 76), Gold = C(255, 204, 60), Cyan = C(80, 230, 255), Lamp = C(255, 232, 130),
	Portal = C(255, 86, 206), PortalRim = C(255, 214, 246), Ink = C(30, 26, 36),
}
local FONT = Enum.Font.FredokaOne

local root: Model
local function W(x: number, z: number, y: number?): Vector3 return ORIGIN + Vector3.new(x, y or 0, z) end
local function group(name: string, parent: Instance?): Model
	local m = Instance.new("Model"); m.Name = name; m.Parent = parent or root; return m
end
local function P(props: {[string]: any}): BasePart
	local p = Instance.new("Part") :: any
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	if props.Shape then p.Shape = props.Shape end
	for k, v in props do if k ~= "Parent" and k ~= "Shape" then p[k] = v end end
	p.Parent = props.Parent or root
	return p
end
-- block with BOTTOM at y, centred on local (x, z)
local function Blk(parent: Instance, size: Vector3, x: number, z: number, y: number, color: Color3, extra: {[string]: any}?): BasePart
	local t: {[string]: any} = {Size = size, CFrame = CFrame.new(W(x, z, y + size.Y / 2)), Color = color, Parent = parent}
	if extra then for k, v in extra do t[k] = v end end
	return P(t)
end
local function Disc(parent: Instance, d: number, h: number, x: number, z: number, top: number, color: Color3, extra: {[string]: any}?): BasePart
	local t: {[string]: any} = {Shape = Enum.PartType.Cylinder, Size = Vector3.new(h, d, d),
		CFrame = CFrame.new(W(x, z, top - h / 2)) * CFrame.Angles(0, 0, math.rad(90)), Color = color, Parent = parent}
	if extra then for k, v in extra do t[k] = v end end
	return P(t)
end
local STUDS = {Material = Enum.Material.Plastic, TopSurface = Enum.SurfaceType.Studs}
local function merge(a: {[string]: any}, b: {[string]: any}?): {[string]: any}
	local t = table.clone(a); if b then for k, v in b do t[k] = v end end; return t
end

local function text(parent: Instance, s: string, pos: UDim2, size: UDim2, color: Color3, stroke: number?, name: string?): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name or "Label"
	l.BackgroundTransparency = 1
	l.Font = FONT
	l.TextScaled = true
	l.RichText = true
	l.Text = s
	l.TextColor3 = color
	l.Position = pos
	l.Size = size
	local st = Instance.new("UIStroke"); st.Thickness = stroke or 3; st.Color = C(20, 16, 26); st.Parent = l
	l.Parent = parent
	return l
end
local function icon(parent: Instance, key: string, pos: UDim2, size: UDim2): ImageLabel
	local i = Instance.new("ImageLabel")
	i.BackgroundTransparency = 1
	i.Image = Assets.Icon(key)
	i.ScaleType = Enum.ScaleType.Fit
	i.Position = pos
	i.Size = size
	i.Parent = parent
	return i
end
local function billboard(adornee: BasePart, studs: Vector2, offsetY: number, maxDist: number, name: string?): BillboardGui
	local b = Instance.new("BillboardGui")
	b.Name = name or "Billboard"
	b.Size = UDim2.fromScale(studs.X, studs.Y)
	b.StudsOffsetWorldSpace = Vector3.new(0, offsetY, 0)
	b.MaxDistance = maxDist
	b.LightInfluence = 0
	b.Adornee = adornee
	b.Parent = adornee
	return b
end
local function anchor(parent: Instance, x: number, z: number, y: number, name: string?): BasePart
	return P({Name = name or "Anchor", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(W(x, z, y)), Transparency = 1,
		CanCollide = false, CanQuery = false, CanTouch = false, Parent = parent})
end
local function prompt(part: BasePart, action: string, object: string, attrs: {[string]: any})
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = action; pp.ObjectText = object
	pp.HoldDuration = 0; pp.MaxActivationDistance = 11; pp.RequiresLineOfSight = false
	pp.KeyboardKeyCode = Enum.KeyCode.F -- E/R are jutsu keys
	pp.GamepadKeyCode = Enum.KeyCode.ButtonX
	for k, v in attrs do pp:SetAttribute(k, v) end
	pp.Parent = part
end
local function beam(parent: Instance, x: number, z: number, y: number, color: Color3)
	Blk(parent, Vector3.new(1.2, 60, 1.2), x, z, y, color, {Material = Enum.Material.Neon, Transparency = 0.55, CanCollide = false, CastShadow = false, CanQuery = false})
end
local function lantern(parent: Instance, x: number, z: number, glow: boolean?)
	Blk(parent, Vector3.new(2.6, 1, 2.6), x, z, 0.3, PAL.Stone)
	Blk(parent, Vector3.new(1.3, 4.4, 1.3), x, z, 1.3, PAL.Stone)
	local head = Blk(parent, Vector3.new(2.2, 1.8, 2.2), x, z, 5.7, PAL.Lamp, {Material = Enum.Material.Neon})
	Blk(parent, Vector3.new(3, 0.7, 3), x, z, 7.5, PAL.Stone)
	Blk(parent, Vector3.new(1.4, 0.6, 1.4), x, z, 8.2, PAL.Stone)
	if glow then
		local l = Instance.new("PointLight"); l.Color = PAL.Lamp; l.Range = 12; l.Brightness = 0.8; l.Shadows = false; l.Parent = head
	end
end
local function pine(parent: Instance, x: number, z: number, y: number, s: number)
	Blk(parent, Vector3.new(1.6, 4, 1.6) * s, x, z, y, PAL.Trunk)
	Blk(parent, Vector3.new(9, 4, 9) * s, x, z, y + 3.4 * s, PAL.Pine)
	Blk(parent, Vector3.new(6.6, 3.6, 6.6) * s, x, z, y + 6.8 * s, PAL.Pine2)
	Blk(parent, Vector3.new(4.2, 3.2, 4.2) * s, x, z, y + 9.8 * s, PAL.Pine)
	Blk(parent, Vector3.new(2, 2, 2) * s, x, z, y + 12.6 * s, PAL.Pine2)
end

---------------------------------------------------------------- arena: checker floor, grass, cliffs
local function buildArena()
	local g = group("Arena")
	Blk(g, Vector3.new(HX * 2 + 40, 10, HZ * 2 + 40), 0, 0, -10.2, PAL.Dirt2, {Name = "Bedrock"})
	local tile = 20
	for ix = 0, HX * 2 / tile - 1 do
		for iz = 0, HZ * 2 / tile - 1 do
			local x, z = -HX + tile / 2 + ix * tile, -HZ + tile / 2 + iz * tile
			Blk(g, Vector3.new(tile, 2, tile), x, z, -2, (ix + iz) % 2 == 0 and PAL.Lav1 or PAL.Lav2, merge(STUDS, {Name = "Floor"}))
		end
	end
	-- main path spawn -> portal, white edged
	Blk(g, Vector3.new(HX * 2 - 4, 0.3, 16), 1, 0, 0, PAL.Path, merge(STUDS, {Name = "MainPath"}))
	for _, z in {-8.5, 8.5} do Blk(g, Vector3.new(HX * 2 - 4, 0.35, 1), 1, z, 0, PAL.PathEdge) end
	-- lime lawns flanking the path (with darker rims), wide patches around the portal plaza
	local function lawn(x0: number, x1: number, z0: number, z1: number)
		Blk(g, Vector3.new(x1 - x0, 0.32, z1 - z0), (x0 + x1) / 2, (z0 + z1) / 2, -0.02, PAL.LimeEdge)
		Blk(g, Vector3.new(x1 - x0 - 1.6, 0.36, z1 - z0 - 1.6), (x0 + x1) / 2, (z0 + z1) / 2, 0, PAL.Lime, merge(STUDS, {Name = "Lawn"}))
	end
	lawn(-140, 90, -20, -9.5); lawn(-140, 90, 9.5, 20)
	lawn(92, 138, -84, -9.5); lawn(92, 138, 9.5, 84)
end

local function buildCliffs()
	local g = group("Cliffs")
	local rng = Random.new(7)
	local function ring(tier: number)
		local depth, h0 = 12, 7 + tier * 8
		local inner = tier * depth
		-- north/south walls run along x; west/east along z (east leaves a gap for the WORLDS portal)
		for _, side in {-1, 1} do
			for x = -HX - inner - depth, HX + inner + depth - 1, 20 do
				local h = h0 + rng:NextInteger(-2, 3)
				local z = side * (HZ + inner + depth / 2)
				Blk(g, Vector3.new(20, h, depth), x + 10, z, -1, (x // 20) % 2 == 0 and PAL.Dirt or PAL.Dirt2)
				Blk(g, Vector3.new(20, 1.4, depth), x + 10, z, h - 1, PAL.GrassTop, STUDS)
				if tier >= 1 and rng:NextNumber() < 0.55 then pine(g, x + 10 + rng:NextNumber(-5, 5), z + rng:NextNumber(-3, 3), h + 0.4, 1 + tier * 0.25) end
			end
		end
		for z = -HZ, HZ - 1, 20 do
			local h = h0 + rng:NextInteger(-2, 3)
			Blk(g, Vector3.new(depth, h, 20), -(HX + inner + depth / 2), z + 10, -1, (z // 20) % 2 == 0 and PAL.Dirt or PAL.Dirt2)
			Blk(g, Vector3.new(depth, 1.4, 20), -(HX + inner + depth / 2), z + 10, h - 1, PAL.GrassTop, STUDS)
			if tier >= 1 and rng:NextNumber() < 0.55 then pine(g, -(HX + inner + depth / 2) + rng:NextNumber(-3, 3), z + 10, h + 0.4, 1 + tier * 0.25) end
		end
	end
	for tier = 0, 2 do ring(tier) end
	-- east edge: low inner terraces either side of the portal (Stage 1 begins right behind it)
	for _, side in {-1, 1} do
		for z = 18, HZ - 1, 18 do
			local h = 9 + rng:NextInteger(0, 4)
			Blk(g, Vector3.new(10, h, 18), HX - 5, side * (z + 9), -1, PAL.Dirt)
			Blk(g, Vector3.new(10, 1.4, 18), HX - 5, side * (z + 9), h - 1, PAL.GrassTop, STUDS)
			if z > 30 then pine(g, HX - 5, side * (z + 9), h + 0.4, 1.1) end
		end
	end
end

---------------------------------------------------------------- spawn + lantern-lined main path + WORLDS portal
local function buildSpawnAndPath()
	local pos = W(-130, 0, 1.0)
	P({Name = "LobbySpawn", Size = Vector3.new(10, 1, 10), CFrame = CFrame.lookAt(pos, pos + Vector3.xAxis),
		Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false})
	local g = group("PathLanterns")
	local k = 0
	for x = -118, 132, 16 do
		k += 1
		lantern(g, x, -11.5, k % 3 == 0)
		lantern(g, x, 11.5, k % 3 == 0)
	end
end

local function buildPortal()
	local g = group("WorldsPortal")
	local px = 143
	for _, z in {-15, 15} do
		Blk(g, Vector3.new(7, 2, 7), px, z, 0.3, PAL.Stone2)
		Blk(g, Vector3.new(5, 30, 5), px, z, 2.3, PAL.Stone)
	end
	Blk(g, Vector3.new(7, 4, 36), px, 0, 32.3, PAL.Stone)
	Blk(g, Vector3.new(6, 1.5, 38), px, 0, 36.3, PAL.Stone2)
	local header = Blk(g, Vector3.new(1, 3.4, 20), px - 3.6, 0, 32.6, PAL.Ink, {Name = "Header"})
	local sg = Instance.new("SurfaceGui"); sg.Face = Enum.NormalId.Left; sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sg.PixelsPerStud = 30; sg.LightInfluence = 0; sg.Parent = header
	text(sg, "WORLDS", UDim2.fromScale(0.05, 0.08), UDim2.fromScale(0.9, 0.84), Color3.new(1, 1, 1), 3)
	-- glowing ring (original: chakra-spiral rim of 20 blocks + translucent core). Walk through = Stage 1.
	local c = W(px, 0, 15.5)
	for i = 0, 31 do
		local a = i * math.pi * 2 / 32
		P({Size = Vector3.new(1.2, 1.3, 2.4), CFrame = CFrame.new(c) * CFrame.Angles(a, 0, 0) * CFrame.new(0, 0, 11), Color = i % 4 == 0 and PAL.PortalRim or PAL.Portal,
			Material = Enum.Material.Neon, CanCollide = false, CastShadow = false, Parent = g})
	end
	local core = P({Name = "Core", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 21, 21), CFrame = CFrame.new(c), Color = PAL.Portal,
		Material = Enum.Material.Neon, Transparency = 0.3, CanCollide = false, CastShadow = false, Parent = g})
	local l = Instance.new("PointLight"); l.Color = PAL.Portal; l.Range = 26; l.Brightness = 1.6; l.Parent = core
	local step = Blk(g, Vector3.new(6, 0.4, 16), px - 6, 0, 0.3, PAL.Stone2, {Name = "Threshold"})
	prompt(step, "Choose World", "Worlds Portal", {LobbyAction = "Menu", Menu = "Stages"})
	local bb = billboard(anchor(g, px - 3, 0, 4), Vector2.new(12, 2.2), 0, 60, "Hint")
	text(bb, "Walk through ▶ STAGE 1 · LEAF GROVE", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), C(255, 236, 120), 3)
end

---------------------------------------------------------------- left of portal: special pet + leaderboards; right: boss rift
local function buildSpecialPet()
	local g = group("SpecialPet")
	g:SetAttribute("Placeholder", "Visual only — no special-pet product/backend; no prompt.")
	local x, z = 114, -40
	Disc(g, 16, 1.4, x, z, 1.7, PAL.Stone)
	Disc(g, 13, 1, x, z, 2.4, C(255, 110, 40), {Material = Enum.Material.Neon, Transparency = 0.25})
	for _, o in {{-6, -6}, {-6, 6}, {6, -6}, {6, 6}} do
		Blk(g, Vector3.new(1.4, 10, 1.4), x + o[1], z + o[2], 1.7, PAL.Ink)
		Blk(g, Vector3.new(1.6, 1.6, 1.6), x + o[1], z + o[2], 11.7, C(255, 140, 50), {Material = Enum.Material.Neon})
	end
	-- original "chakra fox spirit" statue built from blocks (generic fox, not a licensed character)
	local fox = C(255, 136, 52)
	Blk(g, Vector3.new(6, 5, 9), x, z, 2.4, fox)
	Blk(g, Vector3.new(5, 5, 5), x, z - 5.5, 6, fox)
	Blk(g, Vector3.new(2.4, 1.6, 2.4), x, z - 8.6, 6.6, C(255, 220, 190))
	for _, s in {-1, 1} do
		P({Size = Vector3.new(1.4, 3, 1.4), CFrame = CFrame.new(W(x + s * 1.6, z - 5.5, 12)) * CFrame.Angles(0, 0, math.rad(s * -12)), Color = fox, Parent = g})
		Blk(g, Vector3.new(0.9, 0.9, 0.3), x + s * 1.3, z - 8.05, 8.2, PAL.Ink)
	end
	for t = -1, 1 do
		P({Size = Vector3.new(1.6, 1.6, 8), CFrame = CFrame.new(W(x + t * 2, z + 6, 8)) * CFrame.Angles(math.rad(35), math.rad(t * 20), 0), Color = t == 0 and C(255, 230, 200) or fox, Parent = g})
	end
	beam(g, x - 6, z - 6, 12, C(255, 150, 60)); beam(g, x + 6, z - 6, 12, C(255, 150, 60))
	local bb = billboard(anchor(g, x, z, 16), Vector2.new(10, 4), 0, 90, "Card")
	text(bb, "SPECIAL PET!", UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.4), C(255, 220, 60), 4)
	text(bb, "Chakra Fox Spirit", UDim2.fromScale(0.1, 0.4), UDim2.fromScale(0.8, 0.28), Color3.new(1, 1, 1), 3)
	text(bb, "COMING SOON", UDim2.fromScale(0.2, 0.7), UDim2.fromScale(0.6, 0.28), C(255, 120, 120), 3)
end

local function buildBoards()
	local g = group("Leaderboards")
	for i, d in {{"LifetimeHandSigns", "HAND SIGNS", 54}, {"Trophies", "TROPHIES", 70}, {"Stage", "STAGE", 86}} do
		local x, z = 80 + i * 17, -74 + (i == 2 and -2 or 0)
		local m = group("Board_" .. d[1], g)
		m:SetAttribute("BoardKey", d[1])
		local pos = W(x, z, 9)
		local cf = CFrame.lookAt(pos, Vector3.new(pos.X, pos.Y, pos.Z + 10))
		P({Size = Vector3.new(15, 17, 1), CFrame = cf * CFrame.new(0, 0, 0.6), Color = C(120, 90, 210), Parent = m})
		local panel = P({Name = "Panel", Size = Vector3.new(13.5, 15.5, 0.6), CFrame = cf, Color = C(244, 242, 252), Parent = m})
		P({Size = Vector3.new(15, 2, 1.4), CFrame = cf * CFrame.new(0, 9.4, 0.2), Color = C(120, 90, 210), Parent = m})
		for _, s in {-1, 1} do P({Size = Vector3.new(1.2, 9, 1.2), CFrame = cf * CFrame.new(s * 6.5, -12, 0.6), Color = C(120, 90, 210), Parent = m}) end
		local sg = Instance.new("SurfaceGui"); sg.Name = "BoardGui"; sg.Face = Enum.NormalId.Front; sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sg.PixelsPerStud = 30; sg.LightInfluence = 0; sg.Parent = panel
		text(sg, d[2], UDim2.fromScale(0.04, 0.02), UDim2.fromScale(0.92, 0.12), C(130, 96, 230), 2)
		for r = 1, 8 do
			text(sg, r == 1 and "Updates on live servers" or "", UDim2.fromScale(0.05, 0.16 + (r - 1) * 0.1), UDim2.fromScale(0.9, 0.085), C(60, 50, 80), 0, "Row" .. r)
		end
	end
end

local function buildBossRift()
	local g = group("BossRift")
	g:SetAttribute("Placeholder", "Visual only — no timed boss backend; no prompt.")
	local x, z = 114, 44
	Disc(g, 18, 0.6, x, z, 0.75, C(70, 30, 40))
	local c = W(x, z, 14)
	P({Size = Vector3.new(9, 9, 9), CFrame = CFrame.new(c) * CFrame.Angles(0, 0, math.rad(45)) * CFrame.Angles(math.rad(45), 0, 0), Color = C(70, 20, 90), Material = Enum.Material.Neon, Transparency = 0.15, CanCollide = false, Parent = g})
	P({Size = Vector3.new(6, 20, 1.2), CFrame = CFrame.new(c), Color = C(150, 20, 40), Material = Enum.Material.Neon, CanCollide = false, Parent = g})
	for i = 1, 8 do
		local r = Random.new(i)
		Blk(g, Vector3.new(1.4, 1.4, 1.4) * (0.6 + r:NextNumber()), x + r:NextNumber(-7, 7), z + r:NextNumber(-7, 7), r:NextNumber(4, 22), C(40, 20, 30), {CanCollide = false})
	end
	local bb = billboard(anchor(g, x, z, 27), Vector2.new(12, 3.4), 0, 100, "Card")
	text(bb, "BOSS FIGHT", UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.58), C(255, 120, 60), 4)
	text(bb, "COMING SOON", UDim2.fromScale(0.15, 0.6), UDim2.fromScale(0.7, 0.38), Color3.new(1, 1, 1), 3)
end

---------------------------------------------------------------- training station field (north side)
---------------------------------------------------------------- training station kit (detailed, reference-style builds)
local TEX = {
	Rune = "rbxassetid://123418957532795", Spiral = "rbxassetid://127628361347448", GoldRing = "rbxassetid://71800837774248",
	Target = "rbxassetid://124610263594344", Swirl = "rbxassetid://107310565347443", DummyFace = "rbxassetid://75618960542114",
}
local GLOW = C(255, 238, 110)
local function decal(part: BasePart, face: Enum.NormalId, id: string, transp: number?)
	local d = Instance.new("Decal"); d.Face = face; d.Texture = id; d.Transparency = transp or 0; d.Parent = part
	return d
end
local function R(parent: Instance, size: Vector3, cf: CFrame, color: Color3, extra: {[string]: any}?): BasePart
	local t: {[string]: any} = {Size = size, CFrame = cf, Color = color, Parent = parent}
	if extra then for k, v in extra do t[k] = v end end
	return P(t)
end
local NEON = {Material = Enum.Material.Neon}
local NOCOL = {CanCollide = false, CastShadow = false}
local function glowCap(parent: Instance, x: number, z: number, y: number, s: number?)
	local q = s or 1.5
	R(parent, Vector3.new(q, q, q), CFrame.new(W(x, z, y + q / 2)) * CFrame.Angles(0, math.rad(45), 0), GLOW, merge(NEON, {CanCollide = false}))
end
local function lightAt(part: BasePart, color: Color3, range: number)
	local l = Instance.new("PointLight"); l.Color = color; l.Range = range; l.Brightness = 1.2; l.Shadows = false; l.Parent = part
end

-- shared plinth: dark studded slab, inset themed floor, raised gold rail with glowing caps (reference look)
local function plinth(m: Model, x: number, z: number, y0: number, floorColor: Color3, floorMat: Enum.Material?, rail: boolean?): number
	Blk(m, Vector3.new(16, 1.2, 16), x, z, y0 - 0.9, PAL.Stone, merge(STUDS, {Name = "Base"}))
	Blk(m, Vector3.new(13.6, 1.25, 13.6), x, z, y0 - 0.9, floorColor, {Material = floorMat or Enum.Material.SmoothPlastic, Name = "Floor"})
	local top = y0 + 0.35
	if rail ~= false then
		for _, s in {-1, 1} do
			Blk(m, Vector3.new(15.2, 0.6, 0.6), x, z + s * 7.3, top + 1.6, PAL.Gold)
			Blk(m, Vector3.new(0.6, 0.6, 15.2), x + s * 7.3, z, top + 1.6, PAL.Gold)
			Blk(m, Vector3.new(15.6, 0.35, 0.9), x, z + s * 7.5, top - 0.2, PAL.Gold, NEON)
			Blk(m, Vector3.new(0.9, 0.35, 15.6), x + s * 7.5, z, top - 0.2, PAL.Gold, NEON)
		end
		for _, o in {{-7.3, -7.3}, {-7.3, 7.3}, {7.3, -7.3}, {7.3, 7.3}} do
			Blk(m, Vector3.new(1.3, 2.6, 1.3), x + o[1], z + o[2], top, PAL.Gold)
			glowCap(m, x + o[1], z + o[2], top + 2.6, 1.3)
		end
	end
	return top
end


-- place a generated (Roblox AI mesh) model: scale to fit maxW footprint, bottom at y, yaw in degrees
local function placeMesh(parent: Instance, src: Instance, x: number, z: number, y: number, maxW: number, yaw: number, maxH: number?): Model
	local mdl = (src :: Model):Clone()
	local _, sz = mdl:GetBoundingBox()
	local k = maxW / math.max(sz.X, sz.Z, 0.1)
	if maxH then k = math.min(k, maxH / math.max(sz.Y, 0.1)) end
	mdl:ScaleTo(mdl:GetScale() * k)
	mdl:PivotTo(CFrame.new(W(x, z, y)) * CFrame.Angles(0, math.rad(yaw), 0))
	local bb, sz2 = mdl:GetBoundingBox()
	mdl:PivotTo(mdl:GetPivot() + Vector3.new(0, y - (bb.Position.Y - sz2.Y / 2), 0))
	for _, d in mdl:GetDescendants() do if d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false end end
	mdl.Parent = parent
	return mdl
end
local STATION_BUILD: {[string]: (Model, number, number, number, Color3) -> ()} = {}

STATION_BUILD.ring = function(m, x, z, y0) -- X2: dummy training yard
	local y = plinth(m, x, z, y0, C(122, 210, 84), Enum.Material.Grass, false)
	local wood, woodD = C(168, 116, 70), C(122, 82, 50)
	for _, s in {-1, 1} do -- fence
		for k = -3, 3 do Blk(m, Vector3.new(0.7, 2.6, 0.7), x + k * 2.2, z + s * 7, y, woodD) end
		Blk(m, Vector3.new(14.6, 0.45, 0.4), x, z + s * 7, y + 1.0, wood); Blk(m, Vector3.new(14.6, 0.45, 0.4), x, z + s * 7, y + 2.0, wood)
		for k = -3, 3 do Blk(m, Vector3.new(0.7, 2.6, 0.7), x + s * 7, z + k * 2.2, y, woodD) end
		Blk(m, Vector3.new(0.4, 0.45, 14.6), x + s * 7, z, y + 1.0, wood); Blk(m, Vector3.new(0.4, 0.45, 14.6), x + s * 7, z, y + 2.0, wood)
	end
	for _, d in {{-2.6, -1.5}, {2.6, -1.5}} do -- scarecrow dummies with straw hats
		local dx, dz = x + d[1], z + d[2]
		Blk(m, Vector3.new(0.6, 3, 0.6), dx, dz, y, woodD)
		Blk(m, Vector3.new(2.4, 2.6, 1.6), dx, dz, y + 2.6, C(214, 196, 140))
		Blk(m, Vector3.new(5, 0.6, 0.6), dx, dz, y + 4.3, wood)
		for _, s in {-1, 1} do Blk(m, Vector3.new(0.7, 0.9, 0.7), dx + s * 2.6, dz, y + 3.9, C(214, 196, 140)) end
		local head = Blk(m, Vector3.new(2.2, 2.2, 2.2), dx, dz, y + 5.2, C(236, 222, 176))
		decal(head, Enum.NormalId.Back, TEX.DummyFace)
		local tgt = Blk(m, Vector3.new(1.8, 1.8, 0.2), dx, dz + 0.9, y + 3, Color3.new(1, 1, 1), {Transparency = 1})
		decal(tgt, Enum.NormalId.Back, TEX.Target)
		Disc(m, 4, 0.3, dx, dz, y + 7.7, C(232, 198, 110))
		Disc(m, 2.2, 1.2, dx, dz, y + 8.9, C(232, 198, 110))
		Disc(m, 2.25, 0.4, dx, dz, y + 8.1, C(200, 50, 46))
	end
	for _, t in {{-4.5, 3.5}, {0, 4}} do -- target stands
		local tx, tz = x + t[1], z + t[2]
		Blk(m, Vector3.new(0.4, 3.2, 0.4), tx, tz + 0.6, y, woodD)
		local face = R(m, Vector3.new(2.8, 2.8, 0.4), CFrame.new(W(tx, tz, y + 3.4)) * CFrame.Angles(math.rad(-12), 0, 0), Color3.new(1, 1, 1))
		decal(face, Enum.NormalId.Front, TEX.Target)
		decal(face, Enum.NormalId.Back, TEX.Target)
	end
	local barrel = Disc(m, 2.4, 3, x + 4.6, z + 4.4, y + 3, C(140, 90, 52)); barrel.CFrame = CFrame.new(W(x + 4.6, z + 4.4, y + 1.5)) * CFrame.Angles(0, 0, math.rad(90))
	Disc(m, 2.5, 0.25, x + 4.6, z + 4.4, y + 0.9, PAL.Ink); Disc(m, 2.5, 0.25, x + 4.6, z + 4.4, y + 2.4, PAL.Ink)
	Blk(m, Vector3.new(3, 1.6, 2), x - 4.8, z + 4.6, y, C(226, 196, 100))
	for k = 0, 2 do Blk(m, Vector3.new(1.6, 0.15, 1.6), x - 1 + k * 1.8, z + 1.5, y, C(196, 160, 110)) end
end

STATION_BUILD.shrine = function(m, x, z, y0) -- X3: boxing ring
	local y = plinth(m, x, z, y0, C(240, 240, 246), nil, false)
	local mat = Blk(m, Vector3.new(13, 1, 13), x, z, y, C(244, 244, 250), {Name = "RingMat"})
	decal(mat, Enum.NormalId.Top, TEX.GoldRing)
	y += 1
	local corners = {{-6, -6, C(220, 50, 50)}, {6, 6, C(220, 50, 50)}, {-6, 6, C(50, 100, 230)}, {6, -6, C(50, 100, 230)}}
	for _, c in corners do
		Blk(m, Vector3.new(1.3, 4.4, 1.3), x + c[1], z + c[2], y, c[3])
		Blk(m, Vector3.new(1.5, 0.6, 1.5), x + c[1], z + c[2], y, Color3.new(1, 1, 1))
		glowCap(m, x + c[1], z + c[2], y + 4.4, 1.4)
	end
	local ropes = {C(220, 50, 50), Color3.new(1, 1, 1), C(50, 100, 230)}
	for i, col in ropes do
		local h = y + 1.2 + (i - 1) * 1.1
		for _, s in {-1, 1} do
			Blk(m, Vector3.new(11.6, 0.3, 0.3), x, z + s * 6, h, col); Blk(m, Vector3.new(0.3, 0.3, 11.6), x + s * 6, z, h, col)
		end
	end
	-- punching bag on a gallows behind the ring
	Blk(m, Vector3.new(0.8, 9, 0.8), x - 7.6, z - 7.6, y - 1, PAL.Ink)
	Blk(m, Vector3.new(5, 0.7, 0.7), x - 5.5, z - 7.6, y + 7.4, PAL.Ink)
	Blk(m, Vector3.new(0.2, 1.4, 0.2), x - 3.6, z - 7.6, y + 6, C(90, 90, 96))
	local bag = Disc(m, 2, 3.4, x - 3.6, z - 7.6, y + 6, C(200, 40, 40)); bag.CFrame = CFrame.new(W(x - 3.6, z - 7.6, y + 4.3)) * CFrame.Angles(0, 0, math.rad(90))
	Disc(m, 2.05, 0.4, x - 3.6, z - 7.6, y + 5.2, PAL.Ink); Disc(m, 2.05, 0.4, x - 3.6, z - 7.6, y + 3.2, PAL.Ink)
end

STATION_BUILD.crystal = function(m, x, z, y0, col) -- X5: crystal spire
	local y = plinth(m, x, z, y0, C(60, 70, 110))
	Disc(m, 7, 1, x, z, y + 1, PAL.Stone2); Disc(m, 5, 1, x, z, y + 2, C(90, 100, 150))
	local main = R(m, Vector3.new(2.8, 10, 2.8), CFrame.new(W(x, z, y + 7)) * CFrame.Angles(0, math.rad(45), 0), col, merge(NEON, {Transparency = 0.05}))
	lightAt(main, col, 14)
	for k = 0, 4 do
		local a = k * math.pi * 2 / 5
		R(m, Vector3.new(1.4, 4.5, 1.4), CFrame.new(W(x + math.cos(a) * 2.6, z + math.sin(a) * 2.6, y + 3.8)) * CFrame.Angles(math.cos(a) * 0.35, a, math.sin(a) * 0.35), col:Lerp(Color3.new(1, 1, 1), 0.3), merge(NEON, {Transparency = 0.15}))
	end
	for k = 0, 3 do R(m, Vector3.new(0.8, 0.8, 0.8), CFrame.new(W(x + (k < 2 and -4 or 4), z + (k % 2 == 0 and -4 or 4), y + 6 + k)) * CFrame.Angles(0.6, 0.6, 0), col, merge(NEON, NOCOL)) end
end

STATION_BUILD.furnace = function(m, x, z, y0) -- X7: blacksmith forge
	local y = plinth(m, x, z, y0, C(70, 60, 60), Enum.Material.Cobblestone)
	Blk(m, Vector3.new(7, 6, 6), x, z - 2, y, C(40, 38, 44), {Name = "Forge"})
	Blk(m, Vector3.new(7.6, 0.8, 6.6), x, z - 2, y + 6, C(60, 56, 64))
	Blk(m, Vector3.new(3.6, 2.6, 0.3), x, z + 1.05, y + 1.4, C(255, 110, 30), NEON)
	Blk(m, Vector3.new(4.4, 0.5, 0.4), x, z + 1.15, y + 4.2, C(90, 86, 96))
	Blk(m, Vector3.new(2.4, 6, 2.4), x + 2, z - 3.4, y + 6.8, C(60, 56, 64))
	Blk(m, Vector3.new(3, 0.8, 3), x + 2, z - 3.4, y + 12.8, C(40, 38, 44))
	local ember = Blk(m, Vector3.new(1.6, 1.6, 1.6), x + 2, z - 3.4, y + 13.6, C(255, 140, 40), merge(NEON, NOCOL)); lightAt(ember, C(255, 130, 40), 12)
	Blk(m, Vector3.new(1.8, 1.6, 1.4), x - 3.6, z + 4, y, C(90, 90, 100)); Blk(m, Vector3.new(3.6, 1, 1.8), x - 3.6, z + 4, y + 1.6, C(110, 110, 122))
	Blk(m, Vector3.new(0.4, 0.4, 2.6), x - 3.2, z + 4, y + 2.8, C(150, 110, 70)); Blk(m, Vector3.new(1, 0.8, 0.8), x - 3.2, z + 5, y + 2.6, C(120, 120, 130))
	Blk(m, Vector3.new(1.4, 1.4, 1.4), x + 4.2, z + 4.4, y, C(255, 200, 60), NEON)
end

STATION_BUILD.gate = function(m, x, z, y0) -- X10: torii dojo on raked sand
	local y = plinth(m, x, z, y0, C(232, 222, 196), Enum.Material.Sand)
	for k = -2, 2 do Blk(m, Vector3.new(12, 0.1, 0.3), x, z + k * 2, y, C(208, 196, 168)) end
	for _, s in {-1, 1} do Blk(m, Vector3.new(1.2, 8, 1.2), x + s * 3.6, z, y, C(206, 56, 44)); Blk(m, Vector3.new(1.8, 0.8, 1.8), x + s * 3.6, z, y, PAL.Ink) end
	Blk(m, Vector3.new(10.6, 1, 1.6), x, z, y + 8, PAL.Ink)
	Blk(m, Vector3.new(9.4, 0.7, 1.1), x, z, y + 6.6, C(206, 56, 44))
	for _, s in {-1, 1} do R(m, Vector3.new(1.8, 1, 1.6), CFrame.new(W(x + s * 5.6, z, y + 8.7)) * CFrame.Angles(0, 0, math.rad(s * 12)), PAL.Ink) end
	Blk(m, Vector3.new(1.4, 1.6, 0.3), x, z, y + 7.1, PAL.Gold)
	for _, s in {-1, 1} do
		Blk(m, Vector3.new(1.6, 0.6, 1.6), x + s * 4.5, z + 4.5, y, C(170, 170, 178))
		Blk(m, Vector3.new(0.7, 1.8, 0.7), x + s * 4.5, z + 4.5, y + 0.6, C(170, 170, 178))
		Blk(m, Vector3.new(1.4, 1.1, 1.4), x + s * 4.5, z + 4.5, y + 2.4, GLOW, NEON)
		Blk(m, Vector3.new(2, 0.5, 2), x + s * 4.5, z + 4.5, y + 3.5, C(150, 150, 158))
	end
end

STATION_BUILD.dome = function(m, x, z, y0, col) -- X15: chakra dome
	local y = plinth(m, x, z, y0, C(40, 60, 90))
	Disc(m, 10, 0.6, x, z, y + 0.6, C(70, 100, 140))
	local dome = P({Shape = Enum.PartType.Ball, Size = Vector3.new(10, 10, 10), CFrame = CFrame.new(W(x, z, y + 0.3)), Color = C(160, 220, 255), Material = Enum.Material.Glass, Transparency = 0.55, CanCollide = false, Parent = m})
	dome.Name = "Dome"
	for k = 0, 7 do -- glowing ribs
		local a = k * math.pi / 4
		for j = 1, 4 do
			local e = j * math.pi / 10
			R(m, Vector3.new(0.4, 0.4, 0.4), CFrame.new(W(x + math.cos(a) * math.cos(e) * 5, z + math.sin(a) * math.cos(e) * 5, y + 0.3 + math.sin(e) * 5)), C(140, 230, 255), merge(NEON, NOCOL))
		end
	end
	local core = P({Shape = Enum.PartType.Ball, Size = Vector3.new(2.6, 2.6, 2.6), CFrame = CFrame.new(W(x, z, y + 2.6)), Color = col, Material = Enum.Material.Neon, CanCollide = false, Parent = m})
	lightAt(core, col, 14)
	Disc(m, 2, 1.4, x, z, y + 1.4, PAL.Stone2)
end

STATION_BUILD.portal = function(m, x, z, y0, col) -- X20: obsidian rune shrine (reference-style)
	local y = plinth(m, x, z, y0, C(30, 26, 40), Enum.Material.Slate, false)
	local floorRune = Blk(m, Vector3.new(11, 0.1, 11), x, z, y, C(30, 26, 40), {Transparency = 1, CanCollide = false})
	decal(floorRune, Enum.NormalId.Top, TEX.Rune)
	local ob = C(28, 24, 36)
	for _, p in {{-6.5, -6.5, 9}, {6.5, -6.5, 7}, {-6.5, 6.5, 6}, {6.5, 6.5, 8}} do -- obsidian pillars with neon strips
		Blk(m, Vector3.new(2.2, p[3], 2.2), x + p[1], z + p[2], y, ob)
		Blk(m, Vector3.new(0.3, p[3] - 2.4, 0.6), x + p[1] + (p[1] < 0 and 1.15 or -1.15), z + p[2], y + 1.2, col, NEON)
		Blk(m, Vector3.new(2.6, 0.8, 2.6), x + p[1], z + p[2], y + p[3], C(44, 38, 56))
	end
	Blk(m, Vector3.new(15.8, 3, 1.4), x, z - 7.5, y - 0.3, ob) -- back wall
	Blk(m, Vector3.new(15.8, 0.3, 0.2), x, z - 6.75, y + 2.4, col, NEON)
	-- upright rune disc
	local c = W(x - 1.5, z - 4.8, y + 6)
	local disc = R(m, Vector3.new(7, 7, 0.3), CFrame.new(c) * CFrame.Angles(0, math.rad(10), 0), ob, {Transparency = 1, CanCollide = false})
	decal(disc, Enum.NormalId.Back, TEX.Rune); decal(disc, Enum.NormalId.Front, TEX.Rune)
	local glowDisc = P({Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 7.4, 7.4), CFrame = CFrame.new(c - Vector3.new(0, 0, 0.3)) * CFrame.Angles(0, math.rad(100), 0), Color = col, Material = Enum.Material.Neon, Transparency = 0.8, CanCollide = false, Parent = m})
	lightAt(glowDisc, col, 16)
	Disc(m, 3, 1.2, x + 1.5, z + 1, y + 1.2, ob); Disc(m, 2.2, 0.6, x + 1.5, z + 1, y + 1.8, C(44, 38, 56))
	for k, f in {{-4, 3, 8}, {4.5, -2, 10}, {3, 5, 6.5}, {-2.5, -1, 11}} do -- floating cubes
		local cube = R(m, Vector3.new(1.6, 1.6, 1.6), CFrame.new(W(x + f[1], z + f[2], y + f[3])) * CFrame.Angles(k * 0.5, k * 0.7, 0.3), ob, NOCOL)
		cube.Name = "FloatCube"
		R(m, Vector3.new(0.5, 0.5, 0.2), cube.CFrame * CFrame.new(0, 0, -0.85), col, merge(NEON, NOCOL))
	end
end

STATION_BUILD.blossom = function(m, x, z, y0) -- X25: sakura garden
	local y = plinth(m, x, z, y0, C(150, 210, 110), Enum.Material.Grass)
	local pond = Blk(m, Vector3.new(6, 0.2, 4), x + 2.5, z + 3, y, C(110, 200, 255), {Material = Enum.Material.Glass, Transparency = 0.15, CanCollide = false})
	pond.Name = "Pond"
	for k = -1, 1 do Blk(m, Vector3.new(1.6, 0.4 + (1 - k * k) * 0.4, 1.8), x + 2.5 + k * 1.5, z + 3, y + 0.1, C(206, 64, 56)) end
	Blk(m, Vector3.new(1.4, 6, 1.4), x - 3, z - 2, y, C(110, 70, 60))
	R(m, Vector3.new(1, 4, 1), CFrame.new(W(x - 1.8, z - 2, y + 6.4)) * CFrame.Angles(0, 0, math.rad(-35)), C(110, 70, 60))
	for _, c in {{-3, -2, 7, 8, 3, 7}, {-1, -2.5, 9.5, 6, 2.6, 6}, {-4.5, -1, 9, 5, 2.4, 5}, {-2.5, -3, 11.4, 4, 2, 4}} do
		Blk(m, Vector3.new(c[4], c[5], c[6]), x + c[1], z + c[2], y + c[3], (c[3] % 2 > 1) and C(255, 196, 222) or C(255, 170, 206))
	end
	for k = 1, 10 do local r = Random.new(k); Blk(m, Vector3.new(0.6, 0.08, 0.6), x + r:NextNumber(-6, 6), z + r:NextNumber(-6, 6), y, C(255, 186, 214), NOCOL) end
	Blk(m, Vector3.new(1.4, 0.5, 1.4), x + 4.5, z - 4.5, y, C(170, 170, 178)); Blk(m, Vector3.new(0.6, 1.6, 0.6), x + 4.5, z - 4.5, y + 0.5, C(170, 170, 178))
	Blk(m, Vector3.new(1.2, 1, 1.2), x + 4.5, z - 4.5, y + 2.1, GLOW, NEON); Blk(m, Vector3.new(1.8, 0.4, 1.8), x + 4.5, z - 4.5, y + 3.1, C(150, 150, 158))
end

STATION_BUILD.orb = function(m, x, z, y0, col) -- X35: crimson orb altar
	local y = plinth(m, x, z, y0, C(60, 20, 30))
	Disc(m, 8, 1, x, z, y + 1, PAL.Stone2); Disc(m, 6, 1, x, z, y + 2, C(90, 30, 40)); Disc(m, 3, 3, x, z, y + 5, PAL.Stone2)
	local orb = P({Shape = Enum.PartType.Ball, Size = Vector3.new(5, 5, 5), CFrame = CFrame.new(W(x, z, y + 8)), Color = col, Material = Enum.Material.Neon, Transparency = 0.05, CanCollide = false, Parent = m})
	lightAt(orb, col, 18)
	for k = 0, 1 do
		R(m, Vector3.new(0.3, 7.6, 7.6), CFrame.new(W(x, z, y + 8)) * CFrame.Angles(0, k * math.pi / 2, math.rad(70)), col, merge(NEON, {Shape = Enum.PartType.Cylinder, Transparency = 0.75, CanCollide = false}))
	end
	for _, o in {{-5, -5}, {5, -5}, {-5, 5}, {5, 5}} do
		Blk(m, Vector3.new(1, 4, 1), x + o[1], z + o[2], y, PAL.Ink); Blk(m, Vector3.new(1.2, 1.2, 1.2), x + o[1], z + o[2], y + 4, col, NEON)
	end
end

STATION_BUILD.garden = function(m, x, z, y0) -- X50: glowing mushroom grove
	local y = plinth(m, x, z, y0, C(70, 110, 60), Enum.Material.Grass)
	for k, mu in {{-3, -3, 1.4, C(255, 90, 160)}, {3, -2, 1.1, C(120, 220, 255)}, {-1, 3, 1.7, C(255, 200, 70)}, {4, 4, 0.9, C(255, 90, 160)}, {0, -0.5, 1.2, C(170, 120, 255)}} do
		local s = mu[3]
		Blk(m, Vector3.new(0.9, 2.6, 0.9) * s, x + mu[1], z + mu[2], y, C(240, 236, 220))
		local cap = P({Shape = Enum.PartType.Ball, Size = Vector3.new(3.6, 3.6, 3.6) * s, CFrame = CFrame.new(W(x + mu[1], z + mu[2], y + 2.6 * s)), Color = mu[4], Material = Enum.Material.Neon, Transparency = 0.1, CanCollide = false, Parent = m})
		if k == 3 then lightAt(cap, mu[4], 14) end
	end
	for k = 1, 8 do local r = Random.new(50 + k); Blk(m, Vector3.new(0.7, 0.7, 0.7), x + r:NextNumber(-6, 6), z + r:NextNumber(-6, 6), y, k % 2 == 0 and C(255, 120, 190) or C(255, 230, 100)) end
end

STATION_BUILD.tower = function(m, x, z, y0, col) -- X100: pagoda tower
	local y = plinth(m, x, z, y0, C(232, 222, 196), Enum.Material.Sand)
	local yy = y
	for k = 0, 3 do
		local w = 7 - k * 1.3
		Blk(m, Vector3.new(w, 2.6, w), x, z, yy, C(244, 236, 226))
		for _, o in {{-1, -1}, {-1, 1}, {1, -1}, {1, 1}} do Blk(m, Vector3.new(0.5, 2.6, 0.5), x + o[1] * (w / 2 - 0.2), z + o[2] * (w / 2 - 0.2), yy, C(200, 56, 50)) end
		Blk(m, Vector3.new(w + 2.6, 0.6, w + 2.6), x, z, yy + 2.6, C(52, 84, 112))
		Blk(m, Vector3.new(w + 1.2, 0.5, w + 1.2), x, z, yy + 3.2, C(40, 64, 86))
		yy += 3.7
	end
	Blk(m, Vector3.new(0.5, 3, 0.5), x, z, yy, PAL.Gold)
	local top = P({Shape = Enum.PartType.Ball, Size = Vector3.new(1.4, 1.4, 1.4), CFrame = CFrame.new(W(x, z, yy + 3.4)), Color = col, Material = Enum.Material.Neon, CanCollide = false, Parent = m})
	lightAt(top, col, 12)
end

STATION_BUILD.beam = function(m, x, z, y0, col) -- X250: golden throne before a spiral portal (reference-style)
	local y = plinth(m, x, z, y0, C(60, 20, 110))
	local swirl = Blk(m, Vector3.new(13.4, 0.1, 13.4), x, z, y, Color3.new(1, 1, 1), {Transparency = 1, CanCollide = false})
	decal(swirl, Enum.NormalId.Top, TEX.Swirl, 0.1)
	Blk(m, Vector3.new(8, 0.8, 7), x, z - 1.5, y, C(244, 240, 250)); Blk(m, Vector3.new(6.4, 0.8, 5.6), x, z - 2, y + 0.8, PAL.Gold)
	Blk(m, Vector3.new(5, 0.8, 4.4), x, z - 2.4, y + 1.6, C(244, 240, 250))
	local ty = y + 2.4
	Blk(m, Vector3.new(3.4, 1, 3), x, z - 2.6, ty, C(150, 90, 230)) -- seat
	Blk(m, Vector3.new(3.4, 5.6, 0.8), x, z - 4.2, ty, PAL.Gold) -- back
	for _, s in {-1, 1} do
		Blk(m, Vector3.new(0.7, 2, 3), x + s * 2, z - 2.6, ty + 1, PAL.Gold)
		Blk(m, Vector3.new(0.6, 6, 0.6), x + s * 3.2, z - 4.4, ty, PAL.Gold); glowCap(m, x + s * 3.2, z - 4.4, ty + 6, 1.1)
	end
	R(m, Vector3.new(0.4, 1.8, 0.4), CFrame.new(W(x + 2.6, z - 1, ty + 3.6)) * CFrame.Angles(0, 0, math.rad(-20)), PAL.Gold)
	-- spiral portal disc behind the throne
	local c = W(x, z - 6.2, y + 9)
	local disc = R(m, Vector3.new(10, 10, 0.3), CFrame.new(c), C(120, 60, 220), {Transparency = 1, CanCollide = false})
	decal(disc, Enum.NormalId.Back, TEX.Spiral); decal(disc, Enum.NormalId.Front, TEX.Spiral)
	for i = 0, 23 do
		local a = i * math.pi * 2 / 24
		R(m, Vector3.new(1, 1, 0.6), CFrame.new(c) * CFrame.Angles(0, 0, a) * CFrame.new(0, 5.3, 0), i % 2 == 0 and PAL.Gold or C(255, 236, 160), merge(NEON, NOCOL))
	end
	local glow = P({Shape = Enum.PartType.Ball, Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(c), Transparency = 1, CanCollide = false, Parent = m})
	lightAt(glow, col, 20)
end

local function buildStations()
	local g = group("TrainingStations")
	g:SetAttribute("Note", "ZoneMult applied server-side by GameService from SystemsConfig.TrainingStations (Rebirths gate).")
	local cols, rows = {-118, -88, -58, -28, 2, 32, 62}, {-46, -82}
	-- st.Theme names a generated concept model in ServerStorage.LobbyAssets.Stations, else a part build below
	local stationAssets = ServerStorage:FindFirstChild("LobbyAssets") and ServerStorage.LobbyAssets:FindFirstChild("Stations")
	for i, st in SC.TrainingStations do
		local row = math.ceil(i / #cols)
		local col = (i - 1) % #cols + 1
		local x, z = cols[col], rows[row]
		local m = group("Station" .. i, g)
		m:SetAttribute("StationIndex", i)
		local y0 = 0.6 + (row - 1) * 0.5
		local src = stationAssets and stationAssets:FindFirstChild(st.Theme)
		if src then
			local top = plinth(m, x, z, y0, C(58, 54, 70))
			placeMesh(m, src, x, z, top - 0.1, 12.8, 0, 13).Name = "StationModel"
		else
			local build = STATION_BUILD[st.Theme] or STATION_BUILD.crystal
			build(m, x, z, y0, st.Color)
		end
		if st.Pass then -- Robux zone: gold aura floor + unlock prompt (game pass; locked until the owner creates it)
			Blk(m, Vector3.new(18, 0.3, 18), x, z, y0 - 1.05, C(255, 200, 40), {Material = Enum.Material.Neon, Transparency = 0.25, CanCollide = false, Name = "PassGlow"})
			local base = m:FindFirstChild("Base", true) :: BasePart?
			if base then prompt(base, "Unlock", st.Name .. " (R$ " .. st.Robux .. ")", {LobbyAction = "Pass", Pass = st.Pass}) end
		end
		local zone = P({Name = "Zone", Size = Vector3.new(16, 12, 16), CFrame = CFrame.new(W(x, z, y0 + 6)), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Parent = m})
		zone:SetAttribute("StationIndex", i)
		if st.Mult >= 25 then beam(m, x + 6.5, z - 6.5, y0 + 3, st.Color) end
		local bb = billboard(anchor(m, x, z, y0 + 16), Vector2.new(12, 4.6), 0, 130, "Card")
		text(bb, "X" .. Config.Format(st.Mult) .. " HAND SIGNS", UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.52), st.Color, 4, "Mult")
		if st.Pass then
			icon(bb, "Robux", UDim2.fromScale(0.26, 0.54), UDim2.fromScale(0.16, 0.44))
			text(bb, tostring(st.Robux), UDim2.fromScale(0.43, 0.55), UDim2.fromScale(0.34, 0.42), C(255, 214, 60), 4, "Price")
		else
			icon(bb, "Rebirth", UDim2.fromScale(0.3, 0.54), UDim2.fromScale(0.16, 0.44))
			text(bb, Config.Format(st.Rebirths or 0), UDim2.fromScale(0.47, 0.55), UDim2.fromScale(0.3, 0.42), (st.Rebirths or 0) > 0 and C(255, 90, 90) or C(120, 255, 130), 4, "Price")
		end
	end
	local s = anchor(g, -62, -28, 4, "SignAnchor")
	local bb = billboard(s, Vector2.new(16, 2.4), 0, 80, "Card")
	text(bb, "TRAINING ZONES · stand inside to multiply HAND SIGNS", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), Color3.new(1, 1, 1), 3)
end

---------------------------------------------------------------- hand sign showcase (south, near spawn): 2 rows x 7
local function buildShowcase()
	local g = group("SignShowcase")
	g:SetAttribute("Note", "Pad colours/text are per-player, set by the client Lobby module from server state.")
	local x0, dx = -112, 14
	Blk(g, Vector3.new(7 * dx + 6, 1, 13), x0 + 3 * dx, 36, -0.4, PAL.Stone, {Name = "FrontPlatform"})
	Blk(g, Vector3.new(7 * dx + 6, 6.4, 13), x0 + 3 * dx, 50, -0.4, PAL.Stone2, {Name = "BackPlatform"}) -- raised tier like the reference
	Blk(g, Vector3.new(7 * dx + 6, 0.6, 1), x0 + 3 * dx, 29.6, 0.4, PAL.Gold, {Material = Enum.Material.Neon})
	for i, id in Config.HandSignOrder do
		local s = Config.HandSigns[id]
		local back = i > 7
		local k = back and i - 8 or i - 1
		local x, z = x0 + k * dx, back and 50 or 36
		local top = back and 6 or 0.6
		local m = group("Pad_" .. id, g)
		m:SetAttribute("SignId", id)
		local pad = Blk(m, Vector3.new(8, 0.5, 8), x, z, top, C(220, 60, 60), {Name = "Pad", Material = Enum.Material.Neon, Transparency = 0.1})
		prompt(pad, "Buy", s.Name, {LobbyAction = "Sign", SignId = id})
		-- floating transparent hand-sign art only (no tile, frame or backing), like the reference's floating eyes
		local iconId = Assets.SignIcons and Assets.SignIcons[id]
		local art = billboard(anchor(m, x, z, top + 11, "ArtAnchor"), Vector2.new(7.5, 7.5), 0, 140, "Emblem")
		if iconId then
			local img = Instance.new("ImageLabel"); img.Name = "Art"; img.BackgroundTransparency = 1; img.Image = iconId
			img.ScaleType = Enum.ScaleType.Fit; img.Size = UDim2.fromScale(1, 1); img.Parent = art
		else
			text(art, "?", UDim2.fromScale(0.2, 0.1), UDim2.fromScale(0.6, 0.8), Color3.new(1, 1, 1), 5) -- no approved art yet
		end
		local a = anchor(m, x, z, top + 5.2)
		local bb = billboard(a, Vector2.new(8.4, 4.6), 0, 75, "Card")
		text(bb, s.Name, UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.32), s.Color:Lerp(Color3.new(1, 1, 1), 0.45), 3, "SignName")
		text(bb, "x" .. Config.Format(s.Multiplier) .. " Hand Signs", UDim2.fromScale(0.05, 0.32), UDim2.fromScale(0.9, 0.24), C(255, 214, 90), 2, "Mult")
		text(bb, "", UDim2.fromScale(0, 0.56), UDim2.fromScale(1, 0.18), Color3.new(1, 1, 1), 2, "Req")
		icon(bb, "Trophy", UDim2.fromScale(0.16, 0.74), UDim2.fromScale(0.18, 0.26)).Name = "PriceIcon"
		text(bb, "", UDim2.fromScale(0.05, 0.75), UDim2.fromScale(0.9, 0.25), Color3.new(1, 1, 1), 3, "Status")
	end
end

---------------------------------------------------------------- egg walkway (south): Fuse Machine + Boss Shop first, then eggs ascending
local function buildEggs()
	local g = group("EggHatchery")
	Blk(g, Vector3.new(270, 0.4, 20), 10, 100, 0, PAL.Path, merge(STUDS, {Name = "EggWalk"}))
	for _, z in {89.5, 110.5} do Blk(g, Vector3.new(270, 0.45, 1.2), 10, z, 0, PAL.LimeEdge) end
	local n = #SC.EggOrder
	local eggAssets = ServerStorage:FindFirstChild("LobbyAssets") and ServerStorage.LobbyAssets:FindFirstChild("Eggs")
	for i, eggId in SC.EggOrder do
		local egg = SC.Eggs[eggId]
		local x, z = -56 + (i - 1) * (190 / (n - 1)), 100
		local m = group("Egg_" .. eggId, g)
		local glowCol = egg.Color:Lerp(Color3.new(1, 1, 1), 0.2)
		Disc(m, 14, 0.8, x, z, 1.1, PAL.Stone)
		Disc(m, 13, 0.82, x, z, 1.12, glowCol, {Material = Enum.Material.Neon, Transparency = 0.35})
		Disc(m, 11.4, 0.86, x, z, 1.16, PAL.Stone2, STUDS)
		local top = 1.16
		local hit = Blk(m, Vector3.new(8, 3, 8), x, z, top, Color3.new(1, 1, 1), {Name = "Pedestal", Transparency = 1, CanCollide = false})
		prompt(hit, "Hatch", egg.Name .. " · " .. Config.Format(egg.Cost) .. " Trophies", {LobbyAction = "Hatch", EggId = eggId})
		local src = eggAssets and eggAssets:FindFirstChild(eggId)
		if src then
			placeMesh(m, src, x, z, top, 10.5, 180, 14).Name = "EggModel"
			if eggId == "Summoning" then -- Flame egg: real flames around the chained rock egg (concept sheet)
				local f = Instance.new("Fire"); f.Size = 7; f.Heat = 7; f.Color = C(255, 110, 30); f.SecondaryColor = C(255, 214, 80); f.Parent = hit
			end
		else
			local e = P({Name = "Egg", Shape = Enum.PartType.Ball, Size = Vector3.new(5, 5, 5), CFrame = CFrame.new(W(x, z, top + 3.4)), Color = egg.Color, Parent = m})
			local mesh = Instance.new("SpecialMesh"); mesh.MeshType = Enum.MeshType.Sphere; mesh.Scale = Vector3.new(1, 1.28, 1); mesh.Parent = e
		end
		local l = Instance.new("PointLight"); l.Color = glowCol; l.Range = 9; l.Brightness = 0.7; l.Shadows = false; l.Parent = hit
		if i >= n - 1 then beam(m, x, z + 4.5, 3, egg.Color) end
		local bb = billboard(anchor(m, x, z, top + 16), Vector2.new(9, 4.2), 0, 90, "Card")
		text(bb, "STAGE " .. egg.Stage, UDim2.fromScale(0.1, 0), UDim2.fromScale(0.8, 0.26), Color3.new(1, 1, 1), 2)
		text(bb, string.upper(egg.Name), UDim2.fromScale(0, 0.26), UDim2.fromScale(1, 0.38), egg.Color:Lerp(Color3.new(1, 1, 1), 0.35), 3)
		icon(bb, "Trophy", UDim2.fromScale(0.22, 0.66), UDim2.fromScale(0.16, 0.32))
		text(bb, Config.Format(egg.Cost), UDim2.fromScale(0.4, 0.66), UDim2.fromScale(0.4, 0.32), C(255, 214, 90), 3)
	end
	-- placeholders at the start of the walkway (reference order: Boss Shop, Fuse Machine, then eggs)
	local function placeholder(name: string, x: number, title: string, build: (Model) -> ())
		local m = group(name, g)
		m:SetAttribute("Placeholder", "Visual only — backend not built; no prompt or remote is exposed.")
		build(m)
		local bb = billboard(anchor(m, x, 100, 13), Vector2.new(10, 3.2), 0, 90, "Card")
		text(bb, title, UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.58), C(255, 150, 230), 4)
		text(bb, "COMING SOON", UDim2.fromScale(0.15, 0.6), UDim2.fromScale(0.7, 0.38), C(255, 120, 120), 3)
	end
	placeholder("BossShop", -112, "BOSS SHOP", function(m)
		Blk(m, Vector3.new(12, 1, 8), -112, 100, 0.3, PAL.Stone)
		Blk(m, Vector3.new(10, 4, 4), -112, 98, 1.3, C(200, 50, 46))
		for _, s in {-5, 5} do Blk(m, Vector3.new(0.9, 9, 0.9), -112 + s, 102, 1.3, PAL.Ink) end
		Blk(m, Vector3.new(13, 1.2, 7), -112, 100, 10.3, C(200, 50, 46)); Blk(m, Vector3.new(11, 1, 5), -112, 100, 11.5, PAL.Ink)
		Blk(m, Vector3.new(8, 1.8, 0.3), -112, 96.6, 7.5, C(255, 214, 90), {Material = Enum.Material.Neon})
	end)
	placeholder("FuseMachine", -86, "FUSE MACHINE", function(m)
		Blk(m, Vector3.new(10, 1.4, 10), -86, 100, 0.3, PAL.Stone)
		for _, o in {{-4, -4}, {-4, 4}, {4, -4}, {4, 4}} do Blk(m, Vector3.new(1.4, 3, 1.4), -86 + o[1], 100 + o[2], 1.7, C(240, 240, 250)) end
		Blk(m, Vector3.new(5, 6, 5), -86, 100, 1.7, C(110, 60, 200), {Material = Enum.Material.Glass, Transparency = 0.35})
		P({Shape = Enum.PartType.Ball, Size = Vector3.new(3, 3, 3), CFrame = CFrame.new(W(-86, 100, 4.7)), Color = C(220, 120, 255), Material = Enum.Material.Neon, CanCollide = false, Parent = m})
		Blk(m, Vector3.new(6, 1, 6), -86, 100, 7.7, C(240, 240, 250))
	end)
end

---------------------------------------------------------------- stage-1 connection (reversible)
local function backupsFolder(): Folder
	local b = ServerStorage:FindFirstChild("Backups") or Instance.new("Folder")
	b.Name = "Backups"; b.Parent = ServerStorage
	return b :: Folder
end
local function openStage1()
	local s1 = workspace:FindFirstChild("StageCourse") and workspace.StageCourse:FindFirstChild("Stage01")
	if s1 then
		for _, c in s1:GetChildren() do
			if c:IsA("BasePart") and c.Name == "Part" and math.abs(c.Position.X + 87) < 1 and c.Size.Y >= 20 and c.Size.Z >= 150 then
				c:SetAttribute("OriginalParent", c:GetFullName()); c.Name = "Stage01_StartWall"; c.Parent = backupsFolder()
			end
		end
	end
	local sp = workspace:FindFirstChild("SpawnLocation") :: SpawnLocation?
	if sp then
		if sp:GetAttribute("OriginalCFrame") == nil then sp:SetAttribute("OriginalCFrame", sp.CFrame) end
		sp.CFrame = CFrame.lookAt(W(-130, 0, 0.6), W(0, 0, 0.6))
		sp.Transparency = 1; sp.CanCollide = false
		local d = sp:FindFirstChildOfClass("Decal"); if d then d.Transparency = 1 end
	end
end

function B.Revert()
	local old = workspace:FindFirstChild("Lobby"); if old then old:Destroy() end
	local wall = backupsFolder():FindFirstChild("Stage01_StartWall")
	if wall then wall.Name = "Part"; wall.Parent = workspace.StageCourse.Stage01 end
	local sp = workspace:FindFirstChild("SpawnLocation") :: SpawnLocation?
	if sp and sp:GetAttribute("OriginalCFrame") then
		sp.CFrame = sp:GetAttribute("OriginalCFrame"); sp.Transparency = 0; sp.CanCollide = true
		local d = sp:FindFirstChildOfClass("Decal"); if d then d.Transparency = 0 end
	end
end

function B.Build(): number
	local old = workspace:FindFirstChild("Lobby"); if old then old:Destroy() end
	root = Instance.new("Model")
	root.Name = "Lobby"
	root:SetAttribute("BuiltBy", "ServerStorage.Tools.LobbyBuilder v2 (issue #14, reference-matched layout)")
	buildArena(); task.wait()
	buildCliffs(); task.wait()
	buildSpawnAndPath()
	buildPortal()
	buildSpecialPet()
	buildBoards()
	buildBossRift(); task.wait()
	buildStations(); task.wait()
	buildShowcase()
	buildEggs(); task.wait()
	root.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	root.WorldPivot = CFrame.new(ORIGIN)
	root.Parent = workspace
	openStage1()
	local n = 0
	for _, d in root:GetDescendants() do if d:IsA("BasePart") then n += 1 end end
	return n
end

return B
