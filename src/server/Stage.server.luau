-- Golden Core Miner: the little mine-mouth stage the game stands in.
-- The GUI is the game; this is only the world behind it, built once when
-- the server starts so the place is never an empty void.

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local function part(name, size, pos, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = pos
	p.Color = color
	p.Material = material
	p.Anchored = true
	p.CanCollide = true
	p.Parent = Workspace
	return p
end

-- Ground: a wide dark slab the mine mouth sits on.
part("Ground", Vector3.new(70, 1, 70), Vector3.new(0, -0.5, 0), Color3.fromRGB(28, 34, 38), Enum.Material.Slate)

-- Mine mouth: two stone pillars and a lintel, with a dark opening.
part("PillarLeft", Vector3.new(3, 12, 3), Vector3.new(-6, 6, -10), Color3.fromRGB(96, 96, 104), Enum.Material.Concrete)
part("PillarRight", Vector3.new(3, 12, 3), Vector3.new(6, 6, -10), Color3.fromRGB(96, 96, 104), Enum.Material.Concrete)
part("Lintel", Vector3.new(15, 2, 3), Vector3.new(0, 13, -10), Color3.fromRGB(110, 108, 100), Enum.Material.Concrete)
part("MouthDark", Vector3.new(9, 11, 1), Vector3.new(0, 5.5, -11), Color3.fromRGB(8, 8, 12), Enum.Material.SmoothPlastic)

-- Wooden sign on the lintel, naming the game.
local signGui = Instance.new("SurfaceGui")
signGui.Face = Enum.NormalId.Front
signGui.Parent = Workspace:WaitForChild("Lintel")
local signText = Instance.new("TextLabel")
signText.Size = UDim2.fromScale(1, 1)
signText.BackgroundTransparency = 1
signText.Text = "GOLDEN CORE MINER"
signText.Font = Enum.Font.GothamBlack
signText.TextScaled = true
signText.TextColor3 = Color3.fromRGB(255, 210, 63)
signText.Parent = signGui

-- Crystal clusters: bright gold and teal spikes flanking the mouth.
local crystalSpots = {
	{ Vector3.new(-11, 1.5, -7), Color3.fromRGB(255, 200, 40), 35 },
	{ Vector3.new(-12, 1, -5), Color3.fromRGB(86, 178, 255), -25 },
	{ Vector3.new(11, 1.5, -7), Color3.fromRGB(255, 200, 40), -30 },
	{ Vector3.new(12, 1, -5), Color3.fromRGB(46, 204, 113), 20 },
	{ Vector3.new(-9, 1, -12), Color3.fromRGB(255, 210, 63), 15 },
	{ Vector3.new(9, 1, -12), Color3.fromRGB(86, 178, 255), -15 },
}
for i, spot in ipairs(crystalSpots) do
	local c = part("Crystal" .. i, Vector3.new(1.2, 3, 1.2), spot[1], spot[2], Enum.Material.Neon)
	c.Orientation = Vector3.new(0, 0, spot[3])
end

-- Scattered boulders, so the ground is not bare.
local rockSpots = {
	{ Vector3.new(-16, 1, 4), Vector3.new(3, 2, 3) },
	{ Vector3.new(15, 1, 6), Vector3.new(4, 2, 3) },
	{ Vector3.new(-14, 1, 12), Vector3.new(3, 2, 4) },
	{ Vector3.new(17, 1, -2), Vector3.new(3, 3, 3) },
	{ Vector3.new(4, 0.8, 14), Vector3.new(2.5, 1.6, 2.5) },
}
for i, spot in ipairs(rockSpots) do
	local r = part("Boulder" .. i, spot[2], spot[1], Color3.fromRGB(70, 72, 78), Enum.Material.Rock)
	r.Shape = Enum.PartType.Ball
end

-- Gold veins: thin glowing strips in the ground, pointing at the mouth.
local veinSpots = {
	{ Vector3.new(-3, 0.05, 2), 12 },
	{ Vector3.new(2, 0.05, 0), -8 },
	{ Vector3.new(0, 0.05, -4), 4 },
}
for i, spot in ipairs(veinSpots) do
	local vein = part("GoldVein" .. i, Vector3.new(0.6, 0.1, 5), spot[1], Color3.fromRGB(255, 200, 40), Enum.Material.Neon)
	vein.Orientation = Vector3.new(0, spot[2], 0)
end

-- Where players arrive, facing the mine mouth.
local spawn = Instance.new("SpawnLocation")
spawn.Name = "MineSpawn"
spawn.Size = Vector3.new(8, 1, 8)
spawn.Position = Vector3.new(0, 0.5, 6)
spawn.Color = Color3.fromRGB(255, 210, 63)
spawn.Material = Enum.Material.Neon
spawn.Anchored = true
spawn.Neutral = true
spawn.Duration = 0
spawn.Parent = Workspace

-- Warm lamps on the pillars, and a dusk sky over the whole stage.
for _, x in ipairs({ -6, 6 }) do
	local lamp = Instance.new("PointLight")
	lamp.Color = Color3.fromRGB(255, 190, 90)
	lamp.Range = 18
	lamp.Brightness = 2
	lamp.Parent = part("Lamp" .. x, Vector3.new(1, 1, 1), Vector3.new(x, 11, -9), Color3.fromRGB(255, 200, 90), Enum.Material.Neon)
end

Lighting.ClockTime = 16.5
Lighting.Ambient = Color3.fromRGB(46, 46, 58)
Lighting.Brightness = 2
Lighting.FogEnd = 220
