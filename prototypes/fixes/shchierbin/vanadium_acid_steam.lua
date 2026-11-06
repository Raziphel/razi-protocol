local vanadium_acid_steam = {}

-- sulfuric-acid-vanadium of Shchierbin asks for steam of exactly 165 degrees, so a trace of 500-degree steam in the pipe
-- stops the machine (mods.factorio.com/mod/shchierbin/discussion/69a1ad9fbda86954ff3b16b6). It takes steam from 165 to
-- 500 degrees.
function vanadium_acid_steam.data_final_fixes()
	local recipe = data.raw.recipe and data.raw.recipe["sulfuric-acid-vanadium"]
	for _, ingredient in pairs(recipe and recipe.ingredients or {}) do
		if ingredient.type == "fluid" and ingredient.name == "steam" and ingredient.temperature == 165 then
			ingredient.temperature = nil
			ingredient.minimum_temperature = 165
			ingredient.maximum_temperature = 500
			log("razi-protocol: sulfuric-acid-vanadium takes steam from 165 to 500 degrees")
		end
	end
end

return vanadium_acid_steam
