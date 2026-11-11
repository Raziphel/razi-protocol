-- Calcite in space after Vulcanus. Vulcanus lies in the Solaris system, 103 000 km from Nauvis, and the home system
-- has no other calcite: the resource is on Vulcanus, Corrundum and the alchemy planet, and the oxide asteroid crushing
-- that yields it is research of Gleba's science (advanced-asteroid-processing). A player who went to Vulcanus first
-- could feed foundries at home only by interstellar flights. The metallurgic science pack research, done on Vulcanus,
-- also unlocks that crushing recipe, so a platform over Nauvis or Muluna crushes the local oxide chunks into calcite.
-- advanced-asteroid-processing keeps the unlock as well. Nothing changes when the recipe no longer makes calcite or one
-- of the two prototypes is missing.
local space_calcite = {}

local technology_name = "metallurgic-science-pack"
local recipe_name = "advanced-oxide-asteroid-crushing"

local function makes_calcite(recipe)
	for _, result in ipairs(recipe.results or {}) do
		if (result.name or result[1]) == "calcite" then
			return true
		end
	end
	return false
end

function space_calcite.data_final_fixes()
	local technology = data.raw.technology and data.raw.technology[technology_name]
	local recipe = data.raw.recipe and data.raw.recipe[recipe_name]
	if not technology or not recipe or not makes_calcite(recipe) then
		return
	end
	for _, effect in ipairs(technology.effects or {}) do
		if effect.type == "unlock-recipe" and effect.recipe == recipe_name then
			return
		end
	end
	technology.effects = technology.effects or {}
	table.insert(technology.effects, {type = "unlock-recipe", recipe = recipe_name})
	log("razi-protocol: " .. technology_name .. " also unlocks " .. recipe_name .. ", calcite from oxide asteroids")
end

return space_calcite
