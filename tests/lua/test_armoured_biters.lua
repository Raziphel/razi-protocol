-- Armoured Biters placement (compat/armoured_biters.lua) and Hyarion's pollution absorption (compat/enemy_planet_pollution.lua)
-- with each of the three Armoured Biters mods, on a mocked data.raw.
-- Run from the mod root:
--   lua5.2 tests/lua/test_armoured_biters.lua
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

local function setup(active_mods)
	package.loaded["prototypes.compat.armoured_biters"] = nil
	package.loaded["prototypes.compat.enemy_autoplace"] = nil
	package.loaded["prototypes.compat.enemy_planet_pollution"] = nil
	rawset(_G, "mods", active_mods)
	rawset(_G, "settings", {startup = {}})
	rawset(_G, "data", {raw = {
		["unit-spawner"] = {
			["biter-spawner"] = {
				type = "unit-spawner", name = "biter-spawner", autoplace = {probability_expression = "x"},
				result_units = {{"small-biter", {{0, 1}}}, {"small-armoured-biter", {{0.2, 1}}}, {"medium-biter", {{0.2, 1}}}},
			},
			["armoured-biter-spawner"] = {
				type = "unit-spawner", name = "armoured-biter-spawner", autoplace = {probability_expression = "y"},
			},
		},
		tile = {
			["volcanic-soil-dark"] = {type = "tile", name = "volcanic-soil-dark", absorptions_per_second = {pollution = 0.00001}},
			["hyarion-soil-dark"] = {type = "tile", name = "hyarion-soil-dark"},
			["sand-1"] = {type = "tile", name = "sand-1"},
		},
		planet = {
			hyarion = {type = "planet", name = "hyarion", map_gen_settings = {
				autoplace_controls = {}, autoplace_settings = {tile = {settings = {["hyarion-soil-dark"] = {}}}}}},
			nauvis = {type = "planet", name = "nauvis", map_gen_settings = {autoplace_controls = {["enemy-base"] = {}}}},
		},
	}})
end

local function placed_on(planet_name)
	local planet = data.raw.planet[planet_name] --[[@as table]]
	local entity_settings = planet.map_gen_settings.autoplace_settings --[[@as table]]
	return entity_settings and entity_settings.entity and entity_settings.entity.settings
		and entity_settings.entity.settings["armoured-biter-spawner"]
end

-- Each of the three mods sets the nest on Hyarion and takes the armoured units out of the vanilla nest.
for _, mod_name in ipairs({"ArmouredBiters", "ArmouredBiters21Compat", "ArmouredBiters-2_1-update"}) do
	setup({[mod_name] = "1.0.0"})
	require("prototypes.compat.armoured_biters")
	check(placed_on("hyarion") ~= nil, mod_name .. ": the armoured nest is placed on Hyarion")
	check(placed_on("nauvis") == nil, mod_name .. ": the armoured nest is not placed on Nauvis")
	local units = data.raw["unit-spawner"]["biter-spawner"].result_units
	check(#units == 2 and units[1][1] == "small-biter" and units[2][1] == "medium-biter",
		mod_name .. ": armoured units leave the vanilla nest")
	local nest = data.raw["unit-spawner"]["armoured-biter-spawner"] --[[@as table]]
	local restriction = nest.autoplace.tile_restriction
	check(restriction and #restriction == 2, mod_name .. ": the nest is restricted to the tiles that exist")

	require("prototypes.compat.enemy_planet_pollution").data_final_fixes()
	local absorptions = data.raw.tile["hyarion-soil-dark"].absorptions_per_second
	check(absorptions and absorptions.pollution == 0.00001, mod_name .. ": Hyarion's tiles absorb pollution")
end

-- None of them: nothing is touched.
setup({})
require("prototypes.compat.armoured_biters")
check(placed_on("hyarion") == nil, "no Armoured Biters mod, no nest")
check(#data.raw["unit-spawner"]["biter-spawner"].result_units == 3, "no Armoured Biters mod, the vanilla nest stays")
require("prototypes.compat.enemy_planet_pollution").data_final_fixes()
check(data.raw.tile["hyarion-soil-dark"].absorptions_per_second == nil, "no Armoured Biters mod, tiles stay")

-- Enemy routing off: nothing is touched.
setup({["ArmouredBiters-2_1-update"] = "2.0.4"})
settings.startup["razi-enable-enemy-routing"] = {value = false} -- luacheck: ignore 122
require("prototypes.compat.armoured_biters")
check(placed_on("hyarion") == nil, "routing off, no nest")

-- Armoured Biters with the dedicated nest off (no armoured-biter-spawner): the vanilla nest keeps its armoured units.
setup({["ArmouredBiters-2_1-update"] = "2.0.4"})
data.raw["unit-spawner"]["armoured-biter-spawner"] = nil
require("prototypes.compat.armoured_biters")
check(placed_on("hyarion") == nil, "no dedicated nest, nothing placed")
check(#data.raw["unit-spawner"]["biter-spawner"].result_units == 3, "no dedicated nest, the vanilla nest keeps its units")

rawset(_G, "mods", nil)
rawset(_G, "settings", nil)
rawset(_G, "data", nil)
print("armoured_biters: ok")
