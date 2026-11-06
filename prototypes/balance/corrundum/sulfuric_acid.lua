local sulfuric_acid = {}

-- Corrundum dilutes sulfuric acid (100 acid + 400 water -> 500 dilute) and concentrates it back (500 dilute -> 100
-- acid). Both recipes have allow_productivity = false, but the electrochemical plant adds +50 % to every recipe
-- unless maximum_productivity is 0 (see balance/common/catalysts.lua): a round gives 2.25 times the acid, for water.
-- They take no productivity at all.
function sulfuric_acid.data_final_fixes()
	for _, name in pairs({ "sulfuric-acid-dilution", "sulfuric-acid-concentration-alt", "sulfuric-acid-concentration" }) do
		local recipe = data.raw.recipe[name]
		if recipe and recipe.allow_productivity == false and recipe.maximum_productivity == 1 then
			recipe.maximum_productivity = 0
			log("razi-protocol: " .. name .. " takes no productivity")
		end
	end
end

return sulfuric_acid
