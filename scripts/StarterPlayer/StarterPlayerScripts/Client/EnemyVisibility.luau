--!strict
-- EnemyVisibility (client): each player only sees their OWN stage enemies.
-- Enemies are server-simulated per player (EnemyService, OwnerId attribute). Every client hides enemies that
-- belong to someone else: parts, decals, health bars and particles are locally invisible, so two players in the
-- same stage never see (or click on) each other's enemies. Purely visual; the server also refuses hits on them.
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local M = {}

local function hideInstance(d: Instance)
	if d:IsA("BasePart") then
		d.LocalTransparencyModifier = 1
		d.CanQuery = false
	elseif d:IsA("Decal") then
		d.LocalTransparencyModifier = 1
	elseif d:IsA("BillboardGui") or d:IsA("SurfaceGui") then
		d.Enabled = false
	elseif d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") then
		d.Enabled = false
	elseif d:IsA("Light") then
		d.Enabled = false
	elseif d:IsA("Highlight") then
		d.Enabled = false
	end
end

local function isMine(m: Instance): boolean
	local owner = m:GetAttribute("OwnerId")
	return owner == nil or owner == player.UserId -- no owner = shared (e.g. a future world boss)
end
M.IsMine = isMine

local function watch(m: Instance)
	local function apply()
		if isMine(m) then return end
		for _, d in m:GetDescendants() do hideInstance(d) end
	end
	apply()
	m.DescendantAdded:Connect(function(d)
		if not isMine(m) then hideInstance(d) end
	end)
	m:GetAttributeChangedSignal("OwnerId"):Connect(apply)
end

function M.Init()
	local folder = workspace:WaitForChild("Enemies")
	for _, m in folder:GetChildren() do watch(m) end
	folder.ChildAdded:Connect(watch)
end

return M
