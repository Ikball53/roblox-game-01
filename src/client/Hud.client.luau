-- Hud: the client half of Sky Tower Obby.
-- Builds the whole screen interface in code: the title, the stage, the
-- timer and the death count, plus a stage progress bar and the win
-- screen. Everything sits clear of the top-left corner, where Roblox
-- puts its own menu.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local checkpointEvent = ReplicatedStorage:WaitForChild("TowerCheckpoint")
local winEvent = ReplicatedStorage:WaitForChild("TowerWin")
local resetEvent = ReplicatedStorage:WaitForChild("TowerReset")

-- The bright colors of the little confetti pieces on the win screen.
local CONFETTI_COLORS = {
	Color3.fromRGB(255, 214, 64),
	Color3.fromRGB(255, 92, 138),
	Color3.fromRGB(80, 200, 255),
	Color3.fromRGB(120, 255, 110),
	Color3.fromRGB(190, 120, 255),
	Color3.fromRGB(255, 255, 255),
}

local function formatTime(seconds: number): string
	local minutes = math.floor(seconds / 60)
	local rest = seconds - minutes * 60
	return string.format("%d:%04.1f", minutes, rest)
end

local function makeLabel(parent: Instance, name: string, text: string, size: number, position: UDim2, anchor: Vector2): TextLabel
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

local screen = Instance.new("ScreenGui")
screen.Name = "SkyTowerHud"
screen.ResetOnSpawn = false
screen.Parent = playerGui

-- Title and goal, top center where the eye lands first. The title is
-- gold now, so it reads as the game's name, not just another label.
makeLabel(screen, "Title", GameConfig.TEXT.title, 40, UDim2.new(0.5, 0, 0, 8), Vector2.new(0.5, 0))
local titleLabel = screen:FindFirstChild("Title") :: TextLabel
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextColor3 = Color3.fromRGB(241, 196, 15)
makeLabel(screen, "Subtitle", GameConfig.TEXT.subtitle, 20, UDim2.new(0.5, 0, 0, 58), Vector2.new(0.5, 0))

-- A slim progress bar under the subtitle: it fills as the player
-- climbs, so one glance shows how far up the tower they are.
local progressBack = Instance.new("Frame")
progressBack.Name = "ProgressBack"
progressBack.Size = UDim2.new(0, 300, 0, 10)
progressBack.Position = UDim2.new(0.5, 0, 0, 96)
progressBack.AnchorPoint = Vector2.new(0.5, 0)
progressBack.BackgroundColor3 = Color3.fromRGB(20, 24, 40)
progressBack.BackgroundTransparency = 0.3
progressBack.BorderSizePixel = 0
progressBack.Parent = screen
local progressBackCorner = Instance.new("UICorner")
progressBackCorner.CornerRadius = UDim.new(0, 5)
progressBackCorner.Parent = progressBack

local progressFill = Instance.new("Frame")
progressFill.Name = "ProgressFill"
progressFill.Size = UDim2.new(1 / 12, 0, 1, 0)
progressFill.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
progressFill.BorderSizePixel = 0
progressFill.Parent = progressBack
local progressFillCorner = Instance.new("UICorner")
progressFillCorner.CornerRadius = UDim.new(0, 5)
progressFillCorner.Parent = progressFill

-- Stage, timer and deaths, stacked top right. The stage number is
-- cyan so it stands apart from the white timer below it.
local stageLabel = makeLabel(screen, "Stage", "Stage 1 / 12", 26, UDim2.new(1, -16, 0, 8), Vector2.new(1, 0))
stageLabel.TextXAlignment = Enum.TextXAlignment.Right
stageLabel.TextColor3 = Color3.fromRGB(80, 200, 255)
local timerLabel = makeLabel(screen, "Timer", "0:00.0", 26, UDim2.new(1, -16, 0, 44), Vector2.new(1, 0))
timerLabel.TextXAlignment = Enum.TextXAlignment.Right
local deathsLabel = makeLabel(screen, "Deaths", "Deaths: 0", 22, UDim2.new(1, -16, 0, 80), Vector2.new(1, 0))
deathsLabel.TextXAlignment = Enum.TextXAlignment.Right
deathsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)

-- Big center message for checkpoints and falls; it fades on its own.
local messageLabel = makeLabel(screen, "Message", "", 34, UDim2.new(0.5, 0, 0.35, 0), Vector2.new(0.5, 0))
messageLabel.Font = Enum.Font.GothamBlack

local messageUntil = 0
local function showMessage(text: string, seconds: number)
	messageLabel.Text = text
	messageUntil = os.clock() + seconds
end

-- The win screen: hidden until the gold pad is touched. Bigger than
-- before, with a gold outline, so the win feels like a win.
local winFrame = Instance.new("Frame")
winFrame.Name = "WinScreen"
winFrame.Size = UDim2.new(0, 520, 0, 300)
winFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
winFrame.AnchorPoint = Vector2.new(0.5, 0.5)
winFrame.BackgroundColor3 = Color3.fromRGB(20, 24, 40)
winFrame.BackgroundTransparency = 0.1
winFrame.BorderSizePixel = 0
winFrame.Visible = false
winFrame.Parent = screen
local winCorner = Instance.new("UICorner")
winCorner.CornerRadius = UDim.new(0, 16)
winCorner.Parent = winFrame
local winStroke = Instance.new("UIStroke")
winStroke.Color = Color3.fromRGB(241, 196, 15)
winStroke.Thickness = 3
winStroke.Parent = winFrame

local winTitle = makeLabel(winFrame, "WinTitle", GameConfig.TEXT.win, 52, UDim2.new(0.5, 0, 0, 16), Vector2.new(0.5, 0))
winTitle.Font = Enum.Font.GothamBlack
winTitle.TextColor3 = Color3.fromRGB(241, 196, 15)
local winSub = makeLabel(winFrame, "WinSub", GameConfig.TEXT.winSub, 22, UDim2.new(0.5, 0, 0, 88), Vector2.new(0.5, 0))
winSub.TextColor3 = Color3.fromRGB(255, 255, 255)
local winStats = makeLabel(winFrame, "WinStats", "", 24, UDim2.new(0.5, 0, 0, 126), Vector2.new(0.5, 0))

local playAgain = Instance.new("TextButton")
playAgain.Name = "PlayAgain"
playAgain.Text = GameConfig.TEXT.winAgain
playAgain.Font = Enum.Font.GothamBold
playAgain.TextSize = 26
playAgain.TextColor3 = Color3.fromRGB(255, 255, 255)
playAgain.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
playAgain.Size = UDim2.new(0, 220, 0, 56)
playAgain.Position = UDim2.new(0.5, 0, 0, 200)
playAgain.AnchorPoint = Vector2.new(0.5, 0)
playAgain.Parent = winFrame
local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 12)
buttonCorner.Parent = playAgain

-- Little colored squares that rain down the win screen when the
-- player finishes, then clean themselves up.
local function winConfetti()
	for _ = 1, 24 do
		local bit = Instance.new("Frame")
		bit.Name = "WinConfettiBit"
		bit.Size = UDim2.new(0, 10, 0, 10)
		bit.Position = UDim2.new(math.random(), 0, 0, -12)
		bit.BackgroundColor3 = CONFETTI_COLORS[math.random(#CONFETTI_COLORS)]
		bit.BorderSizePixel = 0
		bit.Parent = winFrame
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

-- The attempt clock: it runs from when this screen loads, and stops
-- on the win screen, where the server's own time is shown instead.
local attemptStart = os.clock()
local won = false
local deaths = 0

task.spawn(function()
	while true do
		task.wait(GameConfig.TIMER_TICK)
		if not won then
			timerLabel.Text = formatTime(os.clock() - attemptStart)
		end
		if messageLabel.Text ~= "" and os.clock() > messageUntil then
			messageLabel.Text = ""
		end
	end
end)

checkpointEvent.OnClientEvent:Connect(function(stageIndex: number)
	stageLabel.Text = "Stage " .. tostring(stageIndex) .. " / 12"
	progressFill.Size = UDim2.new(stageIndex / 12, 0, 1, 0)
	showMessage(GameConfig.TEXT.checkpoint .. " Stage " .. tostring(stageIndex), 2)
end)

winEvent.OnClientEvent:Connect(function(climbTime: number, deathCount: number)
	won = true
	deaths = deathCount
	deathsLabel.Text = "Deaths: " .. tostring(deaths)
	winStats.Text = "Time: " .. formatTime(climbTime) .. "   Deaths: " .. tostring(deathCount)
	winFrame.Visible = true
	winConfetti()
end)

playAgain.MouseButton1Click:Connect(function()
	resetEvent:FireServer()
	won = false
	deaths = 0
	deathsLabel.Text = "Deaths: 0"
	stageLabel.Text = "Stage 1 / 12"
	progressFill.Size = UDim2.new(1 / 12, 0, 1, 0)
	attemptStart = os.clock()
	-- A leftover checkpoint or fall message must not survive into the
	-- fresh attempt, or it would sit over the new climb for seconds.
	messageLabel.Text = ""
	messageUntil = 0
	winFrame.Visible = false
end)
