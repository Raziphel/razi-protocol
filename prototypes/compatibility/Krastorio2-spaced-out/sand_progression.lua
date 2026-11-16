-- Sand processing follows the crusher, and glass follows sand.
local helpers = require("prototypes.fixes.common.progression_helpers")
local technology = helpers.technology
local add_prerequisite = helpers.add_prerequisite
local set_hidden_flags = helpers.set_hidden_flags
local remove_recipe_unlock = helpers.remove_recipe_unlock
local technology_has_dependents = helpers.technology_has_dependents

local sand_progression = {}

function sand_progression.data_final_fixes()
	local sand_processing = technology("sand-processing")
	if not sand_processing then
		return
	end

	add_prerequisite(sand_processing, "kr-crusher")
	remove_recipe_unlock("sand-processing", "sand")
	remove_recipe_unlock("sand-processing", "kr-sand")

	local glass_processing = technology("glass-processing")
	if glass_processing then
		add_prerequisite(glass_processing, "sand-processing")
	end

	-- If the old AAI-style sand tech no longer owns any visible unlocks and the
	-- rest of the tree does not point at it, hide it instead of leaving a dead
	-- early node cluttering the menu.
	if sand_processing.effects and #sand_processing.effects == 0 and not technology_has_dependents("sand-processing") then
		set_hidden_flags(sand_processing)
	end
end

return sand_progression
