local crushed_ore_melting = {}

-- Plasma Crafter melts 75 crushed ore instead of 50 ore in plasma-molten-iron and plasma-molten-copper whenever Crushing
-- Industry is installed (prototypes/recipes.lua:249-257), also when its startup setting "Crushed ore" is off and the crushed
-- ores do not exist. The game then stops at load with an unknown item. The recipe gets back the ore it has without Crushing
-- Industry (prototypes/recipes.lua:117-120, 149-152) when the crushed ore is missing.
local RECIPES = {
	["plasma-molten-iron"] = {crushed = "crushed-iron-ore", ore = "iron-ore"},
	["plasma-molten-copper"] = {crushed = "crushed-copper-ore", ore = "copper-ore"},
}
local CRUSHED_AMOUNT = 75
local ORE_AMOUNT = 50

function crushed_ore_melting.data_final_fixes()
	local items_raw = data.raw.item or {}
	for name, items in pairs(RECIPES) do
		local recipe = data.raw.recipe and data.raw.recipe[name]
		if recipe and type(recipe.ingredients) == "table" and not items_raw[items.crushed] and items_raw[items.ore] then
			for _, ingredient in ipairs(recipe.ingredients) do
				if ingredient.name == items.crushed and ingredient.amount == CRUSHED_AMOUNT then
					ingredient.name = items.ore
					ingredient.amount = ORE_AMOUNT
					log("razi-protocol: " .. name .. " melts " .. ORE_AMOUNT .. " " .. items.ore .. " instead of "
						.. CRUSHED_AMOUNT .. " " .. items.crushed .. ", which is not made with crushed ore off")
				end
			end
		end
	end
end

return crushed_ore_melting
