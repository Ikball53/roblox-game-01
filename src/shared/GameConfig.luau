-- GoldenTowerConfig: every number that tunes the Golden Sky Tower lives
-- in this one module. The server and the client both read from it, so a
-- single change here reaches the whole game at once. Nothing in this
-- file moves a platform or changes a rule: it only tunes how far things
-- slide, how long a touch is ignored, and how the celebration looks.

local GoldenTowerConfig = {}

-- A moving platform glides this far from its home position, in studs.
GoldenTowerConfig.SLIDE_DISTANCE = 5
-- One glide takes this long, in seconds, there and back again.
GoldenTowerConfig.SLIDE_TIME = 2.5

-- After a kill bar brushes a player, further touches are ignored for
-- this many seconds, so one brush can never kill the same player twice.
GoldenTowerConfig.HIT_COOLDOWN = 1

-- Dropping below this height ends the attempt: the climber wakes up at
-- the checkpoint they earned, never at the bottom.
GoldenTowerConfig.FALL_LINE = -20

-- How often the client redraws the climb timer, in seconds.
GoldenTowerConfig.CLOCK_TICK = 0.1

-- The golden sparkle that dresses the tower: a few slow-turning stars
-- beside every stage, and a burst of gold confetti over the crown when
-- somebody finishes. All of it is weightless decoration — it can never
-- be touched, and it never changes a single jump.
GoldenTowerConfig.SPARKLE = {
	starsPerStage = 3,
	starTurnTime = 8,
	confettiPieces = 60,
	confettiLifetime = 4,
}

-- The words the climber reads on screen. Short, warm, and large
-- enough to read at a glance on a phone.
GoldenTowerConfig.TEXT = {
	title = "SKY TOWER OBBY",
	subtitle = "Climb 12 stages. Touch green to save. Reach the gold!",
	checkpoint = "Checkpoint saved!",
	win = "YOU WIN!",
	winSub = "You conquered all 12 stages!",
	winAgain = "Play again",
	fell = "You fell! Back to your checkpoint.",
}

-- Friendly short names, so the rest of the code reads like the game it
-- builds. One map, one loop: each old name points at the same value as
-- its new name, so nothing is ever written twice.
local LEGACY_NAMES = {
	MOVE_DISTANCE = "SLIDE_DISTANCE",
	MOVE_TIME = "SLIDE_TIME",
	TOUCH_COOLDOWN = "HIT_COOLDOWN",
	FALL_HEIGHT = "FALL_LINE",
	TIMER_TICK = "CLOCK_TICK",
	DECOR = "SPARKLE",
}
for oldName, newName in pairs(LEGACY_NAMES) do
	GoldenTowerConfig[oldName] = GoldenTowerConfig[newName]
end

return GoldenTowerConfig
