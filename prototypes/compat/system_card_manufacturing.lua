-- Resource-rich, optional second ways to produce system cards.
-- A freight batch consumes FOUR complete native card recipes plus real native materials
-- and yields FIVE cards. No source content is replaced.
local Graph = require("__razi_lib__/lib/technology_graph")

local M = {}

M.rules = {
	{name = "razi-solaris-multiplex-cards", card = "solaris-tech-card",
		unlock = "planet-discovery-corrundum",
		freight = {{"kr-rare-metals", 6}, {"tungsten-plate", 8}}},
	{name = "razi-nyxaris-multiplex-cards", card = "nyxaris-tech-card",
		unlock = "planet-discovery-apia-carnova",
		freight = {{"bioflux", 6}, {"optical-cable", 8}}},
	{name = "razi-vibrant-multiplex-cards", card = "vibrant-tech-card",
		unlock = "planet-discovery-paracelsin",
		freight = {{"electric-coil", 8}, {"holmium-plate", 6}}},
	{name = "razi-vespera-multiplex-cards", card = "vespera-tech-card",
		unlock = "planet-discovery-rubia",
		freight = {{"craptonite-frame", 8}, {"carbon-fiber", 8}}},
	{name = "razi-beetlejuice-multiplex-cards", card = "beetlejuice-tech-card",
		unlock = "planet-discovery-secretas",
		freight = {{"gold-plate", 6}, {"rare-earth-powder", 4}}},
	{name = "razi-umbra-multiplex-cards", card = "umbra-tech-card",
		unlock = "planet-discovery-vesta",
		freight = {{"chitosan", 4}, {"supermagnet", 3}, {"rare-earth-powder", 3}}},
	{name = "razi-deep-space-multiplex-cards", card = "deep-space-tech-card",
		unlock = "discovery-aegis-outer",
		freight = {{"space-logistic-science-pack", 2}, {"pulsar-science-pack", 2}}}
}

-- Plain materials are `item`, science packs and cards are `tool`, some freight (bioflux) is a `capsule`.
local item_types = {"item", "tool", "capsule", "module", "ammo", "item-with-entity-data", "rail-planner", "repair-tool"}

local function item(name)
	for _, type_name in ipairs(item_types) do
		local prototypes = data.raw[type_name]
		if prototypes and prototypes[name] then return prototypes[name] end
	end
end

-- The multiplex recipe must never appear before the ordinary card recipe it multiplies.
-- Keep the configured technology when the card's unlock is among its prerequisites (or is
-- the same technology); otherwise fall back to the technology that unlocks the card itself.
local function unlock_technology(technologies, index, rule)
	local base_unlocks = {}
	for _, name in ipairs(index[rule.card] or {}) do
		local node = technologies[name]
		if node and node.enabled ~= false and not node.hidden then
			base_unlocks[#base_unlocks + 1] = name
		end
	end
	if #base_unlocks == 0 then return nil end
	local configured = technologies[rule.unlock]
	if configured and configured.enabled ~= false and not configured.hidden then
		for _, name in ipairs(base_unlocks) do
			if Graph.reaches(technologies, rule.unlock, name) then return rule.unlock end
		end
	end
	return base_unlocks[1]
end

local function duplicate(value)
	if table.deepcopy then return table.deepcopy(value) end
	local copy = {}
	for k, v in pairs(value) do
		copy[k] = type(v) == "table" and duplicate(v) or v
	end
	return copy
end

local function has_crafting_category(recipe)
	if recipe.category and recipe.category ~= "crafting" then return false end
	if recipe.categories then
		for _, c in ipairs(recipe.categories) do
			if c == "crafting" then return true end
		end
		return false
	end
	return true
end

local function valid_base(recipe, card)
	if not recipe or recipe.hidden or recipe.enabled ~= false
		or not recipe.ingredients or not recipe.results
		or not has_crafting_category(recipe) then return false end
	if #recipe.results ~= 1 then return false end
	local result = recipe.results[1]
	if result.name ~= card or result.amount ~= 1 then return false end
	for _, ingredient in ipairs(recipe.ingredients) do
		if not ingredient.name or not ingredient.amount
			or ingredient.amount <= 0 or ingredient.type == "fluid"
			or not item(ingredient.name) then return false end
	end
	return true
end

-- A multiplex recipe must fit an installed existing crafting machine. If none can take that many
-- ingredients the recipe is skipped; no new assembler is created.
local function has_crafting_machine(ingredient_count)
	for _, machine in pairs(data.raw["assembling-machine"] or {}) do
		if not machine.fixed_recipe
			and (not machine.ingredient_count or machine.ingredient_count >= ingredient_count) then
			for _, category in ipairs(machine.crafting_categories or {}) do
				if category == "crafting" then return true end
			end
		end
	end
	return false
end

function M.data_final_fixes()
	local recipes = data.raw.recipe or {}
	local technologies = data.raw.technology or {}
	local index = Graph.unlock_index(technologies)
	for _, rule in ipairs(M.rules) do
		local unlock = unlock_technology(technologies, index, rule)
		local technology = unlock and technologies[unlock]
		local base = recipes[rule.card]
		local card = item(rule.card)
		local approved = technology and technology.enabled ~= false
			and not technology.hidden and card
			and not recipes[rule.name] and valid_base(base, rule.card)
		if approved then
			for _, part in ipairs(rule.freight) do
				if not item(part[1]) then approved = false break end
			end
		end
		local ingredients
		if approved then
			ingredients = duplicate(base.ingredients)
			for _, part in ipairs(ingredients) do
				part.amount = part.amount * 4
			end
			for _, part in ipairs(rule.freight) do
				ingredients[#ingredients + 1] = {type = "item", name = part[1], amount = part[2]}
			end
			if not has_crafting_machine(#ingredients) then
				approved = false
			end
		end
		if approved and unlock ~= rule.unlock then
			log("Razi cards: " .. rule.name .. " unlocked by " .. unlock .. " (the card's own technology), not " .. rule.unlock)
		end
		if approved then
			local recipe = {
				type = "recipe", name = rule.name,
				localised_name = {"recipe-name." .. rule.name},
				localised_description = {"recipe-description." .. rule.name},
				icon = card.icons and nil or card.icon,
				icon_size = card.icons and nil or card.icon_size,
				icons = card.icons and duplicate(card.icons) or nil,
				categories = {"crafting"}, enabled = false,
				energy_required = (base.energy_required or 10) * 4 * 1.15,
				allow_productivity = false, maximum_productivity = 0,
				auto_recycle = false, allow_decomposition = false,
				subgroup = "system-tech-card",
				order = "s[system]-z[multiplex]-" .. rule.card,
				ingredients = ingredients,
				results = {{type = "item", name = rule.card, amount = 5}}
			}
			data:extend({recipe})
			technology.effects = technology.effects or {}
			local found = false
			for _, effect in ipairs(technology.effects) do
				if effect.type == "unlock-recipe" and effect.recipe == rule.name then
					found = true break
				end
			end
			if not found then
				technology.effects[#technology.effects + 1] = {type = "unlock-recipe", recipe = rule.name}
			end
		else
			log("Razi cards: multiplex recipe " .. rule.name .. " skipped")
		end
	end
end

return M
