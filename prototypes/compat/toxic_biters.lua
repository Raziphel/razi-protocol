local toxic_enemy_control = "enemy-base"

local toxic_enemy_entities = {
	"toxic-biter-spawner",
	"small-toxic-worm-turret",
	"medium-toxic-worm-turret",
	"big-toxic-worm-turret",
	"behemoth-toxic-worm-turret",
	"leviathan-toxic-worm-turret",
	"mother-toxic-worm-turret"
}

local toxic_planets = {
	"cubium",
	"vesta",
	"nexus"
}

local toxic_planet_tiles = {
	"cubium-volcanic-cracks-hot",
	"cubium-volcanic-jagged-ground",
	"cubium-lava",
	"cubium-lava-hot",
	"cubium-volcanic-cracks-warm",
	"cubium-volcanic-cracks",
	"cubium-volcanic-folds-flat",
	"cubium-volcanic-ash-light",
	"cubium-volcanic-ash-dark",
	"cubium-volcanic-ash-flats",
	"cubium-volcanic-pumice-stones",
	"cubium-volcanic-smooth-stone",
	"cubium-smooth-stone-warm",
	"cubium-ash-cracks",
	"cubium-folds",
	"cubium-folds-warm",
	"cubium-soil-dark",
	"cubium-soil-light",
	"cubium-ash-soil",
	"dust-flat-vesta",
	"dust-crests-vesta",
	"dust-lumpy-vesta",
	"dust-patchy-vesta",
	"ice-rough-vesta",
	"ice-smooth-vesta",
	"brash-ice-2-vesta",
	"ammoniacal-ocean-vesta-yellow",
	"ammoniacal-ocean-vesta-pink",
	"ammoniacal-ocean-vesta-lime",
	"ammoniacal-ocean-vesta-red",
	"ammoniacal-ocean-vesta-yellow-ransom",
	"ammoniacal-ocean-vesta-red-ransom",
	"ammoniacal-ocean-vesta-lime-coast",
	"ammoniacal-ocean-vesta-tritium",
	"ammoniacal-ocean-vesta-deuterium",
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

local function existing_tiles(tile_names)
	local tiles = {}
	for _, tile_name in pairs(tile_names) do
		if data.raw.tile[tile_name] then
			table.insert(tiles, tile_name)
		end
	end

	return tiles
end

local existing_toxic_planet_tiles = existing_tiles(toxic_planet_tiles)

local function restrict_entity_to_toxic_tiles(entity_type, entity_name)
	local entity = data.raw[entity_type] and data.raw[entity_type][entity_name]
	if entity and entity.autoplace then
		entity.autoplace.tile_restriction = existing_toxic_planet_tiles
	end
end

local function toxic_entity_exists(entity_name)
	return
		(data.raw["unit-spawner"] and data.raw["unit-spawner"][entity_name]) or
		(data.raw.turret and data.raw.turret[entity_name])
end

local function remove_toxic_enemies_from_planet(planet_name)
	local planet = data.raw.planet[planet_name]
	local map_gen_settings = planet and planet.map_gen_settings
	if not map_gen_settings then
		return
	end

	local entity_settings = map_gen_settings.autoplace_settings
		and map_gen_settings.autoplace_settings.entity
		and map_gen_settings.autoplace_settings.entity.settings

	if not entity_settings then
		return
	end

	for _, entity_name in pairs(toxic_enemy_entities) do
		entity_settings[entity_name] = nil
	end
end

local function add_toxic_enemies_to_planet(planet_name)
	local planet = data.raw.planet[planet_name]
	local map_gen_settings = planet and planet.map_gen_settings
	if not map_gen_settings then
		return
	end

	planet.pollutant_type = planet.pollutant_type or "pollution"
	map_gen_settings.autoplace_controls = map_gen_settings.autoplace_controls or {}
	map_gen_settings.autoplace_controls[toxic_enemy_control] = {
		frequency = 1,
		size = 1,
		richness = 1
	}

	map_gen_settings.autoplace_settings = map_gen_settings.autoplace_settings or {}
	map_gen_settings.autoplace_settings.entity = map_gen_settings.autoplace_settings.entity or {}
	map_gen_settings.autoplace_settings.entity.settings = map_gen_settings.autoplace_settings.entity.settings or {}

	for _, entity_name in pairs(toxic_enemy_entities) do
		if toxic_entity_exists(entity_name) then
			map_gen_settings.autoplace_settings.entity.settings[entity_name] = {}
		end
	end
end

restrict_entity_to_toxic_tiles("unit-spawner", "toxic-biter-spawner")
restrict_entity_to_toxic_tiles("turret", "small-toxic-worm-turret")
restrict_entity_to_toxic_tiles("turret", "medium-toxic-worm-turret")
restrict_entity_to_toxic_tiles("turret", "big-toxic-worm-turret")
restrict_entity_to_toxic_tiles("turret", "behemoth-toxic-worm-turret")
restrict_entity_to_toxic_tiles("turret", "leviathan-toxic-worm-turret")
restrict_entity_to_toxic_tiles("turret", "mother-toxic-worm-turret")

remove_toxic_enemies_from_planet("nauvis")
remove_toxic_enemies_from_planet("vulcanus")

for _, planet_name in pairs(toxic_planets) do
	add_toxic_enemies_to_planet(planet_name)
end
