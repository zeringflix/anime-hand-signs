-- Small UI toolkit: chunky outlined simulator style (FredokaOne, thick strokes, rounded colourful buttons).
local TweenService = game:GetService("TweenService")
local U = {}
U.Font = Enum.Font.FredokaOne

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

-- outlined text
function U.text(props: {[string]: any}): TextLabel
	local t = U.new("TextLabel", {
		BackgroundTransparency = 1, Font = U.Font, TextScaled = true, TextColor3 = Color3.new(1, 1, 1), Size = UDim2.fromScale(1, 1),
	})
	local strokeT = props.Stroke or 2.5
	props.Stroke = nil
	for k, v in props do (t :: any)[k] = v end
	if strokeT > 0 then U.stroke(strokeT).Parent = t end
	return t
end

-- shared palette for actions (+1 Anime Eyes style: positive actions are glossy lime green)
U.GREEN = Color3.fromRGB(96, 226, 34)
U.ORANGE = Color3.fromRGB(255, 166, 26)
U.RED = Color3.fromRGB(236, 52, 76)
U.BLUE = Color3.fromRGB(56, 158, 255)
U.PURPLE = Color3.fromRGB(160, 84, 240)
U.GREY = Color3.fromRGB(118, 118, 132)
U.OUTLINE = Color3.fromRGB(20, 16, 28)

-- raised studs: tiled bevelled stud texture (light top-left edge, dark bottom-right edge)
U.STUDS = "rbxassetid://71524150589644" -- replaced by the bevelled stud texture on upload (assets/textures/studs_bevel.png)
function U.studs(parent: Instance, transp: number?, tile: number?): ImageLabel
	local s = U.new("ImageLabel", {Name = "Studs", BackgroundTransparency = 1, Image = U.STUDS, ScaleType = Enum.ScaleType.Tile,
		TileSize = UDim2.fromOffset(tile or 34, tile or 34), ImageTransparency = transp or 0.05, Size = UDim2.fromScale(1, 1), Parent = parent})
	U.corner(8).Parent = s
	return s
end

-- glossy dimensional surface on any frame/button: colour-preserving vertical gradient, white reflection over the
-- top ~28%, darker bottom lip. Children render above their parent, so the text label must be created after this.
function U.gloss(obj: GuiObject, color: Color3, radius: number?)
	local r = radius or 10
	local g = obj:FindFirstChildOfClass("UIGradient") or U.new("UIGradient", {Parent = obj})
	g.Rotation = 90
	g.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(0.55, Color3.fromRGB(236, 236, 236)), ColorSequenceKeypoint.new(1, Color3.fromRGB(196, 196, 196))})
	local lip = U.new("Frame", {Name = "Lip", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0.2, 0),
		BackgroundColor3 = U.shade(color, 0.62), BorderSizePixel = 0, Parent = obj})
	U.corner(r).Parent = lip
	local shine = U.new("Frame", {Name = "Shine", Position = UDim2.new(0, 5, 0, 3), Size = UDim2.new(1, -10, 0.3, 0),
		BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.35, BorderSizePixel = 0, Parent = obj})
	U.corner(math.max(r - 4, 4)).Parent = shine
	U.new("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 0.85)}), Parent = shine})
	return shine, lip
end

-- chunky glossy button: thick dark outline, gloss, bottom lip, optional studs, press bounce
function U.button(props: {[string]: any}): (TextButton, TextLabel)
	local color = props.Color or U.GREEN
	local b = U.new("TextButton", {
		AutoButtonColor = false, Text = "", BackgroundColor3 = color, Size = props.Size or UDim2.fromOffset(120, 44),
		Position = props.Position or UDim2.new(), AnchorPoint = props.AnchorPoint or Vector2.zero, Parent = props.Parent,
		LayoutOrder = props.LayoutOrder or 0, Name = props.Name or "Button",
	})
	local r = props.Radius or 8
	U.corner(r).Parent = b
	U.stroke(props.StrokeT or 3.5, U.OUTLINE, Enum.ApplyStrokeMode.Border).Parent = b
	if props.Studs ~= false then U.studs(b, 0.55, 18) end
	U.gloss(b, color, r)
	local label = U.text({Name = "Label", Text = props.Text or "", Size = UDim2.new(1, -10, 0.74, -4), Position = UDim2.fromOffset(5, 3),
		TextSize = props.TextSize, TextScaled = props.TextSize == nil, Stroke = props.TextStroke or 3, Parent = b})
	local base = b.Size
	b.MouseButton1Down:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.06), {Size = UDim2.new(base.X.Scale * 0.94, base.X.Offset * 0.94, base.Y.Scale * 0.94, base.Y.Offset * 0.94)}):Play()
	end)
	local function up() TweenService:Create(b, TweenInfo.new(0.12, Enum.EasingStyle.Back), {Size = base}):Play() end
	b.MouseButton1Up:Connect(up)
	b.MouseLeave:Connect(up)
	return b, label
end

-- recolour an existing glossy button (keeps gloss/lip consistent)
function U.recolor(b: GuiObject, color: Color3)
	b.BackgroundColor3 = color
	local lip = b:FindFirstChild("Lip") :: Frame?
	if lip then lip.BackgroundColor3 = U.shade(color, 0.62) end
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
