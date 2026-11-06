-- Prerequisites that the system gates (technology/seven_system_gates.lua) replace wholesale.
-- Runs right after them and restores the links the rest of the campaign relies on.
local TechnologyGraph = require("__razi_lib__/lib/technology_graph")

local system_gate_links = {}

-- Packs whose unlock must precede every technology priced in them: the system cards, and the
-- planet packs that Solaris used to require (through Vulcanus, Fulgora and Gleba) before the gates
-- cut that chain.
local system_cards = {
	"calidus-tech-card",
	"solaris-tech-card",
	"nyxaris-tech-card",
	"vibrant-tech-card",
	"vespera-tech-card",
	"beetlejuice-tech-card",
	"umbra-tech-card"
}

local priced_packs = {}
for _, card in ipairs(system_cards) do
	priced_packs[#priced_packs + 1] = card
end
for _, pack in ipairs({"metallurgic-science-pack", "electromagnetic-science-pack", "agricultural-science-pack"}) do
	priced_packs[#priced_packs + 1] = pack
end

local function add_link(technologies, target, parent, reason)
	if TechnologyGraph.add_prerequisite(technologies, target, parent) then
		log("[Razi Protocol/system-gates] " .. target .. " now requires " .. parent .. reason)
	end
end

-- A system card is made of the packs of the planets below its tier. When one of those packs can only be
-- researched after a technology that is itself priced in the card, nothing can start: the card needs the
-- pack, the pack needs the research, the research needs the card. Drop such a pack from the card recipe.
local function break_card_cycles(technologies, unlock_index)
	local packs = {}
	for _, technology in pairs(technologies) do
		for _, ingredient in ipairs(technology.unit and technology.unit.ingredients or {}) do
			packs[ingredient[1] or ingredient.name] = true
		end
	end

	local function recipe_ingredients(name)
		local recipe = data.raw.recipe and data.raw.recipe[name]
		return recipe and recipe.ingredients or {}
	end

	-- Techs lead to their prerequisites, to the packs in their price and, through the pack, to the
	-- techs that unlock it and to the packs in its recipe.
	local function successors(node)
		local result = {}
		if node.tech then
			local technology = technologies[node.tech]
			for _, parent in ipairs(technology.prerequisites or {}) do
				if technologies[parent] then result[#result + 1] = {tech = parent} end
			end
			for _, ingredient in ipairs(technology.unit and technology.unit.ingredients or {}) do
				result[#result + 1] = {pack = ingredient[1] or ingredient.name}
			end
		else
			for _, unlocker in ipairs(unlock_index[node.pack] or {}) do
				result[#result + 1] = {tech = unlocker}
			end
			for _, ingredient in ipairs(recipe_ingredients(node.pack)) do
				local name = ingredient.name or ingredient[1]
				if packs[name] then result[#result + 1] = {pack = name} end
			end
		end
		return result
	end

	local function reaches_pack(start, wanted)
		local seen, stack = {}, {{pack = start}}
		while #stack > 0 do
			local node = table.remove(stack)
			local key = node.tech and ("t:" .. node.tech) or ("p:" .. node.pack)
			if node.pack == wanted then return true end
			if not seen[key] then
				seen[key] = true
				for _, next_node in ipairs(successors(node)) do
					stack[#stack + 1] = next_node
				end
			end
		end
		return false
	end

	local changed = true
	while changed do
		changed = false
		for _, card in ipairs(system_cards) do
			local recipe = data.raw.recipe and data.raw.recipe[card]
			local ingredients = recipe and recipe.ingredients or {}
			for index = #ingredients, 1, -1 do
				local pack = (ingredients[index] or {}).name
				if packs[pack] and pack ~= card and reaches_pack(pack, card) then
					table.remove(ingredients, index)
					log("[Razi Protocol/system-gates] " .. card .. " no longer needs " .. pack
						.. ": its research needs " .. card)
					changed = true
				end
			end
		end
	end
end

function system_gate_links.data_final_fixes()
	local technologies = data.raw.technology
	if not technologies then
		return
	end

	-- A pack in the price is useless until its recipe is unlocked: some technology that unlocks
	-- the recipe must be an ancestor of every technology priced in that pack.
	local unlock_index = TechnologyGraph.unlock_index(technologies)
	local names = {}
	for name in pairs(technologies) do
		names[#names + 1] = name
	end
	table.sort(names)

	for _, pack in ipairs(priced_packs) do
		local unlockers = unlock_index[pack]
		local first = TechnologyGraph.first_unlock(technologies, pack, true)
		for _, name in ipairs(unlockers and first and names or {}) do
			local technology = technologies[name]
			local ingredients = technology.enabled ~= false and technology.unit and technology.unit.ingredients
			for _, ingredient in ipairs(ingredients or {}) do
				if (ingredient[1] or ingredient.name) == pack then
					local unlocked = false
					for _, unlocker in ipairs(unlockers) do
						if unlocker == name or TechnologyGraph.reaches(technologies, name, unlocker) then
							unlocked = true
							break
						end
					end
					if not unlocked then
						add_link(technologies, name, first, ": it unlocks " .. pack)
					end
				end
			end
		end
	end

	break_card_cycles(technologies, unlock_index)
end

return system_gate_links
