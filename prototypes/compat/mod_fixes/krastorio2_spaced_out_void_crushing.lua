local void_crushing = {}

-- The Krastorio 2 crusher is a furnace with two categories, kr-crushing and kr-void-crushing, and picks the recipe by
-- what goes in. Four items have both a real crushing recipe and a void one that destroys them: Planetaris wasp eggs,
-- fossil larvae, bones and Crucible skarn. The crusher may take the void recipe and quietly destroy its input. The void
-- recipe of an item that has a real crushing recipe is removed, with every technology effect that names it.
-- Only a crushing recipe that takes that one item counts: a recipe with several ingredients (the rocket salvage tiers
-- take rocket chunks with holmium plates, ice or processing units) does not crush its ingredients, so the void recipe
-- of holmium plate, ice and processing unit stays.

local function has_category(recipe, category)
	for _, name in pairs(recipe.categories or {}) do
		if name == category then
			return true
		end
	end

	return false
end

local function item_ingredients(recipe)
	local items = {}
	for _, ingredient in pairs(recipe.ingredients or {}) do
		if ingredient.type == nil or ingredient.type == "item" then
			items[#items + 1] = ingredient
		end
	end

	return items
end

function void_crushing.data_final_fixes()
	local crushed = {}
	for _, recipe in pairs(data.raw.recipe or {}) do
		if has_category(recipe, "kr-crushing") then
			local items = item_ingredients(recipe)
			if #items == 1 then
				crushed[items[1].name] = true
			end
		end
	end

	local removed = {}
	for name, recipe in pairs(data.raw.recipe or {}) do
		if has_category(recipe, "kr-void-crushing") then
			for _, ingredient in pairs(recipe.ingredients or {}) do
				if crushed[ingredient.name] then
					removed[name] = true
				end
			end
		end
	end

	for name in pairs(removed) do
		data.raw.recipe[name] = nil
		log("razi-protocol: removed void crushing recipe " .. name .. " (its item has a real crushing recipe)")
	end

	for _, technology in pairs(data.raw.technology or {}) do
		local effects = technology.effects or {}
		for index = #effects, 1, -1 do
			local effect = effects[index]
			if effect and removed[effect.recipe] then
				table.remove(effects, index)
			end
		end
	end
end

return void_crushing
