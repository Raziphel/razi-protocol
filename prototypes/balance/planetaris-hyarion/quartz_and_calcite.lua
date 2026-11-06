local quartz_and_calcite = {}

-- Hyarion turns 2 quartz into a calcite (particle manipulation), and calcite is 2 matter while a quartz is 0.13:
-- stone -> sand -> quartz -> calcite -> matter -> stone gains a factor 5 with the base productivity of the machines
-- alone, and matter prints quartz at 0.064 matter each. Closing it is a decision of this mod: matter no longer prints
-- quartz (kr-matter-to-kr-quartz is hidden) and the calcite costs 24 quartz (16 still left stone -> sand -> quartz ->
-- calcite -> matter -> sand at x0.64 with the base, x2.6 at +300 % quartz productivity; 24 break even only past
-- +130 %).
function quartz_and_calcite.data_final_fixes()
	local recipe = data.raw.recipe["planetaris-calcite-particle-manipulation"]

	if recipe then
		for _, ingredient in pairs(recipe.ingredients or {}) do
			if ingredient.name == "kr-quartz" and ingredient.amount == 2 then
				ingredient.amount = 24
				log("razi-protocol: planetaris-calcite-particle-manipulation takes 24 quartz")
			end
		end
	end

	require("prototypes.balance.common.hide_recipes").hide({ "kr-matter-to-kr-quartz" })
end

return quartz_and_calcite
