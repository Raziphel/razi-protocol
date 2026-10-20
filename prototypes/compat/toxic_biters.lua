local enemy_autoplace = require("prototypes.compat.enemy_autoplace")

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

local toxic_planets = {
	"cubium",
	"vesta",
	"nexus",
	"crucible",
	"paracelsin",
	"rabbasca",
	"foliax"
}

local toxic_source_planets = {
	"nauvis",
	"vulcanus"
}

-- Preserve original poison-biter habitat rules; the final ecology
-- creates scoped variants on other chemical and biological planets.

for _, planet_name in pairs(toxic_source_planets) do
	enemy_autoplace.remove_entities_from_planet(planet_name, toxic_enemy_entities)
end

for _, planet_name in pairs(toxic_planets) do
	enemy_autoplace.add_entities_to_planet(planet_name, toxic_enemy_entities, toxic_enemy_control)
end
