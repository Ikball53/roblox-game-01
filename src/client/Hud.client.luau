-- GoldenTowerHud: the client half of the Golden Sky Tower.
-- It draws every screen in code. A climber joins to a golden opening
-- screen: the tower's name in white marble letters with gold inlay, a
-- golden PLAY button, and the world glowing warmly behind a soft veil.
-- The climb HUD stays hidden and the clock stays still until PLAY is
-- pressed. Winning opens a golden finish screen with the climb time,
-- the death count and the session best, plus a PLAY AGAIN button that
-- starts a fresh climb. Everything sits clear of the top-left corner,
-- where Roblox puts its own menu.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local TowerTuning = require(ReplicatedStorage:WaitForChild("GameConfig"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local checkpointEvent = ReplicatedStorage:WaitForChild("TowerCheckpoint")
local winEvent = ReplicatedStorage:WaitForChild("TowerWin")
local resetEvent = ReplicatedStorage:WaitForChild("TowerReset")

-- Gold for every celebration in this file: pure gold, champagne and
-- white, matching the shower over the crown pad.
local CROWN_CONFETTI = {
	Color3.fromRGB(255, 215, 0),
	Color3.fromRGB(240, 210, 150),
	Color3.fromRGB(255, 255, 255),
}

local RICH_GOLD = Color3.fromRGB(255, 214, 64)
local DEEP_GOLD = Color3.fromRGB(212, 175, 55)
local PALE_GOLD = Color3.fromRGB(255, 220, 120)
local WARM_DARK = Color3.fromRGB(28, 22, 14)
local VEIL_BRONZE = Color3.fromRGB(35, 26, 12)

local function clockText(seconds: number): string
	local minutes = math.floor(seconds / 60)
	local rest = seconds - minutes * 60
	return string.format("%d:%04.1f", minutes, rest)
end

local function paintLabel(parent: Instance, name: string, text: string, size: number, position: UDim2, anchor: Vector2): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Text = text
	label.Font = Enum.Font.GothamBold
	label.TextSize = size
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.BackgroundTransparency = 1
	label.TextStrokeTransparency = 0.4
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.Size = UDim2.new(0, 420, 0, size + 12)
	label.Position = position
	label.AnchorPoint = anchor
	label.Parent = parent
	return label
end

-- A thin golden rule: the quiet divider between a title and the words
-- beneath it, on both the opening and the finish screens.
local function goldRule(parent: Instance, y: number)
	local rule = Instance.new("Frame")
	rule.Name = "GoldRule"
	rule.Size = UDim2.new(0, 140, 0, 3)
	rule.Position = UDim2.new(0.5, -70, 0, y)
	rule.BackgroundColor3 = DEEP_GOLD
	rule.BorderSizePixel = 0
	rule.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 2)
	corner.Parent = rule
	return rule
end

-- A big golden pill button with dark lettering: the PLAY button on the
-- opening screen and PLAY AGAIN on the finish screen.
local function goldButton(parent: Instance, name: string, text: string, y: number): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.Text = text
	button.Font = Enum.Font.GothamBlack
	button.TextSize = 30
	button.TextColor3 = Color3.fromRGB(30, 22, 10)
	button.BackgroundColor3 = DEEP_GOLD
	button.Size = UDim2.new(0, 300, 0, 68)
	button.Position = UDim2.new(0.5, -150, 0, y)
	button.BorderSizePixel = 0
	button.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 34)
	corner.Parent = button
	local sheen = Instance.new("UIStroke")
	sheen.Color = PALE_GOLD
	sheen.Thickness = 2
	sheen.Parent = button
	return button
end

local screen = Instance.new("ScreenGui")
screen.Name = "SkyTowerHud"
screen.ResetOnSpawn = false
screen.Parent = playerGui

-- The climb HUD, all in one frame so the opening screen can hide it
-- with a single switch. It starts hidden: the opening screen owns the
-- screen until PLAY is pressed.
local hudFrame = Instance.new("Frame")
hudFrame.Name = "HudGroup"
hudFrame.Size = UDim2.new(1, 0, 1, 0)
hudFrame.BackgroundTransparency = 1
hudFrame.Visible = false
hudFrame.Parent = screen

-- The game's name and its goal, top center where the eye lands first.
-- Gold on the warm world, once only: this is the only title in the HUD.
paintLabel(hudFrame, "Title", TowerTuning.TEXT.title, 40, UDim2.new(0.5, 0, 0, 8), Vector2.new(0.5, 0))
local titleLabel = hudFrame:FindFirstChild("Title") :: TextLabel
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextColor3 = RICH_GOLD
paintLabel(hudFrame, "Subtitle", TowerTuning.TEXT.subtitle, 20, UDim2.new(0.5, 0, 0, 58), Vector2.new(0.5, 0))

-- A slim golden bar under the subtitle: it fills as the climber rises,
-- so one glance shows how far up the tower they are.
local progressBack = Instance.new("Frame")
progressBack.Name = "ProgressBack"
progressBack.Size = UDim2.new(0, 300, 0, 10)
progressBack.Position = UDim2.new(0.5, 0, 0, 96)
progressBack.AnchorPoint = Vector2.new(0.5, 0)
progressBack.BackgroundColor3 = WARM_DARK
progressBack.BackgroundTransparency = 0.3
progressBack.BorderSizePixel = 0
progressBack.Parent = hudFrame
local progressBackCorner = Instance.new("UICorner")
progressBackCorner.CornerRadius = UDim.new(0, 5)
progressBackCorner.Parent = progressBack

local progressFill = Instance.new("Frame")
progressFill.Name = "ProgressFill"
progressFill.Size = UDim2.new(1 / 12, 0, 1, 0)
progressFill.BackgroundColor3 = DEEP_GOLD
progressFill.BorderSizePixel = 0
progressFill.Parent = progressBack
local progressFillCorner = Instance.new("UICorner")
progressFillCorner.CornerRadius = UDim.new(0, 5)
progressFillCorner.Parent = progressFill

-- Stage, timer and deaths, stacked top right in one tidy column. The
-- stage number is gold so it reads as part of the tower, not the clock.
local stageLabel = paintLabel(hudFrame, "Stage", "Stage 1 / 12", 26, UDim2.new(1, -16, 0, 8), Vector2.new(1, 0))
stageLabel.TextXAlignment = Enum.TextXAlignment.Right
stageLabel.TextColor3 = RICH_GOLD
local timerLabel = paintLabel(hudFrame, "Timer", "0:00.0", 26, UDim2.new(1, -16, 0, 44), Vector2.new(1, 0))
timerLabel.TextXAlignment = Enum.TextXAlignment.Right
local deathsLabel = paintLabel(hudFrame, "Deaths", "Deaths: 0", 22, UDim2.new(1, -16, 0, 80), Vector2.new(1, 0))
deathsLabel.TextXAlignment = Enum.TextXAlignment.Right
deathsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)

-- One big center message for checkpoints and falls; it fades away.
local messageLabel = paintLabel(hudFrame, "Message", "", 34, UDim2.new(0.5, 0, 0.35, 0), Vector2.new(0.5, 0))
messageLabel.Font = Enum.Font.GothamBlack

local messageUntil = 0
local function showMessage(text: string, seconds: number)
	messageLabel.Text = text
	messageUntil = os.clock() + seconds
end

-- The opening screen: a warm bronze veil over the glowing tower, and
-- the game's name in white marble letters with gold inlay, a golden
-- rule, the goal in one line, and one big golden PLAY button.
local startScreen = Instance.new("Frame")
startScreen.Name = "StartScreen"
startScreen.Size = UDim2.new(1, 0, 1, 0)
startScreen.BackgroundColor3 = VEIL_BRONZE
startScreen.BackgroundTransparency = 0.35
startScreen.BorderSizePixel = 0
startScreen.Parent = screen

local startColumn = Instance.new("Frame")
startColumn.Name = "StartColumn"
startColumn.Size = UDim2.new(0, 640, 0, 460)
startColumn.Position = UDim2.new(0.5, 0, 0.5, 0)
startColumn.AnchorPoint = Vector2.new(0.5, 0.5)
startColumn.BackgroundTransparency = 1
startColumn.Parent = startScreen

local startTag = paintLabel(startColumn, "StartTag", "CLIMB 12 STAGES  •  REACH THE GOLD", 18, UDim2.new(0.5, 0, 0, 0), Vector2.new(0.5, 0))
startTag.TextColor3 = DEEP_GOLD
startTag.Size = UDim2.new(1, 0, 0, 30)
local startTitle1 = paintLabel(startColumn, "StartTitle1", "SKY TOWER", 64, UDim2.new(0.5, 0, 0, 30), Vector2.new(0.5, 0))
startTitle1.Font = Enum.Font.GothamBlack
startTitle1.TextStrokeTransparency = 1
startTitle1.Size = UDim2.new(1, 0, 0, 76)
local startTitle1Stroke = Instance.new("UIStroke")
startTitle1Stroke.Color = DEEP_GOLD
startTitle1Stroke.Thickness = 2
startTitle1Stroke.Parent = startTitle1
local startTitle2 = paintLabel(startColumn, "StartTitle2", "OBBY", 64, UDim2.new(0.5, 0, 0, 104), Vector2.new(0.5, 0))
startTitle2.Font = Enum.Font.GothamBlack
startTitle2.TextStrokeTransparency = 1
startTitle2.Size = UDim2.new(1, 0, 0, 76)
local startTitle2Stroke = Instance.new("UIStroke")
startTitle2Stroke.Color = DEEP_GOLD
startTitle2Stroke.Thickness = 2
startTitle2Stroke.Parent = startTitle2
goldRule(startColumn, 196)
local startSub = paintLabel(startColumn, "StartSub", TowerTuning.TEXT.subtitle, 20, UDim2.new(0.5, 0, 0, 210), Vector2.new(0.5, 0))
startSub.Size = UDim2.new(1, 0, 0, 32)
local playButton = goldButton(startColumn, "PlayButton", "PLAY", 256)
local startControls = paintLabel(startColumn, "StartControls", "WASD / stick to move  •  Space / A / tap to jump", 16, UDim2.new(0.5, 0, 0, 340), Vector2.new(0.5, 0))
startControls.Size = UDim2.new(1, 0, 0, 28)
startControls.TextColor3 = Color3.fromRGB(230, 220, 200)

-- The finish screen: the same warm veil and marble-and-gold voice as
-- the opening screen. The crown is theirs: the time, the deaths, the
-- session best, and a golden PLAY AGAIN button.
local finishScreen = Instance.new("Frame")
finishScreen.Name = "FinishScreen"
finishScreen.Size = UDim2.new(1, 0, 1, 0)
finishScreen.BackgroundColor3 = VEIL_BRONZE
finishScreen.BackgroundTransparency = 0.35
finishScreen.BorderSizePixel = 0
finishScreen.Visible = false
finishScreen.Parent = screen

local finishColumn = Instance.new("Frame")
finishColumn.Name = "FinishColumn"
finishColumn.Size = UDim2.new(0, 640, 0, 440)
finishColumn.Position = UDim2.new(0.5, 0, 0.5, 0)
finishColumn.AnchorPoint = Vector2.new(0.5, 0.5)
finishColumn.BackgroundTransparency = 1
finishColumn.Parent = finishScreen

local finishTag = paintLabel(finishColumn, "FinishTag", "THE CROWN IS YOURS", 18, UDim2.new(0.5, 0, 0, 0), Vector2.new(0.5, 0))
finishTag.TextColor3 = DEEP_GOLD
finishTag.Size = UDim2.new(1, 0, 0, 30)
local finishTitle = paintLabel(finishColumn, "FinishTitle", TowerTuning.TEXT.win, 64, UDim2.new(0.5, 0, 0, 30), Vector2.new(0.5, 0))
finishTitle.Font = Enum.Font.GothamBlack
finishTitle.TextColor3 = RICH_GOLD
finishTitle.Size = UDim2.new(1, 0, 0, 76)
goldRule(finishColumn, 122)
local finishStats = paintLabel(finishColumn, "FinishStats", "", 26, UDim2.new(0.5, 0, 0, 136), Vector2.new(0.5, 0))
finishStats.Size = UDim2.new(1, 0, 0, 38)
local finishBest = paintLabel(finishColumn, "FinishBest", "", 18, UDim2.new(0.5, 0, 0, 174), Vector2.new(0.5, 0))
finishBest.TextColor3 = DEEP_GOLD
finishBest.Size = UDim2.new(1, 0, 0, 30)
local playAgainButton = goldButton(finishColumn, "PlayAgainButton", "PLAY AGAIN", 220)

-- Little golden squares that rain over the whole finish screen when
-- the climber wins, then tidy themselves away.
local function finishConfetti()
	for _ = 1, 32 do
		local bit = Instance.new("Frame")
		bit.Name = "FinishConfettiBit"
		bit.Size = UDim2.new(0, 10, 0, 10)
		bit.Position = UDim2.new(math.random(), 0, 0, -12)
		bit.BackgroundColor3 = CROWN_CONFETTI[math.random(#CROWN_CONFETTI)]
		bit.BorderSizePixel = 0
		bit.Parent = finishScreen
		local bitCorner = Instance.new("UICorner")
		bitCorner.CornerRadius = UDim.new(0, 3)
		bitCorner.Parent = bit
		local fall = TweenService:Create(
			bit,
			TweenInfo.new(math.random(12, 20) / 10, Enum.EasingStyle.Linear),
			{ Position = UDim2.new(bit.Position.X.Scale, 0, 1, 0) }
		)
		fall:Play()
		fall.Completed:Connect(function()
			bit:Destroy()
		end)
	end
end

-- The climb has not started until PLAY is pressed: the clock stands
-- still, and the HUD stays hidden behind the opening screen.
local started = false
local won = false
local deaths = 0
local bestTime: number? = nil
local attemptStart = os.clock()

task.spawn(function()
	while true do
		task.wait(TowerTuning.TIMER_TICK)
		if started and not won then
			timerLabel.Text = clockText(os.clock() - attemptStart)
		end
		if messageLabel.Text ~= "" and os.clock() > messageUntil then
			messageLabel.Text = ""
		end
	end
end)

playButton.MouseButton1Click:Connect(function()
	startScreen.Visible = false
	hudFrame.Visible = true
	started = true
	attemptStart = os.clock()
	timerLabel.Text = "0:00.0"
end)

checkpointEvent.OnClientEvent:Connect(function(stageIndex: number)
	stageLabel.Text = "Stage " .. tostring(stageIndex) .. " / 12"
	progressFill.Size = UDim2.new(stageIndex / 12, 0, 1, 0)
	showMessage(TowerTuning.TEXT.checkpoint .. " Stage " .. tostring(stageIndex), 2)
end)

winEvent.OnClientEvent:Connect(function(climbTime: number, deathCount: number, sessionBest: number?)
	won = true
	deaths = deathCount
	if sessionBest ~= nil then
		bestTime = sessionBest
	end
	deathsLabel.Text = "Deaths: " .. tostring(deaths)
	finishStats.Text = "TIME " .. clockText(climbTime) .. "   •   DEATHS " .. tostring(deathCount)
	if bestTime ~= nil then
		finishBest.Text = "BEST TIME " .. clockText(bestTime :: number)
	else
		finishBest.Text = "BEST TIME --:--"
	end
	hudFrame.Visible = false
	finishScreen.Visible = true
	finishConfetti()
end)

playAgainButton.MouseButton1Click:Connect(function()
	resetEvent:FireServer()
	won = false
	deaths = 0
	deathsLabel.Text = "Deaths: 0"
	stageLabel.Text = "Stage 1 / 12"
	progressFill.Size = UDim2.new(1 / 12, 0, 1, 0)
	attemptStart = os.clock()
	timerLabel.Text = "0:00.0"
	-- A leftover checkpoint or fall message must not survive into the
	-- fresh attempt, or it would sit over the new climb for seconds.
	messageLabel.Text = ""
	messageUntil = 0
	finishScreen.Visible = false
	hudFrame.Visible = true
end)
