local enemy_autoplace = require("prototypes.compat.enemy_autoplace")
local enemy_homes = require("prototypes.compat.enemy_homes")
local nest_names = require("prototypes.compat.enemy_nest_names")

-- ArmouredBiters21Compat and ArmouredBiters-2_1-update (the one Balack requires) are 2.1 forks of Armoured Biters with
-- the same prototype names; with both installed the one that loads last owns them.
local armoured_biter_mods = {"ArmouredBiters", "ArmouredBiters21Compat", "ArmouredBiters-2_1-update"}

local function armoured_biters_installed()
	for _, mod_name in ipairs(armoured_biter_mods) do
		if mods[mod_name] then
			return true
		end
	end

	return false
end

if not enemy_autoplace.enabled() or not armoured_biters_installed() then
	return
end

local armoured_biter_units = {
	["small-armoured-biter"] = true,
	["medium-armoured-biter"] = true,
	["big-armoured-biter"] = true,
	["behemoth-armoured-biter"] = true,
	["leviathan-armoured-biter"] = true
}

local armoured_enemy_entities = nest_names.armoured

local function remove_armoured_units_from_spawner(spawner)
	if not spawner or not spawner.result_units then
		return
	end

	local result_units = {}
	for _, result_unit in pairs(spawner.result_units) do
		if not armoured_biter_units[result_unit.unit or result_unit[1]] then
			table.insert(result_units, result_unit)
		end
	end

	spawner.result_units = result_units
end

local function armoured_spawner_exists(entity_name)
	return enemy_autoplace.entity_exists("unit-spawner", entity_name)
end

local armoured_spawner = enemy_autoplace.entity_exists("unit-spawner", "armoured-biter-spawner")

-- Only move armoured units out of the normal nests when the mod really
-- defines a naturally placeable dedicated nest. With its nest setting off
-- they are meant to come out of the vanilla biter-spawner.
if enemy_autoplace.has_valid_autoplace(armoured_spawner) then
	remove_armoured_units_from_spawner(enemy_autoplace.entity_exists("unit-spawner", "biter-spawner"))
	armoured_spawner.autoplace.tile_restriction = enemy_homes.tiles("armoured")

	enemy_homes.claim("armoured", armoured_enemy_entities)
	for _, planet_name in pairs(enemy_homes.planets("armoured")) do
		enemy_autoplace.add_entities_to_planet(planet_name, armoured_enemy_entities, "enemy-base", armoured_spawner_exists)
	end
end
