local enemy_autoplace = require("prototypes.compat.enemy_autoplace")

if not enemy_autoplace.enabled() or not mods["Arachnids_enemy"] then
	return
end

local arachnid_spawner = data.raw["unit-spawner"]["arachnid-spawner-unitspawner"]

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
		frequency = enemy_autoplace.pressure(planet_name),
		size = 1,
		richness = 1
	}

	map_gen_settings.autoplace_settings = map_gen_settings.autoplace_settings or {}
	map_gen_settings.autoplace_settings.entity = map_gen_settings.autoplace_settings.entity or {}
	map_gen_settings.autoplace_settings.entity.settings = map_gen_settings.autoplace_settings.entity.settings or {}
	map_gen_settings.autoplace_settings.entity.settings["arachnid-spawner-unitspawner"] = {}
end

-- Keep original Arachnids biome constraints. New-world nests use
-- their own planet-local restrictions in razi_enemy_ecology.

-- A source-owned scripted nest must not suppress vanilla spawn points.
if enemy_autoplace.has_valid_autoplace(arachnid_spawner) then
	add_arachnids_to_planet("arig")
	add_arachnids_to_planet("nexus")
	add_arachnids_to_planet("crucible")
	-- Athos/Castra have dry, rugged territory suited to burrowing nests.
	-- Their actual tile restrictions are extended by the final ecology pass.
	add_arachnids_to_planet("athos")
	add_arachnids_to_planet("castra")
end
