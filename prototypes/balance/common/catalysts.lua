local catalysts = {}

-- A product that a recipe only gives back (at most as much as it took) is a catalyst, and productivity must not apply
-- to it: the game's Kovarex and coal liquefaction mark it with ignored_by_productivity. Many mods do not, and the item
-- multiplies:
-- - through productivity modules where the recipe allows them (pulsar science gives back its electric engines,
--   helium circuits their helium);
-- - through the base productivity of a machine even where the recipe does not allow productivity: the base effect
--   applies anyway (see balance/shchierbin/crusher_and_steam.lua). The electrochemical plant (+50 %) gave about 2500
--   tritium a craft on the helium recipe (5000 in, 4995 back), the biocomputer (+50 %) five science packs a craft on
--   the artisan science of moon-eneas (10 in, 10 back), the clarifier (+20 %) servofish on its filters; also biter
--   eggs, the vanadium catalyst, the Eneas upgrades, void bacteria.
-- The returned amount is kept out of productivity. Growth recipes, which give more than they take (bacteria
-- cultivation: 1 -> 4, breeding), are left as they are: the game itself lets productivity multiply its bacteria, so
-- that is the authors' choice. Recycling is skipped: an item that recycles into itself has no productivity to lose.

local function is_recycling(recipe)
	for _, category in pairs(recipe.categories or { recipe.category }) do
		if category:find("recycling", 1, true) then
			return true
		end
	end

	return false
end

local function mark(recipe)
	local count = 0
	local used = {}
	for _, ingredient in pairs(recipe.ingredients or {}) do
		used[ingredient.name] = (used[ingredient.name] or 0) + (ingredient.amount or 0)
	end

	-- every entry of an item the recipe gives back (a recipe may list it twice, the second time with a probability:
	-- Skewer's ske_craptonite_isotope takes 2 craptonite frames and gives 1 and 1 at 50 %)
	local returned, ignored, entries = {}, {}, {}
	for _, product in pairs(recipe.results or {}) do
		if used[product.name] and product.amount then
			returned[product.name] = (returned[product.name] or 0) + product.amount
			ignored[product.name] = (ignored[product.name] or 0) + (product.ignored_by_productivity or 0)
			entries[product.name] = entries[product.name] or {}
			table.insert(entries[product.name], product)
		end
	end

	for item_name, amount in pairs(returned) do
		if amount <= used[item_name] and ignored[item_name] < amount then
			-- the part not yet ignored goes to the entries in turn, each up to its own amount
			local missing = amount - ignored[item_name]
			for _, product in ipairs(entries[item_name]) do
				local room = product.amount - (product.ignored_by_productivity or 0)
				local share = math.min(room, missing)
				if share > 0 then
					product.ignored_by_productivity = (product.ignored_by_productivity or 0) + share
					missing = missing - share
				end
			end
			count = count + 1
		end
	end

	return count
end

function catalysts.data_final_fixes()
	local fixed = 0
	for _, recipe in pairs(data.raw.recipe) do
		if not is_recycling(recipe) then
			fixed = fixed + mark(recipe)
		end
	end

	log("razi-protocol: catalysts kept out of productivity: " .. fixed .. " products")
end

return catalysts
