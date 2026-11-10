local recipe_gates = require("prototypes.fixes.common.recipe_gates")

local pelagos_recipe_gates = {}

-- Pelagos clones the electronic components recipe of Krastorio 2 Spaced Out and unlocks the clone with the early
-- advanced-circuit technology (prototypes/recipes/new.lua:877-901 of 0.59.0). Its surface condition prevents crafting
-- away from Pelagos, but the recipe still appears unlocked before the planet is discovered. It moves beside
-- coconut-sealant, its planet-specific ingredient.
function pelagos_recipe_gates.data_final_fixes()
	recipe_gates.move({"pelagos-electronic-components"}, {"advanced-circuit"}, "coconut-processing-technology")
end

return pelagos_recipe_gates
