local k2so_tech_card_cooling = {}

-- Krastorio2-spaced-out makes a cooling variant of every tech card recipe
-- (prototypes/updates/generate-tech-card-cooling.lua:31-39). Two faults:
--
-- 1. The variant drops the freshness flags of the products. The agricultural
--    science pack recipe makes fresh packs (reset_freshness_on_craft), its
--    cooling variant makes them with the age of the research data, half
--    spoiled (K2SO issue #198). The variant takes the flags of the recipe it
--    copies.
--
-- 2. Cooling recipes run only in the quantum computer (kr-tech-cards-cooling),
--    which needs the pressure of the Maraxsis trench. Some variants also carry
--    the surface conditions of their pack (Cerys radiation, the gravity of
--    interstellar science). No surface meets both, so those recipes show in
--    the menus but can never run (K2SO issue #150). A cooling recipe that no
--    machine of its category can make on any surface is hidden and loses its
--    unlock.
local cooling_category = "kr-tech-cards-cooling"

local function property_value(surface, property)
	local own = surface.surface_properties and surface.surface_properties[property]
	if own ~= nil then
		return own
	end

	local prototype = data.raw["surface-property"] and data.raw["surface-property"][property]
	return prototype and prototype.default_value or 0
end

local function meets(surface, conditions)
	for _, condition in pairs(conditions or {}) do
		local value = property_value(surface, condition.property)
		if (condition.min and value < condition.min) or (condition.max and value > condition.max) then
			return false
		end
	end

	return true
end

-- True when one planet or space surface meets both lists of conditions.
local function some_surface_meets(machine_conditions, recipe_conditions)
	for _, type_name in ipairs({"planet", "surface"}) do
		for _, surface in pairs(data.raw[type_name] or {}) do
			if meets(surface, machine_conditions) and meets(surface, recipe_conditions) then
				return true
			end
		end
	end

	return false
end

local function has_category(prototype, category, field)
	for _, value in pairs(prototype[field] or {}) do
		if value == category then
			return true
		end
	end

	return false
end

local function can_run(recipe)
	for _, category in pairs(recipe.categories or {}) do
		for _, type_name in ipairs({"assembling-machine", "furnace", "rocket-silo"}) do
			for _, machine in pairs(data.raw[type_name] or {}) do
				if not machine.hidden and has_category(machine, category, "crafting_categories")
					and some_surface_meets(machine.surface_conditions, recipe.surface_conditions) then
					return true
				end
			end
		end
	end

	return false
end

local function products_by_name(recipe)
	local by_name = {}
	for _, product in pairs(recipe.results or {}) do
		if product.name then
			by_name[product.name] = product
		end
	end

	return by_name
end

function k2so_tech_card_cooling.data_final_fixes()
	if not mods["Krastorio2-spaced-out"] then
		return
	end

	local recipes = data.raw.recipe or {}
	local names = {}
	for name, recipe in pairs(recipes) do
		local base_name = name:match("^(.+)%-cooling$")
		if base_name and recipes[base_name] and has_category(recipe, cooling_category, "categories") then
			names[#names + 1] = name
		end
	end
	table.sort(names)

	local hidden = {}
	for _, name in ipairs(names) do
		local recipe = recipes[name]
		local base_products = products_by_name(recipes[name:match("^(.+)%-cooling$")])

		for _, product in pairs(recipe.results or {}) do
			local base = base_products[product.name]
			if product.type == "item" and base and base.reset_freshness_on_craft and not product.reset_freshness_on_craft then
				product.reset_freshness_on_craft = true
				log("[Razi Protocol/k2so-tech-card-cooling] " .. name .. " makes fresh " .. product.name .. ", as its base recipe")
			end
		end

		if not recipe.hidden and not can_run(recipe) then
			recipe.hidden = true
			hidden[name] = true
			log("[Razi Protocol/k2so-tech-card-cooling] " .. name .. " hidden: no machine of its category can run it on any surface")
		end
	end

	for _, technology in pairs(data.raw.technology or {}) do
		local effects = technology.effects or {}
		for index = #effects, 1, -1 do
			local effect = effects[index]
			if effect and effect.type == "unlock-recipe" and hidden[effect.recipe] then
				table.remove(effects, index)
			end
		end
	end
end

return k2so_tech_card_cooling
