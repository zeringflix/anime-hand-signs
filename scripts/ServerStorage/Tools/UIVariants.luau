--!nonstrict
-- UIVariants (edit-time MOCKUP tool, owner request 2026-11-02): renders 4 candidate UI styles for the owner to pick
-- before VFX work. Each variant = HUD + "My Hand Signs" menu + Shop menu, built from real game data (sign names,
-- multipliers, Trophy prices) and the owner's icons (Free Icon Pack + our cartoon hand art).
-- Variant 1/3 borrow the layered recipe of the owner's "Studs UI Pack 2" (gradient fill, black outer + white inner
-- stroke, tiled studs, diagonal shine band, double-layer text) and its stud/burst textures, which the owner has in Studio.
-- Nothing here is wired to gameplay: buttons do nothing. Pick one, then the chosen style is applied to Client.UIKit/HUD/Menus.
--
--   local V = require(ServerStorage.Tools.UIVariants)
--   V.Show(k, "HandSigns" | "Shop")   -- builds StarterGui.UIVariantPreview for variant k (1..4)
--   V.Clear()
local RS = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local function fresh(mod: ModuleScript): any
	local c = mod:Clone(); c.Parent = mod.Parent
	local ok, r = pcall(require, c); c:Destroy()
	return ok and r or require(mod)
end
local Assets = fresh(RS.Shared.Assets)
local Config = fresh(RS.Shared.Config)

local V = {}

local W = Color3.new(1, 1, 1)
local function C(h: string): Color3 return Color3.fromHex(h) end
local PACK_STUDS = "rbxassetid://89333738374139"   -- Studs UI Pack 2 stud texture (owner's pack)
local PACK_STUDS2 = "rbxassetid://70699239093270"  -- Studs UI Pack 2 fine stud texture
local PACK_BURST = "rbxassetid://98508264222687"   -- Studs UI Pack 2 card light burst

local GOTHAM = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.ExtraBold)
local THEMES = {
	{ -- 1: Studs Pack Classic (closest to the owner's UI pack)
		name = "Studs Pack Classic", font = GOTHAM, titleFont = GOTHAM,
		corner = 0.06, outer = 3, outerCol = C("000000"), inner = 2, innerCol = W, innerT = 0.15,
		studs = PACK_STUDS, studPx = 34, studT = 0.35, shine = 0.55, shadow = true, textStroke = 3, textStrokeCol = C("191919"),
		body = C("000000"), bodyT = 0.5, bodyStroke = C("ffffff"), card = {C("4a4a4a"), C("262626")}, cardT = 0.25, burst = PACK_BURST,
		tiles = {Store = {"ff008c", "ff0004"}, Quests = {"ffea00", "ff6a00"}, HandSigns = {"90ebfd", "077efe"}, Rebirth = {"ea00ff", "6a00ff"}, Auras = {"ff72c7", "ff2a6a"}, Pets = {"ffff00", "15ff00"}},
		equip = {"b6ff3b", "2fbf00"}, buy = {"fff27a", "ffb300"}, wide = {"ffff00", "15ff00"}, close = {"ff6c6e", "e60012"},
		hsHeader = {"90ebfd", "077efe"}, shopHeader = {"ff008c", "ff0004"}, labelsBelow = true,
	},
	{ -- 2: Anime Eyes Studs (square studded tiles, Luckiest Guy, chunky white rims)
		name = "Anime Eyes Studs", font = Font.fromEnum(Enum.Font.LuckiestGuy), titleFont = Font.fromEnum(Enum.Font.LuckiestGuy),
		corner = 0.14, outer = 4, outerCol = C("1d1033"), inner = 4, innerCol = W, innerT = 0,
		studs = Assets.Studs, studPx = 26, studT = 0.55, shine = 0.75, shadow = false, textStroke = 3.5, textStrokeCol = C("1d1033"),
		body = C("f3ecff"), bodyT = 0, bodyStroke = C("ffffff"), card = {C("ffd34d"), C("ff9a1f")}, cardT = 0, burst = nil,
		tiles = {Store = {"ff5a5a", "d81b3a"}, Quests = {"ffb347", "ff7a00"}, HandSigns = {"ff6fb5", "e0307a"}, Rebirth = {"b07bff", "7a3cff"}, Auras = {"ff8a3d", "ff4d1f"}, Pets = {"ffb04a", "ff7a1a"}},
		equip = {"8dff4a", "35c800"}, buy = {"ffe066", "ffae00"}, wide = {"6ee7ff", "1f9cff"}, close = {"ff6b6b", "d61f3c"},
		hsHeader = {"ffd84d", "ffa800"}, shopHeader = {"ff6b6b", "d61f3c"}, labelsBelow = true,
	},
	{ -- 3: Chakra Night (dark glass panels, neon chakra accents, pack studs very subtle)
		name = "Chakra Night", font = Font.fromEnum(Enum.Font.FredokaOne), titleFont = Font.fromEnum(Enum.Font.FredokaOne),
		corner = 0.18, outer = 3, outerCol = C("0b0618"), inner = 2, innerCol = C("8be9ff"), innerT = 0.35,
		studs = PACK_STUDS2, studPx = 22, studT = 0.82, shine = 0.8, shadow = true, textStroke = 3, textStrokeCol = C("0b0618"),
		body = C("140c2b"), bodyT = 0.08, bodyStroke = C("7c5cff"), card = {C("2b1d5c"), C("150d33")}, cardT = 0, burst = PACK_BURST,
		tiles = {Store = {"ff4f9a", "8f1d6b"}, Quests = {"ffb547", "a3410f"}, HandSigns = {"39d5ff", "1a3fa8"}, Rebirth = {"b26bff", "4a1fa8"}, Auras = {"ff6b3d", "8c1f12"}, Pets = {"5cff9d", "137a52"}},
		equip = {"5cffb0", "0f9e63"}, buy = {"ffcf5c", "c46a00"}, wide = {"39d5ff", "1a3fa8"}, close = {"ff5c7a", "a0122e"},
		hsHeader = {"6b4dff", "2a1677"}, shopHeader = {"ff4f9a", "6e1350"}, labelsBelow = true,
	},
	{ -- 4: Candy Pop (bright pastel bubble buttons, Bangers lettering, thick white rims)
		name = "Candy Pop", font = Font.fromEnum(Enum.Font.Bangers), titleFont = Font.fromEnum(Enum.Font.Bangers),
		corner = 0.32, outer = 4, outerCol = C("5a2a82"), inner = 5, innerCol = W, innerT = 0,
		studs = nil, studPx = 0, studT = 1, shine = 0.45, shadow = true, textStroke = 3.5, textStrokeCol = C("5a2a82"),
		body = C("fff4fb"), bodyT = 0, bodyStroke = C("ffffff"), card = {C("c9f7ff"), C("8fd8ff")}, cardT = 0, burst = nil,
		tiles = {Store = {"ff9ac1", "ff4f8b"}, Quests = {"ffe28a", "ffb84d"}, HandSigns = {"a8f0ff", "4fc3ff"}, Rebirth = {"d9b3ff", "a66bff"}, Auras = {"ffc0a3", "ff7f66"}, Pets = {"b8ffb0", "5ee05a"}},
		equip = {"9dff8a", "3fd13a"}, buy = {"ffe48a", "ffbf3d"}, wide = {"ffb3e6", "ff6fcf"}, close = {"ff9aa8", "ff4f6d"},
		hsHeader = {"a8f0ff", "4fc3ff"}, shopHeader = {"ff9ac1", "ff4f8b"}, labelsBelow = true,
	},
}
V.Themes = THEMES

---------------------------------------------------------------- primitives
local function new(cls: string, props: {[string]: any}, parent: Instance?): any
	local i = Instance.new(cls)
	for k, v in props do (i :: any)[k] = v end
	if parent then i.Parent = parent end
	return i
end
local function ud(xs, xo, ys, yo) return UDim2.new(xs, xo or 0, ys, yo or 0) end
local function grad(p, a: string, b: string, rot: number?)
	return new("UIGradient", {Color = ColorSequence.new(C(a), C(b)), Rotation = rot or 90}, p)
end
local function corner(p, r) if r and r > 0 then new("UICorner", {CornerRadius = UDim.new(r, 0)}, p) end end
local function stroke(p, th, col, contextual: boolean?, tr: number?)
	return new("UIStroke", {Thickness = th, Color = col, Transparency = tr or 0, LineJoinMode = Enum.LineJoinMode.Round,
		ApplyStrokeMode = contextual and Enum.ApplyStrokeMode.Contextual or Enum.ApplyStrokeMode.Border}, p)
end
local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, C("ea00ff")), ColorSequenceKeypoint.new(0.25, C("ff008c")), ColorSequenceKeypoint.new(0.5, C("ffea00")),
	ColorSequenceKeypoint.new(0.75, C("00eeff")), ColorSequenceKeypoint.new(1, C("ea00ff"))})

-- outlined text; optional dark drop layer underneath (pack-style 3D lettering)
local function text(T, parent, str: string, props: {[string]: any})
	local l = new("TextLabel", {BackgroundTransparency = 1, Text = str, FontFace = props.font or T.font, TextScaled = true,
		TextColor3 = props.color or W, Size = props.size, Position = props.pos or ud(0.5, 0, 0.5, 0), AnchorPoint = props.anchor or Vector2.new(0.5, 0.5),
		TextXAlignment = props.xa or Enum.TextXAlignment.Center, ZIndex = props.z or 20, Rotation = props.rot or 0}, parent)
	stroke(l, props.st or T.textStroke, props.stc or T.textStrokeCol, true)
	if props.rainbow then new("UIGradient", {Color = RAINBOW, Rotation = 0}, l) end
	if T.shadow and not props.noShadow then
		local sh = l:Clone()
		for _, g in sh:GetChildren() do if g:IsA("UIGradient") then g:Destroy() end end
		sh.TextColor3 = props.stc or T.textStrokeCol
		sh.Position = l.Position + UDim2.fromOffset(0, math.max(2, (props.st or T.textStroke)))
		sh.ZIndex = l.ZIndex - 1
		sh.Parent = parent
	end
	return l
end

-- the layered tile used for every button / header / card
local function tile(T, parent, cols: {string}, props: {[string]: any})
	local z = props.z or 5
	local f = new("Frame", {Size = props.size, Position = props.pos or ud(0, 0, 0, 0), AnchorPoint = props.anchor or Vector2.zero,
		BackgroundColor3 = W, BorderSizePixel = 0, ZIndex = z, Name = props.name or "Tile", Rotation = props.rot or 0}, parent)
	if props.aspect then new("UIAspectRatioConstraint", {AspectRatio = props.aspect}, f) end
	grad(f, cols[1], cols[2], 90)
	local r = props.corner or T.corner
	corner(f, r)
	stroke(f, props.outer or T.outer, T.outerCol)
	if (props.inner or T.inner) > 0 then
		local inset = props.inner or T.inner
		local inn = new("Frame", {Size = ud(1, -2 * inset, 1, -2 * inset), Position = ud(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1, ZIndex = z + 3, Name = "InnerRim"}, f)
		corner(inn, r)
		stroke(inn, inset, T.innerCol, false, T.innerT)
	end
	if T.studs and not props.noStuds then
		local s = new("ImageLabel", {Size = ud(1, 0, 1, 0), BackgroundTransparency = 1, Image = T.studs, ScaleType = Enum.ScaleType.Tile,
			TileSize = UDim2.fromOffset(props.studPx or T.studPx, props.studPx or T.studPx), ImageTransparency = T.studT, ZIndex = z + 1, Name = "Studs"}, f)
		corner(s, r)
		new("UIGradient", {Transparency = NumberSequence.new(0.1, 0.6), Rotation = 90}, s)
	end
	if not props.noShine then -- glossy top lip + diagonal shine band
		local lip = new("Frame", {Size = ud(1, 0, 0.42, 0), BackgroundColor3 = W, BackgroundTransparency = T.shine, BorderSizePixel = 0, ZIndex = z + 2, Name = "Gloss"}, f)
		corner(lip, r)
		new("UIGradient", {Transparency = NumberSequence.new(0.15, 1), Rotation = 90}, lip)
		local band = new("Frame", {Size = ud(1, 0, 1, 0), BackgroundColor3 = W, BorderSizePixel = 0, ZIndex = z + 2, Name = "Shine"}, f)
		corner(band, r)
		new("UIGradient", {Rotation = props.shineRot or 28, Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.16, 1), NumberSequenceKeypoint.new(0.2, 0.62), NumberSequenceKeypoint.new(0.27, 0.62),
			NumberSequenceKeypoint.new(0.3, 1), NumberSequenceKeypoint.new(0.34, 0.74), NumberSequenceKeypoint.new(0.36, 1), NumberSequenceKeypoint.new(1, 1)})}, band)
	end
	return f
end
local function icon(parent, img: string, props: {[string]: any})
	return new("ImageLabel", {BackgroundTransparency = 1, Image = img, ScaleType = Enum.ScaleType.Fit, Size = props.size, Position = props.pos or ud(0.5, 0, 0.5, 0),
		AnchorPoint = props.anchor or Vector2.new(0.5, 0.5), ZIndex = props.z or 12, Rotation = props.rot or 0, Name = props.name or "Icon"}, parent)
end

---------------------------------------------------------------- HUD
local function hud(T, gui)
	local L = new("Frame", {Name = "Left", BackgroundTransparency = 1, Size = ud(0.19, 0, 0.52, 0), Position = ud(0.012, 0, 0.27, 0)}, gui)
	new("UIAspectRatioConstraint", {AspectRatio = 0.66}, L)
	-- wide Daily bar (pack style)
	local d = tile(T, L, T.wide, {size = ud(1, 0, 0.115, 0), pos = ud(0, 0, 0, 0), name = "Daily"})
	text(T, d, "DAILY REWARDS", {size = ud(0.86, 0, 0.62, 0)})
	local dot = new("Frame", {Size = ud(0, 22, 0, 22), Position = ud(1, -6, 0, -6), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = C("ff2a5a"), ZIndex = 30}, d)
	corner(dot, 0.5); stroke(dot, 2.5, W)
	text(T, dot, "!", {size = ud(0.8, 0, 0.8, 0), z = 31, st = 1.5, noShadow = true})
	local order = {{"Store", "Shop"}, {"Quests", "Quests"}, {"HandSigns", "HandSign"}, {"Rebirth", "Rebirth"}, {"Auras", "Aura"}, {"Pets", "Pets"}}
	local labels = {Store = "STORE", Quests = "QUESTS", HandSigns = "SIGNS", Rebirth = "REBIRTH", Auras = "AURAS", Pets = "PETS"}
	for i, o in order do
		local col, row = (i - 1) % 2, (i - 1) // 2
		local t = tile(T, L, T.tiles[o[1]], {size = ud(0.47, 0, 0.27, 0), pos = ud(col * 0.53, 0, 0.145 + row * 0.29, 0), name = o[1], aspect = 1})
		local img = Assets.Icon(o[2])
		icon(t, img, {size = ud(0.78, 0, 0.78, 0), pos = ud(0.5, 0, 0.43, 0), z = 14, rot = o[1] == "HandSigns" and -6 or 0})
		text(T, t, labels[o[1]], {size = ud(0.98, 0, 0.27, 0), pos = ud(0.5, 0, 0.86, 0), z = 22})
	end
	-- currencies
	local cur = new("Frame", {Name = "Currency", BackgroundTransparency = 1, Size = ud(0.22, 0, 0.13, 0), Position = ud(0.012, 0, 0.82, 0)}, gui)
	icon(cur, Assets.Icon("Rebirth"), {size = ud(0, 34, 0, 34), pos = ud(0, 18, 0.2, 0)})
	text(T, cur, "4", {size = ud(0.3, 0, 0.32, 0), pos = ud(0, 42, 0.2, 0), anchor = Vector2.new(0, 0.5), xa = Enum.TextXAlignment.Left, color = C("ff7ad1")})
	icon(cur, Assets.Icon("Trophy"), {size = ud(0, 40, 0, 40), pos = ud(0, 20, 0.68, 0)})
	text(T, cur, "572,831", {size = ud(0.8, 0, 0.42, 0), pos = ud(0, 46, 0.68, 0), anchor = Vector2.new(0, 0.5), xa = Enum.TextXAlignment.Left, color = C("ffd84d")})
	-- top-right small buttons
	local TR = new("Frame", {Name = "TopRight", BackgroundTransparency = 1, Size = ud(0.34, 0, 0.1, 0), Position = ud(0.985, 0, 0.015, 0), AnchorPoint = Vector2.new(1, 0)}, gui)
	new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0.02, 0)}, TR)
	for _, n in {{"Codes", "CODES"}, {"Daily", "DAILY"}, {"Gift", "GIFTS"}, {"Invite", "INVITE"}, {"Settings", ""}} do
		local b = new("Frame", {BackgroundTransparency = 1, Size = ud(0.18, 0, 1, 0)}, TR)
		new("UIAspectRatioConstraint", {AspectRatio = 1}, b)
		icon(b, Assets.Icon(n[1]), {size = ud(0.9, 0, 0.9, 0), pos = ud(0.5, 0, 0.42, 0)})
		if n[2] ~= "" then text(T, b, n[2], {size = ud(1.1, 0, 0.32, 0), pos = ud(0.5, 0, 0.92, 0), st = 2.5}) end
	end
	-- right column: Robux pet + boosts (rainbow Robux prices)
	local R = new("Frame", {Name = "Right", BackgroundTransparency = 1, Size = ud(0.12, 0, 0.42, 0), Position = ud(0.985, 0, 0.33, 0), AnchorPoint = Vector2.new(1, 0)}, gui)
	icon(R, Assets.Icon("Gift"), {size = ud(0.62, 0, 0.3, 0), pos = ud(0.5, 0, 0.17, 0)})
	text(T, R, "STARTER PACK", {size = ud(1, 0, 0.07, 0), pos = ud(0.5, 0, 0.02, 0), st = 2})
	text(T, R, "R$ 49", {size = ud(0.6, 0, 0.08, 0), pos = ud(0.5, 0, 0.36, 0), rainbow = true})
	for i, b in {{"x2 SIGNS", "R$ 99"}, {"x2 TROPHY", "R$ 79"}} do
		local t = tile(T, R, i == 1 and T.tiles.Rebirth or T.tiles.Store, {size = ud(1, 0, 0.2, 0), pos = ud(0, 0, 0.44 + (i - 1) * 0.25, 0), studPx = 22})
		text(T, t, b[1], {size = ud(0.92, 0, 0.46, 0), pos = ud(0.5, 0, 0.36, 0), z = 22})
		text(T, t, b[2], {size = ud(0.6, 0, 0.34, 0), pos = ud(0.5, 0, 0.78, 0), z = 22, rainbow = true, st = 2})
	end
	-- bottom: hand-sign counter, level bar, boosts
	local B = new("Frame", {Name = "Bottom", BackgroundTransparency = 1, Size = ud(0.42, 0, 0.2, 0), Position = ud(0.5, 0, 0.995, 0), AnchorPoint = Vector2.new(0.5, 1)}, gui)
	icon(B, Assets.Icon("Chakra"), {size = ud(0, 44, 0, 44), pos = ud(0.27, 0, 0.12, 0)})
	text(T, B, "1,284 HAND SIGNS", {size = ud(0.62, 0, 0.24, 0), pos = ud(0.58, 0, 0.12, 0), color = C("8dff4a")})
	local bar = new("Frame", {Size = ud(1, 0, 0.22, 0), Position = ud(0, 0, 0.3, 0), BackgroundColor3 = C("2a2240"), ZIndex = 5}, B)
	corner(bar, T.corner * 1.5); stroke(bar, T.outer, T.outerCol)
	local fill = tile(T, bar, T.buy, {size = ud(0.57, 0, 1, 0), z = 6, outer = 0, inner = 0, studPx = 18})
	text(T, bar, "LEVEL 5", {size = ud(0.3, 0, 0.7, 0), pos = ud(0.03, 0, 0.5, 0), anchor = Vector2.new(0, 0.5), xa = Enum.TextXAlignment.Left, z = 24})
	text(T, bar, "57/100 XP", {size = ud(0.3, 0, 0.7, 0), pos = ud(0.97, 0, 0.5, 0), anchor = Vector2.new(1, 0.5), xa = Enum.TextXAlignment.Right, z = 24})
	local bc = {T.wide, T.tiles.HandSigns, T.tiles.Rebirth}
	for i, s in {"+500", "+3K", "+15K"} do
		local t = tile(T, B, bc[i], {size = ud(0.31, 0, 0.3, 0), pos = ud((i - 1) * 0.345, 0, 0.62, 0), studPx = 20})
		text(T, t, s, {size = ud(0.8, 0, 0.66, 0), z = 22})
	end
	fill.Name = "XPFill"
end

---------------------------------------------------------------- menu frame
local function menu(T, gui, title: string, iconImg: string, headerCols: {string})
	local P = new("Frame", {Name = "Menu", BackgroundTransparency = 1, Size = ud(0.5, 0, 0.6, 0), Position = ud(0.452, 0, 0.475, 0), AnchorPoint = Vector2.new(0.5, 0.5)}, gui)
	new("UIAspectRatioConstraint", {AspectRatio = 1.5}, P)
	local body = new("Frame", {Name = "Body", Size = ud(1, 0, 0.86, 0), Position = ud(0, 0, 0.14, 0), BackgroundColor3 = T.body, BackgroundTransparency = T.bodyT, ZIndex = 2}, P)
	corner(body, T.corner * 0.35); stroke(body, T.outer, T.outerCol)
	if T.studs and T.bodyT < 0.3 then
		local s = new("ImageLabel", {Size = ud(1, 0, 1, 0), BackgroundTransparency = 1, Image = T.studs, ScaleType = Enum.ScaleType.Tile,
			TileSize = UDim2.fromOffset(T.studPx, T.studPx), ImageTransparency = math.min(0.92, T.studT + 0.3), ZIndex = 2}, body)
		corner(s, T.corner * 0.35)
	end
	local h = tile(T, P, headerCols, {size = ud(1, 0, 0.17, 0), pos = ud(0, 0, 0, 0), z = 8, name = "Header", studPx = 30})
	icon(h, iconImg, {size = ud(0.2, 0, 1.55, 0), pos = ud(0.06, 0, 0.32, 0), z = 30, rot = -10, name = "HeaderIcon"})
	text(T, h, title, {font = T.titleFont, size = ud(0.62, 0, 0.66, 0), pos = ud(0.16, 0, 0.5, 0), anchor = Vector2.new(0, 0.5), xa = Enum.TextXAlignment.Left, z = 24})
	local x = tile(T, h, T.close, {size = ud(0.09, 0, 0.74, 0), pos = ud(0.985, 0, 0.5, 0), anchor = Vector2.new(1, 0.5), z = 26, aspect = 1, studPx = 16})
	text(T, x, "X", {size = ud(0.7, 0, 0.7, 0), z = 40})
	return body
end

---------------------------------------------------------------- Hand Signs menu (4 columns, big hand art)
local function handSigns(T, gui)
	local body = menu(T, gui, "MY HAND SIGNS", Assets.SignIcons.Tiger, T.hsHeader)
	local grid = new("Frame", {Name = "Grid", BackgroundTransparency = 1, Size = ud(0.95, 0, 0.94, 0), Position = ud(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), ClipsDescendants = true, ZIndex = 3}, body)
	local states = {Tiger = "EQUIPPED", Ram = "OWNED", Snake = "OWNED"}
	local rarity = { -- card colours by tier so the grid reads like the pack's rarity grid
		{"7fd8ff", "2f7bff"}, {"7fd8ff", "2f7bff"}, {"b7ff6b", "34c400"}, {"b7ff6b", "34c400"},
		{"d68bff", "8a2eff"}, {"d68bff", "8a2eff"}, {"ffd84d", "ff9500"}, {"ffd84d", "ff9500"},
		{"ff7a9c", "ff1f4d"}, {"ff7a9c", "ff1f4d"}, {"ff7a9c", "ff1f4d"}, {"ffffff", "8a8a8a"},
	}
	for i, id in Config.HandSignOrder do
		if i > 12 then break end
		local s = Config.HandSigns[id]
		local col, row = (i - 1) % 4, (i - 1) // 4
		local cols = (T.name == "Studs Pack Classic") and {T.card[1]:ToHex(), T.card[2]:ToHex()} or rarity[i]
		if T.name == "Chakra Night" then cols = {T.card[1]:ToHex(), T.card[2]:ToHex()} end
		local c = tile(T, grid, cols, {size = ud(0.235, 0, 0.47, 0), pos = ud(col * 0.255, 0, row * 0.51, 0), z = 4, name = id, studPx = 24,
			noShine = T.name == "Studs Pack Classic"})
		if T.burst then
			local b = icon(c, T.burst, {size = ud(1.05, 0, 1.05, 0), z = 9, name = "Burst"})
			b.ImageColor3 = T.name == "Chakra Night" and C(rarity[i][1]) or W
			b.ImageTransparency = 0.15
		end
		icon(c, Assets.SignIcons[id] or "", {size = ud(0.7, 0, 0.62, 0), pos = ud(0.5, 0, 0.47, 0), z = 14, name = "Hand"})
		text(T, c, string.upper(s.Name), {size = ud(0.86, 0, 0.15, 0), pos = ud(0.5, 0, 0.1, 0), z = 24, st = 2.5})
		text(T, c, "x" .. s.Multiplier, {size = ud(0.36, 0, 0.15, 0), pos = ud(0.96, 0, 0.26, 0), anchor = Vector2.new(1, 0.5), xa = Enum.TextXAlignment.Right, z = 24, st = 2.5, color = C("ffe23d")})
		local st = states[id]
		if st then
			local b = tile(T, c, st == "EQUIPPED" and T.close or T.equip, {size = ud(0.8, 0, 0.17, 0), pos = ud(0.5, 0, 0.9, 0), anchor = Vector2.new(0.5, 0.5), z = 26, studPx = 12, corner = T.corner * 1.6})
			text(T, b, st == "EQUIPPED" and "UNEQUIP" or "EQUIP", {size = ud(0.86, 0, 0.72, 0), z = 40, st = 2})
		else
			local b = tile(T, c, T.buy, {size = ud(0.8, 0, 0.17, 0), pos = ud(0.5, 0, 0.9, 0), anchor = Vector2.new(0.5, 0.5), z = 26, studPx = 12, corner = T.corner * 1.6})
			icon(b, Assets.Icon("Trophy"), {size = ud(0.26, 0, 1.15, 0), pos = ud(0.16, 0, 0.5, 0), z = 41})
			text(T, b, Config.Format and Config.Format(s.Price) or tostring(s.Price), {size = ud(0.62, 0, 0.72, 0), pos = ud(0.6, 0, 0.5, 0), z = 40, st = 2})
		end
	end
	-- side tabs (pack-style rarity tabs -> sign tiers)
	local tabs = new("Frame", {Name = "Tabs", BackgroundTransparency = 1, Size = ud(0.21, 0, 0.75, 0), Position = ud(1.02, 0, 0.02, 0)}, body)
	for i, t in {{"BASIC", T.tiles.HandSigns}, {"ADVANCED", T.tiles.Rebirth}, {"FORBIDDEN", T.tiles.Store}, {"OWNED 3/14", T.equip}} do
		local b = tile(T, tabs, t[2], {size = ud(1, 0, 0.18, 0), pos = ud(0, 0, (i - 1) * 0.215, 0), z = 6, studPx = 20})
		text(T, b, t[1], {size = ud(0.88, 0, 0.56, 0), z = 24})
	end
end

---------------------------------------------------------------- Shop menu
local function shop(T, gui)
	local body = menu(T, gui, "STORE", Assets.Icon("Shop"), T.shopHeader)
	local rows = new("Frame", {Name = "Rows", BackgroundTransparency = 1, Size = ud(0.95, 0, 0.94, 0), Position = ud(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 3}, body)
	-- row 1: Robux pet offer (rainbow frame)
	local r1 = tile(T, rows, {"ff8ad8", "8a2eff"}, {size = ud(1, 0, 0.47, 0), pos = ud(0, 0, 0, 0), z = 4, studPx = 30, name = "PetOffer"})
	new("UIGradient", {Color = RAINBOW, Rotation = 160}, new("Frame", {Size = ud(1, 8, 1, 8), Position = ud(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = W, ZIndex = 3, BorderSizePixel = 0}, r1))
	icon(r1, Assets.Icon("Pets"), {size = ud(0.3, 0, 0.95, 0), pos = ud(0.17, 0, 0.5, 0), z = 14})
	text(T, r1, "NINE-TAIL SPIRIT FOX", {size = ud(0.6, 0, 0.2, 0), pos = ud(0.64, 0, 0.17, 0), z = 24, rainbow = true})
	text(T, r1, "x100 HAND SIGNS  •  SPECIAL", {size = ud(0.55, 0, 0.13, 0), pos = ud(0.64, 0, 0.38, 0), z = 24, st = 2})
	local buy1 = tile(T, r1, T.equip, {size = ud(0.34, 0, 0.3, 0), pos = ud(0.64, 0, 0.7, 0), anchor = Vector2.new(0.5, 0.5), z = 26, studPx = 14})
	icon(buy1, Assets.Icon("Robux"), {size = ud(0.22, 0, 0.9, 0), pos = ud(0.17, 0, 0.5, 0), z = 41})
	text(T, buy1, "799", {size = ud(0.55, 0, 0.7, 0), pos = ud(0.6, 0, 0.5, 0), z = 40})
	-- row 2: two Robux eggs + 2x pass
	local items = {{"SHADOW EGG", "Egg", "79", T.tiles.Rebirth}, {"MYTHIC EGG", "Egg", "149", T.tiles.Quests}, {"2x HAND SIGNS", "Boost", "199", T.tiles.HandSigns}}
	for i, it in items do
		local c = tile(T, rows, it[4], {size = ud(0.315, 0, 0.48, 0), pos = ud((i - 1) * 0.3425, 0, 0.52, 0), z = 4, studPx = 24, name = it[1]})
		if T.burst then icon(c, T.burst, {size = ud(0.9, 0, 0.9, 0), pos = ud(0.5, 0, 0.42, 0), z = 9}).ImageTransparency = 0.25 end
		icon(c, Assets.Icon(it[2]), {size = ud(0.55, 0, 0.5, 0), pos = ud(0.5, 0, 0.42, 0), z = 14})
		text(T, c, it[1], {size = ud(0.9, 0, 0.15, 0), pos = ud(0.5, 0, 0.1, 0), z = 24, st = 2.5})
		local b = tile(T, c, T.equip, {size = ud(0.8, 0, 0.2, 0), pos = ud(0.5, 0, 0.86, 0), anchor = Vector2.new(0.5, 0.5), z = 26, studPx = 12})
		icon(b, Assets.Icon("Robux"), {size = ud(0.24, 0, 0.95, 0), pos = ud(0.18, 0, 0.5, 0), z = 41})
		text(T, b, it[3], {size = ud(0.55, 0, 0.72, 0), pos = ud(0.6, 0, 0.5, 0), z = 40, st = 2})
	end
end

---------------------------------------------------------------- public
function V.Clear()
	local old = StarterGui:FindFirstChild("UIVariantPreview"); if old then old:Destroy() end
end
function V.Show(k: number, screen: string?)
	V.Clear()
	local T = THEMES[k]
	local gui = new("ScreenGui", {Name = "UIVariantPreview", IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Global, ResetOnSpawn = false})
	gui:SetAttribute("Mockup", "UIVariants v" .. k .. " " .. T.name .. " (not wired to gameplay)")
	hud(T, gui)
	if screen == "HandSigns" then handSigns(T, gui) elseif screen == "Shop" then shop(T, gui) end
	local tag = new("TextLabel", {BackgroundColor3 = C("000000"), BackgroundTransparency = 0.35, Size = ud(0.2, 0, 0.035, 0), Position = ud(0.5, 0, 0.005, 0),
		AnchorPoint = Vector2.new(0.5, 0), Text = "VARIANT " .. k .. " — " .. string.upper(T.name), TextScaled = true, TextColor3 = W, FontFace = GOTHAM, ZIndex = 100}, gui)
	corner(tag, 0.3)
	gui.Parent = StarterGui
	return gui
end

return V
