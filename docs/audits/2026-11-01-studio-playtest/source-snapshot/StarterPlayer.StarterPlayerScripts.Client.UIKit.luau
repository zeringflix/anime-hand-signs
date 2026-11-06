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

-- chunky button: coloured body with darker bottom lip, press bounce
function U.button(props: {[string]: any}): (TextButton, TextLabel)
	local color = props.Color or Color3.fromRGB(70, 200, 90)
	local b = U.new("TextButton", {
		AutoButtonColor = false, Text = "", BackgroundColor3 = color, Size = props.Size or UDim2.fromOffset(120, 44),
		Position = props.Position or UDim2.new(), AnchorPoint = props.AnchorPoint or Vector2.zero, Parent = props.Parent,
		LayoutOrder = props.LayoutOrder or 0, Name = props.Name or "Button",
	})
	U.corner(props.Radius or 10).Parent = b
	U.stroke(props.StrokeT or 3, U.shade(color, 0.45), Enum.ApplyStrokeMode.Border).Parent = b
	U.grad(Color3.new(1, 1, 1), Color3.fromRGB(190, 190, 190)).Parent = b
	local label = U.text({Text = props.Text or "", Size = UDim2.new(1, -10, 1, -8), Position = UDim2.fromOffset(5, 4), TextSize = props.TextSize, TextScaled = props.TextSize == nil, Parent = b})
	local base = b.Size
	b.MouseButton1Down:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.06), {Size = UDim2.new(base.X.Scale * 0.94, base.X.Offset * 0.94, base.Y.Scale * 0.94, base.Y.Offset * 0.94)}):Play()
	end)
	local function up() TweenService:Create(b, TweenInfo.new(0.12, Enum.EasingStyle.Back), {Size = base}):Play() end
	b.MouseButton1Up:Connect(up)
	b.MouseLeave:Connect(up)
	return b, label
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

