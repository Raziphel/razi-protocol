-- Krastorio 2 biomass burns as chemical fuel, and in 2.1 a locomotive refuels itself from the inventory of its driver,
-- so every train ride ate the biomass the player carried. Biomass gets a fuel category of its own, which every burner
-- that takes chemical fuel accepts too, except the locomotives. After every pass that adds a burner.
local biomass_fuel = {}

local function add_category(source)
	if type(source) ~= "table" or (source.type or "burner") ~= "burner" then
		return false
	end
	for _, category in pairs(source.fuel_categories or {}) do
		if category == "kr-biomass" then
			return false
		end
	end
	for _, category in pairs(source.fuel_categories or {}) do
		if category == "chemical" then
			table.insert(source.fuel_categories, "kr-biomass")
			return true
		end
	end

	return false
end

function biomass_fuel.data_final_fixes()
	local raw = data.raw
	local biomass = raw.item and raw.item["kr-biomass"]
	if not (biomass and biomass.fuel_value) then
		return
	end
	local categories = biomass.fuel_categories
	if not (categories and #categories == 1 and categories[1] == "chemical") then
		return
	end

	if not (raw["fuel-category"] and raw["fuel-category"]["kr-biomass"]) then
		data:extend({ { type = "fuel-category", name = "kr-biomass" } })
	end
	biomass.fuel_categories = { "kr-biomass" }

	local burners = 0
	for type_name, prototypes in pairs(raw) do
		if type_name ~= "locomotive" then
			for _, prototype in pairs(prototypes) do
				if type(prototype) == "table" then
					if add_category(prototype.energy_source) then
						burners = burners + 1
					end
					if add_category(prototype.burner) then
						burners = burners + 1
					end
				end
			end
		end
	end
	log("razi-protocol: kr-biomass burns as its own fuel category, taken by " .. burners .. " chemical burners, not by locomotives")
end

return biomass_fuel
