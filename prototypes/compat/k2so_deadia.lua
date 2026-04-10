local function get_ingredient_name(ingredient)
	if type(ingredient) ~= "table" then
		return nil
	end

	return ingredient.name or ingredient[1]
end

local function get_ingredient_type(ingredient)
	if type(ingredient) ~= "table" then
		return nil
	end

	if ingredient.type then
		return ingredient.type
	end

	local ingredient_name = get_ingredient_name(ingredient)
	if ingredient_name and data.raw and data.raw.fluid and data.raw.fluid[ingredient_name] then
		return "fluid"
	end

	return "item"
end

local function normalize_ingredient(existing_ingredients, ingredient)
	local first = existing_ingredients and existing_ingredients[1]
	if type(first) == "table" and first.name == nil and first[1] ~= nil then
		return { ingredient.name, ingredient.amount }
	end

	return ingredient
end

local function add_ingredient_if_missing(ingredients, ingredient)
	if not ingredients then
		return
	end

	local ingredient_name = get_ingredient_name(ingredient)
	local ingredient_type = get_ingredient_type(ingredient)
	for _, existing in pairs(ingredients) do
		if get_ingredient_name(existing) == ingredient_name and get_ingredient_type(existing) == ingredient_type then
			return
		end
	end

	table.insert(ingredients, normalize_ingredient(ingredients, ingredient))
end


local function add_science_pack_to_technology(technology_name, science_pack_name)
	local technology = data.raw.technology and data.raw.technology[technology_name]
	if not technology or not technology.unit or not technology.unit.ingredients then
		return
	end

	add_ingredient_if_missing(technology.unit.ingredients, {
		type = "item",
		name = science_pack_name,
		amount = 1,
	})
end

local function add_recipe_ingredient(recipe_name, ingredient)
	local recipe = data.raw.recipe and data.raw.recipe[recipe_name]
	if not recipe then
		return
	end

	if recipe.ingredients then
		add_ingredient_if_missing(recipe.ingredients, ingredient)
	end

	if recipe.normal and recipe.normal.ingredients then
		add_ingredient_if_missing(recipe.normal.ingredients, ingredient)
	end

	if recipe.expensive and recipe.expensive.ingredients then
		add_ingredient_if_missing(recipe.expensive.ingredients, ingredient)
	end
end

if mods["Krastorio2-spaced-out"] and mods["dea-dia-system"] then
	-- Make Dea Dia sciences relevant in K2SO late-game milestones.
	add_science_pack_to_technology("kr-matter-processing", "insulation-science-pack")
	add_science_pack_to_technology("kr-matter-cube", "thermodynamic-science-pack")
	add_science_pack_to_technology("kr-planetary-teleporter", "aerospace-science-pack")

	-- Feed K2SO planetary research data back into Dea Dia science production.
	add_recipe_ingredient("insulation-science-pack", {
		type = "item",
		name = "kr-agricultural-research-data",
		amount = 1,
	})
	add_recipe_ingredient("thermodynamic-science-pack", {
		type = "item",
		name = "kr-cryogenic-research-data",
		amount = 1,
	})
	add_recipe_ingredient("aerospace-science-pack", {
		type = "item",
		name = "kr-electromagnetic-research-data",
		amount = 1,
	})
end


if mods["apia"] and mods["dea-dia-system"] then
	-- Tighten integration: Apia science production requires Dea Dia progression materials.
	add_recipe_ingredient("apicultural-science-pack", {
		type = "item",
		name = "insulation-science-pack",
		amount = 1,
	})

	-- Make Dea Dia's highest science also consume Apia output to interlock both mod chains.
	add_recipe_ingredient("aerospace-science-pack", {
		type = "item",
		name = "apicultural-science-pack",
		amount = 1,
	})
end
