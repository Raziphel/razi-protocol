local enemy_autoplace = require("prototypes.compat.enemy_autoplace")
local enemy_homes = require("prototypes.compat.enemy_homes")

if not enemy_autoplace.enabled() or not mods["Toxic_biters"] then
	return
end

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

local toxic_source_planets = {
	"nauvis",
	"vulcanus"
}

local toxic_enemy_autoplace = {
	["toxic-biter-spawner"] = "unit-spawner",
	["small-toxic-worm-turret"] = "turret",
	["medium-toxic-worm-turret"] = "turret",
	["big-toxic-worm-turret"] = "turret",
	["behemoth-toxic-worm-turret"] = "turret",
	["leviathan-toxic-worm-turret"] = "turret",
	["mother-toxic-worm-turret"] = "turret"
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
	"cubium-ash-soil"
}

local existing_toxic_planet_tiles = enemy_autoplace.existing_tiles(toxic_planet_tiles)

for entity_name, entity_type in pairs(toxic_enemy_autoplace) do
	enemy_autoplace.restrict_entity_to_tiles(entity_type, entity_name, existing_toxic_planet_tiles)
end

for _, planet_name in pairs(toxic_source_planets) do
	enemy_autoplace.remove_entities_from_planet(planet_name, toxic_enemy_entities)
end

enemy_homes.claim("toxic", toxic_enemy_entities)
for _, planet_name in pairs(enemy_homes.planets("toxic")) do
	enemy_autoplace.add_entities_to_planet(planet_name, toxic_enemy_entities, toxic_enemy_control)
end
