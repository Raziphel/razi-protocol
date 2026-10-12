local water_loop = {}

-- Vesta's water/hydrogen/oxygen recipes can form a productive recycling
-- loop alongside K2SO machines. Cap productivity on both sides without
-- changing the base conversion recipes or removing the planet's challenge.
local recipes = {
	"ske_h2o",
	"ske_water_electrolysis"
}

function water_loop.data_final_fixes()
	for _, name in ipairs(recipes) do
		local recipe = data.raw.recipe[name]
		if recipe then
			recipe.allow_productivity = false
			recipe.maximum_productivity = 0
		end
	end
end

return water_loop
