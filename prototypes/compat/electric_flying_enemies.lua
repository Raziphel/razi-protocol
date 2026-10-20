local enemy_autoplace = require("prototypes.compat.enemy_autoplace")

if not enemy_autoplace.enabled() or not mods["Electric_flying_enemies"] then
	return
end

local electric_enemy_name_patterns = {
	"fulgora",
	"fulgoran",
	"electric",
	"replicator",
	"walker",
	"droid"
}

local explicit_electric_spawners = {
	"flying-electric-unit-spawner",
	"walker-electric-unit-spawner",
	"fulgoran-enemy-spawner",
	"fulgoran-replicator",
	"fulgoran-unit-replicator",
	"electric-flying-enemy-spawner",
	"electric-flying-enemies-spawner",
	"electric-enemy-spawner",
	"unit-replicator"
}

local electric_planets = {
	"corrundum",
	"ribbonia",
	"nexus"
}

local function entity_exists(entity_name)
	return data.raw["unit-spawner"] and data.raw["unit-spawner"][entity_name]
end

local function name_matches_electric_enemy(name)
	for _, pattern in pairs(electric_enemy_name_patterns) do
		if name:find(pattern, 1, true) then
			return true
		end
	end

	return false
end

local function collect_electric_spawners()
	local spawners = {}

	for _, entity_name in pairs(explicit_electric_spawners) do
		local spawner = entity_exists(entity_name)
		if enemy_autoplace.has_valid_autoplace(spawner) then
			spawners[entity_name] = spawner
		end
	end

	for entity_name, spawner in pairs(data.raw["unit-spawner"] or {}) do
		if name_matches_electric_enemy(entity_name)
			and enemy_autoplace.has_valid_autoplace(spawner) then
			spawners[entity_name] = spawner
		end
	end

	return spawners
end

local function add_electric_enemies_to_planet(planet_name, spawners)
	if not next(spawners) then
		return
	end

	for entity_name, spawner in pairs(spawners) do
		local control = spawner.autoplace and spawner.autoplace.control or "enemy-base"
		local entity_settings = enemy_autoplace.prepare_custom_enemy_planet(planet_name, control)
		if entity_settings then
			entity_settings[entity_name] = {}
		end
	end
end

local electric_spawners = collect_electric_spawners()

-- Planet-local nests are generated in the final ecology pass.
-- Do not append a union of unrelated terrain to the shared source nest.

for _, planet_name in pairs(electric_planets) do
	add_electric_enemies_to_planet(planet_name, electric_spawners)
end
