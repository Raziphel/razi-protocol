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
	"crucible"
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
	"volcanic-ash-cracks",
	"planet-crucible-dirt-1",
	"planet-crucible-dirt-2",
	"planet-crucible-dirt-3",
	"planet-crucible-dirt-4",
	"planet-crucible-rock-1",
	"planet-crucible-rock-2",
	"planet-crucible-rock-3",
	"planet-crucible-rock-4",
	"planet-crucible-sand-1"
}

local existing_toxic_planet_tiles = enemy_autoplace.existing_tiles(toxic_planet_tiles)

for entity_name, entity_type in pairs(toxic_enemy_autoplace) do
	enemy_autoplace.restrict_entity_to_tiles(entity_type, entity_name, existing_toxic_planet_tiles)
end

for _, planet_name in pairs(toxic_source_planets) do
	enemy_autoplace.remove_entities_from_planet(planet_name, toxic_enemy_entities)
end

for _, planet_name in pairs(toxic_planets) do
	enemy_autoplace.add_entities_to_planet(planet_name, toxic_enemy_entities, toxic_enemy_control)
end
