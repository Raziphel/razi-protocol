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
	"hyarion",
	"nexus",
	"crucible",
	"castra",
	"athos"
}

local armoured_enemy_entities = {
	"armoured-biter-spawner"
}

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

-- Only separate armoured units from normal nests when the fork really
-- defines a naturally placeable dedicated nest. Otherwise they continue
-- to appear via the original biter-spawner result_units. Creating
-- autoplace={} on the dedicated nest breaks Factorio 2.1 validation.
if enemy_autoplace.has_valid_autoplace(armoured_spawner) then
	remove_armoured_units_from_spawner(enemy_autoplace.entity_exists("unit-spawner", "biter-spawner"))
	-- Keep source-owned tile restrictions unchanged. Final RP3 placement
	-- creates planet-local spawner variants for new habitats.
	for _, planet_name in pairs(armoured_planets) do
		enemy_autoplace.add_entities_to_planet(planet_name, armoured_enemy_entities, "enemy-base", armoured_spawner_exists)
	end
end
