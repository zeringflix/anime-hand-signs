-- HUD layout matching the +1 reference: chunky left menu grid, top-right icon row, event bar,
-- stacked multipliers + big counter + level bar + packs (bottom centre), ATTACK/E/R + auto clickers (bottom right).
-- Pure view: Main wires data and input into the elements returned here.
local U = require(script.Parent.UIKit)
local Assets = require(game.ReplicatedStorage.Shared.Assets)
local SC = require(game.ReplicatedStorage.Shared.SystemsConfig)
local C = Color3.fromRGB
local function img(props: {[string]: any}): ImageLabel
	local i = U.new("ImageLabel", {BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Image = Assets.Icon(props.Icon)})
	props.Icon = nil
	for k, v in props do (i :: any)[k] = v end
	return i
end
local H = {}

-- Studs Pack tile (owner pick: UI variant 1): two-tone gradient body, black outline, white rim, raised studs,
-- shine band, big pack icon, Gotham label over the bottom edge. `color` may be a U.TONES pair.
local function tile(parent: Instance, color: Color3 | {Color3}, icon: string, label: string, size: Vector2, order: number?)
	local c1, c2 = color, nil
	if type(color) == "table" then c1, c2 = color[1], color[2] end
	local b = U.button({Text = "", Color = c1 :: Color3, Color2 = c2, Size = UDim2.fromOffset(size.X, size.Y), Radius = 6, StrokeT = 3.5, StudTile = 30, LayoutOrder = order or 0, Parent = parent})
	local ic = img({Icon = icon, AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.new(0.86, 0, 0.7, 0), Position = UDim2.new(0.5, 0, 0.0, 0), ZIndex = 2, Parent = b})
	local lb = U.text({Text = string.upper(label), Font = U.TitleFont, Size = UDim2.new(1, -4, 0.27, 0), Position = UDim2.new(0, 2, 0.71, 0), Stroke = 3, ZIndex = 3, Parent = b})
	return b, ic, lb
end
H.Tile = tile
H.Img = img

function H.Build(gui: ScreenGui)
	local E = {}

	---------------------------------------------------------------- left menu: 2-column tile grid (reference: Store, Quests, My Eyes, Rebirth, Auras, Pets)
	local left = U.new("Frame", {Name = "LeftMenu", Position = UDim2.fromOffset(14, 92), Size = UDim2.fromOffset(196, 300), BackgroundTransparency = 1, Parent = gui})
	U.new("UIGridLayout", {CellSize = UDim2.fromOffset(92, 92), CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = left})
	E.Grid = {}
	local gridDefs = {
		{"Shop", "Shop", "Store", U.TONES.Red}, {"Quests", "Quests", "Quests", U.TONES.Gold},
		{"Signs", "HandSign", "Signs", U.TONES.Blue}, {"Rebirth", "Rebirth", "Rebirth", U.TONES.Purple},
		{"Auras", "Aura", "Auras", U.TONES.Pink}, {"Pets", "Pets", "Pets", U.TONES.Green},
	}
	for i, d in gridDefs do
		local b, ic, lb = tile(left, d[4], d[2], d[3], Vector2.new(92, 92), i)
		b.Name = d[1]
		lb.TextScaled = true
		if d[1] == "Signs" then
			ic.Image = (Assets.SignIcons and Assets.SignIcons.Tiger) or ic.Image
			E.SignsButton = b
			E.SignsIcon = ic
		else
			E.Grid[d[1]] = b
		end
	end
	-- wide DAILY REWARDS bar above the grid (pack layout); opens the same Daily panel as the top-right icon
	local dailyBar, dl = U.button({Text = "DAILY REWARDS", Color = U.TONES.Green[1], Color2 = U.TONES.Green[2], Size = UDim2.fromOffset(196, 44), Radius = 6, StrokeT = 3.5, StudTile = 24, Name = "DailyBar", Parent = gui})
	dl.TextColor3 = Color3.new(1, 1, 1)
	E.DailyBar = dailyBar
	E.DailyBarDot = U.new("Frame", {Size = UDim2.fromOffset(22, 22), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -4, 0, 2), BackgroundColor3 = C(255, 42, 90), Visible = false, ZIndex = 5, Parent = dailyBar})
	U.corner(11).Parent = E.DailyBarDot
	U.stroke(2.5, Color3.new(1, 1, 1), Enum.ApplyStrokeMode.Border).Parent = E.DailyBarDot
	U.text({Text = "!", Size = UDim2.fromScale(0.8, 0.8), Position = UDim2.fromScale(0.1, 0.1), Stroke = 1.5, ZIndex = 6, Parent = E.DailyBarDot})
	E.RebirthTag = U.text({Text = "0%", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -4, 0, 0), Size = UDim2.fromOffset(60, 24), TextColor3 = C(130, 255, 120), Stroke = 2.5, Rotation = 10, ZIndex = 4, Parent = E.Grid.Rebirth})

	---------------------------------------------------------------- counters under the grid (rebirths, trophies)
	-- owner 2026-11-02: rebirths + trophies (wins) counters were way too small -> big icons + big numbers
	local cur = U.new("Frame", {Name = "Counters", Position = UDim2.fromOffset(14, 404), Size = UDim2.fromOffset(330, 176), BackgroundTransparency = 1, Parent = gui})
	local function row(y: number, icon: string, color: Color3)
		img({Icon = icon, Position = UDim2.fromOffset(-4, y - 4), Size = UDim2.fromOffset(80, 80), ZIndex = 2, Parent = cur})
		local t = U.text({Text = "0", Position = UDim2.fromOffset(80, y + 6), Size = UDim2.fromOffset(250, 64), TextColor3 = color, TextXAlignment = Enum.TextXAlignment.Left, Stroke = 5, Parent = cur})
		t.FontFace = U.FontHeavy
		return t
	end
	E.RebirthCount = row(0, "Rebirth", C(255, 120, 230))
	E.Trophies = row(86, "Trophy", C(255, 214, 60))

	---------------------------------------------------------------- top-right icon row (reference: Codes, Daily Rewards, Invite, Settings; + Free Gifts)
	-- owner 2026-11-02: no Places/Stages or Upgrades buttons (stages = WORLDS portal in the lobby)
	local tr = U.new("Frame", {Name = "TopRight", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 6), Size = UDim2.fromOffset(500, 84), BackgroundTransparency = 1, Parent = gui})
	U.new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = tr})
	E.TopIcons = {}
	-- owner 2026-11-02: small compact studded tiles, same style as the Rebirth tile; Codes = the pack's blue verified icon
	for i, d in {{"Codes", "Verified", "Codes", U.TONES.Blue}, {"Daily", "Daily", "Daily", U.TONES.Green}, {"Gifts", "Gift", "Gifts", U.TONES.Pink},
		{"Invite", "Invite", "Invite", U.TONES.Gold}, {"Settings", "Settings", "Settings", U.TONES.Dark}} do
		local b = tile(tr, d[4], d[2], d[3], Vector2.new(72, 72), i)
		b.Name = d[1]
		E.TopIcons[d[1]] = b
	end
	E.DailyDot = U.new("Frame", {Size = UDim2.fromOffset(18, 18), Position = UDim2.new(1, -12, 0, -6), BackgroundColor3 = C(255, 60, 60), Visible = false, ZIndex = 6, Parent = E.TopIcons.Daily})
	E.GiftDot = U.new("Frame", {Size = UDim2.fromOffset(18, 18), Position = UDim2.new(1, -12, 0, -6), BackgroundColor3 = C(255, 60, 60), Visible = false, ZIndex = 6, Parent = E.TopIcons.Gifts})
	U.corner(8).Parent = E.GiftDot
	U.stroke(2, Color3.new(1, 1, 1), Enum.ApplyStrokeMode.Border).Parent = E.GiftDot
	U.corner(8).Parent = E.DailyDot
	U.stroke(2, Color3.new(1, 1, 1), Enum.ApplyStrokeMode.Border).Parent = E.DailyDot
	-- promo card (only shown when the boost product has a real id)
	E.Promo = tile(gui, C(255, 205, 40), "", "", Vector2.new(250, 100))
	E.Promo.AnchorPoint = Vector2.new(1, 0)
	E.Promo.Position = UDim2.new(1, -20, 0, 112)
	E.Promo.Visible = false
	U.text({Text = "x2 Hand Signs", Size = UDim2.new(1, -16, 0.55, 0), Position = UDim2.fromOffset(8, 6), Stroke = 4, Parent = E.Promo})
	E.PromoPrice = U.text({Text = "15 MINUTES", Size = UDim2.new(1, -16, 0.32, 0), Position = UDim2.new(0, 8, 0.6, 0), TextColor3 = C(130, 255, 110), Stroke = 3, Parent = E.Promo})

	---------------------------------------------------------------- top centre: event / boss bar + objective
	local boss = U.new("Frame", {Name = "Boss", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, -40, 0, 10), Size = UDim2.fromOffset(460, 60), BackgroundTransparency = 1, Visible = false, Parent = gui})
	E.BossName = U.text({Text = "BOSS", Size = UDim2.fromOffset(300, 26), TextColor3 = C(255, 150, 40), TextXAlignment = Enum.TextXAlignment.Left, Stroke = 3, Parent = boss})
	local back = U.new("Frame", {Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = C(60, 55, 70), Parent = boss})
	U.corner(21).Parent = back
	U.stroke(4, C(20, 15, 25), Enum.ApplyStrokeMode.Border).Parent = back
	E.BossFill = U.new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = C(240, 60, 60), Parent = back})
	U.corner(21).Parent = E.BossFill
	U.grad(C(255, 110, 110), C(210, 40, 50)).Parent = E.BossFill
	E.BossHp = U.text({Text = "", Size = UDim2.new(1, -20, 1, -8), Position = UDim2.fromOffset(10, 4), Stroke = 3, Parent = back})
	E.Boss = boss

	local banner = U.new("Frame", {Name = "Objective", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, -40, 0, 92), Size = UDim2.fromOffset(640, 46), BackgroundColor3 = C(15, 25, 45), BackgroundTransparency = 0.5, BorderSizePixel = 0, Visible = false, Parent = gui})
	E.BannerFrame = banner
	U.new("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, 0), NumberSequenceKeypoint.new(0.85, 0), NumberSequenceKeypoint.new(1, 1)}), Parent = banner})
	E.Banner = U.text({Text = "", Size = UDim2.new(1, -40, 1, -8), Position = UDim2.fromOffset(20, 4), Stroke = 3, Parent = banner})

	---------------------------------------------------------------- bottom centre
	local bc = U.new("Frame", {Name = "Progress", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, -90, 1, -10), Size = UDim2.fromOffset(660, 270), BackgroundTransparency = 1, Parent = gui})
	local function stat(y: number, color: Color3, size: number)
		return U.text({Text = "", Position = UDim2.fromOffset(20, y), Size = UDim2.fromOffset(260, size), TextColor3 = color, TextXAlignment = Enum.TextXAlignment.Left, Stroke = 2.5, Parent = bc})
	end
	E.BoostLabel = stat(0, C(120, 255, 110), 28)
	E.Multiplier = stat(32, C(255, 230, 60), 26)
	E.PetsMult = stat(84, C(255, 170, 60), 24)
	E.RebirthMult = stat(110, C(200, 120, 255), 24)
	local bigRow = U.new("Frame", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 70), Size = UDim2.fromOffset(420, 72), BackgroundTransparency = 1, Parent = bc})
	U.new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = bigRow})
	E.BigIcon = img({Icon = "Chakra", Size = UDim2.fromOffset(66, 66), LayoutOrder = 1, Parent = bigRow})
	E.BigCount = U.text({Text = "0 Hand Signs", Font = U.TitleFont, TextScaled = true, TextSize = 48, Size = UDim2.fromOffset(345, 64), TextColor3 = C(120, 255, 110), Stroke = 5, LayoutOrder = 2, Parent = bigRow})
	E.BigScale = U.new("UIScale", {Parent = E.BigCount})

	local lvl = U.new("Frame", {Position = UDim2.fromOffset(40, 142), Size = UDim2.new(1, -40, 0, 58), BackgroundColor3 = C(70, 70, 85), Parent = bc})
	U.corner(14).Parent = lvl
	U.stroke(4, C(25, 20, 35), Enum.ApplyStrokeMode.Border).Parent = lvl
	E.LevelFill = U.new("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = C(255, 200, 40), Parent = lvl})
	U.corner(14).Parent = E.LevelFill
	U.grad(C(255, 234, 0), C(255, 106, 0)).Parent = E.LevelFill
	U.studs(E.LevelFill, 0.35, 26)
	U.studs(lvl, 0.75, 26)
	E.LevelText = U.text({Text = "Level 1", Font = U.TitleFont, Position = UDim2.fromOffset(52, 6), Size = UDim2.new(0.5, 0, 1, -12), TextXAlignment = Enum.TextXAlignment.Left, Stroke = 3.5, Parent = lvl})
	E.XPText = U.text({Text = "0 / 7", Font = U.TitleFont, Position = UDim2.new(0.5, 0, 0, 6), Size = UDim2.new(0.5, -16, 1, -12), TextXAlignment = Enum.TextXAlignment.Right, Stroke = 3.5, Parent = lvl})
	img({Icon = "Star", Position = UDim2.fromOffset(-4, 128), Size = UDim2.fromOffset(88, 88), ZIndex = 3, Parent = bc})

	local packs = U.new("Frame", {Position = UDim2.fromOffset(40, 210), Size = UDim2.new(1, -40, 0, 56), BackgroundTransparency = 1, Parent = bc})
	U.new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), Parent = packs})
	E.Packs = {}
	for i, d in {{"PackSmall", C(255, 150, 40)}, {"PackMedium", C(150, 80, 230)}, {"PackLarge", C(235, 60, 60)}} do
		local tone = ({U.TONES.Gold, U.TONES.Purple, U.TONES.Red})[i]
		local b, l = U.button({Text = "", Color = tone[1], Color2 = tone[2], Size = UDim2.new(1 / 3, -7, 1, 0), LayoutOrder = i, Radius = 6, StrokeT = 3.5, StudTile = 22, Parent = packs})
		img({Icon = "Chakra", Size = UDim2.fromOffset(46, 46), Position = UDim2.fromOffset(4, 4), ZIndex = 2, Parent = b})
		l.Position = UDim2.fromOffset(46, 4)
		l.Size = UDim2.new(1, -52, 1, -8)
		E.Packs[d[1]] = l
		E.Packs[d[1] .. "Button"] = b
	end

	---------------------------------------------------------------- bottom right: abilities
	local br = U.new("Frame", {Name = "Combat", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -14, 1, -14), Size = UDim2.fromOffset(460, 290), BackgroundTransparency = 1, Parent = gui})
	local function ability(size: number, pos: UDim2, color: {Color3}, key: string)
		local b, ic, lb = tile(br, color, "", "", Vector2.new(size, size))
		b.AnchorPoint = Vector2.new(1, 1)
		b.Position = pos
		ic.Size = UDim2.new(0.78, 0, 0.64, 0)
		ic.Position = UDim2.new(0.5, 0, 0.04, 0)
		local badge = U.new("Frame", {Size = UDim2.fromOffset(32, 28), Position = UDim2.fromOffset(-8, -10), BackgroundColor3 = C(30, 30, 40), ZIndex = 4, Parent = b})
		U.corner(8).Parent = badge
		U.stroke(2, Color3.new(1, 1, 1), Enum.ApplyStrokeMode.Border).Parent = badge
		U.text({Text = key, Stroke = 0, Size = UDim2.new(1, -6, 1, -6), Position = UDim2.fromOffset(3, 3), ZIndex = 4, Parent = badge})
		local cd = U.new("Frame", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.35, ZIndex = 3, Parent = b})
		U.corner(14).Parent = cd
		local cdText = U.text({Text = "", ZIndex = 3, Size = UDim2.fromScale(0.8, 0.45), Position = UDim2.fromScale(0.1, 0.2), Stroke = 3, Parent = b})
		return {Button = b, Icon = ic, Name = lb, Cd = cd, CdText = cdText, Badge = badge}
	end
	E.Attack = ability(150, UDim2.new(1, 0, 1, 0), U.TONES.Gold, "M1")
	E.Attack.Icon.Image = Assets.Icon("Fist")
	E.Attack.Button.Name = "Attack"
	E.Attack.Name.Text = "ATTACK"
	E.AbilityE = ability(116, UDim2.new(1, -162, 1, 0), U.TONES.Blue, "E")
	E.AbilityR = ability(116, UDim2.new(1, 0, 1, -162), U.TONES.Purple, "R")
	E.AbilityE.Button.Name = "AbilityE"
	E.AbilityR.Button.Name = "AbilityR"

	-- auto clickers (left of the ability cluster)
	-- owner 2026-11-02: smaller auto clicker buttons; the OP Auto Clicker is always shown (rainbow, "SOON" until the pass has an Id)
	local ac = U.new("Frame", {Name = "AutoTraining", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -290, 1, 0), Size = UDim2.fromOffset(120, 160), BackgroundTransparency = 1, Parent = br})
	local opTitle = U.text({Text = "OP Auto Clicker", Size = UDim2.fromOffset(120, 18), TextColor3 = C(255, 220, 60), Stroke = 2, Parent = ac})
	U.rainbow(opTitle)
	local op, opL = U.button({Text = "PASS", Color = C(255, 255, 255), Size = UDim2.fromOffset(112, 46), Position = UDim2.fromOffset(4, 20), Radius = 6, StrokeT = 3, StudTile = 16, Parent = ac})
	local fillG = op:FindFirstChild("Fill"); if fillG then fillG:Destroy() end
	U.new("UIGradient", {Name = "Fill", Color = ColorSequence.new({ColorSequenceKeypoint.new(0, C(255, 120, 120)), ColorSequenceKeypoint.new(0.33, C(255, 230, 120)), ColorSequenceKeypoint.new(0.66, C(120, 255, 160)), ColorSequenceKeypoint.new(1, C(120, 170, 255))}), Rotation = 20, Parent = op})
	E.OPAuto, E.OPAutoLabel = op, opL
	local _ = opTitle
	U.text({Text = "FREE Auto Clicker", Position = UDim2.fromOffset(0, 76), Size = UDim2.fromOffset(120, 18), TextColor3 = C(120, 255, 110), Stroke = 2, Parent = ac})
	local fr, frL = U.button({Text = "CLAIM", Color = C(90, 90, 105), Size = UDim2.fromOffset(112, 46), Position = UDim2.fromOffset(4, 96), Radius = 6, StrokeT = 3, StudTile = 16, Parent = ac})
	local barBack = U.new("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -6), Size = UDim2.new(1, -20, 0, 8), BackgroundColor3 = C(40, 40, 50), ZIndex = 3, Parent = fr})
	U.corner(4).Parent = barBack
	E.FreeAutoFill = U.new("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = C(110, 255, 110), ZIndex = 3, Parent = barBack})
	U.corner(4).Parent = E.FreeAutoFill
	E.FreeAuto, E.FreeAutoLabel = fr, frL
	---------------------------------------------------------------- responsive: scale the whole HUD with the viewport; keep combat clear of touch controls
	local scale = U.new("UIScale", {Name = "ResponsiveScale", Parent = gui})
	local UIS = game:GetService("UserInputService")
	local leftScale = U.new("UIScale", {Parent = left})
	local dailyScale = U.new("UIScale", {Parent = dailyBar})
	local counterScale = U.new("UIScale", {Parent = cur})
	local topScale = U.new("UIScale", {Parent = tr})
	local progressScale = U.new("UIScale", {Parent = bc})
	local combatScale = U.new("UIScale", {Parent = br})
	local function layout()
		local v = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1366, 768)
		local portrait = v.Y > v.X
		-- Hybrid devices and Studio's simulator may report both touch and keyboard.
		local touch = UIS.TouchEnabled
		local s = math.clamp(math.min(v.X / 1366, v.Y / 768), 0.6, 1.15)
		scale.Scale = s
		local top = math.max(76, 66 / s)
		leftScale.Scale = portrait and 1 or 0.9
		dailyScale.Scale = leftScale.Scale
		dailyBar.Position = UDim2.fromOffset(14, portrait and top + 90 or top)
		left.Position = UDim2.fromOffset(14, portrait and top + 146 or top + 52)
		counterScale.Scale = portrait and 0.7 or 0.8
		cur.Position = UDim2.fromOffset(14, portrait and top + 452 or top + 330)
		cur.Visible = true
		topScale.Scale = portrait and 1.05 or 0.85
		tr.Size = UDim2.fromOffset(380, 72)
		tr.Position = UDim2.new(1, -14, 0, portrait and top or 12)
		progressScale.Scale = portrait and 0.83 or 0.86
		bc.Position = portrait and UDim2.new(0.5, 0, 1, -400) or UDim2.new(0.5, -30, 1, -12)
		packs.Visible = not portrait
		-- Keep the reference triangle, reserving the bottom corners for native touch controls.
		combatScale.Scale = portrait and 0.94 or 0.9
		br.Position = touch and UDim2.new(1, -(portrait and 18 or 170), 1, -(portrait and 170 or 20)) or UDim2.new(1, -14, 1, -14)
		for _, a in {E.Attack, E.AbilityE, E.AbilityR} do a.Badge.Visible = not touch end
		ac.Parent = portrait and gui or br
		ac.AnchorPoint = Vector2.new(1, portrait and 0 or 1)
		ac.Position = portrait and UDim2.new(1, -14, 0, top + 120) or UDim2.new(1, -290, 1, 0)
		boss.Size = UDim2.fromOffset(portrait and 400 or 420, 60)
		boss.Position = UDim2.new(0.5, 0, 0, portrait and top + 92 or 14)
		banner.Size = UDim2.fromOffset(portrait and 420 or 560, 46)
		banner.Position = UDim2.new(0.5, 0, 0, portrait and top + 172 or 96)
	end
	---------------------------------------------------------------- slide the HUD off-screen while a menu is open (reference clips)
	local slides = {{dailyBar, -1, 0}, {left, -1, 0}, {cur, -1, 0}, {tr, 0, -1}, {br, 1, 0}, {bc, 0, 1}, {E.Promo, 1, 0}, {ac, 1, 0}}
	local shown: {[GuiObject]: UDim2} = {}
	local hidden = false
	local TS = game:GetService("TweenService")
	local slideTweens: {[GuiObject]: Tween} = {}
	local function slideTo(o: GuiObject, info: TweenInfo, position: UDim2)
		if slideTweens[o] then slideTweens[o]:Cancel() end
		local tw = TS:Create(o, info, {Position = position})
		slideTweens[o] = tw
		tw:Play()
	end
	local function offFor(sl): UDim2
		local v = workspace.CurrentCamera.ViewportSize
		return UDim2.fromOffset(sl[2] * (v.X / scale.Scale + 760), sl[3] * (v.Y / scale.Scale + 560))
	end
	function E.SetHidden(h: boolean)
		if h == hidden then return end
		hidden = h
		for _, sl in slides do
			local o = sl[1] :: GuiObject
			if h then
				shown[o] = o.Position
				slideTo(o, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), o.Position + offFor(sl))
			elseif shown[o] then
				slideTo(o, TweenInfo.new(0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out), shown[o])
				shown[o] = nil
			end
		end
	end
	local function relayout()
		for o, tw in slideTweens do tw:Cancel(); slideTweens[o] = nil end
		layout()
		if hidden then -- keep hidden pieces off-screen, remember where they belong
			for _, sl in slides do local o = sl[1] :: GuiObject; shown[o] = o.Position; o.Position = o.Position + offFor(sl) end
		end
	end
	layout()
	if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(relayout) end
	UIS:GetPropertyChangedSignal("TouchEnabled"):Connect(relayout)
	E.Layout = relayout
	return E
end

return H
