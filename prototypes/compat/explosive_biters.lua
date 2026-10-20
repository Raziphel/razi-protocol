local enemy_autoplace = require("prototypes.compat.enemy_autoplace")

if not enemy_autoplace.enabled() or not mods["Explosive_biters"] then
	return
end

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

local explosive_planets = {
	"moshine",
	"nexus",
	"cubium",
	"corrundum"
}

local explosive_source_planets = {
	"nauvis",
	"vulcanus"
}

-- Source tile restrictions stay untouched. Final ecology installs
-- planet-local variants to target valid hot/rocky terrain safely.

for _, planet_name in pairs(explosive_source_planets) do
	enemy_autoplace.remove_entities_from_planet(planet_name, explosive_enemy_entities, explosive_enemy_control)
end

for _, planet_name in pairs(explosive_planets) do
	enemy_autoplace.add_entities_to_planet(planet_name, explosive_enemy_entities, explosive_enemy_control)
end
