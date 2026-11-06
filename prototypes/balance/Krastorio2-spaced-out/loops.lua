local loops = {}

-- Resource loops of Krastorio2-spaced-out 2.0.17.
--
-- 1. kr-bio-processing-circuit turns 6 advanced circuits and a pentapod egg into 4 processing units (2 before 2.0.0),
--    and recycling a processing unit returns 0.75 advanced circuit and 0.375 rare metals. From 100 % productivity on
--    (biochamber +50 %, its modules, the endless processing-unit-productivity) every round gives more circuits and rare
--    metals out of eggs. With productivity capped at 50 % a round returns at most 6 circuits for 6.
--
-- 2. Matter: 1.17 matter -> 10 sand -> 6 quartz -> 0.64 matter per 10 quartz. Quartz takes productivity up to the
--    cap of 300 % (electrochemical plant +50 %, legendary modules, Arig's endless quartz productivity), and above 205 %
--    the round makes matter out of power. With 0.48 matter per 10 quartz it breaks even at the cap.
--
-- 3. Krastorio 2 makes a recipe for every rock and tree (prototypes/updates/generate-greenhouse-recipes.lua: 50 coal
--    and 75 stone, or 40 wood and 100 water), unlocked early by kr-decorations. Many of them drop much more when
--    mined: tungsten from volcanic rocks, rare metal ore from Arig rocks, U-238 and panglite from Panglia, platinum and
--    solid fuel from Corrundum, steel, circuits and tiny solar panels from the artificial trees, on any planet. Each
--    of these recipes also takes twice the most its entity can drop of everything but wood, stone, coal and spoilage
--    (the approach of K2SO issue #183), so planting and mining one loses what it gives.
--    A greenhouse takes at most 4 item ingredients (ingredient_count) and the artificial trees drop 9 kinds of items
--    besides wood, so a recipe gets only as many new ingredients as the machines that craft it have slots left, the
--    most valuable drops first, and their amounts grow by the price of the drops left out.
--    This loop needs no productivity, so it closes from the closed level on (loops.decorations_data_final_fixes);
--    1 and 2 only open with productivity and close at strict (loops.data_final_fixes).
local cheap_drops = { wood = true, stone = true, coal = true, spoilage = true }

local function drops(entity)
	local minable = entity.minable
	if not minable then
		return {}
	end
	if minable.results then
		return minable.results
	end
	if minable.result then
		return { { type = "item", name = minable.result, amount = minable.count or 1 } }
	end

	return {}
end

local function placed_entity(item_name)
	local item = data.raw.item and data.raw.item[item_name]
	local entity_name = item and item.place_result or item_name
	for _, type_name in pairs({ "tree", "simple-entity", "simple-entity-with-owner", "simple-entity-with-force" }) do
		local entity = data.raw[type_name] and data.raw[type_name][entity_name]
		if entity then
			return entity
		end
	end

	return nil
end

-- The most distinct item ingredients any assembling machine of the recipe's categories takes (math.huge when one has no
-- limit or none is found). The greenhouses of Krastorio 2 take 4, so a recipe with more cannot be crafted anywhere.
local function item_slots(recipe)
	local categories = recipe.categories or { "crafting" }
	local wanted = {}
	for _, category in pairs(categories) do
		wanted[category] = true
	end
	for _, category in pairs(recipe.additional_categories or {}) do
		wanted[category] = true
	end

	local slots = 0.0
	for _, machine in pairs(data.raw["assembling-machine"] or {}) do
		for _, category in pairs(machine.crafting_categories or {}) do
			if wanted[category] then
				slots = math.max(slots, machine.ingredient_count or math.huge)
				break
			end
		end
	end

	return slots > 0 and slots or math.huge
end

-- A rough price per unit, from the recipe named after the item (raw materials and items without such a recipe count 1,
-- fluids almost nothing). Only the proportions matter: it tells which drops are worth a slot and how much of the
-- kept ones stands in for the rest. Recipes of other names are left out on purpose: scrap, sintering and unpacking
-- recipes of other mods make plates and poles out of almost nothing, and a cheapest-recipe price follows them.
local function new_pricer()
	local recipes = data.raw.recipe
	local unit_costs = {}
	local pending = {}

	local function unit_cost(item_name)
		if unit_costs[item_name] then
			return unit_costs[item_name]
		end
		if pending[item_name] then
			return 1
		end

		pending[item_name] = true
		local price = 1.0
		local recipe = recipes[item_name]
		local made = 0.0
		for _, result in pairs(recipe and recipe.results or {}) do
			if (result.type or "item") == "item" and result.name == item_name then
				made = made + (result.amount or ((result.amount_min or 0) + (result.amount_max or 0)) / 2)
					* (result.independent_probability or 1)
			end
		end
		if recipe and made > 0 then
			local total = 0.0
			for _, ingredient in pairs(recipe.ingredients or {}) do
				if (ingredient.type or "item") == "item" then
					total = total + (ingredient.amount or 1) * unit_cost(ingredient.name)
				else
					total = total + (ingredient.amount or 1) * 0.01
				end
			end
			if total > 0 then
				price = total / made
			end
		end
		pending[item_name] = nil

		unit_costs[item_name] = price
		return price
	end

	return unit_cost
end

local function count_items(recipe)
	local count = 0
	for _, ingredient in pairs(recipe.ingredients or {}) do
		if (ingredient.type or "item") == "item" then
			count = count + 1
		end
	end

	return count
end

local function close_bio_circuit()
	local recipe = data.raw.recipe["kr-bio-processing-circuit"]
	-- a lower cap that the author set stays
	if recipe and recipe.allow_productivity ~= false and (recipe.maximum_productivity or math.huge) > 0.5 then
		recipe.maximum_productivity = 0.5
		log("razi-protocol: kr-bio-processing-circuit takes at most +50 % productivity")
	end
end

local function close_quartz_to_matter()
	local recipe = data.raw.recipe["kr-kr-quartz-to-matter"]
	for _, product in pairs(recipe and recipe.results or {}) do
		if product.name == "kr-matter" and type(product.amount) == "number" and product.amount > 0.48 then
			product.amount = 0.48
			log("razi-protocol: kr-kr-quartz-to-matter gives 0.48 matter")
		end
	end
end

local function price_decorations()
	local recipes = data.raw.recipe
	local unit_cost = new_pricer()

	local decorations = data.raw.technology["kr-decorations"]
	local priced = 0
	local trimmed = 0
	for _, effect in pairs(decorations and decorations.effects or {}) do
		local recipe = effect.type == "unlock-recipe" and recipes[effect.recipe]
		local result = recipe and recipe.results and recipe.results[1]
		local entity = result and placed_entity(result.name)

		if recipe and entity then
			local added = {}
			for _, drop in pairs(drops(entity)) do
				local most = (drop.amount or drop.amount_max or 0) * (drop.independent_probability or 1)
				if (drop.type or "item") == "item" and not cheap_drops[drop.name] and most > 0 then
					added[drop.name] = (added[drop.name] or 0) + math.ceil(2 * most)
				end
			end

			-- Ingredients the recipe has already take more of; new ones need a slot of the machines that craft it. When
			-- there are more drops than slots the most valuable get the slots and take over the price of the rest (their
			-- amounts grow by the value that is left out), so that planting and mining still loses whichever drops get a
			-- slot. A recipe without any slot makes its most valuable ingredient cover the drops instead.
			local candidates = {}
			local touched = false
			for _, ingredient in pairs(recipe.ingredients or {}) do
				if added[ingredient.name] then
					ingredient.amount = ingredient.amount + added[ingredient.name]
					added[ingredient.name] = nil
					touched = true
				end
			end
			for name, amount in pairs(added) do
				table.insert(candidates, { name = name, amount = amount, value = amount * unit_cost(name) })
			end
			table.sort(candidates, function(left, right)
				if left.value ~= right.value then
					return left.value > right.value
				end

				return left.name < right.name
			end)

			local free = math.max(0, item_slots(recipe) - count_items(recipe))
			local kept, left_out = {}, {}
			local kept_value, left_value = 0.0, 0.0
			for index, candidate in ipairs(candidates) do
				if index <= free then
					table.insert(kept, candidate)
					kept_value = kept_value + candidate.value
				else
					table.insert(left_out, candidate.name)
					left_value = left_value + candidate.value
				end
			end
			recipe.ingredients = recipe.ingredients or {}
			for _, candidate in ipairs(kept) do
				local amount = math.ceil(candidate.amount * (kept_value + left_value) / kept_value)
				table.insert(recipe.ingredients, { type = "item", name = candidate.name, amount = amount })
				touched = true
			end
			if #left_out > 0 and #kept == 0 then
				local richest
				for _, ingredient in pairs(recipe.ingredients) do
					if (ingredient.type or "item") == "item"
						and (not richest or unit_cost(ingredient.name) > unit_cost(richest.name)) then
						richest = ingredient
					end
				end
				if richest then
					richest.amount = richest.amount + math.ceil(left_value / unit_cost(richest.name))
					touched = true
				end
			end
			if #left_out > 0 then
				trimmed = trimmed + 1
				local paid = {}
				for _, ingredient in pairs(recipe.ingredients) do
					if (ingredient.type or "item") == "item" then
						table.insert(paid, ingredient.amount .. " " .. ingredient.name)
					end
				end
				log("razi-protocol: " .. recipe.name .. " has no slot for the drops " .. table.concat(left_out, ", ")
					.. "; it costs " .. table.concat(paid, ", "))
			end
			if touched then
				priced = priced + 1
			end
		end
	end
	log("razi-protocol: kr-decorations recipes that also cost twice their valuable drop: " .. priced
		.. ", of them with drops left out for lack of ingredient slots: " .. trimmed)
end

function loops.data_final_fixes()
	close_bio_circuit()
	close_quartz_to_matter()
end

function loops.decorations_data_final_fixes()
	price_decorations()
end

return loops
