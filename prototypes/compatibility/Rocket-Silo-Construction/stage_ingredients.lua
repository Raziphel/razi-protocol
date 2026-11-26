local M = {}

-- RSC selects several stage materials by whichever matching item exists during data.lua
-- (Rocket-Silo-Construction/prototypes/recipe.lua:84-123, 269-276). Keep its vanilla list stable.
local stages = {
	{
		recipe = "rsc-construction-stage2",
		ingredients = {
			{ "item", "concrete", 50 },
			{ "item", "stone-brick", 10 },
			{ "item", "steel-plate", 20 },
			{ "item", "iron-stick", 30 },
			{ "fluid", "water", 500 },
		},
	},
	{
		recipe = "rsc-construction-stage4",
		ingredients = {
			{ "item", "concrete", 50 },
			{ "item", "stone-brick", 10 },
			{ "item", "steel-plate", 20 },
			{ "item", "iron-stick", 30 },
			{ "item", "pipe", 20 },
			{ "item", "pipe-to-ground", 10 },
		},
	},
	{
		recipe = "rsc-construction-stage5",
		ingredients = {
			{ "item", "stone-brick", 10 },
			{ "item", "copper-cable", 100 },
			{ "item", "electronic-circuit", 20 },
			{ "item", "copper-plate", 40 },
			{ "item", "steel-plate", 10 },
		},
	},
	{
		recipe = "rsc-construction-stage6",
		ingredients = {
			{ "item", "refined-concrete", 10 },
			{ "item", "electric-engine-unit", 5 },
			{ "item", "processing-unit", 5 },
			{ "item", "advanced-circuit", 10 },
			{ "item", "electronic-circuit", 30 },
			{ "item", "radar", 2 },
		},
	},
}

local reported_missing = {}

local function same_ingredients(actual, expected)
	if type(actual) ~= "table" or #actual ~= #expected then
		return false
	end

	local count = 0
	for key in pairs(actual) do
		if type(key) ~= "number" or key < 1 or key > #expected or key % 1 ~= 0 then
			return false
		end
		count = count + 1
	end
	if count ~= #expected then
		return false
	end

	for index, expected_ingredient in ipairs(expected) do
		local actual_ingredient = actual[index]
		if type(actual_ingredient) ~= "table" then
			return false
		end
		for key, value in pairs(expected_ingredient) do
			if actual_ingredient[key] ~= value then
				return false
			end
		end
		for key in pairs(actual_ingredient) do
			if expected_ingredient[key] == nil then
				return false
			end
		end
	end
	return true
end

function M.data_final_fixes()
	if not mods or not mods["Rocket-Silo-Construction"] then
		return
	end

	local raw = data and data.raw
	if not raw or not raw.recipe then
		return
	end

	local cost_setting = settings and settings.startup and settings.startup["rsc-st-cost-mp"]
	local mp = cost_setting and cost_setting.value
	if mp == nil then
		mp = 1
	end

	for _, stage in ipairs(stages) do
		local recipe = raw.recipe[stage.recipe]
		if recipe then
			local ingredients = {}
			local missing
			for _, ingredient in ipairs(stage.ingredients) do
				local prototype_type, name, amount = ingredient[1], ingredient[2], ingredient[3]
				if not raw[prototype_type] or not raw[prototype_type][name] then
					missing = name
					break
				end
				ingredients[#ingredients + 1] = {
					type = prototype_type,
					name = name,
					amount = math.ceil(amount * mp),
				}
			end

			if missing then
				local key = stage.recipe .. ":" .. missing
				if not reported_missing[key] then
					reported_missing[key] = true
					log("razi-protocol: Rocket-Silo Construction: skipped " .. stage.recipe .. "; missing " .. missing)
				end
			elseif not same_ingredients(recipe.ingredients, ingredients) then
				recipe.ingredients = ingredients
				log("razi-protocol: Rocket-Silo Construction: set vanilla ingredients for " .. stage.recipe)
			end
		end
	end
end

return M
