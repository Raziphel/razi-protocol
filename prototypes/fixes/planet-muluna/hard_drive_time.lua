local hard_drive_time = {}

-- planet-muluna 2.9.9 writes the craft time of the basic hard drive as `energy_require = 5`
-- (prototypes/recipe/crusher-recipes.lua:363), a field the game ignores, so the recipe takes the default 0.5 s.
-- The time the author wrote, 5 s, is set.
function hard_drive_time.data_final_fixes()
	---@type any
	local recipe = data.raw.recipe and data.raw.recipe["muluna-basic-hard-drive"]
	if recipe and recipe.energy_require == 5 and recipe.energy_required == nil then
		recipe.energy_required = 5
		recipe.energy_require = nil
		log("razi-protocol: muluna-basic-hard-drive takes 5 s, as its energy_require says")
	end
end

return hard_drive_time
