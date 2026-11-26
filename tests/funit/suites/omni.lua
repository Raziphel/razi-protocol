---@diagnostic disable: undefined-field

local DISCOVERY_RECIPES = {
	"lindomanium", "joaonium", "eltonium", "beninium", "omni-seed", "organic-fluid",
	"berengotengo-juice", "berengotengo-oil", "berengotengo-gas", "berengotengo-pulp",
	"berengotengo-refined", "berengotengo-refined-processing",
}

local SYNTHESIS_RECIPES = {
	"lava-from-mancha", "aquilo-from-vitu", "advanced-coal-synthesis", "omni-solid-fuel",
	"omni-holmium-plate", "biofix", "biofix-to-bioflux", "omni-carbon-fiber", "omni-synthesis",
	"promethium-asteroid-reprocessing", "advanced-promethium-asteroid-reprocessing",
}

local SCIENCE_RECIPES = {
	"advanced-automation-science", "advanced-logistic-science", "advanced-chemical-science",
	"advanced-military-science", "advanced-utility-science", "advanced-production-science",
	"advanced-space-science", "advanced-metallurgic-science", "advanced-electromagnetic-science",
	"advanced-agricultural-science", "advanced-cryogenic-science", "advanced-promethium-science",
	"dr-albieri-pentapod-cloning", "dr-albieri-biter-cloning", "dr-albieri-fish-cloning",
}

local PLANET_ONLY_RECIPES = {
	"advanced-automation-science", "advanced-logistic-science", "advanced-chemical-science",
	"advanced-military-science", "advanced-utility-science", "advanced-production-science",
	"advanced-space-science", "advanced-metallurgic-science", "advanced-electromagnetic-science",
	"advanced-agricultural-science", "advanced-cryogenic-science", "advanced-promethium-science",
	"dr-albieri-pentapod-cloning", "dr-albieri-biter-cloning", "dr-albieri-fish-cloning",
	"lava-from-mancha", "aquilo-from-vitu", "advanced-coal-synthesis", "omni-solid-fuel",
	"omni-holmium-plate", "biofix-to-bioflux", "omni-carbon-fiber", "omni-synthesis",
	"promethium-asteroid-reprocessing", "advanced-promethium-asteroid-reprocessing",
}

local SYSTEM_CARDS = {
	"calidus-tech-card", "solaris-tech-card", "nyxaris-tech-card", "vibrant-tech-card",
	"vespera-tech-card", "beetlejuice-tech-card", "umbra-tech-card",
}

local function recipe_unlocks(technology)
	local names = {}
	for _, effect in pairs(technology.effects or {}) do
		if effect.type == "unlock-recipe" then
			names[#names + 1] = effect.recipe
		end
	end
	return names
end

local function same_set(expected, actual)
	if #expected ~= #actual then
		return false
	end
	local found = {}
	for _, name in pairs(actual) do
		if found[name] then
			return false
		end
		found[name] = true
	end
	for _, name in pairs(expected) do
		if not found[name] then
			return false
		end
	end
	return true
end

local function has_condition(recipe, property, minimum, maximum)
	for _, condition in pairs(recipe.surface_conditions or {}) do
		if condition.property == property and condition.min == minimum and condition.max == maximum then
			return true
		end
	end
	return false
end

local function condition_for(recipe, property)
	if not recipe then return nil end
	for _, condition in pairs(recipe.surface_conditions or {}) do
		if condition.property == property then
			return condition
		end
	end
end

return function(runner)
	if not script.active_mods["omni"] then return end

	runner.test("OMNI research has the planned prices, cards and recipe unlocks", function()
		local expected = {
			["planet-discovery-OMNI"] = {count = 2000, recipes = DISCOVERY_RECIPES},
			["razi-omni-synthesis"] = {count = 1000, recipes = SYNTHESIS_RECIPES},
			["razi-omni-science"] = {count = 1500, recipes = SCIENCE_RECIPES},
		}
		local expected_card_set = {}
		for _, name in pairs(SYSTEM_CARDS) do expected_card_set[name] = true end
		if script.active_mods["Nexus"] then
			expected_card_set["deep-space-tech-card"] = true
		end

		for name, values in pairs(expected) do
			local technology = prototypes.technology[name]
			runner.assert(technology, "no technology " .. name)
			runner.assert(technology.research_unit_count == values.count,
				name .. " costs " .. tostring(technology.research_unit_count) .. " units")
			runner.assert(same_set(values.recipes, recipe_unlocks(technology)),
				name .. " does not unlock the planned recipes")
			local found_cards = {}
			for _, ingredient in pairs(technology.research_unit_ingredients) do
				found_cards[ingredient.name] = ingredient.amount
			end
			for card in pairs(expected_card_set) do
				runner.assert(found_cards[card] == 1, name .. " does not take one " .. card)
			end
			local count = 0
			for card in pairs(found_cards) do
				runner.assert(expected_card_set[card], name .. " also takes " .. card)
				count = count + 1
			end
			local expected_count = script.active_mods["Nexus"] and 8 or 7
			runner.assert(count == expected_count,
				name .. " takes " .. count .. " cards instead of " .. expected_count)
		end

		local discovery = prototypes.technology["planet-discovery-OMNI"]
		local prerequisites = {}
		for name in pairs(discovery.prerequisites) do prerequisites[name] = true end
		runner.assert(prerequisites["promethium-science-pack"],
			"planet-discovery-OMNI does not require promethium-science-pack")
		runner.assert(prerequisites["razi-singularity-theory"] or prerequisites["promethium-882-research"],
			"planet-discovery-OMNI has no Deep Space card prerequisite")
	end)

	runner.test("OMNI science, synthesis and cloning recipes require OMNI", function()
		for _, name in pairs(PLANET_ONLY_RECIPES) do
			local recipe = prototypes.recipe[name]
			runner.assert(recipe and has_condition(recipe, "PlanetsLib-is-OMNI", 1, 1),
				name .. " is not restricted to OMNI")
		end
		for _, name in pairs(DISCOVERY_RECIPES) do
			local recipe = prototypes.recipe[name]
			runner.assert(recipe and not condition_for(recipe, "PlanetsLib-is-OMNI"),
				name .. " is unexpectedly restricted to OMNI")
		end
		local biofix = prototypes.recipe.biofix
		runner.assert(biofix and not condition_for(biofix, "PlanetsLib-is-OMNI"),
			"biofix is unexpectedly restricted to OMNI")
		for _, name in pairs(SCIENCE_RECIPES) do
			local copy = prototypes.recipe["igrys-" .. name .. "-enhanced"]
			if copy then
				runner.assert(has_condition(copy, "PlanetsLib-is-OMNI", 1, 1),
					"igrys-" .. name .. "-enhanced is not restricted to OMNI")
			end
		end
	end)

	runner.test("OMNI promethium research uses research data", function()
		local recipe = prototypes.recipe["advanced-promethium-science"]
		local product = recipe and recipe.products and recipe.products[1]
		runner.assert(product and product.name == "kr-promethium-research-data" and product.amount == 5,
			"advanced-promethium-science does not make five research data")
	end)

	runner.test("OMNI's approach route has the planned distance", function()
		local route = prototypes.space_connection["solar-system-edge-OMNI"]
		runner.assert(route and route.length == 300000,
			"solar-system-edge-OMNI is not 300,000 km")
	end)

	runner.test("OMNI signals stay disabled and tree planting still works on Lignumis", function()
		local setting = settings.startup["omni-signals"]
		runner.assert(setting and setting.value == false, "omni-signals is not false")
		if script.active_mods["lignumis"] then
			local tree = prototypes.entity["tree-plant"]
			local pressure = condition_for(tree, "pressure")
			runner.assert(pressure and (not pressure.min or pressure.min <= 900)
				and (not pressure.max or pressure.max >= 900),
				"tree-plant cannot be placed at Lignumis pressure 900")
		end
	end)
end
