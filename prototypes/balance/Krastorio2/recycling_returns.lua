local recycling_returns = {}

-- Recycling recipes that the recycler builds from a dearer alternative recipe return more than a quarter of the
-- recipe that is really used. Each is brought to a quarter of the cheapest recipe:
-- - glass-recycling: from Moshine's glass (4 sand -> 1), 50 % of the K2 recipe (16 sand -> 8 glass); 1 glass returns
--   half a sand;
-- - gold-plate-recycling: from secretas' gold-plate-alt (4 ore -> 1 plate), 100 % of the main chain (1 ore a plate):
--   a quarter of an ore.
local function results_of(name)
	local recipe = data.raw.recipe[name]
	return recipe and recipe.results or {}
end

local function set_fraction(name, item, total)
	for _, product in pairs(results_of(name)) do
		if product.name == item then
			product.amount = math.floor(total)
			product.extra_count_fraction = total - product.amount
			if product.extra_count_fraction == 0 then
				product.extra_count_fraction = nil
			end
			log("razi-protocol: " .. name .. " returns " .. total .. " " .. item)
		end
	end
end

local function total_of(name, item)
	for _, product in pairs(results_of(name)) do
		if product.name == item then
			return (product.amount or 0) + (product.extra_count_fraction or 0)
		end
	end
end

function recycling_returns.data_final_fixes()
	if total_of("glass-recycling", "kr-sand") == 1 then
		set_fraction("glass-recycling", "kr-sand", 0.5)
	end
	if total_of("gold-plate-recycling", "gold-ore") == 1 then
		set_fraction("gold-plate-recycling", "gold-ore", 0.25)
	end
	-- the burner inserter crusher gives a part back at 100 %: the inserter plus 1 plate buys 1.75 parts with the base
	-- productivity of the bioassembler
	local crush = data.raw.recipe["kr-crush-burner-inserter"]
	for _, product in pairs(crush and crush.results or {}) do
		if product.name == "kr-inserter-parts" and product.amount == 1 and not product.extra_count_fraction then
			product.amount = 0
			product.extra_count_fraction = 0.5
			log("razi-protocol: kr-crush-burner-inserter returns half a part")
		end
	end
end

return recycling_returns
