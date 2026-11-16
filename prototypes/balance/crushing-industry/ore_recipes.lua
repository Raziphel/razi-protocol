-- Crushing Industry's "Crushed ore" setting rewrites these recipes on purpose
-- (crushing-industry_0.6.9/base-data-updates.lua:30,42-62). That balance choice
-- belongs here. Its 75:50 ratios are neutral, but the crushing step stays optional:
-- players can still crush ore for smelting and Krastorio 2 enrichment.
local RECIPES = {
	{recipe = "concrete", crushed = "crushed-iron-ore", ore = "iron-ore", factor = 1},
	{recipe = "iron-ore-melting", crushed = "crushed-iron-ore", ore = "iron-ore", factor = 1.5},
	{recipe = "copper-ore-melting", crushed = "crushed-copper-ore", ore = "copper-ore", factor = 1.5},
	{recipe = "advanced-thruster-oxidizer", crushed = "crushed-iron-ore", ore = "iron-ore", factor = 2},
	{recipe = "tungsten-plate", crushed = "crushed-tungsten-ore", ore = "tungsten-ore", factor = 2},
	{recipe = "holmium-solution", crushed = "holmium-powder", ore = "holmium-ore", factor = 1.5},
}

local ore_recipes = {}

function ore_recipes.data_final_fixes()
	local crushing_ore = settings and settings.startup and settings.startup["crushing-industry-ore"]
	if not (mods and mods["crushing-industry"] and crushing_ore and crushing_ore.value == true) then
		return
	end

	local raw = data and data.raw
	if not raw then
		return
	end

	local holmium_changed = false
	for _, entry in ipairs(RECIPES) do
		local recipe = raw.recipe and raw.recipe[entry.recipe]
		local ingredients = recipe and recipe.ingredients
		local ore_exists = raw.item and raw.item[entry.ore]
		if type(ingredients) == "table" and ore_exists then
			local has_ore = false
			---@type {name?: string, amount?: number}|nil
			local crushed_ingredient
			for _, ingredient in ipairs(ingredients) do
				if type(ingredient) == "table" then
					if ingredient.name == entry.ore then
						has_ore = true
					elseif ingredient.type == "item" and ingredient.name == entry.crushed then
						crushed_ingredient = crushed_ingredient or ingredient
					end
				end
			end

			local amount = crushed_ingredient and crushed_ingredient.amount
			local replacement_amount = type(amount) == "number" and amount / entry.factor
			if not has_ore and crushed_ingredient and replacement_amount and replacement_amount >= 1 and replacement_amount % 1 == 0 then
				crushed_ingredient.name = entry.ore
				crushed_ingredient.amount = replacement_amount
				log("razi-protocol: " .. entry.recipe .. " takes " .. replacement_amount .. " " .. entry.ore
					.. " instead of " .. amount .. " " .. entry.crushed .. ", crushing the ore stays optional")
				if entry.recipe == "holmium-solution" then
					holmium_changed = true
				end
			end
		end
	end

	if holmium_changed then
		require("prototypes.balance.common.hide_recipes").hide({"holmium-powder"})
	end
end

return ore_recipes
