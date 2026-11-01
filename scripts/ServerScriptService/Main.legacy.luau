-- Server bootstrap: one entry point, explicit start order.
local Players = game:GetService("Players")
local Services = script.Parent:WaitForChild("Services")
local DataService = require(Services.DataService)
local GameService = require(Services.GameService)
local EnemyService = require(Services.EnemyService)
local AbilityService = require(Services.AbilityService)
local SystemsService = Services:FindFirstChild("SystemsService") and require(Services.SystemsService)

GameService.Start()
EnemyService.Start()
AbilityService.Start()
if SystemsService then SystemsService.Start() end
DataService.Start() -- last: loads players once every OnLoaded hook is registered

-- trophy pads: touching claims the stage-clear reward (server validates pending state)
local course = workspace:WaitForChild("StageCourse")
local padDebounce: {[Player]: number} = {}
for _, stage in course:GetChildren() do
	local pad = stage:FindFirstChild("TrophyPad")
	if pad then
		pad.Touched:Connect(function(hit)
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if not player then return end
			if os.clock() - (padDebounce[player] or 0) < 0.5 then return end
			padDebounce[player] = os.clock()
			GameService.ClaimPad(player, pad:GetAttribute("Stage"))
		end)
	end
end
Players.PlayerRemoving:Connect(function(p) padDebounce[p] = nil end)

-- player health scales with level
Players.PlayerAdded:Connect(function(p)
	p.CharacterAdded:Connect(function(c)
		local hum = c:WaitForChild("Humanoid")
		local lvl = p:GetAttribute("Level") or 1
		hum.MaxHealth = 100 + lvl * 10
		hum.Health = hum.MaxHealth
	end)
end)
