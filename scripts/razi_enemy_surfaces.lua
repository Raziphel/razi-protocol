-- Armoured, Toxic and Arachnids nests share the vanilla enemy control. The data stage switches them off by name on the
-- planets that are not their home (prototypes/compat/enemy_homes.lua), but a surface keeps the generation settings it was
-- made with, so on a surface made before that (an old save, or a save whose level changed to Hard) the entries are
-- missing, and Arachnids on Athos' tiles, which are Nauvis' tiles, would turn up in the new chunks of Nauvis.
-- This puts the entries the planet prototype has switched off into the settings of the surfaces that already exist.
-- It writes nothing else, nothing where the surface already has them, and it only affects chunks made afterwards.
local nest_names = require("prototypes.compat.enemy_nest_names")

local M = {}

local OFF = {frequency = 0, size = 0, richness = 0}

local function shared_names()
	local names = {}
	for _, family in ipairs({"armoured", "arachnids", "toxic"}) do
		for _, name in ipairs(nest_names[family]) do
			names[#names + 1] = name
		end
	end

	return names
end

local function prototype_entities(surface)
	local planet = surface.planet
	local prototype = planet and planet.prototype
	local settings = prototype and prototype.map_gen_settings
	local entity = settings and settings.autoplace_settings and settings.autoplace_settings.entity
	return entity and entity.settings
end

local function is_off(entry)
	return entry ~= nil and entry.frequency == 0
end

-- Returns the surface names that were changed.
function M.apply()
	local changed = {}
	local names = shared_names()
	for _, surface in pairs(game.surfaces) do
		local wanted = prototype_entities(surface)
		if wanted then
			local missing = {}
			local current = surface.map_gen_settings
			local entity = current.autoplace_settings and current.autoplace_settings.entity
			local present = entity and entity.settings or {}
			for _, name in ipairs(names) do
				if is_off(wanted[name]) and not is_off(present[name]) then
					missing[#missing + 1] = name
				end
			end

			if #missing > 0 then
				current.autoplace_settings = current.autoplace_settings or {}
				current.autoplace_settings.entity = current.autoplace_settings.entity or {}
				current.autoplace_settings.entity.settings = current.autoplace_settings.entity.settings or {}
				for _, name in ipairs(missing) do
					current.autoplace_settings.entity.settings[name] = {frequency = OFF.frequency, size = OFF.size, richness = OFF.richness}
				end
				surface.map_gen_settings = current
				changed[#changed + 1] = surface.name
				log("razi-protocol: enemy nests switched off for new chunks of " .. surface.name .. ": " .. table.concat(missing, ", "))
			end
		end
	end

	return changed
end

return M
