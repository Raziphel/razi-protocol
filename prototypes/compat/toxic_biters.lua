local enemy_autoplace = require("prototypes.compat.enemy_autoplace")
local enemy_homes = require("prototypes.compat.enemy_homes")
local nest_names = require("prototypes.compat.enemy_nest_names")

if not enemy_autoplace.enabled() or not mods["Toxic_biters"] then
	return
end

local toxic_enemy_control = "enemy-base"

local toxic_enemy_entities = nest_names.toxic

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

local toxic_planet_tiles = enemy_homes.tiles("toxic")

for entity_name, entity_type in pairs(toxic_enemy_autoplace) do
	enemy_autoplace.restrict_entity_to_tiles(entity_type, entity_name, toxic_planet_tiles)
end

for _, planet_name in pairs(toxic_source_planets) do
	enemy_autoplace.remove_entities_from_planet(planet_name, toxic_enemy_entities)
end

enemy_homes.claim("toxic", toxic_enemy_entities)
for _, planet_name in pairs(enemy_homes.planets("toxic")) do
	enemy_autoplace.add_entities_to_planet(planet_name, toxic_enemy_entities, toxic_enemy_control)
end
