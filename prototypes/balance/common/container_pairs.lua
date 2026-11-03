local container_pairs = {}

-- Two recipes that undo each other exactly (A makes what B takes and B makes what A takes, same amounts) are a pair
-- of a container: fill and drain, preserve and depreserve. Vanilla barrels mark their products ignored_by_stats, which
-- the engine takes for ignored_by_productivity, so a machine with a base productivity bonus does not multiply them.
-- Mods that make such pairs without the mark (shchierbin gas-ballon-* / un-gas-ballon-*, Nexus high-energetic
-- photonen canisters, ribbonia thruster barrels, Renai containers) get x1.5 of items and fluid on every craft in an
-- electrochemical plant or an engineer assembler, and a fill + drain cycle makes matter out of nothing. Every
-- product of both recipes is kept out of productivity. The pair also takes no quality: it loses nothing, so quality
-- modules raise the quality of the container for free (the recycler loses 75 % for the same).

local function is_recycling(recipe)
	for _, category in pairs(recipe.categories or { recipe.category }) do
		if category:find("recycling", 1, true) then
			return true
		end
	end

	return false
end

-- "type:name:amount" of every entry sorted, or nil when an amount is not a plain number (chance, range)
local function signature(entries)
	local parts = {}
	for _, entry in pairs(entries or {}) do
		if type(entry.amount) ~= "number" or (entry.independent_probability or 1) ~= 1 or entry.shared_probability then
			return nil
		end
		parts[#parts + 1] = (entry.type or "item") .. ":" .. entry.name .. ":" .. entry.amount
	end
	table.sort(parts)

	return #parts > 0 and table.concat(parts, "|") or nil
end

local function mark(recipe)
	local count = 0
	if recipe.allow_quality ~= false then
		recipe.allow_quality = false
		count = count + 1
	end
	for _, product in pairs(recipe.results) do
		if product.ignored_by_productivity == nil and product.ignored_by_stats == nil then
			product.ignored_by_productivity = product.amount
			product.ignored_by_stats = product.amount
			count = count + 1
		end
	end

	return count
end

function container_pairs.data_final_fixes()
	local by_ingredients, signatures = {}, {}
	for name, recipe in pairs(data.raw.recipe) do
		if recipe.results and not is_recycling(recipe) then
			local ingredients, results = signature(recipe.ingredients), signature(recipe.results)
			if ingredients and results and ingredients ~= results then
				signatures[name] = { ingredients, results }
				by_ingredients[ingredients] = by_ingredients[ingredients] or {}
				table.insert(by_ingredients[ingredients], name)
			end
		end
	end

	local pairs_found, products = 0, 0
	local names = {}
	for name in pairs(signatures) do
		names[#names + 1] = name
	end
	table.sort(names)

	for _, name in ipairs(names) do
		for _, other in ipairs(by_ingredients[signatures[name][2]] or {}) do
			-- visit each pair once, from its first name
			if name < other and signatures[other][2] == signatures[name][1] then
				local changed = mark(data.raw.recipe[name]) + mark(data.raw.recipe[other])
				if changed > 0 then
					pairs_found = pairs_found + 1
					products = products + changed
					log("razi-protocol: " .. name .. " + " .. other .. " undo each other, " .. changed
						.. " products kept out of productivity")
				end
			end
		end
	end

	log("razi-protocol: reversible recipe pairs kept out of productivity: " .. pairs_found .. " pairs, " .. products
		.. " products")
end

return container_pairs
