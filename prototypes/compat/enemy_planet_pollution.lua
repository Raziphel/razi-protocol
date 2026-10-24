local enemy_autoplace = require("prototypes.compat.enemy_autoplace")
local enemy_homes = require("prototypes.compat.enemy_homes")

local enemy_planet_pollution = {}

-- Arig, Hyarion, Panglia and Obsidiax had no enemies before Razi Protocol routed Arachnids, Armoured Biters and Cold
-- Biters there, and some of their tiles absorb no pollution: Arig's tiles have no absorptions_per_second at all, Hyarion's
-- read a lava value that the base tile-pollution table does not have, three of Panglia's plant tiles have none and
-- Obsidiax' only land tile has none. Pollution then never fades, spreads over the whole map and every nest it reaches
-- attacks. Give each tile without a pollution value the absorption of its vanilla counterpart. Only the planets that
-- are a home of that family at the selected step carry pollution, so only they need it.
local planets = {
	{planet = "arig", family = "arachnids", enemy_mods = {"Arachnids_enemy"}, like_tile = "sand-1", fallback = 0.000015},
	{planet = "hyarion", family = "armoured", enemy_mods = {"ArmouredBiters", "ArmouredBiters21Compat", "ArmouredBiters-2_1-update"}, like_tile = "volcanic-soil-dark", fallback = 0.00003},
	{planet = "panglia", family = "armoured", enemy_mods = {"ArmouredBiters", "ArmouredBiters21Compat", "ArmouredBiters-2_1-update"}, like_tile = "volcanic-soil-dark", fallback = 0.00003},
	{planet = "obsidiax", family = "cold", enemy_mods = {"Cold_biters"}, like_tile = "volcanic-soil-dark", fallback = 0.00003}
}

local function planet_tile_names(planet_name)
	local planet = data.raw.planet and data.raw.planet[planet_name]
	local autoplace = planet and planet.map_gen_settings and planet.map_gen_settings.autoplace_settings
	local tile_settings = autoplace and autoplace.tile and autoplace.tile.settings
	local names = {}

	for name in pairs(tile_settings or {}) do
		names[#names + 1] = name
	end
	table.sort(names)

	return names
end

local function any_mod_active(names)
	for _, name in ipairs(names) do
		if mods[name] then
			return true
		end
	end

	return false
end

local function vanilla_absorption(entry)
	local tile = data.raw.tile and data.raw.tile[entry.like_tile]
	local absorptions = tile and tile.absorptions_per_second
	return absorptions and absorptions.pollution or entry.fallback
end

function enemy_planet_pollution.data_final_fixes()
	if not enemy_autoplace.enabled() then
		return
	end

	for _, entry in ipairs(planets) do
		if any_mod_active(entry.enemy_mods) and enemy_homes.is_home(entry.family, entry.planet) then
			local pollution = vanilla_absorption(entry)

			for _, tile_name in ipairs(planet_tile_names(entry.planet)) do
				local tile = data.raw.tile and data.raw.tile[tile_name]
				local absorptions = tile and tile.absorptions_per_second

				if tile and not (absorptions and absorptions.pollution) then
					-- Tiles may share one table, so every tile gets a copy of its own.
					absorptions = table.deepcopy(absorptions or {})
					absorptions.pollution = pollution
					tile.absorptions_per_second = absorptions
				end
			end
		end
	end
end

return enemy_planet_pollution
