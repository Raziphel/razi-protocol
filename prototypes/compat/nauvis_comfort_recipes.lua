-- The stack inserter and the toolbelt equipment are researched on Nauvis (technology/nauvis_comforts.lua), but Space Age makes them of
-- carbon fiber and jelly, which only Gleba produces. Here they are made of what Nauvis has: the stack inserter takes one low density
-- structure for the two carbon fibers and ten plastic bars for the ten jelly, the toolbelt equipment three low density structures for
-- the ten carbon fibers. A recipe is changed only while it still holds the original ingredients.
-- The recycling and the Krastorio crushing of the two items return what the recipe takes, so they return the new ingredients: they
-- would otherwise hand out carbon fiber and jelly on Nauvis. Recipes that make the same items some other way (the stack inserter from
-- slimy gel) keep their ingredients and stay with the research that unlocks them.
local nauvis_comfort_recipes = {}

local swaps = {
	{
		recipe = "stack-inserter",
		changes = {
			{from = "carbon-fiber", amount = 2, to = "low-density-structure", to_amount = 1},
			{from = "jelly", amount = 10, to = "plastic-bar", to_amount = 10}
		},
		-- what the crushing gives back of the carbon fiber: half of it, as a chance since there is one piece
		crushing = {recipe = "kr-crush-stack-inserter", from = "carbon-fiber", amount = 1,
			to = "low-density-structure", to_amount = 1, probability = 0.5}
	},
	{
		recipe = "toolbelt-equipment",
		changes = {
			{from = "carbon-fiber", amount = 10, to = "low-density-structure", to_amount = 3}
		}
	}
}

local function entry_name(entry)
	return entry.name or entry[1]
end

local function entry_amount(entry)
	return entry.amount or entry[2]
end

local function item_exists(name)
	return data.raw.item and data.raw.item[name] ~= nil
end

local function find(list, name)
	for index, entry in ipairs(list or {}) do
		if entry_name(entry) == name then
			return index, entry
		end
	end
end

-- The quarter that a recycling recipe returns of an ingredient: whole items and the chance of one more.
local function quarter(amount)
	local whole = math.floor(amount / 4)
	return whole, amount / 4 - whole
end

local function same(a, b)
	return math.abs(a - b) < 1e-6
end

local function recipe_matches(recipe, changes)
	for _, change in ipairs(changes) do
		local _, entry = find(recipe.ingredients, change.from)
		if not entry or entry_amount(entry) ~= change.amount or not item_exists(change.to) then
			return false
		end
	end
	return true
end

-- The recycling recipe holds the quarter of the original ingredient; true when it does for every change.
local function recycling_matches(recycling, changes)
	for _, change in ipairs(changes) do
		local _, entry = find(recycling.results, change.from)
		if not entry then
			return false
		end
		local whole, fraction = quarter(change.amount)
		if (entry.amount or 0) ~= whole or not same(entry.extra_count_fraction or 0, fraction) or entry.probability then
			return false
		end
	end
	return true
end

local function swap_ingredients(recipe, changes)
	for _, change in ipairs(changes) do
		local index, entry = find(recipe.ingredients, change.from)
		local _, existing = find(recipe.ingredients, change.to)
		if existing then
			-- the recipe already takes the new ingredient: add to it instead of listing it twice
			if existing.name then
				existing.amount = existing.amount + change.to_amount
			else
				existing[2] = existing[2] + change.to_amount
			end
			table.remove(recipe.ingredients, index)
			log("razi-protocol: " .. recipe.name .. " takes " .. change.to_amount .. " more " .. change.to .. " instead of "
				.. change.amount .. " " .. change.from)
		else
			if entry.name then
				entry.name = change.to
				entry.amount = change.to_amount
			else
				entry[1], entry[2] = change.to, change.to_amount
			end
			log("razi-protocol: " .. recipe.name .. " takes " .. change.to_amount .. " " .. change.to .. " instead of "
				.. change.amount .. " " .. change.from)
		end
	end
end

local function swap_recycling(recycling, changes)
	for _, change in ipairs(changes) do
		local index, entry = find(recycling.results, change.from)
		local whole, fraction = quarter(change.to_amount)
		local _, existing = find(recycling.results, change.to)
		if existing then
			existing.amount = (existing.amount or 0) + whole
			existing.extra_count_fraction = (existing.extra_count_fraction or 0) + fraction
			if existing.extra_count_fraction >= 1 then
				existing.amount = existing.amount + 1
				existing.extra_count_fraction = existing.extra_count_fraction - 1
			end
			table.remove(recycling.results, index)
			log("razi-protocol: " .. recycling.name .. " returns more " .. change.to .. " instead of " .. change.from)
		else
			entry.name = change.to
			entry.amount = whole
			entry.extra_count_fraction = fraction
			log("razi-protocol: " .. recycling.name .. " returns " .. change.to .. " instead of " .. change.from)
		end
	end
end

local function swap_crushing(crushing)
	local recipes = data.raw.recipe
	local recipe = recipes[crushing.recipe]
	if not recipe then
		return
	end
	local _, entry = find(recipe.results, crushing.from)
	if not entry or entry.amount ~= crushing.amount or entry.probability or entry.amount_min or not item_exists(crushing.to) then
		return
	end
	if find(recipe.results, crushing.to) then
		return
	end
	entry.name = crushing.to
	entry.amount = crushing.to_amount
	entry.probability = crushing.probability
	log("razi-protocol: " .. crushing.recipe .. " returns " .. crushing.to .. " instead of " .. crushing.from)
end

function nauvis_comfort_recipes.data_final_fixes()
	local recipes = data.raw.recipe
	if not recipes then
		return
	end
	for _, swap in ipairs(swaps) do
		local recipe = recipes[swap.recipe]
		if recipe and recipe_matches(recipe, swap.changes) then
			swap_ingredients(recipe, swap.changes)
			local recycling = recipes[swap.recipe .. "-recycling"]
			if recycling and recycling_matches(recycling, swap.changes) then
				swap_recycling(recycling, swap.changes)
			elseif recycling then
				log("razi-protocol: " .. recycling.name .. " is not the quarter of the original ingredients, left as it is")
			end
			if swap.crushing then
				swap_crushing(swap.crushing)
			end
		end
	end
end

return nauvis_comfort_recipes
