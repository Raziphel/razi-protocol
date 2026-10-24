local enemy_autoplace = require("prototypes.compat.enemy_autoplace")
local enemy_homes = require("prototypes.compat.enemy_homes")

if not enemy_autoplace.enabled() or not mods["Arachnids_enemy"] then
	return
end

local arachnid_spawner = data.raw["unit-spawner"]["arachnid-spawner-unitspawner"]

local arachnid_tiles = {
	"arig-sand",
	"arig-deep-sand",
	"arig-stable-sand",
	"planetaris-sandstone-1",
	"planetaris-sandstone-2",
	"planetaris-sandstone-3"
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

-- Without a naturally placeable nest, keep the planets' vanilla enemies.
if enemy_autoplace.has_valid_autoplace(arachnid_spawner) then
	enemy_homes.claim("arachnids", {"arachnid-spawner-unitspawner"})
	for _, planet_name in pairs(enemy_homes.planets("arachnids")) do
		add_arachnids_to_planet(planet_name)
	end
end
