-- Non-destructive presentation pass: keep the existing world and artwork intact.
-- Applies locally on join, including streamed-in stage pieces. No economy changes.
local Lighting = game:GetService("Lighting")
local Config = require(game.ReplicatedStorage.Shared.Config)
local Presentation = {}

function Presentation.Start()
	-- Keep the vivid simulator palette while retaining surface shading around glow effects.
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
	if bloom then bloom.Intensity = 0.12; bloom.Size = 12; bloom.Threshold = 2 end
	local grade = Lighting:FindFirstChild("StageGrade")
	if grade then grade.Saturation = 0.06; grade.Brightness = 0; grade.Contrast = 0.06 end
	Lighting.ExposureCompensation = -0.1

	local function dressLobby(obj: Instance)
		if obj:IsA("PointLight") then
			obj.Brightness = math.min(obj.Brightness, 0.6)
			obj.Range = math.min(obj.Range, 16)
		elseif obj:IsA("BillboardGui") and (obj.Name == "Card" or obj.Name == "Emblem") then
			-- Showcase labels remain readable nearby instead of filling the distant skyline.
			obj.MaxDistance = math.min(obj.MaxDistance > 0 and obj.MaxDistance or 65, 65)
		end
	end
	local function dressStage(obj: Instance)
		if not obj:IsA("BasePart") or obj.Name ~= "StartWall" then return end
		local stage = obj.Parent
		local index = stage and tonumber(stage.Name:match("^Stage(%d+)$"))
		local theme = index and Config.Stages[index]
		if theme and not stage:GetAttribute("ReferenceFinishVersion") then
			-- Retain the collision wall; blend its raw red face into the biome's cliff palette.
			obj.Color = theme.Cliff
			obj.Material = Enum.Material.Slate
		end
	end
	local lobby = workspace:WaitForChild("Lobby", 10)
	if lobby then
		lobby.DescendantAdded:Connect(dressLobby)
		for i, obj in lobby:GetDescendants() do dressLobby(obj); if i % 500 == 0 then task.wait() end end
	end
	local course = workspace:WaitForChild("StageCourse", 10)
	if course then
		course.DescendantAdded:Connect(dressStage)
		for _, stage in course:GetChildren() do
			-- Entrance gates split StartWall into two siblings with the same name.
			for _, piece in stage:GetChildren() do dressStage(piece) end
		end
	end
end

return Presentation
