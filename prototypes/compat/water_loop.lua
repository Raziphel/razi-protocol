local water_loop = {}

-- Water goes round through hydrogen and oxygen: Shchierbin's electrolysis makes
-- 100 hydrogen and 800 oxygen from 100 water (with Muluna), and Vesta's ske_h2o
-- makes 30 water from 20 hydrogen and 10 oxygen. K2SO makes both mods use
-- kr-hydrogen and kr-oxygen, so one round gives 150 water for 100, for power
-- only. With productivity it grows much faster: the base productivity of a
-- machine applies even to a recipe with allow_productivity = false (the K2
-- advanced chemical plant makes a round x2.3, the electrochemical plant x3.4),
-- and Vesta's own electrolysis even allows productivity modules.
-- maximum_productivity = 0 is the cap the game applies to every source,
-- machine bonus included. The round itself stays and costs power.
local recipes = {
	"water-electrolysis-shchierbin",
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
