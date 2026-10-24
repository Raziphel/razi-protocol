-- Where the themed enemy families live (compat/enemy_homes.lua and the six enemy modules) on a mocked data.raw.
-- Run from the mod root:
--   lua5.2 tests/lua/test_enemy_homes.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

-- Factorio's table.deepcopy
if not table.deepcopy then
	local function deepcopy(value)
		if type(value) ~= "table" then
			return value
		end
		local copy = {}
		for key, entry in pairs(value) do
			copy[key] = deepcopy(entry)
		end
		return copy
	end
	table.deepcopy = deepcopy -- luacheck: ignore 122
end

local logged = {}
rawset(_G, "log", function(message) logged[#logged + 1] = message end)

local module_names = {
	"enemy_autoplace", "enemy_homes", "enemy_planet_pollution", "armoured_biters", "arachnids_enemy",
	"explosive_biters", "toxic_biters", "cold_biters", "electric_flying_enemies"
}

local all_mods = {
	["ArmouredBiters-2_1-update"] = "2.0.4", Arachnids_enemy = "1.2.1", Explosive_biters = "2.4.0",
	Toxic_biters = "2.1.0", Cold_biters = "2.3.0", Electric_flying_enemies = "0.2.1"
}

local vanilla = {"biter-spawner", "spitter-spawner", "small-worm-turret", "medium-worm-turret", "big-worm-turret", "behemoth-worm-turret"}
local toxic_worm = "small-toxic-worm-turret"
local nest = {
	armoured = "armoured-biter-spawner", arachnids = "arachnid-spawner-unitspawner", explosive = "explosive-biter-spawner",
	toxic = "toxic-biter-spawner", cold = "cb-cold-spawner", electric = "flying-electric-unit-spawner"
}

local function spawner(name, control)
	return {type = "unit-spawner", name = name, autoplace = {control = control, probability_expression = "x"}}
end

local function planet(controls)
	return {type = "planet", map_gen_settings = {autoplace_controls = controls or {}}}
end

local function setup(active_mods)
	for _, name in ipairs(module_names) do
		package.loaded["prototypes.compat." .. name] = nil
	end
	rawset(_G, "mods", active_mods)
	rawset(_G, "settings", {startup = {}})

	local spawners = {}
	for _, name in ipairs(vanilla) do
		spawners[name] = spawner(name, "enemy-base")
	end
	spawners[nest.armoured] = spawner(nest.armoured, "enemy-base")
	spawners[nest.arachnids] = spawner(nest.arachnids, "enemy-base")
	spawners[nest.toxic] = spawner(nest.toxic, "enemy-base")
	spawners[nest.explosive] = spawner(nest.explosive, "hot_enemy_base")
	spawners[nest.cold] = spawner(nest.cold, "frost_enemy_base")
	spawners[nest.electric] = spawner(nest.electric, "electric_enemies")
	local turrets = {[toxic_worm] = {type = "turret", name = toxic_worm, autoplace = {control = "enemy-base", probability_expression = "x"}}}

	local tiles = {}
	for _, name in ipairs({"hyarion-soil-dark", "arig-sand", "moshine-rock", "cubium-folds", "snow-flat", "ice-rough", "fulgoran-dust",
		"dirt-1", "sand-1", "panglia-volcanic-cracks", "planet-crucible-dirt-1", "dust-flat-vesta", "volcanic-cracks"}) do
		tiles[name] = {type = "tile", name = name}
	end

	rawset(_G, "data", {raw = {
		["unit-spawner"] = spawners,
		turret = turrets,
		tile = tiles,
		planet = {
			nauvis = planet({["enemy-base"] = {}, ["frost_enemy_base"] = {}}),
			terrapalus = planet({["enemy-base"] = {}}),
			-- tiles shared with Nauvis and a control of its own: the case a tile restriction does not cover
			athos = planet({["enemy-base"] = {}}),
			hyarion = planet(), arig = planet(), moshine = planet(), cubium = planet(), aquilo = planet(), frozeta = planet(),
			fulgora = planet({electric_enemies = {}}),
			ribbonia = planet(),
			lemures = planet({frost_enemy_base = {}}),
			-- former homes: back to the planets' own state
			panglia = planet(), crucible = planet(), vesta = planet(), paracelsin = planet(), corrundum = planet(), nexus = planet(),
			-- a planet that turns the control off
			quiet = planet({["enemy-base"] = {frequency = 0, size = 0, richness = 0}}),
		},
	}})
end

local function run_all()
	for _, name in ipairs({"arachnids_enemy", "armoured_biters", "cold_biters", "electric_flying_enemies", "explosive_biters", "toxic_biters"}) do
		require("prototypes.compat." .. name)
	end
	require("prototypes.compat.enemy_homes").data_final_fixes()
end

local function map_gen(planet_name)
	return data.raw.planet[planet_name].map_gen_settings --[[@as table]]
end

local function entity_setting(planet_name, entity_name)
	local settings = map_gen(planet_name)
	settings = settings.autoplace_settings and settings.autoplace_settings.entity and settings.autoplace_settings.entity.settings
	return settings and settings[entity_name]
end

local function placed(planet_name, entity_name)
	local setting = entity_setting(planet_name, entity_name)
	return setting ~= nil and setting.frequency ~= 0
end

local function zeroed(planet_name, entity_name)
	local setting = entity_setting(planet_name, entity_name)
	return setting ~= nil and setting.frequency == 0 and setting.size == 0 and setting.richness == 0
end

-- Which planets get which family: Normal.
setup(all_mods)
run_all()
local homes = {
	armoured = {"hyarion"}, arachnids = {"arig"}, explosive = {"moshine"}, toxic = {"cubium"},
	cold = {"frozeta"}, electric = {"ribbonia"}
}
for family, entity_name in pairs(nest) do
	local expected = {}
	for _, planet_name in ipairs(homes[family]) do
		expected[planet_name] = true
	end
	for planet_name in pairs(data.raw.planet) do
		check(placed(planet_name, entity_name) == (expected[planet_name] == true),
			family .. " nests on " .. planet_name .. ": expected " .. tostring(expected[planet_name] == true))
	end
end

-- Former homes and Nexus are back to the planet's own state: no control, no entry, no pollution.
for _, planet_name in ipairs({"panglia", "crucible", "vesta", "paracelsin", "corrundum", "nexus"}) do
	local map_gen_settings = map_gen(planet_name)
	check(next(map_gen_settings.autoplace_controls) == nil, planet_name .. " has no enemy control")
	check(map_gen_settings.autoplace_settings == nil, planet_name .. " has no entity entries")
	check(data.raw.planet[planet_name].pollutant_type == nil, planet_name .. " has no pollution")
end

-- Pollution only where there is a home; Fulgora's is the enemy mod's own, Lemures belongs to Dea Dia.
for _, planet_name in ipairs({"hyarion", "arig", "moshine", "cubium", "frozeta", "ribbonia"}) do
	check(data.raw.planet[planet_name].pollutant_type == "pollution", planet_name .. " carries pollution")
end
for _, planet_name in ipairs({"fulgora", "lemures", "nauvis", "terrapalus", "athos"}) do
	check(data.raw.planet[planet_name].pollutant_type == nil, planet_name .. " is left alone")
end

-- Fulgora (Electric's own planet) and Lemures (Cold, Dea Dia's) are not touched.
check(entity_setting("fulgora", nest.electric) == nil, "Fulgora's electric nests stay the enemy mod's")
check(map_gen("fulgora").autoplace_settings == nil, "Fulgora gets no entity entries")
check(map_gen("lemures").autoplace_settings == nil, "Lemures gets no entity entries")

-- No specialist nests on Nauvis or on any other planet with the shared control, whatever tiles it has.
for _, planet_name in ipairs({"nauvis", "terrapalus", "athos"}) do
	for _, family in ipairs({"armoured", "arachnids", "toxic"}) do
		check(zeroed(planet_name, nest[family]), family .. " is switched off on " .. planet_name)
	end
	check(zeroed(planet_name, toxic_worm), "toxic worms are switched off on " .. planet_name)
	for _, name in ipairs(vanilla) do
		check(entity_setting(planet_name, name) == nil, planet_name .. " keeps the vanilla " .. name)
	end
end
-- A home of one shared-control family is not a home of the others.
check(zeroed("hyarion", nest.toxic) and zeroed("hyarion", nest.arachnids), "Hyarion has Armoured only")
check(zeroed("arig", nest.armoured) and zeroed("cubium", nest.arachnids), "Arig has Arachnids only, Cubium Toxic only")
check(placed("cubium", toxic_worm), "Cubium has the toxic worms")
check(not zeroed("hyarion", nest.armoured), "Hyarion keeps its own family")
-- The vanilla enemies are off on the homes (as before); a planet that switched the control off is left alone.
for _, planet_name in ipairs({"hyarion", "arig", "moshine", "cubium", "frozeta", "ribbonia"}) do
	check(zeroed(planet_name, "biter-spawner"), "vanilla biters are off on " .. planet_name)
end
check(map_gen("quiet").autoplace_settings == nil, "a planet with the control off gets no entries")

-- Tile restrictions keep to the tiles of the homes.
local function restricted_to(entity)
	local restriction = {}
	for _, tile_name in ipairs(entity.autoplace.tile_restriction) do
		restriction[tile_name] = true
	end
	return restriction
end
local armoured_tiles = restricted_to(data.raw["unit-spawner"][nest.armoured])
check(armoured_tiles["hyarion-soil-dark"] and not armoured_tiles["panglia-volcanic-cracks"] and not armoured_tiles["volcanic-cracks"],
	"Armoured nests only on Hyarion's tiles")
local toxic_tiles = restricted_to(data.raw["unit-spawner"][nest.toxic])
check(toxic_tiles["cubium-folds"] and not toxic_tiles["dust-flat-vesta"] and not toxic_tiles["planet-crucible-dirt-1"],
	"Toxic nests only on Cubium's tiles")

check(#logged > 0, "the nests that were switched off are logged")

-- Without the enemy mods nothing is placed or switched off.
setup({})
run_all()
for planet_name in pairs(data.raw.planet) do
	check(map_gen(planet_name).autoplace_settings == nil, "no enemy mods, " .. planet_name .. " untouched")
end

-- Only the installed families are switched off: with Toxic alone the Armoured nest is not named.
setup({Toxic_biters = "2.1.0"})
run_all()
check(zeroed("nauvis", nest.toxic) and entity_setting("nauvis", nest.armoured) == nil, "only the installed family is switched off")

-- Enemy routing off: nothing is touched.
setup(all_mods)
settings.startup["razi-enable-enemy-routing"] = {value = false} -- luacheck: ignore 122
run_all()
for planet_name in pairs(data.raw.planet) do
	check(map_gen(planet_name).autoplace_settings == nil, "routing off, " .. planet_name .. " untouched")
end

-- A family without a placeable nest (a mod with its nest setting off) is not claimed, so nothing is switched off.
setup(all_mods)
data.raw["unit-spawner"][nest.armoured] = nil
run_all()
check(entity_setting("nauvis", nest.armoured) == nil, "no Armoured nest, nothing to switch off")

rawset(_G, "mods", nil)
rawset(_G, "log", nil)
rawset(_G, "settings", nil)
rawset(_G, "data", nil)
print("enemy_homes: ok")
