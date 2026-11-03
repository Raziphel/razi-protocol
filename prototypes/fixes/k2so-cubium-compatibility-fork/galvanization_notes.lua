local galvanization_notes = {}

-- The cubic galvanization science recipe of k2so-cubium-compatibility-fork returns 1000 kr-note-1 with every craft
-- (fixes/recipes/new.lua:179, a leftover of the recipe it was copied from), which fills the output of the machine with notes
-- no one needs. The recipe keeps its science packs and the dormant microcube.
function galvanization_notes.data_final_fixes()
	local recipe = data.raw.recipe and data.raw.recipe["galvanization-science-pack-cubic"]
	local results = recipe and recipe.results or {}

	for index = #results, 1, -1 do
		local product = results[index]
		if product and product.name == "kr-note-1" and product.amount == 1000 then
			table.remove(results, index)
			log("razi-protocol: galvanization-science-pack-cubic no longer returns kr-note-1")
		end
	end
end

return galvanization_notes
