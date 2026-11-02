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

-- reference-style square button: saturated body, dark outline, light inner bevel, big icon, label over the bottom edge
local function tile(parent: Instance, color: Color3, icon: string, label: string, size: Vector2, order: number?)
	local b = U.button({Text = "", Color = color, Size = UDim2.fromOffset(size.X, size.Y), Radius = 14, StrokeT = 4, LayoutOrder = order or 0, Parent = parent})
	local inner = U.new("Frame", {Position = UDim2.fromOffset(5, 5), Size = UDim2.new(1, -10, 1, -10), BackgroundTransparency = 1, Parent = b})
	U.corner(10).Parent = inner
	U.new("UIStroke", {Thickness = 3, Color = Color3.new(1, 1, 1), Transparency = 0.55, Parent = inner})
	local ic = img({Icon = icon, AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.new(0.9, 0, 0.68, 0), Position = UDim2.new(0.5, 0, -0.04, 0), ZIndex = 2, Parent = b})
	local lb = U.text({Text = label, Font = U.TitleFont, Size = UDim2.new(1, -6, 0.3, 0), Position = UDim2.new(0, 3, 0.67, 0), Stroke = 3.5, ZIndex = 3, Parent = b})
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
		{"Shop", "Shop", "Store", C(235, 60, 80)}, {"Quests", "Quests", "Quests", C(255, 150, 40)},
		{"Signs", "HandSign", "Hand Signs", C(235, 60, 80)}, {"Rebirth", "Rebirth", "Rebirth", C(150, 80, 230)},
		{"Auras", "Aura", "Auras", C(235, 60, 80)}, {"Pets", "Pets", "Pets", C(255, 150, 40)},
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
	E.RebirthTag = U.text({Text = "0%", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -4, 0, 0), Size = UDim2.fromOffset(60, 24), TextColor3 = C(130, 255, 120), Stroke = 2.5, Rotation = 10, ZIndex = 4, Parent = E.Grid.Rebirth})

	---------------------------------------------------------------- counters under the grid (rebirths, trophies)
	local cur = U.new("Frame", {Name = "Counters", Position = UDim2.fromOffset(14, 404), Size = UDim2.fromOffset(240, 110), BackgroundTransparency = 1, Parent = gui})
	local function row(y: number, icon: string, color: Color3)
		img({Icon = icon, Position = UDim2.fromOffset(0, y - 2), Size = UDim2.fromOffset(50, 50), Parent = cur})
		return U.text({Text = "0", Position = UDim2.fromOffset(56, y + 4), Size = UDim2.fromOffset(180, 40), TextColor3 = color, TextXAlignment = Enum.TextXAlignment.Left, Stroke = 3.5, Parent = cur})
	end
	E.RebirthCount = row(0, "Rebirth", C(120, 255, 110))
	E.Trophies = row(54, "Trophy", C(120, 255, 110))

	---------------------------------------------------------------- top-right icon row (reference: Codes, Daily Rewards, Invite, Settings; + Free Gifts)
	-- owner 2026-11-02: no Places/Stages or Upgrades buttons (stages = WORLDS portal in the lobby)
	local tr = U.new("Frame", {Name = "TopRight", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 6), Size = UDim2.fromOffset(500, 84), BackgroundTransparency = 1, Parent = gui})
	U.new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = tr})
	E.TopIcons = {}
	for i, d in {{"Codes", "Codes", "Codes"}, {"Daily", "Daily", "Daily"}, {"Gifts", "Gift", "Gifts"}, {"Invite", "Invite", "Invite"}, {"Settings", "Settings", "Settings"}} do
		local b = U.new("TextButton", {Name = d[1], Text = "", BackgroundTransparency = 1, Size = UDim2.fromOffset(86, 88), LayoutOrder = i, Parent = tr})
		img({Icon = d[2], Size = UDim2.fromOffset(64, 64), Position = UDim2.fromOffset(11, -4), Parent = b})
		U.text({Text = d[3], Font = U.TitleFont, Size = UDim2.fromOffset(92, 28), Position = UDim2.fromOffset(-3, 56), Stroke = 3.5, Parent = b})
		E.TopIcons[d[1]] = b
	end
	E.DailyDot = U.new("Frame", {Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(62, 2), BackgroundColor3 = C(255, 60, 60), Visible = false, Parent = E.TopIcons.Daily})
	E.GiftDot = U.new("Frame", {Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(62, 2), BackgroundColor3 = C(255, 60, 60), Visible = false, Parent = E.TopIcons.Gifts})
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
	local boss = U.new("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, -40, 0, 10), Size = UDim2.fromOffset(460, 60), BackgroundTransparency = 1, Visible = false, Parent = gui})
	E.BossName = U.text({Text = "BOSS", Size = UDim2.fromOffset(300, 26), TextColor3 = C(255, 150, 40), TextXAlignment = Enum.TextXAlignment.Left, Stroke = 3, Parent = boss})
	local back = U.new("Frame", {Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = C(60, 55, 70), Parent = boss})
	U.corner(21).Parent = back
	U.stroke(4, C(20, 15, 25), Enum.ApplyStrokeMode.Border).Parent = back
	E.BossFill = U.new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = C(240, 60, 60), Parent = back})
	U.corner(21).Parent = E.BossFill
	U.grad(C(255, 110, 110), C(210, 40, 50)).Parent = E.BossFill
	E.BossHp = U.text({Text = "", Size = UDim2.new(1, -20, 1, -8), Position = UDim2.fromOffset(10, 4), Stroke = 3, Parent = back})
	E.Boss = boss

	local banner = U.new("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, -40, 0, 92), Size = UDim2.fromOffset(640, 46), BackgroundColor3 = C(15, 25, 45), BackgroundTransparency = 0.5, BorderSizePixel = 0, Visible = false, Parent = gui})
	E.BannerFrame = banner
	U.new("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, 0), NumberSequenceKeypoint.new(0.85, 0), NumberSequenceKeypoint.new(1, 1)}), Parent = banner})
	E.Banner = U.text({Text = "", Size = UDim2.new(1, -40, 1, -8), Position = UDim2.fromOffset(20, 4), Stroke = 3, Parent = banner})

	---------------------------------------------------------------- bottom centre
	local bc = U.new("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, -90, 1, -10), Size = UDim2.fromOffset(660, 270), BackgroundTransparency = 1, Parent = gui})
	local function stat(y: number, color: Color3, size: number)
		return U.text({Text = "", Position = UDim2.fromOffset(20, y), Size = UDim2.fromOffset(260, size), TextColor3 = color, TextXAlignment = Enum.TextXAlignment.Left, Stroke = 2.5, Parent = bc})
	end
	E.BoostLabel = stat(0, C(120, 255, 110), 28)
	E.Multiplier = stat(32, C(255, 230, 60), 26)
	E.PetsMult = stat(84, C(255, 170, 60), 24)
	E.RebirthMult = stat(110, C(200, 120, 255), 24)
	local bigRow = U.new("Frame", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 70), Size = UDim2.fromOffset(500, 72), BackgroundTransparency = 1, Parent = bc})
	U.new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = bigRow})
	E.BigIcon = img({Icon = "Chakra", Size = UDim2.fromOffset(72, 72), LayoutOrder = 1, Parent = bigRow})
	E.BigCount = U.text({Text = "0 Hand Signs", Font = U.TitleFont, TextScaled = false, TextSize = 54, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 64), TextColor3 = C(120, 255, 110), Stroke = 5, LayoutOrder = 2, Parent = bigRow})
	E.BigScale = U.new("UIScale", {Parent = E.BigCount})

	local lvl = U.new("Frame", {Position = UDim2.fromOffset(40, 142), Size = UDim2.new(1, -40, 0, 58), BackgroundColor3 = C(70, 70, 85), Parent = bc})
	U.corner(14).Parent = lvl
	U.stroke(4, C(25, 20, 35), Enum.ApplyStrokeMode.Border).Parent = lvl
	E.LevelFill = U.new("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = C(255, 200, 40), Parent = lvl})
	U.corner(14).Parent = E.LevelFill
	U.grad(C(255, 225, 90), C(255, 160, 20)).Parent = E.LevelFill
	E.LevelText = U.text({Text = "Level 1", Font = U.TitleFont, Position = UDim2.fromOffset(52, 6), Size = UDim2.new(0.5, 0, 1, -12), TextXAlignment = Enum.TextXAlignment.Left, Stroke = 3.5, Parent = lvl})
	E.XPText = U.text({Text = "0 / 7", Font = U.TitleFont, Position = UDim2.new(0.5, 0, 0, 6), Size = UDim2.new(0.5, -16, 1, -12), TextXAlignment = Enum.TextXAlignment.Right, Stroke = 3.5, Parent = lvl})
	img({Icon = "Star", Position = UDim2.fromOffset(-4, 128), Size = UDim2.fromOffset(88, 88), ZIndex = 3, Parent = bc})

	local packs = U.new("Frame", {Position = UDim2.fromOffset(40, 210), Size = UDim2.new(1, -40, 0, 56), BackgroundTransparency = 1, Parent = bc})
	U.new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), Parent = packs})
	E.Packs = {}
	for i, d in {{"PackSmall", C(255, 150, 40)}, {"PackMedium", C(150, 80, 230)}, {"PackLarge", C(235, 60, 60)}} do
		local b, l = U.button({Text = "", Color = d[2], Size = UDim2.new(1 / 3, -7, 1, 0), LayoutOrder = i, Radius = 12, StrokeT = 4, Parent = packs})
		img({Icon = "Chakra", Size = UDim2.fromOffset(46, 46), Position = UDim2.fromOffset(4, 4), ZIndex = 2, Parent = b})
		l.Position = UDim2.fromOffset(46, 4)
		l.Size = UDim2.new(1, -52, 1, -8)
		E.Packs[d[1]] = l
		E.Packs[d[1] .. "Button"] = b
	end

	---------------------------------------------------------------- bottom right: abilities
	local br = U.new("Frame", {AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -14, 1, -14), Size = UDim2.fromOffset(460, 290), BackgroundTransparency = 1, Parent = gui})
	local function ability(size: number, pos: UDim2, color: Color3, key: string)
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
	E.Attack = ability(150, UDim2.new(1, 0, 1, 0), C(255, 140, 30), "M1")
	E.Attack.Icon.Image = Assets.Icon("Fist")
	E.Attack.Name.Text = "ATTACK"
	E.AbilityE = ability(116, UDim2.new(1, -162, 1, 0), C(70, 150, 255), "E")
	E.AbilityR = ability(116, UDim2.new(1, 0, 1, -162), C(150, 80, 230), "R")

	-- auto clickers (left of the ability cluster)
	local ac = U.new("Frame", {AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -290, 1, 0), Size = UDim2.fromOffset(160, 240), BackgroundTransparency = 1, Parent = br})
	local opTitle = U.text({Text = "OP Auto Clicker", Size = UDim2.fromOffset(160, 24), TextColor3 = C(255, 220, 60), Stroke = 2.5, Parent = ac})
	local op, opL = U.button({Text = "PASS", Color = C(255, 255, 255), Size = UDim2.fromOffset(150, 70), Position = UDim2.fromOffset(5, 26), Radius = 12, StrokeT = 4, Parent = ac})
	op:FindFirstChildOfClass("UIGradient"):Destroy()
	U.new("UIGradient", {Color = ColorSequence.new({ColorSequenceKeypoint.new(0, C(255, 120, 120)), ColorSequenceKeypoint.new(0.33, C(255, 230, 120)), ColorSequenceKeypoint.new(0.66, C(120, 255, 160)), ColorSequenceKeypoint.new(1, C(120, 170, 255))}), Rotation = 20, Parent = op})
	E.OPAuto, E.OPAutoLabel = op, opL
	if SC.GamePasses.AutoClicker.Id == 0 then op.Visible = false; opTitle.Visible = false end
	U.text({Text = "FREE Auto Clicker", Position = UDim2.fromOffset(0, 104), Size = UDim2.fromOffset(160, 24), TextColor3 = C(120, 255, 110), Stroke = 2.5, Parent = ac})
	local fr, frL = U.button({Text = "CLAIM", Color = C(90, 90, 105), Size = UDim2.fromOffset(150, 70), Position = UDim2.fromOffset(5, 130), Radius = 12, StrokeT = 4, Parent = ac})
	local barBack = U.new("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -6), Size = UDim2.new(1, -20, 0, 8), BackgroundColor3 = C(40, 40, 50), ZIndex = 3, Parent = fr})
	U.corner(4).Parent = barBack
	E.FreeAutoFill = U.new("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = C(110, 255, 110), ZIndex = 3, Parent = barBack})
	U.corner(4).Parent = E.FreeAutoFill
	E.FreeAuto, E.FreeAutoLabel = fr, frL
	---------------------------------------------------------------- responsive: scale the whole HUD with the viewport; keep combat clear of touch controls
	local scale = U.new("UIScale", {Parent = gui})
	local UIS = game:GetService("UserInputService")
	local function layout()
		local cam = workspace.CurrentCamera
		local v = cam and cam.ViewportSize or Vector2.new(1366, 768)
		local s = math.clamp(math.min(v.X / 1366, v.Y / 768), 0.48, 1.15)
		local touch = UIS.TouchEnabled and not UIS.KeyboardEnabled
		local portrait = v.Y > v.X
		if touch then s = math.clamp(s * 1.18, 0.5, 1) end
		scale.Scale = s
		-- abilities sit left of / above the mobile jump button; never under the thumbstick
		br.Position = touch and UDim2.new(1, -(portrait and 20 or 150), 1, -(portrait and 150 or 14)) or UDim2.new(1, -14, 1, -14)
		-- portrait phones: centre block moves up above the ability cluster; side counters tuck in
		bc.Position = portrait and UDim2.new(0.5, 0, 1, -330) or UDim2.new(0.5, -90, 1, -10)
		cur.Visible = not (touch and portrait)
		-- narrow (4:3 / tablet / portrait): auto clickers stack above the ability cluster so the centre block never collides
		local narrow = v.X / math.max(v.Y, 1) < 1.6
		ac.Position = narrow and UDim2.new(1, 0, 1, -300) or UDim2.new(1, -290, 1, 0)
		-- left menu always starts below Roblox's top bar (unscaled ~58px)
		local top = math.max(92, 66 / s)
		left.Position = UDim2.fromOffset(14, top)
		cur.Position = UDim2.fromOffset(14, top + 312)
		-- top-centre boss bar / banner drop below the top-right icon row when the screen is narrow
		boss.Position = narrow and UDim2.new(0.5, -40, 0, 100) or UDim2.new(0.5, -40, 0, 10)
		banner.Position = narrow and UDim2.new(0.5, -40, 0, 182) or UDim2.new(0.5, -40, 0, 92)
	end
	layout()
	if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(layout) end
	E.Layout = layout
	return E
end

return H
