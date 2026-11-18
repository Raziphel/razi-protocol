-- Planetaris Dyes 1.0.8 makes 10 colored walls from 5 stone walls and a dye (prototypes/recipe.lua:205-207): dyeing
-- doubles the walls. The colored wall recipes make 5.
local colored_walls = {}

function colored_walls.data_final_fixes()
	for name, recipe in pairs(data.raw.recipe or {}) do
		if name:find("^planetaris%-.+%-stone%-wall$") then
			for _, product in pairs(recipe.results or {}) do
				if product.name == name and product.amount == 10 then
					product.amount = 5
					log("razi-protocol: " .. name .. " makes 5 walls from 5")
				end
			end
		end
	end
end

return colored_walls
