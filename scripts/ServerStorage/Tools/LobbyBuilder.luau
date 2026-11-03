--!strict
-- LobbyBuilder v5 (edit-time tool, issue #14, owner direction 2026-11-02) — Workspace.Lobby.
--
--   require(game.ServerStorage.Tools.LobbyBuilder).Build()   -- (re)builds Workspace.Lobby only
--   Backup of the previous lobby: ServerStorage.Backups.Lobby_v4_pre_v5_20261102
--
-- v5 layout (world axes, lobby-local coordinates; -Z = north):
--   * WORLDS portal at the BACK (south edge); players spawn right in front of it FACING NORTH into the lobby.
--     Touching the portal opens the Worlds menu (or sends a brand-new player straight to Stage 1).
--   * +1 Anime Eyes floor: lime studded lawns cut by lavender checker ROADS with dark-purple borders.
--   * ~10 stone lanterns spread around the lobby (no more lantern rows along the path).
--   * 13 ORIGINAL training stations modelled in Blender (tools/blender/training_stations_v2.py -> StationKit).
--   * 14-pad hand-sign showcase (cartoon hand art, Anime Eyes-style text: name / xN / price or OWNED/EQUIPPED).
--   * 4 eggs (2 Trophies, 2 Robux), shrunk ~20%; Robux prices in animated rainbow text (client).
--   * Special pet pedestal sells the Nine-Tail Spirit Fox (developer product; Id 0 = not available yet).
-- Built from original parts / owner-approved assets only. The lobby is its own arena west of Stage 1.

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

-- lobby-local frame = world axes (north = -Z). The lobby is its own arena; the WORLDS portal teleports to Stage 1.
local ORIGIN = Vector3.new(-560, 0, 0) -- separate arena far west of Stage 1 (x = -42.5) so the course is not visible over the cliffs
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
	local head = Blk(parent, Vector3.new(2.2, 1.8, 2.2), x, z, 5.7, PAL.Lamp, {Material = Enum.Material.Neon, Transparency = 0.45})
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

local function rainbowText(l: TextLabel) l:SetAttribute("Rainbow", true); l.TextColor3 = Color3.new(1, 1, 1) end
local LAV1, LAV2, PURP = C(206, 192, 246), C(190, 174, 236), C(110, 74, 196)
local LIME1, LIME2 = C(150, 224, 62), C(138, 212, 54)

---------------------------------------------------------------- arena: lime lawn + lavender checker roads with purple borders
local ROADS = { -- {x0, x1, z0, z1}
	{-15, 15, -125, 125},      -- main road (spawn -> north landmark)
	{-140, 140, 44, 66},       -- south cross road
	{-140, 140, -56, -34},     -- north cross road
	{-34, 34, 78, 128},        -- spawn plaza in front of the WORLDS portal
}
local function inRoad(x: number, z: number): boolean
	for _, r in ROADS do if x > r[1] and x < r[2] and z > r[3] and z < r[4] then return true end end
	return false
end
local function buildArena()
	local g = group("Arena")
	Blk(g, Vector3.new(HX * 2 + 40, 10, HZ * 2 + 40), 0, 0, -10.2, PAL.Dirt2, {Name = "Bedrock"})
	-- lawn: big lime tiles (two tones, studded)
	local tile = 20
	for ix = 0, HX * 2 / tile - 1 do
		for iz = 0, HZ * 2 / tile - 1 do
			local x, z = -HX + tile / 2 + ix * tile, -HZ + tile / 2 + iz * tile
			Blk(g, Vector3.new(tile, 2, tile), x, z, -2, (ix + iz) % 2 == 0 and LIME1 or LIME2, merge(STUDS, {Name = "Lawn"}))
		end
	end
	-- roads: purple border slab, then lavender checker tiles on top
	for _, r in ROADS do
		local w, d = r[2] - r[1], r[4] - r[3]
		Blk(g, Vector3.new(w + 2.4, 0.3, d + 2.4), (r[1] + r[2]) / 2, (r[3] + r[4]) / 2, 0, PURP, {Name = "RoadEdge"})
	end
	local t2 = 6
	for ri, r in ROADS do
		for x = r[1], r[2] - 0.01, t2 do
			for z = r[3], r[4] - 0.01, t2 do
				local sx, sz = math.min(t2, r[2] - x), math.min(t2, r[4] - z)
				local cx, cz = x + sx / 2, z + sz / 2
				local covered = false -- earlier roads already tile this spot (no z-fighting at crossings)
				for j = 1, ri - 1 do local q = ROADS[j]; if cx > q[1] and cx < q[2] and cz > q[3] and cz < q[4] then covered = true end end
				if covered then continue end
				local even = (math.floor((cx + 300) / t2) + math.floor((cz + 300) / t2)) % 2 == 0
				Blk(g, Vector3.new(sx, 0.36, sz), cx, cz, 0, even and LAV1 or LAV2, merge(STUDS, {Name = "Road"}))
			end
		end
	end
end

local function buildCliffs()
	local g = group("Cliffs")
	local rng = Random.new(7)
	for tier = 0, 2 do
		local depth, h0 = 12, 7 + tier * 8
		local inner = tier * depth
		for _, side in {-1, 1} do
			for x = -HX - inner - depth, HX + inner + depth - 1, 20 do
				local h = h0 + rng:NextInteger(-2, 3)
				local z = side * (HZ + inner + depth / 2)
				Blk(g, Vector3.new(20, h, depth), x + 10, z, -1, (x // 20) % 2 == 0 and PAL.Dirt or PAL.Dirt2)
				Blk(g, Vector3.new(20, 1.4, depth), x + 10, z, h - 1, PAL.GrassTop, STUDS)
				if tier >= 1 and rng:NextNumber() < 0.55 then pine(g, x + 10 + rng:NextNumber(-5, 5), z + rng:NextNumber(-3, 3), h + 0.4, 1 + tier * 0.25) end
			end
			for z = -HZ, HZ - 1, 20 do
				local h = h0 + rng:NextInteger(-2, 3)
				if side == 1 and (z == 30 or z == 50) then continue end -- gap (z 30..70) for the road to Stage 1
				local x = side * (HX + inner + depth / 2)
				Blk(g, Vector3.new(depth, h, 20), x, z + 10, -1, (z // 20) % 2 == 0 and PAL.Dirt or PAL.Dirt2)
				Blk(g, Vector3.new(depth, 1.4, 20), x, z + 10, h - 1, PAL.GrassTop, STUDS)
				if tier >= 1 and rng:NextNumber() < 0.55 then pine(g, x + rng:NextNumber(-3, 3), z + 10, h + 0.4, 1 + tier * 0.25) end
			end
		end
	end
	-- a few small pines / bushes on the lawns (never on a road)
	local deco = group("LawnTrees", g)
	for _, pnt in {{-24, 20}, {-24, -20}, {26, -18}, {-130, 30}, {-130, -20}, {146, -20}, {28, -118}, {-28, -118}, {-60, 30}} do -- kept clear of station plots
		if not inRoad(pnt[1], pnt[2]) then pine(deco, pnt[1], pnt[2], 0, 0.85) end
	end
end

---------------------------------------------------------------- road to Stage 1 (owner 2026-11-02: "the lobby should connect to stage 1")
-- The south cross road leaves the lobby through a gap in the east cliffs, runs east, bends north and enters Stage 1's
-- open start gate. Local coords (ORIGIN = lobby centre); Stage 1's floor begins at world x = -42.5 (local 517.5).
local ROAD_END = 517.6
local STAGE_ROAD = { -- {x0, x1, z0, z1}
	{140, 452, 44, 66},          -- east from the south cross road
	{430, 452, -11, 66},         -- bend north toward the stage's centre line
	{430, ROAD_END, -11, 11},    -- straight into Stage 1
}
local function buildStageRoad()
	local g = group("StageRoad")
	g:SetAttribute("Note", "Walkable road lobby -> Stage 1 start gate (GameService treats x < -54.5 as lobby).")
	for i, r in STAGE_ROAD do
		local w, d = r[2] - r[1], r[4] - r[3]
		local cx, cz = (r[1] + r[2]) / 2, (r[3] + r[4]) / 2
		-- body: dirt base, lime shoulders (studded), purple border, lavender checker road
		Blk(g, Vector3.new(w + 16, 10, d + 16), cx, cz, -10.2, PAL.Dirt2, {Name = "RoadBase"})
		Blk(g, Vector3.new(w + 16, 2, d + 16), cx, cz, -2, i % 2 == 0 and LIME1 or LIME2, merge(STUDS, {Name = "Shoulder"}))
		Blk(g, Vector3.new(w + 2.4, 0.3, d + 2.4), cx, cz, 0, PURP, {Name = "RoadEdge"})
		for x = r[1], r[2] - 0.01, 6 do
			for z = r[3], r[4] - 0.01, 6 do
				local sx, sz = math.min(6, r[2] - x), math.min(6, r[4] - z)
				local tx, tz = x + sx / 2, z + sz / 2
				local covered = false
				for j = 1, i - 1 do local q = STAGE_ROAD[j]; if tx > q[1] and tx < q[2] and tz > q[3] and tz < q[4] then covered = true end end
				if covered then continue end
				local even = (math.floor((tx + 300) / 6) + math.floor((tz + 300) / 6)) % 2 == 0
				Blk(g, Vector3.new(sx, 0.36, sz), tx, tz, 0, even and LAV1 or LAV2, merge(STUDS, {Name = "Road"}))
			end
		end
	end
	-- invisible guard rails along the outer shoulder edges so nobody walks off into the void
	local INV = {Name = "Rail", Transparency = 1, CastShadow = false, CanQuery = false}
	Blk(g, Vector3.new(305, 12, 1), 307.5, 75.5, 0, Color3.new(1, 1, 1), INV)   -- north side of the east run
	Blk(g, Vector3.new(267, 12, 1), 288.5, 35.5, 0, Color3.new(1, 1, 1), INV)   -- south side (stops where the bend starts)
	Blk(g, Vector3.new(1, 12, 56), 460.5, 47.5, 0, Color3.new(1, 1, 1), INV)     -- outside of the bend (stops at the last straight)
	Blk(g, Vector3.new(1, 12, 54.5), 421.5, 8.25, 0, Color3.new(1, 1, 1), INV)  -- inside of the bend
	Blk(g, Vector3.new(96, 12, 1), 469.5, -19.5, 0, Color3.new(1, 1, 1), INV)   -- last straight, south
	Blk(g, Vector3.new(57, 12, 1), 489, 19.5, 0, Color3.new(1, 1, 1), INV)      -- last straight, north
	-- lanterns + an arrow sign at the lobby exit
	for _, pnt in {{200, 70}, {260, 40}, {340, 70}, {420, 40}, {456, 30}, {470, -15}} do lantern(g, pnt[1], pnt[2], true) end
	local post = Blk(g, Vector3.new(1, 7, 1), 150, 70, 0, PAL.Trunk)
	local sign = Blk(g, Vector3.new(0.6, 3, 9), 150, 70, 6, C(255, 214, 0), merge(STUDS, {Name = "StageSign"}))
	local _ = post
	local sg = Instance.new("SurfaceGui"); sg.Face = Enum.NormalId.Left; sg.LightInfluence = 0; sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sg.PixelsPerStud = 30; sg.Parent = sign
	local t = Instance.new("TextLabel"); t.BackgroundTransparency = 1; t.Size = UDim2.fromScale(1, 1); t.Font = Enum.Font.LuckiestGuy; t.TextScaled = true
	t.Text = "STAGE 1  >>"; t.TextColor3 = Color3.new(1, 1, 1); local st = Instance.new("UIStroke"); st.Thickness = 3; st.Parent = t; t.Parent = sg
end

---------------------------------------------------------------- spawn (in front of the portal, facing north) + ~10 lanterns
local function buildSpawnAndLamps()
	local pos = W(0, 96, 1.0)
	P({Name = "LobbySpawn", Size = Vector3.new(10, 1, 10), CFrame = CFrame.lookAt(pos, pos - Vector3.zAxis),
		Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false})
	local g = group("Lanterns")
	-- 10 lanterns: plaza corners, road crossings and lawn edges (owner: "place around 10 around the lobby")
	for i, pnt in {{-38, 84}, {38, 84}, {-19, 69}, {19, 69}, {-19, -31}, {19, -31}, {-60, 69}, {60, 69}, {-60, -59}, {60, -59}} do
		lantern(g, pnt[1], pnt[2], i <= 6)
	end
end

---------------------------------------------------------------- WORLDS portal at the back (south edge), ring facing north
local function buildPortal()
	local g = group("WorldsPortal")
	local pz = 118
	for _, x in {-18, 18} do
		Blk(g, Vector3.new(8, 2, 8), x, pz, 0.3, PAL.Stone2)
		Blk(g, Vector3.new(6, 34, 6), x, pz, 2.3, PAL.Stone)
	end
	Blk(g, Vector3.new(44, 5, 8), 0, pz, 36.3, PAL.Stone)
	Blk(g, Vector3.new(46, 1.5, 7), 0, pz, 41.3, PAL.Stone2)
	local header = Blk(g, Vector3.new(24, 4.4, 1), 0, pz - 4.1, 36.6, PAL.Ink, {Name = "Header"})
	local sg = Instance.new("SurfaceGui"); sg.Face = Enum.NormalId.Front; sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sg.PixelsPerStud = 30; sg.LightInfluence = 0; sg.Parent = header
	local t = text(sg, "WORLDS", UDim2.fromScale(0.05, 0.08), UDim2.fromScale(0.9, 0.84), Color3.new(1, 1, 1), 3); t.Font = Enum.Font.LuckiestGuy
	local c = W(0, pz, 17.5)
	local ringModel = group("Ring", g)
	for i = 0, 39 do
		local a = i * math.pi * 2 / 40
		P({Size = Vector3.new(2.8, 1.6, 1.4), CFrame = CFrame.new(c) * CFrame.Angles(0, 0, a) * CFrame.new(0, 13.5, 0), Color = i % 5 == 0 and PAL.PortalRim or PAL.Portal,
			Material = Enum.Material.Neon, CanCollide = false, CastShadow = false, Parent = ringModel})
	end
	for i = 0, 11 do
		local a = i * math.pi * 2 / 12
		P({Size = Vector3.new(0.9, 0.9, 0.8), CFrame = CFrame.new(c) * CFrame.Angles(0, 0, a) * CFrame.new(0, 5 + (i % 3) * 2.4, 0), Color = PAL.PortalRim,
			Material = Enum.Material.Neon, CanCollide = false, CastShadow = false, Parent = ringModel})
	end
	ringModel.WorldPivot = CFrame.new(c)
	ringModel:SetAttribute("Spin", "portalZ")
	local core = P({Name = "Core", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 26, 26), CFrame = CFrame.new(c) * CFrame.Angles(0, math.rad(90), 0),
		Color = PAL.Portal, Material = Enum.Material.Neon, Transparency = 0.3, CanCollide = false, CastShadow = false, Parent = g})
	core:SetAttribute("WorldsPortal", true) -- client: touching it opens the Worlds menu / sends new players to Stage 1
	local l = Instance.new("PointLight"); l.Color = PAL.Portal; l.Range = 26; l.Brightness = 1.6; l.Parent = core
	local step = Blk(g, Vector3.new(16, 0.4, 6), 0, pz - 6, 0.3, PAL.Stone2, {Name = "Threshold"})
	prompt(step, "Choose World", "Worlds Portal", {LobbyAction = "Menu", Menu = "Stages"})
end

---------------------------------------------------------------- leaderboards beside the portal
local function buildBoards()
	local g = group("Leaderboards")
	for i, d in {{"LifetimeHandSigns", "HAND SIGNS"}, {"Trophies", "TROPHIES"}, {"Stage", "STAGE"}} do
		local x, z = -36 - i * 18, 116
		local m = group("Board_" .. d[1], g)
		m:SetAttribute("BoardKey", d[1])
		local pos = W(x, z, 9)
		local cf = CFrame.lookAt(pos, pos - Vector3.zAxis)
		P({Size = Vector3.new(15, 17, 1), CFrame = cf * CFrame.new(0, 0, 0.6), Color = C(120, 90, 210), Parent = m})
		local panel = P({Name = "Panel", Size = Vector3.new(13.5, 15.5, 0.6), CFrame = cf, Color = C(244, 242, 252), Parent = m})
		P({Size = Vector3.new(15, 2, 1.4), CFrame = cf * CFrame.new(0, 9.4, 0.2), Color = C(120, 90, 210), Parent = m})
		for _, sx in {-1, 1} do P({Size = Vector3.new(1.2, 9, 1.2), CFrame = cf * CFrame.new(sx * 6.5, -12, 0.6), Color = C(120, 90, 210), Parent = m}) end
		local sg = Instance.new("SurfaceGui"); sg.Name = "BoardGui"; sg.Face = Enum.NormalId.Front; sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sg.PixelsPerStud = 30; sg.LightInfluence = 0; sg.Parent = panel
		local tl = text(sg, d[2], UDim2.fromScale(0.04, 0.02), UDim2.fromScale(0.92, 0.12), C(130, 96, 230), 2); tl.Font = Enum.Font.LuckiestGuy
		for r = 1, 8 do
			text(sg, r == 1 and "Updates on live servers" or "", UDim2.fromScale(0.05, 0.16 + (r - 1) * 0.1), UDim2.fromScale(0.9, 0.085), C(60, 50, 80), 0, "Row" .. r)
		end
	end
end

---------------------------------------------------------------- special pet (Robux): Nine-Tail Spirit Fox pedestal
local function buildSpecialPet()
	local g = group("SpecialPet")
	local x, z = 58, 100
	Disc(g, 16, 1.4, x, z, 1.7, PAL.Stone)
	Disc(g, 13, 1, x, z, 2.4, C(255, 110, 40), {Material = Enum.Material.Neon, Transparency = 0.25})
	for _, o in {{-6, -6}, {-6, 6}, {6, -6}, {6, 6}} do
		Blk(g, Vector3.new(1.4, 10, 1.4), x + o[1], z + o[2], 1.7, PAL.Ink)
		Blk(g, Vector3.new(1.6, 1.6, 1.6), x + o[1], z + o[2], 11.7, C(255, 140, 50), {Material = Enum.Material.Neon})
	end
	local fox, cream = C(255, 136, 52), C(255, 230, 200) -- original blocky spirit fox (not a licensed character)
	Blk(g, Vector3.new(6, 5, 9), x, z, 2.4, fox)
	Blk(g, Vector3.new(5, 5, 5), x, z - 5.5, 6, fox)
	Blk(g, Vector3.new(2.4, 1.6, 2.4), x, z - 8.6, 6.6, cream)
	for _, sx in {-1, 1} do
		P({Size = Vector3.new(1.4, 3, 1.4), CFrame = CFrame.new(W(x + sx * 1.6, z - 5.5, 12)) * CFrame.Angles(0, 0, math.rad(sx * -12)), Color = fox, Parent = g})
		Blk(g, Vector3.new(0.9, 0.9, 0.3), x + sx * 1.3, z - 8.05, 8.2, PAL.Ink)
	end
	for t = -4, 4 do -- nine tails fanned out
		P({Size = Vector3.new(1.3, 1.3, 7), CFrame = CFrame.new(W(x + t * 0.9, z + 6, 8.5)) * CFrame.Angles(math.rad(40), math.rad(t * 13), 0), Color = t % 2 == 0 and cream or fox, Parent = g})
	end
	beam(g, x - 6, z - 6, 12, C(255, 150, 60)); beam(g, x + 6, z - 6, 12, C(255, 150, 60))
	local hit = Blk(g, Vector3.new(14, 6, 14), x, z, 2.4, Color3.new(1, 1, 1), {Name = "Hit", Transparency = 1, CanCollide = false})
	prompt(hit, "Buy", "Nine-Tail Spirit Fox", {LobbyAction = "Product", Product = "PetSpiritFox"})
	local bb = billboard(anchor(g, x, z, 19), Vector2.new(13, 7.5), 0, 120, "Card")
	local t1 = text(bb, "SPECIAL PET!", UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.3), C(255, 220, 60), 4); t1.Font = Enum.Font.LuckiestGuy; rainbowText(t1)
	local t2 = text(bb, "NINE-TAIL FOX", UDim2.fromScale(0, 0.3), UDim2.fromScale(1, 0.26), C(255, 150, 60), 4); t2.Font = Enum.Font.LuckiestGuy
	local t3 = text(bb, "x100 HAND SIGNS", UDim2.fromScale(0.1, 0.56), UDim2.fromScale(0.8, 0.2), Color3.new(1, 1, 1), 3); t3.Font = Enum.Font.LuckiestGuy
	icon(bb, "Robux", UDim2.fromScale(0.27, 0.77), UDim2.fromScale(0.14, 0.22))
	local pr = text(bb, "799", UDim2.fromScale(0.42, 0.77), UDim2.fromScale(0.34, 0.22), C(120, 255, 120), 3, "Price"); pr.Font = Enum.Font.LuckiestGuy; rainbowText(pr)
end

---------------------------------------------------------------- boss rift (placeholder) west lawn
local function buildBossRift()
	local g = group("BossRift")
	g:SetAttribute("Placeholder", "Visual only — no timed boss backend; no prompt.")
	local x, z = -80, 5
	Disc(g, 18, 0.6, x, z, 0.75, C(70, 30, 40))
	local c = W(x, z, 14)
	P({Size = Vector3.new(9, 9, 9), CFrame = CFrame.new(c) * CFrame.Angles(0, 0, math.rad(45)) * CFrame.Angles(math.rad(45), 0, 0), Color = C(70, 20, 90), Material = Enum.Material.Neon, Transparency = 0.15, CanCollide = false, Parent = g})
	P({Size = Vector3.new(6, 20, 1.2), CFrame = CFrame.new(c), Color = C(150, 20, 40), Material = Enum.Material.Neon, CanCollide = false, Parent = g})
	for i = 1, 8 do
		local r = Random.new(i)
		Blk(g, Vector3.new(1.4, 1.4, 1.4) * (0.6 + r:NextNumber()), x + r:NextNumber(-7, 7), z + r:NextNumber(-7, 7), r:NextNumber(4, 22), C(40, 20, 30), {CanCollide = false})
	end
	local bb = billboard(anchor(g, x, z, 27), Vector2.new(12, 3.4), 0, 100, "Card")
	local t = text(bb, "BOSS FIGHT", UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.58), C(255, 120, 60), 4); t.Font = Enum.Font.LuckiestGuy
	text(bb, "COMING SOON", UDim2.fromScale(0.15, 0.6), UDim2.fromScale(0.7, 0.38), Color3.new(1, 1, 1), 3)
end

---------------------------------------------------------------- north landmark: big torii at the end of the main road
local function buildLandmark()
	local g = group("NorthGate")
	local z = -116
	for _, x in {-13, 13} do Blk(g, Vector3.new(3, 26, 3), x, z, 0, C(210, 40, 40)); Blk(g, Vector3.new(4.4, 2, 4.4), x, z, 0, PAL.Ink) end
	Blk(g, Vector3.new(36, 2.4, 4), 0, z, 26, PAL.Ink)
	Blk(g, Vector3.new(32, 1.8, 3), 0, z, 21.5, C(210, 40, 40))
	local plate = Blk(g, Vector3.new(10, 4, 0.6), 0, z + 1.8, 21, PAL.Ink, {Name = "Plate"})
	local sg = Instance.new("SurfaceGui"); sg.Face = Enum.NormalId.Back; sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sg.PixelsPerStud = 30; sg.LightInfluence = 0; sg.Parent = plate
	local t = text(sg, "+1 HAND SIGNS", UDim2.fromScale(0.04, 0.1), UDim2.fromScale(0.92, 0.8), C(255, 220, 80), 3); t.Font = Enum.Font.LuckiestGuy
end

---------------------------------------------------------------- training field: 13 Blender stations (east half)
-- {x, z, yaw}: yaw turns the Blender front (Roblox +Z) toward the nearest cross road (0 = faces +Z / the spawn side)
local STATION_SLOTS = {
	{40, 28, 0}, {70, 28, 0}, {100, 28, 0}, {130, 28, 0},           -- near the spawn, face the south cross road: X2 X3 X5 X7
	{40, 2, 180}, {70, 2, 180}, {100, 2, 180}, {130, 2, 180},       -- face the north cross road: X8$ X10 X12 X20
	{40, -72, 0}, {70, -72, 0}, {100, -72, 0}, {130, -72, 0},       -- beyond the north cross road, facing it: X25$ X35 X40 X50$
	{85, -104, 0},                                                  -- X250$ (big) at the far end
}
-- beam tip height above the lobby floor: beginners short, legendary stations taller (issue #14 review: no sky pillars)
local BEAM_TIP = {16, 16.5, 17, 21, 24, 23, 25, 25, 23, 26, 26, 27, 31}
local STATION_MODEL = {"Dummy", "Ring", "ChakraPool", "Forge", "GoldenDojo", "ScrollTemple", "StormPagoda", "GravitySeal", "ThunderDome",
	"CrimsonAltar", "VoidTotem", "DragonGate", "SageThrone"}
local function buildStations()
	local g = group("TrainingStations")
	g:SetAttribute("Note", "ZoneMult applied server-side by GameService from SystemsConfig.TrainingStations. Models: Blender (StationKit).")
	local kit = ServerStorage:FindFirstChild("LobbyAssets") and ServerStorage.LobbyAssets:FindFirstChild("BlenderStations")
	for i, st in SC.TrainingStations do
		local slot = STATION_SLOTS[i]
		local x, z = slot[1], slot[2]
		local m = group("Station" .. i, g)
		m:SetAttribute("StationIndex", i)
		local big = i == #SC.TrainingStations
		local src = kit and kit:FindFirstChild(STATION_MODEL[i])
		local top = 16
		if src then
			local mdl = (src :: Model):Clone()
			mdl.Name = "StationModel"
			mdl:SetAttribute("Kind", STATION_MODEL[i])
			if big then mdl:ScaleTo(1.35) end
			mdl:PivotTo(CFrame.new(W(x, z, 0)) * CFrame.Angles(0, math.rad(slot[3] or 0), 0)) -- front faces the nearest cross road
			mdl.Parent = m
			-- the Blender neon pillar (+ its white core) becomes FxCore: BeamOrigin / BeamTip / NameAnchor attachments.
			-- The client draws a custom textured beam between them; the station label hangs at the beam's top.
			local beamPart: BasePart? = nil
			for _, d in mdl:GetDescendants() do if d:IsA("BasePart") and d:GetAttribute("Fx") == "beam" then beamPart = d; break end end
			local bx, bz, baseY = W(x, z, 0).X, W(x, z, 0).Z, nil
			if beamPart then
				local bp = beamPart :: BasePart
				bx, bz, baseY = bp.Position.X, bp.Position.Z, bp.Position.Y - bp.Size.X / 2 - ORIGIN.Y
				for _, d in mdl:GetDescendants() do
					if d:IsA("BasePart") and d ~= bp and d.Material == Enum.Material.Neon and math.abs(d.Position.X - bx) < 0.08
						and math.abs(d.Position.Z - bz) < 0.08 and math.abs(d.Size.X - bp.Size.X) < 0.08 then d:Destroy() end
				end
				bp:Destroy()
			end
			local cf, sz = mdl:GetBoundingBox()
			local modelTop = (cf.Position.Y + sz.Y / 2) - ORIGIN.Y
			baseY = baseY or modelTop
			local tip = math.max(BEAM_TIP[i] or 20, (baseY :: number) + 6)
			local core = P({Name = "FxCore", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(bx, ORIGIN.Y + (baseY :: number), bz), Transparency = 1,
				CanCollide = false, CanQuery = false, CanTouch = false, Parent = m})
			core:SetAttribute("Kind", STATION_MODEL[i]); core:SetAttribute("Tier", i); core:SetAttribute("Color", st.Color)
			core:SetAttribute("Floor", ORIGIN.Y + 0.6); core:SetAttribute("ZoneX", W(x, z, 0).X); core:SetAttribute("ZoneZ", W(x, z, 0).Z)
			for name, h in {BeamOrigin = 0, BeamTip = tip - baseY, NameAnchor = tip - baseY + 2.4} do
				local a = Instance.new("Attachment"); a.Name = name; a.Position = Vector3.new(0, h, 0); a.Parent = core
			end
			top = tip
			m:SetAttribute("NameAnchorY", tip + 2.4)
		end
		local half = big and 11 or 8
		if st.Pass then -- Robux zone: gold aura under the plinth + unlock prompt (game pass; locked until the owner creates it)
			Blk(m, Vector3.new(half * 2 + 2, 0.3, half * 2 + 2), x, z, 0.02, C(255, 200, 40), {Material = Enum.Material.Neon, Transparency = 0.25, CanCollide = false, Name = "PassGlow"})
			local hit = Blk(m, Vector3.new(half * 2, 3, half * 2), x, z, 0, Color3.new(1, 1, 1), {Name = "PromptHost", Transparency = 1, CanCollide = false})
			prompt(hit, "Unlock", st.Name, {LobbyAction = "Pass", Pass = st.Pass})
		end
		local zone = P({Name = "Zone", Size = Vector3.new(half * 2, 14, half * 2), CFrame = CFrame.new(W(x, z, 7)), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Parent = m})
		zone:SetAttribute("StationIndex", i)
		-- (light pillars now come from the Blender station models themselves)
		-- label: "X2 HAND SIGNS" + price (rebirth icon + count, or Robux in rainbow) — nothing else (declutter)
		local nameAt = m:FindFirstChild("FxCore") and (m.FxCore :: BasePart):FindFirstChild("NameAnchor")
		local bb: BillboardGui
		if nameAt then -- label sits at the top of the beam (BillboardGui parented to the NameAnchor attachment)
			bb = Instance.new("BillboardGui")
			bb.Name = "Card"; bb.Size = UDim2.fromScale(13, 4.9); bb.MaxDistance = 170; bb.LightInfluence = 0
			bb.Parent = nameAt
		else
			bb = billboard(anchor(m, x, z, top + 4), Vector2.new(13, 4.9), 0, 170, "Card")
		end
		local t = text(bb, "X" .. Config.Format(st.Mult) .. " HAND SIGNS", UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.55), st.Color, 4, "Mult"); t.Font = Enum.Font.LuckiestGuy
		if st.Pass then
			icon(bb, "Robux", UDim2.fromScale(0.28, 0.57), UDim2.fromScale(0.14, 0.42))
			local pr = text(bb, tostring(st.Robux), UDim2.fromScale(0.44, 0.58), UDim2.fromScale(0.34, 0.4), C(120, 255, 120), 4, "Price"); pr.Font = Enum.Font.LuckiestGuy
			rainbowText(pr); rainbowText(t)
		else
			icon(bb, "Rebirth", UDim2.fromScale(0.18, 0.57), UDim2.fromScale(0.13, 0.42))
			local n = st.Rebirths or 0
			local pr = text(bb, Config.Format(n) .. (n == 1 and " REBIRTH" or " REBIRTHS"), UDim2.fromScale(0.32, 0.58), UDim2.fromScale(0.58, 0.4), n > 0 and C(255, 120, 120) or C(120, 255, 130), 4, "Price")
			pr.Font = Enum.Font.LuckiestGuy
		end
	end
end

---------------------------------------------------------------- hand sign showcase (west of the spawn): 2 rows x 7, Anime Eyes text layout
local function buildShowcase()
	local g = group("SignShowcase")
	g:SetAttribute("Note", "Pad colours/text are per-player, set by the client Lobby module from server state.")
	local x0, dx = -128, 15
	local zF, zB = 74, 92
	Blk(g, Vector3.new(7 * dx + 6, 1, 14), x0 + 3 * dx, zF, -0.4, PAL.Stone, {Name = "FrontPlatform"})
	Blk(g, Vector3.new(7 * dx + 6, 8.6, 14), x0 + 3 * dx, zB, -0.4, PAL.Stone2, {Name = "BackPlatform"})
	Blk(g, Vector3.new(7 * dx + 6, 0.6, 1), x0 + 3 * dx, zF - 7.4, 0.4, PAL.Gold, {Material = Enum.Material.Neon})
	for i, id in Config.HandSignOrder do
		local s = Config.HandSigns[id]
		local back = i > 7
		local k = back and i - 8 or i - 1
		local x, z = x0 + k * dx, back and zB or zF
		local top = back and 8.2 or 0.6
		local m = group("Pad_" .. id, g)
		m:SetAttribute("SignId", id)
		local pad = Blk(m, Vector3.new(10, 0.5, 9), x, z, top, C(220, 60, 60), {Name = "Pad", Material = Enum.Material.Neon, Transparency = 0.1})
		prompt(pad, "Buy", s.Name, {LobbyAction = "Sign", SignId = id})
		-- floating cartoon hand art (no tile / frame), like the reference's floating eyes
		local iconId = Assets.SignIcons and Assets.SignIcons[id]
		local art = billboard(anchor(m, x, z, top + (back and 13 or 11), "ArtAnchor"), Vector2.new(8, 8), 0, 160, "Emblem")
		if iconId then
			local img = Instance.new("ImageLabel"); img.Name = "Art"; img.BackgroundTransparency = 1; img.Image = iconId
			img.ScaleType = Enum.ScaleType.Fit; img.Size = UDim2.fromScale(1, 1); img.Parent = art
		else
			local q = text(art, "?", UDim2.fromScale(0.2, 0.1), UDim2.fromScale(0.6, 0.8), Color3.new(1, 1, 1), 5); q.Font = Enum.Font.LuckiestGuy
		end
		-- reference text stack: NAME (sign colour) / xN Hand Signs / trophy price  -or-  EQUIPPED / OWNED
		local bb = billboard(anchor(m, x, z, top + 5.4), Vector2.new(11, 5), 0, 120, "Card")
		local n = text(bb, s.Name, UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.36), s.Color:Lerp(Color3.new(1, 1, 1), 0.25), 3, "SignName"); n.Font = Enum.Font.FredokaOne
		text(bb, "x" .. Config.Format(s.Multiplier) .. " Hand Signs", UDim2.fromScale(0.05, 0.36), UDim2.fromScale(0.9, 0.3), Color3.new(1, 1, 1), 3, "Mult")
		icon(bb, "Trophy", UDim2.fromScale(0.2, 0.68), UDim2.fromScale(0.16, 0.32)).Name = "PriceIcon"
		text(bb, "", UDim2.fromScale(0.05, 0.68), UDim2.fromScale(0.9, 0.32), Color3.new(1, 1, 1), 3, "Status")
	end
end

---------------------------------------------------------------- eggs (north-west, along the north road): 4 eggs + Boss Shop / Fuse placeholders
local function buildEggs()
	local g = group("EggHatchery")
	Blk(g, Vector3.new(118, 0.4, 18), -84, -74, 0.02, PAL.Path, merge(STUDS, {Name = "EggWalk"}))
	for _, z in {-83.4, -64.6} do Blk(g, Vector3.new(118, 0.45, 1.2), -84, z, 0.02, PAL.LimeEdge) end
	local eggAssets = ServerStorage:FindFirstChild("LobbyAssets") and ServerStorage.LobbyAssets:FindFirstChild("Eggs")
	for i, eggId in SC.EggOrder do
		local egg = SC.Eggs[eggId]
		local x, z = -36 - (i - 1) * 26, -74
		local m = group("Egg_" .. eggId, g)
		local glowCol = egg.Color:Lerp(Color3.new(1, 1, 1), 0.2)
		Disc(m, 12, 0.8, x, z, 1.1, PAL.Stone)
		Disc(m, 11, 0.82, x, z, 1.12, glowCol, {Material = Enum.Material.Neon, Transparency = 0.35})
		Disc(m, 9.6, 0.86, x, z, 1.16, PAL.Stone2, STUDS)
		local top = 1.16
		local hit = Blk(m, Vector3.new(8, 3, 8), x, z, top, Color3.new(1, 1, 1), {Name = "Pedestal", Transparency = 1, CanCollide = false})
		prompt(hit, "Hatch", egg.Name .. (egg.Robux and (" · R$ " .. egg.Robux) or (" · " .. Config.Format(egg.Cost) .. " Trophies")), {LobbyAction = "Hatch", EggId = eggId})
		local src = eggAssets and eggAssets:FindFirstChild(eggId)
		local h = 11
		if src then
			local mdl = placeMesh(m, src, x, z, top, 8.4, 0, 11.2) -- shrunk ~20% (owner request)
			mdl.Name = "EggModel"
			mdl:SetAttribute("Spin", "egg")
			local _, sz = mdl:GetBoundingBox(); h = sz.Y
		end
		local l = Instance.new("PointLight"); l.Color = glowCol; l.Range = 9; l.Brightness = 0.7; l.Shadows = false; l.Parent = hit
		if egg.Robux then beam(m, x, z + 4.5, 3, egg.Color) end
		local bb = billboard(anchor(m, x, z, top + h + 4.5), Vector2.new(11, 4.4), 0, 130, "Card")
		local t = text(bb, string.upper(egg.Name), UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.52), egg.Color:Lerp(Color3.new(1, 1, 1), 0.35), 3); t.Font = Enum.Font.LuckiestGuy
		if egg.Robux then
			rainbowText(t)
			icon(bb, "Robux", UDim2.fromScale(0.26, 0.54), UDim2.fromScale(0.16, 0.44))
			local pr = text(bb, tostring(egg.Robux), UDim2.fromScale(0.44, 0.55), UDim2.fromScale(0.34, 0.43), C(120, 255, 120), 3); pr.Font = Enum.Font.LuckiestGuy; rainbowText(pr)
		else
			icon(bb, "Trophy", UDim2.fromScale(0.24, 0.54), UDim2.fromScale(0.16, 0.44))
			local pr = text(bb, Config.Format(egg.Cost), UDim2.fromScale(0.42, 0.55), UDim2.fromScale(0.4, 0.43), C(255, 214, 90), 3); pr.Font = Enum.Font.LuckiestGuy
		end
	end
	local function placeholder(name: string, x: number, title: string, build: (Model) -> ())
		local m = group(name, g)
		m:SetAttribute("Placeholder", "Visual only — backend not built; no prompt or remote is exposed.")
		build(m)
		local bb = billboard(anchor(m, x, -104, 15), Vector2.new(14, 4.6), 0, 150, "Card")
		local t = text(bb, title, UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.58), C(255, 150, 230), 4); t.Font = Enum.Font.LuckiestGuy
		text(bb, "COMING SOON", UDim2.fromScale(0.15, 0.6), UDim2.fromScale(0.7, 0.38), C(255, 120, 120), 3)
	end
	placeholder("BossShop", -112, "BOSS SHOP", function(m)
		Blk(m, Vector3.new(12, 1, 8), -112, -104, 0.3, PAL.Stone)
		Blk(m, Vector3.new(10, 4, 4), -112, -106, 1.3, C(200, 50, 46))
		for _, sx in {-5, 5} do Blk(m, Vector3.new(0.9, 9, 0.9), -112 + sx, -102, 1.3, PAL.Ink) end
		Blk(m, Vector3.new(13, 1.2, 7), -112, -104, 10.3, C(200, 50, 46)); Blk(m, Vector3.new(11, 1, 5), -112, -104, 11.5, PAL.Ink)
	end)
	placeholder("FuseMachine", -84, "FUSE MACHINE", function(m)
		Blk(m, Vector3.new(10, 1.4, 10), -84, -104, 0.3, PAL.Stone)
		for _, o in {{-4, -4}, {-4, 4}, {4, -4}, {4, 4}} do Blk(m, Vector3.new(1.4, 3, 1.4), -84 + o[1], -104 + o[2], 1.7, C(240, 240, 250)) end
		Blk(m, Vector3.new(5, 6, 5), -84, -104, 1.7, C(110, 60, 200), {Material = Enum.Material.Glass, Transparency = 0.35})
		P({Shape = Enum.PartType.Ball, Size = Vector3.new(3, 3, 3), CFrame = CFrame.new(W(-84, -104, 4.7)), Color = C(220, 120, 255), Material = Enum.Material.Neon, CanCollide = false, Parent = m})
		Blk(m, Vector3.new(6, 1, 6), -84, -104, 7.7, C(240, 240, 250))
	end)
end

---------------------------------------------------------------- build
function B.Build(): number
	local old = workspace:FindFirstChild("Lobby"); if old then old:Destroy() end
	root = Instance.new("Model")
	root.Name = "Lobby"
	root:SetAttribute("BuiltBy", "ServerStorage.Tools.LobbyBuilder v5 (issue #14, owner direction 2026-11-02)")
	buildArena(); task.wait()
	buildCliffs(); task.wait()
	buildStageRoad(); task.wait()
	buildSpawnAndLamps()
	buildPortal()
	buildBoards()
	buildSpecialPet()
	buildBossRift()
	buildLandmark(); task.wait()
	buildStations(); task.wait()
	buildShowcase()
	buildEggs(); task.wait()
	root.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	root.WorldPivot = CFrame.new(ORIGIN)
	root.Parent = workspace
	local sp = workspace:FindFirstChild("SpawnLocation") :: SpawnLocation?
	if sp then
		sp.CFrame = CFrame.lookAt(W(0, 96, 0.6), W(0, 0, 0.6)); sp.Transparency = 1; sp.CanCollide = false
		local d = sp:FindFirstChildOfClass("Decal"); if d then d.Transparency = 1 end
	end
	local n = 0
	for _, d in root:GetDescendants() do if d:IsA("BasePart") then n += 1 end end
	return n
end

return B
