-- Menu panels: Hand Signs, Pets, Auras, Upgrades, Rebirth, Stages, Rewards, Codes, Shop, Top, Settings.
-- Panels only display state and ask the server (Action remote); nothing here grants anything.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Config = require(ReplicatedStorage.Shared.Config)
local SC = require(ReplicatedStorage.Shared.SystemsConfig)
local U = require(script.Parent.UIKit)
local Looks = require(script.Parent.Looks)

local AssetsMod = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Assets"))
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
-- raised studs come from the shared UIKit style (glossy buttons already carry their own)
local function studs(parent: Instance, transp: number?, tile: number?)
	local existing = parent:FindFirstChild("Studs")
	if existing then return existing end
	return U.studs(parent, transp, tile)
end
M.Studs = studs
local function card(parent: Instance, color: Color3, order: number?): Frame
	local f = U.new("Frame", {BackgroundColor3 = color, LayoutOrder = order or 0, Parent = parent})
	U.corner(8).Parent = f
	U.stroke(4, C(22, 18, 30), Enum.ApplyStrokeMode.Border).Parent = f
	U.grad(Color3.new(1, 1, 1), Color3.fromRGB(205, 205, 205)).Parent = f
	studs(f, 0.05, 34)
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

---------------------------------------------------------------- panel shell (+1 Anime Eyes-style: studded coloured header, red X, slate body)
local TAB_ICON = {Signs = "HandSign", Pets = "Egg", Auras = "Aura", Upgrades = "Upgrades", Rebirth = "Rebirth", Stages = "Places",
	Rewards = "Gift", Shop = "Shop", Top = "Crown", Codes = "Codes", Settings = "Settings"}
local TAB_TITLE = {Signs = "My Hand Signs", Pets = "Pets", Auras = "Auras", Upgrades = "Upgrades", Rebirth = "Rebirth", Stages = "Stages",
	Rewards = "Quests & Rewards", Shop = "Store", Top = "Leaderboards", Codes = "Codes", Settings = "Settings"}
local TAB_COLOR = {Signs = C(232, 62, 92), Pets = C(232, 62, 92), Auras = C(232, 62, 92), Shop = C(232, 62, 92),
	Rebirth = C(150, 74, 230), Rewards = C(150, 74, 230), Codes = C(150, 74, 230), Settings = C(150, 74, 230), Top = C(150, 74, 230),
	Upgrades = C(60, 180, 90), Stages = C(40, 160, 200)}
local headerIcon: ImageLabel
local headerFrame: Frame
local detail: Frame? = nil
function M.Init(c)
	ctx = c
	root = U.new("Frame", {Name = "Panel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromScale(0.6, 0.74),
		BackgroundColor3 = C(74, 72, 94), Visible = false, Parent = c.Gui, ZIndex = 5})
	U.new("UISizeConstraint", {MinSize = Vector2.new(300, 280), MaxSize = Vector2.new(900, 640), Parent = root})
	U.corner(6).Parent = root
	U.stroke(5, C(16, 14, 22), Enum.ApplyStrokeMode.Border).Parent = root
	headerFrame = U.new("Frame", {Name = "Frame", Size = UDim2.new(1, 0, 0, 72), BackgroundColor3 = C(232, 62, 92), ZIndex = 5, Parent = root})
	U.corner(6).Parent = headerFrame
	U.new("Frame", {Name = "HeaderFill", Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 0, 1, -12), BorderSizePixel = 0, BackgroundColor3 = C(232, 62, 92), ZIndex = 5, Parent = headerFrame})
	U.new("Frame", {Size = UDim2.new(1, 0, 0, 5), Position = UDim2.new(0, 0, 1, 0), BorderSizePixel = 0, BackgroundColor3 = C(16, 14, 22), ZIndex = 6, Parent = headerFrame})
	studs(headerFrame, 0.1, 38)
	headerIcon = U.new("ImageLabel", {BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Size = UDim2.fromOffset(62, 62), Position = UDim2.fromOffset(12, 5), ZIndex = 7, Parent = headerFrame})
	titleLabel = label(headerFrame, "", UDim2.fromOffset(84, 10), UDim2.new(1, -170, 1, -20), nil, Enum.TextXAlignment.Left, 4)
	titleLabel.ZIndex = 7
	local close = U.button({Text = "X", Color = C(235, 50, 80), Size = UDim2.fromOffset(56, 56), Position = UDim2.new(1, -10, 0, 8), AnchorPoint = Vector2.new(1, 0), Radius = 6, StrokeT = 4, Parent = headerFrame})
	close.ZIndex = 8
	studs(close, 0.25, 22)
	close.MouseButton1Click:Connect(function() M.Close() end)
	body = U.new("ScrollingFrame", {Position = UDim2.fromOffset(14, 88), Size = UDim2.new(1, -28, 1, -100), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 8, ScrollBarImageColor3 = C(220, 220, 235), AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ZIndex = 5, Parent = root})
	U.new("UIPadding", {PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 12), Parent = body})
	-- phones: the panel takes most of the screen
	local function fit()
		local cam = workspace.CurrentCamera
		local v = cam and cam.ViewportSize or Vector2.new(1280, 720)
		local compact = current == "Rebirth"
		if v.X < 900 then root.Size = compact and UDim2.fromScale(0.84, 0.6) or UDim2.fromScale(0.92, 0.86)
		else root.Size = compact and UDim2.fromScale(0.44, 0.44) or UDim2.fromScale(0.6, 0.74) end
	end
	M.Fit = fit
	fit()
	if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end
end

function M.IsOpen() return root.Visible end

function M.Open(id: string)
	if current == id and root.Visible then M.Close(); return end
	current = id
	if detail then detail:Destroy(); detail = nil end
	local col = TAB_COLOR[id] or C(232, 62, 92)
	titleLabel.Text = TAB_TITLE[id] or id
	headerFrame.BackgroundColor3 = col
	headerFrame.HeaderFill.BackgroundColor3 = col
	headerIcon.Image = (id == "Signs" and AssetsMod.SignIcons and AssetsMod.SignIcons[attr("Equipped") or "Tiger"]) or AssetsMod.Icon(TAB_ICON[id])
	if M.Fit then M.Fit() end
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

---------------------------------------------------------------- MY HAND SIGNS (big-art collection grid, +1 Anime Eyes "My Eyes" layout)
local TIER_COLOR = {C(160, 160, 172), C(160, 160, 172), C(64, 160, 240), C(64, 160, 240), C(150, 90, 230), C(150, 90, 230), C(150, 90, 230),
	C(255, 150, 40), C(255, 150, 40), C(255, 150, 40), C(240, 70, 90), C(240, 70, 90), C(255, 200, 60), C(255, 200, 60)}
local function signState(id: string, unlocked: {[string]: boolean}): string
	local s = Config.HandSigns[id]
	if unlocked[id] then return (attr("Equipped") or "Tiger") == id and "Equipped" or "Owned" end
	return (attr("Trophies") or 0) >= s.Price and "Buy" or "Locked" -- trophies are the only requirement
end
local function signButton(parent: Instance, id: string, st: string, size: UDim2, pos: UDim2)
	local s = Config.HandSigns[id]
	local text, col
	if st == "Equipped" then text, col = "EQUIPPED", U.GREEN
	elseif st == "Owned" then text, col = "EQUIP", U.GREEN
	elseif st == "Buy" then text, col = "BUY \u{1F3C6}" .. fmt(s.Price), U.ORANGE
	else text, col = "\u{1F3C6} " .. fmt(s.Price), U.GREY end
	local b, bl = U.button({Text = text, Color = col, Size = size, Position = pos, AnchorPoint = Vector2.new(0.5, 1), Radius = 6, StrokeT = 3, Parent = parent})
	studs(b, 0.35, 18)
	b.MouseButton1Click:Connect(function()
		if st == "Owned" then ctx.EquipSign:FireServer(id)
		elseif st == "Buy" then
			local res = act("BuySign", id)
			if res and res.ok and res.bought then ctx.Toast(string.upper(s.Name) .. " UNLOCKED!", C(120, 255, 120)) end
		elseif st == "Locked" then
			ctx.Toast("Need " .. fmt(s.Price) .. " Trophies", C(255, 120, 120))
		end
	end)
	return b, bl
end
local function signArt(parent: Instance, id: string, size: UDim2, pos: UDim2, dim: boolean)
	local art = AssetsMod.SignIcons and AssetsMod.SignIcons[id]
	if art then
		return U.new("ImageLabel", {BackgroundTransparency = 1, Image = art, ScaleType = Enum.ScaleType.Fit, AnchorPoint = Vector2.new(0.5, 0.5),
			Size = size, Position = pos, ImageColor3 = dim and C(120, 120, 130) or Color3.new(1, 1, 1), ZIndex = 6, Parent = parent})
	end
	-- no approved artwork yet (Advanced / Forbidden): honest placeholder, never another sign's pose
	local q = U.text({Text = "?", AnchorPoint = Vector2.new(0.5, 0.5), Size = size, Position = pos, Stroke = 5, ZIndex = 6, Parent = parent})
	return q
end
local function openDetail(id: string)
	if detail then detail:Destroy() end
	local s = Config.HandSigns[id]
	local p = prof()
	local unlocked = p and p.Unlocked or {Tiger = true}
	local st = signState(id, unlocked)
	local d = U.new("Frame", {Name = "Detail", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.56), Size = UDim2.new(0.86, 0, 0.78, 0),
		BackgroundColor3 = TIER_COLOR[s.Order] or C(150, 90, 230), ZIndex = 20, Parent = root})
	detail = d
	U.corner(8).Parent = d
	U.stroke(5, C(16, 14, 22), Enum.ApplyStrokeMode.Border).Parent = d
	U.grad(Color3.new(1, 1, 1), C(190, 190, 200)).Parent = d
	local sd = studs(d, 0.2); sd.ZIndex = 20
	local function L(t: string, pos: UDim2, size: UDim2, col: Color3?, xa: Enum.TextXAlignment?, stroke: number?)
		local l = label(d, t, pos, size, col, xa, stroke); l.ZIndex = 22; return l
	end
	local art = signArt(d, id, UDim2.fromScale(0.4, 0.74), UDim2.fromScale(0.22, 0.46), false)
	art.ZIndex = 22
	L(string.upper(s.Name), UDim2.fromScale(0.43, 0.05), UDim2.fromScale(0.5, 0.13), nil, Enum.TextXAlignment.Left, 4)
	L("x" .. fmt(s.Multiplier) .. " Hand Signs", UDim2.fromScale(0.43, 0.18), UDim2.fromScale(0.5, 0.09), C(255, 230, 90), Enum.TextXAlignment.Left, 3)
	for k, key in {"E", "R"} do
		local j = Config.Jutsu[k == 1 and s.E or s.R]
		local y = 0.3 + (k - 1) * 0.2
		local row = U.new("Frame", {Position = UDim2.fromScale(0.43, y), Size = UDim2.fromScale(0.54, 0.18), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.5, ZIndex = 21, Parent = d})
		U.corner(6).Parent = row
		local kb = U.new("Frame", {Size = UDim2.fromScale(0.13, 0.7), Position = UDim2.fromScale(0.02, 0.15), BackgroundColor3 = j.Color, ZIndex = 22, Parent = row})
		U.corner(6).Parent = kb
		local kl = label(kb, key, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1)); kl.ZIndex = 23
		local n = label(row, j.Name, UDim2.fromScale(0.18, 0.04), UDim2.fromScale(0.8, 0.46), nil, Enum.TextXAlignment.Left, 2.5); n.ZIndex = 22
		local dsc = label(row, j.Desc, UDim2.fromScale(0.18, 0.5), UDim2.fromScale(0.8, 0.44), C(225, 225, 240), Enum.TextXAlignment.Left, 1.5); dsc.ZIndex = 22
	end
	if st == "Buy" or st == "Locked" then
		local priceOk = (attr("Trophies") or 0) >= s.Price
		L("Price: " .. fmt(s.Price) .. " Trophies", UDim2.fromScale(0.43, 0.71), UDim2.fromScale(0.54, 0.07), priceOk and C(130, 255, 130) or C(255, 120, 120), Enum.TextXAlignment.Left, 2)
	end
	local b = signButton(d, id, st, UDim2.fromScale(0.4, 0.14), UDim2.fromScale(0.7, 0.95))
	b.ZIndex = 22
	local x = U.button({Text = "X", Color = C(235, 50, 80), Size = UDim2.fromOffset(44, 44), Position = UDim2.new(1, -8, 0, 8), AnchorPoint = Vector2.new(1, 0), Radius = 6, StrokeT = 3, Parent = d})
	x.ZIndex = 24
	x.MouseButton1Click:Connect(function() d:Destroy(); detail = nil end)
	U.pop(d, 0.85)
end
builders.Signs = function(parent)
	-- AbsoluteSize includes the pop-in tween and the HUD's responsive UIScale; cell offsets get scaled again, so undo both
	local k, node = 1, parent :: Instance?
	while node do local us = node:FindFirstChildOfClass("UIScale"); if us and us.Scale > 0 then k *= us.Scale end; node = node.Parent; if node and node:IsA("PlayerGui") then break end end
	local w = parent.AbsoluteSize.X / k
	local cols = w < 380 and 2 or (w < 560 and 3 or 4)
	local cellW = math.max(80, (w - 16 - 10 * cols) / cols)
	U.new("UIGridLayout", {CellSize = UDim2.fromOffset(cellW, math.floor(cellW / 0.92)), CellPadding = UDim2.fromOffset(10, 10), FillDirectionMaxCells = cols, SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = parent})
	local p = prof()
	local unlocked = p and p.Unlocked or {Tiger = true}
	for i, id in Config.HandSignOrder do
		local s = Config.HandSigns[id]
		local st = signState(id, unlocked)
		local f = card(parent, TIER_COLOR[i] or C(150, 90, 230), i)
		if i >= 13 then -- top tiers get a rainbow card like the reference's best eyes
			f:FindFirstChildOfClass("UIGradient").Color = ColorSequence.new({ColorSequenceKeypoint.new(0, C(255, 120, 140)), ColorSequenceKeypoint.new(0.35, C(255, 230, 120)),
				ColorSequenceKeypoint.new(0.7, C(130, 255, 170)), ColorSequenceKeypoint.new(1, C(140, 180, 255))})
			f:FindFirstChildOfClass("UIGradient").Rotation = 30
			f.BackgroundColor3 = Color3.new(1, 1, 1)
		end
		local nm = label(f, s.Name, UDim2.fromScale(0.04, 0.025), UDim2.fromScale(0.92, 0.13), nil, nil, 3.5)
		nm.ZIndex = 6
		-- the artwork is the hero: ~64% of the card width, centred, never cropped
		signArt(f, id, UDim2.fromScale(1, 0.6), UDim2.fromScale(0.5, 0.425), false)
		local m = label(f, "x" .. fmt(s.Multiplier) .. " Hand Signs", UDim2.fromScale(0.03, 0.665), UDim2.fromScale(0.94, 0.12), nil, nil, 3.5)
		m.ZIndex = 6
		local b = signButton(f, id, st, UDim2.fromScale(0.84, 0.17), UDim2.fromScale(0.5, 0.97))
		b.ZIndex = 7
		local hit = U.new("TextButton", {Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 0.78), ZIndex = 8, Parent = f})
		hit.MouseButton1Click:Connect(function() openDetail(id) end)
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
			local b = U.button({Text = "\u{1F3C6} " .. fmt(egg.Cost) .. "  HATCH", Color = U.GREEN, Size = UDim2.new(1, -12, 0, 44), Position = UDim2.new(0, 6, 1, -52), Parent = f})
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
	local best = U.button({Text = "EQUIP BEST", Color = U.ORANGE, Size = UDim2.new(0.3, 0, 0, 42), Position = UDim2.new(1, 0, 0, 2), AnchorPoint = Vector2.new(1, 0), Parent = bar})
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
			local eq = U.button({Text = isEq and "UNEQUIP" or "EQUIP", Color = isEq and C(230, 90, 60) or U.GREEN, Size = UDim2.new(1, -8, 0, 32), Position = UDim2.fromOffset(4, 120), Parent = f})
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
	list(parent, 8)
	local p = prof() or {}
	local owned = p.Auras or {}
	local highest = attr("Highest") or 1
	for i, id in SC.AuraOrder do
		local a = SC.Auras[id]
		local has = owned[id] == true
		local eq = p.EquippedAura == id
		local f = card(parent, U.shade(a.Color, 0.9), i)
		f.Size = UDim2.new(1, -8, 0, 92)
		local iconBox = U.new("Frame", {Size = UDim2.fromOffset(78, 78), Position = UDim2.fromOffset(7, 7), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.55, ZIndex = 6, Parent = f})
		U.corner(6).Parent = iconBox
		U.new("ImageLabel", {BackgroundTransparency = 1, Image = AssetsMod.Icon("Aura"), ImageColor3 = a.Color:Lerp(Color3.new(1, 1, 1), 0.15), ScaleType = Enum.ScaleType.Fit,
			Size = UDim2.fromScale(0.9, 0.9), Position = UDim2.fromScale(0.05, 0.05), ZIndex = 7, Parent = iconBox})
		local n = label(f, a.Name, UDim2.fromOffset(94, 10), UDim2.new(0.42, -94, 0, 36), nil, Enum.TextXAlignment.Left, 3.5); n.ZIndex = 6
		local m = label(f, "x" .. a.Mult .. " Hand Signs", UDim2.fromOffset(94, 48), UDim2.new(0.42, -94, 0, 26), C(255, 225, 90), Enum.TextXAlignment.Left, 2.5); m.ZIndex = 6
		if not has then
			local pr = label(f, highest >= a.Stage and (fmt(a.Cost) .. " \u{1F3C6}") or ("\u{1F512} Stage " .. a.Stage), UDim2.new(0.42, 0, 0.5, -16), UDim2.new(0.24, 0, 0, 32), Color3.new(1, 1, 1), Enum.TextXAlignment.Right, 3)
			pr.ZIndex = 6
		end
		local text, col
		if has then text, col = eq and "UNEQUIP" or "EQUIP", eq and C(235, 90, 70) or U.GREEN
		elseif highest >= a.Stage then text, col = "BUY", U.ORANGE
		else text, col = "LOCKED", U.GREY end
		local b = U.button({Text = text, Color = col, Size = UDim2.new(0.28, 0, 0, 60), Position = UDim2.new(1, -10, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), Radius = 6, StrokeT = 3, Parent = f})
		b.ZIndex = 7
		studs(b, 0.35, 18)
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
		local b = U.button({Text = maxed and "MAX" or ("\u{1F3C6} " .. fmt(SC.UpgradeCost(id, lvl))), Color = maxed and U.GREY or U.GREEN,
			Size = UDim2.new(0.33, 0, 0, 50), Position = UDim2.new(1, -10, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), Parent = f})
		b.MouseButton1Click:Connect(function() if not maxed then act("BuyUpgrade", id) end end)
	end
end

---------------------------------------------------------------- REBIRTH
builders.Rebirth = function(parent)
	list(parent, 12)
	local p = prof() or {}
	local reb = attr("Rebirths") or 0
	local cost = p.RebirthCost or SC.RebirthCost(reb)
	local have = attr("HandSigns") or 0
	local pct = math.clamp(have / math.max(cost, 1), 0, 1)
	local holder = U.new("Frame", {Size = UDim2.new(1, -8, 0, 236), BackgroundTransparency = 1, LayoutOrder = 1, Parent = parent})
	label(holder, string.format('Hand Signs multiplier x%s -> <font color="#7CFF6B">x%s</font>', tostring(1 + reb * 0.75), tostring(1 + (reb + 1) * 0.75)),
		UDim2.fromScale(0.05, 0), UDim2.new(0.9, 0, 0, 40), nil, nil, 3).RichText = true
	label(holder, "Needs " .. fmt(cost) .. " Hand Signs. Resets your Hand Signs only.", UDim2.new(0.05, 0, 0, 44), UDim2.new(0.9, 0, 0, 30), C(225, 225, 240), nil, 2.5)
	local bar = U.new("Frame", {Position = UDim2.new(0.12, 0, 0, 82), Size = UDim2.new(0.76, 0, 0, 38), BackgroundColor3 = C(40, 40, 55), Parent = holder})
	U.corner(6).Parent = bar
	U.stroke(3, C(16, 14, 22), Enum.ApplyStrokeMode.Border).Parent = bar
	local fill = U.new("Frame", {Size = UDim2.fromScale(pct, 1), BackgroundColor3 = C(70, 160, 255), Parent = bar})
	U.corner(6).Parent = fill
	U.grad(C(120, 200, 255), C(50, 130, 240)).Parent = fill
	label(bar, math.floor(pct * 100) .. "%", UDim2.fromScale(0, 0.1), UDim2.fromScale(1, 0.8), nil, nil, 3)
	local confirm = false
	local b, bl = U.button({Text = "REBIRTH", Color = have >= cost and U.GREEN or U.GREY, Size = UDim2.new(0.42, 0, 0, 64), Position = UDim2.new(0.29, 0, 0, 132), Radius = 8, StrokeT = 4, Parent = holder})
	b.MouseButton1Click:Connect(function()
		if have < cost then ctx.Toast("Not enough Hand Signs", C(255, 90, 90)) return end
		if not confirm then confirm = true; bl.Text = "TAP AGAIN TO CONFIRM"; return end
		act("Rebirth")
	end)
	label(holder, "Rebirths: " .. reb .. "   ·   Kept: stages, signs, pets, auras, upgrades, Trophies", UDim2.new(0.05, 0, 0, 206), UDim2.new(0.9, 0, 0, 24), C(210, 200, 255), nil, 2)
end

---------------------------------------------------------------- STAGES
builders.Stages = function(parent)
	grid(parent, UDim2.fromOffset(150, 84), 8)
	local p = prof() or {}
	local done = p.Completed or {}
	local highest = attr("Highest") or 1
	do -- lobby hub (issue #14)
		local f = card(parent, C(236, 128, 56), 0)
		label(f, "\u{26E9} LOBBY", UDim2.fromOffset(6, 4), UDim2.new(1, -12, 0, 24))
		label(f, "SHINOBI PLAZA", UDim2.fromOffset(6, 28), UDim2.new(1, -12, 0, 18), C(255, 240, 220), nil, 1.5)
		local b = U.button({Text = "GO", Color = U.GREEN, Size = UDim2.new(1, -12, 0, 28), Position = UDim2.new(0, 6, 1, -34), Parent = f})
		b.MouseButton1Click:Connect(function() ctx.TeleportStage:FireServer(0); M.Close() end)
	end
	for i, st in Config.Stages do
		local open = i <= highest
		local f = card(parent, open and U.shade(st.Gate, 0.75) or C(60, 60, 72), i)
		label(f, (done[tostring(i)] and "\u{2705} " or "") .. "STAGE " .. i, UDim2.fromOffset(6, 4), UDim2.new(1, -12, 0, 24))
		label(f, open and st.Name or "\u{1F512} " .. fmt(st.Recommended), UDim2.fromOffset(6, 28), UDim2.new(1, -12, 0, 18), C(240, 240, 255), nil, 1.5)
		if open then
			local b = U.button({Text = "GO", Color = U.GREEN, Size = UDim2.new(1, -12, 0, 28), Position = UDim2.new(0, 6, 1, -34), Parent = f})
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
	local b = U.button({Text = btnText, Color = enabled and U.GREEN or U.GREY, Size = UDim2.new(0.33, 0, 0, 46), Position = UDim2.new(1, -10, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), Parent = f})
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
	local b = U.button({Text = "REDEEM", Color = U.GREEN, Size = UDim2.new(0.5, 0, 0, 52), LayoutOrder = 3, Parent = parent})
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
