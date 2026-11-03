local dry_ice = {}

-- Dry ice takes 50 cold fluoroketone and gives back 25 hot, which cools down to cold again. The hot fluoroketone is
-- not the fluid that went in, so balance/common/catalysts.lua does not see a catalyst, and a recipe with +100 %
-- productivity makes more than it uses (maraxsis-liquid-atmosphere already keeps its hot fluoroketone out). The 25
-- are kept out of productivity.
function dry_ice.data_final_fixes()
	local recipe = data.raw.recipe["dry-ice"]

	for _, product in pairs(recipe and recipe.results or {}) do
		if product.name == "fluoroketone-hot" and product.amount == 25 and product.ignored_by_productivity == nil then
			product.ignored_by_productivity = 25
			log("razi-protocol: dry-ice keeps its hot fluoroketone out of productivity")
		end
	end
end

return dry_ice
