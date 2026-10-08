local research_data_surfaces = {}

-- xy-k2so-enhancements-nulls-fork turns the Paracelsin and Rubia science pack
-- recipes into tech card recipes with empty surface_conditions. The two
-- Krastorio compatibility mods then rebuild their research data from those
-- recipes and lose the planet lock on the way, so the research data can be made
-- anywhere once the machine is built:
-- - galvanization-research-data (paracelsin-krastorio-compatibility-plus) is
--   made in the Krastorio research server on any planet. It gets the pressure
--   of Paracelsin back, as the original galvanization science pack had.
-- - biorecycling-research-data (rubia-krastorio-compatibility-plus) is made in
--   the biorecycling plant, which has no surface conditions of its own. It
--   takes the conditions of the other Rubia research data,
--   rubia-biofusion-research-data.
local function has_no_conditions(recipe)
	return recipe.surface_conditions == nil or next(recipe.surface_conditions) == nil
end

local function lock_galvanization_research_data()
	local recipe = data.raw.recipe["galvanization-research-data"]
	local paracelsin = data.raw.planet and data.raw.planet["paracelsin"]
	local pressure = paracelsin and paracelsin.surface_properties and paracelsin.surface_properties.pressure

	if recipe and pressure and has_no_conditions(recipe) then
		recipe.surface_conditions = {{property = "pressure", min = pressure, max = pressure}}
	end
end

local function lock_biorecycling_research_data()
	local recipe = data.raw.recipe["biorecycling-research-data"]
	local sibling = data.raw.recipe["rubia-biofusion-research-data"]

	if recipe and sibling and sibling.surface_conditions and has_no_conditions(recipe) then
		recipe.surface_conditions = table.deepcopy(sibling.surface_conditions)
	end
end

function research_data_surfaces.data_final_fixes()
	lock_galvanization_research_data()
	lock_biorecycling_research_data()
end

return research_data_surfaces
