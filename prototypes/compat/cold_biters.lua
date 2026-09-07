local enemy_autoplace = require("prototypes.compat.enemy_autoplace")

if not enemy_autoplace.enabled() or not mods["Cold_biters"] then
	return
end

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
	"nexus"
}

local cold_source_planets = {
	"nauvis"
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

local existing_cold_planet_tiles = enemy_autoplace.existing_tiles(cold_planet_tiles)

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

local function cold_entity_exists(entity_name)
	local autoplace = cold_enemy_autoplace[entity_name]
	return autoplace
		and data.raw[autoplace.type]
		and data.raw[autoplace.type][entity_name]
end

for entity_name, autoplace in pairs(cold_enemy_autoplace) do
	restrict_entity_to_cold_tiles(autoplace.type, entity_name, autoplace.distance, autoplace.worm)
end

for _, planet_name in pairs(cold_source_planets) do
	enemy_autoplace.remove_entities_from_planet(planet_name, cold_enemy_entities, cold_enemy_control)
end

for _, planet_name in pairs(cold_planets) do
	enemy_autoplace.add_entities_to_planet(planet_name, cold_enemy_entities, cold_enemy_control, cold_entity_exists)
end
