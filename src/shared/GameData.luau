-- Golden Core Miner: the one shared table of truth for zones, ores and
-- upgrades. The server stage and the client game both read from here, so
-- a number only ever changes in one place.

local GameData = {}

GameData.ZONES = {
	{
		key = "surface",
		name = "SURFACE",
		tag = "Copper Vein",
		unlockGems = 0,
		field = Color3.fromRGB(16, 58, 66),
		accent = Color3.fromRGB(255, 176, 66),
		-- Gentle opening: rocks come slower and warn longer so a
		-- first-time player can mine 25 gems before the run ends.
		rockEvery = { min = 6, max = 9 },
		rockWarn = 1.6,
		-- Fewer rocks aimed straight at the miner while learning.
		rockAimMiner = 0.35,
		ores = {
			{ name = "Copper", color = Color3.fromRGB(214, 116, 60), hits = 2, gems = 1, weight = 65 },
			{ name = "Tin", color = Color3.fromRGB(168, 178, 190), hits = 2, gems = 1, weight = 35 },
		},
	},
	{
		key = "deep",
		name = "DEEP",
		tag = "Sapphire Vein",
		unlockGems = 25,
		field = Color3.fromRGB(24, 32, 86),
		accent = Color3.fromRGB(86, 178, 255),
		rockEvery = { min = 3.5, max = 5.5 },
		rockWarn = 0.9,
		rockAimMiner = 0.5,
		ores = {
			{ name = "Sapphire", color = Color3.fromRGB(62, 132, 255), hits = 3, gems = 3, weight = 60 },
			{ name = "Emerald", color = Color3.fromRGB(46, 204, 113), hits = 4, gems = 5, weight = 40 },
		},
	},
	{
		key = "core",
		name = "CORE",
		tag = "Golden Core",
		unlockGems = 60,
		field = Color3.fromRGB(74, 32, 20),
		accent = Color3.fromRGB(255, 210, 63),
		rockEvery = { min = 3, max = 5 },
		rockWarn = 0.9,
		rockAimMiner = 0.5,
		ores = {
			{ name = "Gold", color = Color3.fromRGB(255, 200, 40), hits = 4, gems = 6, weight = 60 },
			{ name = "Ruby", color = Color3.fromRGB(224, 52, 92), hits = 5, gems = 8, weight = 40 },
		},
	},
}

GameData.CORE = {
	name = "GOLDEN CORE",
	hits = 15,
	color = Color3.fromRGB(255, 214, 64),
}

GameData.UPGRADES = {
	pickaxe = {
		name = "Pickaxe",
		blurb = "+1 damage on every hit",
		costs = { 10, 25, 50 },
	},
	dash = {
		name = "Swift Boots",
		blurb = "Dash recharges faster",
		costs = { 8, 20, 40 },
		cooldowns = { 4, 3, 2.5, 2 },
	},
	magnet = {
		name = "Lucky Magnet",
		blurb = "+1 bonus gem on every break",
		costs = { 12, 30, 60 },
	},
}

GameData.TUNING = {
	hearts = 3,
	nodeCount = 6,
	baseDamage = 1,
	dashSeconds = 1,
	rockWarnSeconds = 0.9,
	rockBuriedSeconds = 3,
	nodeRespawnSeconds = 1.2,
}

-- Pick one ore from a zone, weighted so the common ore shows up most.
function GameData.pickOre(zone)
	local total = 0
	for _, ore in ipairs(zone.ores) do
		total = total + ore.weight
	end
	local roll = math.random(1, total)
	for _, ore in ipairs(zone.ores) do
		roll = roll - ore.weight
		if roll <= 0 then
			return ore
		end
	end
	return zone.ores[1]
end

return GameData
