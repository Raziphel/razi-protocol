package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local function count_conditions(conditions, property)
	local count = 0
	for _, condition in pairs(conditions or {}) do
		if condition.property == property then
			count = count + 1
		end
	end
	return count
end

local function find_condition(conditions, property)
	for _, condition in pairs(conditions or {}) do
		if condition.property == property then
			return condition
		end
	end
end

local function make_world(options)
	options = options or {}
	local planets = {}
	if not options.no_planet then
		planets.nauvis = {
			surface_properties = options.no_planet_str and {} or { ["planet-str"] = 126896796164462 },
		}
	end
	local raw = {
		planet = planets,
		["assembling-machine"] = {
			el_purifier = {
				crafting_categories = { "el_purifier_category" },
				surface_conditions = { { property = "pressure", min = 5 } },
			},
			["bioluminescent-el_purifier"] = { crafting_categories = { "el_purifier_category" } },
			["harene-infused-el_purifier"] = {
				crafting_categories = { "el_purifier_category" },
				surface_conditions = { { property = "pressure", min = 1 } },
			},
			unrelated_assembler = { crafting_categories = { "crafting" } },
		},
		roboport = {
			fi_robo_port = { surface_conditions = { { property = "pressure", max = 50000 } } },
			fi_robo_charger = {},
			["bioluminescent-fi_robo_port"] = {
				surface_conditions = { { property = "pressure", min = 7, max = 50000 } },
			},
			fi_robo_x = { surface_conditions = { { property = "pressure", min = 10 } } },
			["harene-infused-fi_robo_charger"] = {
				surface_conditions = { { property = "pressure", min = 0, max = 50000 } },
			},
			roboport = { surface_conditions = { { property = "pressure", min = 5 } } },
		},
		recipe = {
			["gr_white_hole_cycle_iron-plate_recipe"] = { enabled = true, hidden = false },
			gr_white = { enabled = false, hidden = false },
		},
		technology = {
			first = { effects = {
				{ type = "unlock-recipe", recipe = "gr_white_hole_cycle_iron-plate_recipe" },
				{ type = "unlock-recipe", recipe = "gr_white" },
				{ type = "unlock-space-location", space_location = "nauvis" },
			} },
			second = { effects = {
				{ type = "unlock-recipe", recipe = "gr_white_hole_cycle_copper-plate_recipe" },
			} },
		},
	}
	local logs = {}
	rawset(_G, "data", { raw = raw })
	rawset(_G, "mods", options.no_mod and {} or { ["248k-Redux"] = "2.1.51" })
	rawset(_G, "log", function(message)
		logs[#logs + 1] = message
	end)
	package.loaded["prototypes.compatibility.248k-Redux.purifier_nauvis"] = nil
	package.loaded["prototypes.compatibility.248k-Redux.robo_ports"] = nil
	package.loaded["prototypes.compatibility.248k-Redux.white_hole"] = nil
	return { raw = raw, logs = logs }
end

local purifier = require("prototypes.compatibility.248k-Redux.purifier_nauvis")
local robo_ports = require("prototypes.compatibility.248k-Redux.robo_ports")
local white_hole = require("prototypes.compatibility.248k-Redux.white_hole")

-- Purifier machines receive Nauvis's exact planet-str and keep other conditions.
local world = make_world()
purifier.data_final_fixes()
local machines = world.raw["assembling-machine"]
local el_condition = find_condition(machines.el_purifier.surface_conditions, "planet-str")
check(el_condition and el_condition.min == 126896796164462 and el_condition.max == 126896796164462,
	"el_purifier is restricted to Nauvis")
check(count_conditions(machines.el_purifier.surface_conditions, "pressure") == 1, "existing purifier conditions stay")
check(find_condition(machines["harene-infused-el_purifier"].surface_conditions, "planet-str") ~= nil,
	"harene purifier copy is restricted to Nauvis")
check(find_condition(machines["bioluminescent-el_purifier"].surface_conditions, "planet-str") ~= nil,
	"bioluminescent purifier copy is restricted to Nauvis")
check(count_conditions(machines.unrelated_assembler.surface_conditions, "planet-str") == 0,
	"assembler without the purifier category is unchanged")
purifier.data_final_fixes()
for _, name in ipairs({ "el_purifier", "bioluminescent-el_purifier", "harene-infused-el_purifier" }) do
	check(count_conditions(machines[name].surface_conditions, "planet-str") == 1, name .. " has one Nauvis condition")
end

-- Without a Nauvis planet-str, leave the purifier prototypes untouched.
world = make_world({ no_planet_str = true })
purifier.data_final_fixes()
check(count_conditions(world.raw["assembling-machine"].el_purifier.surface_conditions, "planet-str") == 0,
	"purifiers stay unchanged when Nauvis has no planet-str")
check(world.logs[1] == "razi-protocol: 248k: purifiers left as is, Nauvis has no planet-str",
	"missing Nauvis planet-str is logged")
world = make_world({ no_planet = true })
purifier.data_final_fixes()
check(count_conditions(world.raw["assembling-machine"].el_purifier.surface_conditions, "planet-str") == 0,
	"purifiers stay unchanged when Nauvis is absent")

-- Every 248k roboport is kept off zero-pressure platforms; other roboports stay unchanged.
world = make_world()
robo_ports.data_final_fixes()
local roboports = world.raw.roboport
local port_pressure = find_condition(roboports.fi_robo_port.surface_conditions, "pressure")
check(port_pressure and port_pressure.min == 5 and port_pressure.max == 50000,
	"fi_robo_port gets minimum pressure without changing its maximum")
local charger_pressure = find_condition(roboports.fi_robo_charger.surface_conditions, "pressure")
check(charger_pressure and charger_pressure.min == 5 and charger_pressure.max == nil,
	"fi_robo_charger gets a pressure condition")
check(find_condition(roboports["bioluminescent-fi_robo_port"].surface_conditions, "pressure").min == 7,
	"existing pressure minimum above 5 stays")
check(find_condition(roboports.fi_robo_x.surface_conditions, "pressure").min == 10,
	"fi_robo_x with pressure minimum 10 stays unchanged")
local infused_pressure = find_condition(roboports["harene-infused-fi_robo_charger"].surface_conditions, "pressure")
check(infused_pressure.min == 5 and infused_pressure.max == 50000, "copy pressure minimum is raised to 5")
check(roboports.roboport.surface_conditions[1].min == 5, "generic roboport stays unchanged")
check(#world.logs == 3, "only modified 248k roboports are logged")
for _, message in ipairs(world.logs) do
	check(not message:find("fi_robo_x", 1, true), "unchanged fi_robo_x is not logged")
end

-- Disable every generated white-hole cycle recipe and remove its unlock effects.
world = make_world()
white_hole.data_final_fixes()
local recipes = world.raw.recipe
check(recipes["gr_white_hole_cycle_iron-plate_recipe"].enabled == false
	and recipes["gr_white_hole_cycle_iron-plate_recipe"].hidden == true,
	"white-hole cycle recipe is disabled and hidden")
check(recipes.gr_white.enabled == false and recipes.gr_white.hidden == false, "gr_white recipe stays unchanged")
local first_effects = world.raw.technology.first.effects
check(#first_effects == 2 and first_effects[1].recipe == "gr_white"
	and first_effects[2].type == "unlock-space-location", "only the cycle unlock is removed")
check(#world.raw.technology.second.effects == 0, "cycle unlocks are removed from every technology")
check(world.logs[1] == "razi-protocol: 248k: disabled 1 white-hole cycle recipes and removed 2 unlocks",
	"white-hole recipe and unlock counts are logged")

-- All three passes are inert when 248k is absent.
world = make_world({ no_mod = true })
purifier.data_final_fixes()
robo_ports.data_final_fixes()
white_hole.data_final_fixes()
check(count_conditions(world.raw["assembling-machine"].el_purifier.surface_conditions, "planet-str") == 0,
	"no-mod purifier stays unchanged")
local no_mod_roboports = world.raw.roboport
local no_mod_recipes = world.raw.recipe
local no_mod_effects = world.raw.technology.first.effects
check(no_mod_roboports.fi_robo_charger.surface_conditions == nil, "no-mod roboport stays unchanged")
check(no_mod_recipes["gr_white_hole_cycle_iron-plate_recipe"].enabled == true
	and no_mod_recipes["gr_white_hole_cycle_iron-plate_recipe"].hidden == false,
	"no-mod white-hole recipe stays unchanged")
check(#no_mod_effects == 3 and #world.logs == 0,
	"no-mod technology effects and logs stay unchanged")

print("test_248k_surfaces: ok")
