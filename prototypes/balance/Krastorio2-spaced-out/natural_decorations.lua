-- Razi Protocol does not let greenhouses manufacture trees or resource-bearing
-- decorations. K2/K2SO otherwise makes craftable trees and rocks from other
-- planets (including Ribbonia and Hyarion) available with kr-decorations.
-- These are never research unlocks, even after visiting the source planet.
local natural_decorations = {}

-- No assembler/furnace/greenhouse is given this category. It also prevents
-- already-researched recipes in existing saves from being crafted.
local disabled_category = "razi-disabled-natural-decorations"

local item_types = {
	"item",
	"item-with-tags",
	"item-with-entity-data",
	"item-with-inventory",
	"tool",
	"ammo",
	"capsule"
}

local function item_prototype(name)
	for _, prototype_type in ipairs(item_types) do
		local item = data.raw[prototype_type] and data.raw[prototype_type][name]
		if item then return item end
	end
end

local function has_category(recipe, category)
	if recipe.category == category then return true end
	for _, name in pairs(recipe.categories or {}) do
		if name == category then return true end
	end
	return false
end

local function products(recipe)
	if recipe.results then return recipe.results end
	if recipe.result then return {{type = "item", name = recipe.result}} end
	return {}
end

local function wood_only(recipe)
	local output = products(recipe)
	if #output == 0 then return false end
	for _, product in pairs(output) do
		if (product.type or "item") ~= "item" or product.name ~= "wood" then
			return false
		end
	end
	return true
end

local function has_other_mining_yield(entity, placed_item)
	local minable = entity and entity.minable
	if not minable then return false end
	if minable.result and minable.result ~= placed_item then return true end
	for _, result in pairs(minable.results or {}) do
		if result.name and result.name ~= placed_item then return true end
	end
	return false
end

local natural_subgroups = {trees = true, grass = true, rocks = true}

local function produces_craftable_nature(recipe)
	if natural_subgroups[recipe.subgroup] then return true end

	for _, product in pairs(products(recipe)) do
		if (product.type or "item") == "item" then
			local item = item_prototype(product.name)
			if item then
				if natural_subgroups[item.subgroup] then return true end

				local entity_name = item.place_result
				if type(entity_name) == "string" then
					if data.raw.tree and data.raw.tree[entity_name] then
						return true
					end

					-- Modded rocks, coral and mineral plants are often simple
					-- entities rather than trees. Only block craftable ones
					-- whose harvest yields a different item/resource.
					local simple = (data.raw["simple-entity"] or {})[entity_name]
						or (data.raw["simple-entity-with-owner"] or {})[entity_name]
					if has_other_mining_yield(simple, product.name) then
						return true
					end
				end
			end
		end
	end

	return false
end

function natural_decorations.data_final_fixes()
	local recipes = data.raw.recipe or {}
	local technologies = data.raw.technology or {}
	local disabled = {}

	-- Every recipe K2's decorative technology unlocks is part of the
	-- unwanted create-a-tree/rock mechanic. Do not trust the names alone:
	-- other planet mods keep adding new species to this technology.
	local decorations = technologies["kr-decorations"]
	for _, effect in pairs(decorations and decorations.effects or {}) do
		if effect.type == "unlock-recipe" and recipes[effect.recipe] then
			disabled[effect.recipe] = true
		end
	end

	for recipe_name, recipe in pairs(recipes) do
		-- Preserve the greenhouse's ordinary wood / fertilizer chain.
		-- K2SO's kr-yumako / kr-jellynut and future exotic growing recipes
		-- are intentionally not supported. Native agricultural towers stay.
		if (has_category(recipe, "kr-growing") and not wood_only(recipe))
			or produces_craftable_nature(recipe) then
			disabled[recipe_name] = true
		end
	end

	if not next(disabled) then return end

	if not ((data.raw["recipe-category"] or {})[disabled_category]) then
		data:extend({{type = "recipe-category", name = disabled_category}})
	end

	local count = 0
	for recipe_name in pairs(disabled) do
		local recipe = recipes[recipe_name]
		recipe.enabled = false
		recipe.hidden = true
		recipe.hidden_in_factoriopedia = true
		recipe.auto_recycle = false
		recipe.category = nil
		recipe.categories = {disabled_category}
		count = count + 1
	end

	-- A tech can unlock the same recipe from somewhere other than
	-- kr-decorations. Remove *all* those routes rather than just the early one.
	local removed_effects = 0
	for _, technology in pairs(technologies) do
		local effects = technology.effects or {}
		for index = #effects, 1, -1 do
			local effect = effects[index]
			if effect.type == "unlock-recipe" and disabled[effect.recipe] then
				table.remove(effects, index)
				removed_effects = removed_effects + 1
			end
		end
	end

	-- Keep the technology prototype around for compatibility with K2SO,
	-- which refers to it during data-final-fixes. Hide it if now useless.
	if decorations and #(decorations.effects or {}) == 0 then
		decorations.hidden = true
	end

	log("razi-protocol: disabled " .. count
		.. " craftable trees, rocks and exotic greenhouse recipes; removed "
		.. removed_effects .. " technology unlocks")
end

return natural_decorations
