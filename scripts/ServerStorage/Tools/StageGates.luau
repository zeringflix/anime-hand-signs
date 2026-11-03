--!nonstrict
-- StageGates (edit-time tool, owner 2026-11-02 "like +1 Anime Eyes"): adds the big entrance banner
-- "STAGE N / RECOMMENDED CHAKRA X" (or "BOSS STAGE") over every stage's entry, and restyles Stage 1's start wall as
-- the pink STAGE 1 gate the lobby opens onto. Additive: never deletes stage geometry, only recolours Stage 1's
-- StartWall pieces and replaces its old small arch sign. Safe to re-run (old EntryBanner models are replaced).
--
--   require(game.ServerStorage.Tools.StageGates).Apply()  -> number of banners
local RS = game:GetService("ReplicatedStorage")
local function fresh(mod: ModuleScript): any
	local c = mod:Clone(); c.Parent = mod.Parent
	local ok, r = pcall(require, c); c:Destroy()
	return ok and r or require(mod)
end
local Config = fresh(RS.Shared.Config)

local G = {}
local PINK, PINK2 = Color3.fromRGB(255, 62, 150), Color3.fromRGB(214, 30, 116)

local function part(parent: Instance, size: Vector3, cf: CFrame, color: Color3, props: {[string]: any}?): Part
	local p = Instance.new("Part")
	p.Anchored = true; p.Size = size; p.CFrame = cf; p.Color = color
	p.Material = Enum.Material.Plastic; p.TopSurface = Enum.SurfaceType.Studs; p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props or {} do (p :: any)[k] = v end
	p.Parent = parent
	return p
end
local function label(parent: Instance, text: string, pos: UDim2, size: UDim2, color: Color3, stroke: number)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1; t.Position = pos; t.Size = size; t.Text = text; t.TextScaled = true
	t.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy)
	t.TextColor3 = color
	local s = Instance.new("UIStroke"); s.Thickness = stroke; s.Color = Color3.fromRGB(20, 16, 28); s.LineJoinMode = Enum.LineJoinMode.Round; s.Parent = t
	t.Parent = parent
	return t
end
-- two-line sign on both faces of a board part (faces along X)
local function sign(board: BasePart, i: number, st: any)
	local boss = Config.HasBoss and Config.HasBoss(i)
	for _, face in {Enum.NormalId.Left, Enum.NormalId.Right} do
		local sg = Instance.new("SurfaceGui")
		sg.Face = face; sg.LightInfluence = 0; sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sg.PixelsPerStud = 8 -- TextScaled caps at 100 px
		sg.Parent = board
		label(sg, "STAGE " .. i, UDim2.fromScale(0.05, 0.02), UDim2.fromScale(0.9, 0.56), Color3.new(1, 1, 1), 6)
		local rec = st.Recommended > 0 and ("RECOMMENDED CHAKRA " .. Config.Format(st.Recommended)) or "START HERE!"
		local sub = boss and ("BOSS STAGE  ·  " .. rec) or rec
		local _ = boss and ("BOSS STAGE  ·  RECOMMENDED CHAKRA " .. Config.Format(st.Recommended)) or ("RECOMMENDED CHAKRA " .. Config.Format(st.Recommended))
		label(sg, sub, UDim2.fromScale(0.04, 0.6), UDim2.fromScale(0.92, 0.32), boss and Color3.fromRGB(255, 110, 110) or Color3.fromRGB(255, 236, 90), 4)
	end
end

function G.Apply(): number
	local course = workspace:FindFirstChild("StageCourse")
	assert(course, "StageCourse missing")
	local n = 0
	for i = 1, Config.StageCount do
		local stage = course:FindFirstChild(string.format("Stage%02d", i))
		if not stage then continue end
		local st = Config.Stages[i]
		local old = stage:FindFirstChild("EntryBanner"); if old then old:Destroy() end
		local m = Instance.new("Model"); m.Name = "EntryBanner"
		m:SetAttribute("Source", "ServerStorage.Tools.StageGates")
		local x0 = (i - 1) * Config.StageLength - Config.StageLength / 2
		if i == 1 then
			-- Stage 1: the start wall IS the gate (pink like the reference); tall sign board above the opening
			for _, c in stage:GetChildren() do
				if c:IsA("BasePart") and (c.Name == "StartWall" or c.Name == "StartWallLintel") then
					c.Color = PINK
					-- raised studs on the lobby-facing side (same original stud tile as the UI)
					for _, old in c:GetChildren() do if old:IsA("Texture") and old.Name == "Studs" then old:Destroy() end end
					local tx = Instance.new("Texture"); tx.Name = "Studs"; tx.Face = Enum.NormalId.Left; tx.Texture = "rbxassetid://84866711570025"
					tx.StudsPerTileU = 3; tx.StudsPerTileV = 3; tx.Transparency = 0.15; tx.Parent = c
				end
				if c:IsA("BasePart") and c.Name == "Part" and c:FindFirstChildOfClass("SurfaceGui") and math.abs(c.Position.X - (x0 - 2)) < 1 then c:Destroy() end
			end
			local board = part(m, Vector3.new(4.6, 14, 64), CFrame.new(x0 - 2, 37, 0), PINK2, {Name = "SignBoard"})
			part(m, Vector3.new(5, 1.2, 66), CFrame.new(x0 - 2, 44.6, 0), Color3.fromRGB(40, 32, 46), {Name = "SignCap"})
			-- posts tying the board to the wall
			for _, z in {-26, 26} do part(m, Vector3.new(4.4, 2, 4), CFrame.new(x0 - 2, 31, z), PINK2) end
			sign(board, i, st)
		else
			-- later stages: a floating banner over the entry lane (non-colliding), coloured with the stage's gate colour
			local col = st.Gate or PINK
			local board = part(m, Vector3.new(2.4, 10, 46), CFrame.new(x0 + 7, 24, 0), col, {Name = "SignBoard", CanCollide = false, CanQuery = false})
			part(m, Vector3.new(2.8, 1, 48), CFrame.new(x0 + 7, 29.5, 0), Color3.fromRGB(40, 32, 46), {CanCollide = false, CanQuery = false})
			for _, z in {-24, 24} do
				part(m, Vector3.new(2.4, 29, 2.4), CFrame.new(x0 + 7, 14.5, z), col:Lerp(Color3.new(0, 0, 0), 0.25), {Name = "Post"})
			end
			sign(board, i, st)
		end
		m.Parent = stage
		n += 1
	end
	return n
end

return G
