-- Lookups and small edits of recipes and technologies that the repairs of single mods share.
local helpers = {}

local function recipe(name)
	return data.raw.recipe and data.raw.recipe[name]
end

local function first_existing_recipe(names)
	for _, name in ipairs(names) do
		local target_recipe = recipe(name)
		if target_recipe then
			return target_recipe, name
		end
	end

	return nil, nil
end

local function item_exists(name)
	for type_name in pairs(defines.prototypes.item) do
		local prototype = data.raw[type_name] and data.raw[type_name][name]
		if prototype then
			return prototype
		end
	end
end

local function first_existing_item(names)
	for _, name in ipairs(names) do
		if item_exists(name) then
			return name
		end
	end

	return nil
end

local function ingredient_name(ingredient)
	return ingredient and (ingredient.name or ingredient[1])
end

local function ingredient_type(ingredient)
	return ingredient and (ingredient.type or "item")
end

local function remove_result_if_missing(recipe_name, result_name)
	local target_recipe = recipe(recipe_name)
	if not target_recipe or not target_recipe.results or item_exists(result_name) then
		return
	end

	for index = #target_recipe.results, 1, -1 do
		local result = target_recipe.results[index]
		if (result.type == nil or result.type == "item") and ingredient_name(result) == result_name then
			table.remove(target_recipe.results, index)
		end
	end

	if target_recipe.main_product == result_name then
		target_recipe.main_product = nil
	end
end

local function remove_ingredient_if_present(recipe_name, ingredient_to_remove)
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

local function technology(name)
	return data.raw.technology and data.raw.technology[name]
end

local function technology_has_prerequisite(technology_name, prerequisite_name)
	local target_technology = technology(technology_name)
	if not target_technology then
		return false
	end

	for _, prerequisite in ipairs(target_technology.prerequisites or {}) do
		if prerequisite == prerequisite_name then
			return true
		end
	end

	return false
end

local function add_technology_prerequisite_if_present(technology_name, prerequisite_name)
	local target_technology = technology(technology_name)
	local prerequisite_technology = technology(prerequisite_name)
	if not target_technology or not prerequisite_technology then
		return
	end

	target_technology.prerequisites = target_technology.prerequisites or {}
	if not technology_has_prerequisite(technology_name, prerequisite_name) then
		table.insert(target_technology.prerequisites, prerequisite_name)
	end
end

local function remove_technology_ingredient_if_present(technology_name, ingredient_to_remove)
	local target_technology = technology(technology_name)
	if not target_technology or not target_technology.unit or not target_technology.unit.ingredients then
		return
	end

	for index = #target_technology.unit.ingredients, 1, -1 do
		if ingredient_name(target_technology.unit.ingredients[index]) == ingredient_to_remove then
			table.remove(target_technology.unit.ingredients, index)
		end
	end
end

local function technology_has_ingredient(technology_name, ingredient_name_to_find)
	local target_technology = technology(technology_name)
	if not target_technology or not target_technology.unit or not target_technology.unit.ingredients then
		return false
	end

	for _, ingredient in ipairs(target_technology.unit.ingredients) do
		if ingredient_name(ingredient) == ingredient_name_to_find then
			return true
		end
	end

	return false
end

local function replace_technology_ingredient_if_present(technology_name, ingredient_to_replace, replacement_name)
	local target_technology = technology(technology_name)
	if not target_technology or not target_technology.unit or not target_technology.unit.ingredients then
		return
	end

	local replacement_already_exists = technology_has_ingredient(technology_name, replacement_name)

	for index = #target_technology.unit.ingredients, 1, -1 do
		local current_ingredient = target_technology.unit.ingredients[index]
		if ingredient_name(current_ingredient) == ingredient_to_replace then
			if replacement_already_exists then
				table.remove(target_technology.unit.ingredients, index)
			else
				if current_ingredient.name then
					current_ingredient.name = replacement_name
				else
					current_ingredient[1] = replacement_name
				end
				replacement_already_exists = true
			end
		end
	end
end

local function lab_accepts(input_name)
	for _, lab in pairs(data.raw.lab or {}) do
		for _, lab_input in ipairs(lab.inputs or {}) do
			if lab_input == input_name then
				return true
			end
		end
	end

	return false
end

-- Factorio 2.1 science packs can be plain items (the vanilla packs and the
-- K2 tech cards are), so a research ingredient is valid when it is an item
-- of any type that some lab accepts, not only when it is a tool.
local function strip_non_lab_technology_ingredients(technology_name)
	local target_technology = technology(technology_name)
	if not target_technology or not target_technology.unit or not target_technology.unit.ingredients then
		return
	end

	for index = #target_technology.unit.ingredients, 1, -1 do
		local current_ingredient = target_technology.unit.ingredients[index]
		local current_name = ingredient_name(current_ingredient)
		if current_name and not (item_exists(current_name) and lab_accepts(current_name)) then
			table.remove(target_technology.unit.ingredients, index)
		end
	end
end

local function set_craft_trigger(technology_name, item_name, count)
	local target_technology = technology(technology_name)
	if not target_technology or not item_exists(item_name) then
		return
	end

	target_technology.unit = nil
	target_technology.research_trigger = {
		type = "craft-item",
		item = item_name,
		count = count
	}
end

local function ensure_recipe_unlock_copy(source_recipe_name, target_recipe_name)
	local source_recipe = recipe(source_recipe_name)
	local target_recipe = recipe(target_recipe_name)
	if not source_recipe or not target_recipe then
		return
	end

	for _, target_technology in pairs(data.raw.technology or {}) do
		local effects = target_technology.effects
		if effects then
			local has_source_unlock = false
			local has_target_unlock = false

			for _, effect in ipairs(effects) do
				if effect.type == "unlock-recipe" then
					if effect.recipe == source_recipe_name then
						has_source_unlock = true
					elseif effect.recipe == target_recipe_name then
						has_target_unlock = true
					end
				end
			end

			if has_source_unlock and not has_target_unlock then
				table.insert(effects, {
					type = "unlock-recipe",
					recipe = target_recipe_name
				})
			end
		end
	end
end

local function recipe_has_fluid_ingredient(target_recipe)
	for _, variant in ipairs({target_recipe, target_recipe.normal, target_recipe.expensive}) do
		if variant and variant.ingredients then
			for _, ingredient in ipairs(variant.ingredients) do
				if ingredient_type(ingredient) == "fluid" then
					return true
				end
			end
		end
	end

	return false
end

local function overwrite_recipe_variants(target_recipe, fields)
	for _, variant in ipairs({target_recipe, target_recipe.normal, target_recipe.expensive}) do
		if variant then
			for key, value in pairs(fields) do
				if type(value) == "table" then
					variant[key] = table.deepcopy(value)
				else
					variant[key] = value
				end
			end
		end
	end
end

helpers.recipe = recipe
helpers.first_existing_recipe = first_existing_recipe
helpers.item_exists = item_exists
helpers.first_existing_item = first_existing_item
helpers.ingredient_name = ingredient_name
helpers.ingredient_type = ingredient_type
helpers.remove_result_if_missing = remove_result_if_missing
helpers.remove_ingredient_if_present = remove_ingredient_if_present
helpers.technology = technology
helpers.technology_has_prerequisite = technology_has_prerequisite
helpers.add_technology_prerequisite_if_present = add_technology_prerequisite_if_present
helpers.remove_technology_ingredient_if_present = remove_technology_ingredient_if_present
helpers.technology_has_ingredient = technology_has_ingredient
helpers.replace_technology_ingredient_if_present = replace_technology_ingredient_if_present
helpers.lab_accepts = lab_accepts
helpers.strip_non_lab_technology_ingredients = strip_non_lab_technology_ingredients
helpers.set_craft_trigger = set_craft_trigger
helpers.ensure_recipe_unlock_copy = ensure_recipe_unlock_copy
helpers.recipe_has_fluid_ingredient = recipe_has_fluid_ingredient
helpers.overwrite_recipe_variants = overwrite_recipe_variants

return helpers
