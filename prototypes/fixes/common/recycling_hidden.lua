local recycling_hidden = {}

-- The recycler generates its recipes hidden (recycler/recycling.lua:259): only a recycler runs them, so the crafting
-- menu never lists them. RenaiTransportation 2.3.5 hides its open chest recycling itself (prototypes/OpenContainer.lua:74),
-- but other mods in the pack still add recipes that only a recycler makes without hidden. For example, Frozeta Nuclear
-- Winter 1.12.9 adds advanced-processing-unit-recycling (prototype/recipes.lua:157). Every recipe that only a recycler
-- can make is hidden, except one whose mod set hidden = false on purpose: planet-rabbasca shows
-- rabbasca-warp-pylon-recycling in Factoriopedia and keeps it out of the crafting menu with hide_from_player_crafting
-- (data-final-fixes.lua:19-21 of 0.23.2).
function recycling_hidden.data_final_fixes()
	for name, recipe in pairs(data.raw.recipe or {}) do
		local categories = type(recipe.categories) == "table" and recipe.categories or {}
		local recycling_only = next(categories) ~= nil
		for _, category in pairs(categories) do
			recycling_only = recycling_only and category == "recycling"
		end
		if recycling_only and recipe.hidden == nil then
			recipe.hidden = true
			log("razi-protocol: " .. name .. " is hidden, only a recycler makes it")
		end
	end
end

return recycling_hidden
