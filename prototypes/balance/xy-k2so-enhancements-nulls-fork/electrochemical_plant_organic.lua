local electrochemical_plant_organic = {}

-- xy-k2so-enhancements-nulls-fork gives the electrochemical plant the crafting category "organic" on purpose
-- (patches/entity.lua:42, "this biolab is way too annoying"), so the plant makes the recipes of the biochamber without
-- the nutrients that the biochamber burns to work, and the biochamber has no reason to exist. This is a decision of this
-- mod, not a mistake of that one: the category is taken away again and the plant keeps its other categories.
function electrochemical_plant_organic.data_final_fixes()
	local plant = data.raw["assembling-machine"] and data.raw["assembling-machine"]["electrochemical-plant"]
	local categories = plant and plant.crafting_categories or {}

	for index = #categories, 1, -1 do
		if categories[index] == "organic" then
			table.remove(categories, index)
			log("razi-protocol: electrochemical-plant no longer makes organic recipes")
		end
	end
end

return electrochemical_plant_organic
