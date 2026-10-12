local water_loop = {}

-- Keep Vesta's reciprocal hydrogen/oxygen recipes safe from K2SO machine
-- base productivity, even when their own recipe productivity is disabled.
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
