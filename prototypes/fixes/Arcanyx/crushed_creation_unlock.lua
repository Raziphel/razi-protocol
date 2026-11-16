local crushed_creation_unlock = {}

-- Arcanyx makes the recipe s6x-entropic-creation-crushed only while Crushing Industry's startup setting "Crushed ore" is on
-- (prototypes/entropic-creation.lua:58), but adds its unlock to s6x-entropic-creation whenever Crushing Industry is installed
-- (prototypes/technology.lua:316). With the setting off the game stops at load: "recipe with name
-- 's6x-entropic-creation-crushed' does not exist". The unlock goes when its recipe is missing.
local TECHNOLOGY = "s6x-entropic-creation"
local RECIPE = "s6x-entropic-creation-crushed"

function crushed_creation_unlock.data_final_fixes()
	local technology = data.raw.technology and data.raw.technology[TECHNOLOGY]
	if not technology or type(technology.effects) ~= "table" or (data.raw.recipe or {})[RECIPE] then
		return
	end
	for index = #technology.effects, 1, -1 do
		local effect = technology.effects[index]
		if effect.type == "unlock-recipe" and effect.recipe == RECIPE then
			table.remove(technology.effects, index)
			log("razi-protocol: " .. TECHNOLOGY .. " no longer unlocks " .. RECIPE .. ", which is not made with crushed ore off")
		end
	end
end

return crushed_creation_unlock
