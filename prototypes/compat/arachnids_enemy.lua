local enemy_autoplace = require("prototypes.compat.enemy_autoplace")
local arachnid_spawner = data.raw["unit-spawner"]["arachnid-spawner-unitspawner"]

local arachnid_tiles = {
	"arig-sand",
	"arig-deep-sand",
	"arig-stable-sand",
	"planetaris-sandstone-1",
	"planetaris-sandstone-2",
	"planetaris-sandstone-3",
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

local function add_arachnids_to_planet(planet_name)
	local planet = data.raw.planet[planet_name]
	local map_gen_settings = planet and planet.map_gen_settings
	if not map_gen_settings then
		return
	end

	planet.pollutant_type = planet.pollutant_type or "pollution"
	enemy_autoplace.disable_vanilla_enemies_on_planet(planet_name)
	map_gen_settings.autoplace_controls = map_gen_settings.autoplace_controls or {}
	map_gen_settings.autoplace_controls["enemy-base"] = {
		frequency = 1,
		size = 1,
		richness = 1
	}

	map_gen_settings.autoplace_settings = map_gen_settings.autoplace_settings or {}
	map_gen_settings.autoplace_settings.entity = map_gen_settings.autoplace_settings.entity or {}
	map_gen_settings.autoplace_settings.entity.settings = map_gen_settings.autoplace_settings.entity.settings or {}
	map_gen_settings.autoplace_settings.entity.settings["arachnid-spawner-unitspawner"] = {}
end

if arachnid_spawner and arachnid_spawner.autoplace then
	arachnid_spawner.autoplace.tile_restriction = arachnid_tiles
end

add_arachnids_to_planet("arig")
add_arachnids_to_planet("nexus")
add_arachnids_to_planet("crucible")
