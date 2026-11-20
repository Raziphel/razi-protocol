-- xy-k2so-enhancements-nulls-fork 0.8.6 puts the Krastorio advanced chemical plant into the recipe of the Paracelsin
-- electrochemical plant (patches/entity.lua:47-53) and makes planet-discovery-paracelsin require its technology
-- (patches/technology.lua:35). The progression of this mod sets the prerequisites of planet-discovery-paracelsin anew
-- (prototypes/technology/systems/progression.lua), so the electrochemical plant could be researched before the machine
-- its recipe needs. Its technology requires kr-advanced-chemical-plant when nothing before it does.
local electrochemical_plant_prerequisite = {}

local TECHNOLOGY = "electrochemical-plant"
local INGREDIENT = "kr-advanced-chemical-plant"
local REQUIRED = "kr-advanced-chemical-plant"

local function needs_ingredient()
	local recipe = data.raw.recipe and data.raw.recipe[TECHNOLOGY]
	for _, ingredient in ipairs(recipe and recipe.ingredients or {}) do
		if ingredient.name == INGREDIENT then
			return true
		end
	end

	return false
end

-- Whether the technology requires `name`, directly or through its prerequisites.
local function requires(technologies, start, name)
	local seen, queue = {}, {start}
	while #queue > 0 do
		local technology = technologies[table.remove(queue)]
		for _, prerequisite in ipairs(technology and technology.prerequisites or {}) do
			if prerequisite == name then
				return true
			end
			if not seen[prerequisite] then
				seen[prerequisite] = true
				queue[#queue + 1] = prerequisite
			end
		end
	end

	return false
end

function electrochemical_plant_prerequisite.data_final_fixes()
	local technologies = data.raw.technology
	local technology = technologies and technologies[TECHNOLOGY]
	if not (technology and technologies[REQUIRED] and needs_ingredient()) or requires(technologies, TECHNOLOGY, REQUIRED) then
		return
	end

	technology.prerequisites = technology.prerequisites or {}
	table.insert(technology.prerequisites, REQUIRED)
	log("razi-protocol: " .. TECHNOLOGY .. " requires " .. REQUIRED .. ", which its recipe needs")
end

return electrochemical_plant_prerequisite
