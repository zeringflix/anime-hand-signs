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
local Assets = require(RS.Shared.Assets)
local ServerStorage = game:GetService("ServerStorage")

local B = {}

-- lobby-local frame: +X runs from spawn toward the WORLDS portal / Stage 1. East floor edge meets Stage 1 (world x = -85).
local ORIGIN = Vector3.new(-185, 0, 0)
local HX, HZ = 100, 90 -- floor half extents
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
	lawn(-92, 46, -20, -9.5); lawn(-92, 46, 9.5, 20)
	lawn(48, 88, -64, -9.5); lawn(48, 88, 9.5, 64)
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
	local pos = W(-84, 0, 1.0)
	P({Name = "LobbySpawn", Size = Vector3.new(10, 1, 10), CFrame = CFrame.lookAt(pos, pos + Vector3.xAxis),
		Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false})
	local g = group("PathLanterns")
	local k = 0
	for x = -70, 82, 16 do
		k += 1
		lantern(g, x, -11.5, k % 3 == 0)
		lantern(g, x, 11.5, k % 3 == 0)
	end
end

local function buildPortal()
	local g = group("WorldsPortal")
	local px = 93
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
	local x, z = 68, -34
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
		local x, z = d[3] - 8, -58 + (i == 2 and -2 or 0)
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
	local x, z = 68, 36
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
local function centerpiece(g: Model, theme: string, x: number, z: number, y: number, color: Color3)
	if theme == "ring" then
		for _, o in {{-4, -4}, {-4, 4}, {4, -4}, {4, 4}} do Blk(g, Vector3.new(0.6, 4, 0.6), x + o[1], z + o[2], y, Color3.new(1, 1, 1)) end
		for _, h in {1.5, 3} do
			for _, s in {-4, 4} do
				Blk(g, Vector3.new(8.6, 0.3, 0.3), x, z + s, y + h, C(220, 50, 50)); Blk(g, Vector3.new(0.3, 0.3, 8.6), x + s, z, y + h, C(60, 90, 220))
			end
		end
		Blk(g, Vector3.new(0.4, 6, 0.4), x, z - 2, y + 1, PAL.Ink); Blk(g, Vector3.new(1.6, 3, 1.6), x, z - 2, y + 2.4, C(200, 40, 40))
	elseif theme == "shrine" then
		Blk(g, Vector3.new(7, 4, 5), x, z, y, C(200, 50, 46)); Blk(g, Vector3.new(9, 1, 7), x, z, y + 4, PAL.Ink); Blk(g, Vector3.new(6, 1, 4), x, z, y + 5, PAL.Ink)
	elseif theme == "crystal" then
		Blk(g, Vector3.new(4, 2, 4), x, z, y, PAL.Stone2)
		P({Size = Vector3.new(2.6, 9, 2.6), CFrame = CFrame.new(W(x, z, y + 6.5)) * CFrame.Angles(0, math.rad(45), 0), Color = color, Material = Enum.Material.Neon, Transparency = 0.1, Parent = g})
	elseif theme == "furnace" then
		Blk(g, Vector3.new(5, 6, 5), x, z, y, PAL.Ink); Blk(g, Vector3.new(3, 2, 0.4), x, z - 2.6, y + 1.5, C(255, 90, 30), {Material = Enum.Material.Neon}); Blk(g, Vector3.new(1.4, 4, 1.4), x + 1.2, z + 1.2, y + 6, PAL.Stone2)
	elseif theme == "gate" then
		for _, s in {-3, 3} do Blk(g, Vector3.new(0.9, 7, 0.9), x + s, z, y, C(206, 56, 44)) end
		Blk(g, Vector3.new(9, 0.9, 1.4), x, z, y + 7, PAL.Ink); Blk(g, Vector3.new(7.4, 0.6, 1), x, z, y + 5.6, C(206, 56, 44))
	elseif theme == "dome" then
		local d = P({Shape = Enum.PartType.Ball, Size = Vector3.new(9, 9, 9), CFrame = CFrame.new(W(x, z, y)), Color = color, Material = Enum.Material.Glass, Transparency = 0.45, CanCollide = false, Parent = g})
		d.Name = "Dome"; Blk(g, Vector3.new(1.6, 3, 1.6), x, z, y, C(255, 255, 255), {Material = Enum.Material.Neon})
	elseif theme == "portal" then
		for _, s in {-3, 3} do Blk(g, Vector3.new(1.2, 8, 1.2), x + s, z, y, PAL.Ink) end
		Blk(g, Vector3.new(7.4, 1.2, 1.2), x, z, y + 8, PAL.Ink)
		Blk(g, Vector3.new(4.8, 7, 0.3), x, z, y + 0.6, color, {Material = Enum.Material.Neon, Transparency = 0.3, CanCollide = false})
	elseif theme == "blossom" then
		Blk(g, Vector3.new(1, 5, 1), x, z, y, PAL.Trunk); Blk(g, Vector3.new(7, 3, 7), x, z, y + 4.4, C(255, 186, 214)); Blk(g, Vector3.new(4.4, 2, 4.4), x + 0.8, z, y + 7.2, C(255, 210, 228))
	elseif theme == "orb" or theme == "beam" then
		Blk(g, Vector3.new(3, 3, 3), x, z, y, PAL.Stone2)
		P({Shape = Enum.PartType.Ball, Size = Vector3.new(6, 6, 6), CFrame = CFrame.new(W(x, z, y + 6.5)), Color = color, Material = Enum.Material.Neon, Transparency = 0.15, CanCollide = false, Parent = g})
		if theme == "beam" then beam(g, x, z, y + 9, color) end
	elseif theme == "garden" then
		for i = 0, 5 do local a = i * math.pi / 3; Blk(g, Vector3.new(1.4, 1.4 + i % 2, 1.4), x + math.cos(a) * 3, z + math.sin(a) * 3, y, i % 2 == 0 and C(255, 120, 190) or C(255, 220, 90)) end
		Blk(g, Vector3.new(2, 4, 2), x, z, y, C(120, 200, 80))
	elseif theme == "tower" then
		for k = 0, 3 do Blk(g, Vector3.new(6 - k, 2.4, 6 - k), x, z, y + k * 3, k % 2 == 0 and C(240, 236, 226) or color); Blk(g, Vector3.new(7.4 - k, 0.6, 7.4 - k), x, z, y + k * 3 + 2.4, PAL.Ink) end
	end
end
local function buildStations()
	local g = group("TrainingStations")
	g:SetAttribute("Note", "ZoneMult applied server-side by GameService from SystemsConfig.TrainingStations (Rebirths gate).")
	local cols, rows = {-62, -38, -14, 10, 34}, {-34, -55, -76}
	for i, st in SC.TrainingStations do
		local row = math.ceil(i / #cols)
		local col = (i - 1) % #cols + 1
		local x, z = cols[col], rows[row]
		local m = group("Station" .. i, g)
		m:SetAttribute("StationIndex", i)
		local y = 0.3 + (row - 1) * 0.6
		Blk(m, Vector3.new(15, 1 + (row - 1) * 0.6, 15), x, z, -0.3, PAL.Stone, {Name = "Base"})
		for _, s in {-1, 1} do
			Blk(m, Vector3.new(15.4, 0.5, 0.9), x, z + s * 7.2, y + 0.4, PAL.Gold, {Material = Enum.Material.Neon})
			Blk(m, Vector3.new(0.9, 0.5, 15.4), x + s * 7.2, z, y + 0.4, PAL.Gold, {Material = Enum.Material.Neon})
		end
		for _, o in {{-7, -7}, {-7, 7}, {7, -7}, {7, 7}} do
			Blk(m, Vector3.new(1.1, 3, 1.1), x + o[1], z + o[2], y + 0.4, PAL.Gold)
			Blk(m, Vector3.new(1, 1, 1), x + o[1], z + o[2], y + 3.4, PAL.Cyan, {Material = Enum.Material.Neon})
		end
		centerpiece(m, st.Theme, x, z, y + 0.4, st.Color)
		local zone = P({Name = "Zone", Size = Vector3.new(15, 12, 15), CFrame = CFrame.new(W(x, z, y + 6)), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Parent = m})
		zone:SetAttribute("StationIndex", i)
		if st.Mult >= 50 then beam(m, x + 6, z + 6, y + 3, st.Color) end
		local bb = billboard(anchor(m, x, z, y + 13), Vector2.new(11, 4.2), 0, 120, "Card")
		text(bb, "X" .. Config.Format(st.Mult) .. " HAND SIGNS", UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.5), st.Color, 4, "Mult")
		if st.Rebirths > 0 then
			icon(bb, "Rebirth", UDim2.fromScale(0.3, 0.52), UDim2.fromScale(0.16, 0.44))
			text(bb, Config.Format(st.Rebirths), UDim2.fromScale(0.47, 0.54), UDim2.fromScale(0.3, 0.42), C(255, 90, 90), 3, "Price")
		else
			text(bb, "FREE", UDim2.fromScale(0.3, 0.54), UDim2.fromScale(0.4, 0.42), C(120, 255, 130), 3, "Price")
		end
	end
	-- field sign
	local s = anchor(g, -14, -24, 4, "SignAnchor")
	local bb = billboard(s, Vector2.new(16, 2.4), 0, 80, "Card")
	text(bb, "TRAINING ZONES · stand inside to multiply HAND SIGNS", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), Color3.new(1, 1, 1), 3)
end

---------------------------------------------------------------- hand sign showcase (south, near spawn): 2 rows x 7
local function buildShowcase()
	local g = group("SignShowcase")
	g:SetAttribute("Note", "Pad colours/text are per-player, set by the client Lobby module from server state.")
	local x0, dx = -72, 12.5
	Blk(g, Vector3.new(7 * dx + 6, 1, 13), x0 + 3 * dx, 34, -0.4, PAL.Stone, {Name = "FrontPlatform"})
	Blk(g, Vector3.new(7 * dx + 6, 6.4, 13), x0 + 3 * dx, 47, -0.4, PAL.Stone2, {Name = "BackPlatform"}) -- raised tier like the reference
	Blk(g, Vector3.new(7 * dx + 6, 0.6, 1), x0 + 3 * dx, 27.6, 0.4, PAL.Gold, {Material = Enum.Material.Neon})
	for i, id in Config.HandSignOrder do
		local s = Config.HandSigns[id]
		local back = i > 7
		local k = back and i - 8 or i - 1
		local x, z = x0 + k * dx, back and 47 or 34
		local top = back and 6 or 0.6
		local m = group("Pad_" .. id, g)
		m:SetAttribute("SignId", id)
		local pad = Blk(m, Vector3.new(8, 0.5, 8), x, z, top, C(220, 60, 60), {Name = "Pad", Material = Enum.Material.Neon, Transparency = 0.1})
		prompt(pad, "Buy", s.Name, {LobbyAction = "Sign", SignId = id})
		-- floating emblem orb (original hand-sign emblem on a coloured sphere)
		local orb = P({Name = "Orb", Shape = Enum.PartType.Ball, Size = Vector3.new(4.8, 4.8, 4.8), CFrame = CFrame.new(W(x, z, top + 9)), Color = s.Color,
			Material = Enum.Material.SmoothPlastic, CanCollide = false, Parent = m})
		local eb = billboard(orb, Vector2.new(4.2, 4.2), 0, 120, "Emblem")
		eb.StudsOffset = Vector3.new(0, 0, 3) -- camera-space: draw the emblem in front of its orb
		text(eb, s.Emblem, UDim2.fromScale(0.08, 0.08), UDim2.fromScale(0.84, 0.84), Color3.new(1, 1, 1), 0)
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
	Blk(g, Vector3.new(170, 0.4, 16), 2, 72, 0, PAL.Path, merge(STUDS, {Name = "EggWalk"}))
	for _, z in {63.5, 80.5} do Blk(g, Vector3.new(170, 0.45, 1.2), 2, z, 0, PAL.LimeEdge) end
	local n = #SC.EggOrder
	for i, eggId in SC.EggOrder do
		local egg = SC.Eggs[eggId]
		local x, z = -36 + (i - 1) * (114 / (n - 1)), 74
		local m = group("Egg_" .. eggId, g)
		Disc(m, 9, 1, x, z, 1.4, PAL.Stone)
		Disc(m, 7.6, 0.5, x, z, 1.7, egg.Color:Lerp(C(255, 40, 60), 0.5), {Material = Enum.Material.Neon, Transparency = 0.15})
		local ped = Disc(m, 6, 1.6, x, z, 3.2, PAL.Stone2, {Name = "Pedestal"})
		prompt(ped, "Hatch", egg.Name .. " · " .. Config.Format(egg.Cost) .. " Trophies", {LobbyAction = "Hatch", EggId = eggId})
		local e = P({Name = "Egg", Shape = Enum.PartType.Ball, Size = Vector3.new(5, 5, 5), CFrame = CFrame.new(W(x, z, 6.4)), Color = egg.Color, Parent = m})
		local mesh = Instance.new("SpecialMesh"); mesh.MeshType = Enum.MeshType.Sphere; mesh.Scale = Vector3.new(1, 1.28, 1); mesh.Parent = e
		if i >= n - 1 then beam(m, x, z + 3, 3, egg.Color) end
		local bb = billboard(e, Vector2.new(7, 3.2), 5.4, 70, "Card")
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
		local bb = billboard(anchor(m, x, 74, 13), Vector2.new(10, 3.2), 0, 90, "Card")
		text(bb, title, UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.58), C(255, 150, 230), 4)
		text(bb, "COMING SOON", UDim2.fromScale(0.15, 0.6), UDim2.fromScale(0.7, 0.38), C(255, 120, 120), 3)
	end
	placeholder("BossShop", -76, "BOSS SHOP", function(m)
		Blk(m, Vector3.new(12, 1, 8), -76, 74, 0.3, PAL.Stone)
		Blk(m, Vector3.new(10, 4, 4), -76, 72, 1.3, C(200, 50, 46))
		for _, s in {-5, 5} do Blk(m, Vector3.new(0.9, 9, 0.9), -76 + s, 76, 1.3, PAL.Ink) end
		Blk(m, Vector3.new(13, 1.2, 7), -76, 74, 10.3, C(200, 50, 46)); Blk(m, Vector3.new(11, 1, 5), -76, 74, 11.5, PAL.Ink)
		Blk(m, Vector3.new(8, 1.8, 0.3), -76, 70.6, 7.5, C(255, 214, 90), {Material = Enum.Material.Neon})
	end)
	placeholder("FuseMachine", -56, "FUSE MACHINE", function(m)
		Blk(m, Vector3.new(10, 1.4, 10), -56, 74, 0.3, PAL.Stone)
		for _, o in {{-4, -4}, {-4, 4}, {4, -4}, {4, 4}} do Blk(m, Vector3.new(1.4, 3, 1.4), -56 + o[1], 74 + o[2], 1.7, C(240, 240, 250)) end
		Blk(m, Vector3.new(5, 6, 5), -56, 74, 1.7, C(110, 60, 200), {Material = Enum.Material.Glass, Transparency = 0.35})
		P({Shape = Enum.PartType.Ball, Size = Vector3.new(3, 3, 3), CFrame = CFrame.new(W(-56, 74, 4.7)), Color = C(220, 120, 255), Material = Enum.Material.Neon, CanCollide = false, Parent = m})
		Blk(m, Vector3.new(6, 1, 6), -56, 74, 7.7, C(240, 240, 250))
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
		sp.CFrame = CFrame.lookAt(W(-84, 0, 0.6), W(0, 0, 0.6))
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
