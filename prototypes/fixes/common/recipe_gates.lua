local recipe_gates = {}

-- Recipes that a mod unlocks with the wrong technology: the unlock moves to the technology that fits, and the recipe
-- starts disabled.
local function technology_unlocks(technology, recipe_name)
	for _, effect in ipairs(technology.effects or {}) do
		if effect.type == "unlock-recipe" and effect.recipe == recipe_name then
			return true
		end
	end

	return false
end

-- Removes every unlock-recipe effect for the recipe from a technology, if present. Returns whether one was removed.
local function remove_unlock(technology_name, recipe_name)
	local technology = data.raw.technology and data.raw.technology[technology_name]
	local removed = false
	if not technology or not technology.effects then
		return removed
	end

	for index = #technology.effects, 1, -1 do
		local effect = technology.effects[index]
		if effect.type == "unlock-recipe" and effect.recipe == recipe_name then
			table.remove(technology.effects, index)
			removed = true
		end
	end

	return removed
end

-- Moves the unlocks of the recipes from the technologies in `from` to `to`, and disables the recipes. Without the
-- target technology nothing changes, or the recipes would lose their only unlock.
function recipe_gates.move(recipes, from, to)
	local target = data.raw.technology and data.raw.technology[to]
	if not target then
		return
	end

	for _, recipe_name in ipairs(recipes) do
		local recipe = data.raw.recipe and data.raw.recipe[recipe_name]

		if recipe then
			local changed = false
			for _, technology_name in ipairs(from) do
				changed = remove_unlock(technology_name, recipe_name) or changed
			end

			if not technology_unlocks(target, recipe_name) then
				target.effects = target.effects or {}
				table.insert(target.effects, {type = "unlock-recipe", recipe = recipe_name})
				changed = true
			end

			if recipe.enabled ~= false then
				recipe.enabled = false
				changed = true
			end

			if changed then
				log("razi-protocol: " .. recipe_name .. " is unlocked by " .. to .. ", not by " .. table.concat(from, ", "))
			end
		end
	end
end

return recipe_gates
