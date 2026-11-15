-- GoldenTowerPlan: the Golden Sky Tower as pure data, stage by stage.
-- A spiral of marble steps winds around the central column, climbing
-- ten studs per stage in four jumps. The higher the stage, the warmer
-- the marble: ivory at the foot of the tower, pure gold at the crown.
-- The shape of the climb never changes here. Jump gaps, step sizes and
-- platform counts are fixed; only the dressing varies, and every step
-- stays at least six and a half studs wide, so the easy opening stages
-- stay exactly as easy as they always were.

local GoldenTowerPlan = {}

GoldenTowerPlan.STAGE_COUNT = 12
GoldenTowerPlan.STAGE_HEIGHT = 10
GoldenTowerPlan.TOWER_RADIUS = 14
GoldenTowerPlan.PLATFORMS_PER_STAGE = 4

-- One warm marble tone per stage, ivory at the bottom warming to gold
-- at the top, so a climber can read their height from the stone alone.
GoldenTowerPlan.PALETTE = {
	Color3.fromRGB(245, 240, 228),
	Color3.fromRGB(242, 233, 213),
	Color3.fromRGB(240, 226, 196),
	Color3.fromRGB(238, 219, 178),
	Color3.fromRGB(235, 210, 158),
	Color3.fromRGB(232, 200, 138),
	Color3.fromRGB(230, 190, 118),
	Color3.fromRGB(228, 180, 100),
	Color3.fromRGB(226, 170, 84),
	Color3.fromRGB(224, 160, 70),
	Color3.fromRGB(222, 150, 58),
	Color3.fromRGB(255, 215, 0),
}

-- Marble for every ordinary step; the crown stage glows gold. No glass,
-- no plastic shine — the whole tower reads as carved stone and gold.
function GoldenTowerPlan.stageMaterial(stageIndex: number): Enum.Material
	if stageIndex == GoldenTowerPlan.STAGE_COUNT then
		return Enum.Material.Neon
	end
	return Enum.Material.Marble
end

-- Step footprints vary a touch from jump to jump, always roomy: the
-- leaps are the same distances as ever, the landings are only shaped a
-- little differently so no two stages feel quite the same.
local STEP_SIZES = {
	Vector3.new(9, 1, 9),
	Vector3.new(8, 1, 7),
	Vector3.new(7, 1, 7),
	Vector3.new(7.5, 1, 6.5),
}

GoldenTowerPlan.CHECKPOINT_COLOR = Color3.fromRGB(16, 185, 129)
GoldenTowerPlan.KILL_COLOR = Color3.fromRGB(192, 21, 47)
GoldenTowerPlan.MOVE_COLOR = Color3.fromRGB(212, 175, 55)
GoldenTowerPlan.WIN_COLOR = Color3.fromRGB(255, 215, 0)

-- The sparkle of the golden stars drifting beside the tower: pure gold,
-- soft champagne and white, nothing else. Elegant, never rainbow.
GoldenTowerPlan.STAR_COLORS = {
	Color3.fromRGB(255, 215, 0),
	Color3.fromRGB(240, 220, 180),
	Color3.fromRGB(255, 255, 255),
}

-- The marble tone of one stage, warming toward gold as the tower
-- rises. A stage past the top simply wears the first tone.
function GoldenTowerPlan.stageTone(stageIndex: number): Color3
	return GoldenTowerPlan.PALETTE[stageIndex] or GoldenTowerPlan.PALETTE[1]
end

-- Where one step of a stage sits: a spiral turn around the column.
-- `stageIndex` is 1-based, `stepIndex` is 1-based inside the stage.
function GoldenTowerPlan.platformPosition(stageIndex: number, stepIndex: number): Vector3
	local baseAngle = (stageIndex - 1) * 100
	local angle = math.rad(baseAngle + (stepIndex - 1) * 35)
	local height = (stageIndex - 1) * GoldenTowerPlan.STAGE_HEIGHT + (stepIndex - 1) * 2.5 + 2
	local x = math.cos(angle) * GoldenTowerPlan.TOWER_RADIUS
	local z = math.sin(angle) * GoldenTowerPlan.TOWER_RADIUS
	return Vector3.new(x, height, z)
end

-- A golden star drifting beside the tower. Pure sparkle: it can never
-- be touched, and it never blocks a jump.
function GoldenTowerPlan.decorStarPosition(stageIndex: number, starIndex: number): Vector3
	local angle = math.rad((stageIndex - 1) * 100 + (starIndex - 1) * 120 + 55)
	local radius = 20 + starIndex * 1.5
	-- Half a step up from the stage floor, so each star hangs between
	-- two step levels instead of sitting flat on one of them.
	local height = (stageIndex - 1) * GoldenTowerPlan.STAGE_HEIGHT + 3.2 + starIndex * 2.5
	return Vector3.new(math.cos(angle) * radius, height, math.sin(angle) * radius)
end

-- Which sparkle tone a drifting star wears: gold, champagne, white,
-- cycling with the stage.
function GoldenTowerPlan.decorStarColor(stageIndex: number, starIndex: number): Color3
	return GoldenTowerPlan.STAR_COLORS[(stageIndex + starIndex - 1) % #GoldenTowerPlan.STAR_COLORS + 1]
end

-- The full plan for one stage: its steps, and any ruby bar hanging
-- across the gap between the second and third step.
function GoldenTowerPlan.stagePlan(stageIndex: number)
	local color = GoldenTowerPlan.stageTone(stageIndex)
	local platforms = {}
	for stepIndex = 1, GoldenTowerPlan.PLATFORMS_PER_STAGE do
		local kind = "normal"
		if stepIndex == 1 then
			kind = "checkpoint"
		elseif stageIndex >= 4 and stepIndex == 3 then
			kind = "moving"
		end
		local size = STEP_SIZES[stepIndex]
		table.insert(platforms, {
			kind = kind,
			position = GoldenTowerPlan.platformPosition(stageIndex, stepIndex),
			size = size,
			color = kind == "checkpoint" and GoldenTowerPlan.CHECKPOINT_COLOR or kind == "moving" and GoldenTowerPlan.MOVE_COLOR or color,
			material = kind == "normal" and GoldenTowerPlan.stageMaterial(stageIndex) or Enum.Material.Neon,
		})
	end

	local killBars = {}
	if stageIndex >= 6 then
		local second = GoldenTowerPlan.platformPosition(stageIndex, 2)
		local third = GoldenTowerPlan.platformPosition(stageIndex, 3)
		local middle = Vector3.new((second.X + third.X) / 2, (second.Y + third.Y) / 2 + 0.6, (second.Z + third.Z) / 2)
		table.insert(killBars, {
			position = middle,
			size = Vector3.new(8, 1, 1.5),
			color = GoldenTowerPlan.KILL_COLOR,
		})
	end

	return { platforms = platforms, killBars = killBars }
end

-- The golden crown pad on top of the central column: the finish line.
function GoldenTowerPlan.winPadPosition(): Vector3
	return Vector3.new(0, 121.5, 0)
end

-- The pale pearl pad on the ground that carries a fallen climber back
-- to their checkpoint, so a fall costs time, not the whole climb.
function GoldenTowerPlan.returnPadPosition(): Vector3
	return Vector3.new(26, 1.1, 12)
end

return GoldenTowerPlan
