--!strict
-- Lobby (client, issue #14): per-player state for Workspace.Lobby + ProximityPrompt routing.
-- Display only. Every action goes through EXISTING server-validated remotes:
--   Sign pad  -> EquipSign (if owned) / Action "BuySign" (server checks stage + Hand Signs + Trophies)
--   Training  -> Train (server rate-limited)    Egg -> Action "Hatch"    Shrines/Portal -> open menus
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Menus = require(script.Parent:WaitForChild("Menus"))
local U = require(script.Parent:WaitForChild("UIKit"))
local Sfx = require(script.Parent:WaitForChild("Sfx"))

local player = Players.LocalPlayer
local C = Color3.fromRGB
local M = {}
local ctx: any

local STATE = {
	Equipped = {Color = C(80, 225, 110), Text = "EQUIPPED", Action = "Equipped"},
	Owned = {Color = C(255, 225, 50), Text = "OWNED", Action = "Equip"},
	Ready = {Color = C(255, 60, 60), Text = "", Action = "Buy"},
	Locked = {Color = C(200, 40, 50), Text = "", Action = "Buy"},
}
local GOOD, BAD = C(140, 255, 150), C(255, 130, 130)

local function attr(n: string): any return player:GetAttribute(n) end
local function owns(id: string): boolean
	local p = ctx and ctx.Profile
	if id == "Tiger" then return true end
	return p ~= nil and p.Unlocked ~= nil and p.Unlocked[id] == true
end
local function stateOf(id: string): string
	local s = Config.HandSigns[id]
	if owns(id) then return (attr("Equipped") or "Tiger") == id and "Equipped" or "Owned" end
	return (attr("Trophies") or 0) >= s.Price and "Ready" or "Locked" -- trophies only (owner 2026-11-02)
end

local lastSig: {[Instance]: string} = {}
local function updatePad(m: Instance)
	local id = m:GetAttribute("SignId")
	local s = id and Config.HandSigns[id]
	if not s then return end
	local st = stateOf(id)
	local priceOk = (attr("Trophies") or 0) >= s.Price
	local sig = st .. tostring(priceOk)
	if lastSig[m] == sig then return end
	lastSig[m] = sig
	local info = STATE[st]
	local pad = m:FindFirstChild("Pad") :: BasePart?
	if pad then
		pad.Color = info.Color
		pad.Material = Enum.Material.Neon
		local pp = pad:FindFirstChildOfClass("ProximityPrompt")
		if pp then
			pp.ActionText = (st == "Ready" or st == "Locked") and ("Buy  🏆 " .. Config.Format(s.Price)) or info.Action
			pp.Enabled = st ~= "Equipped"
		end
	end
	local card = m:FindFirstChild("Anchor") and (m :: any).Anchor:FindFirstChild("Card")
	if card then
		-- Anime Eyes text stack: name / xN / trophy price (green if affordable) or EQUIPPED (green) / OWNED (yellow)
		local status = card:FindFirstChild("Status") :: TextLabel?
		local priceIcon = card:FindFirstChild("PriceIcon") :: ImageLabel?
		if status then
			local buying = st == "Ready" or st == "Locked"
			if priceIcon then priceIcon.Visible = buying end
			if buying then
				status.Text = Config.Format(s.Price)
				status.TextColor3 = priceOk and GOOD or BAD
				status.Position = UDim2.fromScale(priceIcon and 0.36 or 0.05, 0.75)
				status.Size = UDim2.fromScale(priceIcon and 0.5 or 0.9, 0.25)
			else
				status.Text = st == "Equipped" and "EQUIPPED" or "OWNED"
				status.Font = Enum.Font.LuckiestGuy
				status.TextColor3 = info.Color
				status.Position = UDim2.fromScale(0.05, 0.75)
				status.Size = UDim2.fromScale(0.9, 0.25)
			end
		end
	end
end

local function onPrompt(prompt: ProximityPrompt)
	local action = prompt:GetAttribute("LobbyAction")
	if action == "Sign" then
		local id = prompt:GetAttribute("SignId")
		local s = typeof(id) == "string" and Config.HandSigns[id]
		if not s then return end
		if owns(id) then
			ctx.EquipSign:FireServer(id)
			ctx.Toast(string.upper(s.Name) .. " EQUIPPED", C(120, 255, 140))
		else
			local res = Menus.Act("BuySign", id)
			if res and res.ok and res.bought then ctx.Toast(s.Emblem .. " " .. string.upper(s.Name) .. " UNLOCKED!", C(120, 255, 140)) end
		end
	elseif action == "Train" then
		local r = ReplicatedStorage:FindFirstChild("Remotes")
		local train = r and r:FindFirstChild("Train") :: RemoteEvent?
		if train then train:FireServer(1) end
	elseif action == "Hatch" then
		local eggId = prompt:GetAttribute("EggId")
		local res = Menus.Act("Hatch", eggId)
		if res and res.ok and ctx.HatchAnimation then ctx.HatchAnimation(eggId, res.pet) end
	elseif action == "Product" then
		-- Robux pet / item: server prompts the developer product (or answers "Not available yet" while Id = 0)
		local key = prompt:GetAttribute("Product")
		if typeof(key) == "string" then Menus.Act("BuyProduct", key) end
	elseif action == "Pass" then
		-- Robux training zone: server prompts the real game pass (or answers "Not available yet" while Id = 0)
		local key = prompt:GetAttribute("Pass")
		if typeof(key) == "string" then Menus.Act("BuyPass", key) end
	elseif action == "Menu" then
		local menu = prompt:GetAttribute("Menu")
		if typeof(menu) == "string" then Menus.Open(menu) end
	end
end

local function updateBoards(lobby: Instance)
	local holder = ReplicatedStorage:FindFirstChild("LeaderboardData") :: StringValue?
	if not holder or holder.Value == "" then return end
	local ok, data = pcall(HttpService.JSONDecode, HttpService, holder.Value)
	if not ok or type(data) ~= "table" then return end
	local boards = lobby:FindFirstChild("Leaderboards")
	if not boards then return end
	for _, m in boards:GetChildren() do
		local key = m:GetAttribute("BoardKey")
		local list = key and data[key]
		local panel = m:FindFirstChild("Panel")
		local gui = panel and panel:FindFirstChild("BoardGui")
		if gui and type(list) == "table" then
			for r = 1, 8 do
				local row = gui:FindFirstChild("Row" .. r) :: TextLabel?
				local e = list[r]
				if row then row.Text = e and string.format("%d. %s  —  %s", r, tostring(e.Name), Config.Format(tonumber(e.Value) or 0)) or "" end
			end
		end
	end
end

function M.Init(c: any)
	ctx = c
	ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, who: Player)
		if who == player and prompt:IsDescendantOf(workspace) and prompt:GetAttribute("LobbyAction") then onPrompt(prompt) end
	end)
	task.spawn(function()
		local lobby = workspace:WaitForChild("Lobby", 30)
		if not lobby then return end
		local showcase = lobby:WaitForChild("SignShowcase", 10)
		-- chakra orb halo spin (only while near the lobby)
		local halo = lobby:FindFirstChild("Halo", true) :: Model?
		if halo then
			local base = halo:GetPivot()
			local t = 0
			RunService.RenderStepped:Connect(function(dt)
				local char = player.Character
				local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
				if not root or (root.Position - base.Position).Magnitude > 260 then return end
				t += dt
				halo:PivotTo(base * CFrame.Angles(0, t * 0.9, 0) * CFrame.new(0, math.sin(t * 2) * 0.4, 0))
			end)
		end
		-- eggs slowly turn and bob on their pedestals (client-only visual)
		local spinners: {{any}} = {}
		for _, d in lobby:GetDescendants() do
			if d:IsA("Model") and d:GetAttribute("Spin") then table.insert(spinners, {d, d:GetPivot()}) end
		end
		if #spinners > 0 then
			local t = 0
			RunService.RenderStepped:Connect(function(dt)
				local char = player.Character
				local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
				if not root or (root.Position - spinners[1][2].Position).Magnitude > 300 then return end
				t += dt
				for i, s in spinners do
					local kind = s[1]:GetAttribute("Spin")
					if kind == "portal" then
						s[1]:PivotTo(s[2] * CFrame.Angles(t * 1.2, 0, 0)) -- WORLDS ring turns about its own axis
					elseif kind == "portalZ" then
						s[1]:PivotTo(s[2] * CFrame.Angles(0, 0, t * 1.2))
					elseif kind == "y" then -- Blender station spinners (halo rings, gems)
						s[1]:PivotTo(s[2] * CFrame.Angles(0, t * 0.9, 0))
					elseif kind == "bob" then -- Blender station floaters (orbs, rocks, clouds)
						s[1]:PivotTo(s[2] * CFrame.new(0, math.sin(t * 1.8 + i) * 0.45, 0))
					else
						s[1]:PivotTo(s[2] * CFrame.new(0, math.sin(t * 1.6 + i) * 0.35, 0) * CFrame.Angles(0, t * 0.6, 0))
					end
				end
			end)
		end
		-- Robux prices / names flagged by the builder get the animated rainbow text
		for _, d in lobby:GetDescendants() do
			if d:IsA("TextLabel") and d:GetAttribute("Rainbow") then U.rainbow(d) end
		end
		-- edit-time-built billboard text sometimes never lays out (TextBounds stay 0) until its Text changes once:
		-- nudge every lobby label so all signs render (seen on the egg cards)
		task.delay(1, function()
			for _, d in lobby:GetDescendants() do
				if d:IsA("TextLabel") and d.Text ~= "" and d.TextBounds.X == 0 then
					local t = d.Text
					d.Text = t .. " "
					task.defer(function() d.Text = t end)
				end
			end
		end)
		-- WORLDS portal: walking into it opens the Worlds menu (a brand-new player goes straight to Stage 1)
		local portal = lobby:FindFirstChild("WorldsPortal")
		local core = portal and portal:FindFirstChild("Core") :: BasePart?
		if core then
			local last = 0
			core.Touched:Connect(function(hit)
				local char = player.Character
				if not char or not hit:IsDescendantOf(char) or os.clock() - last < 2.5 then return end
				last = os.clock()
				Sfx.Play("Teleport")
				if (attr("Highest") or 1) <= 1 then
					ctx.TeleportStage:FireServer(1)
				else
					Menus.Open("Stages")
				end
			end)
		end
		local boardTick = 0
		while lobby.Parent do
			if showcase then
				for _, m in showcase:GetChildren() do
					if m:GetAttribute("SignId") then updatePad(m) end
				end
			end
			boardTick += 1
			if boardTick % 20 == 1 then updateBoards(lobby) end
			task.wait(0.5)
		end
	end)
end

return M
