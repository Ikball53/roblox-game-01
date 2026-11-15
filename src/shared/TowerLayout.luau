-- TowerLayout: the whole Sky Tower as data, one stage at a time.
-- The tower is a spiral of small platforms around the central column.
-- Every stage climbs 10 studs in 4 jumps; later stages add moving
-- platforms and kill bars, so the climb gets harder the higher you go.
-- Jump distances never change here: only sizes, colors and materials
-- vary, and every platform stays at least 6.5 studs wide, so the
-- early stages stay exactly as easy as before.

local TowerLayout = {}

TowerLayout.STAGE_COUNT = 12
TowerLayout.STAGE_HEIGHT = 10
TowerLayout.TOWER_RADIUS = 14
TowerLayout.PLATFORMS_PER_STAGE = 4

-- One bright color per stage, so the player can read how high they are.
TowerLayout.PALETTE = {
	Color3.fromRGB(88, 166, 255),
	Color3.fromRGB(64, 224, 160),
	Color3.fromRGB(255, 214, 64),
	Color3.fromRGB(255, 140, 66),
	Color3.fromRGB(255, 92, 138),
	Color3.fromRGB(190, 120, 255),
	Color3.fromRGB(80, 200, 255),
	Color3.fromRGB(120, 255, 110),
	Color3.fromRGB(255, 190, 40),
	Color3.fromRGB(255, 110, 90),
	Color3.fromRGB(140, 160, 255),
	Color3.fromRGB(255, 220, 120),
}

-- Materials rotate per stage: glass every third stage, a glowing neon
-- finale on stage 12, smooth plastic everywhere else. Looks different,
-- plays exactly the same.
function TowerLayout.stageMaterial(stageIndex: number): Enum.Material
	if stageIndex == TowerLayout.STAGE_COUNT then
		return Enum.Material.Neon
	elseif stageIndex % 3 == 0 then
		return Enum.Material.Glass
	else
		return Enum.Material.SmoothPlastic
	end
end

-- Platform footprints vary a little per step, always roomy: the jumps
-- are the same distances as before, the landings are just shaped
-- differently so no two stages feel identical.
local STEP_SIZES = {
	Vector3.new(9, 1, 9),
	Vector3.new(8, 1, 7),
	Vector3.new(7, 1, 7),
	Vector3.new(7.5, 1, 6.5),
}

TowerLayout.CHECKPOINT_COLOR = Color3.fromRGB(46, 204, 113)
TowerLayout.KILL_COLOR = Color3.fromRGB(231, 76, 60)
TowerLayout.MOVE_COLOR = Color3.fromRGB(155, 89, 182)
TowerLayout.WIN_COLOR = Color3.fromRGB(241, 196, 15)

-- The sparkle colors of the decorative stars that float beside the
-- tower: white, gold, sky blue and pink, cycling with the stages.
TowerLayout.STAR_COLORS = {
	Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(255, 220, 120),
	Color3.fromRGB(120, 220, 255),
	Color3.fromRGB(255, 150, 220),
}

-- Where one platform of a stage sits: a spiral step around the column.
-- `stageIndex` is 1-based, `stepIndex` is 1-based inside the stage.
function TowerLayout.platformPosition(stageIndex: number, stepIndex: number): Vector3
	local baseAngle = (stageIndex - 1) * 100
	local angle = math.rad(baseAngle + (stepIndex - 1) * 35)
	local height = (stageIndex - 1) * TowerLayout.STAGE_HEIGHT + (stepIndex - 1) * 2.5 + 2
	local x = math.cos(angle) * TowerLayout.TOWER_RADIUS
	local z = math.sin(angle) * TowerLayout.TOWER_RADIUS
	return Vector3.new(x, height, z)
end

-- A decorative star floating beside the tower. Pure sparkle: it can
-- never collide with or block a player.
function TowerLayout.decorStarPosition(stageIndex: number, starIndex: number): Vector3
	local angle = math.rad((stageIndex - 1) * 100 + (starIndex - 1) * 120 + 55)
	local radius = 20 + starIndex * 1.5
	-- Offset by half a step, so each star floats between two platform
	-- levels instead of sitting exactly level with one of them.
	local height = (stageIndex - 1) * TowerLayout.STAGE_HEIGHT + 3.2 + starIndex * 2.5
	return Vector3.new(math.cos(angle) * radius, height, math.sin(angle) * radius)
end

-- Which sparkle color a decorative star gets: cycles with the stage.
function TowerLayout.decorStarColor(stageIndex: number, starIndex: number): Color3
	return TowerLayout.STAR_COLORS[(stageIndex + starIndex - 1) % #TowerLayout.STAR_COLORS + 1]
end

-- Where the big floating title sign hangs: high above the spawn pad,
-- where every player sees it the moment they join.
function TowerLayout.titleSignPosition(): Vector3
	return Vector3.new(26, 11, 0)
end

-- The full plan for one stage: its platforms, and any kill bar floating
-- across the gap between the second and third platform.
function TowerLayout.stagePlan(stageIndex: number)
	local color = TowerLayout.PALETTE[stageIndex] or TowerLayout.PALETTE[1]
	local platforms = {}
	for stepIndex = 1, TowerLayout.PLATFORMS_PER_STAGE do
		local kind = "normal"
		if stepIndex == 1 then
			kind = "checkpoint"
		elseif stageIndex >= 4 and stepIndex == 3 then
			kind = "moving"
		end
		local size = STEP_SIZES[stepIndex]
		table.insert(platforms, {
			kind = kind,
			position = TowerLayout.platformPosition(stageIndex, stepIndex),
			size = size,
			color = kind == "checkpoint" and TowerLayout.CHECKPOINT_COLOR or kind == "moving" and TowerLayout.MOVE_COLOR or color,
			material = kind == "normal" and TowerLayout.stageMaterial(stageIndex) or Enum.Material.Neon,
		})
	end

	local killBars = {}
	if stageIndex >= 6 then
		local second = TowerLayout.platformPosition(stageIndex, 2)
		local third = TowerLayout.platformPosition(stageIndex, 3)
		local middle = Vector3.new((second.X + third.X) / 2, (second.Y + third.Y) / 2 + 0.6, (second.Z + third.Z) / 2)
		table.insert(killBars, {
			position = middle,
			size = Vector3.new(8, 1, 1.5),
			color = TowerLayout.KILL_COLOR,
		})
	end

	return { platforms = platforms, killBars = killBars }
end

-- The golden pad on top of the central column: the finish line.
function TowerLayout.winPadPosition(): Vector3
	return Vector3.new(0, 121.5, 0)
end

-- The glowing pad on the ground that carries a fallen player back to
-- their checkpoint, so a fall costs time, not the whole climb.
function TowerLayout.returnPadPosition(): Vector3
	return Vector3.new(26, 1.1, 12)
end

return TowerLayout
