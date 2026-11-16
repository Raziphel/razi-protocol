local hide_recipes = {}

-- Takes working recipes out of the game for the balance files: a recipe is disabled and hidden, its unlock effects go,
-- and a technology left with nothing to unlock is hidden unless another technology requires it. Recipes that do not
-- exist are skipped.
function hide_recipes.hide(names, recipe_log_message)
	local removed = {}
	for _, name in ipairs(names) do
		local recipe = data.raw.recipe[name]
		if recipe then
			local changed = recipe.hidden ~= true or recipe.enabled ~= false
			recipe.enabled = false
			recipe.hidden = true
			removed[name] = true
			if changed then
				log(recipe_log_message and recipe_log_message(name)
					or "razi-protocol: recipe " .. name .. " hidden")
			end
		end
	end

	local emptied = {}
	for technology_name, technology in pairs(data.raw.technology) do
		local effects = technology.effects or {}
		local had = #effects
		for index = #effects, 1, -1 do
			local effect = effects[index]
			if effect and effect.type == "unlock-recipe" and removed[effect.recipe] then
				table.remove(effects, index)
			end
		end
		if had > 0 and #effects == 0 then
			emptied[technology_name] = true
		end
	end

	for _, technology in pairs(data.raw.technology) do
		for _, prerequisite in pairs(technology.prerequisites or {}) do
			emptied[prerequisite] = nil
		end
	end

	for technology_name in pairs(emptied) do
		data.raw.technology[technology_name].hidden = true
		log("razi-protocol: technology " .. technology_name .. " hidden: nothing left to unlock")
	end

	return emptied
end

return hide_recipes
