local nutrients_refresh = {}

-- Apia makes a freshness restoration recipe for every spoiling item but nutrients (lib.lua:51 of 0.5.1 skips an item with
-- fuel_category == "nutrients"). Factorio 2.1.20 removed fuel_category for fuel_categories, the check never matches, and
-- nutrients got a recipe too: lymph keeps them fresh for ever. The recipes of the items that burn as nutrients are taken
-- out again, with their unlocks.
local function burns_as_nutrients(item)
	for _, category in pairs(item.fuel_categories or {}) do
		if category == "nutrients" then
			return true
		end
	end

	return item.fuel_category == "nutrients"
end

function nutrients_refresh.data_final_fixes()
	local recipes = data.raw.recipe
	if not recipes then
		return
	end

	local removed = {}
	for type_name in pairs(defines.prototypes.item) do
		for name, item in pairs(data.raw[type_name] or {}) do
			local recipe_name = name .. "-refresh-freshness"
			if burns_as_nutrients(item) and recipes[recipe_name] then
				recipes[recipe_name] = nil
				removed[recipe_name] = true
				log("razi-protocol: removed " .. recipe_name .. " (apia skips nutrients)")
			end
		end
	end

	for _, technology in pairs(data.raw.technology or {}) do
		local effects = technology.effects or {}
		for index = #effects, 1, -1 do
			local effect = effects[index]
			if effect and effect.type == "unlock-recipe" and removed[effect.recipe] then
				table.remove(effects, index)
			end
		end
	end
end

return nutrients_refresh
