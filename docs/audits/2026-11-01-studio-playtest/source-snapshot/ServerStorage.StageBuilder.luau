-- Edit-time builder for the 50 connected studded stages (run from the command bar / MCP in chunks).
local Config = require(game.ReplicatedStorage.Shared.Config)
local B = {}
local L = Config.StageLength
local HALF_W = 60

local function part(parent, size, cf, color, opts)
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = Enum.Material.Plastic
	p.TopSurface = Enum.SurfaceType.Studs
	p.BottomSurface = Enum.SurfaceType.Inlet
	if opts then for k, v in opts do p[k] = v end end
	p.Parent = parent
	return p
end
local function shade(c, f) return Color3.new(math.clamp(c.R * f, 0, 1), math.clamp(c.G * f, 0, 1), math.clamp(c.B * f, 0, 1)) end

---------------------------------------------------------------- props
local P = {}
function P.tree(m, pos, st, rng, style)
	local h = rng:NextInteger(8, 14)
	part(m, Vector3.new(2.5, h, 2.5), CFrame.new(pos + Vector3.new(0, h / 2, 0)), st.Trunk)
	if style == "pine" then
		for i = 0, 2 do
			local s = 11 - i * 3
			part(m, Vector3.new(s, 3, s), CFrame.new(pos + Vector3.new(0, h - 2 + i * 3, 0)), shade(st.Leaf, 1 - i * 0.06))
		end
		part(m, Vector3.new(2, 2, 2), CFrame.new(pos + Vector3.new(0, h + 8, 0)), st.Leaf)
	elseif style == "mushroom" then
		part(m, Vector3.new(12, 4, 12), CFrame.new(pos + Vector3.new(0, h + 1, 0)), st.Leaf)
		part(m, Vector3.new(8, 2, 8), CFrame.new(pos + Vector3.new(0, h + 4, 0)), shade(st.Leaf, 1.1))
	else -- rounded blocky canopy (blossom, spirit, big tree)
		local big = style == "bigtree" and 1.6 or 1
		part(m, Vector3.new(12, 6, 12) * big, CFrame.new(pos + Vector3.new(0, h + 2, 0)), st.Leaf)
		part(m, Vector3.new(8, 4, 8) * big, CFrame.new(pos + Vector3.new(rng:NextNumber(-1, 1), h + 6 * big, rng:NextNumber(-1, 1))), shade(st.Leaf, 1.08))
		part(m, Vector3.new(5, 3, 5) * big, CFrame.new(pos + Vector3.new(4, h, 3)), shade(st.Leaf, 0.92))
		if style == "spirittree" then
			local orb = part(m, Vector3.new(1.5, 1.5, 1.5), CFrame.new(pos + Vector3.new(3, h - 2, -3)), st.Gate, {Material = Enum.Material.Neon, Shape = Enum.PartType.Ball, CanCollide = false})
		end
	end
end
function P.column(m, pos, st, rng, style)
	local n = (style == "bamboo" or style == "reed") and rng:NextInteger(3, 6) or 1
	for i = 1, n do
		local off = n > 1 and Vector3.new(rng:NextNumber(-4, 4), 0, rng:NextNumber(-4, 4)) or Vector3.zero
		local h = rng:NextInteger(10, 22)
		local w = (style == "bamboo" or style == "reed" or style == "rod") and 1.4 or (style == "cactus" and 3 or 4)
		local col = (style == "bamboo" or style == "cactus" or style == "reed") and st.Leaf or (style == "lavarock" and st.Cliff or st.Gate)
		local mat = (style == "icespike" or style == "crystal") and Enum.Material.Glass or (style == "goldpillar" and Enum.Material.Plastic or Enum.Material.Plastic)
		local p = part(m, Vector3.new(w, h, w), CFrame.new(pos + off + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, rng:NextNumber(0, 1), (style == "crystal" or style == "icespike") and rng:NextNumber(-0.25, 0.25) or 0), col, {Material = mat})
		if style == "bamboo" then
			for y = 3, h - 1, 4 do part(m, Vector3.new(w + 0.3, 0.5, w + 0.3), CFrame.new(pos + off + Vector3.new(0, y, 0)), shade(col, 0.8)) end
			part(m, Vector3.new(4, 1, 1), CFrame.new(pos + off + Vector3.new(1.5, h - 1, 0)) * CFrame.Angles(0, 0, 0.4), st.Leaf)
		elseif style == "cactus" then
			part(m, Vector3.new(4, 2, 2), CFrame.new(pos + off + Vector3.new(2, h * 0.5, 0)), col)
			part(m, Vector3.new(2, 5, 2), CFrame.new(pos + off + Vector3.new(4, h * 0.5 + 2.5, 0)), col)
		elseif style == "lavarock" then
			part(m, Vector3.new(w + 0.2, 1, w + 0.2), CFrame.new(pos + off + Vector3.new(0, h, 0)), st.Leaf, {Material = Enum.Material.Neon})
		elseif style == "rod" then
			part(m, Vector3.new(2.5, 2.5, 2.5), CFrame.new(pos + off + Vector3.new(0, h + 1, 0)), st.Gate, {Material = Enum.Material.Neon, Shape = Enum.PartType.Ball})
		elseif style == "goldpillar" or style == "pillar" then
			part(m, Vector3.new(w + 2, 1.5, w + 2), CFrame.new(pos + off + Vector3.new(0, h, 0)), shade(col, 0.85))
			part(m, Vector3.new(w + 2, 1.5, w + 2), CFrame.new(pos + off + Vector3.new(0, 0.75, 0)), shade(col, 0.85))
		end
		if style == "crystal" or style == "icespike" then p.Transparency = 0.15; p.Reflectance = 0.1 end
	end
end
function P.boulder(m, pos, st, rng, style)
	local lift = (style == "floatrock" or style == "cloudpuff") and rng:NextInteger(10, 20) or 0
	local col = style == "cloudpuff" and Color3.new(1, 1, 1) or shade(st.Cliff, 0.95)
	for i = 1, 3 do
		local s = rng:NextInteger(4, 8)
		part(m, Vector3.new(s, s * 0.8, s), CFrame.new(pos + Vector3.new(rng:NextNumber(-3, 3), lift + s * 0.4 + (i - 1), rng:NextNumber(-3, 3))) * CFrame.Angles(0, rng:NextNumber(0, 1.5), 0), shade(col, 1 - i * 0.04))
	end
	if style == "floatrock" then part(m, Vector3.new(6, 1, 6), CFrame.new(pos + Vector3.new(0, lift + 6, 0)), st.Ground) end
end
function P.structure(m, pos, st, rng, style)
	local rot = CFrame.Angles(0, math.rad(rng:NextInteger(0, 3) * 90), 0)
	local base = CFrame.new(pos) * rot
	if style == "torii" or style == "cloud" then
		part(m, Vector3.new(2, 14, 2), base * CFrame.new(-6, 7, 0), st.Gate)
		part(m, Vector3.new(2, 14, 2), base * CFrame.new(6, 7, 0), st.Gate)
		part(m, Vector3.new(18, 1.5, 3), base * CFrame.new(0, 14.5, 0), shade(st.Gate, 0.4))
		part(m, Vector3.new(15, 1, 2), base * CFrame.new(0, 11, 0), st.Gate)
	elseif style == "grave" or style == "scroll" or style == "banner" then
		for i = -1, 1 do
			local h = style == "banner" and 12 or 4
			part(m, Vector3.new(style == "banner" and 0.6 or 3, h, style == "banner" and 0.6 or 1), base * CFrame.new(i * 6, h / 2, 0), style == "banner" and st.Trunk or shade(st.Cliff, 1.2))
			if style == "banner" then part(m, Vector3.new(3, 5, 0.3), base * CFrame.new(i * 6 + 1.6, h - 3, 0), st.Gate) end
		end
	elseif style == "waterfall" then
		part(m, Vector3.new(14, 24, 4), base * CFrame.new(0, 12, 2), st.Cliff)
		part(m, Vector3.new(8, 24, 1), base * CFrame.new(0, 12, -0.6), Color3.fromRGB(120, 210, 255), {Material = Enum.Material.Glass, Transparency = 0.3, CanCollide = false})
	elseif style == "crack" then
		for i = 1, 4 do part(m, Vector3.new(rng:NextInteger(6, 12), 0.3, 1), base * CFrame.new(rng:NextNumber(-5, 5), 0.1, rng:NextNumber(-5, 5)) * CFrame.Angles(0, rng:NextNumber(0, 3), 0), st.Leaf, {Material = Enum.Material.Neon, CanCollide = false}) end
		P.boulder(m, pos + Vector3.new(0, 0, 8), st, rng, "floatrock")
	elseif style == "snakestatue" or style == "toadstatue" or style == "tank" or style == "coral" or style == "windmill" then
		part(m, Vector3.new(6, 3, 6), base * CFrame.new(0, 1.5, 0), shade(st.Cliff, 1.1))
		if style == "toadstatue" then
			part(m, Vector3.new(7, 5, 6), base * CFrame.new(0, 5.5, 0), st.Leaf)
			part(m, Vector3.new(1.5, 1.5, 1.5), base * CFrame.new(-2, 8.5, -2), Color3.new(1, 0.9, 0.3))
			part(m, Vector3.new(1.5, 1.5, 1.5), base * CFrame.new(2, 8.5, -2), Color3.new(1, 0.9, 0.3))
		elseif style == "tank" then
			part(m, Vector3.new(4, 10, 4), base * CFrame.new(0, 8, 0), st.Leaf, {Material = Enum.Material.Glass, Transparency = 0.35})
		elseif style == "windmill" then
			part(m, Vector3.new(3, 14, 3), base * CFrame.new(0, 10, 0), st.Trunk)
			part(m, Vector3.new(14, 1.5, 0.5), base * CFrame.new(0, 16, -1.8) * CFrame.Angles(0, 0, 0.4), st.Gate)
			part(m, Vector3.new(14, 1.5, 0.5), base * CFrame.new(0, 16, -1.8) * CFrame.Angles(0, 0, 1.97), st.Gate)
		else
			for i = 0, 3 do part(m, Vector3.new(2.5, 2.5, 2.5), base * CFrame.new(math.sin(i) * 1.5, 4 + i * 2.2, math.cos(i) * 1.5), st.Leaf) end
		end
	else -- house / dojo / temple / castle / wall / ruinhouse
		local w, d, h = 16, 12, 9
		if style == "castle" or style == "temple" then w, d, h = 20, 16, 12 end
		if style == "wall" then w, d, h = 26, 4, 12 end
		local wallCol = (style == "house" or style == "dojo") and Color3.fromRGB(240, 230, 210) or shade(st.Cliff, 1.15)
		part(m, Vector3.new(w, h, d), base * CFrame.new(0, h / 2, 0), wallCol)
		part(m, Vector3.new(w, 1, d), base * CFrame.new(0, 1, 0), st.Trunk)
		if style ~= "wall" and style ~= "ruinhouse" then
			part(m, Vector3.new(w + 4, 1.5, d + 4), base * CFrame.new(0, h + 0.75, 0), shade(st.Gate, 0.55))
			part(m, Vector3.new(w - 2, 2.5, d - 2), base * CFrame.new(0, h + 2.75, 0), shade(st.Gate, 0.45))
			part(m, Vector3.new(w * 0.4, 1, d * 0.4), base * CFrame.new(0, h + 4.5, 0), shade(st.Gate, 0.4))
			part(m, Vector3.new(4, 6, 0.4), base * CFrame.new(0, 3, -d / 2 - 0.1), st.Trunk)
		elseif style == "wall" then
			for i = -2, 2 do part(m, Vector3.new(3, 2, d), base * CFrame.new(i * 5.5, h + 1, 0), wallCol) end
		else
			part(m, Vector3.new(w * 0.6, 2, d), base * CFrame.new(-w * 0.2, h + 1, 0), wallCol)
		end
	end
end
local propKind = {pine="tree", blossom="tree", spirittree="tree", bigtree="tree", mushroom="tree",
	bamboo="column", reed="column", rod="column", icespike="column", crystal="column", goldpillar="column", pillar="column", lavarock="column", cactus="column",
	rock="boulder", boulder="boulder", moonrock="boulder", floatrock="boulder", cloudpuff="boulder"}
local function prop(m, pos, st, rng)
	local style = st.Prop
	local kind = propKind[style] or "structure"
	P[kind](m, pos, st, rng, style)
end

local function lantern(m, pos, st)
	part(m, Vector3.new(1, 6, 1), CFrame.new(pos + Vector3.new(0, 3, 0)), Color3.fromRGB(40, 35, 35))
	local head = part(m, Vector3.new(2.4, 2.6, 2.4), CFrame.new(pos + Vector3.new(0, 7, 0)), st.Gate, {Material = Enum.Material.Neon})
	part(m, Vector3.new(3, 0.6, 3), CFrame.new(pos + Vector3.new(0, 8.5, 0)), Color3.fromRGB(40, 35, 35))
	local light = Instance.new("PointLight")
	light.Color = st.Gate
	light.Range = 14
	light.Brightness = 1.2
	light.Parent = head
end

---------------------------------------------------------------- gate signage
local function label(parent, text, size, pos, color, rot)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = size
	t.Position = pos
	t.Text = text
	t.TextScaled = true
	t.Font = Enum.Font.FredokaOne
	t.TextColor3 = color or Color3.new(1, 1, 1)
	t.Rotation = rot or -6
	local s = Instance.new("UIStroke")
	s.Thickness = 4
	s.Color = Color3.fromRGB(25, 20, 30)
	s.Parent = t
	t.Parent = parent
	return t
end

function B.BuildGate(m, i, x0, st)
	local nextSt = Config.Stages[i + 1]
	local gx = x0 + L / 2 - 2
	local gateModel = Instance.new("Model")
	gateModel.Name = "Gate"
	local frameCol = Color3.fromRGB(205, 30, 35)
	part(gateModel, Vector3.new(6, 48, 6), CFrame.new(gx, 24, -HALF_W + 3), frameCol)
	part(gateModel, Vector3.new(6, 48, 6), CFrame.new(gx, 24, HALF_W - 3), frameCol)
	part(gateModel, Vector3.new(8, 5, HALF_W * 2 + 14), CFrame.new(gx, 50, 0), Color3.fromRGB(30, 25, 25))
	part(gateModel, Vector3.new(7, 3, HALF_W * 2 + 4), CFrame.new(gx, 46, 0), frameCol)
	local tint = nextSt and nextSt.Gate or st.Gate
	local barrier = part(gateModel, Vector3.new(1, 43, HALF_W * 2 - 12), CFrame.new(gx, 21.5, 0), tint, {Name = "Barrier", Transparency = 0.35, Material = Enum.Material.SmoothPlastic, TopSurface = Enum.SurfaceType.Smooth})
	barrier:SetAttribute("Stage", i)
	for _, face in {Enum.NormalId.Left, Enum.NormalId.Right} do
		local sg = Instance.new("SurfaceGui")
		sg.Name = face == Enum.NormalId.Left and "FrontGui" or "BackGui"
		sg.Face = face
		sg.CanvasSize = Vector2.new(1080, 430)
		sg.LightInfluence = 0
		sg.Parent = barrier
		if nextSt then
			label(sg, "5 LEFT", UDim2.fromScale(0.36, 0.13), UDim2.fromScale(0.32, 0.13), Color3.new(1, 1, 1)).Name = "Left"
			label(sg, "STAGE " .. (i + 1), UDim2.fromScale(0.5, 0.17), UDim2.fromScale(0.25, 0.3), Color3.new(1, 1, 1)).Name = "StageNum"
			label(sg, string.upper(nextSt.Name), UDim2.fromScale(0.5, 0.08), UDim2.fromScale(0.25, 0.48), Color3.fromRGB(255, 240, 200))
			label(sg, "RECOMMENDED HAND SIGNS " .. Config.Format(nextSt.Recommended), UDim2.fromScale(0.8, 0.1), UDim2.fromScale(0.1, 0.6), Color3.fromRGB(110, 230, 255))
			label(sg, "+" .. Config.Format(st.Trophies * 10) .. " TROPHIES", UDim2.fromScale(0.44, 0.09), UDim2.fromScale(0.28, 0.74), Color3.fromRGB(255, 215, 60))
		else
			label(sg, "5 LEFT", UDim2.fromScale(0.36, 0.13), UDim2.fromScale(0.32, 0.18), Color3.new(1, 1, 1)).Name = "Left"
			label(sg, "DIVINE SUMMIT", UDim2.fromScale(0.6, 0.15), UDim2.fromScale(0.2, 0.38), Color3.fromRGB(255, 230, 140))
			label(sg, "FINAL STAGE - DEFEAT THE DIVINE CHAKRA MASTER", UDim2.fromScale(0.86, 0.09), UDim2.fromScale(0.07, 0.6), Color3.new(1, 1, 1))
		end
	end
	-- biome name arch text on the top beam
	local beamGui = Instance.new("SurfaceGui")
	beamGui.Face = Enum.NormalId.Left
	beamGui.CanvasSize = Vector2.new(1400, 60)
	beamGui.LightInfluence = 0
	label(beamGui, string.upper(st.Name), UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), Color3.new(1, 1, 1), 0)
	beamGui.Parent = gateModel:GetChildren()[3]
	gateModel.Parent = m
	return barrier
end

---------------------------------------------------------------- one stage
function B.BuildStage(i, parent)
	local st = Config.Stages[i]
	local x0 = (i - 1) * L
	local rng = Random.new(i * 7919)
	local old = parent:FindFirstChild(string.format("Stage%02d", i))
	if old then old:Destroy() end
	local m = Instance.new("Model")
	m.Name = string.format("Stage%02d", i)
	m:SetAttribute("StageIndex", i)
	local deco = Instance.new("Model"); deco.Name = "Decor"; deco.Parent = m

	-- checker studded floor (20x20 tiles) + lighter central path
	local tile = 20
	for tx = 0, L / tile - 1 do
		for tz = 0, (HALF_W * 2) / tile - 1 do
			local cx = x0 - L / 2 + tile / 2 + tx * tile
			local cz = -HALF_W + tile / 2 + tz * tile
			local onPath = math.abs(cz) < 20 and (tx % 2 == 0)
			local base = (tx + tz) % 2 == 0 and st.Ground or shade(st.Ground, 0.9)
			if math.abs(cz) < 15 then base = (tx + tz) % 2 == 0 and st.Path or shade(st.Path, 0.92) end
			part(m, Vector3.new(tile, 4, tile), CFrame.new(cx, -2, cz), base, {Name = "Floor"})
		end
	end
	-- layered side cliffs (3 tiers) with grass caps
	for side = -1, 1, 2 do
		for tier = 1, 3 do
			local h = tier * 7
			local z = side * (HALF_W + tier * 9 - 4)
			for seg = 0, 3 do
				local sx = x0 - L / 2 + seg * (L / 4) + L / 8
				local jitter = rng:NextInteger(-2, 2)
				part(deco, Vector3.new(L / 4 + 0.2, h + jitter, 10), CFrame.new(sx, (h + jitter) / 2, z), shade(st.Cliff, 1 - tier * 0.05))
				part(deco, Vector3.new(L / 4 + 0.2, 1.2, 10), CFrame.new(sx, h + jitter + 0.6, z), shade(st.Ground, 1 - tier * 0.04))
			end
			-- props on each tier
			for k = 1, 3 do
				local px = x0 - L / 2 + rng:NextNumber(10, L - 10)
				prop(deco, Vector3.new(px, h + 1.2, z + rng:NextNumber(-2, 2)), st, rng)
			end
		end
		-- invisible boundary wall
		part(m, Vector3.new(L, 60, 2), CFrame.new(x0, 30, side * (HALF_W + 1)), Color3.new(), {Transparency = 1, Name = "Boundary"})
	end
	-- ground-level props near the edges + lanterns along the path
	for k = 1, 4 do
		local side = k % 2 == 0 and 1 or -1
		prop(deco, Vector3.new(x0 - L / 2 + 20 + (k - 1) * 38 + rng:NextNumber(-5, 5), 0, side * rng:NextNumber(40, 52)), st, rng)
	end
	for k = 0, 3 do
		lantern(deco, Vector3.new(x0 - L / 2 + 25 + k * 40, 0, 18), st)
		lantern(deco, Vector3.new(x0 - L / 2 + 25 + k * 40, 0, -18), st)
	end
	-- spawn / arrival platform
	local spawnPart = part(m, Vector3.new(14, 1, 14), CFrame.new(x0 - L / 2 + 14, 0.5, 0) * CFrame.Angles(0, -math.pi / 2, 0), shade(st.Path, 0.85), {Name = "Spawn", CanCollide = true})
	-- enemy spawn markers (4 regular + 1 elite/boss)
	local spawns = Instance.new("Folder"); spawns.Name = "EnemySpawns"; spawns.Parent = m
	local pts = {Vector3.new(10, 0, -10), Vector3.new(10, 0, 10), Vector3.new(30, 0, -18), Vector3.new(30, 0, 18), Vector3.new(45, 0, 0)}
	for idx, p in pts do
		local sp = part(spawns, Vector3.new(4, 0.2, 4), CFrame.new(x0 + p.X, 0.1, p.Z), Color3.new(), {Transparency = 1, CanCollide = false, CanQuery = false, Name = idx == 5 and "Boss" or ("S" .. idx)})
	end
	-- trophy reward pad (claims stage-clear reward)
	local pad = part(m, Vector3.new(16, 1, 10), CFrame.new(x0 + L / 2 - 22, 0.5, 34), Color3.fromRGB(255, 215, 40), {Name = "TrophyPad", Material = Enum.Material.SmoothPlastic})
	part(m, Vector3.new(18, 0.6, 12), CFrame.new(x0 + L / 2 - 22, 0.3, 34), Color3.fromRGB(30, 25, 30))
	pad:SetAttribute("Stage", i)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromScale(10, 4)
	bb.StudsOffset = Vector3.new(0, 5, 0)
	bb.AlwaysOnTop = false
	bb.LightInfluence = 0
	bb.MaxDistance = 150
	label(bb, "+" .. Config.Format(st.Trophies * 10) .. " \u{1F3C6}", UDim2.fromScale(1, 0.7), UDim2.fromScale(0, 0), Color3.fromRGB(255, 225, 90), 0)
	label(bb, "CLEAR STAGE TO CLAIM", UDim2.fromScale(1, 0.3), UDim2.fromScale(0, 0.7), Color3.new(1, 1, 1), 0).Name = "Hint"
	bb.Parent = pad
	-- stage title stone near the spawn
	local sign = part(deco, Vector3.new(1, 6, 16), CFrame.new(x0 - L / 2 + 30, 5, -30), st.Gate)
	local sg = Instance.new("SurfaceGui"); sg.Face = Enum.NormalId.Left; sg.CanvasSize = Vector2.new(400, 150); sg.LightInfluence = 0; sg.Parent = sign
	label(sg, "STAGE " .. i, UDim2.fromScale(1, 0.5), UDim2.fromScale(0, 0), Color3.new(1, 1, 1), 0)
	label(sg, string.upper(st.Name), UDim2.fromScale(1, 0.4), UDim2.fromScale(0, 0.55), Color3.fromRGB(255, 245, 210), 0)
	part(deco, Vector3.new(1.5, 4, 1.5), CFrame.new(x0 - L / 2 + 30, 1, -24), st.Trunk)
	part(deco, Vector3.new(1.5, 4, 1.5), CFrame.new(x0 - L / 2 + 30, 1, -36), st.Trunk)

	B.BuildGate(m, i, x0, st)
	m.Parent = parent
	return m
end

function B.SetupWorld()
	local course = workspace:FindFirstChild("StageCourse")
	if not course then course = Instance.new("Folder"); course.Name = "StageCourse"; course.Parent = workspace end
	for _, n in {"Baseplate", "SpawnLocation"} do local o = workspace:FindFirstChild(n); if o then o:Destroy() end end
	local Lighting = game:GetService("Lighting")
	Lighting.ClockTime = 14
	Lighting.Brightness = 2.2
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.3
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 160)
	Lighting.Ambient = Color3.fromRGB(70, 70, 80)
	Lighting.GlobalShadows = true
	local atm = Lighting:FindFirstChildOfClass("Atmosphere")
	if atm then atm.Density = 0.22; atm.Haze = 0.4; atm.Color = Color3.fromRGB(200, 225, 255); atm.Decay = Color3.fromRGB(120, 150, 200) end
	local dof = Lighting:FindFirstChildOfClass("DepthOfFieldEffect")
	if dof then dof.Enabled = false end
	local sp = Instance.new("SpawnLocation")
	sp.Name = "SpawnLocation"; sp.Anchored = true; sp.Size = Vector3.new(8, 1, 8); sp.CFrame = CFrame.new(-L / 2 + 14, 0.6, 0); sp.Transparency = 1; sp.CanCollide = false; sp.Neutral = true
	sp.Parent = workspace
	pcall(function() workspace.StreamingEnabled = false end)
	return course
end

return B

