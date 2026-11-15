-- GoldenTowerMain: the server half of the Golden Sky Tower.
-- It raises the tower, then watches every touch that matters: emerald
-- pads save progress, ruby bars end the attempt, the golden crown wins
-- the game, and the pearl pad carries a fallen climber back to their
-- checkpoint. It also dresses the sky in golden hour — a low warm sun,
-- honeyed air and a soft bloom — so the marble and gold shine without
-- glare. Nothing here moves a platform; only the light changes.

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TowerPlan = require(ReplicatedStorage:WaitForChild("TowerLayout"))
local TowerTuning = require(ReplicatedStorage:WaitForChild("GameConfig"))
local TowerBuilder = require(script.Parent:WaitForChild("TowerBuilder"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))

-- A golden-hour sky: the sun low and warm, honey-colored air, and a
-- gentle bloom so the gold trims glow. Nothing here touches gameplay,
-- only how the tower looks in screenshots.
local function dressGoldenHour()
	Lighting.ClockTime = 17.3
	Lighting.Brightness = 2.2
	Lighting.Ambient = Color3.fromRGB(120, 95, 75)
	Lighting.OutdoorAmbient = Color3.fromRGB(200, 160, 120)
	-- Less flat wash, more shine, so the marble catches the low sun
	-- and the gold trims glow instead of being drowned out.
	Lighting.EnvironmentDiffuseScale = 0.35
	Lighting.EnvironmentSpecularScale = 0.7

	local sky = Instance.new("Sky")
	sky.CelestialBodiesShown = true
	sky.Parent = Lighting

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.3
	atmosphere.Offset = 0.25
	atmosphere.Color = Color3.fromRGB(255, 210, 150)
	atmosphere.Decay = Color3.fromRGB(240, 180, 120)
	atmosphere.Glare = 0.4
	atmosphere.Haze = 1
	atmosphere.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.35
	bloom.Size = 28
	bloom.Threshold = 0.9
	bloom.Parent = Lighting

	local rays = Instance.new("SunRaysEffect")
	rays.Intensity = 0.25
	rays.Spread = 0.5
	rays.Parent = Lighting
end

dressGoldenHour()

local tower = TowerBuilder.buildTower(game:GetService("Workspace"))

local function openRemote(name: string): RemoteEvent
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = ReplicatedStorage
	return remote
end

local checkpointEvent = openRemote("TowerCheckpoint")
local winEvent = openRemote("TowerWin")
local resetEvent = openRemote("TowerReset")

local spawnCFrame = CFrame.new(26, 3, 0)
local lastKillAt = {}

-- Lifts a character to a spot, standing just above it.
local function carryPlayer(player: Player, target: CFrame)
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

-- A new climber joins: a fresh record, and every respawn returns them
-- to the checkpoint they earned, never to the bottom by surprise.
local function onPlayerAdded(player: Player)
	PlayerState.newPlayer(player, spawnCFrame)
	player.CharacterAdded:Connect(function(character)
		local record = PlayerState.get(player)
		if record == nil then
			return
		end
		character:WaitForChild("HumanoidRootPart", 5)
		carryPlayer(player, record.checkpoint)
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

-- Emerald pads: save the stage, and tell that climber's screen.
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

-- Ruby bars: one touch ends the attempt. A short cooldown keeps one
-- brush from counting twice.
for _, bar in ipairs(tower.killBars) do
	bar.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = Players:GetPlayerFromCharacter(character)
		if player == nil then
			return
		end
		local now = os.clock()
		if lastKillAt[player] ~= nil and now - lastKillAt[player] < TowerTuning.TOUCH_COOLDOWN then
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

-- The golden crown: the climb is done. Tell the winner their time,
-- and celebrate over the crown pad with a shower of gold.
tower.winPad.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if player == nil then
		return
	end
	local climbTime = PlayerState.finish(player)
	if climbTime ~= nil then
		local record = PlayerState.get(player)
		local best = record ~= nil and record.bestTime or nil
		winEvent:FireClient(player, climbTime, record ~= nil and record.deaths or 0, best)
		TowerBuilder.celebrateWin(tower.winPad.Position)
	end
end)

-- The pearl pad on the ground: a fallen climber steps on it and goes
-- straight back to their checkpoint.
tower.returnPad.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if player == nil then
		return
	end
	local record = PlayerState.get(player)
	if record ~= nil then
		carryPlayer(player, record.checkpoint)
	end
end)

-- "Play again" from the win screen: a clean clock, back to stage 1.
resetEvent.OnServerEvent:Connect(function(player)
	local record = PlayerState.get(player)
	if record == nil then
		return
	end
	PlayerState.resetForReplay(player, spawnCFrame)
	carryPlayer(player, spawnCFrame)
end)

-- One slow watch for falls: a climber under the tower has lost the
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
			if root ~= nil and record ~= nil and root.Position.Y < TowerTuning.FALL_HEIGHT then
				PlayerState.addDeath(player)
				carryPlayer(player, record.checkpoint)
			end
		end
	end
end)
