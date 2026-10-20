local corrundum_compat_plus = {}

local research_data = "electrochemical-research-data"

local function has_no_conditions(recipe)
	return recipe.surface_conditions == nil or next(recipe.surface_conditions) == nil
end

-- With XY's tech cards, Corrundum Compatibility+ builds the electrochemical
-- research data recipe from the science pack recipe, which XY has already
-- freed from its surface conditions, so the data can be made on any planet.
-- XY's own recipe, and Corrundum's before it, make it only under Corrundum's
-- pressure and magnetic field. Until Corrundum Compatibility+ keeps that lock, the
-- data recipe gets the conditions of the planet back.
local function lock_research_data()
	local recipe = data.raw.recipe[research_data]
	local planet = data.raw.planet and data.raw.planet["corrundum"]
	local properties = planet and planet.surface_properties
	local pressure = properties and properties.pressure
	local magnetic_field = properties and properties["magnetic-field"]

	if not (recipe and pressure and magnetic_field and has_no_conditions(recipe)) then
		return
	end

	recipe.surface_conditions = {
		{property = "pressure", min = pressure, max = pressure},
		{property = "magnetic-field", min = magnetic_field, max = magnetic_field}
	}
	log("razi-protocol: " .. research_data .. " is made only under the surface conditions of Corrundum")
end

function corrundum_compat_plus.data_final_fixes()
	lock_research_data()
end

return corrundum_compat_plus
