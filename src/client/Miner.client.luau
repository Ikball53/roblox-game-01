-- Golden Core Miner: the game itself. It builds every screen, runs the
-- run, and keeps score. One run lasts a few minutes: mine ores, dodge
-- the falling rocks, buy upgrades, and break the Golden Core.

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local GuiKit = require(script.Parent:WaitForChild("GuiKit"))
local OreField = require(script.Parent:WaitForChild("OreField"))

local gui = script.Parent
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false

local GOLD = Color3.fromRGB(255, 176, 66)
local CREAM = Color3.fromRGB(245, 238, 220)
local DARK = Color3.fromRGB(12, 24, 30)
local PANEL = Color3.fromRGB(20, 38, 44)
local RED = Color3.fromRGB(255, 70, 70)

local state = {
	running = false,
	gems = 0,
	earned = 0,
	mined = 0,
	hearts = 3,
	zone = 1,
	pickaxe = 0,
	dash = 0,
	magnet = 0,
	minerSlot = 1,
	dashUntil = 0,
	dashReadyAt = 0,
	startedAt = 0,
	elapsed = 0,
	bestTime = nil,
	bestGems = 0,
}

local ui = {}

-- A dark rounded panel, the base of every screen section.
local function panel(parent, size, pos)
	local frame = GuiKit.make("Frame", {
		Size = size,
		Position = pos,
		BackgroundColor3 = PANEL,
		BorderSizePixel = 0,
	}, parent)
	GuiKit.round(frame, 12)
	return frame
end

-- ---------- Start screen ----------

local function buildStart()
	local screen = GuiKit.make("Frame", {
		Name = "StartScreen",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = DARK,
		BorderSizePixel = 0,
	}, gui)

	GuiKit.make("TextLabel", {
		Size = UDim2.fromScale(0.9, 0.11),
		Position = UDim2.fromScale(0.05, 0.03),
		BackgroundTransparency = 1,
		Text = "GOLDEN CORE MINER",
		Font = Enum.Font.GothamBlack,
		TextScaled = true,
		TextColor3 = GOLD,
	}, screen)
	GuiKit.make("TextLabel", {
		Size = UDim2.fromScale(0.9, 0.05),
		Position = UDim2.fromScale(0.05, 0.145),
		BackgroundTransparency = 1,
		Text = "Dig deep. Dodge the rocks. Break the Golden Core.",
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		TextColor3 = CREAM,
	}, screen)

	-- One card per zone: name, vein, ores, and what unlocks it.
	for i, zone in ipairs(GameData.ZONES) do
		local card = panel(screen, UDim2.fromScale(0.30, 0.24), UDim2.fromScale(0.025 + (i - 1) * 0.325, 0.22))
		GuiKit.ring(card, zone.accent, 2)
		GuiKit.make("TextLabel", {
			Size = UDim2.fromScale(0.9, 0.22),
			Position = UDim2.fromScale(0.05, 0.05),
			BackgroundTransparency = 1,
			Text = zone.name,
			Font = Enum.Font.GothamBlack,
			TextScaled = true,
			TextColor3 = zone.accent,
		}, card)
		GuiKit.make("TextLabel", {
			Size = UDim2.fromScale(0.9, 0.16),
			Position = UDim2.fromScale(0.05, 0.28),
			BackgroundTransparency = 1,
			Text = zone.tag,
			Font = Enum.Font.GothamBold,
			TextScaled = true,
			TextColor3 = CREAM,
		}, card)
		local oreText = ""
		for j, ore in ipairs(zone.ores) do
			if j > 1 then
				oreText = oreText .. "  "
			end
			oreText = oreText .. ore.name .. " +" .. ore.gems
		end
		GuiKit.make("TextLabel", {
			Size = UDim2.fromScale(0.9, 0.16),
			Position = UDim2.fromScale(0.05, 0.48),
			BackgroundTransparency = 1,
			Text = oreText,
			Font = Enum.Font.Gotham,
			TextScaled = true,
			TextColor3 = CREAM,
		}, card)
		local unlock = "FREE"
		if zone.unlockGems > 0 then
			unlock = zone.unlockGems .. " gems"
		end
		GuiKit.make("TextLabel", {
			Size = UDim2.fromScale(0.9, 0.18),
			Position = UDim2.fromScale(0.05, 0.70),
			BackgroundTransparency = 1,
			Text = unlock,
			Font = Enum.Font.GothamBold,
			TextScaled = true,
			TextColor3 = GOLD,
		}, card)
	end

	-- How to play, in three short lines.
	local how = panel(screen, UDim2.fromScale(0.9, 0.15), UDim2.fromScale(0.05, 0.49))
	GuiKit.make("TextLabel", {
		Size = UDim2.fromScale(0.94, 0.28),
		Position = UDim2.fromScale(0.03, 0.06),
		BackgroundTransparency = 1,
		Text = "HOW TO PLAY",
		Font = Enum.Font.GothamBlack,
		TextScaled = true,
		TextColor3 = GOLD,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, how)
	local lines = {
		"Tap an ore to walk over and mine it.",
		"Rocks fall without warning - DASH to dodge.",
		"Spend gems in the Workshop to dig deeper.",
	}
	for i, line in ipairs(lines) do
		GuiKit.make("TextLabel", {
			Size = UDim2.fromScale(0.94, 0.2),
			Position = UDim2.fromScale(0.03, 0.32 + (i - 1) * 0.21),
			BackgroundTransparency = 1,
			Text = i .. ". " .. line,
			Font = Enum.Font.Gotham,
			TextScaled = true,
			TextColor3 = CREAM,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, how)
	end

	ui.bestLabel = GuiKit.make("TextLabel", {
		Size = UDim2.fromScale(0.9, 0.05),
		Position = UDim2.fromScale(0.05, 0.67),
		BackgroundTransparency = 1,
		Text = "Best time: --:--      Most gems: 0",
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		TextColor3 = CREAM,
	}, screen)

	ui.playButton = GuiKit.make("TextButton", {
		Size = UDim2.fromScale(0.5, 0.11),
		Position = UDim2.fromScale(0.25, 0.75),
		BackgroundColor3 = GOLD,
		Text = "PLAY",
		Font = Enum.Font.GothamBlack,
		TextScaled = true,
		TextColor3 = DARK,
		AutoButtonColor = true,
	}, screen)
	GuiKit.round(ui.playButton, 14)

	GuiKit.make("TextLabel", {
		Size = UDim2.fromScale(0.9, 0.05),
		Position = UDim2.fromScale(0.05, 0.89),
		BackgroundTransparency = 1,
		Text = "Workshop: Pickaxe  -  Swift Boots  -  Lucky Magnet",
		Font = Enum.Font.Gotham,
		TextScaled = true,
		TextColor3 = CREAM,
	}, screen)

	return screen
end

-- ---------- Game screen ----------

local function buildGame()
	local screen = GuiKit.make("Frame", {
		Name = "GameScreen",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = GameData.ZONES[1].field,
		BorderSizePixel = 0,
		Visible = false,
	}, gui)

	-- Top bar: gems on the left, timer in the middle, hearts on the right.
	local gemIcon = GuiKit.gemIcon(screen, 26)
	gemIcon.Position = UDim2.fromScale(0.03, 0.035)
	ui.gemLabel = GuiKit.make("TextLabel", {
		Size = UDim2.fromScale(0.2, 0.07),
		Position = UDim2.fromScale(0.07, 0.015),
		BackgroundTransparency = 1,
		Text = "0",
		Font = Enum.Font.GothamBlack,
		TextScaled = true,
		TextColor3 = GOLD,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, screen)
	ui.timerLabel = GuiKit.make("TextLabel", {
		Size = UDim2.fromScale(0.2, 0.07),
		Position = UDim2.fromScale(0.4, 0.015),
		BackgroundTransparency = 1,
		Text = "0:00",
		Font = Enum.Font.GothamBlack,
		TextScaled = true,
		TextColor3 = CREAM,
	}, screen)
	ui.hearts = {}
	for i = 1, GameData.TUNING.hearts do
		local heart = GuiKit.dot(screen, 24, RED)
		heart.Position = UDim2.fromScale(0.88 + (i - 1) * 0.04, 0.03)
		ui.hearts[i] = heart
	end

	-- Zone label and the progress bar toward the next zone.
	ui.zoneLabel = GuiKit.make("TextLabel", {
		Size = UDim2.fromScale(0.4, 0.06),
		Position = UDim2.fromScale(0.03, 0.105),
		BackgroundTransparency = 1,
		Text = "SURFACE - Copper Vein",
		Font = Enum.Font.GothamBlack,
		TextScaled = true,
		TextColor3 = CREAM,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, screen)
	local progBack = GuiKit.make("Frame", {
		Size = UDim2.fromScale(0.45, 0.035),
		Position = UDim2.fromScale(0.52, 0.115),
		BackgroundColor3 = DARK,
		BorderSizePixel = 0,
	}, screen)
	GuiKit.round(progBack, 6)
	ui.progBar = GuiKit.make("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = GOLD,
		BorderSizePixel = 0,
	}, progBack)
	GuiKit.round(ui.progBar, 6)
	ui.progLabel = GuiKit.make("TextLabel", {
		Size = UDim2.fromScale(0.45, 0.04),
		Position = UDim2.fromScale(0.52, 0.155),
		BackgroundTransparency = 1,
		Text = "0 / 25 gems to DEEP",
		Font = Enum.Font.Gotham,
		TextScaled = true,
		TextColor3 = CREAM,
		TextXAlignment = Enum.TextXAlignment.Right,
	}, screen)

	-- The ore field itself.
	local fieldFrame = GuiKit.make("Frame", {
		Name = "Field",
		Size = UDim2.fromScale(0.94, 0.60),
		Position = UDim2.fromScale(0.03, 0.21),
		BackgroundTransparency = 1,
	}, screen)
	ui.field = OreField.new(fieldFrame, GuiKit, GameData)

	-- The miner: a small helmeted digger that walks to the tapped ore.
	local miner = GuiKit.make("Frame", {
		Name = "Miner",
		Size = UDim2.fromScale(0.07, 0.09),
		BackgroundTransparency = 1,
		ZIndex = 10,
	}, fieldFrame)
	GuiKit.make("Frame", {
		Size = UDim2.fromScale(1, 0.4),
		Position = UDim2.fromScale(0, 0),
		BackgroundColor3 = GOLD,
		BorderSizePixel = 0,
	}, miner)
	GuiKit.make("Frame", {
		Size = UDim2.fromScale(0.85, 0.32),
		Position = UDim2.fromScale(0.075, 0.38),
		BackgroundColor3 = Color3.fromRGB(255, 200, 150),
		BorderSizePixel = 0,
	}, miner)
	GuiKit.make("Frame", {
		Size = UDim2.fromScale(0.95, 0.28),
		Position = UDim2.fromScale(0.025, 0.68),
		BackgroundColor3 = Color3.fromRGB(40, 140, 160),
		BorderSizePixel = 0,
	}, miner)
	ui.miner = miner

	-- Double-tap the empty field to dash. The nodes sit above this pad.
	local pad = GuiKit.make("TextButton", {
		Name = "FieldPad",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 1,
	}, fieldFrame)
	ui.fieldPad = pad

	-- Bottom row: Workshop on the left, DASH on the right.
	ui.workshopButton = GuiKit.button("WORKSHOP", screen)
	ui.workshopButton.Size = UDim2.fromScale(0.30, 0.11)
	ui.workshopButton.Position = UDim2.fromScale(0.03, 0.85)
	ui.dashButton = GuiKit.make("TextButton", {
		Size = UDim2.fromScale(0.30, 0.11),
		Position = UDim2.fromScale(0.67, 0.85),
		BackgroundColor3 = GOLD,
		Text = "DASH",
		Font = Enum.Font.GothamBlack,
		TextScaled = true,
		TextColor3 = DARK,
		AutoButtonColor = true,
	}, screen)
	GuiKit.round(ui.dashButton, 14)

	-- Red flash when a rock hits the miner.
	ui.flash = GuiKit.make("Frame", {
		Name = "Flash",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = RED,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 20,
	}, screen)

	-- Big centre banner for zone unlocks.
	ui.banner = GuiKit.make("TextLabel", {
		Size = UDim2.fromScale(0.8, 0.1),
		Position = UDim2.fromScale(0.1, 0.42),
		BackgroundTransparency = 1,
		Text = "",
		Font = Enum.Font.GothamBlack,
		TextScaled = true,
		TextColor3 = GOLD,
		Visible = false,
		ZIndex = 21,
	}, screen)

	return screen
end

-- ---------- Workshop ----------

local UPGRADE_ORDER = { "pickaxe", "dash", "magnet" }

local function buildWorkshop()
	local screen = GuiKit.make("Frame", {
		Name = "Workshop",
		Size = UDim2.fromScale(0.86, 0.62),
		Position = UDim2.fromScale(0.07, 0.19),
		BackgroundColor3 = PANEL,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 30,
	}, gui)
	GuiKit.round(screen, 14)
	GuiKit.ring(screen, GOLD, 2)
	GuiKit.make("TextLabel", {
		Size = UDim2.fromScale(0.9, 0.12),
		Position = UDim2.fromScale(0.05, 0.03),
		BackgroundTransparency = 1,
		Text = "WORKSHOP",
		Font = Enum.Font.GothamBlack,
		TextScaled = true,
		TextColor3 = GOLD,
		ZIndex = 31,
	}, screen)

	ui.upgradeRows = {}
	for i, key in ipairs(UPGRADE_ORDER) do
		local def = GameData.UPGRADES[key]
		local row = panel(screen, UDim2.fromScale(0.9, 0.2), UDim2.fromScale(0.05, 0.18 + (i - 1) * 0.24))
		row.ZIndex = 31
		GuiKit.make("TextLabel", {
			Size = UDim2.fromScale(0.4, 0.4),
			Position = UDim2.fromScale(0.04, 0.1),
			BackgroundTransparency = 1,
			Text = def.name,
			Font = Enum.Font.GothamBlack,
			TextScaled = true,
			TextColor3 = CREAM,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 32,
		}, row)
		GuiKit.make("TextLabel", {
			Size = UDim2.fromScale(0.55, 0.32),
			Position = UDim2.fromScale(0.04, 0.52),
			BackgroundTransparency = 1,
			Text = def.blurb,
			Font = Enum.Font.Gotham,
			TextScaled = true,
			TextColor3 = CREAM,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 32,
		}, row)
		local pips = {}
		for p = 1, 3 do
			local pip = GuiKit.dot(row, 16, Color3.fromRGB(60, 70, 78))
			pip.Position = UDim2.fromScale(0.62 + (p - 1) * 0.05, 0.3)
			pip.ZIndex = 32
			pips[p] = pip
		end
		local buy = GuiKit.make("TextButton", {
			Size = UDim2.fromScale(0.2, 0.6),
			Position = UDim2.fromScale(0.76, 0.2),
			BackgroundColor3 = GOLD,
			Text = def.costs[1] .. " gems",
			Font = Enum.Font.GothamBold,
			TextScaled = true,
			TextColor3 = DARK,
			AutoButtonColor = true,
			ZIndex = 32,
		}, row)
		GuiKit.round(buy, 8)
		ui.upgradeRows[key] = { pips = pips, buy = buy }
	end

	ui.closeWorkshop = GuiKit.make("TextButton", {
		Size = UDim2.fromScale(0.3, 0.1),
		Position = UDim2.fromScale(0.35, 0.88),
		BackgroundColor3 = GOLD,
		Text = "CLOSE",
		Font = Enum.Font.GothamBlack,
		TextScaled = true,
		TextColor3 = DARK,
		AutoButtonColor = true,
		ZIndex = 31,
	}, screen)
	GuiKit.round(ui.closeWorkshop, 10)

	return screen
end

-- ---------- Finish screen ----------

local function buildFinish()
	local screen = GuiKit.make("Frame", {
		Name = "FinishScreen",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = DARK,
		BorderSizePixel = 0,
		Visible = false,
	}, gui)
	ui.finishTitle = GuiKit.make("TextLabel", {
		Size = UDim2.fromScale(0.9, 0.12),
		Position = UDim2.fromScale(0.05, 0.08),
		BackgroundTransparency = 1,
		Text = "GOLDEN CORE BROKEN!",
		Font = Enum.Font.GothamBlack,
		TextScaled = true,
		TextColor3 = GOLD,
	}, screen)
	ui.finishStats = GuiKit.make("TextLabel", {
		Size = UDim2.fromScale(0.8, 0.35),
		Position = UDim2.fromScale(0.1, 0.26),
		BackgroundTransparency = 1,
		Text = "",
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		TextColor3 = CREAM,
	}, screen)
	ui.againButton = GuiKit.make("TextButton", {
		Size = UDim2.fromScale(0.5, 0.11),
		Position = UDim2.fromScale(0.25, 0.68),
		BackgroundColor3 = GOLD,
		Text = "PLAY AGAIN",
		Font = Enum.Font.GothamBlack,
		TextScaled = true,
		TextColor3 = DARK,
		AutoButtonColor = true,
	}, screen)
	GuiKit.round(ui.againButton, 14)
	return screen
end

ui.startScreen = buildStart()
ui.gameScreen = buildGame()
ui.workshop = buildWorkshop()
ui.finishScreen = buildFinish()

-- ---------- HUD refresh ----------

local function refreshHud()
	ui.gemLabel.Text = tostring(state.gems)
	for i, heart in ipairs(ui.hearts) do
		heart.Visible = i <= state.hearts
	end
	local zone = GameData.ZONES[state.zone]
	ui.zoneLabel.Text = zone.name .. " - " .. zone.tag
	if state.zone < #GameData.ZONES then
		local nextZone = GameData.ZONES[state.zone + 1]
		local need = nextZone.unlockGems
		ui.progBar.Size = UDim2.fromScale(math.min(state.earned / need, 1), 1)
		ui.progLabel.Text = state.earned .. " / " .. need .. " gems to " .. nextZone.name
	else
		ui.progBar.Size = UDim2.fromScale(1, 1)
		ui.progLabel.Text = "Break the Golden Core!"
	end
	local now = os.clock()
	if now < state.dashReadyAt then
		ui.dashButton.Text = string.format("%.1f", state.dashReadyAt - now)
		ui.dashButton.BackgroundColor3 = Color3.fromRGB(90, 100, 108)
	else
		ui.dashButton.Text = "DASH"
		ui.dashButton.BackgroundColor3 = GOLD
	end
end

local function refreshWorkshop()
	for _, key in ipairs(UPGRADE_ORDER) do
		local def = GameData.UPGRADES[key]
		local level = state[key]
		local row = ui.upgradeRows[key]
		for p, pip in ipairs(row.pips) do
			if p <= level then
				pip.BackgroundColor3 = GOLD
			else
				pip.BackgroundColor3 = Color3.fromRGB(60, 70, 78)
			end
		end
		if level >= #def.costs then
			row.buy.Text = "MAX"
			row.buy.BackgroundColor3 = Color3.fromRGB(90, 100, 108)
		else
			row.buy.Text = def.costs[level + 1] .. " gems"
			if state.gems >= def.costs[level + 1] then
				row.buy.BackgroundColor3 = GOLD
			else
				row.buy.BackgroundColor3 = Color3.fromRGB(120, 90, 40)
			end
		end
	end
end

local function showBanner(text)
	ui.banner.Text = text
	ui.banner.Visible = true
	task.delay(2, function()
		ui.banner.Visible = false
	end)
end

-- ---------- Run flow ----------

-- Forward-declared: mineCore and loseHeart end the run, and they are
-- written above the definition.
local endRun

local function moveMinerTo(slotIndex)
	local slot = ui.field.slots[slotIndex]
	if not slot then
		return
	end
	local pos = slot.button.Position
	local goal = UDim2.fromScale(pos.X.Scale + 0.005, pos.Y.Scale - 0.05)
	TweenService:Create(ui.miner, TweenInfo.new(0.15, Enum.EasingStyle.Quad), { Position = goal }):Play()
end

local function zoneCheck()
	if state.zone >= #GameData.ZONES then
		return
	end
	local nextZone = GameData.ZONES[state.zone + 1]
	if state.earned < nextZone.unlockGems then
		return
	end
	state.zone = state.zone + 1
	local zone = GameData.ZONES[state.zone]
	TweenService:Create(ui.gameScreen, TweenInfo.new(0.6), { BackgroundColor3 = zone.field }):Play()
	ui.field:fill(zone)
	if state.zone == #GameData.ZONES then
		ui.field:showCore()
	end
	showBanner(zone.name .. " ZONE UNLOCKED!")
	refreshHud()
end

local function floatGain(slotIndex, text)
	local slot = ui.field.slots[slotIndex]
	if not slot then
		return
	end
	local label = GuiKit.make("TextLabel", {
		Size = UDim2.fromScale(0.3, 0.12),
		Position = slot.button.Position,
		BackgroundTransparency = 1,
		Text = text,
		Font = Enum.Font.GothamBlack,
		TextScaled = true,
		TextColor3 = GOLD,
		ZIndex = 15,
	}, ui.field.frame)
	local goal = UDim2.fromScale(slot.button.Position.X.Scale, slot.button.Position.Y.Scale - 0.12)
	local tween = TweenService:Create(label, TweenInfo.new(0.8), { Position = goal, TextTransparency = 1 })
	tween:Play()
	tween.Completed:Connect(function()
		label:Destroy()
	end)
end

local function mine(index)
	if not state.running then
		return
	end
	state.minerSlot = index
	moveMinerTo(index)
	local result = ui.field:hit(index, GameData.TUNING.baseDamage + state.pickaxe)
	if not result then
		return
	end
	if result.broken then
		local gain = result.ore.gems + state.magnet
		state.gems = state.gems + gain
		state.earned = state.earned + gain
		state.mined = state.mined + 1
		floatGain(index, "+" .. gain)
		refreshHud()
		zoneCheck()
	end
end

local function mineCore()
	if not state.running then
		return
	end
	local broken = ui.field:hitCore(GameData.TUNING.baseDamage + state.pickaxe)
	if broken then
		endRun(true)
	end
end

local function loseHeart()
	state.hearts = state.hearts - 1
	ui.flash.BackgroundTransparency = 0.4
	TweenService:Create(ui.flash, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
	refreshHud()
	if state.hearts <= 0 then
		endRun(false)
	end
end

local function dash()
	if not state.running then
		return
	end
	local now = os.clock()
	if now < state.dashReadyAt then
		return
	end
	local def = GameData.UPGRADES.dash
	state.dashUntil = now + GameData.TUNING.dashSeconds
	state.dashReadyAt = now + def.cooldowns[state.dash + 1]
	local hop = TweenService:Create(ui.miner, TweenInfo.new(0.2), { Position = UDim2.fromScale(ui.miner.Position.X.Scale, ui.miner.Position.Y.Scale - 0.08) })
	hop:Play()
	hop.Completed:Connect(function()
		TweenService:Create(ui.miner, TweenInfo.new(0.2), { Position = UDim2.fromScale(ui.miner.Position.X.Scale, ui.miner.Position.Y.Scale + 0.08) }):Play()
	end)
	refreshHud()
end

local function buyUpgrade(key)
	local def = GameData.UPGRADES[key]
	local level = state[key]
	if level >= #def.costs then
		return
	end
	local cost = def.costs[level + 1]
	if state.gems < cost then
		return
	end
	state.gems = state.gems - cost
	state[key] = level + 1
	refreshWorkshop()
	refreshHud()
end

local function rockLoop()
	while state.running do
		-- Deeper zones rain rocks faster, so the endgame stays tense.
		local rate = GameData.ZONES[state.zone].rockEvery
		local waitFor = math.random(rate.min * 10, rate.max * 10) / 10
		task.wait(waitFor)
		if not state.running then
			break
		end
		local target
		if math.random() < 0.5 then
			target = state.minerSlot
		else
			target = math.random(1, GameData.TUNING.nodeCount)
		end
		ui.field:warnSlot(target)
		task.wait(GameData.TUNING.rockWarnSeconds)
		if not state.running then
			break
		end
		ui.field:dropRock(target)
		if target == state.minerSlot and os.clock() > state.dashUntil then
			loseHeart()
		end
	end
end

local function timerLoop()
	while state.running do
		state.elapsed = os.clock() - state.startedAt
		ui.timerLabel.Text = GuiKit.clock(state.elapsed)
		refreshHud()
		task.wait(0.1)
	end
end

local function startRun()
	state.running = false
	state.gems = 0
	state.earned = 0
	state.mined = 0
	state.hearts = GameData.TUNING.hearts
	state.zone = 1
	state.pickaxe = 0
	state.dash = 0
	state.magnet = 0
	state.minerSlot = 1
	state.dashUntil = 0
	state.dashReadyAt = 0
	state.elapsed = 0
	ui.field:clearRocks()
	ui.field:hideCore()
	ui.field:fill(GameData.ZONES[1])
	ui.gameScreen.BackgroundColor3 = GameData.ZONES[1].field
	ui.startScreen.Visible = false
	ui.finishScreen.Visible = false
	ui.workshop.Visible = false
	ui.gameScreen.Visible = true
	moveMinerTo(1)
	refreshHud()
	refreshWorkshop()
	state.running = true
	state.startedAt = os.clock()
	task.spawn(timerLoop)
	task.spawn(rockLoop)
end

endRun = function(won)
	state.running = false
	if won then
		if state.bestTime == nil or state.elapsed < state.bestTime then
			state.bestTime = state.elapsed
		end
	end
	if state.earned > state.bestGems then
		state.bestGems = state.earned
	end
	ui.bestLabel.Text = "Best time: "
		.. (state.bestTime and GuiKit.clock(state.bestTime) or "--:--")
		.. "      Most gems: "
		.. state.bestGems
	if won then
		ui.finishTitle.Text = "GOLDEN CORE BROKEN!"
		ui.finishTitle.TextColor3 = GOLD
	else
		ui.finishTitle.Text = "THE ROCKS GOT YOU"
		ui.finishTitle.TextColor3 = RED
	end
	ui.finishStats.Text = "Time: "
		.. GuiKit.clock(state.elapsed)
		.. "\nGems earned: "
		.. state.earned
		.. "\nOres mined: "
		.. state.mined
		.. "\nPickaxe level: "
		.. state.pickaxe
	ui.gameScreen.Visible = false
	ui.workshop.Visible = false
	ui.finishScreen.Visible = true
end

-- ---------- Wiring ----------

ui.playButton.Activated:Connect(startRun)
ui.againButton.Activated:Connect(startRun)
ui.dashButton.Activated:Connect(dash)
ui.workshopButton.Activated:Connect(function()
	refreshWorkshop()
	ui.workshop.Visible = true
end)
ui.closeWorkshop.Activated:Connect(function()
	ui.workshop.Visible = false
end)
for key, row in pairs(ui.upgradeRows) do
	row.buy.Activated:Connect(function()
		buyUpgrade(key)
	end)
end
for i, slot in ipairs(ui.field.slots) do
	slot.button.Activated:Connect(function()
		mine(i)
	end)
end
ui.field.core.Activated:Connect(mineCore)

local lastPadTap = 0
ui.fieldPad.Activated:Connect(function()
	local now = os.clock()
	if now - lastPadTap < 0.35 then
		dash()
	end
	lastPadTap = now
end)

refreshHud()
