local maraxsis_trench_wind = {}

-- The Krastorio 2 wind turbine needs rubia-wind-speed >= 1. Maraxsis sets the
-- property to 0 on its surface, but the trench does not set it, so the default
-- of 15 applies and the turbine works at the bottom of the ocean. The trench
-- gets the 0 of Maraxsis.
function maraxsis_trench_wind.data_final_fixes()
	local trench = data.raw.planet and data.raw.planet["maraxsis-trench"]
	local property = data.raw["surface-property"] and data.raw["surface-property"]["rubia-wind-speed"]

	if trench and property then
		trench.surface_properties = trench.surface_properties or {}
		if trench.surface_properties["rubia-wind-speed"] == nil then
			trench.surface_properties["rubia-wind-speed"] = 0
		end
	end
end

return maraxsis_trench_wind
