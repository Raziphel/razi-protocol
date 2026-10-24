-- Skewer Shattered Planet 1.0.42 next to Skewer Planet Vesta: three recipes that no technology opens.
--
-- With Vesta, prototypes/technology.lua of the mod (lines 668-744) leaves `ske_water_vaporization` out of
-- `chunk_slurry_creation` and `ske_ammonia` out of `alternate_methods_of_production`; the branch without Vesta lists both
-- (lines 744-825). The third, `nitrogen`, is listed in both branches, but its name is also the name of the fluid:
-- paracelsin-krastorio-compatibility-plus (data-final-fixes.lua:15-22 and :147-155) hides every recipe named like a fluid
-- it replaces and removes its unlock from all technologies, and with it Skewer's own slurry recipe.
-- Until Skewer Shattered Planet lists the two recipes under Vesta and Paracelsin Krastorio Compatibility+ hides only
-- its own recipes, the unlocks come back here, on the technologies that carry them in the branch without Vesta.
local compat = {}

-- recipe -> technology of the branch without Vesta
local unlocks = {
	{recipe = "ske_water_vaporization", technology = "chunk_slurry_creation"},
	{recipe = "ske_ammonia", technology = "alternate_methods_of_production"},
	{recipe = "nitrogen", technology = "alternate_methods_of_production", slurry_recipe = true},
}

local function unlocked(recipe_name)
	for _, technology in pairs(data.raw.technology or {}) do
		for _, effect in pairs(technology.effects or {}) do
			if effect.type == "unlock-recipe" and effect.recipe == recipe_name then
				return true
			end
		end
	end
	return false
end

-- The recipe of the slurry of the mod, not another one named `nitrogen`.
local function takes_oxide_slurry(recipe)
	for _, ingredient in pairs(recipe.ingredients or {}) do
		if (ingredient.name or ingredient[1]) == "ske_slurry_oxide" then
			return true
		end
	end
	return false
end

function compat.data_final_fixes()
	if not (mods and mods["skewer_shattered_planet"] and mods["skewer_planet_vesta"]) then
		return
	end

	local recipes = data.raw.recipe or {}
	for _, entry in ipairs(unlocks) do
		local recipe = recipes[entry.recipe]
		local technology = data.raw.technology and data.raw.technology[entry.technology]
		if recipe and technology and not unlocked(entry.recipe) and (not entry.slurry_recipe or takes_oxide_slurry(recipe)) then
			if entry.slurry_recipe and recipe.hidden then
				recipe.hidden = false
				log("razi-protocol: " .. entry.recipe .. " is shown again")
			end
			technology.effects = technology.effects or {}
			technology.effects[#technology.effects + 1] = {type = "unlock-recipe", recipe = entry.recipe}
			log("razi-protocol: " .. entry.technology .. " unlocks " .. entry.recipe .. " again")
		end
	end
end

return compat
