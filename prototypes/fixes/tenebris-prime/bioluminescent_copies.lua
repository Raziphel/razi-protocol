local bioluminescent_copies = {}

-- Tenebris Prime makes a bioluminescent copy of each machine (prototypes/bioluminescent.lua): no energy needed,
-- pressure exactly 3000, so it works on Tenebris only. The copies are made in its data stage and fall behind the
-- later changes of other mods. Tenebris repairs the two faults below itself in
-- prototypes/bioluminescent-final-fixes.lua, but that runs before the data-final-fixes of the mods that load after
-- it, so copies of machines changed there are still wrong. This pass runs after every other pass of this mod.
--
-- 1. A copy keeps the crafting categories its base had when it was copied. The bioluminescent chemical plant misses
--    vulcanization and the Muluna greenhouse, the advanced furnace metallurgy, the quantum computer and research
--    server the K2 tech cards (and keep the t2/t3 categories K2SO took away). Every copy takes the categories of its
--    base.
--
-- 2. A copy runs at the pressure of Tenebris even when its base is bound to another place: the K2 quantum computer
--    (pressure 800000, the Maraxsis trench), the K2 bio lab (1000), the greenhouse (1000..2525), the fungicultural
--    tower (gravity 8..9), the Moshine scanner (space). Their copies took those machines to Tenebris anyway. The
--    bioinfusion recipe of a copy whose base no surface condition lets onto Tenebris is hidden and loses its unlock, so
--    the copy can no longer be had. Recipes Tenebris wrote by hand for a copy stay: bio-agricultural-tower, the tower
--    that grows the plants of Tenebris, is meant to be. The item and the entity stay: deleting them would break the
--    recycling, crushing and crate recipes that name the item, and the game refuses a hidden item as the mining result
--    of an entity in an upgrade chain. A copy built before keeps working as it did.
--
-- 3. Tenebris also copies machines whose item another mod hides and stops making: K2SO's renames leave Flare Stack's
--    flare-stack, and the hidden kr-electric-mining-drill-mk3, kr-advanced-transport-belt and
--    planetaris-assembling-machine-4 have no recipe either. Their bioinfusion recipes ask for an item nothing makes,
--    so they are hidden and lose their unlock the same way.

local function property_value(tenebris, property)
	local own = tenebris.surface_properties and tenebris.surface_properties[property]
	if own ~= nil then
		return own
	end

	local prototype = data.raw["surface-property"] and data.raw["surface-property"][property]
	return prototype and prototype.default_value or 0
end

local function allowed_on_tenebris(tenebris, conditions)
	for _, condition in pairs(conditions or {}) do
		local value = property_value(tenebris, condition.property)
		if (condition.min and value < condition.min) or (condition.max and value > condition.max) then
			return false
		end
	end

	return true
end

local function same_list(left, right)
	if #left ~= #right then
		return false
	end
	for index, value in ipairs(left) do
		if right[index] ~= value then
			return false
		end
	end

	return true
end

-- A hidden item counts as obtainable only when a recipe that is not hidden makes it.
local function made_by_a_recipe(item_name)
	for _, recipe in pairs(data.raw.recipe) do
		if not recipe.hidden then
			for _, result in pairs(recipe.results or {}) do
				if result.name == item_name and result.type ~= "fluid" then
					return true
				end
			end
		end
	end

	return false
end

-- The first ingredient item of the recipe that is hidden and that no visible recipe makes, or nil.
local function unobtainable_ingredient(recipe)
	for _, ingredient in pairs(recipe.ingredients or {}) do
		if ingredient.type ~= "fluid" then
			local item = data.raw.item and data.raw.item[ingredient.name]
			if item and item.hidden and not made_by_a_recipe(ingredient.name) then
				return ingredient.name
			end
		end
	end

	return nil
end

function bioluminescent_copies.data_final_fixes()
	local tenebris = data.raw.planet and data.raw.planet.tenebris
	if not tenebris then
		return
	end

	local hidden_recipes = {}

	for type_name, entries in pairs(data.raw) do
		for name, copy in pairs(entries) do
			local base_name = type(copy) == "table" and copy.bioluminescent and name:match("^bioluminescent%-(.+)$")
			local base = base_name and entries[base_name]

			if base then
				if base.crafting_categories and copy.crafting_categories
					and not same_list(copy.crafting_categories, base.crafting_categories) then
					copy.crafting_categories = table.deepcopy(base.crafting_categories)
					log("razi-protocol: " .. type_name .. "/" .. name .. " takes the crafting categories of " .. base_name)
				end

				-- Only the bioinfusion recipe, which has the name of the copy: a recipe Tenebris wrote by hand for a copy
				-- (bio-agricultural-tower, the tower that grows the plants of Tenebris) is meant to be.
				local recipe = data.raw.recipe and data.raw.recipe[name]
				local bioinfusion = false
				for _, category in pairs(recipe and recipe.categories or {}) do
					bioinfusion = bioinfusion or category == "bioinfusion"
				end
				if bioinfusion and not recipe.hidden and not allowed_on_tenebris(tenebris, base.surface_conditions) then
					recipe.hidden = true
					recipe.enabled = false
					hidden_recipes[name] = true
					log("razi-protocol: " .. type_name .. "/" .. name .. " can no longer be made: its base cannot work on Tenebris")
				end
				local missing = bioinfusion and not recipe.hidden and unobtainable_ingredient(recipe)
				if missing then
					recipe.hidden = true
					recipe.enabled = false
					hidden_recipes[name] = true
					log("razi-protocol: " .. type_name .. "/" .. name .. " can no longer be made: its ingredient " .. missing
						.. " is hidden and no recipe makes it")
				end
			end
		end
	end

	for _, technology in pairs(data.raw.technology or {}) do
		local effects = technology.effects or {}
		for index = #effects, 1, -1 do
			local effect = effects[index]
			if effect and effect.type == "unlock-recipe" and hidden_recipes[effect.recipe] then
				table.remove(effects, index)
			end
		end
	end
end

return bioluminescent_copies
