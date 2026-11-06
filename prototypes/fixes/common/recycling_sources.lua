local recycling_sources = {}

-- The recycler mod (part of the game since 2.1) builds "<item>-recycling" from every recipe in data-updates.lua
-- (recycler/data-updates.lua:4-6), and Krastorio2 2.1.4 runs the same generator over every recipe once more in
-- its data-final-fixes (prototypes/compatibility/recycler-final-fixes.lua:9-11). An item with several recipes
-- keeps the recycling recipe of the one defined last (pairs() runs in insertion order). Vanilla foundry casting
-- recipes set auto_recycle = false to stay out of that (so does Krastorio2-spaced-out since 2.0.18, which Razi
-- still accepts at 2.0.17). Two casting recipes forgot it: pelagos-casting-engine-unit in Pelagos 0.59.0
-- (prototypes/recipes/new.lua:471-486) and s6x-casting-mythril in Iridescent Industry 1.1.10
-- (prototypes/mythril.lua:69-88), so they became the source. An engine unit returns 0.75 activated carbon instead
-- of iron, a gear wheel and pipes; a mythril plate returns a quarter of a refined prismite instead of 1.25 mythril precursor.
--
-- The rule, for an item X: a recipe named X exists, is no metallurgy recipe and may be recycled
-- (auto_recycle is not false); another recipe with the metallurgy category, also without auto_recycle = false,
-- makes X; and X-recycling is what the recycler builds from that casting recipe, not from recipe X. A recycling
-- recipe that fits no casting recipe is not the known-bad one and stays: mods write some by hand (Cerys 4.25.0
-- forces the vanilla values for pipes, copper cable, concrete and others: compat/static-recycling.lua:4).
-- Then X-recycling gets the values that the recycler's own generate_recycling_recipe computes for recipe X, so
-- amounts and fractions are the vanilla ones. Only what depends on the reversed recipe is copied (results,
-- energy_required, crafting_machine_tint, subgroup). The rest of the current recipe stays: the enabled = true
-- that moon-eneas sets on every recycling recipe (prototypes/patches/tech.lua:29-33), the hidden flag, the
-- allowed_module_categories that other mods append.
-- Every call of the generator also appends an unlock-recipe effect to the recycling technology
-- (recycling.lua:196). The technology has one for each recipe that the recycler turned into X-recycling already
-- (two for each of these items), so the new one repeats them and is taken out again: the effects stay as they were.

-- This runs before the 2.1 category conversion of the foreign recipes, so a mod not yet updated for 2.1 may still
-- carry the old single "category" here.
local function has_category(recipe, category)
	if recipe.category == category then
		return true
	end
	if type(recipe.categories) ~= "table" then
		return false
	end

	for _, name in pairs(recipe.categories) do
		if name == category then
			return true
		end
	end

	return false
end

-- The item that a recipe makes; nil when it makes none or several different ones. The recycler names its recipe
-- after this item (and builds none for several), so it also tells which recycling recipe a call overwrites.
local function sole_item(recipe)
	local item_name

	for _, product in pairs(recipe.results or {}) do
		if product.type == "item" then
			if item_name and product.name ~= item_name then
				return nil
			end
			item_name = product.name
		end
	end

	return item_name
end

-- What a recipe returns, order-insensitive; %.9g hides float noise.
local function results_key(recipe)
	local keys = {}

	for _, product in pairs(recipe.results or {}) do
		keys[#keys + 1] = string.format("%s:%s:%.9g:%.9g", product.type or "item", product.name,
			product.amount or 0, product.extra_count_fraction or 0)
	end
	table.sort(keys)

	return table.concat(keys, "|")
end

local function unlocks_recipe(effects, recipe_name)
	for _, effect in pairs(effects) do
		if effect.type == "unlock-recipe" and effect.recipe == recipe_name then
			return true
		end
	end

	return false
end

-- The recycling recipe that the recycler builds from `recipe`; nil when it builds none (an opt-out, a random
-- amount, ...). The call overwrites data.raw.recipe[recycling_name], which is put back here; the unlock that it
-- appends to the recycling technology is left to the caller. The call must build recycling_name or nothing, or it
-- overwrites another recycling recipe: the sole_item of `recipe` must be the item behind recycling_name.
local function built_from(recycling, recipe, recycling_name)
	local recipes = data.raw.recipe
	local current = recipes[recycling_name]

	recycling.generate_recycling_recipe(recipe)
	local generated = recipes[recycling_name]
	recipes[recycling_name] = current

	if generated ~= current then
		return generated
	end

	return nil
end

-- The casting recipe that the recycler turns into a recycling recipe with exactly these results (a results_key);
-- nil when none does.
local function casting_source(recycling, casting_names, recycling_name, key)
	for _, casting_name in ipairs(casting_names) do
		local generated = built_from(recycling, data.raw.recipe[casting_name], recycling_name)

		if generated and results_key(generated) == key then
			return casting_name
		end
	end

	return nil
end

local function rebuild(recycling, item_name, casting_names)
	local recipes = data.raw.recipe
	local recycling_name = item_name .. "-recycling"
	local current = recipes[recycling_name]
	if not current then
		return
	end

	local technology = data.raw.technology and data.raw.technology.recycling
	local effects = technology and technology.effects
	local effect_count = effects and #effects or 0

	local wanted = built_from(recycling, recipes[item_name], recycling_name)
	local current_key = results_key(current)
	local casting_name
	if wanted and results_key(wanted) ~= current_key then
		casting_name = casting_source(recycling, casting_names, recycling_name, current_key)
	end

	-- The unlocks land in the effects table that the recycler captured when its module was loaded. That is this
	-- one unless a mod replaced the list since; then this one was not touched.
	local appended = false
	if effects then
		for index = #effects, effect_count + 1, -1 do
			effects[index] = nil
			appended = true
		end
	end

	-- Nothing to rebuild from (several item results, a random amount, ...), the same results, or a recycling
	-- recipe that no casting recipe made: keep the current recipe.
	if not (wanted and casting_name) then
		return
	end

	current.results = wanted.results
	current.energy_required = wanted.energy_required
	current.crafting_machine_tint = wanted.crafting_machine_tint
	current.subgroup = wanted.subgroup

	-- The unlock went astray and the technology has none for this recipe: it must not stay without one.
	if effects and not appended and not unlocks_recipe(effects, recycling_name) then
		table.insert(effects, { type = "unlock-recipe", recipe = recycling_name, hidden = true })
	end

	log("razi-protocol: " .. recycling_name .. " rebuilt from recipe " .. item_name .. " (was built from "
		.. casting_name .. ")")
end

function recycling_sources.data_final_fixes()
	local recipes = data.raw.recipe or {}

	-- Only items that a casting recipe makes can have lost their recycling recipe to it.
	local castings = {}
	for recipe_name, recipe in pairs(recipes) do
		if has_category(recipe, "metallurgy") and recipe.auto_recycle ~= false then
			local item_name = sole_item(recipe)

			if item_name and item_name ~= recipe_name then
				castings[item_name] = castings[item_name] or {}
				table.insert(castings[item_name], recipe_name)
			end
		end
	end

	local item_names = {}
	for item_name in pairs(castings) do
		item_names[#item_names + 1] = item_name
	end
	table.sort(item_names)

	local recycling
	for _, item_name in ipairs(item_names) do
		local recipe = recipes[item_name]

		if recipe and not has_category(recipe, "metallurgy") and sole_item(recipe) == item_name
			and recipe.auto_recycle ~= false and recipes[item_name .. "-recycling"] then
			-- Loaded only now: the library needs the recycler mod, and most sets have no such item.
			recycling = recycling or require("__recycler__.recycling")
			rebuild(recycling, item_name, castings[item_name])
		end
	end
end

return recycling_sources
