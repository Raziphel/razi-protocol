local enemy_autoplace = require("prototypes.compat.enemy_autoplace")

if not mods["Electric_flying_enemies"] then
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
	"fulgoran-enemy-spawner",
	"fulgoran-replicator",
	"fulgoran-unit-replicator",
	"electric-flying-enemy-spawner",
	"electric-flying-enemies-spawner",
	"electric-enemy-spawner",
	"unit-replicator"
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

local function existing_tiles(tile_names)
	local tiles = {}
	for _, tile_name in pairs(tile_names) do
		if data.raw.tile and data.raw.tile[tile_name] then
			table.insert(tiles, tile_name)
		end
	end

	return tiles
end

local function extend_tile_restriction(spawner)
	spawner.autoplace = spawner.autoplace or {}
	spawner.autoplace.tile_restriction = spawner.autoplace.tile_restriction or {}

	for _, tile_name in pairs(existing_tiles(electric_enemy_tiles)) do
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

	local planet = data.raw.planet and data.raw.planet[planet_name]
	local map_gen_settings = planet and planet.map_gen_settings
	if not map_gen_settings then
		return
	end

	planet.pollutant_type = planet.pollutant_type or "pollution"
	enemy_autoplace.disable_vanilla_enemies_on_planet(planet_name)

	map_gen_settings.autoplace_controls = map_gen_settings.autoplace_controls or {}
	map_gen_settings.autoplace_settings = map_gen_settings.autoplace_settings or {}
	map_gen_settings.autoplace_settings.entity = map_gen_settings.autoplace_settings.entity or {}
	map_gen_settings.autoplace_settings.entity.settings = map_gen_settings.autoplace_settings.entity.settings or {}

	for entity_name, spawner in pairs(spawners) do
		local control = spawner.autoplace and spawner.autoplace.control or "enemy-base"
		map_gen_settings.autoplace_controls[control] = {
			frequency = 1,
			size = 1,
			richness = 1
		}
		map_gen_settings.autoplace_settings.entity.settings[entity_name] = {}
	end
end

local electric_spawners = collect_electric_spawners()

for _, spawner in pairs(electric_spawners) do
	extend_tile_restriction(spawner)
end

add_electric_enemies_to_planet("corrundum", electric_spawners)
add_electric_enemies_to_planet("nexus", electric_spawners)
