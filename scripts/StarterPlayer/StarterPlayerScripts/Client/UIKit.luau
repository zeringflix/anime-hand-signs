-- Small UI toolkit. Owner pick 2026-11-02: UI variant 1 "Studs Pack Classic" (the layered recipe of the owner's
-- Studs UI Pack 2): two-tone gradient fill, black outer stroke + white inner rim, raised stud texture, glossy top +
-- diagonal shine band, Gotham ExtraBold lettering with dark outline. Every HUD tile / menu / button uses these primitives.
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Assets = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Assets"))
local U = {}
U.Font = Enum.Font.FredokaOne -- legacy enum values: U.text maps both to Gotham ExtraBold (pack lettering)
U.TitleFont = Enum.Font.LuckiestGuy
U.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.ExtraBold)
U.FontHeavy = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy)

function U.new(class: string, props: {[string]: any}?, children: {Instance}?): any
	local i = Instance.new(class)
	for k, v in props or {} do
		if k ~= "Parent" then (i :: any)[k] = v end
	end
	for _, c in children or {} do c.Parent = i end
	if props and props.Parent then i.Parent = props.Parent end
	return i
end

function U.corner(r: number?) return U.new("UICorner", {CornerRadius = UDim.new(0, r or 12)}) end
function U.stroke(th: number?, col: Color3?, mode: Enum.ApplyStrokeMode?)
	return U.new("UIStroke", {Thickness = th or 3, Color = col or Color3.fromRGB(25, 20, 35), ApplyStrokeMode = mode or Enum.ApplyStrokeMode.Contextual, LineJoinMode = Enum.LineJoinMode.Round})
end
function U.pad(px: number) return U.new("UIPadding", {PaddingLeft = UDim.new(0, px), PaddingRight = UDim.new(0, px), PaddingTop = UDim.new(0, px), PaddingBottom = UDim.new(0, px)}) end
function U.grad(a: Color3, b: Color3, rot: number?) return U.new("UIGradient", {Color = ColorSequence.new(a, b), Rotation = rot or 90}) end

function U.shade(c: Color3, f: number): Color3
	return Color3.new(math.clamp(c.R * f, 0, 1), math.clamp(c.G * f, 0, 1), math.clamp(c.B * f, 0, 1))
end

-- big title: heavy Gotham, thick dark outline, pack-style silver sheen (light grey -> white -> light grey)
function U.title(props: {[string]: any}): TextLabel
	local noGrad = props.NoGradient
	props.Font = props.Font or U.TitleFont
	props.Stroke = props.Stroke or 4
	local t = U.text(props)
	t.FontFace = U.FontHeavy
	if noGrad == nil then
		U.new("UIGradient", {Rotation = 90, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(235, 235, 235)),
			ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(1, Color3.fromRGB(215, 215, 215))}), Parent = t})
	end
	return t
end

-- outlined text
function U.text(props: {[string]: any}): TextLabel
	local t = U.new("TextLabel", {
		BackgroundTransparency = 1, Font = U.Font, TextScaled = true, TextColor3 = Color3.new(1, 1, 1), Size = UDim2.fromScale(1, 1),
	})
	local strokeT = props.Stroke or 2.5
	props.Stroke = nil
	props.NoGradient = nil
	for k, v in props do (t :: any)[k] = v end
	-- pack lettering everywhere: the old Fredoka / Luckiest Guy enums become Gotham ExtraBold
	if t.Font == Enum.Font.FredokaOne or t.Font == Enum.Font.LuckiestGuy then t.FontFace = U.FontFace end
	if strokeT > 0 then U.stroke(strokeT, Color3.fromRGB(22, 20, 26)).Parent = t end
	return t
end

-- shared palette for actions (+1 Anime Eyes style: positive actions are glossy lime green)
U.GREEN = Color3.fromRGB(96, 226, 34)
U.ORANGE = Color3.fromRGB(255, 166, 26)
U.RED = Color3.fromRGB(236, 52, 76)
U.BLUE = Color3.fromRGB(56, 158, 255)
U.PURPLE = Color3.fromRGB(160, 84, 240)
U.GREY = Color3.fromRGB(118, 118, 132)
U.OUTLINE = Color3.fromRGB(0, 0, 0)
U.YELLOW = Color3.fromRGB(255, 214, 0)
U.PINK = Color3.fromRGB(255, 40, 120)
-- two-tone fills taken from the pack's palette: top colour, bottom colour
U.TONES = {
	Red = {Color3.fromHex("ff008c"), Color3.fromHex("ff0004")}, Gold = {Color3.fromHex("ffea00"), Color3.fromHex("ff6a00")},
	Blue = {Color3.fromHex("90ebfd"), Color3.fromHex("077efe")}, Purple = {Color3.fromHex("ea00ff"), Color3.fromHex("6a00ff")},
	Green = {Color3.fromHex("ffff00"), Color3.fromHex("15ff00")}, Lime = {Color3.fromHex("b6ff3b"), Color3.fromHex("2fbf00")},
	Pink = {Color3.fromHex("ff72c7"), Color3.fromHex("ff2a6a")}, Grey = {Color3.fromHex("fdfdfd"), Color3.fromHex("888888")},
	Dark = {Color3.fromHex("8a8a8a"), Color3.fromHex("313131")}, Close = {Color3.fromHex("ff6c6e"), Color3.fromHex("e60012")},
}

-- raised studs (owner: "studify the ui"): the Studs UI Pack 2 stud texture, clearly visible, fading slightly
-- towards the bottom like the pack. Old callers pass transparencies tuned for the previous texture; clamp them.
-- owner 2026-11-02: THE owner's stud texture (assets/textures/owner_studs_source.png, 8x8 studs per sheet), converted to a
-- white/black alpha overlay (owner_studs_overlay.png) so it shades every tile colour the same way.
U.STUDS = "rbxassetid://118774955486499"
U.STUDS_PER_SHEET = 8
U.STUDS_PACK = "rbxassetid://89333738374139" -- Studs UI Pack 2 texture (kept for reference)
function U.studs(parent: Instance, transp: number?, tile: number?): ImageLabel
	local px = math.max(30, math.floor((tile or 34) * 1.35)) * U.STUDS_PER_SHEET -- tile = size of ONE stud
	local s = U.new("ImageLabel", {Name = "Studs", BackgroundTransparency = 1, Image = U.STUDS, ScaleType = Enum.ScaleType.Tile,
		TileSize = UDim2.fromOffset(px, px), ImageTransparency = math.clamp(transp or 0.35, 0.25, 0.8), Size = UDim2.fromScale(1, 1), Parent = parent})
	if parent:IsA("GuiObject") then s.ZIndex = parent.ZIndex end
	U.corner(8).Parent = s
	return s
end

-- ANIMATED RAINBOW TEXT for Robux items (owner request): a hue-cycling UIGradient; one shared 20 Hz updater.
local rainbows: {UIGradient} = {}
local RAINBOW_KEYS = 7
function U.rainbow(label: GuiObject, speed: number?): UIGradient
	local old = label:FindFirstChild("Rainbow")
	if old then return old :: UIGradient end
	if label:IsA("TextLabel") or label:IsA("TextButton") then (label :: any).TextColor3 = Color3.new(1, 1, 1) end
	for _, g in label:GetChildren() do if g:IsA("UIGradient") then g:Destroy() end end -- one gradient per label
	local g = U.new("UIGradient", {Name = "Rainbow", Rotation = 0, Parent = label})
	g:SetAttribute("Speed", speed or 0.35)
	table.insert(rainbows, g)
	return g
end
local acc = 0
RunService.RenderStepped:Connect(function(dt)
	acc += dt
	if acc < 0.05 or #rainbows == 0 then return end
	acc = 0
	local t = os.clock()
	for i = #rainbows, 1, -1 do
		local g = rainbows[i]
		if not g.Parent then table.remove(rainbows, i) continue end
		local sp = g:GetAttribute("Speed") or 0.35
		local keys = {}
		for k = 0, RAINBOW_KEYS - 1 do
			local a = k / (RAINBOW_KEYS - 1)
			table.insert(keys, ColorSequenceKeypoint.new(a, Color3.fromHSV((t * sp + a * 0.85) % 1, 0.72, 1)))
		end
		g.Color = ColorSequence.new(keys)
	end
end)

-- pack surface on any frame/button: two-tone vertical fill (top lighter), glossy top, diagonal shine band,
-- white inner rim. Children render above their parent, so the text label must be created after this.
-- `color2` = bottom colour; omitted -> derived from `color` (keeps old single-colour callers working).
local SHINE = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.16, 1), NumberSequenceKeypoint.new(0.2, 0.6), NumberSequenceKeypoint.new(0.27, 0.6),
	NumberSequenceKeypoint.new(0.3, 1), NumberSequenceKeypoint.new(0.34, 0.74), NumberSequenceKeypoint.new(0.36, 1), NumberSequenceKeypoint.new(1, 1)})
local function lighten(c: Color3, f: number): Color3 return c:Lerp(Color3.new(1, 1, 1), f) end
function U.fill(obj: GuiObject, color: Color3, color2: Color3?)
	obj.BackgroundColor3 = Color3.new(1, 1, 1)
	local g = obj:FindFirstChild("Fill") :: UIGradient?
	if not g then
		for _, x in obj:GetChildren() do if x:IsA("UIGradient") then x:Destroy() end end
		g = U.new("UIGradient", {Name = "Fill", Rotation = 90, Parent = obj})
	end
	local top = color2 and color or lighten(color, 0.18)
	local bottom = color2 or U.shade(color, 0.78);
	(g :: UIGradient).Color = ColorSequence.new(top, bottom)
	obj:SetAttribute("FillColor", color)
end
function U.gloss(obj: GuiObject, color: Color3, radius: number?, color2: Color3?)
	local r = radius or 10
	local z = obj.ZIndex
	U.fill(obj, color, color2)
	local gloss = U.new("Frame", {Name = "Shine", Size = UDim2.new(1, 0, 0.42, 0), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.55,
		BorderSizePixel = 0, ZIndex = z, Parent = obj})
	U.corner(r).Parent = gloss
	U.new("UIGradient", {Rotation = 90, Transparency = NumberSequence.new(0.1, 1), Parent = gloss})
	local band = U.new("Frame", {Name = "Band", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = z, Parent = obj})
	U.corner(r).Parent = band
	U.new("UIGradient", {Rotation = 28, Transparency = SHINE, Parent = band})
	local rim = U.new("Frame", {Name = "Rim", Position = UDim2.fromOffset(2, 2), Size = UDim2.new(1, -4, 1, -4), BackgroundTransparency = 1, ZIndex = z, Parent = obj})
	U.corner(math.max(r - 2, 2)).Parent = rim
	U.new("UIStroke", {Thickness = 2, Color = Color3.new(1, 1, 1), Transparency = 0.12, Parent = rim})
	return gloss, rim
end

-- chunky glossy button: thick dark outline, gloss, bottom lip, optional studs, press bounce
function U.button(props: {[string]: any}): (TextButton, TextLabel)
	local color = props.Color or U.GREEN
	local b = U.new("TextButton", {
		AutoButtonColor = false, Text = "", BackgroundColor3 = color, Size = props.Size or UDim2.fromOffset(120, 44),
		Position = props.Position or UDim2.new(), AnchorPoint = props.AnchorPoint or Vector2.zero, Parent = props.Parent,
		LayoutOrder = props.LayoutOrder or 0, Name = props.Name or "Button",
	})
	local r = props.Radius or 6
	U.corner(r).Parent = b
	U.stroke(props.StrokeT or 3.5, U.OUTLINE, Enum.ApplyStrokeMode.Border).Parent = b
	U.gloss(b, color, r, props.Color2)
	if props.Studs ~= false then U.studs(b, 0.3, props.StudTile or 20) end
	local label = U.text({Name = "Label", Text = props.Text or "", Size = UDim2.new(1, -10, 0.74, -4), Position = UDim2.fromOffset(5, 3),
		TextSize = props.TextSize, TextScaled = props.TextSize == nil, Stroke = props.TextStroke or 3, Parent = b})
	local press = U.motionScale(b)
	if props.Hover ~= false then U.hover(b, {Scale = props.HoverScale or 1.07, Tilt = props.HoverTilt or 0}) end
	b.MouseButton1Down:Connect(function()
		local okS, Sfx = pcall(require, script.Parent:FindFirstChild("Sfx"))
		if okS and Sfx then Sfx.Play("Click") end
		TweenService:Create(press, TweenInfo.new(0.06), {Scale = 0.94}):Play()
	end)
	local function up() TweenService:Create(press, TweenInfo.new(0.12, Enum.EasingStyle.Back), {Scale = 1}):Play() end
	b.MouseButton1Up:Connect(up)
	b.MouseLeave:Connect(up)
	return b, label
end

-- recolour an existing glossy button (keeps the two-tone fill consistent)
function U.recolor(b: GuiObject, color: Color3, color2: Color3?)
	U.fill(b, color, color2)
end

-- an icon-pack image to the left of a button / label's text (replaces emoji like the trophy or lock glyphs)
function U.iconLeft(holder: GuiObject, label: TextLabel, image: string, frac: number?): ImageLabel
	local f = frac or 0.26
	local ic = U.new("ImageLabel", {Name = "PackIcon", BackgroundTransparency = 1, Image = image, ScaleType = Enum.ScaleType.Fit,
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0.04, 0, 0.5, 0), Size = UDim2.new(f, 0, 1.1, 0), ZIndex = label.ZIndex + 1, Parent = holder})
	U.new("UIAspectRatioConstraint", {AspectRatio = 1, Parent = ic})
	label.Position = UDim2.new(0.04 + f * 0.85, 0, label.Position.Y.Scale, label.Position.Y.Offset)
	label.Size = UDim2.new(0.92 - f * 0.85, 0, label.Size.Y.Scale, label.Size.Y.Offset)
	return ic
end

---------------------------------------------------------------- MOTION (owner's reference clips, 2026-11-02)
-- Hover: the element grows ~7-15 %, optionally tilts a few degrees, and lifts above its neighbours.
-- Open: HUD slides off-screen, the world blurs + zooms in, the panel lands from oversize, a shine sweeps the
-- header, then the content pops in card by card (oversize -> settle, dark -> bright). Close: the panel drops away.
local Lighting = game:GetService("Lighting")
local function sfx(name: string)
	local ok, Sfx = pcall(require, script.Parent:FindFirstChild("Sfx"))
	if ok and Sfx then Sfx.Play(name) end
end
function U.motionScale(obj: GuiObject): UIScale
	local sc = obj:FindFirstChild("MotionScale") :: UIScale?
	if not sc then
		for _, x in obj:GetChildren() do if x:IsA("UIScale") then return x end end
		sc = U.new("UIScale", {Name = "MotionScale", Parent = obj})
	end
	return sc :: UIScale
end
local HOVER_IN = TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local HOVER_OUT = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
function U.hover(obj: GuiObject, opts: {[string]: any}?)
	if obj:GetAttribute("HoverWired") then return end
	obj:SetAttribute("HoverWired", true)
	local amt = opts and opts.Scale or 1.08
	local tilt = opts and opts.Tilt or 0
	local sc = U.motionScale(obj)
	local baseZ: number? = nil
	obj.MouseEnter:Connect(function()
		if obj:GetAttribute("Intro") then return end
		baseZ = baseZ or obj.ZIndex
		obj.ZIndex = (baseZ :: number) + 2
		TweenService:Create(sc, HOVER_IN, {Scale = amt}):Play()
		if tilt ~= 0 then TweenService:Create(obj, HOVER_IN, {Rotation = tilt * (obj.AbsolutePosition.X % 2 < 1 and -1 or 1)}):Play() end
		sfx("Hover")
	end)
	obj.MouseLeave:Connect(function()
		if baseZ then obj.ZIndex = baseZ end
		TweenService:Create(sc, HOVER_OUT, {Scale = 1}):Play()
		if tilt ~= 0 then TweenService:Create(obj, HOVER_OUT, {Rotation = 0}):Play() end
	end)
end

-- content intro: every card in `container` (cards inside grid / list holder frames too) pops in, top-left first
function U.intro(container: Instance, delay0: number?)
	local items: {GuiObject} = {}
	local function collect(parent: Instance, depth: number)
		for _, c in parent:GetChildren() do
			if c:IsA("GuiObject") and c.Visible then
				local holder = c.BackgroundTransparency >= 0.99 and (c:FindFirstChildOfClass("UIGridLayout") or c:FindFirstChildOfClass("UIListLayout")
					or (c.ClassName == "Frame" and #c:GetChildren() > 2))
				if holder and depth < 2 then collect(c, depth + 1) else table.insert(items, c) end
			end
		end
	end
	collect(container, 0)
	table.sort(items, function(a, b)
		if math.abs(a.AbsolutePosition.Y - b.AbsolutePosition.Y) > 6 then return a.AbsolutePosition.Y < b.AbsolutePosition.Y end
		return a.AbsolutePosition.X < b.AbsolutePosition.X
	end)
	for i, it in items do
		local sc = U.motionScale(it)
		local isCard = it.BackgroundTransparency < 0.99
		local dark: Frame? = nil
		if isCard then
			dark = U.new("Frame", {Name = "IntroDark", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.35, ZIndex = 50, Parent = it})
			U.corner(6).Parent = dark
			if it.AbsoluteSize.X < 320 then U.hover(it, {Scale = 1.07, Tilt = 2.5}) else U.hover(it, {Scale = 1.012}) end
		end
		it:SetAttribute("Intro", true)
		sc.Scale = 0.55
		local d = (delay0 or 0) + math.min(i - 1, 18) * 0.035
		task.delay(d, function()
			if not it.Parent then return end
			TweenService:Create(sc, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
			if dark then
				local tw = TweenService:Create(dark, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
				tw.Completed:Connect(function() dark:Destroy() end)
				tw:Play()
			end
			task.delay(0.3, function() if it.Parent then it:SetAttribute("Intro", nil) end end)
		end)
	end
	return #items
end

-- world behind an open menu: blur + slight dim + a small camera zoom-in
local blurFx: BlurEffect? = nil
local dimFx: ColorCorrectionEffect? = nil
local baseFov: number? = nil
function U.menuWorld(on: boolean)
	blurFx = blurFx or U.new("BlurEffect", {Name = "MenuBlur", Size = 0, Parent = Lighting})
	dimFx = dimFx or U.new("ColorCorrectionEffect", {Name = "MenuDim", Parent = Lighting})
	local cam = workspace.CurrentCamera
	local ti = TweenInfo.new(on and 0.3 or 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(blurFx :: BlurEffect, ti, {Size = on and 14 or 0}):Play()
	TweenService:Create(dimFx :: ColorCorrectionEffect, ti, {Brightness = on and -0.06 or 0, Saturation = on and -0.12 or 0}):Play()
	if cam then
		if on then
			baseFov = baseFov or cam.FieldOfView
			TweenService:Create(cam, ti, {FieldOfView = (baseFov :: number) - 8}):Play()
		elseif baseFov then
			TweenService:Create(cam, ti, {FieldOfView = baseFov}):Play()
			baseFov = nil
		end
	end
end

-- a light streak that sweeps across a header bar (once per call)
function U.sweep(bar: GuiObject)
	local f = bar:FindFirstChild("Sweep") :: Frame?
	if not f then
		f = U.new("Frame", {Name = "Sweep", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = bar.ZIndex + 1, Parent = bar})
		U.corner(6).Parent = f
		U.new("UIGradient", {Name = "G", Rotation = 20, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.4, 1),
			NumberSequenceKeypoint.new(0.47, 0.45), NumberSequenceKeypoint.new(0.5, 0.25), NumberSequenceKeypoint.new(0.53, 0.45), NumberSequenceKeypoint.new(0.6, 1), NumberSequenceKeypoint.new(1, 1)}), Parent = f})
	end
	local g = (f :: Frame):FindFirstChild("G") :: UIGradient
	g.Offset = Vector2.new(-1, 0)
	TweenService:Create(g, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Offset = Vector2.new(1, 0)}):Play()
end

function U.pop(obj: GuiObject, from: number?)
	local sc = obj:FindFirstChildOfClass("UIScale") or U.new("UIScale", {Parent = obj})
	sc.Scale = from or 0.6
	TweenService:Create(sc, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
end

function U.tween(obj: Instance, t: number, props: {[string]: any}, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	local tw = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

return U
