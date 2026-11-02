--!strict
-- LobbyBuilder (edit-time tool, issue #14) — builds Workspace.Lobby, the "Shinobi Plaza" hub.
--
--   require(game.ServerStorage.Tools.LobbyBuilder).Build()   -- (re)builds Workspace.Lobby only
--   require(game.ServerStorage.Tools.LobbyBuilder).Revert()  -- removes the lobby, restores Stage01 wall + SpawnLocation
--
-- Safety: only ever destroys/replaces Workspace.Lobby. The 50-stage StageCourse is never regenerated;
-- the single Stage01 start wall is MOVED (not deleted) to ServerStorage.Backups so the bridge can connect.
-- Everything interactive here is a ProximityPrompt routed by the client Lobby module into EXISTING
-- server-validated remotes (Action/EquipSign/Train). Nothing in the world grants anything by itself.

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local SC = require(game:GetService("ReplicatedStorage").Shared.SystemsConfig)
local ServerStorage = game:GetService("ServerStorage")

local B = {}

local CENTER = Vector3.new(-250, 0, 0)
local ISLAND_R = 120
local C = Color3.fromRGB
local PAL = {
	Grass = C(104, 196, 84), GrassDark = C(74, 160, 64), Dirt = C(132, 94, 62), Rock = C(112, 114, 124), RockDark = C(84, 86, 98),
	Stone = C(216, 210, 198), StoneDark = C(156, 150, 142), Tile = C(238, 232, 220), Accent = C(236, 128, 56),
	Vermilion = C(204, 62, 46), Wood = C(160, 108, 64), WoodDark = C(92, 60, 40), Roof = C(52, 84, 112), RoofEdge = C(36, 54, 72),
	Plaster = C(242, 234, 214), Water = C(96, 186, 255), Gold = C(255, 204, 64), Ink = C(40, 34, 44),
	Blossom = C(255, 184, 214), Blossom2 = C(255, 156, 196), Pine = C(58, 150, 76), Pine2 = C(80, 176, 90),
}
local FONT = Enum.Font.FredokaOne

local root: Model
local function W(x: number, z: number, y: number?): Vector3
	return CENTER + Vector3.new(x, y or 0, z)
end
local function polar(r: number, deg: number): (number, number)
	local a = math.rad(deg)
	return r * math.cos(a), r * math.sin(a)
end
local function group(name: string, parent: Instance?): Model
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent or root
	return m
end

local function P(props: {[string]: any}): BasePart
	local p = Instance.new(props.Class or "Part") :: any
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	if props.Shape then p.Shape = props.Shape end
	for k, v in props do
		if k ~= "Class" and k ~= "Parent" and k ~= "Shape" then p[k] = v end
	end
	p.Parent = props.Parent or root
	return p
end
-- block: centered at pos (y is the BOTTOM of the block), optional yaw/look target
local function Block(parent: Instance, size: Vector3, x: number, z: number, bottom: number, color: Color3, extra: {[string]: any}?): BasePart
	local t: {[string]: any} = {Size = size, CFrame = CFrame.new(W(x, z, bottom + size.Y / 2)), Color = color, Parent = parent}
	if extra then for k, v in extra do t[k] = v end end
	return P(t)
end
-- vertical-axis disc: diameter d, height h, top surface at y=top
local function Disc(parent: Instance, d: number, h: number, x: number, z: number, top: number, color: Color3, extra: {[string]: any}?): BasePart
	local t: {[string]: any} = {Shape = Enum.PartType.Cylinder, Size = Vector3.new(h, d, d),
		CFrame = CFrame.new(W(x, z, top - h / 2)) * CFrame.Angles(0, 0, math.rad(90)), Color = color, Parent = parent}
	if extra then for k, v in extra do t[k] = v end end
	return P(t)
end
local function facing(pos: Vector3, target: Vector3): CFrame
	return CFrame.lookAt(pos, Vector3.new(target.X, pos.Y, target.Z))
end

local function label(parent: Instance, text: string, pos: UDim2, size: UDim2, color: Color3?, stroke: number?): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = FONT
	l.TextScaled = true
	l.Text = text
	l.TextColor3 = color or Color3.new(1, 1, 1)
	l.TextStrokeTransparency = 1
	l.Position = pos
	l.Size = size
	local s = Instance.new("UIStroke")
	s.Thickness = stroke or 3
	s.Color = C(20, 16, 26)
	s.Parent = l
	l.Parent = parent
	return l
end
local function surface(part: BasePart, face: Enum.NormalId, ppu: number?): SurfaceGui
	local g = Instance.new("SurfaceGui")
	g.Face = face
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = ppu or 40
	g.LightInfluence = 0
	g.Parent = part
	return g
end
-- signboard facing `target`: wood frame + ink panel with title/sub on the front
local function Signboard(parent: Instance, x: number, z: number, bottom: number, w: number, h: number, target: Vector3, title: string, sub: string?, titleColor: Color3?): BasePart
	local pos = W(x, z, bottom + h / 2)
	local cf = facing(pos, target)
	P({Size = Vector3.new(w + 1, h + 1, 0.8), CFrame = cf * CFrame.new(0, 0, 0.3), Color = PAL.WoodDark, Parent = parent})
	local panel = P({Size = Vector3.new(w, h, 0.6), CFrame = cf, Color = PAL.Ink, Parent = parent, Name = "Panel"})
	local g = surface(panel, Enum.NormalId.Front)
	label(g, title, UDim2.fromScale(0.04, sub and 0.06 or 0.12), UDim2.fromScale(0.92, sub and 0.56 or 0.76), titleColor or PAL.Gold, 4)
	if sub then label(g, sub, UDim2.fromScale(0.06, 0.64), UDim2.fromScale(0.88, 0.3), Color3.new(1, 1, 1), 2) end
	for _, side in {-1, 1} do
		P({Size = Vector3.new(0.9, bottom + 0.4, 0.9), CFrame = cf * CFrame.new(side * (w / 2 - 0.6), -(h / 2) - bottom / 2 - 0.2, 0.3), Color = PAL.WoodDark, Parent = parent})
	end
	return panel
end
local function billboard(adornee: BasePart, studs: Vector2, offsetY: number, maxDist: number): BillboardGui
	local b = Instance.new("BillboardGui")
	b.Size = UDim2.fromScale(studs.X, studs.Y)
	b.StudsOffsetWorldSpace = Vector3.new(0, offsetY, 0)
	b.MaxDistance = maxDist
	b.LightInfluence = 0
	b.Adornee = adornee
	b.Parent = adornee
	return b
end
local function prompt(part: BasePart, action: string, object: string, attrs: {[string]: any}): ProximityPrompt
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = action
	pp.ObjectText = object
	pp.HoldDuration = 0
	pp.MaxActivationDistance = 11
	pp.RequiresLineOfSight = false
	pp.KeyboardKeyCode = Enum.KeyCode.F -- E/R are jutsu keys
	pp.GamepadKeyCode = Enum.KeyCode.ButtonX
	for k, v in attrs do pp:SetAttribute(k, v) end
	pp.Parent = part
	return pp
end
local function light(part: BasePart, color: Color3, range: number, brightness: number)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = brightness
	l.Shadows = false
	l.Parent = part
end
local function kit(name: string, parent: Instance, x: number, z: number, ground: number, yaw: number?)
	local src = ServerStorage:FindFirstChild("Tools") and ServerStorage.Tools:FindFirstChild("Kit") and ServerStorage.Tools.Kit:FindFirstChild(name)
	if not src then return end
	local m = (src :: Model):Clone()
	m:PivotTo(CFrame.new(W(x, z, 0)) * CFrame.Angles(0, math.rad(yaw or 0), 0))
	local bb, sz = m:GetBoundingBox()
	m:PivotTo(m:GetPivot() + Vector3.new(0, ground - (bb.Position.Y - sz.Y / 2), 0))
	m.Parent = parent
end

---------------------------------------------------------------- pieces
local function buildIsland()
	local g = group("Island")
	Disc(g, ISLAND_R * 2, 8, 0, 0, 0, PAL.Grass, {Material = Enum.Material.Plastic, TopSurface = Enum.SurfaceType.Studs, Name = "Ground"})
	Disc(g, ISLAND_R * 2 + 4, 3, 0, 0, -0.6, PAL.GrassDark)
	Disc(g, ISLAND_R * 2 - 4, 12, 0, 0, -8, PAL.Dirt)
	Disc(g, ISLAND_R * 2 - 44, 16, 0, 0, -20, PAL.Rock)
	Disc(g, ISLAND_R * 2 - 104, 18, 0, 0, -36, PAL.RockDark)
	Disc(g, 56, 16, 0, 0, -54, PAL.RockDark)
	local rng = Random.new(14)
	for i = 1, 14 do
		local x, z = polar(ISLAND_R - 18 - rng:NextNumber() * 30, i * (360 / 14) + rng:NextNumber() * 10)
		local s = 10 + rng:NextNumber() * 12
		P({Size = Vector3.new(s, s * 1.4, s), CFrame = CFrame.new(W(x, z, -14 - s * 0.6)) * CFrame.Angles(rng:NextNumber() * 0.4, rng:NextNumber() * 3, rng:NextNumber() * 0.4),
			Color = i % 2 == 0 and PAL.Rock or PAL.RockDark, Parent = g})
	end
	-- rim boulders frame the island edge (gap at the east path)
	for deg = 10, 350, 18 do
		if deg > 14 and deg < 346 and not (deg > 162 and deg < 198) then
			local x, z = polar(ISLAND_R - 3, deg)
			local s = 4 + rng:NextNumber() * 3
			P({Size = Vector3.new(s * 1.3, s * 0.8, s), CFrame = CFrame.new(W(x, z, s * 0.3)) * CFrame.Angles(0, rng:NextNumber() * 3, 0.15), Color = PAL.Rock, Parent = g})
		end
	end
end

local function buildPlaza()
	local g = group("Plaza")
	-- promenade ring (r 66..88) that links showcase, hatchery, shrines and portal
	Disc(g, 176, 0.6, 0, 0, 0.25, PAL.StoneDark, {Name = "PromenadeEdge"})
	Disc(g, 172, 0.62, 0, 0, 0.27, PAL.Stone, {Material = Enum.Material.Plastic, TopSurface = Enum.SurfaceType.Studs, Name = "Promenade"})
	Disc(g, 132, 0.64, 0, 0, 0.29, PAL.Grass, {Material = Enum.Material.Plastic, TopSurface = Enum.SurfaceType.Studs, Name = "InnerLawn"})
	-- central plaza
	Disc(g, 100, 0.66, 0, 0, 0.42, PAL.StoneDark)
	Disc(g, 96, 0.68, 0, 0, 0.45, PAL.Stone, {Material = Enum.Material.Plastic, TopSurface = Enum.SurfaceType.Studs, Name = "PlazaFloor"})
	Disc(g, 60, 0.7, 0, 0, 0.48, PAL.Accent, {Name = "PlazaRing"})
	Disc(g, 55, 0.72, 0, 0, 0.5, PAL.Tile, {Name = "PlazaInner"})
	-- radial walkways from the plaza out to the promenade (N, S, W) + the main east road
	for _, deg in {90, 270} do
		local x, z = polar(58, deg)
		Block(g, Vector3.new(14, 0.6, 18), x, z, -0.25, PAL.Stone, {Material = Enum.Material.Plastic, TopSurface = Enum.SurfaceType.Studs})
	end
	local road = Block(g, Vector3.new(74, 0.62, 22), 84, 0, -0.27, PAL.Stone, {Material = Enum.Material.Plastic, TopSurface = Enum.SurfaceType.Studs, Name = "EastRoad"})
	road.Size = road.Size
	for _, side in {-1, 1} do
		Block(g, Vector3.new(70, 1, 1.4), 86, side * 11.7, -0.2, PAL.StoneDark)
	end
end

local function buildFountain()
	local g = group("ChakraFountain")
	Disc(g, 30, 1.5, 0, 0, 1.0, PAL.StoneDark)
	Disc(g, 26, 3, 0, 0, 3.0, PAL.Stone)
	Disc(g, 23, 0.4, 0, 0, 3.1, PAL.Water, {Material = Enum.Material.Glass, Transparency = 0.25, Name = "Water"})
	Disc(g, 8, 4, 0, 0, 7, PAL.StoneDark)
	Disc(g, 5, 6, 0, 0, 13, PAL.Stone)
	Disc(g, 7.5, 1, 0, 0, 14, PAL.Gold)
	local orb = P({Shape = Enum.PartType.Ball, Size = Vector3.new(6, 6, 6), CFrame = CFrame.new(W(0, 0, 18.5)), Color = PAL.Accent,
		Material = Enum.Material.Neon, Name = "ChakraOrb", Parent = g, CanCollide = false})
	light(orb, C(255, 160, 80), 26, 1.4)
	local halo = group("Halo", g)
	for i = 1, 8 do
		local x, z = polar(6.5, i * 45)
		P({Shape = Enum.PartType.Ball, Size = Vector3.new(1.3, 1.3, 1.3), CFrame = CFrame.new(W(x, z, 18.5)), Color = C(255, 226, 150),
			Material = Enum.Material.Neon, CanCollide = false, CastShadow = false, Parent = halo})
	end
	halo.WorldPivot = CFrame.new(W(0, 0, 18.5))
	-- welcome sign on the fountain's east face (seen right from spawn)
	Signboard(g, 15.5, 0, 0.5, 12, 3.4, W(40, 0), "SHINOBI PLAZA", "Train · Unlock Signs · Enter Stage 1 ▶")
end

local function buildSpawn()
	local pos = W(28, 0, 1.0)
	local sp = P({Name = "LobbySpawn", Size = Vector3.new(10, 1, 10), CFrame = CFrame.lookAt(pos, pos + Vector3.xAxis),
		Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false})
	Disc(root, 11, 0.74, 28, 0, 0.52, PAL.Gold, {Name = "SpawnRune"})
	Disc(root, 8, 0.76, 28, 0, 0.54, PAL.Tile)
	return sp
end

local function buildGateAndBridge()
	local g = group("Stage1Gate")
	local gx = 112
	-- torii
	for _, side in {-1, 1} do
		Block(g, Vector3.new(5, 2, 5), gx, side * 13, 0, PAL.Ink)
		Block(g, Vector3.new(3, 24, 3), gx, side * 13, 2, PAL.Vermilion, {Name = "Pillar"})
	end
	Block(g, Vector3.new(3, 2, 36), gx, 0, 14.6, PAL.Vermilion) -- nuki sits below the destination board
	Block(g, Vector3.new(4, 2, 38), gx, 0, 22.5, PAL.Vermilion)
	Block(g, Vector3.new(5, 2.5, 30), gx, 0, 24.5, PAL.Ink)
	for _, side in {-1, 1} do
		P({Size = Vector3.new(5, 2.5, 9), CFrame = CFrame.new(W(gx, side * 18.5, 26.4)) * CFrame.Angles(math.rad(side * 9), 0, 0), Color = PAL.Ink, Parent = g})
	end
	-- destination board between the beams: front faces the lobby (west), back faces Stage 1
	local pos = W(gx, 0, 20.2)
	local board = P({Name = "DestinationBoard", Size = Vector3.new(1.2, 4.6, 22), CFrame = CFrame.lookAt(pos, pos - Vector3.xAxis) * CFrame.Angles(0, 0, 0), Color = PAL.Ink, Parent = g})
	board.Size = Vector3.new(22, 4.6, 1.2) -- lookAt points -Z at west: width runs along world Z
	local front = surface(board, Enum.NormalId.Front, 30)
	label(front, "STAGE 1 ▶  LEAF GROVE", UDim2.fromScale(0.03, 0.08), UDim2.fromScale(0.94, 0.58), PAL.Gold, 4)
	label(front, "Defeat 5 enemies to open Stage 2", UDim2.fromScale(0.1, 0.66), UDim2.fromScale(0.8, 0.28), Color3.new(1, 1, 1), 2)
	local back = surface(board, Enum.NormalId.Back, 30)
	label(back, "◀ SHINOBI PLAZA", UDim2.fromScale(0.05, 0.12), UDim2.fromScale(0.9, 0.56), PAL.Gold, 4)
	label(back, "Lobby · Eggs · Hand Sign Showcase", UDim2.fromScale(0.1, 0.68), UDim2.fromScale(0.8, 0.26), Color3.new(1, 1, 1), 2)
	kit("PostLantern", g, gx - 4, -16, 0.3, 0)
	kit("PostLantern", g, gx - 4, 16, 0.3, 180)

	-- bridge: island edge -> Stage 1 floor (world x -130 .. -85)
	local bridge = group("Bridge")
	local x0, x1 = ISLAND_R - 2, 166
	local len = x1 - x0
	local mid = (x0 + x1) / 2
	Block(bridge, Vector3.new(len, 1.6, 22), mid, 0, -1.3, PAL.Wood, {Material = Enum.Material.WoodPlanks, Name = "Deck"})
	for i = 0, math.floor(len / 6) do
		Block(bridge, Vector3.new(0.6, 0.2, 22), x0 + 2 + i * 6, 0, 0.3, PAL.WoodDark)
	end
	for _, side in {-1, 1} do
		Block(bridge, Vector3.new(len, 3, 2), mid, side * 8, -4.3, PAL.WoodDark)
		for i = 0, math.floor(len / 7.5) do
			Block(bridge, Vector3.new(1.2, 4, 1.2), x0 + 1 + i * 7.5, side * 11.4, 0.3, PAL.WoodDark)
		end
		Block(bridge, Vector3.new(len, 0.8, 0.8), mid, side * 11.4, 3.3, PAL.Vermilion)
		Block(bridge, Vector3.new(len, 0.5, 0.5), mid, side * 11.4, 1.6, PAL.Vermilion)
	end
	for _, bx in {x0 + 12, x1 - 12} do
		for _, side in {-1, 1} do
			Block(bridge, Vector3.new(3, 26, 3), bx, side * 8, -30, PAL.RockDark)
		end
	end
end

local function buildAcademy()
	local g = group("ShinobiAcademy")
	local ax = -94
	Block(g, Vector3.new(42, 3, 50), ax, 0, 0, PAL.StoneDark, {Name = "Foundation"})
	for i = 1, 3 do -- front steps
		Block(g, Vector3.new(2, i, 18), ax + 21 + (4 - i) * 2 - 1, 0, 0, PAL.Stone)
	end
	Block(g, Vector3.new(34, 16, 42), ax - 1, 0, 3, PAL.Plaster, {Name = "Hall"})
	for _, z in {-21, -7, 7, 21} do
		Block(g, Vector3.new(2, 16, 2), ax + 16, z, 3, PAL.WoodDark)
	end
	Block(g, Vector3.new(36, 2, 44), ax - 1, 0, 19, PAL.WoodDark)
	Block(g, Vector3.new(1, 10, 10), ax + 16.2, 0, 3, PAL.Ink, {Name = "Door"})
	-- tiered pagoda roof
	local y = 21
	for _, s in {{48, 56}, {42, 50}, {34, 42}} do
		Block(g, Vector3.new(s[1], 2, s[2]), ax - 1, 0, y, PAL.Roof)
		y += 2
	end
	Block(g, Vector3.new(22, 9, 28), ax - 1, 0, y, PAL.Plaster)
	Block(g, Vector3.new(24, 1.5, 30), ax - 1, 0, y + 9, PAL.WoodDark)
	y += 10.5
	for _, s in {{32, 38}, {26, 32}, {18, 24}, {10, 16}} do
		Block(g, Vector3.new(s[1], 2, s[2]), ax - 1, 0, y, PAL.Roof)
		y += 2
	end
	Block(g, Vector3.new(4, 1.5, 20), ax - 1, 0, y, PAL.RoofEdge)
	local orbBase = Block(g, Vector3.new(2, 4, 2), ax - 1, 0, y + 1.5, PAL.Gold)
	orbBase.Name = "Finial"
	-- title board on the facade, facing the plaza
	local pos = W(ax + 17, 0, 31.5)
	local board = P({Name = "TitleBoard", Size = Vector3.new(30, 8, 1), CFrame = CFrame.lookAt(pos, pos + Vector3.xAxis), Color = PAL.Ink, Parent = g})
	P({Size = Vector3.new(32, 10, 0.8), CFrame = board.CFrame * CFrame.new(0, 0, 0.5), Color = PAL.Gold, Parent = g})
	local sg = surface(board, Enum.NormalId.Front, 30)
	label(sg, "+1 ANIME HAND SIGNS", UDim2.fromScale(0.03, 0.06), UDim2.fromScale(0.94, 0.6), PAL.Gold, 5)
	label(sg, "SHINOBI ACADEMY", UDim2.fromScale(0.2, 0.68), UDim2.fromScale(0.6, 0.26), Color3.new(1, 1, 1), 3)
	for _, z in {-14, 14} do
		local banner = Block(g, Vector3.new(0.4, 12, 5), ax + 16.6, z, 5, PAL.Vermilion)
		banner.Name = "Banner"
		local bg = surface(banner, Enum.NormalId.Right, 20)
		label(bg, "忍", UDim2.fromScale(0.1, 0.3), UDim2.fromScale(0.8, 0.3), Color3.new(1, 1, 1), 2)
	end
end

local function buildTraining()
	local g = group("TrainingGrounds")
	local mx = -36
	Block(g, Vector3.new(24, 0.8, 18), mx, 0, 0.2, PAL.WoodDark)
	local mat = Block(g, Vector3.new(22, 0.82, 16), mx, 0, 0.22, PAL.Wood, {Material = Enum.Material.WoodPlanks, Name = "Mat"})
	prompt(mat, "Train", "Training Grounds", {LobbyAction = "Train"})
	for _, d in {{-6, -5}, {-6, 5}, {-2, 0}} do
		local x, z = mx + d[1], d[2]
		Block(g, Vector3.new(1.4, 6, 1.4), x, z, 1, PAL.Wood)
		Block(g, Vector3.new(1, 1, 6), x, z, 4.5, PAL.Wood)
		Block(g, Vector3.new(2.6, 2.6, 2.6), x, z, 7, C(226, 196, 126))
		local pos = W(x + 0.9, z, 5.4)
		P({Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 3, 3), CFrame = CFrame.new(pos), Color = C(220, 70, 60), Parent = g})
		P({Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.42, 1.4, 1.4), CFrame = CFrame.new(pos), Color = Color3.new(1, 1, 1), Parent = g})
	end
	Signboard(g, mx + 9, -11, 0.4, 13, 4, W(20, 0), "TRAINING GROUNDS", "Press [F] here or tap TRAIN to gain Hand Signs")
end

local SIGN_ARC = {from = 215, to = 325, r = 77}
local function buildShowcase()
	local g = group("SignShowcase")
	g:SetAttribute("Note", "Pad colors/text are per-player, set by the client Lobby module from server state.")
	local n = #Config.HandSignOrder
	for i, id in Config.HandSignOrder do
		local s = Config.HandSigns[id]
		local deg = SIGN_ARC.from + (SIGN_ARC.to - SIGN_ARC.from) * (i - 1) / (n - 1)
		local x, z = polar(SIGN_ARC.r, deg)
		local m = group("Pad_" .. id, g)
		m:SetAttribute("SignId", id)
		Disc(m, 9.5, 1.2, x, z, 0.85, PAL.StoneDark)
		local pad = Disc(m, 7.6, 1.3, x, z, 0.98, C(120, 120, 130), {Name = "Pad"})
		prompt(pad, "Buy", s.Name, {LobbyAction = "Sign", SignId = id})
		local bx, bz = polar(SIGN_ARC.r + 5.2, deg)
		Block(m, Vector3.new(1.6, 9, 1.6), bx, bz, 0.3, PAL.WoodDark)
		Block(m, Vector3.new(3.4, 0.8, 3.4), bx, bz, 9.3, PAL.Roof)
		local lamp = Block(m, Vector3.new(1.4, 1.6, 1.4), bx, bz, 7.4, s.Color, {Name = "Lamp", Material = Enum.Material.Neon})
		lamp.Transparency = 0.15
		local anchor = P({Name = "Anchor", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(W(x, z, 7.2)), Transparency = 1,
			CanCollide = false, CanQuery = false, CanTouch = false, Parent = m})
		local bb = billboard(anchor, Vector2.new(6.6, 6.2), 0, 70)
		bb.Name = "Card"
		label(bb, s.Emblem, UDim2.fromScale(0.25, 0), UDim2.fromScale(0.5, 0.34), nil, 0).Name = "Emblem"
		label(bb, string.upper(s.Name), UDim2.fromScale(0, 0.34), UDim2.fromScale(1, 0.17), Color3.new(1, 1, 1), 3).Name = "SignName"
		label(bb, "x" .. Config.Format(s.Multiplier) .. " TRAINING", UDim2.fromScale(0.1, 0.51), UDim2.fromScale(0.8, 0.11), PAL.Gold, 2).Name = "Mult"
		label(bb, "", UDim2.fromScale(0, 0.63), UDim2.fromScale(1, 0.12), Color3.new(1, 1, 1), 2).Name = "Req"
		label(bb, "", UDim2.fromScale(0.05, 0.76), UDim2.fromScale(0.9, 0.16), Color3.new(1, 1, 1), 3).Name = "Status"
	end
	local hx, hz = polar(92, 270)
	Signboard(g, hx, hz, 7, 30, 6, CENTER, "HAND SIGN SHOWCASE", "Stage + Hand Signs + Trophies unlocks a sign · Step on a pad")
end

local function buildHatchery()
	local g = group("EggHatchery")
	local n = #SC.EggOrder
	for i, eggId in SC.EggOrder do
		local egg = SC.Eggs[eggId]
		local deg = 45 + 80 * (i - 1) / (n - 1)
		local x, z = polar(77, deg)
		local m = group("Egg_" .. eggId, g)
		Disc(m, 8.5, 1, x, z, 0.8, PAL.StoneDark)
		local col = Disc(m, 6.4, 2.2, x, z, 3, PAL.Stone, {Name = "Pedestal"})
		prompt(col, "Hatch", egg.Name .. " · " .. Config.Format(egg.Cost) .. " Trophies", {LobbyAction = "Hatch", EggId = eggId})
		local e = P({Shape = Enum.PartType.Ball, Size = Vector3.new(5, 5, 5), CFrame = CFrame.new(W(x, z, 6.4)), Color = egg.Color, Name = "Egg", Parent = m})
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Scale = Vector3.new(1, 1.28, 1)
		mesh.Parent = e
		local bb = billboard(e, Vector2.new(6, 2.4), 5.2, 55)
		label(bb, string.upper(egg.Name), UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.5), Color3.new(1, 1, 1), 3)
		label(bb, "🏆 " .. Config.Format(egg.Cost) .. "  ·  STAGE " .. egg.Stage, UDim2.fromScale(0.05, 0.52), UDim2.fromScale(0.9, 0.42), PAL.Gold, 2)
	end
	local hx, hz = polar(92, 85)
	Signboard(g, hx, hz, 7, 24, 6, CENTER, "EGG HATCHERY", "Spend Trophies · Pets multiply your Hand Signs")
end

local function shrine(name: string, deg: number, color: Color3, title: string, sub: string, menu: string?)
	local g = group(name)
	local x, z = polar(80, deg)
	Block(g, Vector3.new(12, 1, 12), x, z, 0.2, PAL.StoneDark)
	local base = Block(g, Vector3.new(10, 1, 10), x, z, 1.2, PAL.Stone, {Name = "Base"})
	for _, o in {{-4, -4}, {-4, 4}, {4, -4}, {4, 4}} do
		Block(g, Vector3.new(1, 7, 1), x + o[1], z + o[2], 2.2, PAL.Vermilion)
	end
	Block(g, Vector3.new(14, 1.4, 14), x, z, 9.2, PAL.Roof)
	Block(g, Vector3.new(9, 1.4, 9), x, z, 10.6, PAL.RoofEdge)
	local core = P({Size = Vector3.new(2.6, 2.6, 2.6), CFrame = CFrame.new(W(x, z, 5)) * CFrame.Angles(math.rad(45), 0, math.rad(45)),
		Color = color, Material = Enum.Material.Neon, Name = "Core", CanCollide = false, Parent = g})
	light(core, color, 14, 1)
	local bb = billboard(base, Vector2.new(9, 3), 12.5, 80)
	label(bb, title, UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.6), color, 4)
	label(bb, sub, UDim2.fromScale(0.05, 0.6), UDim2.fromScale(0.9, 0.36), Color3.new(1, 1, 1), 2)
	if menu then prompt(base, "Open", title, {LobbyAction = "Menu", Menu = menu}) end
	return g
end

local function buildPortal()
	local g = group("WorldsPortal")
	local x, z = polar(80, 340)
	local pos = W(x, z, 9)
	local cf = facing(pos, CENTER)
	Block(g, Vector3.new(16, 1.2, 8), x, z, 0.2, PAL.StoneDark)
	for i = 0, 15 do
		local a = i * (math.pi * 2 / 16)
		P({Size = Vector3.new(2.4, 2.4, 3), CFrame = cf * CFrame.new(math.cos(a) * 7.2, math.sin(a) * 7.2, 0) * CFrame.Angles(0, 0, a), Color = i % 2 == 0 and PAL.Stone or PAL.StoneDark, Parent = g})
	end
	local disc = P({Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 12.4, 12.4), CFrame = cf * CFrame.Angles(0, math.rad(90), 0),
		Color = C(130, 110, 255), Material = Enum.Material.Neon, Transparency = 0.35, CanCollide = false, Name = "Swirl", Parent = g})
	light(disc, C(150, 130, 255), 18, 1.2)
	local stand = Block(g, Vector3.new(6, 1, 4), x, z, 1.4, PAL.Stone, {Name = "Step"})
	prompt(stand, "Travel", "Worlds Portal", {LobbyAction = "Menu", Menu = "Stages"})
	local bb = billboard(stand, Vector2.new(10, 3), 18.5, 90)
	label(bb, "WORLDS", UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.6), C(190, 170, 255), 4)
	label(bb, "Teleport to any unlocked stage", UDim2.fromScale(0.05, 0.6), UDim2.fromScale(0.9, 0.36), Color3.new(1, 1, 1), 2)
end

local function comingSoon(name: string, deg: number, title: string, build: (Model, number, number) -> ())
	local g = group(name)
	g:SetAttribute("Placeholder", "Visual only — backend not built; no prompt or remote is exposed.")
	local x, z = polar(80, deg)
	build(g, x, z)
	local anchor = P({Name = "Anchor", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(W(x, z, 10)), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Parent = g})
	local bb = billboard(anchor, Vector2.new(9, 3), 2, 80)
	label(bb, title, UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.58), Color3.new(1, 1, 1), 4)
	label(bb, "COMING SOON", UDim2.fromScale(0.15, 0.6), UDim2.fromScale(0.7, 0.36), C(255, 120, 120), 3)
end

local function buildBoards()
	local g = group("Leaderboards")
	for i, key in {"Trophies", "Stage"} do
		local z = i == 1 and -30 or 30
		local pos = W(-54, z, 8.5)
		local cf = facing(pos, CENTER)
		local m = group("Board_" .. key, g)
		m:SetAttribute("BoardKey", key)
		P({Size = Vector3.new(15, 15, 0.8), CFrame = cf * CFrame.new(0, 0, 0.4), Color = PAL.WoodDark, Parent = m})
		local panel = P({Name = "Panel", Size = Vector3.new(14, 14, 0.6), CFrame = cf, Color = PAL.Ink, Parent = m})
		for _, side in {-1, 1} do
			P({Size = Vector3.new(1, 9, 1), CFrame = cf * CFrame.new(side * 6, -11, 0.4), Color = PAL.WoodDark, Parent = m})
		end
		P({Size = Vector3.new(16, 1.2, 2.4), CFrame = cf * CFrame.new(0, 7.6, 0.2), Color = PAL.Roof, Parent = m})
		local sg = surface(panel, Enum.NormalId.Front, 30)
		sg.Name = "BoardGui"
		label(sg, key == "Trophies" and "🏆 TOP TROPHIES" or "🗺 HIGHEST STAGE", UDim2.fromScale(0.04, 0.02), UDim2.fromScale(0.92, 0.12), PAL.Gold, 3)
		for r = 1, 8 do
			label(sg, r == 1 and "Updates on live servers" or "", UDim2.fromScale(0.06, 0.16 + (r - 1) * 0.1), UDim2.fromScale(0.88, 0.085), Color3.new(1, 1, 1), 2).Name = "Row" .. r
		end
	end
end

local function cherry(parent: Instance, x: number, z: number, s: number)
	Block(parent, Vector3.new(1.6 * s, 9 * s, 1.6 * s), x, z, 0, PAL.WoodDark)
	Block(parent, Vector3.new(12 * s, 4 * s, 12 * s), x, z, 8 * s, PAL.Blossom)
	Block(parent, Vector3.new(9 * s, 3.5 * s, 9 * s), x + 2 * s, z - 1 * s, 11.5 * s, PAL.Blossom2)
	Block(parent, Vector3.new(6 * s, 2.5 * s, 6 * s), x - 1.5 * s, z + 1.5 * s, 14.5 * s, PAL.Blossom)
end
local function pine(parent: Instance, x: number, z: number, s: number)
	Block(parent, Vector3.new(1.6 * s, 6 * s, 1.6 * s), x, z, 0, PAL.WoodDark)
	Block(parent, Vector3.new(10 * s, 4 * s, 10 * s), x, z, 4 * s, PAL.Pine)
	Block(parent, Vector3.new(7.5 * s, 3.5 * s, 7.5 * s), x, z, 7.5 * s, PAL.Pine2)
	Block(parent, Vector3.new(5 * s, 3 * s, 5 * s), x, z, 10.5 * s, PAL.Pine)
	Block(parent, Vector3.new(2.4 * s, 2 * s, 2.4 * s), x, z, 13.2 * s, PAL.Pine2)
end
local function buildDecor()
	local g = group("Decor")
	-- inner lawn ring (between plaza r50 and promenade r66)
	for i, deg in {35, 75, 115, 245, 285, 325} do
		local x, z = polar(58, deg)
		if i % 2 == 0 then cherry(g, x, z, 0.9) else pine(g, x, z, 0.9) end
	end
	-- outer edge trees, framing the promenade
	for i, deg in {28, 62, 96, 128, 230, 262, 298, 332} do
		local x, z = polar(102, deg)
		if i % 2 == 0 then pine(g, x, z, 1.25) else cherry(g, x, z, 1.25) end
	end
	-- stone lanterns ring the plaza; post lanterns line the east road
	for deg = 45, 315, 45 do
		local x, z = polar(51.5, deg)
		kit("StoneLantern", g, x, z, 0.45, deg)
	end
	for _, rx in {58, 76, 94} do
		kit("PostLantern", g, rx, -14, 0.3, 0)
		kit("PostLantern", g, rx, 14, 0.3, 180)
	end
end

---------------------------------------------------------------- stage-1 connection (reversible)
local function backupsFolder(): Folder
	local b = ServerStorage:FindFirstChild("Backups") or Instance.new("Folder")
	b.Name = "Backups"
	b.Parent = ServerStorage
	return b :: Folder
end
local function openStage1()
	local s1 = workspace:FindFirstChild("StageCourse") and workspace.StageCourse:FindFirstChild("Stage01")
	if not s1 then return end
	for _, c in s1:GetChildren() do
		if c:IsA("BasePart") and c.Name == "Part" and math.abs(c.Position.X + 87) < 1 and c.Size.Y >= 20 and c.Size.Z >= 150 then
			c:SetAttribute("OriginalParent", c:GetFullName())
			c.Name = "Stage01_StartWall"
			c.Parent = backupsFolder()
		end
	end
	local sp = workspace:FindFirstChild("SpawnLocation") :: SpawnLocation?
	if sp then
		if sp:GetAttribute("OriginalCFrame") == nil then sp:SetAttribute("OriginalCFrame", sp.CFrame) end
		sp.CFrame = CFrame.lookAt(W(28, 0, 0.6), W(60, 0, 0.6))
		sp.Transparency = 1
		sp.CanCollide = false
		local d = sp:FindFirstChildOfClass("Decal")
		if d then d.Transparency = 1 end
	end
end

function B.Revert()
	local old = workspace:FindFirstChild("Lobby")
	if old then old:Destroy() end
	local wall = backupsFolder():FindFirstChild("Stage01_StartWall")
	if wall then wall.Name = "Part"; wall.Parent = workspace.StageCourse.Stage01 end
	local sp = workspace:FindFirstChild("SpawnLocation") :: SpawnLocation?
	if sp and sp:GetAttribute("OriginalCFrame") then
		sp.CFrame = sp:GetAttribute("OriginalCFrame")
		sp.Transparency = 0
		sp.CanCollide = true
		local d = sp:FindFirstChildOfClass("Decal")
		if d then d.Transparency = 0 end
	end
end

function B.Build()
	local old = workspace:FindFirstChild("Lobby")
	if old then old:Destroy() end
	root = Instance.new("Model")
	root.Name = "Lobby"
	root:SetAttribute("BuiltBy", "ServerStorage.Tools.LobbyBuilder (issue #14)")
	buildIsland(); task.wait()
	buildPlaza()
	buildFountain()
	buildSpawn()
	buildGateAndBridge(); task.wait()
	buildAcademy()
	buildTraining()
	buildShowcase(); task.wait()
	buildHatchery()
	shrine("UpgradeShrine", 20, C(90, 230, 120), "UPGRADES", "Boost damage, training & more", "Upgrades")
	shrine("RebirthAltar", 140, C(200, 110, 255), "REBIRTH", "Reset for a permanent multiplier", "Rebirth")
	buildPortal()
	comingSoon("FuseMachine", 158, "PET FUSE MACHINE", function(g, x, z)
		Block(g, Vector3.new(8, 1, 7), x, z, 0.2, PAL.StoneDark)
		Block(g, Vector3.new(7, 6, 6), x, z, 1.2, C(120, 126, 142))
		Block(g, Vector3.new(7.4, 0.8, 6.4), x, z, 4.2, C(255, 200, 70))
		for _, o in {-2, 2} do
			P({Shape = Enum.PartType.Ball, Size = Vector3.new(3.2, 3.2, 3.2), CFrame = CFrame.new(W(x + o, z, 8.6)), Color = C(170, 220, 255), Material = Enum.Material.Glass, Transparency = 0.35, Parent = g})
		end
	end)
	comingSoon("BossShop", 202, "BOSS SHOP", function(g, x, z)
		Block(g, Vector3.new(10, 1, 7), x, z, 0.2, PAL.StoneDark)
		Block(g, Vector3.new(9, 3.4, 3.4), x, z, 1.2, PAL.Wood)
		for _, o in {-4, 4} do Block(g, Vector3.new(0.8, 8, 0.8), x + o, z, 1.2, PAL.WoodDark) end
		for i = 0, 4 do Block(g, Vector3.new(2.2, 0.6, 6), x - 4.4 + i * 2.2, z, 9.2, i % 2 == 0 and PAL.Vermilion or PAL.Tile) end
		Block(g, Vector3.new(2, 2, 2), x - 2, z, 4.6, C(255, 140, 50))
		Block(g, Vector3.new(2, 2, 2), x + 2, z, 4.6, C(120, 90, 200))
	end)
	buildBoards()
	buildDecor(); task.wait()
	root.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	root.WorldPivot = CFrame.new(CENTER)
	root.Parent = workspace
	openStage1()
	local n = 0
	for _, d in root:GetDescendants() do if d:IsA("BasePart") then n += 1 end end
	return n
end

return B
