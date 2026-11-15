-- Main: the server half of Sky Tower Obby.
-- Builds the tower, then watches every touch that matters: green pads
-- save progress, red bars end the attempt, the gold pad wins the game,
-- and the cyan pad carries a fallen player back to their checkpoint.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TowerLayout = require(ReplicatedStorage:WaitForChild("TowerLayout"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local TowerBuilder = require(script.Parent:WaitForChild("TowerBuilder"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))

local tower = TowerBuilder.buildTower(game:GetService("Workspace"))

local function makeRemote(name: string): RemoteEvent
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = ReplicatedStorage
	return remote
end

local checkpointEvent = makeRemote("TowerCheckpoint")
local winEvent = makeRemote("TowerWin")
local resetEvent = makeRemote("TowerReset")

local spawnCFrame = CFrame.new(26, 3, 0)
local lastKillAt = {}

-- Moves a character to a spot, standing just above it.
local function teleportPlayer(player: Player, target: CFrame)
	local character = player.Character
	if character == nil then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root == nil then
		return
	end
	character:PivotTo(target + Vector3.new(0, 3, 0))
end

-- A new climber joins: fresh record, and every respawn puts them back
-- at the checkpoint they earned, never at the bottom by surprise.
local function onPlayerAdded(player: Player)
	PlayerState.newPlayer(player, spawnCFrame)
	player.CharacterAdded:Connect(function(character)
		local record = PlayerState.get(player)
		if record == nil then
			return
		end
		character:WaitForChild("HumanoidRootPart", 5)
		teleportPlayer(player, record.checkpoint)
	end)
end

for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(player)
	PlayerState.removePlayer(player)
	lastKillAt[player] = nil
end)

-- Green pads: save the stage, and tell that player's screen about it.
for stageIndex, pad in pairs(tower.checkpoints) do
	pad.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player == nil then
			return
		end
		local saved = PlayerState.setCheckpoint(player, stageIndex, pad.CFrame)
		if saved then
			checkpointEvent:FireClient(player, stageIndex)
		end
	end)
end

-- Red bars: one touch ends the attempt. A short cooldown keeps one
-- brush from counting twice.
for _, bar in ipairs(tower.killBars) do
	bar.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = Players:GetPlayerFromCharacter(character)
		if player == nil then
			return
		end
		local now = os.clock()
		if lastKillAt[player] ~= nil and now - lastKillAt[player] < GameConfig.TOUCH_COOLDOWN then
			return
		end
		lastKillAt[player] = now
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid ~= nil and humanoid.Health > 0 then
			PlayerState.addDeath(player)
			humanoid.Health = 0
		end
	end)
end

-- The gold pad: the climb is done. Tell the winner their time.
tower.winPad.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if player == nil then
		return
	end
	local climbTime = PlayerState.finish(player)
	if climbTime ~= nil then
		local record = PlayerState.get(player)
		winEvent:FireClient(player, climbTime, record ~= nil and record.deaths or 0)
	end
end)

-- The cyan pad on the ground: a fallen player steps on it and goes
-- straight back to their checkpoint.
tower.returnPad.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if player == nil then
		return
	end
	local record = PlayerState.get(player)
	if record ~= nil then
		teleportPlayer(player, record.checkpoint)
	end
end)

-- "Play again" from the win screen: clean clock, back to stage 1.
resetEvent.OnServerEvent:Connect(function(player)
	local record = PlayerState.get(player)
	if record == nil then
		return
	end
	PlayerState.resetForReplay(player, spawnCFrame)
	teleportPlayer(player, spawnCFrame)
end)

-- One slow watch for falls: a player under the tower has lost the
-- climb, so they wake up at their checkpoint.
task.spawn(function()
	while true do
		task.wait(0.5)
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			if character == nil then
				continue
			end
			local root = character:FindFirstChild("HumanoidRootPart")
			local record = PlayerState.get(player)
			if root ~= nil and record ~= nil and root.Position.Y < GameConfig.FALL_HEIGHT then
				PlayerState.addDeath(player)
				teleportPlayer(player, record.checkpoint)
			end
		end
	end
end)
