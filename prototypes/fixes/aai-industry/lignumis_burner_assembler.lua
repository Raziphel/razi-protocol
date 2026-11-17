-- AAI Industry 0.7.5 swaps the motor of burner-assembling-machine for 2 kr-automation-core under Krastorio 2
-- (prototypes/phase-3/compatibility/krastorio2.lua:74, replace_or_add_ingredient). Lignumis 2.12.4 owns that recipe
-- with wooden parts and no motor (prototypes/content/burner-assembling-machine.lua:97-108), so the call adds the cores
-- instead. The cores take iron and copper plates behind iron-processing and copper-processing, which Lignumis has
-- before the trip to Nauvis, while burner-automation needs only wood science.
local lignumis_burner_assembler = {}

local RECIPE = "burner-assembling-machine"
local CORE = "kr-automation-core"
local CORE_AMOUNT = 2

local function has_ingredient(recipe, name)
	for _, ingredient in ipairs(recipe.ingredients or {}) do
		if ingredient.name == name then
			return true
		end
	end
	return false
end

function lignumis_burner_assembler.data_final_fixes()
	if not (mods and mods["lignumis"] and mods["aai-industry"]) then
		return
	end

	local recipe = data.raw.recipe and data.raw.recipe[RECIPE]
	-- The wooden gear wheel marks the recipe of Lignumis; the recipe of AAI Industry keeps its cores.
	if not (recipe and has_ingredient(recipe, "wooden-gear-wheel")) then
		return
	end

	local ingredients = recipe.ingredients or {}
	for index, ingredient in ipairs(ingredients) do
		if ingredient.name == CORE and ingredient.amount == CORE_AMOUNT then
			table.remove(ingredients, index)
			log("razi-protocol: " .. RECIPE .. " no longer takes " .. CORE .. ", which AAI Industry added to the wooden recipe of Lignumis")
			return
		end
	end
end

return lignumis_burner_assembler
