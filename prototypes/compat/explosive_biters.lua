local explosive_enemy_control = "hot_enemy_base"

local explosive_enemy_entities = {
	"explosive-biter-spawner",
	"small-explosive-worm-turret",
	"medium-explosive-worm-turret",
	"big-explosive-worm-turret",
	"behemoth-explosive-worm-turret",
	"leviathan-explosive-worm-turret",
	"mother-explosive-worm-turret"
}

local explosive_planet_tiles = {
	"moshine-rock",
	"moshine-hot-swamp",
	"moshine-lava",
	"moshine-dust",
	"moshine-sand",
	"moshine-dunes",
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

local function restrict_entity_to_explosive_tiles(entity_type, entity_name)
	local entity = data.raw[entity_type] and data.raw[entity_type][entity_name]
	if entity and entity.autoplace then
		entity.autoplace.tile_restriction = explosive_planet_tiles
	end
end

local function remove_explosive_enemies_from_planet(planet_name)
	local planet = data.raw.planet[planet_name]
	local map_gen_settings = planet and planet.map_gen_settings
	if not map_gen_settings then
		return
	end

	if map_gen_settings.autoplace_controls then
		map_gen_settings.autoplace_controls[explosive_enemy_control] = nil
	end

	local entity_settings = map_gen_settings.autoplace_settings
		and map_gen_settings.autoplace_settings.entity
		and map_gen_settings.autoplace_settings.entity.settings

	if not entity_settings then
		return
	end

	for _, entity_name in pairs(explosive_enemy_entities) do
		entity_settings[entity_name] = nil
	end
end

local function add_explosive_enemies_to_planet(planet_name)
	local planet = data.raw.planet[planet_name]
	local map_gen_settings = planet and planet.map_gen_settings
	if not map_gen_settings then
		return
	end

	planet.pollutant_type = planet.pollutant_type or "pollution"
	map_gen_settings.autoplace_controls = map_gen_settings.autoplace_controls or {}
	map_gen_settings.autoplace_controls[explosive_enemy_control] = {
		frequency = 1,
		size = 1,
		richness = 1
	}

	map_gen_settings.autoplace_settings = map_gen_settings.autoplace_settings or {}
	map_gen_settings.autoplace_settings.entity = map_gen_settings.autoplace_settings.entity or {}
	map_gen_settings.autoplace_settings.entity.settings = map_gen_settings.autoplace_settings.entity.settings or {}

	for _, entity_name in pairs(explosive_enemy_entities) do
		map_gen_settings.autoplace_settings.entity.settings[entity_name] = {}
	end
end

restrict_entity_to_explosive_tiles("unit-spawner", "explosive-biter-spawner")
restrict_entity_to_explosive_tiles("turret", "small-explosive-worm-turret")
restrict_entity_to_explosive_tiles("turret", "medium-explosive-worm-turret")
restrict_entity_to_explosive_tiles("turret", "big-explosive-worm-turret")
restrict_entity_to_explosive_tiles("turret", "behemoth-explosive-worm-turret")
restrict_entity_to_explosive_tiles("turret", "leviathan-explosive-worm-turret")
restrict_entity_to_explosive_tiles("turret", "mother-explosive-worm-turret")

remove_explosive_enemies_from_planet("nauvis")
remove_explosive_enemies_from_planet("vulcanus")

add_explosive_enemies_to_planet("moshine")
add_explosive_enemies_to_planet("nexus")
