-- moon-eneas 1.0.10 with its startup setting integrate-lignumis removes the Lignumis technology
-- basic-construction-robotics-copper (prototypes/patches/lignumis-recipe.lua:14-17) but leaves the technologies that
-- require it. Lignumis 2.12.4 basic-roboport requires it (prototypes/content/basic-roboport.lua:327), and the game
-- refuses to load: "technology with name 'basic-construction-robotics-copper' does not exist". Those technologies
-- require what the removed one required instead (prototypes/content/basic-construction-robots.lua:214), so they stay
-- in the same place of the tree.
local lignumis_robotics = {}

local REMOVED = "basic-construction-robotics-copper"
local REMOVED_PREREQUISITES = {"basic-construction-robotics-gold", "automation-science-pack"}

function lignumis_robotics.data_final_fixes()
	local technologies = data.raw.technology
	if not (mods and mods["moon-eneas"] and mods["lignumis"] and technologies) or technologies[REMOVED] then
		return
	end

	for name, technology in pairs(technologies) do
		local prerequisites = technology.prerequisites or {}
		for index = #prerequisites, 1, -1 do
			if prerequisites[index] == REMOVED then
				table.remove(prerequisites, index)
				local at = index
				for _, replacement in ipairs(REMOVED_PREREQUISITES) do
					local present = false
					for _, prerequisite in ipairs(prerequisites) do
						present = present or prerequisite == replacement
					end
					if technologies[replacement] and not present then
						table.insert(prerequisites, at, replacement)
						at = at + 1
					end
				end
				log("razi-protocol: " .. name .. " no longer requires " .. REMOVED
					.. ", which Eneas removes with integrate-lignumis, and requires its prerequisites instead")
			end
		end
	end
end

return lignumis_robotics
