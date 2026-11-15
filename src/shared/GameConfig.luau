-- GameConfig: every tuning number of Sky Tower Obby in one place.
-- Nothing here is a guess at runtime: the server and the client both
-- read these, so a tweak lands everywhere at once.

local GameConfig = {}

-- How far a moving platform slides from its home spot, in studs.
GameConfig.MOVE_DISTANCE = 5
-- How long one slide takes, in seconds (there and back).
GameConfig.MOVE_TIME = 2.5

-- A touch only counts again after this many seconds, so one brush with
-- a kill bar cannot kill the same player twice.
GameConfig.TOUCH_COOLDOWN = 1

-- Falling below this height means the climb is over for this attempt:
-- the player goes back to their checkpoint.
GameConfig.FALL_HEIGHT = -20

-- How often the client refreshes the timer label, in seconds.
GameConfig.TIMER_TICK = 0.1

-- The messages the player sees. Short, big, and readable at a glance.
GameConfig.TEXT = {
	title = "SKY TOWER OBBY",
	subtitle = "Climb 12 stages. Touch green to save. Reach the gold!",
	checkpoint = "Checkpoint saved!",
	win = "YOU WIN!",
	winAgain = "Play again",
	fell = "You fell! Back to your checkpoint.",
}

return GameConfig
