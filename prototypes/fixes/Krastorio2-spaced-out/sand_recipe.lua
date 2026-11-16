-- kr-sand ends as a direct crusher recipe, whichever pass of the Krastorio 2 family touched it.
local helpers = require("prototypes.fixes.common.sanity_helpers")
local first_existing_recipe = helpers.first_existing_recipe
local first_existing_item = helpers.first_existing_item
local ensure_recipe_unlock_copy = helpers.ensure_recipe_unlock_copy
local recipe_has_fluid_ingredient = helpers.recipe_has_fluid_ingredient
local overwrite_recipe_variants = helpers.overwrite_recipe_variants

local kr_sand = {}

function kr_sand.data_final_fixes()
	local sand_recipe, sand_recipe_name = first_existing_recipe({"kr-sand", "sand"})
	local crusher = data.raw.furnace and data.raw.furnace["kr-crusher"]
	local sand_item_name = first_existing_item({"kr-sand", "sand"})
	if not sand_recipe or not crusher or not sand_item_name then
		return
	end

	local has_fluid_ingredients = recipe_has_fluid_ingredient(sand_recipe)

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

	-- Tighten this down aggressively: no matter which K2/K2SO branch touched the
	-- recipe, `kr-sand` should end up as a direct crusher recipe instead of
	-- leaving a hidden fluid variant behind on a difficulty-specific branch.
	overwrite_recipe_variants(sand_recipe, {
		categories = {"kr-crushing"},
		hidden = false,
		hidden_in_factoriopedia = false,
		hide_from_player_crafting = false,
		hide_from_stats = false,
		ingredients = {
			{type = "item", name = "stone", amount = 3}
		},
		results = {
			{type = "item", name = sand_item_name, amount_min = 7, amount_max = 8}
		},
		main_product = sand_item_name
	})

	-- Factorio 2.1 merges the old singular category and
	-- additional_categories fields into categories. Clear both legacy fields in
	-- case an upstream compatibility pass left them on any recipe variant.
	for _, variant in ipairs({sand_recipe, sand_recipe.normal, sand_recipe.expensive}) do
		if variant then
			variant.category = nil
			variant.additional_categories = nil
		end
	end

	if sand_recipe_name == "sand" then
		ensure_recipe_unlock_copy("kr-sand", "sand")
	end

	if has_fluid_ingredients and sand_recipe_name == "kr-sand" then
		sand_recipe.localised_description = {"recipe-description.kr-sand"}
	end
end

return kr_sand
