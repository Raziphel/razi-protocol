local panglite_recycling = {}

-- Panglia keeps quality away from panglite: the baking recipe (5 -> 6, with productivity) has allow_quality = false,
-- and the author rewrote the matter printer recycling without panglite (data-final-fixes.lua:260-288). Two recycling
-- recipes still return it: the volcanic universe precursor and the sentient processor, both craftable with quality
-- modules. Recycling a legendary one gives legendary panglite, which the baking recipe then multiplies for ever, and
-- through it fiber, glass, microcosms and the space incubator outputs come in legendary quality without modules.
-- Panglite leaves these two recycling recipes, as it left the matter printer one.
function panglite_recycling.data_final_fixes()
	for _, name in ipairs({ "panglia_universe_precursor_volcanic-recycling", "panglia_sentient_processor-recycling" }) do
		local recipe = data.raw.recipe[name]
		local results = recipe and recipe.results

		if results then
			for index = #results, 1, -1 do
				if results[index].name == "panglia_panglite" then
					table.remove(results, index)
					log("razi-protocol: " .. name .. " no longer returns panglia_panglite")
				end
			end
		end
	end
end

return panglite_recycling
