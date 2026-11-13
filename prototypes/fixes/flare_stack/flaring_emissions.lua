local flaring_emissions = {}

-- Flare Stack 4.3.1 builds a "<fluid>-flaring" recipe for every fluid and gives it emissions_multiplier 0 for oxygen,
-- hydrogen, steam and water and 1 for everything else (data-final-fixes.lua:42-47, 72-78), so a fluid that pollutes
-- more or less than usual when burnt (crude oil 3, heavy oil 2, ethanol 0.25 in this set of mods) flares like any
-- other. The open pull request snouz/GotLag-Flare-Stack#21 reads the multiplier of the fluid. Here a
-- flaring recipe that still has 1 gets the multiplier of its fluid; the zeros stay.
function flaring_emissions.data_final_fixes()
	local recipes = data.raw.recipe or {}
	local changed = 0
	for name, fluid in pairs(data.raw.fluid or {}) do
		local recipe = recipes[name .. "-flaring"]
		local multiplier = fluid.emissions_multiplier
		if recipe and recipe.emissions_multiplier == 1 and type(multiplier) == "number" and multiplier ~= 1 then
			recipe.emissions_multiplier = multiplier
			changed = changed + 1
		end
	end
	if changed > 0 then
		log("razi-protocol: " .. changed .. " flaring recipes of Flare Stack pollute as their fluid does when burnt")
	end
end

return flaring_emissions
