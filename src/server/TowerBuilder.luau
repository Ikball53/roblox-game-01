-- GoldenTowerBuilder: turns the GoldenTowerPlan into real parts.
-- One job: raise the tower. It hands back the parts the main script
-- has to watch — the emerald pads, the ruby bars, the crown pad and
-- the pearl return pad. Everything else here is dressing: a thin gold
-- trim under every step, slow golden stars drifting beside the tower,
-- a slim beam of light over the crown, and gold confetti for a win.
-- None of the dressing can collide with a player or change a jump.
-- There is no title sign in the world any more: the HUD alone carries
-- the game's name, so nothing in 3D can ever double it on screen.

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TowerPlan = require(ReplicatedStorage:WaitForChild("TowerLayout"))
local TowerTuning = require(ReplicatedStorage:WaitForChild("GameConfig"))

local GoldenTowerBuilder = {}

-- The gold confetti that rains over the crown when somebody finishes:
-- pure gold, champagne and white. Nothing garish, nothing rainbow.
local CROWN_CONFETTI = {
	Color3.fromRGB(255, 215, 0),
	Color3.fromRGB(240, 210, 150),
	Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(230, 190, 110),
}

local function carvePart(name: string, size: Vector3, position: Vector3, color: Color3, material: Enum.Material): Part
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

-- A thin band of gold beneath a step, a touch wider than the step
-- itself, so every marble slab looks set in a gilded frame. It hangs
-- below the walking surface and never collides, so feet never clip it.
local function addGoldTrim(spec, parent: Instance)
	local trim = Instance.new("Part")
	trim.Name = "GoldTrim"
	trim.Size = Vector3.new(spec.size.X + 0.3, 0.18, spec.size.Z + 0.3)
	trim.CFrame = CFrame.new(spec.position + Vector3.new(0, -spec.size.Y / 2 - 0.09, 0))
	trim.Anchored = true
	trim.CanCollide = false
	trim.Color = Color3.fromRGB(212, 175, 55)
	trim.Material = Enum.Material.Neon
	trim.Transparency = 0.25
	trim.TopSurface = Enum.SurfaceType.Smooth
	trim.BottomSurface = Enum.SurfaceType.Smooth
	trim.Parent = parent
	return trim
end

-- One marble step of the spiral, set in its gold frame.
function GoldenTowerBuilder.buildPlatform(spec, parent: Instance): Part
	local part = carvePart("Platform", spec.size, spec.position, spec.color, spec.material or Enum.Material.Marble)
	part.Parent = parent
	addGoldTrim(spec, parent)
	return part
end

-- A step of solid gold that glides back and forth along the tower's
-- ring, so the climber must time the leap. TweenService loops it
-- forever. No trim here on purpose: a fixed trim cannot follow the
-- tween, and the gold slab glows on its own.
function GoldenTowerBuilder.buildMovingPlatform(spec, parent: Instance): Part
	local part = carvePart("MovingPlatform", spec.size, spec.position, spec.color, Enum.Material.Neon)
	part.Parent = parent
	local home = part.CFrame
	local tangent = Vector3.new(-spec.position.Z, 0, spec.position.X).Unit * TowerTuning.SLIDE_DISTANCE
	local goal = { CFrame = home + tangent }
	local glide = TweenService:Create(
		part,
		TweenInfo.new(TowerTuning.SLIDE_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		goal
	)
	glide:Play()
	return part
end

-- A ruby bar across a gap. It does not block: it ends the attempt of
-- whoever brushes against it.
function GoldenTowerBuilder.buildKillBar(spec, parent: Instance): Part
	local part = carvePart("KillBar", spec.size, spec.position, spec.color, Enum.Material.Neon)
	part.CanCollide = false
	part.Parent = parent
	return part
end

-- The emerald pad that opens a stage. Touching it saves the climb.
function GoldenTowerBuilder.buildCheckpointPad(stageIndex: number, position: Vector3, parent: Instance): Part
	local part = carvePart("Checkpoint" .. tostring(stageIndex), Vector3.new(9, 1, 9), position, TowerPlan.CHECKPOINT_COLOR, Enum.Material.Neon)
	part.Parent = parent
	addGoldTrim({ size = Vector3.new(9, 1, 9), position = position }, parent)
	return part
end

-- The crown pad on top of the column: the finish line, lit from below
-- by a warm light so the top of the tower glows like a lantern.
function GoldenTowerBuilder.buildWinPad(parent: Instance): Part
	local part = carvePart("WinPad", Vector3.new(10, 1, 10), TowerPlan.winPadPosition(), TowerPlan.WIN_COLOR, Enum.Material.Neon)
	part.Parent = parent
	local glow = Instance.new("PointLight")
	glow.Color = TowerPlan.WIN_COLOR
	glow.Range = 24
	glow.Brightness = 2.5
	glow.Parent = part
	return part
end

-- The pearl pad on the ground that carries a fallen climber straight
-- back to their checkpoint, so a fall costs time, not the whole climb.
function GoldenTowerBuilder.buildReturnPad(parent: Instance): Part
	local part = carvePart("ReturnPad", Vector3.new(8, 1, 8), TowerPlan.returnPadPosition(), Color3.fromRGB(245, 240, 228), Enum.Material.Marble)
	part.Parent = parent
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(255, 215, 0)
	glow.Range = 12
	glow.Brightness = 1.5
	glow.Parent = part
	return part
end

-- Golden stars drifting beside the tower, one small set per stage.
-- They turn slowly in place and can never be touched: pure sparkle.
function GoldenTowerBuilder.buildDecorStars(parent: Instance)
	for stageIndex = 1, TowerPlan.STAGE_COUNT do
		for starIndex = 1, TowerTuning.SPARKLE.starsPerStage do
			local position = TowerPlan.decorStarPosition(stageIndex, starIndex)
			local star = Instance.new("Part")
			star.Name = "DecorStar"
			star.Size = Vector3.new(1, 1, 1)
			star.CFrame = CFrame.new(position)
			star.Anchored = true
			star.CanCollide = false
			star.Color = TowerPlan.decorStarColor(stageIndex, starIndex)
			star.Material = Enum.Material.Neon
			star.TopSurface = Enum.SurfaceType.Smooth
			star.BottomSurface = Enum.SurfaceType.Smooth
			star.Parent = parent
			local turn = TweenService:Create(
				star,
				TweenInfo.new(TowerTuning.SPARKLE.starTurnTime, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true),
				{ CFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(180), 0) }
			)
			turn:Play()
		end
	end
end

-- A slim shaft of golden light rising from the crown pad, so the
-- finish line can be seen from the ground before the climb begins.
function GoldenTowerBuilder.buildWinBeacon(parent: Instance)
	local top = TowerPlan.winPadPosition()
	local beam = Instance.new("Part")
	beam.Name = "WinBeacon"
	beam.Size = Vector3.new(1.5, 100, 1.5)
	beam.CFrame = CFrame.new(top + Vector3.new(0, 50.5, 0))
	beam.Anchored = true
	beam.CanCollide = false
	beam.Color = TowerPlan.WIN_COLOR
	beam.Material = Enum.Material.Neon
	beam.Transparency = 0.55
	beam.TopSurface = Enum.SurfaceType.Smooth
	beam.BottomSurface = Enum.SurfaceType.Smooth
	beam.Parent = parent
end

-- A shower of gold over the crown pad when somebody finishes. The
-- pieces are tiny, never collide, and tidy themselves away after a
-- few seconds, so a win never leaves clutter behind.
function GoldenTowerBuilder.celebrateWin(position: Vector3)
	local workspace = game:GetService("Workspace")
	for _ = 1, TowerTuning.SPARKLE.confettiPieces do
		local piece = Instance.new("Part")
		piece.Name = "WinConfetti"
		piece.Size = Vector3.new(0.7, 0.7, 0.15)
		piece.Color = CROWN_CONFETTI[math.random(#CROWN_CONFETTI)]
		piece.Material = Enum.Material.Neon
		piece.Anchored = false
		piece.CanCollide = false
		piece.CFrame = CFrame.new(position + Vector3.new(math.random(-6, 6), math.random(2, 8), math.random(-6, 6)))
		piece.AssemblyLinearVelocity = Vector3.new(math.random(-12, 12), math.random(18, 38), math.random(-12, 12))
		piece.Parent = workspace
		Debris:AddItem(piece, TowerTuning.SPARKLE.confettiLifetime)
	end
end

-- Raises every stage of the tower into a folder in Workspace and
-- hands back the parts the game logic needs to watch.
function GoldenTowerBuilder.buildTower(workspace: Workspace)
	local folder = Instance.new("Folder")
	folder.Name = "SkyTower"
	folder.Parent = workspace

	local checkpoints = {}
	local killBars = {}

	for stageIndex = 1, TowerPlan.STAGE_COUNT do
		local plan = TowerPlan.stagePlan(stageIndex)
		for _, spec in ipairs(plan.platforms) do
			if spec.kind == "checkpoint" then
				local pad = GoldenTowerBuilder.buildCheckpointPad(stageIndex, spec.position, folder)
				checkpoints[stageIndex] = pad
			elseif spec.kind == "moving" then
				GoldenTowerBuilder.buildMovingPlatform(spec, folder)
			else
				GoldenTowerBuilder.buildPlatform(spec, folder)
			end
		end
		for _, bar in ipairs(plan.killBars) do
			table.insert(killBars, GoldenTowerBuilder.buildKillBar(bar, folder))
		end
	end

	local winPad = GoldenTowerBuilder.buildWinPad(folder)
	local returnPad = GoldenTowerBuilder.buildReturnPad(folder)
	GoldenTowerBuilder.buildDecorStars(folder)
	GoldenTowerBuilder.buildWinBeacon(folder)

	return {
		checkpoints = checkpoints,
		killBars = killBars,
		winPad = winPad,
		returnPad = returnPad,
	}
end

return GoldenTowerBuilder
