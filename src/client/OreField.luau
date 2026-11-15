-- Golden Core Miner: the ore field. Six mineable nodes in a grid, plus the
-- Golden Core banner on top. It owns the nodes' looks and hit points; the
-- game controller owns the rules (gems, zones, hearts).

local OreField = {}
OreField.__index = OreField

local COLUMNS = 3

local function slotPosition(index)
	local col = (index - 1) % COLUMNS
	local row = math.floor((index - 1) / COLUMNS)
	-- Rows start below the Golden Core banner so the miner, which parks
	-- just above its node, never overlaps the banner.
	return UDim2.fromScale(0.015 + col * 0.328, 0.19 + row * 0.41)
end

function OreField.new(fieldFrame, kit, data)
	local self = setmetatable({}, OreField)
	self.kit = kit
	self.data = data
	self.frame = fieldFrame
	self.zone = data.ZONES[1]
	self.slots = {}

	-- The Golden Core banner: hidden until the Core zone opens.
	local core = kit.make("TextButton", {
		Name = "GoldenCore",
		Size = UDim2.fromScale(1, 0.13),
		Position = UDim2.fromScale(0, 0),
		BackgroundColor3 = data.CORE.color,
		Text = "",
		Visible = false,
		AutoButtonColor = true,
	}, fieldFrame)
	kit.round(core, 10)
	kit.ring(core, Color3.fromRGB(120, 80, 0), 2)
	kit.make("TextLabel", {
		Name = "CoreName",
		Size = UDim2.fromScale(1, 0.55),
		Position = UDim2.fromScale(0, 0.02),
		BackgroundTransparency = 1,
		Text = "GOLDEN CORE",
		Font = Enum.Font.GothamBlack,
		TextScaled = true,
		TextColor3 = Color3.fromRGB(60, 35, 0),
	}, core)
	local coreBarBack = kit.make("Frame", {
		Name = "CoreBarBack",
		Size = UDim2.fromScale(0.9, 0.22),
		Position = UDim2.fromScale(0.05, 0.66),
		BackgroundColor3 = Color3.fromRGB(60, 35, 0),
		BorderSizePixel = 0,
	}, core)
	kit.round(coreBarBack, 5)
	local coreBar = kit.make("Frame", {
		Name = "CoreBar",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
	}, coreBarBack)
	kit.round(coreBar, 5)
	self.core = core
	self.coreBar = coreBar
	self.coreHp = 0
	self.coreMax = 1

	for i = 1, data.TUNING.nodeCount do
		local button = kit.make("TextButton", {
			Name = "Node" .. i,
			Size = UDim2.fromScale(0.305, 0.38),
			Position = slotPosition(i),
			BackgroundColor3 = Color3.fromRGB(24, 40, 46),
			Text = "",
			AutoButtonColor = true,
		}, fieldFrame)
		kit.round(button, 12)
		kit.ring(button, Color3.fromRGB(70, 100, 110), 2)

		local face = kit.make("Frame", {
			Name = "Face",
			Size = UDim2.fromScale(0.62, 0.52),
			Position = UDim2.fromScale(0.19, 0.10),
			BackgroundColor3 = Color3.fromRGB(214, 116, 60),
			BorderSizePixel = 0,
		}, button)
		kit.round(face, 10)
		-- Three bright studs on the ore face, so it reads as a gem vein.
		for s = 1, 3 do
			kit.make("Frame", {
				Size = UDim2.fromOffset(10, 10),
				Position = UDim2.fromScale(0.16 + (s - 1) * 0.3, 0.32),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.25,
				BorderSizePixel = 0,
				Rotation = 45,
			}, face)
		end

		local hpBack = kit.make("Frame", {
			Name = "HpBack",
			Size = UDim2.fromScale(0.7, 0.09),
			Position = UDim2.fromScale(0.15, 0.72),
			BackgroundColor3 = Color3.fromRGB(10, 18, 22),
			BorderSizePixel = 0,
		}, button)
		kit.round(hpBack, 4)
		local hp = kit.make("Frame", {
			Name = "Hp",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(120, 220, 120),
			BorderSizePixel = 0,
		}, hpBack)
		kit.round(hp, 4)

		local nameLabel = kit.make("TextLabel", {
			Name = "OreName",
			Size = UDim2.fromScale(1, 0.14),
			Position = UDim2.fromScale(0, 0.85),
			BackgroundTransparency = 1,
			Text = "Copper",
			Font = Enum.Font.GothamBold,
			TextScaled = true,
			TextColor3 = Color3.fromRGB(245, 238, 220),
		}, button)

		-- Rock warning: a red ring plus an exclamation mark.
		local warn = kit.make("Frame", {
			Name = "Warn",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Visible = false,
		}, button)
		kit.ring(warn, Color3.fromRGB(255, 60, 60), 4)
		kit.round(warn, 12)
		kit.make("TextLabel", {
			Size = UDim2.fromScale(0.4, 0.4),
			Position = UDim2.fromScale(0.3, 0.05),
			BackgroundTransparency = 1,
			Text = "!",
			Font = Enum.Font.GothamBlack,
			TextScaled = true,
			TextColor3 = Color3.fromRGB(255, 60, 60),
		}, warn)

		-- The fallen rock itself: a grey boulder covering the node.
		local rock = kit.make("Frame", {
			Name = "Rock",
			Size = UDim2.fromScale(0.88, 0.88),
			Position = UDim2.fromScale(0.06, 0.06),
			BackgroundColor3 = Color3.fromRGB(92, 92, 98),
			BorderSizePixel = 0,
			Visible = false,
		}, button)
		kit.round(rock, 16)

		self.slots[i] = {
			button = button,
			face = face,
			hpBar = hp,
			nameLabel = nameLabel,
			warn = warn,
			rock = rock,
			ore = nil,
			hp = 0,
			maxHp = 1,
			buried = false,
		}
	end

	return self
end

-- Recolour a slot from its ore and remaining hits: the face darkens and
-- the health bar shrinks as the node cracks.
function OreField:paint(slot)
	local share = slot.hp / slot.maxHp
	local base = slot.ore.color
	slot.face.BackgroundColor3 = Color3.new(
		base.R * (0.45 + 0.55 * share),
		base.G * (0.45 + 0.55 * share),
		base.B * (0.45 + 0.55 * share)
	)
	slot.hpBar.Size = UDim2.fromScale(math.max(share, 0.05), 1)
	if share > 0.5 then
		slot.hpBar.BackgroundColor3 = Color3.fromRGB(120, 220, 120)
	elseif share > 0.25 then
		slot.hpBar.BackgroundColor3 = Color3.fromRGB(255, 200, 60)
	else
		slot.hpBar.BackgroundColor3 = Color3.fromRGB(255, 80, 60)
	end
end

-- Fill every slot with a fresh ore from the given zone.
function OreField:fill(zone)
	self.zone = zone
	for _, slot in ipairs(self.slots) do
		self:rollSlot(slot)
	end
end

function OreField:rollSlot(slot)
	local ore = self.data.pickOre(self.zone)
	slot.ore = ore
	slot.hp = ore.hits
	slot.maxHp = ore.hits
	slot.buried = false
	slot.rock.Visible = false
	slot.warn.Visible = false
	slot.nameLabel.Text = ore.name
	self:paint(slot)
end

-- Hit a node. Returns nil when the node cannot be mined right now,
-- otherwise a small table saying whether it broke and what it was.
function OreField:hit(index, damage)
	local slot = self.slots[index]
	if not slot or not slot.ore or slot.buried then
		return nil
	end
	slot.hp = slot.hp - damage
	if slot.hp <= 0 then
		local ore = slot.ore
		slot.ore = nil
		slot.nameLabel.Text = ""
		slot.hpBar.Size = UDim2.fromScale(0, 1)
		task.delay(self.data.TUNING.nodeRespawnSeconds, function()
			if slot.ore == nil then
				self:rollSlot(slot)
			end
		end)
		return { broken = true, ore = ore }
	end
	self:paint(slot)
	return { broken = false, ore = slot.ore }
end

-- Flash the rock warning on a slot; the controller drops the rock next.
function OreField:warnSlot(index)
	local slot = self.slots[index]
	if slot then
		slot.warn.Visible = true
	end
end

-- Drop a rock on a slot, burying its node for a few seconds.
function OreField:dropRock(index)
	local slot = self.slots[index]
	if not slot then
		return
	end
	slot.warn.Visible = false
	slot.rock.Visible = true
	slot.buried = true
	task.delay(self.data.TUNING.rockBuriedSeconds, function()
		slot.rock.Visible = false
		slot.buried = false
	end)
end

-- Clear every warning and rock at once, for a fresh run.
function OreField:clearRocks()
	for _, slot in ipairs(self.slots) do
		slot.warn.Visible = false
		slot.rock.Visible = false
		slot.buried = false
	end
end

-- Reveal the Golden Core banner with a full health bar.
function OreField:showCore()
	self.coreHp = self.data.CORE.hits
	self.coreMax = self.data.CORE.hits
	self.coreBar.Size = UDim2.fromScale(1, 1)
	self.core.Visible = true
end

function OreField:hideCore()
	self.core.Visible = false
end

-- Hit the Golden Core. Returns true the moment it breaks.
function OreField:hitCore(damage)
	if not self.core.Visible then
		return false
	end
	self.coreHp = self.coreHp - damage
	self.coreBar.Size = UDim2.fromScale(math.max(self.coreHp / self.coreMax, 0), 1)
	return self.coreHp <= 0
end

return OreField
