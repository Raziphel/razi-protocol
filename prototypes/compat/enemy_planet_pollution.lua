local enemy_autoplace = require("prototypes.compat.enemy_autoplace")

local enemy_planet_pollution = {}

-- Arig and Hyarion had no enemies before Razi Protocol routed Arachnids and
-- Armoured Biters there, and their tiles absorb no pollution: Arig's tiles have
-- no absorptions_per_second at all, and Hyarion's read a lava value that the
-- base tile-pollution table does not have. Pollution then never fades, spreads
-- over the whole map and every nest it reaches attacks. Give each tile without
-- a pollution value the absorption of its vanilla counterpart.
local planets = {
	{planet = "arig", enemy_mod = "Arachnids_enemy", like_tile = "sand-1", fallback = 0.000015},
	{planet = "hyarion", enemy_mod = "ArmouredBiters", like_tile = "volcanic-soil-dark", fallback = 0.00003}
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
		if mods[entry.enemy_mod] then
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
