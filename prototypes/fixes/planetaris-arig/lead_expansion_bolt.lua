-- Arig adds these ingredients without checking whether bzlead created the bolt
-- (planetaris-arig/compat/bzlead.lua:17-18); bzlead creates the item only when
-- more_entities is enabled (bzlead/lead-recipe.lua:101-129; bzlead/me.lua:15).
-- Fix the recipes in data so quality's later data-updates recycling pass copies lead-plate.
local M = {}

local RECIPE_NAMES = {
	"planetaris-advanced-solar-panel",
	"planetaris-water-harvester",
}

local function replace_bolt_ingredient(recipe)
	local ingredients = recipe.ingredients or {}
	local lead_plate
	for _, ingredient in ipairs(ingredients) do
		if ingredient.name == "lead-plate" then
			lead_plate = ingredient
			break
		end
	end

	local changed = false
	local index = 1
	while index <= #ingredients do
		local ingredient = ingredients[index]
		if ingredient.name == "lead-expansion-bolt" then
			if lead_plate then
				lead_plate.amount = lead_plate.amount + ingredient.amount
				table.remove(ingredients, index)
			else
				ingredient.name = "lead-plate"
				lead_plate = ingredient
				index = index + 1
			end
			changed = true
		else
			index = index + 1
		end
	end

	return changed
end

function M.data()
	if not (mods and mods["planetaris-arig"] and mods["bzlead"]) then
		return
	end

	local raw = data and data.raw or {}
	if (raw.item or {})["lead-expansion-bolt"] then
		return
	end

	local recipes = raw.recipe or {}
	for _, name in ipairs(RECIPE_NAMES) do
		local recipe = recipes[name]
		if recipe and replace_bolt_ingredient(recipe) then
			log("razi-protocol: bz: " .. name .. ": lead-expansion-bolt -> lead-plate")
		end
	end
end

return M
