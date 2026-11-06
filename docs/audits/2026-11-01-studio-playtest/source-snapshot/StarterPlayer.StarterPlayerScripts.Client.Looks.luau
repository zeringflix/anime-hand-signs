-- Client-only cosmetics: part-built original pets that follow their owner, and chakra auras.
-- Pets are never physics objects (anchored, no collision, moved in RenderStepped) -> cheap on mobile.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SC = require(game.ReplicatedStorage.Shared.SystemsConfig)

local L = {}
L.HideOthers = false
L.Reduced = false
local folder = Instance.new("Folder")
folder.Name = "PetVisuals"
folder.Parent = workspace

local function part(model: Model, size: Vector3, cf: CFrame, color: Color3, shape: Enum.PartType?, mat: Enum.Material?)
	local p = Instance.new("Part")
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Shape = shape or Enum.PartType.Block
	p.Material = mat or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = model
	return p
end

local function eyes(m: Model, head: CFrame, w: number, z: number)
	for _, s in {-1, 1} do
		part(m, Vector3.new(0.28, 0.36, 0.1), head * CFrame.new(s * w, 0.08, z), Color3.new(0.05, 0.05, 0.08))
		part(m, Vector3.new(0.1, 0.12, 0.05), head * CFrame.new(s * w + 0.05, 0.16, z - 0.05), Color3.new(1, 1, 1))
	end
end

-- builds around origin, facing -Z; returns model with PrimaryPart "Core"
function L.BuildPet(id: string): Model
	local def = SC.Pets[id]
	local m = Instance.new("Model")
	m.Name = id
	local c1, c2 = def and def.Color or Color3.new(1, 1, 1), def and def.Color2 or Color3.new(0.5, 0.5, 0.5)
	local shape = def and def.Shape or "cat"
	local core = part(m, Vector3.new(1.6, 1.3, 1.8), CFrame.new(0, 0, 0), c1)
	core.Name = "Core"
	m.PrimaryPart = core
	local head = CFrame.new(0, 0.9, -0.9)
	if shape == "cat" or shape == "dog" or shape == "fox" or shape == "wolf" then
		part(m, Vector3.new(1.5, 1.3, 1.3), head, c1)
		eyes(m, head, 0.35, -0.66)
		part(m, Vector3.new(0.5, 0.35, 0.3), head * CFrame.new(0, -0.3, -0.75), c2) -- muzzle
		local earH = (shape == "dog") and 0.5 or 0.7
		for _, s in {-1, 1} do
			local ear = part(m, Vector3.new(0.4, earH, 0.25), head * CFrame.new(s * 0.45, 0.85, 0) * CFrame.Angles(0, 0, s * (shape == "dog" and 0.9 or 0.25)), shape == "cat" and c2 or c1)
			ear.Name = "Ear"
			part(m, Vector3.new(0.35, 0.5, 0.35), CFrame.new(s * 0.5, -0.8, -0.55), c1)
			part(m, Vector3.new(0.35, 0.5, 0.35), CFrame.new(s * 0.5, -0.8, 0.55), c1)
		end
		local tails = (id == "KitsuneKit" or shape == "fox" and def.Rarity ~= "Rare") and 3 or 1
		for t = 1, tails do
			local a = (t - (tails + 1) / 2) * 0.45
			local tail = part(m, Vector3.new(0.45, 0.45, shape == "fox" and 1.6 or 1.1), CFrame.new(0, 0.4, 1.3) * CFrame.Angles(0.6, a, 0), shape == "fox" and c1 or c2)
			tail.Name = "Tail"
			if shape == "fox" then part(m, Vector3.new(0.4, 0.4, 0.5), tail.CFrame * CFrame.new(0, 0, 0.8), c2) end
		end
		if shape == "cat" and id == "NinjaCat" then part(m, Vector3.new(1.55, 0.25, 1.35), head * CFrame.new(0, 0.3, 0), c2) end -- headband
	elseif shape == "spirit" then
		core.Shape = Enum.PartType.Ball
		core.Size = Vector3.one * 1.8
		core.Material = Enum.Material.Neon
		core.Transparency = 0.25
		eyes(m, CFrame.new(0, 0.2, 0), 0.32, -0.88)
		local tail = part(m, Vector3.new(0.9, 0.9, 1.4), CFrame.new(0, -0.3, 1) * CFrame.Angles(0.5, 0, 0), c2, nil, Enum.Material.Neon)
		tail.Transparency = 0.4
		tail.Name = "Tail"
	elseif shape == "serpent" then
		core.Size = Vector3.new(1.1, 1.1, 1.1)
		local prev = CFrame.new(0, 0, 0)
		for i = 1, 5 do
			local seg = part(m, Vector3.new(1 - i * 0.12, 1 - i * 0.12, 1), CFrame.new(math.sin(i) * 0.5, -0.1 * i, i * 0.85), i % 2 == 0 and c2 or c1)
			seg.Name = "Tail"
		end
		local h = part(m, Vector3.new(1.3, 0.9, 1.4), CFrame.new(0, 0.5, -0.8), c1)
		eyes(m, h.CFrame, 0.35, -0.71)
		part(m, Vector3.new(0.15, 0.05, 0.6), h.CFrame * CFrame.new(0, -0.3, -0.9), Color3.fromRGB(220, 40, 60))
	elseif shape == "golem" then
		core.Size = Vector3.new(2, 1.8, 1.6)
		core.Material = Enum.Material.Slate
		local h = part(m, Vector3.new(1.3, 1, 1.2), CFrame.new(0, 1.35, -0.2), c1, nil, Enum.Material.Slate)
		for _, s in {-1, 1} do
			part(m, Vector3.new(0.3, 0.2, 0.1), h.CFrame * CFrame.new(s * 0.3, 0.1, -0.62), c2, nil, Enum.Material.Neon)
			part(m, Vector3.new(0.7, 1.6, 0.7), CFrame.new(s * 1.35, -0.1, -0.1), c1, nil, Enum.Material.Slate)
		end
	elseif shape == "toad" then
		core.Size = Vector3.new(2, 1.2, 1.9)
		for _, s in {-1, 1} do
			local e = part(m, Vector3.one * 0.7, CFrame.new(s * 0.6, 0.75, -0.55), c1, Enum.PartType.Ball)
			part(m, Vector3.one * 0.35, e.CFrame * CFrame.new(0, 0.05, -0.28), Color3.new(0.05, 0.05, 0.05), Enum.PartType.Ball)
			part(m, Vector3.new(0.7, 0.4, 0.9), CFrame.new(s * 0.9, -0.5, 0.4), c2)
		end
		part(m, Vector3.new(1.4, 0.1, 0.1), CFrame.new(0, -0.05, -0.96), c2)
		part(m, Vector3.new(2.05, 0.3, 1.2), CFrame.new(0, 0.25, 0.2), c2) -- vest stripe
	else -- dragon / beast
		core.Size = Vector3.new(1.5, 1.3, 2.2)
		local h = part(m, Vector3.new(1.3, 1.1, 1.5), CFrame.new(0, 0.9, -1.2), c1)
		eyes(m, h.CFrame, 0.35, -0.76)
		for _, s in {-1, 1} do
			part(m, Vector3.new(0.2, 0.8, 0.2), h.CFrame * CFrame.new(s * 0.4, 0.75, 0.3) * CFrame.Angles(-0.5, 0, s * 0.2), c2)
			if shape == "dragon" then
				local wing = part(m, Vector3.new(1.8, 0.12, 1.1), CFrame.new(s * 1.4, 0.5, 0) * CFrame.Angles(0, 0, s * 0.35), c2)
				wing.Name = s < 0 and "WingL" or "WingR"
			else
				part(m, Vector3.new(0.4, 0.6, 0.4), CFrame.new(s * 0.5, -0.85, -0.7), c1)
				part(m, Vector3.new(0.4, 0.6, 0.4), CFrame.new(s * 0.5, -0.85, 0.7), c1)
			end
		end
		local tail = part(m, Vector3.new(0.5, 0.5, 1.6), CFrame.new(0, 0.2, 1.7) * CFrame.Angles(0.3, 0, 0), c1)
		tail.Name = "Tail"
		if shape == "beast" then
			local glow = part(m, Vector3.one * 2.6, CFrame.new(), c2, Enum.PartType.Ball, Enum.Material.ForceField)
			glow.Transparency = 0.2
		end
	end
	local rarity = def and def.Rarity or "Common"
	if rarity == "Legendary" or rarity == "Mythic" or rarity == "Secret" then
		local att = Instance.new("Attachment")
		att.Parent = core
		local pe = Instance.new("ParticleEmitter")
		pe.Color = ColorSequence.new(SC.RarityColor[rarity] == Color3.new(0.12, 0.12, 0.12) and Color3.new(1, 1, 1) or SC.RarityColor[rarity])
		pe.LightEmission = 1
		pe.Size = NumberSequence.new(0.25, 0)
		pe.Lifetime = NumberRange.new(0.6, 1)
		pe.Rate = 6
		pe.Speed = NumberRange.new(1, 2)
		pe.SpreadAngle = Vector2.new(180, 180)
		pe.Parent = att
	end
	-- record offsets so the whole model can be moved rigidly every frame
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then d:SetAttribute("Off", core.CFrame:ToObjectSpace(d.CFrame)) end
	end
	return m
end

local function placeRigid(m: Model, cf: CFrame, t: number, flying: boolean)
	for _, d in m:GetChildren() do
		if d:IsA("BasePart") then
			local off = d:GetAttribute("Off") :: CFrame
			if off then
				if d.Name == "Tail" then off = CFrame.Angles(0, math.sin(t * 6) * 0.25, 0) * off end
				if d.Name == "WingL" or d.Name == "WingR" then
					local s = d.Name == "WingL" and -1 or 1
					off = CFrame.Angles(0, 0, s * math.sin(t * 9) * 0.5) * off
				end
				d.CFrame = cf * off
			end
		end
	end
end

---------------------------------------------------------------- pet followers
local states: {[Player]: {key: string, pets: {{model: Model, cf: CFrame, flying: boolean}}}} = {}

local function rebuild(p: Player)
	local st = states[p]
	if st then for _, e in st.pets do e.model:Destroy() end end
	local key = p:GetAttribute("PetsShown") or ""
	st = {key = key, pets = {}}
	states[p] = st
	if key == "" then return end
	if L.HideOthers and p ~= Players.LocalPlayer then return end
	for _, id in string.split(key, ",") do
		if #st.pets >= 6 then break end
		local def = SC.Pets[id]
		if def then
			local m = L.BuildPet(id)
			m.Parent = folder
			table.insert(st.pets, {model = m, cf = CFrame.new(), flying = def.Shape == "dragon" or def.Shape == "spirit"})
		end
	end
end

---------------------------------------------------------------- auras
local auraFx: {[Player]: {key: string, inst: Instance?}} = {}
local function setAura(p: Player)
	local key = p:GetAttribute("Aura") or ""
	local cur = auraFx[p]
	local char = p.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if cur and cur.key == key and cur.inst and cur.inst.Parent then return end
	if cur and cur.inst then cur.inst:Destroy() end
	auraFx[p] = {key = key}
	local a = SC.Auras[key]
	if not a or not root then return end
	if L.Reduced and p ~= Players.LocalPlayer then return end
	local att = Instance.new("Attachment")
	att.Name = "AuraFx"
	att.Position = Vector3.new(0, -1.5, 0)
	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(a.Color, a.Color2)
	pe.LightEmission = a.Id == "Cursed" and 0 or 0.9
	pe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1)})
	pe.Lifetime = NumberRange.new(0.6, 1.1)
	pe.Rate = 28
	pe.LockedToPart = false
	if a.Style == "flame" then
		pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0)})
		pe.Speed = NumberRange.new(5, 8)
		pe.Acceleration = Vector3.new(0, 6, 0)
		pe.SpreadAngle = Vector2.new(25, 25)
		pe.EmissionDirection = Enum.NormalId.Top
	elseif a.Style == "petals" then
		pe.Size = NumberSequence.new(0.35)
		pe.Speed = NumberRange.new(3, 5)
		pe.RotSpeed = NumberRange.new(-180, 180)
		pe.Rotation = NumberRange.new(0, 360)
		pe.SpreadAngle = Vector2.new(180, 30)
		pe.Acceleration = Vector3.new(0, 2, 0)
	elseif a.Style == "sparks" then
		pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0)})
		pe.Speed = NumberRange.new(8, 14)
		pe.SpreadAngle = Vector2.new(180, 180)
		pe.Rate = 40
	else -- swirl
		pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0.2)})
		pe.Speed = NumberRange.new(2, 4)
		pe.Acceleration = Vector3.new(0, 4, 0)
		pe.SpreadAngle = Vector2.new(180, 10)
		pe.RotSpeed = NumberRange.new(200, 300)
	end
	pe.Parent = att
	local light = Instance.new("PointLight")
	light.Color = a.Color
	light.Range = 9
	light.Brightness = 1.2
	light.Parent = att
	att.Parent = root
	auraFx[p].inst = att
end

function L.Refresh()
	for _, p in Players:GetPlayers() do rebuild(p); setAura(p) end
end

local function hook(p: Player)
	p:GetAttributeChangedSignal("PetsShown"):Connect(function() rebuild(p) end)
	p:GetAttributeChangedSignal("Aura"):Connect(function() setAura(p) end)
	p.CharacterAdded:Connect(function() task.wait(0.5); auraFx[p] = nil; setAura(p) end)
	rebuild(p)
	task.defer(setAura, p)
end

function L.Start()
	for _, p in Players:GetPlayers() do hook(p) end
	Players.PlayerAdded:Connect(hook)
	Players.PlayerRemoving:Connect(function(p)
		local st = states[p]
		if st then for _, e in st.pets do e.model:Destroy() end end
		states[p] = nil
		auraFx[p] = nil
	end)
	RunService.RenderStepped:Connect(function(dt)
		local t = os.clock()
		local camPos = workspace.CurrentCamera.CFrame.Position
		for p, st in states do
			local char = p.Character
			local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root and #st.pets > 0 then
				local far = (root.Position - camPos).Magnitude > 180
				local n = #st.pets
				for i, e in st.pets do
					-- arc behind the owner
					local ang = (i - (n + 1) / 2) * 0.7
					local off = Vector3.new(math.sin(ang) * 6, 0, math.cos(ang) * 6 + 1)
					local goalPos = (root.CFrame * CFrame.new(off)).Position
					local ground = root.Position.Y - 2.2
					local moving = (Vector3.new(goalPos.X, 0, goalPos.Z) - Vector3.new(e.cf.X, 0, e.cf.Z)).Magnitude > 0.6
					local y = e.flying and (ground + 3 + math.sin(t * 2 + i) * 0.5) or (ground + (moving and math.abs(math.sin(t * 10 + i)) * 0.9 or 0))
					local target = Vector3.new(goalPos.X, y, goalPos.Z)
					local pos = e.cf.Position:Lerp(target, math.min(1, dt * 8))
					if (pos - target).Magnitude > 40 then pos = target end
					local look = root.CFrame.LookVector
					e.cf = CFrame.lookAt(pos, pos + Vector3.new(look.X, 0, look.Z))
					if not far then placeRigid(e.model, e.cf, t + i, e.flying) end
				end
			end
		end
	end)
end

return L

