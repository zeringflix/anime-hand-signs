-- Menu panels: Hand Signs, Pets, Auras, Upgrades, Rebirth, Stages, Rewards, Codes, Shop, Top, Settings.
-- Panels only display state and ask the server (Action remote); nothing here grants anything.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Config = require(ReplicatedStorage.Shared.Config)
local SC = require(ReplicatedStorage.Shared.SystemsConfig)
local U = require(script.Parent.UIKit)
local Looks = require(script.Parent.Looks)
local Sfx = require(script.Parent.Sfx)

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
	if res.ok == false and res.msg then ctx.Toast(res.msg, C(255, 90, 90)); Sfx.Play("Error") end
	if res.ok and (res.bought or res.what) then Sfx.Play(res.bought and "Buy" or "Reward") end
	return res
end
M.Act = act
local function prof() return ctx.Profile end
local function attr(n: string) return player:GetAttribute(n) end

---------------------------------------------------------------- panel shell (+1 Anime Eyes-style: studded coloured header, red X, slate body)
local TAB_ICON = {Signs = "HandSign", Pets = "Pets", Auras = "Aura", Upgrades = "Upgrades", Rebirth = "Rebirth", Stages = "Places",
	Rewards = "Gift", Quests = "Quests", Daily = "Daily", Gifts = "Gift", Shop = "Shop", Top = "Crown", Codes = "Codes", Settings = "Settings"}
local TAB_TITLE = {Signs = "My Hand Signs", Pets = "Pets", Auras = "Auras", Upgrades = "Upgrades", Rebirth = "Rebirth", Stages = "Worlds",
	Rewards = "Rewards", Quests = "Quests", Daily = "Daily Rewards", Gifts = "Free Gifts", Shop = "Store", Top = "Leaderboards", Codes = "Codes", Settings = "Settings"}
local TAB_COLOR = {Signs = C(232, 62, 92), Pets = C(232, 62, 92), Auras = C(232, 62, 92), Shop = C(232, 62, 92), Gifts = C(232, 62, 92),
	Rebirth = C(150, 74, 230), Rewards = C(150, 74, 230), Quests = C(255, 150, 40), Codes = C(150, 74, 230), Settings = C(150, 74, 230), Top = C(150, 74, 230),
	Daily = C(60, 150, 240), Upgrades = C(60, 180, 90), Stages = C(150, 74, 230)}
-- header tones from the pack palette (Hand Signs = blue like the mockup the owner picked, Store = red)
local TAB_TONE = {Signs = "Blue", Pets = "Green", Auras = "Pink", Shop = "Red", Gifts = "Pink", Rebirth = "Purple", Rewards = "Gold", Quests = "Gold",
	Codes = "Purple", Settings = "Grey", Top = "Gold", Daily = "Green", Upgrades = "Lime", Stages = "Blue"}
local headerIcon: ImageLabel
local headerFrame: Frame
local detail: Frame? = nil
function M.Init(c)
	ctx = c
	root = U.new("Frame", {Name = "Panel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromScale(0.6, 0.74),
		BackgroundColor3 = C(18, 18, 22), BackgroundTransparency = 0.12, Visible = false, Parent = c.Gui, ZIndex = 5})
	U.new("UISizeConstraint", {MinSize = Vector2.new(300, 280), MaxSize = Vector2.new(900, 640), Parent = root})
	U.corner(6).Parent = root
	U.stroke(4, C(0, 0, 0), Enum.ApplyStrokeMode.Border).Parent = root
	local bodyRim = U.new("Frame", {Name = "BodyRim", Position = UDim2.fromOffset(3, 3), Size = UDim2.new(1, -6, 1, -6), BackgroundTransparency = 1, ZIndex = 5, Parent = root})
	U.corner(4).Parent = bodyRim
	U.new("UIStroke", {Thickness = 2, Color = Color3.new(1, 1, 1), Transparency = 0.2, Parent = bodyRim})
	-- Studs Pack header: two-tone studded bar with shine, the panel's icon popping out of the top-left corner
	headerFrame = U.new("Frame", {Name = "Header", Size = UDim2.new(1, 0, 0, 72), BackgroundColor3 = C(255, 255, 255), ZIndex = 5, Parent = root})
	U.corner(6).Parent = headerFrame
	U.stroke(4, C(0, 0, 0), Enum.ApplyStrokeMode.Border).Parent = headerFrame
	U.gloss(headerFrame, U.TONES.Red[1], 6, U.TONES.Red[2])
	studs(headerFrame, 0.3, 34)
	headerIcon = U.new("ImageLabel", {BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Size = UDim2.fromOffset(112, 112), Position = UDim2.fromOffset(-26, -34), Rotation = -10, ZIndex = 9, Parent = headerFrame})
	titleLabel = label(headerFrame, "", UDim2.fromOffset(100, 8), UDim2.new(1, -190, 1, -16), nil, Enum.TextXAlignment.Left, 4)
	titleLabel.FontFace = U.FontHeavy
	titleLabel.ZIndex = 7
	local close = U.button({Name = "Close", Text = "X", Color = U.TONES.Close[1], Color2 = U.TONES.Close[2], Size = UDim2.fromOffset(56, 56), Position = UDim2.new(1, -10, 0, 8), AnchorPoint = Vector2.new(1, 0), Radius = 6, StrokeT = 3.5, StudTile = 18, Parent = headerFrame})
	close.ZIndex = 8
	close:SetAttribute("HoverWired", nil)
	U.hover(close, {Scale = 1.12, Tilt = 12})
	close.MouseButton1Click:Connect(function() M.Close() end)
	body = U.new("ScrollingFrame", {Position = UDim2.fromOffset(14, 88), Size = UDim2.new(1, -28, 1, -100), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 10, ScrollBarImageColor3 = C(255, 255, 255), AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ZIndex = 5, Parent = root})
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

local PANEL_POS = UDim2.fromScale(0.5, 0.52)
local motionToken = 0
local sideTabs: Frame? = nil
local function clearSideTabs() if sideTabs then sideTabs:Destroy(); sideTabs = nil end end
function M.Open(id: string)
	if current == id and root.Visible then M.Close(); return end
	local fresh = not root.Visible
	current = id
	motionToken += 1
	clearSideTabs()
	if detail then detail:Destroy(); detail = nil end
	local tone = U.TONES[TAB_TONE[id] or "Red"]
	titleLabel.Text = string.upper(TAB_TITLE[id] or id)
	U.fill(headerFrame, tone[1], tone[2])
	headerIcon.Image = (id == "Signs" and AssetsMod.SignIcons and AssetsMod.SignIcons[attr("Equipped") or "Tiger"]) or AssetsMod.Icon(TAB_ICON[id])
	if M.Fit then M.Fit() end
	local sc = U.motionScale(root)
	root.Position = PANEL_POS
	root.Rotation = 0
	if fresh then -- HUD slides away, world blurs, the panel lands from oversize
		if ctx.SetHud then ctx.SetHud(false) end
		U.menuWorld(true)
		sc.Scale = 1.32
		root.Visible = true
		U.tween(sc, 0.3, {Scale = 1}, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	else -- switching panels: quick squash-pop
		sc.Scale = 0.9
		U.tween(sc, 0.25, {Scale = 1}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	end
	U.sweep(headerFrame)
	M.Refresh()
	U.intro(body, fresh and 0.16 or 0.05)
end

function M.Close()
	clearSideTabs()
	if not root.Visible then current = nil; return end
	Sfx.Play("Close")
	current = nil
	motionToken += 1
	local my = motionToken
	if detail then detail:Destroy(); detail = nil end
	local sc = U.motionScale(root)
	U.tween(sc, 0.18, {Scale = 0.72}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	U.tween(root, 0.18, {Position = UDim2.fromScale(0.5, 0.8), Rotation = 4}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	if ctx.SetHud then ctx.SetHud(true) end
	U.menuWorld(false)
	task.delay(0.19, function()
		if my ~= motionToken then return end -- reopened meanwhile
		root.Visible = false
		root.Position = PANEL_POS
		root.Rotation = 0
		sc.Scale = 1
	end)
end

-- live countdowns (Daily / Gifts) without rebuilding the panel every second
local tickers: {() -> ()} = {}
task.spawn(function()
	local n = 0
	while true do
		task.wait(1)
		n += 1
		if root and root.Visible and n % 4 == 0 and headerFrame then U.sweep(headerFrame) end
		if root and root.Visible then
			for i = #tickers, 1, -1 do
				local ok = pcall(tickers[i])
				if not ok then table.remove(tickers, i) end
			end
		end
	end
end)

function M.Refresh()
	if not root.Visible or not current then return end
	local y = body.CanvasPosition
	for _, ch in body:GetChildren() do ch:Destroy() end
	table.clear(tickers)
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
	local text, tone
	if st == "Equipped" then text, tone = "EQUIPPED", U.TONES.Blue
	elseif st == "Owned" then text, tone = "EQUIP", U.TONES.Lime
	elseif st == "Buy" then text, tone = fmt(s.Price), U.TONES.Gold
	else text, tone = fmt(s.Price), U.TONES.Dark end
	local b, bl = U.button({Text = text, Color = tone[1], Color2 = tone[2], Size = size, Position = pos, AnchorPoint = Vector2.new(0.5, 1), Radius = 6, StrokeT = 3, StudTile = 16, Parent = parent})
	if st == "Buy" or st == "Locked" then U.iconLeft(b, bl, AssetsMod.Icon("Trophy"), 0.24) end
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
		local f = card(parent, C(86, 86, 92), i)
		-- tier colour survives as a coloured inner rim + tinted light burst (pack "Index" card look)
		local tierRim = U.new("Frame", {Position = UDim2.fromOffset(3, 3), Size = UDim2.new(1, -6, 1, -6), BackgroundTransparency = 1, Parent = f})
		U.corner(6).Parent = tierRim
		U.new("UIStroke", {Thickness = 2.5, Color = TIER_COLOR[i] or C(150, 90, 230), Parent = tierRim})
		U.new("ImageLabel", {Name = "Burst", BackgroundTransparency = 1, Image = "rbxassetid://98508264222687", ScaleType = Enum.ScaleType.Fit,
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.43), Size = UDim2.fromScale(1.05, 0.86),
			ImageColor3 = (TIER_COLOR[i] or C(255, 255, 255)):Lerp(Color3.new(1, 1, 1), 0.55), ImageTransparency = 0.1, ZIndex = 5, Parent = f})
		if i >= 13 then -- top tiers get a rainbow card like the reference's best eyes
			f:FindFirstChildOfClass("UIGradient").Color = ColorSequence.new({ColorSequenceKeypoint.new(0, C(255, 120, 140)), ColorSequenceKeypoint.new(0.35, C(255, 230, 120)),
				ColorSequenceKeypoint.new(0.7, C(130, 255, 170)), ColorSequenceKeypoint.new(1, C(140, 180, 255))})
			f:FindFirstChildOfClass("UIGradient").Rotation = 30
			f.BackgroundColor3 = Color3.new(1, 1, 1)
		end
		local nm = label(f, string.upper(s.Name), UDim2.fromScale(0.04, 0.025), UDim2.fromScale(0.92, 0.13), nil, nil, 3.5)
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
		local nameL = label(f, string.upper(egg.Name), UDim2.fromOffset(6, 4), UDim2.new(1, -12, 0, 24))
		nameL.Font = U.TitleFont
		if egg.Robux then U.rainbow(nameL) end
		local eggShape = U.new("Frame", {Size = UDim2.fromOffset(44, 56), Position = UDim2.new(0, 10, 0, 34), BackgroundColor3 = egg.Color, Parent = f})
		U.corner(26).Parent = eggShape
		U.stroke(3).Parent = eggShape
		for k, row in egg.Odds do
			local def = SC.Pets[row.Pet]
			label(f, def.Name .. "  " .. row.Chance .. "%", UDim2.new(0, 60, 0, 30 + (k - 1) * 17), UDim2.new(1, -66, 0, 16), SC.RarityColor[def.Rarity] == SC.RarityColor.Secret and C(255, 255, 255) or SC.RarityColor[def.Rarity], Enum.TextXAlignment.Left, 1.5)
		end
		label(f, "+" .. SC.Pets[egg.Odds[1].Pet].Boost .. " to +" .. fmt(SC.Pets[egg.Odds[#egg.Odds].Pet].Boost) .. " boost", UDim2.fromOffset(6, 104), UDim2.new(1, -12, 0, 16), C(255, 235, 120))
		if egg.Robux then
			local b, bl = U.button({Text = "R$ " .. egg.Robux .. "  HATCH", Color = U.GREEN, Size = UDim2.new(1, -12, 0, 44), Position = UDim2.new(0, 6, 1, -52), Parent = f})
			U.rainbow(bl)
			b.MouseButton1Click:Connect(function() act("Hatch", eggId) end)
		elseif open then
			local b, bl = U.button({Text = fmt(egg.Cost) .. "  HATCH", Color = U.TONES.Lime[1], Color2 = U.TONES.Lime[2], Size = UDim2.new(1, -12, 0, 44), Position = UDim2.new(0, 6, 1, -52), Parent = f})
			U.iconLeft(b, bl, AssetsMod.Icon("Trophy"), 0.2)
			b.MouseButton1Click:Connect(function()
				local res = act("Hatch", eggId)
				if res and res.ok then ctx.HatchAnimation(eggId, res.pet) end
			end)
		else
			label(f, "LOCKED: STAGE " .. egg.Stage, UDim2.new(0, 6, 1, -46), UDim2.new(1, -12, 0, 30), C(255, 130, 130))
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
			local lock = U.button({Text = rec.Locked and "UNLOCK" or "LOCK", Color = C(120, 120, 220), Size = UDim2.new(0.5, -6, 0, 28), Position = UDim2.fromOffset(4, 156), Parent = f})
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
			local pr = label(f, highest >= a.Stage and (fmt(a.Cost) .. " TROPHIES") or ("STAGE " .. a.Stage), UDim2.new(0.42, 0, 0.5, -16), UDim2.new(0.24, 0, 0, 32), Color3.new(1, 1, 1), Enum.TextXAlignment.Right, 3)
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
		local b, bl = U.button({Text = maxed and "MAX" or fmt(SC.UpgradeCost(id, lvl)), Color = maxed and U.GREY or U.GREEN,
			Size = UDim2.new(0.33, 0, 0, 50), Position = UDim2.new(1, -10, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), Parent = f})
		if not maxed then U.iconLeft(b, bl, AssetsMod.Icon("Trophy"), 0.22) end
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
		label(f, "LOBBY", UDim2.fromOffset(6, 4), UDim2.new(1, -12, 0, 24))
		label(f, "SHINOBI PLAZA", UDim2.fromOffset(6, 28), UDim2.new(1, -12, 0, 18), C(255, 240, 220), nil, 1.5)
		local b = U.button({Text = "GO", Color = U.GREEN, Size = UDim2.new(1, -12, 0, 28), Position = UDim2.new(0, 6, 1, -34), Parent = f})
		b.MouseButton1Click:Connect(function() ctx.TeleportStage:FireServer(0); M.Close() end)
	end
	for i, st in Config.Stages do
		local open = i <= highest
		local f = card(parent, open and U.shade(st.Gate, 0.75) or C(60, 60, 72), i)
		label(f, "STAGE " .. i .. (done[tostring(i)] and " \u{2713}" or ""), UDim2.fromOffset(6, 4), UDim2.new(1, -12, 0, 24))
		label(f, open and st.Name or ("LOCKED  " .. fmt(st.Recommended)), UDim2.fromOffset(6, 28), UDim2.new(1, -12, 0, 18), C(240, 240, 255), nil, 1.5)
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

---------------------------------------------------------------- QUESTS (stage milestones + offline earnings)
builders.Quests = function(parent)
	list(parent, 8)
	local p = prof() or {}
	if (p.PendingOffline or 0) > 0 then
		rewardRow(parent, 0, "WHILE YOU WERE AWAY", "+" .. fmt(p.PendingOffline) .. " Hand Signs", "CLAIM", true, function() act("ClaimOffline") end)
	end
	for i, stage in SC.MilestoneStages do
		local key = tostring(stage)
		local claimed = p.ClaimedMilestones and p.ClaimedMilestones[key]
		local done = p.Completed and p.Completed[key]
		rewardRow(parent, 10 + i, "CLEAR STAGE " .. stage, "+" .. fmt(Config.Stages[stage].Trophies * 50) .. " Trophies", claimed and "CLAIMED" or (done and "CLAIM" or "LOCKED"), done and not claimed, function()
			local r = act("ClaimMilestone", stage)
			if r and r.ok then ctx.Toast("+" .. fmt(r.amount) .. " Trophies!", C(255, 220, 80)) end
		end)
	end
end
builders.Rewards = builders.Quests

-- reward row -> icon key + short text (Daily week + Free Gifts pools)
local function rewardInfo(row: any): (string, string)
	local st = Config.Stages[attr("Highest") or 1] or Config.Stages[1]
	if row.Kind == "Trophies" then return "Trophy", "+" .. fmt(math.max(5, math.floor(st.Trophies * row.Mult))) end
	if row.Kind == "Boost" then return "Boost", "x2 Signs " .. row.Minutes .. "m" end
	if row.Kind == "TrophyBoost" then return "TrophyBoost", "x2 Trophies " .. row.Minutes .. "m" end
	if row.Kind == "Hatch" then return "Egg", "x" .. (row.Count or 1) .. " " .. (SC.Eggs[row.Egg] and SC.Eggs[row.Egg].Name or "Egg") end
	if row.Kind == "Aura" then return "Aura", SC.Auras[row.Aura] and SC.Auras[row.Aura].Name or "Aura" end
	if row.Kind == "Pet" then return "Pets", SC.Pets[row.Pet] and SC.Pets[row.Pet].Name or "Pet" end
	return "Gift", ""
end
local function iconImg(parent: Instance, key: string, size: UDim2, pos: UDim2, z: number?): ImageLabel
	return U.new("ImageLabel", {BackgroundTransparency = 1, Image = AssetsMod.Icon(key), ScaleType = Enum.ScaleType.Fit, AnchorPoint = Vector2.new(0.5, 0.5),
		Size = size, Position = pos, ZIndex = z or 7, Parent = parent})
end
-- studded rounded tile (reference reward cards): colour + darker rim
local function tileCard(parent: Instance, color: Color3, size: UDim2, pos: UDim2, z: number?): Frame
	local f = U.new("Frame", {BackgroundColor3 = color, Size = size, Position = pos, ZIndex = z or 6, Parent = parent})
	U.corner(8).Parent = f
	U.stroke(4, U.OUTLINE, Enum.ApplyStrokeMode.Border).Parent = f
	U.grad(Color3.new(1, 1, 1), C(215, 215, 215)).Parent = f
	local sd = U.studs(f, 0.15, 26); sd.ZIndex = z or 6
	return f
end
local function clockText(s: number): string
	s = math.max(0, math.floor(s))
	if s >= 3600 then return string.format("%d:%02d:%02d", s // 3600, (s % 3600) // 60, s % 60) end
	return string.format("%d:%02d", s // 60, s % 60)
end

---------------------------------------------------------------- DAILY REWARDS (7-day week, +1 Anime Eyes layout)
builders.Daily = function(parent)
	local p = prof() or {}
	local serverOffset = (p.ServerTime or os.time()) - os.time()
	local nextDay = p.DailyNextDay or 1
	local streak = p.DailyStreak or 0
	local week = nextDay == 1 and (math.floor(streak / 7) + (streak > 0 and 1 or 0)) or (math.floor((streak - 1) / 7) + 1)
	week = math.max(week, 1)
	local holder = U.new("Frame", {Size = UDim2.new(1, -6, 0, 488), BackgroundTransparency = 1, Parent = parent})
	local wk = U.title({Text = "WEEK " .. week, Size = UDim2.new(0.3, 0, 0, 34), Position = UDim2.new(0, 4, 0, -2), TextColor3 = C(255, 222, 60), ZIndex = 7, Parent = holder})
	wk.TextXAlignment = Enum.TextXAlignment.Left
	local timers = {}
	for d = 1, 7 do
		local row = SC.DailyWeek[d]
		local big = d == 7
		local col, rowI = (d - 1) % 3, (d - 1) // 3
		local size = big and UDim2.new(0.24, 0, 0, 404) or UDim2.new(0.235, 0, 0, 194)
		local pos = big and UDim2.new(0.755, 0, 0, 38) or UDim2.new(col * 0.25, 0, 0, 38 + rowI * 210)
		local f = tileCard(holder, big and C(255, 255, 255) or C(70, 160, 245), size, pos)
		if big then -- rainbow Day 7 card
			local g = f:FindFirstChildOfClass("UIGradient"); if g then g:Destroy() end
			local rg = U.new("UIGradient", {Rotation = 35, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, C(255, 90, 90)), ColorSequenceKeypoint.new(0.25, C(255, 220, 70)),
				ColorSequenceKeypoint.new(0.5, C(110, 240, 110)), ColorSequenceKeypoint.new(0.75, C(90, 170, 255)), ColorSequenceKeypoint.new(1, C(200, 110, 255))}), Parent = f})
			local _ = rg
		end
		U.title({Text = "Day " .. d, Size = UDim2.new(1, -8, 0, big and 46 or 30), Position = UDim2.fromOffset(4, 4), ZIndex = 8, Parent = f})
		local key, txt = rewardInfo(row)
		if row.Kind == "Pet" then
			local vp = petViewport(f, row.Pet, UDim2.new(1, -10, 0, 170), UDim2.fromOffset(5, 56)); vp.ZIndex = 8
		else
			iconImg(f, key, big and UDim2.fromOffset(150, 150) or UDim2.fromOffset(76, 76), UDim2.new(0.5, 0, 0, big and 140 or 78), 8)
		end
		local t = U.title({Text = txt, Size = UDim2.new(1, -8, 0, big and 64 or 24), Position = UDim2.new(0, 4, 0, big and 236 or 112), ZIndex = 8, Parent = f})
		t.TextWrapped = true
		local state = d < nextDay and "Claimed" or (d == nextDay and "Next" or "Later")
		local b, bl = U.button({Text = state == "Claimed" and "CLAIMED" or ("DAY " .. d), Color = U.GREY, Size = UDim2.new(0.86, 0, 0, big and 60 or 40),
			Position = UDim2.new(0.07, 0, 1, big and -74 or -48), Radius = 6, StrokeT = 3, Parent = f})
		b.ZIndex = 9
		bl.Font = U.TitleFont
		if state == "Next" then
			local function upd()
				local left = (p.LastDaily or 0) + SC.DailyCooldown - (os.time() + serverOffset)
				if left <= 0 then bl.Text = "CLAIM"; U.recolor(b, U.GREEN) else bl.Text = clockText(left); U.recolor(b, U.GREY) end
			end
			upd(); table.insert(timers, upd)
			b.MouseButton1Click:Connect(function()
				local r = act("ClaimDaily")
				if r and r.ok then ctx.Celebrate("DAY " .. r.day .. "!", r.what, C(120, 220, 255)) end
			end)
		end
	end
	for _, f in timers do table.insert(tickers, f) end
	-- skip: Robux product (Id 0 = not available yet), rainbow price like every Robux item
	local dp = SC.DevProducts.DailyUnlockAll
	local ub, ul = U.button({Text = "UNLOCK ALL  R$ " .. dp.Robux, Color = U.GREEN, Size = UDim2.new(0.42, 0, 0, 48), Position = UDim2.new(0.58, 0, 0, -4), Radius = 8, StrokeT = 3, Parent = holder})
	ub.Position = UDim2.new(1, 0, 0, 450); ub.AnchorPoint = Vector2.new(1, 0); ub.Size = UDim2.new(0.4, 0, 0, 46)
	ul.Font = U.TitleFont
	U.rainbow(ul)
	ub.MouseButton1Click:Connect(function() act("BuyProduct", "DailyUnlockAll") end)
end

---------------------------------------------------------------- FREE GIFTS (5 / 15 / 60 min timers, +1 Anime Eyes layout)
builders.Gifts = function(parent)
	local p = prof() or {}
	local serverOffset = (p.ServerTime or os.time()) - os.time()
	local holder = U.new("Frame", {Size = UDim2.new(1, -6, 0, 420), BackgroundTransparency = 1, Parent = parent})
	for i, g in SC.Gifts do
		local f = tileCard(holder, g.Color, UDim2.new(0.32, 0, 1, -6), UDim2.new((i - 1) * 0.34, 0, 0, 0))
		U.title({Text = g.Title, Size = UDim2.new(1, -8, 0, 34), Position = UDim2.fromOffset(4, 6), ZIndex = 8, Parent = f})
		iconImg(f, g.Icon, UDim2.fromOffset(92, 92), UDim2.new(0.5, 0, 0, 96), 8)
		local used = p.GiftCounts and p.GiftCounts[g.Id] or 0
		U.title({Text = (g.PerDay - used) .. "/" .. g.PerDay .. " left", Size = UDim2.new(1, -8, 0, 26), Position = UDim2.fromOffset(4, 144), TextColor3 = C(255, 222, 60), ZIndex = 8, Parent = f})
		local gridF = U.new("Frame", {Size = UDim2.new(1, -12, 0, 170), Position = UDim2.fromOffset(6, 174), BackgroundTransparency = 1, ZIndex = 8, Parent = f})
		U.new("UIGridLayout", {CellSize = UDim2.new(0.31, 0, 0, 80), CellPadding = UDim2.fromOffset(5, 5), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = gridF})
		for k, row in g.Pool do
			local key, txt = rewardInfo(row)
			local rare = row.Chance <= 3
			local cell = U.new("Frame", {BackgroundColor3 = rare and C(255, 190, 40) or (row.Kind == "Trophies" and C(120, 120, 135) or C(150, 90, 230)), LayoutOrder = k, ZIndex = 8, Parent = gridF})
			U.corner(6).Parent = cell
			U.stroke(3, U.OUTLINE, Enum.ApplyStrokeMode.Border).Parent = cell
			local sd = U.studs(cell, 0.3, 18); sd.ZIndex = 8
			iconImg(cell, key, UDim2.fromScale(0.62, 0.5), UDim2.fromScale(0.5, 0.33), 9)
			local tl = U.text({Text = txt, Size = UDim2.new(1, -4, 0.24, 0), Position = UDim2.new(0, 2, 0.55, 0), ZIndex = 9, Stroke = 2, Parent = cell})
			local _ = tl
			U.text({Text = row.Chance .. "%", Size = UDim2.new(1, -4, 0.2, 0), Position = UDim2.new(0, 2, 0.78, 0), TextColor3 = C(255, 230, 120), ZIndex = 9, Stroke = 2, Parent = cell})
			if rare then U.rainbow(tl) end
		end
		local b, bl = U.button({Text = "", Color = C(235, 60, 80), Size = UDim2.new(0.88, 0, 0, 50), Position = UDim2.new(0.06, 0, 1, -60), Radius = 6, StrokeT = 3, Parent = f})
		b.ZIndex = 9
		bl.Font = U.TitleFont
		local function upd()
			local at = p.GiftReady and p.GiftReady[g.Id] or math.huge
			local left = at - (os.time() + serverOffset)
			if used >= g.PerDay then bl.Text = "DONE TODAY"; U.recolor(b, U.GREY)
			elseif left <= 0 then bl.Text = "CLAIM!"; U.recolor(b, U.GREEN)
			else bl.Text = clockText(left); U.recolor(b, C(235, 60, 80)) end
		end
		upd(); table.insert(tickers, upd)
		b.MouseButton1Click:Connect(function()
			local r = act("ClaimGift", g.Id)
			if r and r.ok then ctx.Celebrate("FREE GIFT!", r.what, C(255, 220, 80)) end
		end)
	end
end

---------------------------------------------------------------- STORE (Robux items wear rainbow animated text)
local function shopCard(parent: Instance, order: number, color: Color3, title: string, sub: string, price: string, robux: boolean, onBuy: () -> (), petId: string?, iconKey: string?)
	local f = card(parent, color, order)
	if petId then
		local vp = petViewport(f, petId, UDim2.new(1, -8, 0, 120), UDim2.fromOffset(4, 30)); vp.ZIndex = 7
	elseif iconKey then
		iconImg(f, iconKey, UDim2.fromOffset(96, 96), UDim2.new(0.5, 0, 0, 86), 7)
	end
	local t = U.title({Text = title, Size = UDim2.new(1, -10, 0, 28), Position = UDim2.fromOffset(5, 4), ZIndex = 8, Parent = f})
	if robux then U.rainbow(t) end
	label(f, sub, UDim2.new(0, 5, 0, 152), UDim2.new(1, -10, 0, 22), C(255, 236, 140), nil, 2).ZIndex = 8
	local b, bl = U.button({Text = price, Color = U.GREEN, Size = UDim2.new(1, -14, 0, 44), Position = UDim2.new(0, 7, 1, -52), Radius = 6, StrokeT = 3, Parent = f})
	b.ZIndex = 8
	bl.Font = U.TitleFont -- Robux titles are rainbow; the price stays white on green for contrast
	b.MouseButton1Click:Connect(onBuy)
	return f
end
local function section(parent: Instance, order: number, text: string)
	local h = U.title({Text = text, Size = UDim2.new(1, -8, 0, 36), TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = order, Parent = parent})
	return h
end
-- reference: small category buttons hang off the panel's left edge and jump the list to a section
local tabMarks: {GuiObject} = {} -- rebuilt with the list on every Refresh; the side tabs read the current ones
local function addSideTabs(marks: {{any}})
	clearSideTabs()
	sideTabs = U.new("Frame", {Name = "SideTabs", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(0, -8, 0, 92),
		Size = UDim2.fromOffset(70, #marks * 82), ZIndex = 6, Parent = root})
	U.new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = sideTabs})
	for i, m in marks do
		local b = U.new("TextButton", {Text = "", BackgroundTransparency = 1, Size = UDim2.fromOffset(70, 74), LayoutOrder = i, ZIndex = 6, Parent = sideTabs})
		U.new("ImageLabel", {BackgroundTransparency = 1, Image = AssetsMod.Icon(m[2]), ScaleType = Enum.ScaleType.Fit, Size = UDim2.fromOffset(52, 52), Position = UDim2.fromOffset(9, 0), ZIndex = 6, Parent = b})
		U.text({Text = m[3], Size = UDim2.fromOffset(70, 20), Position = UDim2.fromOffset(0, 52), Stroke = 2.5, ZIndex = 7, Parent = b})
		U.hover(b, {Scale = 1.15, Tilt = 6})
		b.MouseButton1Click:Connect(function()
			Sfx.Play("Click")
			local mark = tabMarks[i]
			if not (mark and mark.Parent) then return end
			-- CanvasPosition is in on-screen pixels, the same space as AbsolutePosition
			local y = body.CanvasPosition.Y + (mark.AbsolutePosition.Y - body.AbsolutePosition.Y)
			U.tween(body, 0.35, {CanvasPosition = Vector2.new(0, math.max(0, y - 6))}, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
			U.pop(mark, 1.25)
		end)
	end
	U.intro(sideTabs, 0.2)
end
builders.Shop = function(parent)
	list(parent, 10)
	local p = prof() or {}
	local passes = p.Passes or {}
	local m1 = section(parent, 1, "SPECIAL PETS")
	local pets = U.new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 2, Parent = parent})
	grid(pets, UDim2.fromOffset(190, 236), 10)
	for i, rp in SC.RobuxPets do
		local def = SC.Pets[rp.Pet]
		shopCard(pets, i, rp.Special and C(255, 140, 40) or C(120, 80, 220), def.Name, "x" .. fmt(1 + def.Boost) .. " Hand Signs", "R$ " .. rp.Robux, true,
			function() act("BuyProduct", rp.Product) end, rp.Pet)
	end
	local m2 = section(parent, 3, "ROBUX EGGS")
	local eggs = U.new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 4, Parent = parent})
	grid(eggs, UDim2.fromOffset(190, 236), 10)
	local n = 0
	for _, eggId in SC.EggOrder do
		local egg = SC.Eggs[eggId]
		if egg.Robux then
			n += 1
			local best = SC.Pets[egg.Odds[#egg.Odds].Pet]
			shopCard(eggs, n, U.shade(egg.Color, 0.8), egg.Name, "Up to " .. best.Name, "R$ " .. egg.Robux, true, function() act("Hatch", eggId) end, nil, "Egg")
		end
	end
	local m3 = section(parent, 5, "GAME PASSES")
	local gps = U.new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 6, Parent = parent})
	grid(gps, UDim2.fromOffset(190, 236), 10)
	local order = 0
	for key, gp in SC.GamePasses do
		if not key:match("^Zone") then -- training zones are bought at the zone itself
			order += 1
			local owned = passes[key]
			shopCard(gps, order, C(70, 150, 240), gp.Name, owned and "OWNED" or "Game pass", owned and "OWNED" or (gp.Id == 0 and "SOON" or "BUY"), true,
				function() if not owned then act("BuyPass", key) end end, nil, key == "DoubleTrophies" and "TrophyBoost" or (key == "AutoClicker" and "Clock" or "Star"))
		end
	end
	local m4 = section(parent, 7, "BOOSTS & PACKS")
	tabMarks = {m1, m2, m3, m4}
	if not sideTabs then addSideTabs({{m1, "Pets", "PETS"}, {m2, "Egg", "EGGS"}, {m3, "Crown", "PASSES"}, {m4, "Boost", "BOOSTS"}}) end
	local dps = U.new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 8, Parent = parent})
	grid(dps, UDim2.fromOffset(190, 236), 10)
	order = 0
	for _, key in {"Boost15", "PackSmall", "PackMedium", "PackLarge"} do
		local dp = SC.DevProducts[key]
		order += 1
		shopCard(dps, order, C(255, 150, 40), dp.Name, dp.Id == 0 and "Coming soon" or "Developer product", dp.Id == 0 and "SOON" or "BUY", true,
			function() act("BuyProduct", key) end, nil, key == "Boost15" and "Boost" or "Chakra")
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
