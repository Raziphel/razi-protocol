-- Razi puts Ferrum behind beetlejuice-discovery, which is priced in Vibrant and Vespera cards. Ferrum itself is written
-- for an earlier place; two things of the mod would make the research it needs wait for the planet:
-- - Its robotics science: planet-ferrum data-updates.lua:13-19 and prototypes/science.lua add the pack to every
--   technology priced in Vulcanus, Fulgora and Gleba science and make the technology that unlocks the pack a
--   prerequisite. Three technologies that feed the Vibrant card (planetaris-refraction-science-pack,
--   planetaris-particle-manipulation, planetaris-beryllium-processing) would need Ferrum's pack, which needs Ferrum, which
--   needs the Vibrant card. The cycle breaker of technology/system_gate_links.lua resolves it by taking the refraction
--   and pathological packs out of the Vibrant card recipe, so a recommended world would change a required recipe.
-- - Its magnets: data-updates.lua:8-13 adds ten ferrum-rare-earth-magnet to the cryogenic plant (and 200 to the fusion
--   reactor). The Vespera card needs the cryogenic science pack, whose research data needs fluoroketone from the
--   cryogenic plant: plant -> Ferrum -> beetlejuice-discovery -> Vespera card -> cryogenic science pack -> plant. A
--   recipe cannot be part of a technology cycle, so only the recipe check of a play-through (YAFC) sees it.
-- Whatever Ferrum's discovery needs does not need Ferrum's pack or its magnets. Technologies and recipes after Ferrum
-- (the fusion reactor, legendary quality, ...) keep them.
local TechnologyGraph = require("__razi_lib__/lib/technology_graph")

local compat = {}

local pack = "ferrum-robotics-science-pack"
local magnet = "ferrum-rare-earth-magnet"
local gate = "planet-discovery-ferrum"

local function ingredient_name(ingredient)
	return ingredient.name or ingredient[1]
end

-- Takes every entry of the item out of the list; true if there was one.
local function remove_named(list, name)
	local removed = false
	for index = #list, 1, -1 do
		if ingredient_name(list[index]) == name then
			table.remove(list, index)
			removed = true
		end
	end
	return removed
end

-- Technologies that the gate needs: through prerequisites, through the packs in a price (the technologies that unlock
-- the recipe of the pack) and through the packs in the recipe of such a pack. The prerequisites and the price entries
-- that name Ferrum's pack are not followed: they are the cycle.
local function ancestors_of_gate(technologies, unlock_index)
	local priced = {}
	for _, technology in pairs(technologies) do
		for _, ingredient in ipairs(technology.unit and technology.unit.ingredients or {}) do
			priced[ingredient_name(ingredient)] = true
		end
	end

	local skipped = {}
	for _, name in ipairs(unlock_index[pack] or {}) do
		skipped[name] = true
	end

	local seen_techs, seen_packs, found = {}, {}, {}
	local pending = {{tech = gate}}
	while #pending > 0 do
		local node = table.remove(pending)
		if node.tech then
			local technology = technologies[node.tech]
			if technology and not seen_techs[node.tech] then
				seen_techs[node.tech] = true
				found[#found + 1] = node.tech
				for _, parent in ipairs(technology.prerequisites or {}) do
					if not skipped[parent] then
						pending[#pending + 1] = {tech = parent}
					end
				end
				for _, ingredient in ipairs(technology.unit and technology.unit.ingredients or {}) do
					if ingredient_name(ingredient) ~= pack then
						pending[#pending + 1] = {pack = ingredient_name(ingredient)}
					end
				end
			end
		elseif not seen_packs[node.pack] then
			local pack_name = node.pack ---@type string
			seen_packs[pack_name] = true
			for _, unlocker in ipairs(unlock_index[pack_name] or {}) do
				pending[#pending + 1] = {tech = unlocker}
			end
			local recipe = data.raw.recipe and data.raw.recipe[pack_name]
			for _, ingredient in ipairs(recipe and recipe.ingredients or {}) do
				local name = ingredient_name(ingredient)
				if priced[name] and name ~= pack then
					pending[#pending + 1] = {pack = name}
				end
			end
		end
	end
	return found, skipped
end

function compat.data_final_fixes()
	if not (mods and mods["planet-ferrum"]) then
		return
	end
	local technologies = data.raw.technology
	if not (technologies and technologies[gate]) then
		return
	end

	local unlock_index = TechnologyGraph.unlock_index(technologies)
	local ancestors, unlocking = ancestors_of_gate(technologies, unlock_index)
	local stripped = 0
	for _, name in ipairs(ancestors) do
		local technology = technologies[name]
		local ingredients = technology.unit and technology.unit.ingredients or {}
		local priced = false
		for index = #ingredients, 1, -1 do
			if ingredient_name(ingredients[index]) == pack then
				if #ingredients > 1 then
					table.remove(ingredients, index)
					stripped = stripped + 1
					log("razi-protocol: " .. name .. " no longer costs " .. pack .. ": " .. gate .. " needs it")
				else
					priced = true
				end
			end
		end

		local prerequisites = technology.prerequisites or {}
		for index = #prerequisites, 1, -1 do
			if unlocking[prerequisites[index]] and not priced then
				log("razi-protocol: " .. name .. " no longer requires " .. prerequisites[index] .. ": " .. gate .. " needs it")
				table.remove(prerequisites, index)
			end
		end
	end
	log("razi-protocol: " .. pack .. " stripped from " .. stripped .. " technologies that " .. gate .. " needs")

	-- the recipes that those technologies unlock and that ask for Ferrum's magnets, and their recycling recipes
	local needed = {}
	for _, name in ipairs(ancestors) do
		needed[name] = true
	end
	for recipe_name, recipe in pairs(data.raw.recipe or {}) do
		local unlockers = unlock_index[recipe_name] or {}
		local is_needed = #unlockers > 0
		for _, unlocker in ipairs(unlockers) do
			is_needed = is_needed and needed[unlocker] == true
		end
		if is_needed and remove_named(recipe.ingredients or {}, magnet) then
			log("razi-protocol: " .. recipe_name .. " no longer takes " .. magnet .. ": " .. gate .. " needs it")
			local recycling = data.raw.recipe[recipe_name .. "-recycling"]
			if recycling then
				remove_named(recycling.results or {}, magnet)
			end
		end
	end
end

return compat
