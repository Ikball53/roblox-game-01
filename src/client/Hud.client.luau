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

-- The climb HUD is a slim strip across the top of the screen, nothing
-- more. It is deliberately NOT full-screen: the old full-screen frame
-- swallowed every drag and pinch, which left the player unable to turn
-- the camera or zoom in — the lens sat far away and could not be
-- pulled closer. With only this strip and the small stats column on
-- the right, a finger anywhere else reaches the camera directly.
-- Every piece here is also marked inactive, so the HUD never claims a
-- touch. The strip starts hidden: the opening screen owns the screen
-- until PLAY is pressed.
local hudTop = Instance.new("Frame")
hudTop.Name = "HudTop"
hudTop.Size = UDim2.new(1, 0, 0, 104)
hudTop.BackgroundTransparency = 1
hudTop.Active = false
hudTop.Visible = false
hudTop.Parent = screen

-- The game's name, shrunk to one small gold line: the big title lives
-- only on the opening screen. During the climb it stays out of the
-- way, small above the progress bar and nowhere else. The subtitle is
-- gone from the climb entirely — it already said its piece on the
-- opening screen.
local hudTitle = paintLabel(hudTop, "HudTitle", TowerTuning.TEXT.title, 16, UDim2.new(0.5, 0, 0, 6), Vector2.new(0.5, 0))
hudTitle.Font = Enum.Font.GothamBlack
hudTitle.TextColor3 = RICH_GOLD
hudTitle.Active = false

-- A slim golden bar under the small title: it fills as the climber
-- rises, so one glance shows how far up the tower they are.
local progressBack = Instance.new("Frame")
progressBack.Name = "ProgressBack"
progressBack.Size = UDim2.new(0, 220, 0, 8)
progressBack.Position = UDim2.new(0.5, 0, 0, 40)
progressBack.AnchorPoint = Vector2.new(0.5, 0)
progressBack.BackgroundColor3 = WARM_DARK
progressBack.BackgroundTransparency = 0.3
progressBack.BorderSizePixel = 0
progressBack.Active = false
progressBack.Parent = hudTop
local progressBackCorner = Instance.new("UICorner")
progressBackCorner.CornerRadius = UDim.new(0, 5)
progressBackCorner.Parent = progressBack

local progressFill = Instance.new("Frame")
progressFill.Name = "ProgressFill"
progressFill.Size = UDim2.new(1 / 12, 0, 1, 0)
progressFill.BackgroundColor3 = DEEP_GOLD
progressFill.BorderSizePixel = 0
progressFill.Active = false
progressFill.Parent = progressBack
local progressFillCorner = Instance.new("UICorner")
progressFillCorner.CornerRadius = UDim.new(0, 5)
progressFillCorner.Parent = progressFill

-- Stage, timer and deaths, stacked top right in one tidy column. The
-- stage number is gold so it reads as part of the tower, not the clock.
-- All three are marked inactive like the rest of the strip.
local stageLabel = paintLabel(hudTop, "Stage", "Stage 1 / 12", 24, UDim2.new(1, -16, 0, 4), Vector2.new(1, 0))
stageLabel.TextXAlignment = Enum.TextXAlignment.Right
stageLabel.TextColor3 = RICH_GOLD
stageLabel.Active = false
local timerLabel = paintLabel(hudTop, "Timer", "0:00.0", 24, UDim2.new(1, -16, 0, 38), Vector2.new(1, 0))
timerLabel.TextXAlignment = Enum.TextXAlignment.Right
timerLabel.Active = false
local deathsLabel = paintLabel(hudTop, "Deaths", "Deaths: 0", 20, UDim2.new(1, -16, 0, 70), Vector2.new(1, 0))
deathsLabel.TextXAlignment = Enum.TextXAlignment.Right
deathsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
deathsLabel.Active = false

-- One big center message for checkpoints and falls; it fades away. It
-- hangs straight off the screen instead of the HUD strip, so it is
-- one small box in the middle of the screen and never a sheet over it.
local messageLabel = paintLabel(screen, "Message", "", 34, UDim2.new(0.5, 0, 0.35, 0), Vector2.new(0.5, 0))
messageLabel.Font = Enum.Font.GothamBlack
messageLabel.Active = false

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

-- The camera, settled close to the climber. The default lens starts
-- far away, and with the old full-screen HUD eating every touch the
-- player could not drag it closer or pinch it in. Two guards fix it:
-- the HUD no longer covers the screen, and PLAY pulls the lens in
-- tight and hands it back to the player in Custom mode with a sane
-- zoom range, so drag and pinch work from the first step.
local CAMERA_NEAR = 14
local CAMERA_CLOSE = 6
local CAMERA_WIDE = 40

local function settleCamera()
	local lens = workspace.CurrentCamera
	if lens == nil then
		return
	end
	lens.CameraType = Enum.CameraType.Custom
	player.CameraMinZoomDistance = CAMERA_CLOSE
	player.CameraMaxZoomDistance = CAMERA_NEAR
	-- Point the lens at a close view behind the climber; the Custom
	-- camera takes over from here and the zoom clamp keeps it near.
	local character = player.Character
	local root = character ~= nil and character:FindFirstChild("HumanoidRootPart") or nil
	if root ~= nil then
		local focus = root.Position
		lens.CFrame = CFrame.lookAt(focus + Vector3.new(0, 4, CAMERA_NEAR), focus + Vector3.new(0, 2, 0))
	end
	-- After a breath, let the player pull out a little further if
	-- they want the whole tower in frame.
	task.delay(1, function()
		player.CameraMaxZoomDistance = CAMERA_WIDE
	end)
end

playButton.MouseButton1Click:Connect(function()
	-- The opening screen is done forever: destroy it, don't just hide
	-- it, so no invisible veil can ever swallow a touch again.
	startScreen:Destroy()
	hudTop.Visible = true
	started = true
	attemptStart = os.clock()
	timerLabel.Text = "0:00.0"
	settleCamera()
end)

-- A fresh spawn gets the same close lens: the camera resets when the
-- character does, so re-settle it a beat after every respawn, and once
-- up front so the tower already sits close behind the opening veil.
player.CharacterAdded:Connect(function()
	task.wait(0.5)
	settleCamera()
end)

settleCamera()

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
	hudTop.Visible = false
	-- A leftover checkpoint or fall message must not survive over the
	-- finish screen.
	messageLabel.Text = ""
	messageUntil = 0
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
	hudTop.Visible = true
	settleCamera()
end)
