local fuel_liquefaction = {}

-- Secretas solid-fuel-liquefaction takes 5 solid fuel and 50 heavy oil and gives 120 heavy oil back
-- (prototypes/recipe.lua:358-388), 70 more. Cracked to light oil and turned into solid fuel, those 70 give 5.25 solid
-- fuel, more than went in: the loop grows by itself, faster with productivity (issue #74). Without productivity and
-- with 100 heavy oil out, the 50 gained make 3.75 solid fuel, less than the 5 spent, and the recipe still turns
-- solid fuel into oil.
--
-- allow_productivity = false does not stop the +50 % base productivity of the electrochemical plant (see
-- prototypes/balance/common/catalysts.lua), which still gives 8.2 solid fuel for 5, so the recipe takes
-- maximum_productivity = 0 and gives 90 heavy oil: 40 net, 2 solid fuel a round, 4.4 with the heavy oil recipe.
function fuel_liquefaction.data_final_fixes()
	local recipe = data.raw.recipe["solid-fuel-liquefaction"]
	if not recipe then
		return
	end

	if recipe.allow_productivity ~= false then
		recipe.allow_productivity = false
		log("razi-protocol: solid-fuel-liquefaction takes no productivity modules")
	end
	for _, product in pairs(recipe.results or {}) do
		local heavy = product.name == "heavy-oil" and type(product.amount) == "number"
		if heavy and product.amount > 100 then
			product.amount = 100
		end
		if heavy and product.amount == 100 then
			product.amount = 90
			log("razi-protocol: solid-fuel-liquefaction gives 90 heavy oil")
		end
	end
	if recipe.maximum_productivity ~= 0 then
		recipe.maximum_productivity = 0
		log("razi-protocol: solid-fuel-liquefaction takes no base productivity either")
	end
end

return fuel_liquefaction
