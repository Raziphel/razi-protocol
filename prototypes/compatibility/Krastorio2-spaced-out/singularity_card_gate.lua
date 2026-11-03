-- The Krastorio singularity card stays in the transceiver finale, out of the early Deep Space card.
local helpers = require("prototypes.fixes.common.progression_helpers")
local remove_recipe_ingredient = helpers.remove_recipe_ingredient

local singularity_card_gate = {}

function singularity_card_gate.data_final_fixes()
	-- The black deep-space card is the Nexus/Promethium bridge. K2 singularity
	-- cards should stay in the transceiver finale, not sneak into this earlier
	-- recipe and make the tree look like the ending starts too soon.
	remove_recipe_ingredient("deep-space-tech-card", "kr-singularity-tech-card")
end

return singularity_card_gate
