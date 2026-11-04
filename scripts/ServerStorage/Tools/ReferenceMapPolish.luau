-- Reversible edit-time finish pass. Never rebuilds stages, spawns, gates or stations.
-- Run ApplyRange in batches; Restore returns every edited property and archives additions.
local Config = require(game.ReplicatedStorage.Shared.Config)
local M = {}
local PREFIX = "ReferenceFinishOriginal_"
local function set(part, property, value)
	if part:GetAttribute(PREFIX .. property) == nil then
		local old = part[property]
		part:SetAttribute(PREFIX .. property, typeof(old) == "EnumItem" and old.Name or old)
	end
	part[property] = value
end
local function shade(c, f) return Color3.new(c.R * f, c.G * f, c.B * f) end
local function earth(st)
	-- Warm soil beneath green biomes; retain ice, desert, volcanic and supernatural palettes.
	local c = st.Cliff
	if c.G > c.R * 1.15 and c.G > c.B * 1.15 then return Color3.fromRGB(146, 83, 56) end
	return c:Lerp(Color3.fromRGB(108, 86, 77), 0.22)
end
local function add(parent, name, size, pos, color)
	local p = Instance.new("Part")
	p.Name = name; p.Size = size; p.Position = pos; p.Color = color
	p.Anchored = true; p.CanCollide = false; p.CanTouch = false; p.CanQuery = false
	p.Material = Enum.Material.Plastic; p.TopSurface = Enum.SurfaceType.Studs
	p.BottomSurface = Enum.SurfaceType.Smooth; p.Parent = parent
	return p
end
function M.ApplyStage(stage, index)
	local st = Config.Stages[index]
	if not st then return end
	local soil = earth(st)
	local cliffs = stage:FindFirstChild("Cliffs")
	if cliffs then
		for _, p in cliffs:GetDescendants() do
			if p:IsA("BasePart") then
				if p.Name == "Cliff" then
					set(p, "Color", shade(soil, 0.82 + math.clamp(p.Position.Y / 80, 0, 0.14)))
				elseif p.Name == "Ledge" then
					set(p, "Color", st.Ground); set(p, "TopSurface", Enum.SurfaceType.Studs)
				elseif p.Size.X >= Config.StageLength - 1 and p.Position.Y > 20 then
					-- Existing red perimeter wall becomes the upper earth/grass terrace.
					set(p, "Color", p.Size.Y <= 2 and st.Ground or soil)
				end
			end
		end
	end
	if index == 1 then
		local additions = stage:FindFirstChild("ReferenceEntranceFinish")
		if not additions then
			additions = Instance.new("Model"); additions.Name = "ReferenceEntranceFinish"
			additions.Parent = stage
			for _, wall in stage:GetChildren() do
				if wall:IsA("BasePart") and wall.Name == "StartWall" then
					for _, face in {-1, 1} do
						for band = 1, 3 do
							for segment = 1, 3 do
								local width = wall.Size.Z / 3
								local z = wall.Position.Z - wall.Size.Z / 2 + width * (segment - 0.5)
								local h = 8 + ((segment + band) % 2)
								local top = band * 10
								local x = wall.Position.X + face * (wall.Size.X / 2 + (4 - band) * 0.55)
								add(additions, "EarthFace", Vector3.new((4-band)*1.1, h, width-0.12), Vector3.new(x,top-h/2,z), shade(soil,0.88+segment*0.035))
								add(additions, "GrassShelf", Vector3.new((4-band)*1.1+0.7,0.8,width),Vector3.new(x,top+0.15,z),st.Ground)
							end
						end
					end
				end
			end
		end
		for _, p in stage:GetChildren() do
			if p:IsA("BasePart") then
				if p.Name == "StartWall" or p.Name == "StartWallLintel" then
					set(p,"Color",soil); set(p,"Material",Enum.Material.Plastic)
				elseif p.Name == "Part" and p.Size == Vector3.new(6,6,48) then
					set(p,"Color",st.Ground); set(p,"TopSurface",Enum.SurfaceType.Studs)
				end
			end
		end
	end
	stage:SetAttribute("ReferenceFinishVersion", 1)
end
function M.ApplyRange(first, last)
	assert(first >= 1 and last <= Config.StageCount and first <= last)
	for i = first, last do
		local stage = workspace.StageCourse:FindFirstChild(string.format("Stage%02d", i))
		if stage then M.ApplyStage(stage, i) end
		task.wait()
	end
end
function M.Restore()
	local archive = Instance.new("Folder"); archive.Name = "ReferenceFinishArchived"
	archive.Parent = game.ServerStorage.Backups
	for _, stage in workspace.StageCourse:GetChildren() do
		for _, p in stage:GetDescendants() do
			if p:IsA("BasePart") then
				for property, value in p:GetAttributes() do
					if property:sub(1,#PREFIX) == PREFIX then
						local key = property:sub(#PREFIX+1)
						if key == "Material" then value = Enum.Material[value]
						elseif key == "TopSurface" then value = Enum.SurfaceType[value] end
						p[key] = value; p:SetAttribute(property,nil)
					end
				end
			end
		end
		local additions = stage:FindFirstChild("ReferenceEntranceFinish")
		if additions then additions.Parent = archive end
		stage:SetAttribute("ReferenceFinishVersion",nil)
		task.wait()
	end
end
return M
