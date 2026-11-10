local refresh_freshness_names = {}

-- Apia names the freshness restoration recipe of every spoiling item by the item-name key of the item
-- (lib.lua:83 of 0.5.1: {"recipe-name.refresh-freshness", {"item-name." .. item.name}}). An item that the game names by
-- its entity, like the captive copper spitter spawner of Pelagos (it has no item-name key, only entity-name.<name> of
-- the entity it places), gave "Freshness restoration Unknown key: item-name.captive-copper-biter-spawner" in every
-- language. The item-name key stays the first choice, so an item that has one reads exactly as before; the name falls
-- back to the localised_name of the item, else to the name of the entity it places, as the game names the item itself.
local function item_of(recipe_name)
	local first = recipe_name[2]
	local key = type(first) == "table" and first[1]
	local item_name = type(key) == "string" and key:match("^item%-name%.(.+)$")
	if not item_name or first[2] ~= nil then
		return nil
	end

	return data.raw.item and data.raw.item[item_name], item_name
end

function refresh_freshness_names.data_final_fixes()
	for name, recipe in pairs(data.raw.recipe or {}) do
		local shown = recipe.localised_name
		-- Only the name Apia wrote: {"recipe-name.refresh-freshness", {"item-name.<item>"}}.
		if type(shown) == "table" and shown[1] == "recipe-name.refresh-freshness" and shown[3] == nil then
			local item, item_name = item_of(shown)
			local fallback = item and (item.localised_name or item.place_result and {"entity-name." .. item.place_result})
			if fallback then
				recipe.localised_name = {"recipe-name.refresh-freshness", {"?", {"item-name." .. item_name}, fallback}}
				log("razi-protocol: " .. name .. " falls back to the name of " .. item_name .. " when it has no item-name key")
			end
		end
	end
end

return refresh_freshness_names
