local transceiver_endgame = {}

local transceiver_recipe = "kr-intergalactic-transceiver"
local original_transceiver_tech = "kr-intergalactic-transceiver"
local final_transceiver_tech = "razi-stable-intergalactic-singularity"

local function remove_recipe_unlock(technology_name, recipe_name)
	local technology = data.raw.technology and data.raw.technology[technology_name]
	if not technology or not technology.effects then
		return
	end

	for index = #technology.effects, 1, -1 do
		local effect = technology.effects[index]
		if effect.type == "unlock-recipe" and effect.recipe == recipe_name then
			table.remove(technology.effects, index)
		end
	end
end

local function add_recipe_unlock(technology_name, recipe_name)
	local technology = data.raw.technology and data.raw.technology[technology_name]
	if not technology then
		return
	end

	technology.effects = technology.effects or {}
	for _, effect in ipairs(technology.effects) do
		if effect.type == "unlock-recipe" and effect.recipe == recipe_name then
			return
		end
	end

	table.insert(technology.effects, {
		type = "unlock-recipe",
		recipe = recipe_name
	})
end

function transceiver_endgame.data_final_fixes()
	-- K2SO should still own the final charge/activation. We just move the recipe
	-- unlock behind our own test-fire research chain.
	remove_recipe_unlock(original_transceiver_tech, transceiver_recipe)
	add_recipe_unlock(final_transceiver_tech, transceiver_recipe)
end

return transceiver_endgame
