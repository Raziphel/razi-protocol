local M = {}

-- PlanetsLib defines oxygen and its planet values (PlanetsLib/prototypes/surface-property/atmosphere.lua:1-21).
-- bzcarbon replaces them in its data stage, after PlanetsLib (bzcarbon/carbon-recipe.lua:612-616, :679-684).
-- Restore them here before PlanetsLib checks the combined gas percentages (PlanetsLib/data-final-fixes.lua:67-80).
local planet_values = {
	{ name = "vulcanus", bzcarbon = 12, planetslib = 3 },
	{ name = "fulgora", bzcarbon = 15, planetslib = 20 },
	{ name = "gleba", bzcarbon = 30, planetslib = 35 },
	{ name = "aquilo", bzcarbon = 10, planetslib = 15 },
}

function M.data_updates()
	if not (mods and mods["bzcarbon"] and mods["PlanetsLib"]) then
		return
	end

	local setting = settings and settings.startup and settings.startup["PlanetsLib-enable-oxygen"]
	if not (setting and setting.value == true) then
		return
	end

	local raw = data and data.raw or {}
	local oxygen = (raw["surface-property"] or {}).oxygen
	if not oxygen then
		return
	end

	if oxygen.default_value == 19 then
		oxygen.default_value = 21
		if not oxygen.order or oxygen.order == "" then
			oxygen.order = "z[gas]a"
		end
		if not oxygen.localised_unit_key or oxygen.localised_unit_key == "" then
			oxygen.localised_unit_key = "surface-property-unit.percentage"
		end
		if log then
			log("razi-protocol: bz: restored the PlanetsLib oxygen surface-property prototype")
		end
	end

	local planets = raw.planet or {}
	for _, values in ipairs(planet_values) do
		local surface_properties = planets[values.name] and planets[values.name].surface_properties
		if surface_properties and surface_properties.oxygen == values.bzcarbon then
			surface_properties.oxygen = values.planetslib
			if log then
				log("razi-protocol: bz: restored PlanetsLib oxygen on " .. values.name)
			end
		end
	end
end

return M
