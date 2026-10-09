local furnace_result_slots = {}

-- A furnace has a fixed number of result slots, and a recipe with more item
-- results than slots stops the furnace once they are full. Secretas sets 40
-- on the recycler for its spaceship scrap (data-updates.lua), and
-- Krastorio2-spaced-out sets it back to the number of results of
-- scrap-recycling in its data-final-fixes. In this pack that leaves 13 slots on
-- the recycler and 12 on the Tenebris bioluminescent recycler, while
-- warp-drive-engine-recycling (Nexus) has 16 item results and
-- matter-activator-recycling 15: the recycler stops on them. Give every
-- furnace at least as many result slots as the recipes it can make have item
-- results.
local function most_item_results_by_category()
	local most = {}
	for _, recipe in pairs(data.raw.recipe or {}) do
		local count = 0
		for _, product in pairs(recipe.results or {}) do
			if product.type == "item" then
				count = count + 1
			end
		end

		-- 2.1 knows only categories, but a mod not yet updated for it can still set
		-- the old category: count its recipes where that mod meant them to go.
		---@diagnostic disable-next-line: undefined-field
		for _, category in pairs(recipe.categories or {recipe.category or "crafting"}) do
			most[category] = math.max(most[category] or 0, count)
		end
	end

	return most
end

function furnace_result_slots.data_final_fixes()
	local most = most_item_results_by_category()

	for _, furnace in pairs(data.raw.furnace or {}) do
		local needed = 0
		for _, category in pairs(furnace.crafting_categories or {}) do
			needed = math.max(needed, most[category] or 0)
		end

		if needed > (furnace.result_inventory_size or 0) then
			furnace.result_inventory_size = needed
		end
	end
end

return furnace_result_slots
