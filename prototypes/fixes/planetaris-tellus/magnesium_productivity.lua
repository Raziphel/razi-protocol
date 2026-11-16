local magnesium_productivity = {}

-- planetaris-tellus 1.1.19 leaves allow_productivity out of the magnesium sheet recipe (prototypes/recipe.lua:93-110),
-- so productivity modules and the furnace bonus do not apply to it, unlike every other plate. The author called it a
-- bug on the mod portal in March 2026 (discussion 69b2fddad19ab84720771e1e). The recipe takes productivity.
function magnesium_productivity.data_final_fixes()
	local recipe = data.raw.recipe and data.raw.recipe["planetaris-magnesium-sheet"]
	if recipe and recipe.allow_productivity == nil then
		recipe.allow_productivity = true
		log("razi-protocol: planetaris-magnesium-sheet takes productivity like the other plates")
	end
end

return magnesium_productivity
