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

-- A card keeps at least this many ingredients: with fewer, the cycle breaker would turn the card into its
-- one-pack fallback (lab_cards.lua), and a cycle that cannot be broken without that is reported instead.
local min_card_ingredients = 2

-- A system card is made of the packs of the planets below its tier. When one of those packs can only be
-- researched after a technology that is itself priced in the card, nothing can start: the card needs the
-- pack, the pack needs the research, the research needs the card. Drop such a pack from the card recipe,
-- with a log line that names the chain. If that would leave the card with fewer than min_card_ingredients,
-- the card is left whole and the cycle is logged as an error.
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

	local tech_names, pack_names = {}, {}
	for name in pairs(technologies) do tech_names[#tech_names + 1] = name end
	for name in pairs(packs) do pack_names[#pack_names + 1] = name end
	table.sort(tech_names)
	table.sort(pack_names)

	-- Everything that cannot be had before the card: the technologies and packs that need it, with the
	-- first reason found for each. A technology waits for all of its prerequisites and for every pack in
	-- its price. A pack waits for the packs in its recipe and, when its recipe is not enabled from the
	-- start, for the research that unlocks it: the first of several unlocking technologies is enough, so
	-- the pack waits only if each of them waits (Foliax unlocks steel plate, but so does steel processing).
	local function needing(card)
		local tech_why, pack_why = {}, {[card] = true}
		local grew = true
		while grew do
			grew = false
			for _, name in ipairs(tech_names) do
				if not tech_why[name] then
					local technology = technologies[name]
					local cause
					for _, parent in ipairs(technology.prerequisites or {}) do
						if tech_why[parent] then cause = {tech = parent} break end
					end
					for _, ingredient in ipairs(not cause and technology.unit and technology.unit.ingredients or {}) do
						local pack = ingredient[1] or ingredient.name
						if pack_why[pack] then cause = {pack = pack} break end
					end
					if cause then
						tech_why[name] = cause
						grew = true
					end
				end
			end
			for _, pack in ipairs(pack_names) do
				if not pack_why[pack] then
					local cause
					local recipe = data.raw.recipe and data.raw.recipe[pack]
					local unlockers = unlock_index[pack]
					if unlockers and #unlockers > 0 and (not recipe or recipe.enabled == false) then
						local all = true
						for _, unlocker in ipairs(unlockers) do
							if not tech_why[unlocker] then all = false break end
						end
						if all then cause = {tech = unlockers[1]} end
					end
					for _, ingredient in ipairs(not cause and recipe_ingredients(pack) or {}) do
						local name = ingredient.name or ingredient[1]
						if packs[name] and pack_why[name] then cause = {pack = name} break end
					end
					if cause then
						pack_why[pack] = cause
						grew = true
					end
				end
			end
		end
		return tech_why, pack_why
	end

	-- "start -> ... -> card": what the pack waits for, step by step.
	local function chain_of(pack, tech_why, pack_why)
		local steps, node = {pack}, pack_why[pack]
		while node ~= true do
			local name = node.tech or node.pack
			steps[#steps + 1] = name
			node = node.tech and tech_why[name] or pack_why[name]
		end
		return table.concat(steps, " -> ")
	end

	local reported = {}
	local changed = true
	while changed do
		changed = false
		for _, card in ipairs(system_cards) do
			local recipe = data.raw.recipe and data.raw.recipe[card]
			local ingredients = recipe and recipe.ingredients or {}
			local tech_why, pack_why
			local looping = {}
			for index = #ingredients, 1, -1 do
				local pack = (ingredients[index] or {}).name
				if packs[pack] and pack ~= card then
					if not pack_why then tech_why, pack_why = needing(card) end
					if pack_why[pack] then
						looping[#looping + 1] = {index = index, pack = pack, chain = chain_of(pack, tech_why, pack_why)}
					end
				end
			end
			if #looping > 0 then
				if #ingredients - #looping < min_card_ingredients then
					for _, entry in ipairs(looping) do
						local key = card .. "/" .. entry.pack
						if not reported[key] then
							reported[key] = true
							log("[Razi Protocol/system-gates] ERROR: " .. card .. " needs " .. entry.pack
								.. " but its research needs " .. card .. " (" .. entry.chain
								.. "); kept, because dropping it would leave " .. card .. " with "
								.. (#ingredients - #looping) .. " of " .. #ingredients .. " ingredients")
						end
					end
				else
					for _, entry in ipairs(looping) do
						table.remove(ingredients, entry.index)
						log("[Razi Protocol/system-gates] " .. card .. " no longer needs " .. entry.pack
							.. ": its research needs " .. card .. " (" .. entry.chain .. ")")
						changed = true
					end
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
