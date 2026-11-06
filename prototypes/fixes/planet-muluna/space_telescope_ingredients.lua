-- The Muluna space telescope asks only for packs a laboratory accepts.
local helpers = require("prototypes.fixes.common.sanity_helpers")
local strip_non_lab_technology_ingredients = helpers.strip_non_lab_technology_ingredients

local space_telescope_ingredients = {}

function space_telescope_ingredients.data_final_fixes()
	-- Muluna copies the current vanilla-lab science list onto this technology in
	-- its own final-fixes pass. In larger mod stacks that can include non-tool
	-- placeholder items, which Factorio rejects for research units.
	strip_non_lab_technology_ingredients("muluna-space-telescope")
end

return space_telescope_ingredients
