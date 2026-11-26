local M = {}

local function has_one_item_named(products, name)
	local count = 0
	for _, product in pairs(products or {}) do
		count = count + 1
		if type(product) ~= "table" or (product.type and product.type ~= "item")
			or (product.name or product[1]) ~= name then
			return false
		end
	end

	return count == 1
end

-- Only a surviving one-to-one bzcarbon graphite recipe makes the fallback unnecessary (bzcarbon/carbon-recipe.lua:38-63).
local function converts_flake_to_graphite(recipes)
	for _, recipe in pairs(recipes) do
		local has_one_graphite_result = recipe.results and has_one_item_named(recipe.results, "graphite")
			or (not recipe.results and recipe.result == "graphite")
		if has_one_graphite_result and has_one_item_named(recipe.ingredients, "flake-graphite") then
			return true
		end
	end

	return false
end

local function unlocks_recipe(effects, recipe_name)
	for _, effect in pairs(effects or {}) do
		if effect.type == "unlock-recipe" and effect.recipe == recipe_name then
			return true
		end
	end

	return false
end

function M.data_final_fixes()
	if not (mods and mods["bzcarbon"]) then
		return
	end

	local raw = data and data.raw or {}
	local items = raw.item or {}
	local technologies = raw.technology or {}
	local recipes = raw.recipe or {}
	local recipe_categories = raw["recipe-category"] or {}
	local technology = technologies["graphite-processing"]
	if not items["flake-graphite"] or not items.graphite or not technology
		or not recipe_categories["kr-crushing"] or recipes["razi-bz-graphite-from-flake"]
		or converts_flake_to_graphite(recipes) then
		return
	end

	data:extend({
		{
			type = "recipe",
			name = "razi-bz-graphite-from-flake",
			localised_name = { "item-name.graphite" },
			icons = {
				{ icon = "__bzcarbon__/graphics/icons/graphite.png", icon_size = 128 },
				{ icon = "__bzcarbon__/graphics/icons/flake-graphite.png", icon_size = 128, scale = 0.125, shift = { -8, -8 } },
			},
			categories = { "kr-crushing" },
			subgroup = "raw-material",
			order = "d[graphite]",
			enabled = false,
			auto_recycle = false,
			allow_productivity = true,
			energy_required = 0.25,
			ingredients = { { type = "item", name = "flake-graphite", amount = 1 } },
			results = { { type = "item", name = "graphite", amount = 1 } },
		},
	})

	technology.effects = technology.effects or {}
	if not unlocks_recipe(technology.effects, "razi-bz-graphite-from-flake") then
		technology.effects[#technology.effects + 1] = {
			type = "unlock-recipe",
			recipe = "razi-bz-graphite-from-flake",
		}
		if log then
			log("razi-protocol: bz: graphite-processing unlocks razi-bz-graphite-from-flake")
		end
	end
end

return M
