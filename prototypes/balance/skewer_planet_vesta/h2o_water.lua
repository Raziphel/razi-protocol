local h2o_water = {}

-- Vesta's ske_h2o gives 30 water for 20 hydrogen and 10 oxygen. Every electrolysis of the installed mods makes about
-- one hydrogen from a water or fewer (Shchierbin, Muria 2 per water, Krastorio 3 per 5), so a round of water ->
-- hydrogen -> water gives 1.5 to 3 times the water, with power as the only cost: water, hydrogen and oxygen out of
-- nothing on every planet with Vesta's recipes, also on platforms. It is no productivity loop (the recipes already
-- take none, see prototypes/balance/common/water_loop.lua), only the unit of the recipe. The recipe gives 6 water, so
-- that 100 hydrogen come back as 30 water for the 100 that made them with Shchierbin's electrolysis.
function h2o_water.data_final_fixes()
	local recipe = data.raw.recipe["ske_h2o"]

	if recipe then
		for _, product in pairs(recipe.results or {}) do
			if product.name == "water" and product.amount == 30 then
				product.amount = 6
				if product.ignored_by_productivity == 30 then
					product.ignored_by_productivity = 6
				end
				if product.ignored_by_stats == 30 then
					product.ignored_by_stats = 6
				end
				log("razi-protocol: ske_h2o gives 6 water, not 30")
			end
		end
	end
end

return h2o_water
