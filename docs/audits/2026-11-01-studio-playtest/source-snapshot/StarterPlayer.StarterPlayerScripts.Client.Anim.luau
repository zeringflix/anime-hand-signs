-- Procedural R15 poses (no uploaded animation ids needed): hand-seal training poses, punches,
-- casting gestures for every player, and walk/attack motion for stage NPCs. Runs after the Animator each frame.
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local A = {}

-- per-sign seal pose: {right shoulder, left shoulder, right elbow, left elbow} as Euler (x, y, z)
local SEALS = {
	tiger = {{1.35, 0, -0.55}, {1.35, 0, 0.55}, {0.5, 0, 0}, {0.5, 0, 0}},       -- index+middle fingers up, hands pressed
	ram = {{1.2, 0, -0.65}, {1.2, 0, 0.65}, {0.9, 0, 0}, {0.9, 0, 0}},
	snake = {{1.0, 0.2, -0.7}, {1.0, -0.2, 0.7}, {1.2, 0, 0}, {1.2, 0, 0}},     -- clasped low
	rat = {{1.5, 0, -0.4}, {1.2, 0, 0.8}, {0.3, 0, 0}, {1.0, 0, 0}},
	ox = {{1.3, 0.3, -0.7}, {1.0, -0.3, 0.5}, {0.8, 0, 0}, {1.2, 0, 0}},
	hare = {{1.6, 0, -0.3}, {0.9, 0, 0.7}, {0.2, 0, 0}, {1.3, 0, 0}},
	horse = {{1.7, 0, -0.5}, {1.7, 0, 0.5}, {0.6, 0, 0}, {0.6, 0, 0}},         -- raised triangle
	boar = {{1.1, 0, -0.6}, {1.1, 0, 0.6}, {1.0, 0, 0}, {1.0, 0, 0}},
	dog = {{0.9, 0, -0.5}, {1.3, 0, 0.6}, {1.4, 0, 0}, {0.6, 0, 0}},
	bird = {{1.9, 0, -0.6}, {1.9, 0, 0.6}, {0.4, 0, 0}, {0.4, 0, 0}},
	monkey = {{1.4, -0.2, -0.5}, {1.4, 0.2, 0.5}, {0.7, 0, 0}, {0.7, 0, 0}},
	dragon = {{2.1, 0, -0.45}, {2.1, 0, 0.45}, {0.2, 0, 0}, {0.2, 0, 0}},
	advanced = {{1.6, 0.3, -0.5}, {1.2, -0.3, 0.6}, {0.7, 0, 0}, {1.0, 0, 0}},
	forbidden = {{2.3, 0.2, -0.3}, {2.3, -0.2, 0.3}, {0.1, 0, 0}, {0.1, 0, 0}},
}
A.SealFor = function(signId)
	local Config = require(game.ReplicatedStorage.Shared.Config)
	local s = Config.HandSigns[signId]
	return SEALS[s and s.Pose or "tiger"] or SEALS.tiger
end

local localTrainAt = 0
function A.Train() localTrainAt = os.clock() end

local function motors(char)
	local m = char:GetAttribute("_m") and nil
	local function f(partName, motorName)
		local p = char:FindFirstChild(partName)
		return p and p:FindFirstChild(motorName)
	end
	return f("RightUpperArm", "RightShoulder"), f("LeftUpperArm", "LeftShoulder"), f("RightLowerArm", "RightElbow"), f("LeftLowerArm", "LeftElbow"),
		f("RightUpperLeg", "RightHip"), f("LeftUpperLeg", "LeftHip"), f("UpperTorso", "Waist")
end
local function e(v, k) return CFrame.Angles(v[1] * k, v[2] * k, v[3] * k) end

local function poseCharacter(char, now, serverNow, isLocal)
	local rs, ls, re, le, rh, lh, waist = motors(char)
	if not rs or not ls then return end
	local castAt = char:GetAttribute("CastAt") or 0
	local punchAt = char:GetAttribute("PunchAt") or 0
	local sinceCast = serverNow - castAt
	local sincePunch = serverNow - punchAt
	local player = Players:GetPlayerFromCharacter(char)
	local sign = player and player:GetAttribute("Equipped") or "Tiger"
	if sinceCast >= 0 and sinceCast < 0.7 then
		-- quick seal, then thrust the casting arm forward
		local seal = A.SealFor(sign)
		if sinceCast < 0.3 then
			local k = math.min(sinceCast / 0.12, 1)
			rs.Transform = e(seal[1], k); ls.Transform = e(seal[2], k)
			if re then re.Transform = e(seal[3], k) end; if le then le.Transform = e(seal[4], k) end
		else
			local k = 1 - math.clamp((sinceCast - 0.45) / 0.25, 0, 1)
			rs.Transform = CFrame.Angles(1.55 * k, 0, 0); if re then re.Transform = CFrame.new() end
			ls.Transform = CFrame.Angles(0.4 * k, 0, 0.3 * k)
			if waist then waist.Transform = CFrame.Angles(0, 0.35 * k, 0) end
		end
		return
	end
	if sincePunch >= 0 and sincePunch < 0.28 then
		local right = math.floor(punchAt * 10) % 2 == 0
		local k = math.sin(math.clamp(sincePunch / 0.28, 0, 1) * math.pi)
		local arm = right and rs or ls
		arm.Transform = CFrame.Angles(1.6 * k, 0, 0)
		if waist then waist.Transform = CFrame.Angles(0, (right and 0.4 or -0.4) * k, 0) end
		return
	end
	if isLocal and now - localTrainAt < 0.22 then
		local seal = A.SealFor(sign)
		local k = math.sin(math.clamp((now - localTrainAt) / 0.22, 0, 1) * math.pi)
		k = math.max(k, 0.85)
		rs.Transform = e(seal[1], k); ls.Transform = e(seal[2], k)
		if re then re.Transform = e(seal[3], k) end; if le then le.Transform = e(seal[4], k) end
	end
end

local function poseNpc(model, now, serverNow)
	local rs, ls, re, le, rh, lh = motors(model)
	local root = model:FindFirstChild("HumanoidRootPart")
	if not rs or not root or not rh or not lh then return end
	if (model:GetAttribute("RootedUntil") or 0) > serverNow then
		rs.Transform = CFrame.Angles(0, 0, 0.15); ls.Transform = CFrame.Angles(0, 0, -0.15)
		return
	end
	local attack = serverNow - (model:GetAttribute("AttackAt") or model:GetAttribute("PunchAt") or 0)
	local v = root.AssemblyLinearVelocity
	local speed = Vector3.new(v.X, 0, v.Z).Magnitude
	local swing = math.min(speed / 14, 1) * math.sin(now * 11) * 0.8
	local idle = math.sin(now * 2.2) * 0.05
	rh.Transform = CFrame.Angles(swing, 0, 0)
	lh.Transform = CFrame.Angles(-swing, 0, 0)
	if attack >= 0 and attack < 0.35 then
		local k = math.sin(attack / 0.35 * math.pi)
		rs.Transform = CFrame.Angles(1.7 * k, 0, 0)
		ls.Transform = CFrame.Angles(-0.4 * k, 0, 0)
	else
		rs.Transform = CFrame.Angles(-swing + idle, 0, 0.05)
		ls.Transform = CFrame.Angles(swing + idle, 0, -0.05)
		if re then re.Transform = CFrame.Angles(0.35, 0, 0) end
		if le then le.Transform = CFrame.Angles(0.35, 0, 0) end
	end
end

function A.Start()
	local enemies = workspace:WaitForChild("Enemies")
	RunService.PreSimulation:Connect(function()
		local now = os.clock()
		local serverNow = workspace:GetServerTimeNow()
		local cam = workspace.CurrentCamera
		local camPos = cam and cam.CFrame.Position or Vector3.zero
		for _, p in Players:GetPlayers() do
			local c = p.Character
			if c then poseCharacter(c, now, serverNow, p == Players.LocalPlayer) end
		end
		for _, m in enemies:GetChildren() do
			local r = m:FindFirstChild("HumanoidRootPart")
			if r and (r.Position - camPos).Magnitude < 140 then poseNpc(m, now, serverNow) end -- animation LOD
		end
		for _, m in workspace:GetChildren() do
			if m:GetAttribute("IsClone") then poseNpc(m, now, serverNow) end
		end
	end)
end

return A

