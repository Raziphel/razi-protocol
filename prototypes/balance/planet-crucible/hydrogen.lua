local hydrogen = {}

-- Crucible's hot hydrogen recipes give more hydrogen than the water and ammonia recipes of the other planet mods take,
-- and Vesta's ske_h2o and the Krastorio / Shchierbin ammonia recipes turn it back into water and ammonia:
-- - space electrolysis: 100 water -> 500 hydrogen + 250 oxygen with productivity (+135 % in the electromagnetic
--   plant) feeds 25 ske_h2o, 750 water for 100;
-- - ammonia reforming: 100 ammonia -> 750 hydrogen, and 30 hydrogen make 30 ammonia on Vesta, 30 on K2.
-- Space electrolysis gives 250 hydrogen and takes no productivity; the ammonia recipe is hidden (Crucible's lithium
-- hydride only needs the hot hydrogen of planet-crucible-hydrogen from steam).
function hydrogen.data_final_fixes()
	local recipe = data.raw.recipe["planet-crucible-space-electrolysis"]

	if recipe then
		for _, product in pairs(recipe.results or {}) do
			if product.name == "kr-hydrogen" and product.amount == 500 then
				product.amount = 250
				recipe.allow_productivity = false
				recipe.maximum_productivity = 0
				log("razi-protocol: planet-crucible-space-electrolysis gives 250 hydrogen, no productivity")
			end
		end
	end

	require("prototypes.balance.common.hide_recipes").hide({ "planet-crucible-hydrogen-from-ammonia" })
end

return hydrogen
