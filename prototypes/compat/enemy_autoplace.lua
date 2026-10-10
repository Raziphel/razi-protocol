local enemy_autoplace = {}

local vanilla_enemy_entities = {
	"biter-spawner",
	"spitter-spawner",
	"small-worm-turret",
	"medium-worm-turret",
	"big-worm-turret",
	"behemoth-worm-turret"
}

function enemy_autoplace.enabled()
	local setting = settings
		and settings.startup
		and settings.startup["razi-enable-enemy-routing"]

	return not setting or setting.value ~= false
end

local function planet_entity_settings(planet_name)
	local planet = data.raw.planet and data.raw.planet[planet_name]
	local map_gen_settings = planet and planet.map_gen_settings
	if not map_gen_settings then
		return nil
	end

	map_gen_settings.autoplace_settings = map_gen_settings.autoplace_settings or {}
	map_gen_settings.autoplace_settings.entity = map_gen_settings.autoplace_settings.entity or {}
	map_gen_settings.autoplace_settings.entity.settings = map_gen_settings.autoplace_settings.entity.settings or {}

	return map_gen_settings.autoplace_settings.entity.settings
end

function enemy_autoplace.disable_vanilla_enemies_on_planet(planet_name)
	if not enemy_autoplace.enabled() then
		return
	end

	local entity_settings = planet_entity_settings(planet_name)
	if not entity_settings then
		return
	end

	for _, entity_name in pairs(vanilla_enemy_entities) do
		if
			(data.raw["unit-spawner"] and data.raw["unit-spawner"][entity_name]) or
			(data.raw.turret and data.raw.turret[entity_name])
		then
			entity_settings[entity_name] = {
				frequency = 0,
				size = 0,
				richness = 0
			}
		end
	end
end

function enemy_autoplace.existing_tiles(tile_names)
	local tiles = {}
	for _, tile_name in pairs(tile_names or {}) do
		if data.raw.tile and data.raw.tile[tile_name] then
			table.insert(tiles, tile_name)
		end
	end

	return tiles
end

function enemy_autoplace.entity_exists(entity_type, entity_name)
	return data.raw[entity_type] and data.raw[entity_type][entity_name]
end

function enemy_autoplace.enemy_entity_exists(entity_name)
	return
		(data.raw["unit-spawner"] and data.raw["unit-spawner"][entity_name]) or
		(data.raw.turret and data.raw.turret[entity_name])
end

function enemy_autoplace.restrict_entity_to_tiles(entity_type, entity_name, tile_names)
	if not enemy_autoplace.enabled() then
		return
	end

	local entity = enemy_autoplace.entity_exists(entity_type, entity_name)
	if entity and entity.autoplace then
		entity.autoplace.tile_restriction = tile_names
	end
end

function enemy_autoplace.remove_entities_from_planet(planet_name, entity_names, control_name)
	if not enemy_autoplace.enabled() then
		return
	end

	local planet = data.raw.planet and data.raw.planet[planet_name]
	local map_gen_settings = planet and planet.map_gen_settings
	if not map_gen_settings then
		return
	end

	if control_name and map_gen_settings.autoplace_controls then
		map_gen_settings.autoplace_controls[control_name] = nil
	end

	local entity_settings = map_gen_settings.autoplace_settings
		and map_gen_settings.autoplace_settings.entity
		and map_gen_settings.autoplace_settings.entity.settings

	if not entity_settings then
		return
	end

	for _, entity_name in pairs(entity_names or {}) do
		entity_settings[entity_name] = nil
	end
end

function enemy_autoplace.prepare_custom_enemy_planet(planet_name, control_name)
	if not enemy_autoplace.enabled() then
		return nil
	end

	local planet = data.raw.planet and data.raw.planet[planet_name]
	local map_gen_settings = planet and planet.map_gen_settings
	if not map_gen_settings then
		return nil
	end

	planet.pollutant_type = planet.pollutant_type or "pollution"
	enemy_autoplace.disable_vanilla_enemies_on_planet(planet_name)

	map_gen_settings.autoplace_controls = map_gen_settings.autoplace_controls or {}
	map_gen_settings.autoplace_controls[control_name] = {
		frequency = 1,
		size = 1,
		richness = 1
	}

	map_gen_settings.autoplace_settings = map_gen_settings.autoplace_settings or {}
	map_gen_settings.autoplace_settings.entity = map_gen_settings.autoplace_settings.entity or {}
	map_gen_settings.autoplace_settings.entity.settings = map_gen_settings.autoplace_settings.entity.settings or {}

	return map_gen_settings.autoplace_settings.entity.settings
end

function enemy_autoplace.add_entities_to_planet(planet_name, entity_names, control_name, entity_exists)
	local entity_settings = enemy_autoplace.prepare_custom_enemy_planet(planet_name, control_name)
	if not entity_settings then
		return
	end

	entity_exists = entity_exists or enemy_autoplace.enemy_entity_exists
	for _, entity_name in pairs(entity_names or {}) do
		if entity_exists(entity_name) then
			entity_settings[entity_name] = {}
		end
	end
end

return enemy_autoplace
