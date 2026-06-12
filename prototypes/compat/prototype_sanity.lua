local prototype_sanity = {}

local function recipe(name)
	return data.raw.recipe and data.raw.recipe[name]
end

local function item_exists(name)
	return
		(data.raw.item and data.raw.item[name]) or
		(data.raw.tool and data.raw.tool[name]) or
		(data.raw.module and data.raw.module[name]) or
		(data.raw["item-with-entity-data"] and data.raw["item-with-entity-data"][name]) or
		(data.raw["rail-planner"] and data.raw["rail-planner"][name]) or
		(data.raw["ammo"] and data.raw["ammo"][name]) or
		(data.raw["capsule"] and data.raw["capsule"][name]) or
		(data.raw["gun"] and data.raw["gun"][name]) or
		(data.raw["repair-tool"] and data.raw["repair-tool"][name]) or
		(data.raw["armor"] and data.raw["armor"][name]) or
		(data.raw["selection-tool"] and data.raw["selection-tool"][name]) or
		(data.raw["copy-paste-tool"] and data.raw["copy-paste-tool"][name]) or
		(data.raw["deconstruction-item"] and data.raw["deconstruction-item"][name]) or
		(data.raw["spidertron-remote"] and data.raw["spidertron-remote"][name])
end

local function ingredient_name(ingredient)
	return ingredient and (ingredient.name or ingredient[1])
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

local function harden_kr_sand_recipe()
	local sand_recipe = recipe("kr-sand")
	local crusher = data.raw.furnace and data.raw.furnace["kr-crusher"]
	if not sand_recipe or not crusher then
		return
	end

	-- Keep late recipe tweaks from accidentally turning sand into a generic
	-- assembler recipe. Stone -> sand should stay a crusher job.
	sand_recipe.category = "kr-crushing"
	sand_recipe.ingredients = {
		{type = "item", name = "stone", amount = 3}
	}
	sand_recipe.results = {
		{type = "item", name = "kr-sand", amount_min = 7, amount_max = 8}
	}
	sand_recipe.main_product = "kr-sand"
	crusher.crafting_categories = crusher.crafting_categories or {}

	local has_crushing = false
	for _, category in ipairs(crusher.crafting_categories) do
		if category == "kr-crushing" then
			has_crushing = true
			break
		end
	end

	if not has_crushing then
		table.insert(crusher.crafting_categories, "kr-crushing")
	end
end

function prototype_sanity.data_final_fixes()
	harden_kr_sand_recipe()
	-- Planetaris Arig/Tellus still exposes a few trigger-techs whose recipe names
	-- read like "glass panel" steps even though the crafts themselves produce the
	-- generic `glass` item. Trigger on the crafted item result directly so the
	-- Arig chain advances no matter which source recipe provided the glass.
	set_craft_trigger("planetaris-compression", "glass", 50)
	set_craft_trigger("planetaris-raw-diamond-production", "kr-quartz", 50)
	set_craft_trigger("condensing-agricultural-tower", "glass", 25)
	remove_result_if_missing("planetaris-cactus-mash", "planetaris-cactus-seeds")
	-- Hyarion's K2SO refraction chain is a Solaris-tier step. Crucible's
	-- broad data-updates sweep adds its science to any technology with the
	-- three inner-planet packs, which incorrectly drags this branch into
	-- Beetlejuice. Strip those late-added packs back out of the affected
	-- Hyarion techs and the K2SO research-data alias that players see.
	local hyarion_refraction_techs = {
		"planetaris-refraction-science-pack",
		"planetaris-particle-manipulation",
		"planetaris-beryllium-processing",
		"planetaris-space-facilities-1",
		"planetaris-zero-grav-accumulator",
		"planetaris-bismuth-processing",
		"planetaris-electromagnetic-radar"
	}
	local crucible_pack_aliases = {
		"planet-crucible-science-pack",
		"high-pressure-pack",
		"high-pressure-science-pack"
	}

	for _, ingredient_name_to_remove in ipairs(crucible_pack_aliases) do
		remove_ingredient_if_present("refraction-research-data", ingredient_name_to_remove)
		remove_ingredient_if_present("kr-refraction-research-data", ingredient_name_to_remove)

		for _, technology_name in ipairs(hyarion_refraction_techs) do
			remove_technology_ingredient_if_present(technology_name, ingredient_name_to_remove)
		end
	end
end

return prototype_sanity
