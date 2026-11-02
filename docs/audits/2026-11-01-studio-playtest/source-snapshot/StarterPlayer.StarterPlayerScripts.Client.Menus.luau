-- Menu panels: Hand Signs, Pets, Auras, Upgrades, Rebirth, Stages, Rewards, Codes, Shop, Top, Settings.
-- Panels only display state and ask the server (Action remote); nothing here grants anything.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Config = require(ReplicatedStorage.Shared.Config)
local SC = require(ReplicatedStorage.Shared.SystemsConfig)
local U = require(script.Parent.UIKit)
local Looks = require(script.Parent.Looks)

local M = {}
local ctx: any
local player = Players.LocalPlayer
local fmt = Config.Format
local C = Color3.fromRGB

local root: Frame
local titleLabel: TextLabel
local body: ScrollingFrame
local current: string? = nil
local builders: {[string]: (ScrollingFrame) -> ()} = {}

M.Tabs = {
	{Id = "Signs", Label = "SIGNS", Icon = "\u{1F590}", Color = C(255, 120, 40)},
	{Id = "Pets", Label = "PETS", Icon = "\u{1F95A}", Color = C(255, 190, 60)},
	{Id = "Auras", Label = "AURAS", Icon = "\u{2728}", Color = C(90, 170, 255)},
	{Id = "Upgrades", Label = "UPGRADES", Icon = "\u{2B06}", Color = C(80, 210, 110)},
	{Id = "Rebirth", Label = "REBIRTH", Icon = "\u{267B}", Color = C(190, 90, 255)},
	{Id = "Stages", Label = "STAGES", Icon = "\u{1F5FA}", Color = C(60, 200, 200)},
	{Id = "Rewards", Label = "REWARDS", Icon = "\u{1F381}", Color = C(255, 80, 130)},
	{Id = "Shop", Label = "SHOP", Icon = "\u{1F6D2}", Color = C(255, 210, 50)},
	{Id = "Top", Label = "TOP", Icon = "\u{1F451}", Color = C(240, 170, 40)},
	{Id = "Codes", Label = "CODES", Icon = "\u{1F511}", Color = C(140, 140, 255)},
	{Id = "Settings", Label = "SETTINGS", Icon = "\u{2699}", Color = C(150, 150, 160)},
}

---------------------------------------------------------------- helpers
local function grid(parent: Instance, cell: UDim2, pad: number?)
	U.new("UIGridLayout", {CellSize = cell, CellPadding = UDim2.fromOffset(pad or 10, pad or 10), SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = parent})
end
local function list(parent: Instance, pad: number?)
	U.new("UIListLayout", {Padding = UDim.new(0, pad or 8), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = parent})
end
local function card(parent: Instance, color: Color3, order: number?): Frame
	local f = U.new("Frame", {BackgroundColor3 = color, LayoutOrder = order or 0, Parent = parent})
	U.corner(12).Parent = f
	U.stroke(3, U.shade(color, 0.4), Enum.ApplyStrokeMode.Border).Parent = f
	U.grad(Color3.new(1, 1, 1), Color3.fromRGB(200, 200, 200)).Parent = f
	return f
end
local function label(parent: Instance, text: string, pos: UDim2, size: UDim2, color: Color3?, xa: Enum.TextXAlignment?, stroke: number?)
	return U.text({Text = text, Position = pos, Size = size, TextColor3 = color or Color3.new(1, 1, 1), TextXAlignment = xa or Enum.TextXAlignment.Center, Stroke = stroke or 2, Parent = parent})
end
local function act(kind: string, ...: any)
	local ok, res = pcall(ctx.Action.InvokeServer, ctx.Action, kind, ...)
	if not ok or type(res) ~= "table" then ctx.Toast("Try again", C(255, 90, 90)); return nil end
	if res.ok == false and res.msg then ctx.Toast(res.msg, C(255, 90, 90)) end
	return res
end
M.Act = act
local function prof() return ctx.Profile end
local function attr(n: string) return player:GetAttribute(n) end

---------------------------------------------------------------- panel shell
function M.Init(c)
	ctx = c
	root = U.new("Frame", {Name = "Panel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.62, 0.72),
		BackgroundColor3 = C(45, 40, 70), Visible = false, Parent = c.Gui, ZIndex = 5})
	U.new("UISizeConstraint", {MinSize = Vector2.new(340, 300), MaxSize = Vector2.new(920, 640), Parent = root})
	U.corner(18).Parent = root
	U.stroke(5, C(20, 15, 35), Enum.ApplyStrokeMode.Border).Parent = root
	U.grad(C(70, 62, 110), C(38, 33, 60)).Parent = root
	local header = U.new("Frame", {Size = UDim2.new(1, 0, 0, 58), BackgroundColor3 = C(255, 170, 40), Parent = root})
	U.corner(18).Parent = header
	U.new("Frame", {Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 1, -20), BorderSizePixel = 0, BackgroundColor3 = C(255, 170, 40), Parent = header})
	header:FindFirstChildOfClass("Frame").Name = "HeaderFill"
	U.grad(Color3.new(1, 1, 1), C(200, 200, 200)).Parent = header
	titleLabel = label(header, "", UDim2.fromOffset(18, 8), UDim2.new(1, -90, 1, -16), nil, Enum.TextXAlignment.Left, 3)
	local close = U.button({Text = "X", Color = C(235, 60, 60), Size = UDim2.fromOffset(46, 46), Position = UDim2.new(1, -8, 0, 6), AnchorPoint = Vector2.new(1, 0), Parent = header})
	close.MouseButton1Click:Connect(function() M.Close() end)
	body = U.new("ScrollingFrame", {Position = UDim2.fromOffset(12, 68), Size = UDim2.new(1, -24, 1, -80), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 8, ScrollBarImageColor3 = C(255, 200, 80), AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Parent = root})
end

function M.IsOpen() return root.Visible end

function M.Open(id: string)
	if current == id and root.Visible then M.Close(); return end
	current = id
	for _, t in M.Tabs do
		if t.Id == id then
			titleLabel.Text = t.Icon .. "  " .. (t.Id == "Signs" and "HAND SIGNS" or t.Label)
			root:FindFirstChild("Frame").BackgroundColor3 = t.Color
			root.Frame.HeaderFill.BackgroundColor3 = t.Color
		end
	end
	root.Visible = true
	U.pop(root, 0.8)
	M.Refresh()
end

function M.Close()
	root.Visible = false
	current = nil
end

function M.Refresh()
	if not root.Visible or not current then return end
	local y = body.CanvasPosition
	for _, ch in body:GetChildren() do ch:Destroy() end
	local b = builders[current]
	if b then b(body) end
	body.CanvasPosition = y
end

---------------------------------------------------------------- HAND SIGNS
builders.Signs = function(parent)
	grid(parent, UDim2.fromOffset(250, 210), 12)
	local p = prof()
	local unlocked = p and p.Unlocked or {Tiger = true}
	local equipped = attr("Equipped") or "Tiger"
	for i, id in Config.HandSignOrder do
		local s = Config.HandSigns[id]
		local owned = unlocked[id] == true
		local f = card(parent, owned and U.shade(s.Color, 0.85) or C(70, 70, 85), i)
		label(f, (owned and "" or "\u{1F512} ") .. string.upper(s.Name), UDim2.fromOffset(8, 6), UDim2.new(1, -16, 0, 26), nil, nil, 2.5)
		label(f, "x" .. fmt(s.Multiplier) .. " TRAINING", UDim2.fromOffset(8, 32), UDim2.new(1, -16, 0, 18), C(255, 235, 90))
		local je, jr = Config.Jutsu[s.E], Config.Jutsu[s.R]
		for k, j in {je, jr} do
			local row = U.new("Frame", {Position = UDim2.fromOffset(8, 54 + (k - 1) * 46), Size = UDim2.new(1, -16, 0, 42), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.55, Parent = f})
			U.corner(8).Parent = row
			local key = U.new("Frame", {Size = UDim2.fromOffset(30, 30), Position = UDim2.fromOffset(6, 6), BackgroundColor3 = j.Color, Parent = row})
			U.corner(6).Parent = key
			label(key, k == 1 and "E" or "R", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1))
			label(row, j.Name, UDim2.fromOffset(42, 2), UDim2.new(1, -46, 0, 20), nil, Enum.TextXAlignment.Left)
			label(row, j.Desc, UDim2.fromOffset(42, 22), UDim2.new(1, -46, 0, 16), C(210, 210, 230), Enum.TextXAlignment.Left, 1)
		end
		if owned then
			local isEq = equipped == id
			local btn = U.button({Text = isEq and "EQUIPPED" or "EQUIP", Color = isEq and C(120, 120, 130) or C(70, 210, 90), Size = UDim2.new(1, -16, 0, 40), Position = UDim2.new(0, 8, 1, -48), Parent = f})
			btn.MouseButton1Click:Connect(function()
				if isEq then return end
				ctx.EquipSign:FireServer(id)
			end)
		else
			local need = "STAGE " .. s.Stage .. "  +  " .. fmt(s.Power) .. " HAND SIGNS"
			label(f, "REQUIRES", UDim2.new(0, 8, 1, -54), UDim2.new(1, -16, 0, 18), C(255, 120, 120))
			label(f, need, UDim2.new(0, 8, 1, -34), UDim2.new(1, -16, 0, 24), C(255, 255, 255))
		end
	end
end

---------------------------------------------------------------- PETS
local function petViewport(parent: Instance, petId: string, size: UDim2, pos: UDim2?)
	local vp = U.new("ViewportFrame", {Size = size, Position = pos or UDim2.new(), BackgroundTransparency = 1, Ambient = C(200, 200, 200), LightColor = C(255, 255, 255), LightDirection = Vector3.new(-1, -1, -1), Parent = parent})
	local m = Looks.BuildPet(petId)
	m:PivotTo(CFrame.Angles(0, math.rad(200), 0))
	m.Parent = vp
	local cam = Instance.new("Camera")
	cam.FieldOfView = 40
	cam.CFrame = CFrame.lookAt(Vector3.new(0, 1.5, -6.5), Vector3.new(0, 0.3, 0))
	cam.Parent = vp
	vp.CurrentCamera = cam
	return vp
end
M.PetViewport = petViewport

builders.Pets = function(parent)
	list(parent, 10)
	local p = prof() or {}
	local highest = attr("Highest") or 1
	local eggsRow = U.new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 1, Parent = parent})
	grid(eggsRow, UDim2.fromOffset(196, 250), 10)
	for i, eggId in SC.EggOrder do
		local egg = SC.Eggs[eggId]
		local open = highest >= egg.Stage
		local f = card(eggsRow, open and U.shade(egg.Color, 0.8) or C(70, 70, 85), i)
		label(f, string.upper(egg.Name), UDim2.fromOffset(6, 4), UDim2.new(1, -12, 0, 24))
		local eggShape = U.new("Frame", {Size = UDim2.fromOffset(44, 56), Position = UDim2.new(0, 10, 0, 34), BackgroundColor3 = egg.Color, Parent = f})
		U.corner(26).Parent = eggShape
		U.stroke(3).Parent = eggShape
		for k, row in egg.Odds do
			local def = SC.Pets[row.Pet]
			label(f, def.Name .. "  " .. row.Chance .. "%", UDim2.new(0, 60, 0, 30 + (k - 1) * 17), UDim2.new(1, -66, 0, 16), SC.RarityColor[def.Rarity] == SC.RarityColor.Secret and C(255, 255, 255) or SC.RarityColor[def.Rarity], Enum.TextXAlignment.Left, 1.5)
		end
		label(f, "+" .. SC.Pets[egg.Odds[1].Pet].Boost .. " to +" .. fmt(SC.Pets[egg.Odds[#egg.Odds].Pet].Boost) .. " boost", UDim2.fromOffset(6, 104), UDim2.new(1, -12, 0, 16), C(255, 235, 120))
		if open then
			local b = U.button({Text = "\u{1F3C6} " .. fmt(egg.Cost) .. "  HATCH", Color = C(70, 210, 90), Size = UDim2.new(1, -12, 0, 44), Position = UDim2.new(0, 6, 1, -52), Parent = f})
			b.MouseButton1Click:Connect(function()
				local res = act("Hatch", eggId)
				if res and res.ok then ctx.HatchAnimation(eggId, res.pet) end
			end)
		else
			label(f, "\u{1F512} REACH STAGE " .. egg.Stage, UDim2.new(0, 6, 1, -46), UDim2.new(1, -12, 0, 30), C(255, 130, 130))
		end
	end
	-- inventory header
	local pets = p.Pets or {}
	local equipped = p.EquippedPets or {}
	local count = 0
	for _ in pets do count += 1 end
	local bar = U.new("Frame", {Size = UDim2.new(1, 0, 0, 48), BackgroundTransparency = 1, LayoutOrder = 2, Parent = parent})
	label(bar, "INVENTORY " .. count .. "/" .. SC.MaxPetsOwned .. "   EQUIPPED " .. #equipped .. "/" .. (p.PetSlots or 3) .. "   x" .. string.format("%.2f", p.PetMult or 1), UDim2.fromOffset(0, 6), UDim2.new(0.65, 0, 0, 36), nil, Enum.TextXAlignment.Left)
	local best = U.button({Text = "EQUIP BEST", Color = C(255, 170, 40), Size = UDim2.new(0.3, 0, 0, 42), Position = UDim2.new(1, 0, 0, 2), AnchorPoint = Vector2.new(1, 0), Parent = bar})
	best.MouseButton1Click:Connect(function() act("EquipBest") end)
	local inv = U.new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 3, Parent = parent})
	grid(inv, UDim2.fromOffset(150, 190), 8)
	local uids = {}
	for uid in pets do table.insert(uids, uid) end
	table.sort(uids, function(a, b)
		local ea, eb = table.find(equipped, a) ~= nil, table.find(equipped, b) ~= nil
		if ea ~= eb then return ea end
		return (SC.Pets[pets[a].Pet] and SC.Pets[pets[a].Pet].Boost or 0) > (SC.Pets[pets[b].Pet] and SC.Pets[pets[b].Pet].Boost or 0)
	end)
	if #uids == 0 then
		label(inv, "Hatch an egg to get your first pet!", UDim2.new(), UDim2.new(1, 0, 0, 30))
	end
	for i, uid in uids do
		local rec = pets[uid]
		local def = SC.Pets[rec.Pet]
		if def then
			local isEq = table.find(equipped, uid) ~= nil
			local rc = SC.RarityColor[def.Rarity]
			local f = card(inv, isEq and C(60, 140, 70) or C(70, 64, 100), i)
			petViewport(f, rec.Pet, UDim2.new(1, 0, 0, 84), UDim2.fromOffset(0, 2))
			label(f, def.Name, UDim2.fromOffset(4, 84), UDim2.new(1, -8, 0, 18))
			label(f, string.upper(def.Rarity) .. "  +" .. fmt(def.Boost), UDim2.fromOffset(4, 102), UDim2.new(1, -8, 0, 16), rc == SC.RarityColor.Secret and C(255, 255, 255) or rc)
			local eq = U.button({Text = isEq and "UNEQUIP" or "EQUIP", Color = isEq and C(230, 90, 60) or C(70, 210, 90), Size = UDim2.new(1, -8, 0, 32), Position = UDim2.fromOffset(4, 120), Parent = f})
			eq.MouseButton1Click:Connect(function() act("EquipPet", uid) end)
			local lock = U.button({Text = rec.Locked and "\u{1F512}" or "\u{1F513}", Color = C(120, 120, 220), Size = UDim2.new(0.5, -6, 0, 28), Position = UDim2.fromOffset(4, 156), Parent = f})
			lock.MouseButton1Click:Connect(function() act("LockPet", uid) end)
			local del = U.button({Text = "DELETE", Color = C(200, 60, 60), Size = UDim2.new(0.5, -6, 0, 28), Position = UDim2.new(0.5, 2, 0, 156), Parent = f})
			local armed = false
			del.MouseButton1Click:Connect(function()
				if rec.Locked then ctx.Toast("Unlock the pet first", C(255, 90, 90)) return end
				if not armed then armed = true; (del:FindFirstChildOfClass("TextLabel") :: TextLabel).Text = "SURE?"; return end
				act("DeletePet", uid)
			end)
		end
	end
end

---------------------------------------------------------------- AURAS
builders.Auras = function(parent)
	grid(parent, UDim2.fromOffset(200, 170), 10)
	local p = prof() or {}
	local owned = p.Auras or {}
	local highest = attr("Highest") or 1
	for i, id in SC.AuraOrder do
		local a = SC.Auras[id]
		local has = owned[id] == true
		local eq = p.EquippedAura == id
		local f = card(parent, U.shade(a.Color, has and 0.8 or 0.45), i)
		local orb = U.new("Frame", {Size = UDim2.fromOffset(40, 40), Position = UDim2.new(0.5, -20, 0, 34), BackgroundColor3 = a.Color, Parent = f})
		U.corner(20).Parent = orb
		U.new("UIStroke", {Thickness = 4, Color = a.Color2, Parent = orb})
		label(f, string.upper(a.Name), UDim2.fromOffset(6, 4), UDim2.new(1, -12, 0, 24))
		label(f, "x" .. a.Mult .. " TRAINING", UDim2.fromOffset(6, 80), UDim2.new(1, -12, 0, 22), C(255, 235, 90))
		local text, col
		if has then text, col = eq and "UNEQUIP" or "EQUIP", eq and C(230, 90, 60) or C(70, 210, 90)
		elseif highest >= a.Stage then text, col = "\u{1F3C6} " .. fmt(a.Cost), C(255, 170, 40)
		else text, col = "\u{1F512} STAGE " .. a.Stage, C(110, 110, 120) end
		local b = U.button({Text = text, Color = col, Size = UDim2.new(1, -12, 0, 44), Position = UDim2.new(0, 6, 1, -52), Parent = f})
		b.MouseButton1Click:Connect(function()
			local res = act("BuyAura", id)
			if res and res.bought then ctx.Celebrate("NEW AURA!", a.Name, a.Color) end
		end)
	end
end

---------------------------------------------------------------- UPGRADES
builders.Upgrades = function(parent)
	list(parent, 8)
	local p = prof() or {}
	local ups = p.Upgrades or {}
	for i, id in SC.UpgradeOrder do
		local u = SC.Upgrades[id]
		local lvl = ups[id] or 0
		local f = card(parent, C(70, 64, 110), i)
		f.Size = UDim2.new(1, -8, 0, 70)
		label(f, u.Name .. "  (" .. lvl .. "/" .. u.Max .. ")", UDim2.fromOffset(14, 6), UDim2.new(0.62, 0, 0, 30), nil, Enum.TextXAlignment.Left)
		label(f, u.Desc, UDim2.fromOffset(14, 38), UDim2.new(0.62, 0, 0, 22), C(210, 210, 235), Enum.TextXAlignment.Left, 1)
		local maxed = lvl >= u.Max
		local b = U.button({Text = maxed and "MAX" or ("\u{1F3C6} " .. fmt(SC.UpgradeCost(id, lvl))), Color = maxed and C(110, 110, 120) or C(70, 210, 90),
			Size = UDim2.new(0.33, 0, 0, 50), Position = UDim2.new(1, -10, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), Parent = f})
		b.MouseButton1Click:Connect(function() if not maxed then act("BuyUpgrade", id) end end)
	end
end

---------------------------------------------------------------- REBIRTH
builders.Rebirth = function(parent)
	list(parent, 10)
	local p = prof() or {}
	local reb = attr("Rebirths") or 0
	local cost = p.RebirthCost or SC.RebirthCost(reb)
	local have = attr("HandSigns") or 0
	local f = card(parent, C(110, 60, 170), 1)
	f.Size = UDim2.new(1, -8, 0, 250)
	label(f, "REBIRTHS: " .. reb, UDim2.fromOffset(10, 10), UDim2.new(1, -20, 0, 40))
	label(f, "Multiplier  x" .. (1 + reb * 0.75) .. "  \u{2192}  x" .. (1 + (reb + 1) * 0.75), UDim2.fromOffset(10, 56), UDim2.new(1, -20, 0, 32), C(120, 255, 140))
	label(f, "Requires " .. fmt(cost) .. " Hand Signs  (you have " .. fmt(have) .. ")", UDim2.fromOffset(10, 94), UDim2.new(1, -20, 0, 26), have >= cost and C(255, 255, 255) or C(255, 130, 130))
	label(f, "Resets: Hand Signs only.  Kept: stages, hand signs, pets, auras, upgrades, Trophies, purchases.", UDim2.fromOffset(10, 126), UDim2.new(1, -20, 0, 40), C(220, 210, 255), nil, 1)
	local confirm = false
	local b, bl = U.button({Text = "REBIRTH", Color = have >= cost and C(70, 210, 90) or C(110, 110, 120), Size = UDim2.new(0.6, 0, 0, 56), Position = UDim2.new(0.2, 0, 1, -70), Parent = f})
	b.MouseButton1Click:Connect(function()
		if have < cost then ctx.Toast("Not enough Hand Signs", C(255, 90, 90)) return end
		if not confirm then confirm = true; bl.Text = "TAP AGAIN TO CONFIRM"; return end
		act("Rebirth")
	end)
end

---------------------------------------------------------------- STAGES
builders.Stages = function(parent)
	grid(parent, UDim2.fromOffset(150, 84), 8)
	local p = prof() or {}
	local done = p.Completed or {}
	local highest = attr("Highest") or 1
	for i, st in Config.Stages do
		local open = i <= highest
		local f = card(parent, open and U.shade(st.Gate, 0.75) or C(60, 60, 72), i)
		label(f, (done[tostring(i)] and "\u{2705} " or "") .. "STAGE " .. i, UDim2.fromOffset(6, 4), UDim2.new(1, -12, 0, 24))
		label(f, open and st.Name or "\u{1F512} " .. fmt(st.Recommended), UDim2.fromOffset(6, 28), UDim2.new(1, -12, 0, 18), C(240, 240, 255), nil, 1.5)
		if open then
			local b = U.button({Text = "GO", Color = C(70, 210, 90), Size = UDim2.new(1, -12, 0, 28), Position = UDim2.new(0, 6, 1, -34), Parent = f})
			b.MouseButton1Click:Connect(function() ctx.TeleportStage:FireServer(i); M.Close() end)
		end
	end
end

---------------------------------------------------------------- REWARDS
local function rewardRow(parent, order, title, sub, btnText, enabled, onClick)
	local f = card(parent, C(70, 64, 110), order)
	f.Size = UDim2.new(1, -8, 0, 64)
	label(f, title, UDim2.fromOffset(14, 6), UDim2.new(0.62, 0, 0, 28), nil, Enum.TextXAlignment.Left)
	label(f, sub, UDim2.fromOffset(14, 36), UDim2.new(0.62, 0, 0, 20), C(210, 210, 235), Enum.TextXAlignment.Left, 1)
	local b = U.button({Text = btnText, Color = enabled and C(70, 210, 90) or C(110, 110, 120), Size = UDim2.new(0.33, 0, 0, 46), Position = UDim2.new(1, -10, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), Parent = f})
	b.MouseButton1Click:Connect(function() if enabled then onClick() end end)
end

builders.Rewards = function(parent)
	list(parent, 8)
	local p = prof() or {}
	local now = os.time()
	local serverNow = p.ServerTime or now
	local highest = attr("Highest") or 1
	if (p.PendingOffline or 0) > 0 then
		rewardRow(parent, 0, "WHILE YOU WERE AWAY", "+" .. fmt(p.PendingOffline) .. " Hand Signs", "CLAIM", true, function() act("ClaimOffline") end)
	end
	local left = (p.LastDaily or 0) + SC.DailyCooldown - serverNow
	rewardRow(parent, 1, "DAILY REWARD (streak " .. (p.DailyStreak or 0) .. ")", "\u{1F3C6} " .. fmt(SC.DailyReward((p.DailyStreak or 0) + 1, highest)),
		left <= 0 and "CLAIM" or string.format("%dh %dm", left // 3600, (left % 3600) // 60), left <= 0, function()
			local r = act("ClaimDaily")
			if r and r.ok then ctx.Toast("+" .. fmt(r.amount) .. " Trophies!", C(255, 220, 80)) end
		end)
	local played = os.time() - (p.SessionStart or os.time())
	for i, row in SC.PlaytimeRewards do
		local claimed = p.Playtime and (p.Playtime[i] or p.Playtime[tostring(i)])
		local ready = played >= row.Minutes * 60
		local remain = row.Minutes * 60 - played
		rewardRow(parent, 1 + i, "PLAY " .. row.Minutes .. " MINUTES", "\u{1F3C6} " .. fmt(Config.Stages[highest].Trophies * row.Mult),
			claimed and "CLAIMED" or (ready and "CLAIM" or string.format("%d:%02d", remain // 60, remain % 60)), ready and not claimed, function()
				local r = act("ClaimPlaytime", i)
				if r and r.ok then ctx.Toast("+" .. fmt(r.amount) .. " Trophies!", C(255, 220, 80)) end
			end)
	end
	for i, stage in SC.MilestoneStages do
		local key = tostring(stage)
		local claimed = p.ClaimedMilestones and p.ClaimedMilestones[key]
		local done = p.Completed and p.Completed[key]
		rewardRow(parent, 10 + i, "CLEAR STAGE " .. stage, "\u{1F3C6} " .. fmt(Config.Stages[stage].Trophies * 50), claimed and "CLAIMED" or (done and "CLAIM" or "LOCKED"), done and not claimed, function()
			local r = act("ClaimMilestone", stage)
			if r and r.ok then ctx.Toast("+" .. fmt(r.amount) .. " Trophies!", C(255, 220, 80)) end
		end)
	end
end

---------------------------------------------------------------- SHOP
builders.Shop = function(parent)
	list(parent, 8)
	local p = prof() or {}
	local passes = p.Passes or {}
	local order = 0
	for key, gp in SC.GamePasses do
		order += 1
		local owned = passes[key]
		rewardRow(parent, order, gp.Name, gp.Id == 0 and "Coming soon" or "Game pass", owned and "OWNED" or (gp.Id == 0 and "SOON" or "BUY"), gp.Id ~= 0 and not owned, function() act("BuyPass", key) end)
	end
	for key, dp in SC.DevProducts do
		order += 1
		local active = (p.BoostUntil or 0) > (p.ServerTime or os.time())
		rewardRow(parent, order, dp.Name, active and "Active!" or (dp.Id == 0 and "Coming soon" or "Stacks"), dp.Id == 0 and "SOON" or "BUY", dp.Id ~= 0, function() act("BuyProduct", key) end)
	end
end

---------------------------------------------------------------- TOP (leaderboards)
builders.Top = function(parent)
	grid(parent, UDim2.fromOffset(200, 330), 10)
	local holder = ReplicatedStorage:FindFirstChild("LeaderboardData") :: StringValue?
	local ok, data = pcall(HttpService.JSONDecode, HttpService, holder and holder.Value or "{}")
	if not ok then data = {} end
	local titles = {{"LifetimeHandSigns", "HAND SIGNS"}, {"Trophies", "TROPHIES"}, {"Rebirths", "REBIRTHS"}, {"Stage", "STAGE"}}
	for i, t in titles do
		local f = card(parent, C(70, 64, 110), i)
		label(f, t[2], UDim2.fromOffset(6, 6), UDim2.new(1, -12, 0, 28), C(255, 220, 80))
		local rows = data[t[1]] or {}
		if #rows == 0 then label(f, "Updates on live servers", UDim2.fromOffset(6, 40), UDim2.new(1, -12, 0, 20), C(200, 200, 220), nil, 1) end
		for r, row in rows do
			label(f, r .. ". " .. row.Name, UDim2.fromOffset(8, 36 + (r - 1) * 28), UDim2.new(0.62, -8, 0, 24), nil, Enum.TextXAlignment.Left, 1.5)
			label(f, fmt(math.floor(row.Value + 0.5)), UDim2.new(0.62, 0, 0, 36 + (r - 1) * 28), UDim2.new(0.38, -8, 0, 24), C(140, 255, 160), Enum.TextXAlignment.Right, 1.5)
		end
	end
end

---------------------------------------------------------------- CODES
builders.Codes = function(parent)
	list(parent, 10)
	label(parent, "Enter a code from our updates:", UDim2.new(), UDim2.new(1, 0, 0, 30))
	local box = U.new("TextBox", {Size = UDim2.new(0.8, 0, 0, 54), BackgroundColor3 = C(30, 26, 50), TextColor3 = Color3.new(1, 1, 1), Font = U.Font, TextScaled = true,
		PlaceholderText = "CODE", Text = "", ClearTextOnFocus = false, LayoutOrder = 2, Parent = parent})
	U.corner(10).Parent = box
	U.stroke(3, C(255, 200, 80), Enum.ApplyStrokeMode.Border).Parent = box
	local b = U.button({Text = "REDEEM", Color = C(70, 210, 90), Size = UDim2.new(0.5, 0, 0, 52), LayoutOrder = 3, Parent = parent})
	b.MouseButton1Click:Connect(function()
		local r = act("Redeem", box.Text)
		if r and r.ok then ctx.Toast("Code redeemed! +" .. fmt(r.amount) .. " Trophies", C(120, 255, 140)) end
	end)
end

---------------------------------------------------------------- SETTINGS
builders.Settings = function(parent)
	list(parent, 8)
	local p = prof() or {}
	local s = p.Settings or {}
	local rows = {
		{"ReduceEffects", "Reduce Effects", "Fewer particles; hides other players' auras"},
		{"HideOtherPets", "Hide Other Pets", "Only show your own pets"},
		{"AutoTrain", "Auto Train", "Needs the Auto Train upgrade"},
	}
	for i, r in rows do
		local on = s[r[1]] == true
		if r[1] == "AutoTrain" then on = s[r[1]] ~= false end
		rewardRow(parent, i, r[2], r[3], on and "ON" or "OFF", true, function() act("Setting", r[1], not on) end)
	end
end

return M

