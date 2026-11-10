local vehicle_fuel = {}

-- Krastorio 2 moves the car and the tank to its vehicle fuel only (kr-vehicle-fuel: fuel, biofuel, advanced fuel;
-- prototypes/updates/base/entities.lua:84 and :91), and the locomotive to chemical and vehicle fuel together (:304).
-- The planes of Aircraft Space Age take the fuel categories of the car as the car was when Aircraft ran
-- (prototypes/entity/entities.lua:145), before Krastorio 2 changed them, so they, their carbon fiber versions and their
-- Rubia variants still take chemical fuel only and none of the K2 fuels fit them. They take both, as the locomotive does.
local planes = {gunship = true, ["cargo-plane"] = true, jet = true, ["flying-fortress"] = true}

function vehicle_fuel.data_final_fixes()
	local category = data.raw["fuel-category"] and data.raw["fuel-category"]["kr-vehicle-fuel"]
	if not category then
		return
	end

	for name, car in pairs(data.raw.car or {}) do
		local base_name = name:gsub("^rubia%-auto%-variant%-", ""):gsub("%-carbon%-fiber$", "")
		local burner = car.energy_source

		if planes[base_name] and burner and burner.type == "burner" then
			local categories = burner.fuel_categories or {}
			local has_chemical, has_vehicle = false, false
			for _, fuel_category in pairs(categories) do
				has_chemical = has_chemical or fuel_category == "chemical"
				has_vehicle = has_vehicle or fuel_category == "kr-vehicle-fuel"
			end

			if has_chemical and not has_vehicle then
				table.insert(categories, "kr-vehicle-fuel")
				burner.fuel_categories = categories
				log("razi-protocol: " .. name .. " also takes kr-vehicle-fuel")
			end
		end
	end
end

return vehicle_fuel
