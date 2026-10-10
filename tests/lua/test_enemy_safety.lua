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

data.raw["unit-spawner"]["armoured-biter-spawner"] = {autoplace = {}}
router.add_entities_to_planet("test-world", {"armoured-biter-spawner", "missing-mod-spawner"},
	"enemy-base")
local settings_map = p.map_gen_settings.autoplace_settings.entity.settings
check(settings_map["armoured-biter-spawner"] ~= nil, "Custom spawner not installed")
check(settings_map["biter-spawner"].frequency == 0, "Vanilla spawner not suppressed")
check(settings_map["small-worm-turret"].frequency == 0, "Vanilla worm not suppressed")

router = setup()
local mock_settings = rawget(_G, "settings")
mock_settings.startup["razi-enable-enemy-routing"].value = false
local second = data.raw.planet["test-world"]
data.raw["unit-spawner"]["armoured-biter-spawner"] = {autoplace = {}}
router.add_entities_to_planet("test-world", {"armoured-biter-spawner"}, "enemy-base")
check(second.pollutant_type == nil, "Disabled enemy routing still mutated planet")
check(second.map_gen_settings.autoplace_settings.entity.settings["biter-spawner"].frequency == 1,
	"Disabled enemy routing removed vanilla spawn")

print("Optional enemy routing fixtures passed")
