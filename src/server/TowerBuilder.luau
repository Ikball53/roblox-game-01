-- TowerBuilder: turns the TowerLayout plan into real parts.
-- One job: build the tower. It returns the parts the main script has
-- to wire up (checkpoints, kill bars, the win pad, the return pad).

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TowerLayout = require(ReplicatedStorage:WaitForChild("TowerLayout"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local TowerBuilder = {}

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

-- A normal platform: a solid step of the spiral.
function TowerBuilder.buildPlatform(spec, parent: Instance): Part
	local part = makePart("Platform", spec.size, spec.position, spec.color, Enum.Material.SmoothPlastic)
	part.Parent = parent
	return part
end

-- A platform that slides back and forth along the tower's ring, so the
-- player has to time the jump. TweenService loops it forever.
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
	return part
end

-- The golden pad on top of the column: the finish line.
function TowerBuilder.buildWinPad(parent: Instance): Part
	local part = makePart("WinPad", Vector3.new(10, 1, 10), TowerLayout.winPadPosition(), TowerLayout.WIN_COLOR, Enum.Material.Neon)
	part.Parent = parent
	return part
end

-- The cyan pad on the ground that carries a fallen player back to
-- their checkpoint, so a fall costs time, not the whole climb.
function TowerBuilder.buildReturnPad(parent: Instance): Part
	local part = makePart("ReturnPad", Vector3.new(8, 1, 8), TowerLayout.returnPadPosition(), Color3.fromRGB(0, 200, 255), Enum.Material.Neon)
	part.Parent = parent
	return part
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

	return {
		checkpoints = checkpoints,
		killBars = killBars,
		winPad = winPad,
		returnPad = returnPad,
	}
end

return TowerBuilder
