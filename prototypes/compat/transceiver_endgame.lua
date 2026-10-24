local transceiver_endgame = {}
local Technology = require("__razi_lib__/lib/technology")

local transceiver_recipe = "kr-intergalactic-transceiver"
local original_transceiver_tech = "kr-intergalactic-transceiver"
local final_transceiver_tech = "razi-stable-intergalactic-singularity"

local function remove_recipe_unlock(technology_name, recipe_name)
	local technology = Technology.optional(technology_name)
	if technology then technology:remove_unlock(recipe_name) end
end

local function add_recipe_unlock(technology_name, recipe_name)
	local technology = Technology.optional(technology_name)
	if technology then technology:unlock(recipe_name) end
end

function transceiver_endgame.data_final_fixes()
	-- K2SO should still own the final charge/activation. We just move the recipe
	-- unlock behind our own test-fire research chain.
	remove_recipe_unlock(original_transceiver_tech, transceiver_recipe)
	add_recipe_unlock(final_transceiver_tech, transceiver_recipe)
end

return transceiver_endgame
