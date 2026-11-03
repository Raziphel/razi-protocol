-- Lookups and small edits of technologies and recipes that the progression passes share.
local helpers = {}

local function technology(name)
	return data.raw.technology and data.raw.technology[name]
end

local function recipe(name)
	return data.raw.recipe and data.raw.recipe[name]
end

local function recipe_exists(name)
	return recipe(name) ~= nil
end

-- Factorio 2.1 science packs can be plain items (the vanilla packs are).
local function science_pack_exists(name)
	return (data.raw.tool and data.raw.tool[name] ~= nil) or (data.raw.item and data.raw.item[name] ~= nil)
end

local function technology_exists(name)
	return technology(name) ~= nil
end

local function add_prerequisite(tech, prerequisite)
	if not tech or not technology_exists(prerequisite) then
		return
	end

	tech.prerequisites = tech.prerequisites or {}
	for _, existing in ipairs(tech.prerequisites) do
		if existing == prerequisite then
			return
		end
	end

	table.insert(tech.prerequisites, prerequisite)
end

local function set_order_if_present(technology_name, order)
	local target_technology = technology(technology_name)
	if target_technology then
		target_technology.order = order
	end
end

local function set_hidden_flags(prototype)
	if not prototype then
		return
	end

	prototype.hidden = true
	prototype.hidden_in_factoriopedia = true
end

local function remove_prerequisite(tech, prerequisite)
	if not tech or not tech.prerequisites then
		return
	end

	for index = #tech.prerequisites, 1, -1 do
		if tech.prerequisites[index] == prerequisite then
			table.remove(tech.prerequisites, index)
		end
	end
end

local function set_recipe_enabled_state(target_recipe, enabled)
	if not target_recipe then
		return
	end

	target_recipe.enabled = enabled
	for _, variant in ipairs({target_recipe.normal, target_recipe.expensive}) do
		if variant then
			variant.enabled = enabled
		end
	end
end

local function science_ingredients(science_packs)
	local ingredients = {}

	for _, science_pack in ipairs(science_packs) do
		if science_pack_exists(science_pack) then
			table.insert(ingredients, {science_pack, 1})
		end
	end

	return ingredients
end

local function ingredient_name(ingredient)
	return ingredient and (ingredient.name or ingredient[1])
end

local function recipe_has_ingredient(recipe_name, ingredient_to_find)
	local target_recipe = recipe(recipe_name)
	if not target_recipe or not target_recipe.ingredients then
		return false
	end

	for _, ingredient in ipairs(target_recipe.ingredients) do
		if ingredient_name(ingredient) == ingredient_to_find then
			return true
		end
	end

	return false
end

local function remove_recipe_ingredient(recipe_name, ingredient_to_remove)
	local target_recipe = recipe(recipe_name)
	if not target_recipe or not target_recipe.ingredients then
		return
	end

	for index = #target_recipe.ingredients, 1, -1 do
		if ingredient_name(target_recipe.ingredients[index]) == ingredient_to_remove then
			table.remove(target_recipe.ingredients, index)
		end
	end
end

local function technology_has_unlock(technology_name, recipe_name)
	local target_technology = technology(technology_name)
	if not target_technology or not target_technology.effects then
		return false
	end

	for _, effect in ipairs(target_technology.effects) do
		if effect.type == "unlock-recipe" and effect.recipe == recipe_name then
			return true
		end
	end

	return false
end

local function add_recipe_unlock(technology_name, recipe_name)
	local target_technology = technology(technology_name)
	if not target_technology or not recipe_exists(recipe_name) then
		return
	end

	target_technology.effects = target_technology.effects or {}
	if not technology_has_unlock(technology_name, recipe_name) then
		table.insert(target_technology.effects, {
			type = "unlock-recipe",
			recipe = recipe_name
		})
	end
end

local function remove_recipe_unlock(technology_name, recipe_name)
	local target_technology = technology(technology_name)
	if not target_technology or not target_technology.effects then
		return
	end

	for index = #target_technology.effects, 1, -1 do
		local effect = target_technology.effects[index]
		if effect.type == "unlock-recipe" and effect.recipe == recipe_name then
			table.remove(target_technology.effects, index)
		end
	end
end

local function technology_has_dependents(technology_name)
	for _, target_technology in pairs(data.raw.technology or {}) do
		for _, prerequisite in ipairs(target_technology.prerequisites or {}) do
			if prerequisite == technology_name then
				return true
			end
		end
	end

	return false
end

local function first_existing_technology(names)
	for _, name in ipairs(names) do
		if technology_exists(name) then
			return name
		end
	end

	return nil
end

local function gate_recipe_to_technology(recipe_names, technology_names, stale_unlock_technologies)
	local unlock_technology_name = first_existing_technology(technology_names)
	if not unlock_technology_name then
		return
	end

	for _, recipe_name in ipairs(recipe_names) do
		local target_recipe = recipe(recipe_name)
		if target_recipe then
			set_recipe_enabled_state(target_recipe, false)
			add_recipe_unlock(unlock_technology_name, recipe_name)

			for _, stale_unlock_name in ipairs(stale_unlock_technologies or {}) do
				if stale_unlock_name ~= unlock_technology_name then
					remove_recipe_unlock(stale_unlock_name, recipe_name)
				end
			end
		end
	end
end

helpers.technology = technology
helpers.recipe = recipe
helpers.recipe_exists = recipe_exists
helpers.science_pack_exists = science_pack_exists
helpers.technology_exists = technology_exists
helpers.add_prerequisite = add_prerequisite
helpers.set_order_if_present = set_order_if_present
helpers.set_hidden_flags = set_hidden_flags
helpers.remove_prerequisite = remove_prerequisite
helpers.set_recipe_enabled_state = set_recipe_enabled_state
helpers.science_ingredients = science_ingredients
helpers.ingredient_name = ingredient_name
helpers.recipe_has_ingredient = recipe_has_ingredient
helpers.remove_recipe_ingredient = remove_recipe_ingredient
helpers.technology_has_unlock = technology_has_unlock
helpers.add_recipe_unlock = add_recipe_unlock
helpers.remove_recipe_unlock = remove_recipe_unlock
helpers.technology_has_dependents = technology_has_dependents
helpers.first_existing_technology = first_existing_technology
helpers.gate_recipe_to_technology = gate_recipe_to_technology

return helpers
