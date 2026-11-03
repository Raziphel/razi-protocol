local fluoroketone_catalyst = {}

-- Every plasma recipe of plasma_crafter returns its hot fluoroketone outside productivity, but plasma-carbon-fiber
-- does not (prototypes/recipes.lua:175). In a biochamber (+50 % base productivity) 5 plasma, made 1:1 from cold
-- fluoroketone in a fusion reactor, come back as 7.5 hot fluoroketone, which cools down to cold: endless fluoroketone.
-- The returned fluid is a catalyst, as in the other plasma recipes.
function fluoroketone_catalyst.data_final_fixes()
	local recipe = data.raw.recipe["plasma-carbon-fiber"]

	for _, product in pairs(recipe and recipe.results or {}) do
		if product.name == "fluoroketone-hot" and not product.ignored_by_productivity then
			product.ignored_by_productivity = product.amount
			log("razi-protocol: plasma-carbon-fiber fluoroketone-hot ignored_by_productivity = " .. tostring(product.amount))
		end
	end
end

return fluoroketone_catalyst
