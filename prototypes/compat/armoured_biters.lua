local enemy_autoplace = require("prototypes.compat.enemy_autoplace")

-- ArmouredBiters21Compat is the 2.1 fork of Armoured Biters with the same prototype names.
if not enemy_autoplace.enabled() or not (mods["ArmouredBiters"] or mods["ArmouredBiters21Compat"]) then
	return
end

local armoured_biter_units = {
	["small-armoured-biter"] = true,
	["medium-armoured-biter"] = true,
	["big-armoured-biter"] = true,
	["behemoth-armoured-biter"] = true,
	["leviathan-armoured-biter"] = true
}

local armoured_planets = {
	"panglia",
	"hyarion",
	"nexus",
	"crucible"
}

local armoured_enemy_entities = {
	"armoured-biter-spawner"
}

local armoured_biter_tiles = {
	"panglia-volcanic-soil-dark",
	"panglia-volcanic-soil-light",
	"panglia-volcanic-ash-soil",
	"panglia-volcanic-ash-flats",
	"panglia-volcanic-ash-light",
	"panglia-volcanic-ash-dark",
	"panglia-volcanic-cracks",
	"panglia-volcanic-cracks-warm",
	"panglia-volcanic-folds",
	"panglia-volcanic-folds-flat",
	"panglia-volcanic-folds-warm",
	"panglia-volcanic-pumice-stones",
	"panglia-volcanic-cracks-hot",
	"panglia-volcanic-jagged-ground",
	"panglia-volcanic-smooth-stone",
	"panglia-volcanic-smooth-stone-warm",
	"panglia-volcanic-ash-cracks",
	"panglia-midland-turquoise-bark",
	"panglia-midland-turquoise-bark-2",
	"panglia-wetland-light-dead-skin",
	"panglia-wetland-dead-skin",
	"panglia-midland-cracked-lichen-dark",
	"hyarion-jagged-ground",
	"hyarion-cracks-hot",
	"hyarion-cracks-warm",
	"hyarion-cracks",
	"hyarion-folds-flat",
	"hyarion-crystal-light",
	"hyarion-crystal-dark",
	"hyarion-crystal-flats",
	"hyarion-pumice-stones",
	"hyarion-smooth-stone",
	"hyarion-smooth-stone-warm",
	"hyarion-crystal-cracks",
	"hyarion-folds",
	"hyarion-folds-warm",
	"hyarion-soil-dark",
	"hyarion-soil-light",
	"hyarion-crystal-soil",
	"volcanic-soil-dark",
	"volcanic-soil-light",
	"volcanic-ash-soil",
	"volcanic-ash-flats",
	"volcanic-ash-light",
	"volcanic-ash-dark",
	"volcanic-cracks",
	"volcanic-cracks-warm",
	"volcanic-folds",
	"volcanic-folds-flat",
	"volcanic-folds-warm",
	"volcanic-pumice-stones",
	"volcanic-cracks-hot",
	"volcanic-jagged-ground",
	"volcanic-smooth-stone",
	"volcanic-smooth-stone-warm",
	"volcanic-ash-cracks",
	"planet-crucible-dirt-1",
	"planet-crucible-dirt-2",
	"planet-crucible-dirt-3",
	"planet-crucible-dirt-4",
	"planet-crucible-rock-1",
	"planet-crucible-rock-2",
	"planet-crucible-rock-3",
	"planet-crucible-rock-4",
	"planet-crucible-sand-1"
}

local function remove_armoured_units_from_spawner(spawner)
	if not spawner or not spawner.result_units then
		return
	end

	local result_units = {}
	for _, result_unit in pairs(spawner.result_units) do
		if not armoured_biter_units[result_unit[1]] then
			table.insert(result_units, result_unit)
		end
	end

	spawner.result_units = result_units
end

local function armoured_spawner_exists(entity_name)
	return enemy_autoplace.entity_exists("unit-spawner", entity_name)
end

local armoured_spawner = enemy_autoplace.entity_exists("unit-spawner", "armoured-biter-spawner")

remove_armoured_units_from_spawner(enemy_autoplace.entity_exists("unit-spawner", "biter-spawner"))

if armoured_spawner then
	armoured_spawner.autoplace = armoured_spawner.autoplace or {}
	armoured_spawner.autoplace.tile_restriction = enemy_autoplace.existing_tiles(armoured_biter_tiles)

	for _, planet_name in pairs(armoured_planets) do
		enemy_autoplace.add_entities_to_planet(planet_name, armoured_enemy_entities, "enemy-base", armoured_spawner_exists)
	end
end
