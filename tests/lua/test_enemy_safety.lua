---@diagnostic disable: missing-fields, need-check-nil, assign-type-mismatch
-- Validate optional enemy routing without any Factorio engine.
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(condition, message)
	if not condition then error(message, 2) end
end

local function planet()
	return {
		map_gen_settings = {
			autoplace_controls = {["enemy-base"] = {frequency = 1}},
			autoplace_settings = {entity = {settings = {
				["biter-spawner"] = {frequency = 1},
				["small-worm-turret"] = {frequency = 1}
			}}}
		}
	}
end

local function setup()
	rawset(_G, "settings", {startup = {["razi-enable-enemy-routing"] = {value = true}}})
	rawset(_G, "data", {raw = {
		planet = {["test-world"] = planet()},
		["unit-spawner"] = {["biter-spawner"] = {}},
		turret = {["small-worm-turret"] = {}}
	}})
	package.loaded["prototypes.compat.enemy_autoplace"] = nil
	return require("prototypes.compat.enemy_autoplace")
end

local router = setup()
local p = data.raw.planet["test-world"]
router.add_entities_to_planet("test-world", {"missing-mod-spawner"}, "enemy-base")
check(p.pollutant_type == nil, "Missing enemy polluted the world")
check(p.map_gen_settings.autoplace_settings.entity.settings["biter-spawner"].frequency == 1,
	"Missing enemy pack suppressed vanilla spawners")
check(p.map_gen_settings.autoplace_settings.entity.settings["small-worm-turret"].frequency == 1,
	"Missing enemy pack suppressed vanilla worms")

-- Invalid placement must not reserve a planet slot or suppress vanilla.
data.raw["unit-spawner"]["armoured-biter-spawner"] = {autoplace = {}}
router.add_entities_to_planet("test-world", {"armoured-biter-spawner", "missing-mod-spawner"},
	"enemy-base")
local settings_map = p.map_gen_settings.autoplace_settings.entity.settings
check(settings_map["armoured-biter-spawner"] == nil, "Invalid spawner was placed")
check(settings_map["biter-spawner"].frequency == 1, "Invalid spawner suppressed vanilla")
check(router.remove_invalid_autoplace("unit-spawner", "armoured-biter-spawner"),
	"Malformed fork definition was not repaired")
check(data.raw["unit-spawner"]["armoured-biter-spawner"].autoplace == nil,
	"Malformed autoplace was not removed")

data.raw["unit-spawner"]["armoured-biter-spawner"].autoplace = {
	probability_expression = "enemy_spawner"
}
router.add_entities_to_planet("test-world", {"armoured-biter-spawner", "missing-mod-spawner"},
	"enemy-base")
check(settings_map["armoured-biter-spawner"] ~= nil, "Valid custom spawner not installed")
check(settings_map["biter-spawner"].frequency == 1, "Additive specialists must not suppress native biters")
check(settings_map["small-worm-turret"].frequency == 1, "Additive specialists must not suppress native worms")

router = setup()
local mock_settings = rawget(_G, "settings")
mock_settings.startup["razi-enable-enemy-routing"].value = false
local second = data.raw.planet["test-world"]
data.raw["unit-spawner"]["armoured-biter-spawner"] = {autoplace = {}}
router.add_entities_to_planet("test-world", {"armoured-biter-spawner"}, "enemy-base")
check(second.pollutant_type == nil, "Disabled enemy routing still mutated planet")
check(second.map_gen_settings.autoplace_settings.entity.settings["biter-spawner"].frequency == 1,
	"Disabled enemy routing removed vanilla spawn")

-- Regression for the actual ArmouredBiters21Compat 2.0.6 stack.
-- The fork may spawn armoured units via vanilla nests instead of giving
-- its dedicated nest a valid natural autoplace specification.
router = setup()
rawset(_G, "mods", {ArmouredBiters21Compat = "2.0.6"})
data.raw.planet.hyarion = planet()
local vanilla = data.raw["unit-spawner"]["biter-spawner"]
vanilla.result_units = {
	{"small-armoured-biter", {{0, 1}}},
	{"small-biter", {{0, 1}}}
}
local dedicated = {autoplace = {}}
data.raw["unit-spawner"]["armoured-biter-spawner"] = dedicated
package.loaded["prototypes.compat.armoured_biters"] = nil
require("prototypes.compat.armoured_biters")
check(vanilla.result_units[1][1] == "small-armoured-biter",
	"An invalid dedicated nest removed source armoured units from vanilla")
check(data.raw.planet.hyarion.map_gen_settings.autoplace_settings.entity.settings["armoured-biter-spawner"] == nil,
	"An invalid dedicated nest was added to Hyarion")
router.repair_optional_enemy_autoplace()
check(dedicated.autoplace == nil, "Final repair did not strip broken armoured autoplace")

router = setup()
rawset(_G, "mods", {ArmouredBiters21Compat = "2.0.6"})
data.raw.planet.hyarion = planet()
vanilla = data.raw["unit-spawner"]["biter-spawner"]
vanilla.result_units = {
	{"small-armoured-biter", {{0, 1}}},
	{"small-biter", {{0, 1}}}
}
dedicated = {autoplace = {probability_expression = "enemy_spawner"}}
data.raw["unit-spawner"]["armoured-biter-spawner"] = dedicated
package.loaded["prototypes.compat.armoured_biters"] = nil
require("prototypes.compat.armoured_biters")
check(#vanilla.result_units == 1 and vanilla.result_units[1][1] == "small-biter",
	"Valid dedicated nest must avoid double-spawning armoured units")
check(data.raw.planet.hyarion.map_gen_settings.autoplace_settings.entity.settings["armoured-biter-spawner"] == nil,
	"Early Armoured Biters integration must defer extra worlds to the final ecology pass")
check(dedicated.autoplace.probability_expression == "enemy_spawner",
	"Valid source noise expression was changed")

print("Optional enemy routing fixtures passed")
