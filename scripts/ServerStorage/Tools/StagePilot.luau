--!strict
-- StagePilot (edit-time tool, issue #14 visual pilot) — restyles Stage01..Stage03 IN PLACE.
--
--   require(game.ServerStorage.Tools.StagePilot).Apply()   -- idempotent: rebuilds each stage's "Pilot" model
--   Revert: restore the stage models from ServerStorage.Backups.Backup_preIssue14_Stages01-03_20261102.
--
-- Never regenerates, deletes or renumbers stages. Never moves EnemySpawns, Spawn, TrophyPad or the
-- Gate.Barrier (client gate logic and server guards are untouched). Replaced props (old palette-swapped
-- Landmark, bamboo-like desert "cactus") are MOVED to ServerStorage.Backups.Issue14_ReplacedProps.
-- Gate text is generated from live Config each run; the client still drives the "Left" label.

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local ServerStorage = game:GetService("ServerStorage")

local SP = {}
local C = Color3.fromRGB
local FONT = Enum.Font.FredokaOne
local L = Config.StageLength

local cur: Model
local X0 = 0
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function P(props: {[string]: any}): BasePart
	local p = Instance.new("Part") :: any
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	if props.Shape then p.Shape = props.Shape end
	for k, v in props do if k ~= "Parent" and k ~= "Shape" then p[k] = v end end
	p.Parent = props.Parent or cur
	return p
end
-- block with its BOTTOM at y (world), x/z stage-local
local function B(size: Vector3, x: number, z: number, y: number, color: Color3, extra: {[string]: any}?): BasePart
	local t: {[string]: any} = {Size = size, CFrame = CFrame.new(X0 + x, y + size.Y / 2, z), Color = color}
	if extra then for k, v in extra do t[k] = v end end
	return P(t)
end
local function ground(x: number, z: number): number
	local r = workspace:Raycast(Vector3.new(X0 + x, 300, z), Vector3.new(0, -600, 0), rayParams)
	return r and r.Position.Y or 0
end
local function blob(size: Vector3, x: number, z: number, y: number, color: Color3, extra: {[string]: any}?): BasePart
	-- small ball part + scaled sphere mesh: big soft silhouette, tiny footprint
	local t: {[string]: any} = {Shape = Enum.PartType.Ball, Size = Vector3.new(4, 4, 4), CFrame = CFrame.new(X0 + x, y + size.Y / 2, z), Color = color}
	if extra then for k, v in extra do t[k] = v end end
	local p = P(t)
	local m = Instance.new("SpecialMesh")
	m.MeshType = Enum.MeshType.Sphere
	m.Scale = size / 4
	m.Parent = p
	return p
end
local function label(parent: Instance, text: string, y0: number, h: number, color: Color3, stroke: number?, name: string?): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name or "Label"
	l.BackgroundTransparency = 1
	l.Font = FONT
	l.TextScaled = true
	l.Text = text
	l.TextColor3 = color
	l.Position = UDim2.fromScale(0.04, y0)
	l.Size = UDim2.fromScale(0.92, h)
	local s = Instance.new("UIStroke")
	s.Thickness = stroke or 3
	s.Color = C(20, 16, 26)
	s.Parent = l
	l.Parent = parent
	return l
end
local function stash(inst: Instance, tag: string)
	local b = ServerStorage:FindFirstChild("Backups") or Instance.new("Folder")
	b.Name = "Backups"; b.Parent = ServerStorage
	local f = b:FindFirstChild("Issue14_ReplacedProps") or Instance.new("Folder")
	f.Name = "Issue14_ReplacedProps"; f.Parent = b
	inst:SetAttribute("OriginalPath", tag)
	inst.Parent = f
end

---------------------------------------------------------------- shared props
local function tree(x: number, z: number, s: number, trunk: Color3, leaves: {Color3})
	local y = ground(x, z)
	B(Vector3.new(1.8, 9, 1.8) * s, x, z, y, trunk)
	B(Vector3.new(12, 4.5, 12) * s, x, z, y + 7.5 * s, leaves[1])
	B(Vector3.new(9, 4, 9) * s, x + 1.6 * s, z - 1 * s, y + 11 * s, leaves[2] or leaves[1])
	B(Vector3.new(6, 3, 6) * s, x - 1.2 * s, z + 1.2 * s, y + 14.5 * s, leaves[1])
end

-- restyled gate: themed frame colours, header from live Config, opaque hanging sign plates that carry the
-- existing FrontGui/BackGui (via Adornee) so text no longer bleeds through the translucent barrier.
local function restyleGate(stage: Model, i: number, frame: Color3, beam: Color3, tint: Color3)
	local gate = stage:FindFirstChild("Gate")
	local barrier = gate and gate:FindFirstChild("Barrier") :: BasePart?
	if not gate or not barrier then return end
	local gx = barrier.Position.X
	for _, p in gate:GetChildren() do
		if p:IsA("BasePart") and p ~= barrier then
			if p.Size.Y >= 40 then p.Color = frame; p.Material = Enum.Material.SmoothPlastic
			elseif p.Size.Z >= 70 and p.Size.Y < 5 then p.Color = beam end
			local sg = p:FindFirstChildOfClass("SurfaceGui")
			local tl = sg and sg:FindFirstChildOfClass("TextLabel")
			if tl then
				local nxt = Config.Stages[i + 1]
				tl.Text = nxt and ("STAGE " .. (i + 1) .. " ▶ " .. string.upper(nxt.Name)) or "FINAL STAGE"
				tl.TextColor3 = C(255, 214, 90)
			end
		end
	end
	barrier.Color = tint
	barrier.Material = Enum.Material.SmoothPlastic
	local nxt = Config.Stages[i + 1]
	local st = Config.Stages[i]
	local title = nxt and ("NEXT: STAGE " .. (i + 1) .. " · " .. string.upper(nxt.Name)) or "FINAL STAGE"
	local info = (nxt and ("Recommended " .. Config.Format(nxt.Recommended) .. " Hand Signs   ·   ") or "") .. "Clear reward +" .. Config.Format(st.Trophies * 10) .. " 🏆"
	for side, gname in {[-1] = "FrontGui", [1] = "BackGui"} do
		local plate = P({Name = "SignPlate" .. (side < 0 and "Front" or "Back"), Size = Vector3.new(0.5, 11, 36),
			CFrame = CFrame.new(gx + side * 0.9, 25, 0), Color = C(34, 28, 40), CanCollide = false, CastShadow = false, Parent = cur})
		P({Size = Vector3.new(0.7, 11.8, 36.8), CFrame = plate.CFrame * CFrame.new(-side * 0.2, 0, 0), Color = beam, CanCollide = false, Parent = cur})
		for _, cz in {-13, 13} do
			P({Size = Vector3.new(0.4, 13, 0.4), CFrame = CFrame.new(gx + side * 0.9, 37, cz), Color = C(60, 54, 62), CanCollide = false, Parent = cur})
		end
		local g = barrier:FindFirstChild(gname) :: SurfaceGui?
		if g then
			g.Adornee = plate
			g.Face = side < 0 and Enum.NormalId.Left or Enum.NormalId.Right
			g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			g.PixelsPerStud = 24
			g.LightInfluence = 0
			for _, c in g:GetChildren() do c:Destroy() end
			local f = Instance.new("Frame")
			f.Name = "Frame"
			f.BackgroundTransparency = 1
			f.Size = UDim2.fromScale(1, 1)
			f.Parent = g
			label(f, title, 0.06, 0.24, C(255, 214, 90), 3, "StageNum")
			label(f, "5 LEFT", 0.33, 0.36, Color3.new(1, 1, 1), 4, "Left")
			label(f, info, 0.74, 0.18, C(200, 235, 255), 2, "Info")
		end
	end
end

local function recolorStage(stage: Model, ledge: Color3, cliff: Color3, wall: Color3, wallCap: Color3, path: Color3?)
	for _, p in stage.Cliffs:GetChildren() do
		if p:IsA("BasePart") then
			if p.Name == "Ledge" then p.Color = ledge
			elseif p.Name == "Cliff" then p.Color = cliff
			elseif p.Size.X >= 160 and p.Size.Y >= 6 then p.Color = wall; p.Material = Enum.Material.WoodPlanks
			elseif p.Size.X >= 160 and p.Size.Z >= 3 then p.Color = wallCap end
		end
	end
	if path then
		for _, p in stage.Floor:GetChildren() do
			if p:IsA("BasePart") and p.Name == "Part" and p.Size.Y < 1 and p.Size.Z >= 20 then p.Color = path end
		end
	end
end

---------------------------------------------------------------- Stage 1: Leaf Grove — starter village
local function stage1(stage: Model)
	restyleGate(stage, 1, C(198, 62, 46), C(44, 36, 40), C(140, 220, 120))
	recolorStage(stage, C(108, 196, 84), C(84, 150, 66), C(124, 84, 54), C(70, 48, 34), C(214, 180, 128))
	-- landmark: the Great Leaf Tree with a lookout deck (north terraces)
	local tx, tz = -38, -68
	local y = ground(tx, tz)
	B(Vector3.new(8, 40, 8), tx, tz, y - 2, C(112, 74, 46), {Name = "GreatTreeTrunk"})
	for _, o in {{5, 0}, {-5, 0}, {0, 5}, {0, -5}} do B(Vector3.new(4, 6, 4), tx + o[1], tz + o[2], y - 1, C(96, 62, 40)) end
	B(Vector3.new(16, 1, 16), tx, tz, y + 16, C(150, 104, 62), {Name = "LookoutDeck"})
	for _, o in {{-7.5, -7.5}, {-7.5, 7.5}, {7.5, -7.5}, {7.5, 7.5}} do B(Vector3.new(0.8, 3, 0.8), tx + o[1], tz + o[2], y + 17, C(96, 62, 40)) end
	local greens = {C(70, 168, 70), C(96, 196, 84), C(58, 148, 64)}
	B(Vector3.new(38, 9, 32), tx, tz, y + 30, greens[1])
	B(Vector3.new(28, 8, 26), tx + 4, tz + 2, y + 38, greens[2])
	B(Vector3.new(20, 7, 18), tx - 3, tz - 1, y + 45, greens[3])
	B(Vector3.new(11, 5, 11), tx + 1, tz + 1, y + 51, greens[2])
	B(Vector3.new(14, 6, 12), tx - 16, tz + 6, y + 27, greens[2])
	B(Vector3.new(12, 6, 12), tx + 17, tz - 4, y + 28, greens[3])
	-- leaf-village huts (south terraces)
	for _, h in {{18, 66}, {50, 64}} do
		local hx, hz = h[1], h[2]
		local hy = ground(hx, hz)
		B(Vector3.new(14, 8, 10), hx, hz, hy, C(240, 226, 196))
		B(Vector3.new(15, 1, 11), hx, hz, hy + 8, C(110, 74, 48))
		B(Vector3.new(16, 2, 12), hx, hz, hy + 9, C(206, 96, 60))
		B(Vector3.new(12, 2, 9), hx, hz, hy + 11, C(190, 82, 50))
		B(Vector3.new(7, 1.5, 5), hx, hz, hy + 13, C(170, 70, 44))
		B(Vector3.new(3, 5, 0.4), hx, hz - 5.1, hy, C(60, 40, 30))
		local leaf = P({Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 3, 3), CFrame = CFrame.new(X0 + hx, hy + 6.5, hz - 5.2) * CFrame.Angles(0, math.rad(90), 0), Color = C(110, 210, 90)})
		leaf.Name = "LeafCrest"
	end
	-- training posts near spawn and a stream with a plank bridge across the field
	for _, pz in {-20, 20} do
		local px = -60
		B(Vector3.new(1.4, 6, 1.4), px, pz, 0, C(150, 104, 62))
		B(Vector3.new(2.6, 2.6, 2.6), px, pz, 6, C(226, 196, 126))
	end
	B(Vector3.new(7, 0.15, 94), -36, 0, 0.02, C(96, 186, 255), {Material = Enum.Material.Glass, Transparency = 0.2, CanCollide = false, Name = "Stream"})
	B(Vector3.new(9, 0.5, 20), -36, 0, 0.27, C(150, 104, 62), {Material = Enum.Material.WoodPlanks, Name = "PlankBridge"})
	-- bigger, friendlier pines
	for _, m in stage.Decor:GetChildren() do
		if m:IsA("Model") and m.Name == "pine" then
			if m:GetAttribute("PilotOrigScale") == nil then m:SetAttribute("PilotOrigScale", m:GetScale()) end
			m:ScaleTo((m:GetAttribute("PilotOrigScale") :: number) * 1.5)
		end
	end
	tree(-70, 40, 1.2, C(96, 62, 40), {C(80, 180, 80), C(110, 205, 90)})
	tree(70, -40, 1.1, C(96, 62, 40), {C(80, 180, 80), C(110, 205, 90)})
end

---------------------------------------------------------------- Stage 2: Cherry Blossom Hill — pastel garden
local function stage2(stage: Model)
	restyleGate(stage, 2, C(120, 64, 84), C(255, 196, 214), C(255, 210, 226))
	recolorStage(stage, C(244, 206, 224), C(178, 158, 170), C(132, 86, 96), C(80, 52, 62), C(246, 226, 230))
	local pinks = {C(255, 186, 214), C(255, 210, 228), C(248, 160, 196)}
	-- landmark: ancient giant sakura (south)
	local tx, tz = -40, 68
	local y = ground(tx, tz)
	B(Vector3.new(7, 22, 7), tx, tz, y - 1, C(128, 84, 78), {Name = "SakuraTrunk"})
	P({Size = Vector3.new(5, 16, 5), CFrame = CFrame.new(X0 + tx + 4, y + 26, tz - 2) * CFrame.Angles(0, 0, math.rad(-28)), Color = C(128, 84, 78)})
	P({Size = Vector3.new(4.5, 14, 4.5), CFrame = CFrame.new(X0 + tx - 4, y + 25, tz + 1) * CFrame.Angles(math.rad(10), 0, math.rad(30)), Color = C(128, 84, 78)})
	for _, c in {{0, 0, 30, 40, 10, 30}, {9, -4, 36, 26, 8, 22}, {-11, 3, 35, 24, 8, 20}, {2, 2, 41, 22, 7, 18}, {-3, -6, 46, 14, 5, 12}, {14, 5, 30, 14, 6, 12}} do
		B(Vector3.new(c[4], c[5], c[6]), tx + c[1], tz + c[2], y + c[3], pinks[(c[3] % 3) + 1])
	end
	-- three-tier pagoda (north)
	local px, pz = 38, -68
	local py = ground(px, pz)
	B(Vector3.new(18, 2, 18), px, pz, py, C(176, 160, 170))
	local tiers = {{14, 7}, {11, 6}, {8, 5}}
	local yy = py + 2
	for k, t in tiers do
		B(Vector3.new(t[1], t[2], t[1]), px, pz, yy, C(244, 236, 226))
		for _, o in {{-1, -1}, {-1, 1}, {1, -1}, {1, 1}} do B(Vector3.new(1, t[2], 1), px + o[1] * (t[1] / 2 - 0.4), pz + o[2] * (t[1] / 2 - 0.4), yy, C(190, 60, 70)) end
		B(Vector3.new(t[1] + 7 - k, 1.4, t[1] + 7 - k), px, pz, yy + t[2], C(60, 70, 92))
		B(Vector3.new(t[1] + 3 - k, 1.2, t[1] + 3 - k), px, pz, yy + t[2] + 1.4, C(76, 88, 112))
		yy += t[2] + 2.6
	end
	B(Vector3.new(1, 6, 1), px, pz, yy, C(255, 204, 64), {Name = "PagodaFinial"})
	-- koi pond with an arched red bridge (non-colliding water) on the north edge of the field
	local qx, qz = -6, -36
	B(Vector3.new(30, 0.5, 14), qx, qz, 0.0, C(176, 160, 170), {CanCollide = false})
	B(Vector3.new(27, 0.55, 11), qx, qz, 0.02, C(110, 196, 255), {Material = Enum.Material.Glass, Transparency = 0.15, CanCollide = false, Name = "KoiPond"})
	for k, f in {{-6, -2, C(255, 140, 60)}, {3, 2, Color3.new(1, 1, 1)}, {8, -1, C(255, 110, 60)}} do
		B(Vector3.new(1.6, 0.3, 0.7), qx + f[1], qz + f[2], 0.3, f[3], {CanCollide = false, Name = "Koi" .. k})
	end
	for k = -3, 3 do
		B(Vector3.new(2, 0.6, 5), qx + k * 2, qz, 0.6 + (9 - k * k) * 0.25, C(206, 64, 56), {CanCollide = false})
	end
	-- petals scattered on the field, blossoms recoloured from neon to pastel
	local rng = Random.new(2)
	for _ = 1, 36 do
		local x, z = rng:NextNumber(-80, 80), rng:NextNumber(-46, 46)
		P({Size = Vector3.new(0.9, 0.08, 0.9), CFrame = CFrame.new(X0 + x, 0.32, z) * CFrame.Angles(0, rng:NextNumber() * 3, 0), Color = pinks[rng:NextInteger(1, 3)], CanCollide = false, CastShadow = false, CanQuery = false})
	end
	for _, m in stage.Decor:GetChildren() do
		if m:IsA("Model") and (m.Name == "blossom" or m.Name == "pine") then
			for _, p in m:GetDescendants() do
				if p:IsA("BasePart") and p.Color.R > 0.7 and p.Color.B > 0.4 and p.Color.G < 0.6 then p.Color = pinks[1]; p.Material = Enum.Material.SmoothPlastic end
			end
		end
	end
	tree(70, 40, 1.15, C(128, 84, 78), {pinks[1], pinks[2]})
	tree(-70, -40, 1.1, C(128, 84, 78), {pinks[3], pinks[1]})
	tree(60, -42, 0.95, C(128, 84, 78), {pinks[2], pinks[1]})
end

---------------------------------------------------------------- Stage 3: Sand Dunes — desert ruins
local function stage3(stage: Model)
	restyleGate(stage, 3, C(206, 168, 112), C(120, 84, 52), C(255, 214, 150))
	recolorStage(stage, C(236, 206, 146), C(206, 160, 104), C(176, 128, 82), C(120, 84, 52), C(240, 222, 182))
	local sand, sand2, stone = C(232, 202, 142), C(216, 182, 120), C(214, 178, 124)
	-- landmark: broken sandstone arch (north)
	local ax, az = -40, -68
	local y = ground(ax, az)
	for _, oz in {-11, 11} do
		B(Vector3.new(7, 4, 7), ax, az + oz, y - 1, C(190, 152, 100))
		B(Vector3.new(5.5, 26, 5.5), ax, az + oz, y + 3, stone)
	end
	B(Vector3.new(7, 5, 15), ax, az - 5, y + 29, stone)
	P({Size = Vector3.new(7, 5, 13), CFrame = CFrame.new(X0 + ax, y + 32.5, az + 8) * CFrame.Angles(math.rad(14), 0, 0), Color = C(204, 166, 112)})
	for k = 1, 5 do
		local r = Random.new(30 + k)
		P({Size = Vector3.new(3, 2.5, 3) * (0.7 + r:NextNumber()), CFrame = CFrame.new(X0 + ax + r:NextNumber(-8, 8), y + 1, az + r:NextNumber(-14, 14)) * CFrame.Angles(0, r:NextNumber() * 3, r:NextNumber() * 0.5), Color = stone})
	end
	-- stepped pyramid (south)
	local px, pz = 40, 70
	local py = ground(px, pz)
	for k, w in {30, 24, 18, 12, 6} do
		B(Vector3.new(w, 4, w), px, pz, py + (k - 1) * 4, k % 2 == 0 and C(222, 188, 128) or C(210, 174, 116))
	end
	B(Vector3.new(3, 3, 3), px, pz, py + 20, C(255, 204, 64), {Material = Enum.Material.Neon, Name = "PyramidCapstone"})
	-- dunes ring the course (outside the play boundary) to give the desert a horizon
	for _, d in {{-55, -96}, {0, -104}, {55, -94}, {-50, 96}, {10, 104}, {62, 94}} do
		blob(Vector3.new(80, 14, 40), d[1], d[2] * 1.12, -5, d[1] % 2 == 0 and sand or sand2, {CanCollide = false})
	end
	-- proper cacti replace the bamboo-like props; small oasis near spawn
	for _, m in stage.Decor:GetChildren() do
		if m:IsA("Model") and m.Name == "cactus" then stash(m, m:GetFullName()) end
	end
	local green, green2 = C(76, 156, 80), C(96, 180, 92)
	for _, c in {{-20, 44}, {25, -44}, {60, 42}, {-62, -44}, {-5, -46}, {70, -30}} do
		local cx, cz = c[1], c[2]
		local cy = ground(cx, cz)
		B(Vector3.new(2.6, 9, 2.6), cx, cz, cy, green)
		B(Vector3.new(3.4, 1.4, 1.6), cx + 2.2, cz, cy + 4, green2)
		B(Vector3.new(1.6, 3.5, 1.6), cx + 3.4, cz, cy + 4.6, green2)
		B(Vector3.new(3, 1.4, 1.6), cx - 2, cz, cy + 5.5, green2)
		B(Vector3.new(1.6, 3, 1.6), cx - 3, cz, cy + 6, green2)
	end
	local ox, oz = -66, -32
	B(Vector3.new(16, 0.5, 12), ox, oz, 0.0, C(196, 160, 104), {CanCollide = false})
	B(Vector3.new(13, 0.55, 9), ox, oz, 0.02, C(70, 190, 210), {Material = Enum.Material.Glass, Transparency = 0.15, CanCollide = false, Name = "Oasis"})
	for k, pl in {{-72, -39}, {-60, -39}} do
		local bx, bz = pl[1], pl[2]
		local dir = k == 1 and -1 or 1
		for s = 0, 5 do
			P({Size = Vector3.new(2.2, 3.4, 2.2), CFrame = CFrame.new(X0 + bx + s * 0.55 * dir, 1.7 + s * 3.2, bz), Color = s % 2 == 0 and C(150, 108, 66) or C(128, 90, 54)})
		end
		local top = Vector3.new(X0 + bx + 3 * dir, 20.5, bz)
		P({Shape = Enum.PartType.Ball, Size = Vector3.new(2.6, 2.6, 2.6), CFrame = CFrame.new(top), Color = C(120, 84, 52)})
		for f = 0, 6 do
			P({Size = Vector3.new(12, 0.5, 3), CFrame = CFrame.new(top) * CFrame.Angles(0, math.rad(f * 51), math.rad(-24)) * CFrame.new(5.6, 0, 0), Color = f % 2 == 0 and green or green2, CanCollide = false})
		end
	end
end

---------------------------------------------------------------- driver
function SP.Apply(): string
	local course = workspace:WaitForChild("StageCourse")
	local out = {}
	for i, fn in {stage1, stage2, stage3} do
		local stage = course:FindFirstChild(string.format("Stage%02d", i)) :: Model
		local old = stage:FindFirstChild("Pilot")
		if old then old:Destroy() end
		cur = Instance.new("Model")
		cur.Name = "Pilot"
		cur:SetAttribute("Issue", 14)
		cur.Parent = stage
		X0 = (i - 1) * L
		rayParams.FilterDescendantsInstances = {cur, stage.Decor, stage:FindFirstChild("Gate") :: Instance, workspace:FindFirstChild("Lobby") :: Instance}
		local lm = stage.Decor:FindFirstChild("Landmark")
		if lm then stash(lm, lm:GetFullName()) end
		fn(stage)
		local n = 0
		for _, d in cur:GetDescendants() do if d:IsA("BasePart") then n += 1 end end
		table.insert(out, stage.Name .. ": " .. n .. " pilot parts")
		task.wait()
	end
	return table.concat(out, "; ")
end

return SP
