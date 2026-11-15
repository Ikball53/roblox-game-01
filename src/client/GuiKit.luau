-- Golden Core Miner: small helpers for building GUI in code. Every frame,
-- button and label in the game goes through here so the styling stays
-- consistent and the game script stays readable.

local GuiKit = {}

-- Create an instance, set its properties, and parent it in one call.
function GuiKit.make(className, props, parent)
	local inst = Instance.new(className)
	for key, value in pairs(props) do
		inst[key] = value
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

-- Round the corners of a frame or button.
function GuiKit.round(target, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = target
	return corner
end

-- Outline a frame or button with a coloured border.
function GuiKit.ring(target, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = target
	return stroke
end

-- Inset a frame's contents so text never touches the edge.
function GuiKit.pad(target, pixels)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, pixels)
	padding.PaddingBottom = UDim.new(0, pixels)
	padding.PaddingLeft = UDim.new(0, pixels)
	padding.PaddingRight = UDim.new(0, pixels)
	padding.Parent = target
	return padding
end

-- A button with the game's house style: dark panel, gold edge, cream text.
function GuiKit.button(text, parent)
	local btn = GuiKit.make("TextButton", {
		BackgroundColor3 = Color3.fromRGB(20, 38, 44),
		Text = text,
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		TextColor3 = Color3.fromRGB(245, 238, 220),
		AutoButtonColor = true,
	}, parent)
	GuiKit.round(btn, 10)
	GuiKit.ring(btn, Color3.fromRGB(255, 176, 66), 2)
	return btn
end

-- A small gold diamond, used as the gem icon next to counters.
function GuiKit.gemIcon(parent, size)
	local gem = GuiKit.make("Frame", {
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = Color3.fromRGB(255, 210, 63),
		BorderSizePixel = 0,
		Rotation = 45,
	}, parent)
	GuiKit.round(gem, 3)
	return gem
end

-- Seconds as M:SS, for the run timer and the best-time display.
function GuiKit.clock(seconds)
	local total = math.floor(seconds or 0)
	local minutes = math.floor(total / 60)
	local rest = total % 60
	return string.format("%d:%02d", minutes, rest)
end

-- A round dot of the given diameter and colour: hearts, pips, markers.
function GuiKit.dot(parent, diameter, color)
	local dot = GuiKit.make("Frame", {
		Size = UDim2.fromOffset(diameter, diameter),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
	}, parent)
	GuiKit.round(dot, math.floor(diameter / 2))
	return dot
end

return GuiKit
