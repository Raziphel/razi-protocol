-- Space Age prices the stack inserter and the two belt capacity technologies in agricultural science and makes the stack inserter
-- and the toolbelt equipment wait for carbon fiber. With the system gates Gleba is a destination after Nyxaris, so these four
-- Krastorio 2 Spaced Out conveniences would wait for a trip off Nauvis. They stay on Nauvis: the order of the planets is
-- unchanged, and the four technologies lose Gleba's science and the carbon fiber research.
-- Runs before technology/system_gate_links.lua, which would otherwise tie a technology priced in agricultural science to its pack.
-- The recipes that the stack inserter and the toolbelt equipment unlock still name carbon fiber (and jelly); this pass does not
-- touch recipes.
local TechnologyGraph = require("__razi_lib__/lib/technology_graph")

local nauvis_comforts = {}

local technology_names = {
	"stack-inserter",
	"toolbelt-equipment",
	"transport-belt-capacity-1",
	"transport-belt-capacity-2"
}

-- Packs of the planets behind the first systems, and the research that opens Gleba's branch.
local planet_packs = {
	["agricultural-science-pack"] = true,
	["electromagnetic-science-pack"] = true,
	["metallurgic-science-pack"] = true
}
local gleba_prerequisites = {
	["agricultural-science-pack"] = true,
	["carbon-fiber"] = true
}
-- Packs of Nauvis whose technology carries the pack's name.
local nauvis_packs = {
	["production-science-pack"] = true,
	["space-science-pack"] = true,
	["utility-science-pack"] = true
}

local function ingredient_name(ingredient)
	return ingredient.name or ingredient[1]
end

local function strip_packs(name, technology)
	local ingredients = technology.unit and technology.unit.ingredients
	if not ingredients then
		return
	end
	for index = #ingredients, 1, -1 do
		local pack = ingredient_name(ingredients[index])
		if planet_packs[pack] then
			if #ingredients > 1 then
				table.remove(ingredients, index)
				log("razi-protocol: " .. name .. " no longer costs " .. pack)
			else
				log("razi-protocol: " .. name .. " keeps " .. pack .. ": it is the only pack of the price")
			end
		end
	end
end

local function strip_prerequisites(name, technology)
	local prerequisites = technology.prerequisites
	if not prerequisites then
		return
	end
	for index = #prerequisites, 1, -1 do
		local parent = prerequisites[index]
		if gleba_prerequisites[parent] then
			if #prerequisites > 1 then
				table.remove(prerequisites, index)
				log("razi-protocol: " .. name .. " no longer requires " .. parent)
			else
				log("razi-protocol: " .. name .. " keeps " .. parent .. ": it is the only prerequisite")
			end
		end
	end
end

-- The prerequisites that were dropped also led to the research of the packs that remain in the price (a pack whose
-- technology is not an ancestor can not be made yet). Add the technology of each remaining Nauvis pack, unless it is an ancestor.
local function link_packs(technologies, name, technology)
	for _, ingredient in ipairs(technology.unit and technology.unit.ingredients or {}) do
		local pack = ingredient_name(ingredient)
		if nauvis_packs[pack] and technologies[pack] and TechnologyGraph.add_prerequisite(technologies, name, pack) then
			log("razi-protocol: " .. name .. " now requires " .. pack .. ": the pack is in its price")
		end
	end
end

-- The technologies after the stack inserter reached the carbon fiber research through it. Those that unlock a recipe with carbon
-- fiber keep it as a prerequisite.
local function keep_carbon_fiber_links(technologies)
	local recipes = data.raw.recipe or {}
	local names, listed = {}, {}
	for name, technology in pairs(technologies) do
		for _, effect in ipairs(technology.effects or {}) do
			local recipe = effect.type == "unlock-recipe" and recipes[effect.recipe]
			for _, ingredient in ipairs(recipe and recipe.ingredients or {}) do
				if ingredient_name(ingredient) == "carbon-fiber" and not listed[name] then
					listed[name] = true
					names[#names + 1] = name
				end
			end
		end
	end
	table.sort(names)
	local comforts = {}
	for _, name in ipairs(technology_names) do
		comforts[name] = true
	end
	for _, name in ipairs(names) do
		if not comforts[name] then
			for comfort in pairs(comforts) do
				if technologies[comfort] and TechnologyGraph.reaches(technologies, name, comfort) then
					if TechnologyGraph.add_prerequisite(technologies, name, "carbon-fiber") then
						log("razi-protocol: " .. name .. " now requires carbon-fiber: it unlocks a recipe with carbon fiber")
					end
					break
				end
			end
		end
	end
end

function nauvis_comforts.data_final_fixes()
	local technologies = data.raw.technology
	if not technologies then
		return
	end
	for _, name in ipairs(technology_names) do
		local technology = technologies[name]
		if technology then
			strip_packs(name, technology)
			strip_prerequisites(name, technology)
		end
	end
	-- after all four were stripped: the belt capacity technologies reach the packs through the stack inserter
	for _, name in ipairs(technology_names) do
		local technology = technologies[name]
		if technology then
			link_packs(technologies, name, technology)
		end
	end
	keep_carbon_fiber_links(technologies)
end

return nauvis_comforts
