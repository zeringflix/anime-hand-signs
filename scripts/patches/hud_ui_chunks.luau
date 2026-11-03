--@@LEFT
	---------------------------------------------------------------- left menu: 2-column tile grid (reference: Store, Quests, My Eyes, Rebirth, Auras, Pets)
	local left = U.new("Frame", {Name = "LeftMenu", Position = UDim2.fromOffset(14, 92), Size = UDim2.fromOffset(196, 300), BackgroundTransparency = 1, Parent = gui})
	U.new("UIGridLayout", {CellSize = UDim2.fromOffset(92, 92), CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = left})
	E.Grid = {}
	local gridDefs = {
		{"Shop", "Shop", "Store", C(235, 60, 80)}, {"Rewards", "Scroll", "Quests", C(255, 150, 40)},
		{"Signs", "HandSign", "Hand Signs", C(235, 60, 80)}, {"Rebirth", "Rebirth", "Rebirth", C(150, 80, 230)},
		{"Auras", "Aura", "Auras", C(235, 60, 80)}, {"Pets", "Egg", "Pets", C(255, 150, 40)},
	}
	for i, d in gridDefs do
		local b, ic, lb = tile(left, d[4], d[2], d[3], Vector2.new(92, 92), i)
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

	---------------------------------------------------------------- top-right icon row (systems that exist: Codes, Daily, Upgrades, Stages, Top, Settings)
	local tr = U.new("Frame", {Name = "TopRight", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 6), Size = UDim2.fromOffset(500, 84), BackgroundTransparency = 1, Parent = gui})
	U.new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = tr})
	E.TopIcons = {}
	for i, d in {{"Codes", "Codes", "Codes"}, {"Rewards", "Daily", "Daily"}, {"Upgrades", "Upgrades", "Upgrades"}, {"Stages", "Places", "Stages"}, {"Top", "Crown", "Top"}, {"Settings", "Settings", "Settings"}} do
		local b = U.new("TextButton", {Text = "", BackgroundTransparency = 1, Size = UDim2.fromOffset(78, 84), LayoutOrder = i, Parent = tr})
		img({Icon = d[2], Size = UDim2.fromOffset(58, 58), Position = UDim2.fromOffset(10, -2), Parent = b})
		U.text({Text = d[3], Size = UDim2.fromOffset(78, 26), Position = UDim2.fromOffset(0, 54), Stroke = 3, Parent = b})
		E.TopIcons[d[1]] = b
	end
	E.DailyDot = U.new("Frame", {Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(58, 2), BackgroundColor3 = C(255, 60, 60), Visible = false, Parent = E.TopIcons.Rewards})
	U.corner(8).Parent = E.DailyDot
	U.stroke(2, Color3.new(1, 1, 1), Enum.ApplyStrokeMode.Border).Parent = E.DailyDot
--@@ENDLEFT
--@@RESPONSIVE
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
--@@ENDRESPONSIVE
