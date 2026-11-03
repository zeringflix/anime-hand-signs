-- Edit-time generator for the 50-stage course (run from the command bar / MCP):
--   require(game.ServerStorage.Tools.WorldBuilder:Clone()).BuildAll()   or  .BuildStage(i)
-- Contract kept for gameplay code: workspace.StageCourse.StageNN with Spawn, EnemySpawns(S1..S4,Boss), TrophyPad(attr Stage),
-- Gate.Barrier(FrontGui/BackGui with "Left" label). Stage i is centred at x = (i-1)*StageLength (85), floor top at y = 0.
-- EnemySpawns: S1..S5 + Boss (EnemyService only spawns the boss on Config.HasBoss stages).
local Config = require(game.ReplicatedStorage.Shared.Config)
local W = {}
local LEN = Config.StageLength
local C = Color3.fromRGB
local STUDS = Enum.SurfaceType.Studs

local function shade(c: Color3, f: number) return Color3.new(math.clamp(c.R * f, 0, 1), math.clamp(c.G * f, 0, 1), math.clamp(c.B * f, 0, 1)) end
local function mix(a: Color3, b: Color3, t: number) return a:Lerp(b, t) end

local function P(parent: Instance, size: Vector3, cf: CFrame, color: Color3, opts: {[string]: any}?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = Enum.Material.Plastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if opts then for k, v in opts do (p :: any)[k] = v end end
	p.Parent = parent
	return p
end
local function deco(parent: Instance, size: Vector3, cf: CFrame, color: Color3, opts: {[string]: any}?): Part
	local p = P(parent, size, cf, color, opts)
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	return p
end
local function neon(parent, size, cf, color, opts)
	local p = deco(parent, size, cf, color, opts)
	p.Material = Enum.Material.Neon
	p.CastShadow = false
	return p
end

---------------------------------------------------------------- props (all built at a ground CFrame `g`, y = ground top)
local Props = {}
local function rng(seed) return Random.new(seed) end

function Props.tree(m, g, st, r, style)
	local leaf, trunk = st.Leaf, st.Trunk
	local h = r:NextNumber(5, 8)
	local tw = style == "bigtree" and 4 or 2
	deco(m, Vector3.new(tw, h, tw), g * CFrame.new(0, h / 2, 0), trunk, {Material = Enum.Material.WoodPlanks})
	if style == "pine" then
		for k = 0, 3 do
			local s = 11 - k * 2.6
			deco(m, Vector3.new(s, 2.6, s), g * CFrame.new(0, h + k * 2.6, 0) * CFrame.Angles(0, k * 0.4, 0), shade(leaf, 1 - k * 0.04), {TopSurface = STUDS})
		end
		deco(m, Vector3.new(1.6, 2, 1.6), g * CFrame.new(0, h + 11.4, 0), leaf, {TopSurface = STUDS})
	else
		local big = style == "bigtree" and 1.8 or 1
		local glow = style == "spirittree"
		for k = 1, 4 do
			local s = Vector3.new(r:NextNumber(6, 9), r:NextNumber(4, 6), r:NextNumber(6, 9)) * big
			local off = Vector3.new(r:NextNumber(-3, 3), r:NextNumber(0, 3), r:NextNumber(-3, 3)) * big
			local p = deco(m, s, g * CFrame.new(off + Vector3.new(0, h + 2 * big, 0)), shade(leaf, r:NextNumber(0.9, 1.08)), {TopSurface = STUDS})
			if glow then p.Material = Enum.Material.Neon; p.Transparency = 0.15 end
		end
		if style == "blossom" then
			for k = 1, 3 do
				deco(m, Vector3.new(1, 1, 1), g * CFrame.new(r:NextNumber(-6, 6), 0.5, r:NextNumber(-6, 6)) * CFrame.Angles(0, r:NextNumber(0, 3), 0), shade(leaf, 1.05))
			end
		end
	end
end

function Props.bamboo(m, g, st, r)
	for k = 1, r:NextInteger(4, 7) do
		local h = r:NextNumber(14, 26)
		local x, z = r:NextNumber(-4, 4), r:NextNumber(-4, 4)
		local stalk = shade(st.Trunk, r:NextNumber(0.9, 1.15))
		local segs = math.floor(h / 4)
		for s = 0, segs - 1 do
			deco(m, Vector3.new(1, 3.7, 1), g * CFrame.new(x, s * 4 + 1.9, z), stalk)
			deco(m, Vector3.new(1.3, 0.3, 1.3), g * CFrame.new(x, s * 4 + 3.85, z), shade(stalk, 0.75))
		end
		deco(m, Vector3.new(3.5, 0.4, 1.2), g * CFrame.new(x + 1.2, segs * 4, z) * CFrame.Angles(0, r:NextNumber(0, 3), 0.4), st.Leaf)
	end
end

function Props.reed(m, g, st, r)
	deco(m, Vector3.new(10, 0.4, 8), g * CFrame.new(0, 0.2, 0), C(80, 140, 170), {Material = Enum.Material.Glass, Transparency = 0.25})
	for k = 1, 7 do
		local h = r:NextNumber(4, 8)
		deco(m, Vector3.new(0.5, h, 0.5), g * CFrame.new(r:NextNumber(-5, 5), h / 2, r:NextNumber(-4, 4)) * CFrame.Angles(r:NextNumber(-0.2, 0.2), 0, r:NextNumber(-0.2, 0.2)), st.Leaf)
	end
end

function Props.rock(m, g, st, r, style)
	local base = style == "moonrock" and C(70, 70, 100) or mix(st.Cliff, C(135, 135, 140), 0.6)
	for k = 1, 3 do
		local s = Vector3.new(r:NextNumber(4, 9), r:NextNumber(3, 7), r:NextNumber(4, 9)) * (k == 1 and 1.3 or 0.8)
		local p = deco(m, s, g * CFrame.new(r:NextNumber(-3, 3), s.Y / 2, r:NextNumber(-3, 3)) * CFrame.Angles(0, r:NextNumber(0, 3), r:NextNumber(-0.15, 0.15)), shade(base, r:NextNumber(0.85, 1.1)), {Material = Enum.Material.Slate})
		if style == "lavarock" then neon(m, Vector3.new(s.X + 0.2, 0.4, 0.6), p.CFrame * CFrame.new(0, 0, 0) * CFrame.Angles(0, 0.4, 0), C(255, 110, 20)) end
		if style == "moonrock" then neon(m, Vector3.new(0.6, s.Y * 0.8, 0.6), p.CFrame * CFrame.new(s.X / 2, 0, 0), C(220, 40, 60)) end
	end
end

function Props.spike(m, g, st, r, style)
	local col = style == "crystal" and st.Leaf or C(190, 230, 255)
	for k = 1, r:NextInteger(3, 5) do
		local h = r:NextNumber(6, 16)
		local w = r:NextNumber(1.8, 3.2)
		local p = deco(m, Vector3.new(w, h, w), g * CFrame.new(r:NextNumber(-3, 3), h / 2 - 0.5, r:NextNumber(-3, 3)) * CFrame.Angles(r:NextNumber(-0.3, 0.3), r:NextNumber(0, 3), r:NextNumber(-0.3, 0.3)), col,
			{Material = style == "crystal" and Enum.Material.Neon or Enum.Material.Ice, Transparency = style == "crystal" and 0.2 or 0.1})
		p.CastShadow = false
	end
end

function Props.rod(m, g, st, r)
	local h = r:NextNumber(14, 20)
	deco(m, Vector3.new(4, 2, 4), g * CFrame.new(0, 1, 0), st.Cliff, {Material = Enum.Material.Slate})
	deco(m, Vector3.new(1, h, 1), g * CFrame.new(0, h / 2 + 2, 0), C(90, 95, 110), {Material = Enum.Material.Metal})
	neon(m, Vector3.new(1.6, 1.6, 1.6), g * CFrame.new(0, h + 2.5, 0) * CFrame.Angles(0.6, 0.6, 0), C(255, 240, 90))
	local l = Instance.new("PointLight"); l.Color = C(255, 240, 120); l.Range = 14; l.Parent = m:GetChildren()[#m:GetChildren()]
end

function Props.pillar(m, g, st, r, style)
	local gold = style == "goldpillar"
	local col = gold and C(255, 210, 80) or st.Path
	local h = r:NextNumber(10, 18)
	deco(m, Vector3.new(5, 1.5, 5), g * CFrame.new(0, 0.75, 0), shade(col, 0.85), {TopSurface = STUDS})
	deco(m, Vector3.new(3.4, h, 3.4), g * CFrame.new(0, h / 2 + 1.5, 0), col, {Material = gold and Enum.Material.Foil or Enum.Material.Plastic})
	if r:NextNumber() > 0.4 then
		deco(m, Vector3.new(5, 1.5, 5), g * CFrame.new(0, h + 2.25, 0), shade(col, 0.85), {TopSurface = STUDS})
	else
		deco(m, Vector3.new(3.4, 4, 3.4), g * CFrame.new(2.5, 1.5, 3) * CFrame.Angles(0, 0.5, math.pi / 2), col)
	end
	if gold then neon(m, Vector3.new(2, 2, 2), g * CFrame.new(0, h + 4, 0) * CFrame.Angles(0.7, 0.7, 0), C(255, 250, 200)) end
end

function Props.mushroom(m, g, st, r, style)
	for k = 1, r:NextInteger(2, 4) do
		local h = r:NextNumber(3, 8)
		local x, z = r:NextNumber(-4, 4), r:NextNumber(-4, 4)
		deco(m, Vector3.new(1.4, h, 1.4), g * CFrame.new(x, h / 2, z), C(235, 225, 200))
		local cap = deco(m, Vector3.new(h * 0.9 + 2, 1.6, h * 0.9 + 2), g * CFrame.new(x, h + 0.6, z), style == "coral" and shade(st.Leaf, r:NextNumber(0.8, 1.2)) or st.Leaf, {TopSurface = STUDS})
		if style ~= "coral" then cap.Material = Enum.Material.Neon; cap.Transparency = 0.1 end
	end
end

function Props.grave(m, g, st, r)
	for k = 1, 3 do
		local x, z = (k - 2) * 4, r:NextNumber(-2, 2)
		deco(m, Vector3.new(2.6, 4, 0.8), g * CFrame.new(x, 2, z) * CFrame.Angles(r:NextNumber(-0.15, 0.15), 0, r:NextNumber(-0.1, 0.1)), C(150, 150, 160), {Material = Enum.Material.Slate})
		deco(m, Vector3.new(2.6, 0.3, 4), g * CFrame.new(x, 0.15, z + 2.4), shade(st.Ground, 0.7))
	end
	local w = neon(m, Vector3.new(1.5, 1.5, 1.5), g * CFrame.new(0, 7, 0), C(180, 140, 255), {Shape = Enum.PartType.Ball, Transparency = 0.3})
	local l = Instance.new("PointLight"); l.Color = C(180, 140, 255); l.Range = 12; l.Parent = w
end

function Props.torii(m, g, st, r)
	local c = st.Gate
	for _, s in {-1, 1} do deco(m, Vector3.new(1.6, 12, 1.6), g * CFrame.new(s * 5, 6, 0), c) end
	deco(m, Vector3.new(15, 1.4, 2.2), g * CFrame.new(0, 12.6, 0), C(35, 30, 35), {TopSurface = STUDS})
	deco(m, Vector3.new(12, 1, 1.4), g * CFrame.new(0, 10, 0), c)
end

function Props.house(m, g, st, r, style)
	local ruined = style == "ruinhouse"
	local wallC = ruined and C(150, 135, 115) or C(235, 225, 205)
	local roofC = style == "dojo" and C(70, 50, 40) or (ruined and C(90, 80, 70) or shade(st.Gate, 0.75))
	local w, d, h = r:NextNumber(12, 16), r:NextNumber(10, 13), 8
	deco(m, Vector3.new(w + 2, 1.5, d + 2), g * CFrame.new(0, 0.75, 0), C(120, 110, 100), {TopSurface = STUDS})
	deco(m, Vector3.new(w, h, d), g * CFrame.new(0, 1.5 + h / 2, 0), wallC)
	for _, x in {-w / 2, w / 2} do deco(m, Vector3.new(1.2, h, 1.2), g * CFrame.new(x, 1.5 + h / 2, -d / 2), st.Trunk) end
	deco(m, Vector3.new(3, 5, 0.4), g * CFrame.new(0, 4, -d / 2 - 0.1), C(60, 45, 35))
	if not ruined then
		deco(m, Vector3.new(w + 5, 1.4, d + 5), g * CFrame.new(0, 1.5 + h + 0.7, 0), roofC, {TopSurface = STUDS})
		deco(m, Vector3.new(w + 1, 2.4, d - 2), g * CFrame.new(0, 1.5 + h + 2.6, 0), roofC, {TopSurface = STUDS})
		deco(m, Vector3.new(w - 3, 1.2, d - 6), g * CFrame.new(0, 1.5 + h + 4.4, 0), shade(roofC, 0.8))
	else
		deco(m, Vector3.new(w * 0.6, 1.2, d + 3), g * CFrame.new(-w * 0.2, 1.5 + h + 0.6, 0) * CFrame.Angles(0, 0, 0.25), roofC)
	end
end

function Props.temple(m, g, st, r)
	local roofC = shade(st.Gate, 0.8)
	local y = 0
	for k = 0, 2 do
		local s = 14 - k * 3.5
		deco(m, Vector3.new(s, 5, s), g * CFrame.new(0, y + 2.5, 0), k == 0 and C(240, 230, 210) or C(230, 215, 190))
		deco(m, Vector3.new(s + 4, 1.2, s + 4), g * CFrame.new(0, y + 5.6, 0), roofC, {TopSurface = STUDS})
		y += 6.2
	end
	deco(m, Vector3.new(0.8, 5, 0.8), g * CFrame.new(0, y + 2.5, 0), C(255, 210, 80), {Material = Enum.Material.Foil})
end

function Props.wall(m, g, st, r, style)
	local c = style == "castle" and C(215, 210, 200) or C(140, 145, 150)
	local h = style == "castle" and 18 or 12
	deco(m, Vector3.new(7, h, 7), g * CFrame.new(0, h / 2, 0), c, {Material = Enum.Material.Cobblestone})
	for _, o in {Vector3.new(-2.5, 0, -2.5), Vector3.new(2.5, 0, -2.5), Vector3.new(-2.5, 0, 2.5), Vector3.new(2.5, 0, 2.5)} do
		deco(m, Vector3.new(2, 2, 2), g * CFrame.new(o + Vector3.new(0, h + 1, 0)), c, {TopSurface = STUDS})
	end
	if style == "castle" then
		deco(m, Vector3.new(10, 1.4, 10), g * CFrame.new(0, h + 2.7, 0), shade(st.Gate, 0.8), {TopSurface = STUDS})
		deco(m, Vector3.new(6, 3, 6), g * CFrame.new(0, h + 4.5, 0), C(240, 235, 225))
		deco(m, Vector3.new(8.5, 1.2, 8.5), g * CFrame.new(0, h + 6.6, 0), shade(st.Gate, 0.8), {TopSurface = STUDS})
	end
end

function Props.banner(m, g, st, r)
	deco(m, Vector3.new(0.8, 14, 0.8), g * CFrame.new(0, 7, 0), C(60, 45, 35))
	deco(m, Vector3.new(0.2, 9, 4), g * CFrame.new(0, 9, 2.4), st.Gate, {Material = Enum.Material.Fabric})
	deco(m, Vector3.new(0.25, 2, 2), g * CFrame.new(0, 10.5, 2.4) * CFrame.Angles(math.pi / 4, 0, 0), Color3.new(1, 1, 1))
end

function Props.windmill(m, g, st, r)
	deco(m, Vector3.new(5, 16, 5), g * CFrame.new(0, 8, 0), C(235, 225, 205))
	deco(m, Vector3.new(6, 3, 6), g * CFrame.new(0, 17.5, 0), shade(st.Gate, 0.8), {TopSurface = STUDS})
	for k = 0, 3 do deco(m, Vector3.new(1, 14, 0.3), g * CFrame.new(0, 14, -3) * CFrame.Angles(0, 0, k * math.pi / 2 + 0.3) * CFrame.new(0, 6, 0), C(250, 250, 250)) end
end

function Props.statue(m, g, st, r, style)
	local c = C(150, 150, 140)
	deco(m, Vector3.new(9, 3, 9), g * CFrame.new(0, 1.5, 0), shade(st.Cliff, 0.9), {TopSurface = STUDS, Material = Enum.Material.Slate})
	if style == "toadstatue" then
		deco(m, Vector3.new(8, 6, 7), g * CFrame.new(0, 6, 0), c, {Material = Enum.Material.Slate})
		for _, s in {-1, 1} do
			deco(m, Vector3.new(2.5, 2.5, 2.5), g * CFrame.new(s * 2.4, 9.8, -2), c, {Shape = Enum.PartType.Ball, Material = Enum.Material.Slate})
			neon(m, Vector3.new(1, 1, 0.4), g * CFrame.new(s * 2.4, 9.9, -3.2), C(255, 200, 60))
		end
	else
		local y = 3
		for k = 0, 5 do
			deco(m, Vector3.new(3.2 - k * 0.2, 3.2, 3.2 - k * 0.2), g * CFrame.new(math.sin(k * 1.2) * 2, y + 1.6, 0), c, {Material = Enum.Material.Slate})
			y += 2.6
		end
		deco(m, Vector3.new(4, 3, 5), g * CFrame.new(math.sin(6 * 1.2) * 2, y + 1.5, -1), c, {Material = Enum.Material.Slate})
		neon(m, Vector3.new(0.6, 0.6, 0.3), g * CFrame.new(math.sin(6 * 1.2) * 2 + 1, y + 2, -3.6), C(255, 230, 60))
	end
end

function Props.tank(m, g, st, r)
	deco(m, Vector3.new(6, 1.5, 6), g * CFrame.new(0, 0.75, 0), C(90, 95, 105), {Material = Enum.Material.DiamondPlate})
	neon(m, Vector3.new(4.4, 8, 4.4), g * CFrame.new(0, 5.5, 0), st.Leaf, {Transparency = 0.45, Shape = Enum.PartType.Cylinder, CFrame = g * CFrame.new(0, 5.5, 0) * CFrame.Angles(0, 0, math.pi / 2), Size = Vector3.new(8, 4.4, 4.4)})
	deco(m, Vector3.new(6, 1.5, 6), g * CFrame.new(0, 10.2, 0), C(90, 95, 105), {Material = Enum.Material.DiamondPlate})
end

function Props.scroll(m, g, st, r)
	deco(m, Vector3.new(2, 2, 12), g * CFrame.new(0, 1, 0) * CFrame.Angles(0, r:NextNumber(0, 3), 0), C(240, 225, 190), {Shape = Enum.PartType.Cylinder, Size = Vector3.new(12, 2, 2)})
	deco(m, Vector3.new(8, 0.2, 10), g * CFrame.new(0, 0.1, 6), C(245, 235, 205))
	neon(m, Vector3.new(4, 0.25, 4), g * CFrame.new(0, 0.2, 6) * CFrame.Angles(0, 0.78, 0), C(255, 120, 40))
end

function Props.cloudpuff(m, g, st, r)
	for k = 1, 4 do
		deco(m, Vector3.new(r:NextNumber(5, 9), r:NextNumber(3, 5), r:NextNumber(5, 9)), g * CFrame.new(r:NextNumber(-4, 4), r:NextNumber(8, 12), r:NextNumber(-4, 4)), Color3.new(1, 1, 1), {TopSurface = STUDS})
	end
	deco(m, Vector3.new(4, 1, 4), g * CFrame.new(0, 0.5, 0), C(230, 235, 255))
end

function Props.floatrock(m, g, st, r)
	local y = r:NextNumber(10, 18)
	deco(m, Vector3.new(9, 3, 9), g * CFrame.new(0, y, 0) * CFrame.Angles(0, r:NextNumber(0, 3), 0), st.Ground, {TopSurface = STUDS})
	deco(m, Vector3.new(6, 4, 6), g * CFrame.new(0, y - 3.4, 0) * CFrame.Angles(0, r:NextNumber(0, 3), 0), st.Cliff, {Material = Enum.Material.Slate})
	deco(m, Vector3.new(3, 3, 3), g * CFrame.new(0, y - 6.6, 0) * CFrame.Angles(0.3, r:NextNumber(0, 3), 0.3), shade(st.Cliff, 0.8), {Material = Enum.Material.Slate})
	if st.Element == "void" then neon(m, Vector3.new(9.2, 0.3, 0.6), g * CFrame.new(0, y - 1, 0), st.Leaf) end
end

function Props.waterfall(m, g, st, r)
	deco(m, Vector3.new(14, 22, 6), g * CFrame.new(0, 11, 2), st.Cliff, {Material = Enum.Material.Slate, TopSurface = STUDS})
	neon(m, Vector3.new(8, 22, 0.6), g * CFrame.new(0, 11, -1.2), C(150, 220, 255), {Transparency = 0.25})
	deco(m, Vector3.new(14, 0.6, 8), g * CFrame.new(0, 0.3, -5), C(90, 180, 230), {Material = Enum.Material.Glass, Transparency = 0.2})
end

function Props.crack(m, g, st, r)
	for k = 1, 3 do
		neon(m, Vector3.new(r:NextNumber(6, 12), 0.25, 0.8), g * CFrame.new(r:NextNumber(-4, 4), 0.15, r:NextNumber(-4, 4)) * CFrame.Angles(0, r:NextNumber(0, 3), 0), st.Leaf)
	end
	Props.spike(m, g * CFrame.new(0, 0, 0), st, r, "crystal")
end

local PROP_MAP = {
	pine = {"tree", "pine"}, blossom = {"tree", "blossom"}, spirittree = {"tree", "spirittree"}, bigtree = {"tree", "bigtree"},
	cactus = {"bamboo"}, bamboo = {"bamboo"}, reed = {"reed"}, rock = {"rock"}, boulder = {"rock"}, lavarock = {"rock", "lavarock"}, moonrock = {"rock", "moonrock"},
	icespike = {"spike"}, crystal = {"spike", "crystal"}, rod = {"rod"}, pillar = {"pillar"}, goldpillar = {"pillar", "goldpillar"},
	mushroom = {"mushroom"}, coral = {"mushroom", "coral"}, grave = {"grave"}, torii = {"torii"},
	house = {"house"}, dojo = {"house", "dojo"}, ruinhouse = {"house", "ruinhouse"}, temple = {"temple"},
	wall = {"wall"}, castle = {"wall", "castle"}, banner = {"banner"}, windmill = {"windmill"},
	snakestatue = {"statue", "snakestatue"}, toadstatue = {"statue", "toadstatue"}, tank = {"tank"}, scroll = {"scroll"},
	cloud = {"rock"}, cloudpuff = {"cloudpuff"}, floatrock = {"floatrock"}, waterfall = {"waterfall"}, crack = {"crack"},
}
-- secondary filler so every stage mixes its signature prop with a matching natural one
local FILLER = {pine = "rock", blossom = "pine", cactus = "rock", rock = "boulder", bamboo = "pine", reed = "pine", boulder = "pine", icespike = "rock",
	rod = "rock", lavarock = "rock", spirittree = "mushroom", pillar = "pine", mushroom = "spirittree", grave = "spirittree", torii = "blossom",
	house = "pine", wall = "pine", dojo = "bamboo", banner = "rock", castle = "pine", temple = "rock", coral = "rock", windmill = "boulder",
	crystal = "rock", scroll = "pine", snakestatue = "pine", toadstatue = "pine", tank = "pillar", bigtree = "pine", ruinhouse = "rock",
	cloud = "pillar", cloudpuff = "pillar", floatrock = "pine", waterfall = "pine", goldpillar = "bigtree", crack = "moonrock", moonrock = "crack"}

local function prop(m, g, st, r, kind)
	local map = PROP_MAP[kind] or {"tree", "pine"}
	Props[map[1]](m, g, st, r, map[2] or kind)
end

---------------------------------------------------------------- landmarks (one hero piece per stage, by region)
local function pagodaTower(m, g, st)
	-- red water-tower style lookout from the reference beginner area (original design: spiral emblem, not a village logo)
	deco(m, Vector3.new(14, 4, 14), g * CFrame.new(0, 2, 0), C(110, 100, 95), {TopSurface = STUDS})
	for _, o in {Vector3.new(-5, 0, -5), Vector3.new(5, 0, -5), Vector3.new(-5, 0, 5), Vector3.new(5, 0, 5)} do
		deco(m, Vector3.new(1.5, 14, 1.5), g * CFrame.new(o + Vector3.new(0, 11, 0)), C(80, 60, 50))
	end
	local body = deco(m, Vector3.new(13, 10, 13), g * CFrame.new(0, 23, 0), st.Gate, {Shape = Enum.PartType.Cylinder, CFrame = g * CFrame.new(0, 23, 0) * CFrame.Angles(0, 0, math.pi / 2), Size = Vector3.new(10, 14, 14)})
	deco(m, Vector3.new(4, 16.5, 16.5), g * CFrame.new(0, 29.5, 0) * CFrame.Angles(0, 0, math.pi / 2), shade(st.Gate, 0.7), {Shape = Enum.PartType.Cylinder})
	deco(m, Vector3.new(3, 10, 10), g * CFrame.new(0, 33, 0) * CFrame.Angles(0, 0, math.pi / 2), shade(st.Gate, 0.7), {Shape = Enum.PartType.Cylinder})
	local emblem = deco(m, Vector3.new(0.4, 6, 6), g * CFrame.new(0, 23, -7.1) * CFrame.Angles(0, math.pi / 2, 0), Color3.new(1, 1, 1), {Shape = Enum.PartType.Cylinder})
	deco(m, Vector3.new(0.5, 3.6, 3.6), emblem.CFrame * CFrame.new(-0.1, 0, 0), st.Gate, {Shape = Enum.PartType.Cylinder})
	deco(m, Vector3.new(0.6, 1.4, 1.4), emblem.CFrame * CFrame.new(-0.2, 0, 0), Color3.new(1, 1, 1), {Shape = Enum.PartType.Cylinder})
	for _, s in {-1, 1} do neon(m, Vector3.new(1.4, 1.8, 0.4), g * CFrame.new(s * 3.2, 25.5, -7), C(255, 240, 160)) end
end
local function obelisk(m, g, st)
	deco(m, Vector3.new(12, 3, 12), g * CFrame.new(0, 1.5, 0), shade(st.Cliff, 0.9), {TopSurface = STUDS, Material = Enum.Material.Slate})
	deco(m, Vector3.new(6, 26, 6), g * CFrame.new(0, 16, 0), shade(st.Cliff, 1.1), {Material = Enum.Material.Slate})
	neon(m, Vector3.new(6.3, 2, 6.3), g * CFrame.new(0, 22, 0), st.Gate)
	local orb = neon(m, Vector3.new(5, 5, 5), g * CFrame.new(0, 33, 0), st.Leaf, {Shape = Enum.PartType.Ball})
	local l = Instance.new("PointLight"); l.Color = st.Leaf; l.Range = 30; l.Brightness = 2; l.Parent = orb
end
local function bigTorii(m, g, st)
	for _, s in {-1, 1} do deco(m, Vector3.new(3, 26, 3), g * CFrame.new(s * 10, 13, 0), st.Gate) end
	deco(m, Vector3.new(30, 2.6, 4), g * CFrame.new(0, 27, 0), C(35, 30, 35), {TopSurface = STUDS})
	deco(m, Vector3.new(25, 1.8, 2.4), g * CFrame.new(0, 22, 0), st.Gate)
	deco(m, Vector3.new(4, 5, 0.6), g * CFrame.new(0, 24.4, -0.8), C(35, 30, 35))
end
local function floatingTemple(m, g, st)
	local y = 18
	deco(m, Vector3.new(20, 4, 20), g * CFrame.new(0, y, 0), st.Ground, {TopSurface = STUDS})
	deco(m, Vector3.new(12, 6, 12), g * CFrame.new(0, y - 5, 0), st.Cliff, {Material = Enum.Material.Slate})
	deco(m, Vector3.new(6, 6, 6), g * CFrame.new(0, y - 10, 0) * CFrame.Angles(0.3, 0.5, 0.2), shade(st.Cliff, 0.8), {Material = Enum.Material.Slate})
	Props.temple(m, g * CFrame.new(0, y + 2, 0), st, Random.new(1))
end

local LANDMARK = {pagodaTower, obelisk, bigTorii, function(m, g, st) Props.wall(m, g, st, Random.new(2), "castle") end, obelisk,
	function(m, g, st) Props.statue(m, g, st, Random.new(3), st.Index == 27 and "snakestatue" or "toadstatue") end, bigTorii, floatingTemple, obelisk, floatingTemple}

---------------------------------------------------------------- gate (torii frame + tinted barrier with per-player text)
local function gateText(parent: Instance, face: Enum.NormalId, nextSt, recommended: string, trophies: string)
	local sg = Instance.new("SurfaceGui")
	sg.Name = face == Enum.NormalId.Left and "FrontGui" or "BackGui"
	sg.Face = face
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 20
	sg.LightInfluence = 0
	sg.Parent = parent
	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.46)
	holder.Size = UDim2.fromScale(0.96, 0.8)
	holder.Rotation = -6
	holder.Parent = sg
	local function line(name, text, y, h, color)
		local t = Instance.new("TextLabel")
		t.Name = name
		t.BackgroundTransparency = 1
		t.Font = Enum.Font.FredokaOne
		t.TextScaled = true
		t.Text = text
		t.TextColor3 = color
		t.Position = UDim2.fromScale(0, y)
		t.Size = UDim2.fromScale(1, h)
		local s = Instance.new("UIStroke"); s.Thickness = 5; s.Color = C(25, 20, 35); s.Parent = t
		t.Parent = holder
		return t
	end
	line("Left", "5 LEFT", 0, 0.2, Color3.new(1, 1, 1))
	line("StageNum", "STAGE " .. nextSt.Index, 0.22, 0.26, Color3.new(1, 1, 1))
	line("StageName", string.upper(nextSt.Name), 0.5, 0.14, C(255, 240, 250))
	line("Recommended", "RECOMMENDED HAND SIGNS " .. recommended, 0.66, 0.15, C(120, 230, 255))
	line("Reward", "+" .. trophies .. " TROPHIES", 0.83, 0.15, C(255, 220, 60))
end

local function buildGate(stage: Model, st, O: CFrame)
	local nextSt = Config.Stages[math.min(st.Index + 1, Config.StageCount)]
	local final = st.Index == Config.StageCount
	local g = Instance.new("Model")
	g.Name = "Gate"
	local gx = LEN / 2 - 2
	local col = nextSt.Gate
	local halfW = 32
	for _, s in {-1, 1} do
		P(g, Vector3.new(6, 50, 6), O * CFrame.new(gx, 25, s * (halfW + 3)), col, {TopSurface = STUDS})
		P(g, Vector3.new(8, 3, 8), O * CFrame.new(gx, 1.5, s * (halfW + 3)), C(45, 40, 45), {TopSurface = STUDS})
	end
	local top = P(g, Vector3.new(9, 5, 2 * halfW + 22), O * CFrame.new(gx, 52, 0), C(35, 30, 38), {TopSurface = STUDS})
	P(g, Vector3.new(7, 3.5, 2 * halfW + 8), O * CFrame.new(gx, 46, 0), col)
	P(g, Vector3.new(2, 7, 18), O * CFrame.new(gx - 1, 48, 0), C(35, 30, 38))
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Left
	sg.LightInfluence = 0
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 14
	sg.Parent = top
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.Text = string.upper(st.Name)
	t.TextColor3 = Color3.new(1, 1, 1)
	local ts = Instance.new("UIStroke"); ts.Thickness = 3; ts.Parent = t
	t.Parent = sg
	local barrier = P(g, Vector3.new(1, 43, 2 * halfW), O * CFrame.new(gx, 22.5, 0), col, {Name = "Barrier", Material = Enum.Material.ForceField, Transparency = 0.3, CastShadow = false})
	barrier.Material = Enum.Material.SmoothPlastic
	-- no text on the barrier (owner 2026-11-02): the client tints it dark grey (closed) / light grey (open)
	local _ = gateText -- kept for reference; unused
	g.Parent = stage
end

---------------------------------------------------------------- Blender kit (ServerStorage.Tools.Kit, imported from AHSKit.fbx)
function W.Kit(name: string, cf: CFrame, st, lit: boolean): Model
	local kitFolder = game:GetService("ServerStorage").Tools:FindFirstChild("Kit")
	local src = kitFolder and kitFolder:FindFirstChild(name)
	if not src then
		local f = Instance.new("Model"); f.Name = name .. "_missing"; return f
	end
	local m = src:Clone()
	local glow = m:FindFirstChild("Glow") :: BasePart?
	if glow then
		glow.Color = mix(Color3.fromRGB(255, 210, 120), st.Gate, 0.35)
		local l = glow:FindFirstChildOfClass("PointLight")
		if l then
			l.Color = glow.Color
			if not lit then l:Destroy() end -- keep light count low for mobile
		end
	end
	local paper = m:FindFirstChild("Paper") :: BasePart?
	if paper then paper.Color = st.Gate end
	local stone = m:FindFirstChild("Stone") :: BasePart?
	if stone then stone.Color = mix(Color3.fromRGB(170, 170, 175), st.Cliff, 0.25) end
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then p.CanQuery = false; p.CanTouch = false end
	end
	m:PivotTo(cf)
	return m
end

---------------------------------------------------------------- one stage
function W.BuildStage(i: number, parent: Instance)
	local st = Config.Stages[i]
	local r = rng(i * 7919)
	local O = CFrame.new((i - 1) * LEN, 0, 0)
	local stage = Instance.new("Model")
	stage.Name = string.format("Stage%02d", i)
	stage:SetAttribute("StageIndex", i)
	local half = LEN / 2

	-- checker floor (two tones, studded) -------------------------------------------------
	local floor = Instance.new("Model"); floor.Name = "Floor"; floor.Parent = stage
	local tileX, tileZ = LEN / 10, 16
	local g1, g2 = st.Ground, shade(st.Ground, 0.86)
	for ix = 0, 9 do
		for iz = -3, 2 do
			local x = -half + tileX * (ix + 0.5)
			local z = tileZ * (iz + 0.5)
			P(floor, Vector3.new(tileX, 4, tileZ), O * CFrame.new(x, -2, z), ((ix + iz) % 2 == 0) and g1 or g2, {TopSurface = STUDS, Name = "Floor"})
		end
	end
	-- path down the middle (lighter, two-tone too)
	for ix = 0, 9 do
		deco(floor, Vector3.new(tileX, 0.3, 22), O * CFrame.new(-half + tileX * (ix + 0.5), 0.12, 0), (ix % 2 == 0) and st.Path or shade(st.Path, 1.06), {TopSurface = STUDS})
	end

	-- terraced cliffs on both sides ---------------------------------------------------------
	local cliffs = Instance.new("Model"); cliffs.Name = "Cliffs"; cliffs.Parent = stage
	local tiers = {{z0 = 48, z1 = 58, h = 7}, {z0 = 58, z1 = 68, h = 14}, {z0 = 68, z1 = 80, h = 22}}
	local segs = 4
	local heights = {}
	for _, side in {-1, 1} do
		heights[side] = {}
		for ti, t in tiers do
			heights[side][ti] = {}
			for s = 0, segs - 1 do
				local x0 = -half + s * (LEN / segs)
				local h = t.h + r:NextInteger(-1, 2)
				heights[side][ti][s] = h
				local depth = t.z1 - t.z0
				local zc = side * (t.z0 + depth / 2)
				P(cliffs, Vector3.new(LEN / segs, h - 1.5, depth), O * CFrame.new(x0 + LEN / segs / 2, (h - 1.5) / 2, zc), shade(st.Cliff, 1 - ti * 0.05), {Name = "Cliff"})
				P(cliffs, Vector3.new(LEN / segs, 1.5, depth), O * CFrame.new(x0 + LEN / segs / 2, h - 0.75, zc), shade(st.Ground, 1.04 - ti * 0.04), {TopSurface = STUDS, Name = "Ledge"})
			end
		end
		-- ramp tier 0 -> 1 so the slopes are reachable (+ lip in front)
		P(cliffs, Vector3.new(LEN, 1, 48 - 46), O * CFrame.new(0, 0.5, side * 47), shade(st.Cliff, 0.9), {TopSurface = STUDS})
		-- back wall (accent coloured, dark cap) on the top tier
		local wallCol = (st.Region <= 1 or st.Region == 4) and C(200, 45, 40) or shade(st.Cliff, 0.75)
		P(cliffs, Vector3.new(LEN, 8, 2), O * CFrame.new(0, 26, side * 79), wallCol, {TopSurface = STUDS})
		P(cliffs, Vector3.new(LEN, 1.2, 3.2), O * CFrame.new(0, 30.6, side * 79), C(40, 35, 40), {TopSurface = STUDS})
	end
	-- start wall for stage 1 / joins between stages are open
	if i == 1 then
		-- start wall with a 22-stud gate: the lobby road (LobbyBuilder.buildStageRoad) walks straight into Stage 1
		for _, sz in {-1, 1} do
			P(stage, Vector3.new(4, 30, 69), O * CFrame.new(-half - 2, 15, sz * 45.5), C(200, 45, 40), {TopSurface = STUDS, Name = "StartWall"})
		end
		P(stage, Vector3.new(4, 6, 22), O * CFrame.new(-half - 2, 21, 0), C(200, 45, 40), {TopSurface = STUDS, Name = "StartWallLintel"})
		local arch = P(stage, Vector3.new(6, 6, 48), O * CFrame.new(-half - 2, 27, 0), C(35, 30, 38), {TopSurface = STUDS})
		local sg = Instance.new("SurfaceGui"); sg.Face = Enum.NormalId.Right; sg.LightInfluence = 0; sg.PixelsPerStud = 14; sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sg.Parent = arch
		local t = Instance.new("TextLabel"); t.BackgroundTransparency = 1; t.Size = UDim2.fromScale(1, 1); t.Font = Enum.Font.FredokaOne; t.TextScaled = true
		t.Text = "STAGE 1 · LEAF GROVE"; t.TextColor3 = Color3.new(1, 1, 1); local s = Instance.new("UIStroke"); s.Thickness = 3; s.Parent = t; t.Parent = sg
	end
	if i == Config.StageCount then
		P(stage, Vector3.new(4, 60, 160), O * CFrame.new(half + 8, 30, 0), shade(st.Cliff, 0.8), {TopSurface = STUDS})
	end
	-- invisible bounds (keep players in the lane area; cliffs remain climbable)
	for _, side in {-1, 1} do
		P(stage, Vector3.new(LEN, 80, 2), O * CFrame.new(0, 40, side * 82), Color3.new(), {Name = "Boundary", Transparency = 1, CanQuery = false})
	end

	-- props on the tiers + floor edges -------------------------------------------------------
	local decor = Instance.new("Model"); decor.Name = "Decor"; decor.Parent = stage
	local filler = FILLER[st.Prop] or "pine"
	for _, side in {-1, 1} do
		for k = 0, 5 do
			local ti = (k % 3) + 1
			local t = tiers[ti]
			local x = -half + 7 + k * (LEN - 14) / 5 + r:NextNumber(-3, 3)
			local z = side * ((t.z0 + t.z1) / 2 + r:NextNumber(-2, 2))
			local seg = math.clamp(math.floor((x + half) / (LEN / segs)), 0, segs - 1)
			local y = heights[side][ti][seg] + 0.5 -- exact ledge top
			local kind = (k % 2 == 0) and st.Prop or filler
			local m = Instance.new("Model"); m.Name = kind; m.Parent = decor
			prop(m, O * CFrame.new(x, y - 0.5, z) * CFrame.Angles(0, r:NextNumber(0, math.pi * 2), 0), st, r, kind)
		end
		-- ground-level props along the floor edge (outside the fight lane)
		for k = 0, 1 do
			local x = -half + 20 + k * (LEN - 40) + r:NextNumber(-4, 4)
			local m = Instance.new("Model"); m.Name = filler; m.Parent = decor
			prop(m, O * CFrame.new(x, 0, side * 41) * CFrame.Angles(0, r:NextNumber(0, 6), 0), st, r, k == 1 and st.Prop or filler)
		end
	end
	-- landmark
	local lm = Instance.new("Model"); lm.Name = "Landmark"; lm.Parent = decor
	local lmSide = (i % 2 == 0) and 1 or -1
	LANDMARK[st.Region](lm, O * CFrame.new(-half + 22, heights[lmSide][2][0] + 0.5, lmSide * 63) * CFrame.Angles(0, lmSide > 0 and math.pi or 0, 0), st)

	-- lanterns lining the path ---------------------------------------------------------------
	local lan = Instance.new("Model"); lan.Name = "Lanterns"; lan.Parent = decor
	for k = 0, 2 do
		for _, side in {-1, 1} do
			local x = -half + 10 + k * (LEN - 26) / 2
			-- Blender kit: stone toro lanterns alternate with hanging paper lanterns (arm reaches over the path)
			local kind = (k % 2 == 0) and "StoneLantern" or "PostLantern"
			local yaw = kind == "PostLantern" and (side > 0 and math.pi / 2 or -math.pi / 2) or 0
			local m = W.Kit(kind, O * CFrame.new(x, 0, side * (kind == "PostLantern" and 17 or 15)) * CFrame.Angles(0, yaw, 0), st, k == 1)
			m:ScaleTo(1.25)
			m.Parent = lan
		end
	end
	-- stone lanterns flank the gate
	for _, side in {-1, 1} do
		local m = W.Kit("StoneLantern", O * CFrame.new(half - 8, 0, side * 27), st, true)
		m:ScaleTo(1.6)
		m.Parent = lan
	end

	-- spawn / arrival pad ---------------------------------------------------------------------
	local spawnPart = P(stage, Vector3.new(14, 1, 14), O * CFrame.new(-half + 14, 0.5, 0), shade(st.Path, 0.9), {Name = "Spawn", TopSurface = STUDS, CanCollide = true})
	spawnPart.CFrame = spawnPart.CFrame * CFrame.Angles(0, -math.pi / 2, 0)
	neon(stage, Vector3.new(15, 0.2, 15), O * CFrame.new(-half + 14, 0.05, 0), st.Gate, {Transparency = 0.4})

	-- enemy spawns (same layout the EnemyService expects) -------------------------------------
	local es = Instance.new("Folder"); es.Name = "EnemySpawns"; es.Parent = stage
	-- 5 regular spots spread across the lane + the boss spot in front of the gate (85-stud stage: x in -42.5..42.5)
	local spots = {S1 = Vector3.new(-12, 0.1, -9), S2 = Vector3.new(-12, 0.1, 9), S3 = Vector3.new(2, 0.1, -15), S4 = Vector3.new(2, 0.1, 15),
		S5 = Vector3.new(8, 0.1, 0), Boss = Vector3.new(26, 0.1, 0)}
	for name, pos in spots do
		P(es, Vector3.new(4, 0.2, 4), O * CFrame.new(pos), Color3.new(1, 0, 0), {Name = name, Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false})
	end

	-- trophy pad -----------------------------------------------------------------------------
	local pad = P(stage, Vector3.new(14, 1, 9), O * CFrame.new(half - 16, 0.5, 31), C(255, 210, 50), {Name = "TrophyPad", TopSurface = STUDS, Material = Enum.Material.SmoothPlastic})
	pad:SetAttribute("Stage", i)
	P(stage, Vector3.new(16, 0.8, 11), O * CFrame.new(half - 16, 0.2, 31), C(40, 35, 45), {CanCollide = false})
	local statue = W.Kit("TrophyStatue", O * CFrame.new(half - 27, 0, 36) * CFrame.Angles(0, math.pi, 0), st, false)
	statue:ScaleTo(1.8)
	statue.Parent = decor
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(220, 70)
	bb.StudsOffset = Vector3.new(0, 5, 0)
	bb.MaxDistance = 140
	bb.LightInfluence = 0
	bb.Parent = pad
	local bt = Instance.new("TextLabel")
	bt.BackgroundTransparency = 1
	bt.Size = UDim2.fromScale(1, 1)
	bt.Font = Enum.Font.FredokaOne
	bt.TextScaled = true
	bt.Text = "+" .. Config.Format(st.Trophies * 10) .. " \u{1F3C6}"
	bt.TextColor3 = C(255, 240, 160)
	local bs = Instance.new("UIStroke"); bs.Thickness = 4; bs.Parent = bt
	bt.Parent = bb

	buildGate(stage, st, O)
	stage.Parent = parent
	return stage
end

---------------------------------------------------------------- lighting + whole course
function W.Lighting()
	local L = game:GetService("Lighting")
	L.ClockTime = 14.2
	L.Brightness = 2.6
	L.EnvironmentDiffuseScale = 0.6
	L.EnvironmentSpecularScale = 0.4
	L.Ambient = C(110, 110, 125)
	L.OutdoorAmbient = C(150, 150, 165)
	L.ShadowSoftness = 0.25
	local atm = L:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", L)
	atm.Density = 0.24
	atm.Offset = 0.1
	atm.Color = C(200, 225, 255)
	atm.Decay = C(120, 150, 200)
	atm.Glare = 0.1
	atm.Haze = 1.2
	local cc = L:FindFirstChild("StageGrade") or Instance.new("ColorCorrectionEffect")
	cc.Name = "StageGrade"
	cc.Saturation = 0.18
	cc.Contrast = 0.06
	cc.Brightness = 0.02
	cc.Parent = L
	local bloom = L:FindFirstChildOfClass("BloomEffect")
	if bloom then bloom.Intensity = 0.6; bloom.Size = 20; bloom.Threshold = 1.6 end
	local dof = L:FindFirstChildOfClass("DepthOfFieldEffect")
	if dof then dof.Enabled = false end
end

function W.BuildAll(from: number?, to: number?)
	local course = workspace:FindFirstChild("StageCourse")
	if not course then course = Instance.new("Folder"); course.Name = "StageCourse"; course.Parent = workspace end
	-- drop stages beyond the current StageCount (course was 50, now 30)
	for _, s in course:GetChildren() do
		local n = s:GetAttribute("StageIndex")
		if n and n > Config.StageCount then s:Destroy() end
	end
	for i = from or 1, to or Config.StageCount do
		local old = course:FindFirstChild(string.format("Stage%02d", i))
		if old then old:Destroy() end
		-- build outside the DataModel, then parent once (cheap single insert per stage)
		local holder = Instance.new("Folder")
		local s = W.BuildStage(i, holder)
		s.Parent = course
		holder:Destroy()
		task.wait()
	end
	local sl = workspace:FindFirstChild("SpawnLocation")
	if sl then sl.CFrame = CFrame.new(-260, -20, 0); sl.Transparency = 1; sl.CanCollide = false; local d = sl:FindFirstChildOfClass("Decal"); if d then d:Destroy() end end
	W.Lighting()
end

return W
