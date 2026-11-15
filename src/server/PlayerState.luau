-- PlayerState: every climber's progress, kept in one place on the server.
-- One record per player: which stage they reached, how many times they
-- died, when they started, and where they respawn. Best times live for
-- the session only, by design: no DataStore, so no service failure can
-- ever break the game.

local PlayerState = {}

local records = {}

function PlayerState.newPlayer(player: Player, startCFrame: CFrame)
	records[player] = {
		stage = 1,
		deaths = 0,
		startTime = os.clock(),
		bestTime = nil,
		checkpoint = startCFrame,
		won = false,
	}
end

function PlayerState.get(player: Player)
	return records[player]
end

function PlayerState.removePlayer(player: Player)
	records[player] = nil
end

-- A checkpoint is only ever forward: touching an earlier pad cannot
-- drag a player back down the tower.
function PlayerState.setCheckpoint(player: Player, stageIndex: number, checkpointCFrame: CFrame)
	local record = records[player]
	if record == nil then
		return false
	end
	if stageIndex <= record.stage and stageIndex ~= 1 then
		return false
	end
	record.stage = stageIndex
	record.checkpoint = checkpointCFrame
	return true
end

function PlayerState.addDeath(player: Player)
	local record = records[player]
	if record ~= nil then
		record.deaths += 1
	end
end

-- Called when a player reaches the gold pad. Returns their climb time.
function PlayerState.finish(player: Player): number?
	local record = records[player]
	if record == nil or record.won then
		return nil
	end
	record.won = true
	local climbTime = os.clock() - record.startTime
	if record.bestTime == nil or climbTime < record.bestTime then
		record.bestTime = climbTime
	end
	return climbTime
end

-- A fresh attempt after a win: same player, clean clock, back to stage 1.
function PlayerState.resetForReplay(player: Player, startCFrame: CFrame)
	local record = records[player]
	if record == nil then
		return
	end
	record.stage = 1
	record.deaths = 0
	record.startTime = os.clock()
	record.checkpoint = startCFrame
	record.won = false
end

return PlayerState
