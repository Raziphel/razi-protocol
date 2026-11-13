local crushed_prismite_sand = {}

-- Voidcraft turns prismite into sand with crushed prismite ore whenever Crushing Industry is installed
-- (prototypes/prismite-oreconv-vc.lua:118, the recipe and its coherence copy), but crushed prismite ore exists only while
-- Crushing Industry's startup setting "Crushed ore" is on (prototypes/prismite-common.lua:281); the crushed iron, copper
-- and coal conversions next to it check that setting (:111, :115). With the setting off the game stops at load with an
-- unknown item. The two sand recipes then take prismite ore, like the other conversions.
local RECIPES = {"s6x-prismiteconv-sand", "s6x-prismiteconv-coh-sand"}
local CRUSHED = "crushed-prismite-ore"
local ORE = "prismite-ore"

function crushed_prismite_sand.data_final_fixes()
	local items = data.raw.item or {}
	if items[CRUSHED] or not items[ORE] then
		return
	end
	for _, name in ipairs(RECIPES) do
		local recipe = data.raw.recipe and data.raw.recipe[name]
		for _, ingredient in ipairs(recipe and recipe.ingredients or {}) do
			if ingredient.name == CRUSHED then
				ingredient.name = ORE
				log("razi-protocol: " .. name .. " takes " .. ORE .. " instead of " .. CRUSHED
					.. ", which is not made with crushed ore off")
			end
		end
	end
end

return crushed_prismite_sand
