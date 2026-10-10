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

local electric_enemy_tiles = {
	"fulgoran-dust",
	"fulgoran-rock",
	"fulgoran-conduit",
	"fulgoran-machinery",
	"oil-ocean-shallow",
	"oil-ocean-deep",
	"fulgoran-space-platform",
	"ribbonia-gap",
	"ribbonia-water",
	"ribbonia-void",
	"dirt-1",
	"dirt-2",
	"dirt-3",
	"dirt-4",
	"dirt-5",
	"dirt-6",
	"dirt-7",
	"grass-1",
	"grass-2",
	"grass-3",
	"grass-4",
	"red-desert-0",
	"red-desert-1",
	"red-desert-2",
	"red-desert-3",
	"dry-dirt",
	"sand-1",
	"sand-2",
	"sand-3",
	"corrundum-dunes",
	"corrundum-sand",
	"petroleum-tile",
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
	"volcanic-ash-cracks"
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

local function add_unique(values, value)
	for _, existing in pairs(values) do
		if existing == value then
			return
		end
	end

	table.insert(values, value)
end

local function extend_tile_restriction(spawner)
	spawner.autoplace = spawner.autoplace or {}
	spawner.autoplace.tile_restriction = spawner.autoplace.tile_restriction or {}

	for _, tile_name in pairs(enemy_autoplace.existing_tiles(electric_enemy_tiles)) do
		add_unique(spawner.autoplace.tile_restriction, tile_name)
	end
end

local function collect_electric_spawners()
	local spawners = {}

	for _, entity_name in pairs(explicit_electric_spawners) do
		local spawner = entity_exists(entity_name)
		if spawner then
			spawners[entity_name] = spawner
		end
	end

	for entity_name, spawner in pairs(data.raw["unit-spawner"] or {}) do
		if name_matches_electric_enemy(entity_name) and spawner.autoplace then
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

for _, spawner in pairs(electric_spawners) do
	extend_tile_restriction(spawner)
end

for _, planet_name in pairs(electric_planets) do
	add_electric_enemies_to_planet(planet_name, electric_spawners)
end
