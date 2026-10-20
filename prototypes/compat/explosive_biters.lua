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

local explosive_enemy_autoplace = {
	["explosive-biter-spawner"] = "unit-spawner",
	["small-explosive-worm-turret"] = "turret",
	["medium-explosive-worm-turret"] = "turret",
	["big-explosive-worm-turret"] = "turret",
	["behemoth-explosive-worm-turret"] = "turret",
	["leviathan-explosive-worm-turret"] = "turret",
	["mother-explosive-worm-turret"] = "turret"
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

local existing_explosive_planet_tiles = enemy_autoplace.existing_tiles(explosive_planet_tiles)

-- Source tile restrictions stay untouched. Final ecology installs
-- planet-local variants to target valid hot/rocky terrain safely.

for _, planet_name in pairs(explosive_source_planets) do
	enemy_autoplace.remove_entities_from_planet(planet_name, explosive_enemy_entities, explosive_enemy_control)
end

for _, planet_name in pairs(explosive_planets) do
	enemy_autoplace.add_entities_to_planet(planet_name, explosive_enemy_entities, explosive_enemy_control)
end
