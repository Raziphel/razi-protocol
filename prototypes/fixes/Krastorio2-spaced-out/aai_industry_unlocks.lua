-- AAI Industry 0.7.5 opens kr-grow-wood-with-sand through kr-greenhouse
-- (prototypes/phase-3/compatibility/krastorio2.lua:129-136), but Krastorio 2
-- Spaced Out 2.0.19 redefines kr-greenhouse without that unlock
-- (prototypes/final-fixes/trigger-tech.lua:49-65). AAI removes kr-laboratory
-- and opens lab through electric-lab; K2SO recreates the hidden kr-laboratory
-- with the lab unlock (trigger-tech.lua:33-48) and only hides it
-- (prototypes/compatibility/aai-industry.lua:26).
local progression_helpers = require("prototypes.fixes.common.progression_helpers")

local aai_industry_unlocks = {}

local function has_recipe_unlock(recipe_name)
	for _, technology in pairs(data.raw.technology or {}) do
		for _, effect in ipairs(technology.effects or {}) do
			if effect.type == "unlock-recipe" and effect.recipe == recipe_name then
				return true
			end
		end
	end
	return false
end

local function has_visible_recipe_unlock(recipe_name)
	for _, technology in pairs(data.raw.technology or {}) do
		if not technology.hidden then
			for _, effect in ipairs(technology.effects or {}) do
				if effect.type == "unlock-recipe" and effect.recipe == recipe_name then
					return true
				end
			end
		end
	end
	return false
end

function aai_industry_unlocks.data_final_fixes()
	if not (mods and mods["aai-industry"]) then
		return
	end

	local wood_recipe = data.raw.recipe and data.raw.recipe["kr-grow-wood-with-sand"]
	local greenhouse = data.raw.technology and data.raw.technology["kr-greenhouse"]
	if wood_recipe and greenhouse and not has_recipe_unlock("kr-grow-wood-with-sand") then
		progression_helpers.add_recipe_unlock("kr-greenhouse", "kr-grow-wood-with-sand")
		log("razi-protocol: kr-greenhouse unlocks kr-grow-wood-with-sand again for AAI Industry")
	end

	local laboratory = data.raw.technology and data.raw.technology["kr-laboratory"]
	if laboratory and laboratory.hidden == true and has_visible_recipe_unlock("lab") then
		local has_lab_unlock = false
		for _, effect in ipairs(laboratory.effects or {}) do
			if effect.type == "unlock-recipe" and effect.recipe == "lab" then
				has_lab_unlock = true
				break
			end
		end
		if has_lab_unlock then
			progression_helpers.remove_recipe_unlock("kr-laboratory", "lab")
			log("razi-protocol: kr-laboratory no longer unlocks lab because AAI Industry opens it through another visible technology")
		end
	end
end

return aai_industry_unlocks
