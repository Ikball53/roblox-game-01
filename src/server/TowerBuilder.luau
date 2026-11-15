-- TowerBuilder: turns the TowerLayout plan into real parts.
-- One job: build the tower. It returns the parts the main script has
-- to wire up (checkpoints, kill bars, the win pad, the return pad).
-- Everything added here is visual: glow trims under the platforms,
-- floating stars, a title sign, a win beacon and win confetti. None
-- of it can collide with a player or change a jump.

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TowerLayout = require(ReplicatedStorage:WaitForChild("TowerLayout"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local TowerBuilder = {}

-- The bright confetti colors that burst when someone reaches the top.
local CONFETTI_COLORS = {
	Color3.fromRGB(255, 214, 64),
	Color3.fromRGB(255, 92, 138),
	Color3.fromRGB(80, 200, 255),
	Color3.fromRGB(120, 255, 110),
	Color3.fromRGB(190, 120, 255),
	Color3.fromRGB(255, 255, 255),
}

local function makePart(name: string, size: Vector3, position: Vector3, color: Color3, material: Enum.Material): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = CFrame.new(position)
	part.Anchored = true
	part.CanCollide = true
	part.Color = color
	part.Material = material
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

-- A thin neon slab under a platform, slightly wider than the platform
-- itself, so every step looks like it floats on light. It sits below
-- the walking surface and never collides, so feet never clip into it.
local function addGlowTrim(spec, parent: Instance)
	local trim = Instance.new("Part")
	trim.Name = "GlowTrim"
	trim.Size = Vector3.new(spec.size.X + 0.3, 0.18, spec.size.Z + 0.3)
	trim.CFrame = CFrame.new(spec.position + Vector3.new(0, -spec.size.Y / 2 - 0.09, 0))
	trim.Anchored = true
	trim.CanCollide = false
	trim.Color = spec.color
	trim.Material = Enum.Material.Neon
	trim.Transparency = 0.15
	trim.TopSurface = Enum.SurfaceType.Smooth
	trim.BottomSurface = Enum.SurfaceType.Smooth
	trim.Parent = parent
	return trim
end

-- A normal platform: a solid step of the spiral, with its glow trim.
function TowerBuilder.buildPlatform(spec, parent: Instance): Part
	local part = makePart("Platform", spec.size, spec.position, spec.color, spec.material or Enum.Material.SmoothPlastic)
	part.Parent = parent
	addGlowTrim(spec, parent)
	return part
end

-- A platform that slides back and forth along the tower's ring, so the
-- player has to time the jump. TweenService loops it forever. No glow
-- trim here on purpose: a static trim cannot follow the tween, and the
-- platform is already neon, so it glows on its own.
function TowerBuilder.buildMovingPlatform(spec, parent: Instance): Part
	local part = makePart("MovingPlatform", spec.size, spec.position, spec.color, Enum.Material.Neon)
	part.Parent = parent
	local home = part.CFrame
	local tangent = Vector3.new(-spec.position.Z, 0, spec.position.X).Unit * GameConfig.MOVE_DISTANCE
	local goal = { CFrame = home + tangent }
	local tween = TweenService:Create(
		part,
		TweenInfo.new(GameConfig.MOVE_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		goal
	)
	tween:Play()
	return part
end

-- A red bar across a gap. It does not block: it kills whoever brushes it.
function TowerBuilder.buildKillBar(spec, parent: Instance): Part
	local part = makePart("KillBar", spec.size, spec.position, spec.color, Enum.Material.Neon)
	part.CanCollide = false
	part.Parent = parent
	return part
end

-- The green pad that starts a stage. Touching it saves the climb so far.
function TowerBuilder.buildCheckpointPad(stageIndex: number, position: Vector3, parent: Instance): Part
	local part = makePart("Checkpoint" .. tostring(stageIndex), Vector3.new(9, 1, 9), position, TowerLayout.CHECKPOINT_COLOR, Enum.Material.Neon)
	part.Parent = parent
	addGlowTrim({ size = Vector3.new(9, 1, 9), position = position, color = TowerLayout.CHECKPOINT_COLOR }, parent)
	return part
end

-- The golden pad on top of the column: the finish line, with a warm
-- light so the top of the tower glows from below.
function TowerBuilder.buildWinPad(parent: Instance): Part
	local part = makePart("WinPad", Vector3.new(10, 1, 10), TowerLayout.winPadPosition(), TowerLayout.WIN_COLOR, Enum.Material.Neon)
	part.Parent = parent
	local light = Instance.new("PointLight")
	light.Color = TowerLayout.WIN_COLOR
	light.Range = 24
	light.Brightness = 2
	light.Parent = part
	return part
end

-- The cyan pad on the ground that carries a fallen player back to
-- their checkpoint, so a fall costs time, not the whole climb.
function TowerBuilder.buildReturnPad(parent: Instance): Part
	local part = makePart("ReturnPad", Vector3.new(8, 1, 8), TowerLayout.returnPadPosition(), Color3.fromRGB(0, 200, 255), Enum.Material.Neon)
	part.Parent = parent
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(0, 200, 255)
	light.Range = 12
	light.Brightness = 1.5
	light.Parent = part
	return part
end

-- Floating stars that sparkle beside the tower, one set per stage.
-- They slowly spin in place and can never be touched: pure decoration.
function TowerBuilder.buildDecorStars(parent: Instance)
	for stageIndex = 1, TowerLayout.STAGE_COUNT do
		for starIndex = 1, GameConfig.DECOR.starsPerStage do
			local position = TowerLayout.decorStarPosition(stageIndex, starIndex)
			local star = Instance.new("Part")
			star.Name = "DecorStar"
			star.Size = Vector3.new(1.4, 1.4, 1.4)
			star.CFrame = CFrame.new(position)
			star.Anchored = true
			star.CanCollide = false
			star.Color = TowerLayout.decorStarColor(stageIndex, starIndex)
			star.Material = Enum.Material.Neon
			star.TopSurface = Enum.SurfaceType.Smooth
			star.BottomSurface = Enum.SurfaceType.Smooth
			star.Parent = parent
			local spin = TweenService:Create(
				star,
				TweenInfo.new(GameConfig.DECOR.starSpinTime, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true),
				{ CFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(180), 0) }
			)
			spin:Play()
		end
	end
end

-- A big floating title sign above the spawn pad. A BillboardGui always
-- faces the camera, so it reads from anywhere on the ground.
function TowerBuilder.buildTitleSign(parent: Instance)
	local anchor = Instance.new("Part")
	anchor.Name = "TitleSignAnchor"
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.CFrame = CFrame.new(TowerLayout.titleSignPosition())
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.Transparency = 1
	anchor.Parent = parent

	local board = Instance.new("BillboardGui")
	board.Name = "TitleSign"
	board.Size = UDim2.new(0, 520, 0, 150)
	board.LightInfluence = 0
	board.MaxDistance = 200
	board.Parent = anchor

	local title = Instance.new("TextLabel")
	title.Name = "SignTitle"
	title.Text = GameConfig.TEXT.title
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 52
	title.TextColor3 = Color3.fromRGB(241, 196, 15)
	title.TextStrokeTransparency = 0.2
	title.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 70)
	title.Position = UDim2.new(0, 0, 0, 10)
	title.Parent = board

	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "SignSubtitle"
	subtitle.Text = GameConfig.TEXT.subtitle
	subtitle.Font = Enum.Font.GothamBold
	subtitle.TextSize = 22
	subtitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	subtitle.TextStrokeTransparency = 0.2
	subtitle.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	subtitle.BackgroundTransparency = 1
	subtitle.Size = UDim2.new(1, 0, 0, 32)
	subtitle.Position = UDim2.new(0, 0, 0, 84)
	subtitle.Parent = board
end

-- A tall golden beam of light rising from the win pad, so the finish
-- line is visible from the ground before the climb even starts.
function TowerBuilder.buildWinBeacon(parent: Instance)
	local top = TowerLayout.winPadPosition()
	local beam = Instance.new("Part")
	beam.Name = "WinBeacon"
	beam.Size = Vector3.new(2.5, 100, 2.5)
	beam.CFrame = CFrame.new(top + Vector3.new(0, 50.5, 0))
	beam.Anchored = true
	beam.CanCollide = false
	beam.Color = TowerLayout.WIN_COLOR
	beam.Material = Enum.Material.Neon
	beam.Transparency = 0.4
	beam.TopSurface = Enum.SurfaceType.Smooth
	beam.BottomSurface = Enum.SurfaceType.Smooth
	beam.Parent = parent
end

-- A burst of bright confetti over the win pad when someone finishes.
-- The pieces are tiny, never collide, and clean themselves up after
-- a few seconds, so a win never leaves clutter behind.
function TowerBuilder.celebrateWin(position: Vector3)
	local workspace = game:GetService("Workspace")
	for _ = 1, GameConfig.DECOR.confettiPieces do
		local piece = Instance.new("Part")
		piece.Name = "WinConfetti"
		piece.Size = Vector3.new(0.7, 0.7, 0.15)
		piece.Color = CONFETTI_COLORS[math.random(#CONFETTI_COLORS)]
		piece.Material = Enum.Material.Neon
		piece.Anchored = false
		piece.CanCollide = false
		piece.CFrame = CFrame.new(position + Vector3.new(math.random(-6, 6), math.random(2, 8), math.random(-6, 6)))
		piece.AssemblyLinearVelocity = Vector3.new(math.random(-12, 12), math.random(18, 38), math.random(-12, 12))
		piece.Parent = workspace
		Debris:AddItem(piece, GameConfig.DECOR.confettiLifetime)
	end
end

-- Builds every stage of the tower into a folder in Workspace and hands
-- back the parts the game logic needs to watch.
function TowerBuilder.buildTower(workspace: Workspace)
	local folder = Instance.new("Folder")
	folder.Name = "SkyTower"
	folder.Parent = workspace

	local checkpoints = {}
	local killBars = {}

	for stageIndex = 1, TowerLayout.STAGE_COUNT do
		local plan = TowerLayout.stagePlan(stageIndex)
		for _, spec in ipairs(plan.platforms) do
			if spec.kind == "checkpoint" then
				local pad = TowerBuilder.buildCheckpointPad(stageIndex, spec.position, folder)
				checkpoints[stageIndex] = pad
			elseif spec.kind == "moving" then
				TowerBuilder.buildMovingPlatform(spec, folder)
			else
				TowerBuilder.buildPlatform(spec, folder)
			end
		end
		for _, bar in ipairs(plan.killBars) do
			table.insert(killBars, TowerBuilder.buildKillBar(bar, folder))
		end
	end

	local winPad = TowerBuilder.buildWinPad(folder)
	local returnPad = TowerBuilder.buildReturnPad(folder)
	TowerBuilder.buildDecorStars(folder)
	TowerBuilder.buildTitleSign(folder)
	TowerBuilder.buildWinBeacon(folder)

	return {
		checkpoints = checkpoints,
		killBars = killBars,
		winPad = winPad,
		returnPad = returnPad,
	}
end

return TowerBuilder
