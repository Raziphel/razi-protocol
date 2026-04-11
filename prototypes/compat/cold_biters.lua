local cold_enemy_control = "frost_enemy_base"

local cold_enemy_entities = {
	"cb-cold-spawner",
	"small-cold-worm-turret",
	"medium-cold-worm-turret",
	"big-cold-worm-turret",
	"behemoth-cold-worm-turret",
	"leviathan-cold-worm-turret",
	"mother-cold-worm-turret"
}

local cold_enemy_autoplace = {
	["cb-cold-spawner"] = {type = "unit-spawner", distance = 0, worm = false},
	["small-cold-worm-turret"] = {type = "turret", distance = 0, worm = true},
	["medium-cold-worm-turret"] = {type = "turret", distance = 2, worm = true},
	["big-cold-worm-turret"] = {type = "turret", distance = 5, worm = true},
	["behemoth-cold-worm-turret"] = {type = "turret", distance = 8, worm = true},
	["leviathan-cold-worm-turret"] = {type = "turret", distance = 10, worm = true},
	["mother-cold-worm-turret"] = {type = "turret", distance = 14, worm = true}
}

local cold_planets = {
	"aquilo",
	"paracelsin",
	"frozeta",
	"cerys",
	"nexus"
}

local cold_planet_tiles = {
	"snow-flat",
	"snow-crests",
	"snow-lumpy",
	"snow-patchy",
	"ice-rough",
	"ice-smooth",
	"ammoniacal-ocean",
	"ammoniacal-ocean-2",
	"brash-ice",
	"cerys-empty-space-2",
	"cerys-ice-on-water",
	"cerys-water-puddles",
	"cerys-ash-cracks-frozen",
	"cerys-ash-dark-frozen",
	"cerys-pumice-stones-frozen",
	"volcanic-soil-dark",
	"volcanic-soil-light",
	"volcanic-ash-soil",
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

local existing_cold_planet_tiles = existing_tiles(cold_planet_tiles)

local function cold_autoplace_expression(distance, worm)
	local expression = "cb_enemy_autoplace_base(" .. distance .. ", " .. (42000 + distance) .. ")"
	if worm then
		return "(" .. expression .. ") * (1 - no_enemies_mode)"
	end

	return expression
end

local function restrict_entity_to_cold_tiles(entity_type, entity_name, distance, worm)
	local entity = data.raw[entity_type] and data.raw[entity_type][entity_name]
	if entity then
		entity.autoplace = entity.autoplace or {}
		entity.autoplace.control = cold_enemy_control
		entity.autoplace.order = worm and "b[enemy]-b[worm]" or "b[enemy]-a[spawner]"
		entity.autoplace.force = "enemy"
		entity.autoplace.probability_expression = cold_autoplace_expression(distance, worm)
		entity.autoplace.richness_expression = 1
		entity.autoplace.tile_restriction = existing_cold_planet_tiles
	end
end

local function remove_cold_enemies_from_planet(planet_name)
	local planet = data.raw.planet[planet_name]
	local map_gen_settings = planet and planet.map_gen_settings
	if not map_gen_settings then
		return
	end

	if map_gen_settings.autoplace_controls then
		map_gen_settings.autoplace_controls[cold_enemy_control] = nil
	end

	local entity_settings = map_gen_settings.autoplace_settings
		and map_gen_settings.autoplace_settings.entity
		and map_gen_settings.autoplace_settings.entity.settings

	if not entity_settings then
		return
	end

	for _, entity_name in pairs(cold_enemy_entities) do
		entity_settings[entity_name] = nil
	end
end

local function add_cold_enemies_to_planet(planet_name)
	local planet = data.raw.planet[planet_name]
	local map_gen_settings = planet and planet.map_gen_settings
	if not map_gen_settings then
		return
	end

	planet.pollutant_type = planet.pollutant_type or "pollution"
	map_gen_settings.autoplace_controls = map_gen_settings.autoplace_controls or {}
	map_gen_settings.autoplace_controls[cold_enemy_control] = {
		frequency = 1,
		size = 1,
		richness = 1
	}

	map_gen_settings.autoplace_settings = map_gen_settings.autoplace_settings or {}
	map_gen_settings.autoplace_settings.entity = map_gen_settings.autoplace_settings.entity or {}
	map_gen_settings.autoplace_settings.entity.settings = map_gen_settings.autoplace_settings.entity.settings or {}

	for _, entity_name in pairs(cold_enemy_entities) do
		local autoplace = cold_enemy_autoplace[entity_name]
		if autoplace and data.raw[autoplace.type] and data.raw[autoplace.type][entity_name] then
			map_gen_settings.autoplace_settings.entity.settings[entity_name] = {}
		end
	end
end

for entity_name, autoplace in pairs(cold_enemy_autoplace) do
	restrict_entity_to_cold_tiles(autoplace.type, entity_name, autoplace.distance, autoplace.worm)
end

remove_cold_enemies_from_planet("nauvis")

for _, planet_name in pairs(cold_planets) do
	add_cold_enemies_to_planet(planet_name)
end
