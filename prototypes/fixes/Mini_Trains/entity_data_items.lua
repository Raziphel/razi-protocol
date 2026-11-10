local entity_data_items = {}

-- The items of Mini_Trains 2.1.0 are plain items (data/mini-trains.lua:706, 846 and 995), while the locomotives and
-- wagons of the game are item-with-entity-data: a mini train picked up loses its color and its equipment grid. The three
-- items become item-with-entity-data under the same names.
function entity_data_items.data_final_fixes()
	local entity_data = data.raw["item-with-entity-data"]

	for _, name in ipairs({"mini-locomotive", "mini-cargo-wagon", "mini-fluid-wagon"}) do
		local item = data.raw.item and data.raw.item[name]

		if item and entity_data and not entity_data[name] then
			data.raw.item[name] = nil
			item.type = "item-with-entity-data"
			entity_data[name] = item
			log("razi-protocol: " .. name .. " is an item-with-entity-data")
		end
	end
end

return entity_data_items
