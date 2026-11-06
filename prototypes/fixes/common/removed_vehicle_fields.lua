local removed_vehicle_fields = {}

-- Factorio 2.1 replaced braking_power and friction of a vehicle with braking_force and friction_force, and silently
-- ignores the old fields. Mods that still write them on a copy of a vanilla car keep the numbers of the vanilla car:
-- - the tank of Krastorio2 2.1.4 (prototypes/updates/base/entities.lua:96, "1.75MW") brakes with the 800 kW of the vanilla
--   tank, its braking distance is 1.9 times too long;
-- - RTPropCar of RenaiTransportation 2.3.4 and older (prototypes/TrainGoBrrrr/PropHunt.lua:18), the hidden stand-in of
--   a flying train, loses speed; 2.3.5 writes friction_force, and Renai is not a dependency, so older versions still come.
-- The rocket buggy of planet-muluna writes the new fields since 2.9.14, the version this mod requires.
-- The old value is moved to the new field by the conversion the game itself uses (power / 60), on every car that has one,
-- so the copies of other mods follow, and the repair does nothing once a mod writes the new field.
-- Only cars: a spider vehicle ignores the field either way (measured on the Maraxsis submarines).
function removed_vehicle_fields.data_final_fixes()
	for name, car in pairs(data.raw.car or {}) do
		---@type any
		local old = car
		if old.braking_power ~= nil then
			local force = old.braking_power
			if type(force) == "string" then
				force = require("__core__.lualib.util").parse_energy(force)
			end
			car.braking_force = force
			old.braking_power = nil
			log("razi-protocol: " .. name .. " braking_force = " .. force .. " from braking_power")
		end
		if old.friction ~= nil then
			car.friction_force = old.friction
			old.friction = nil
			log("razi-protocol: " .. name .. " friction_force = " .. car.friction_force .. " from friction")
		end
	end
end

return removed_vehicle_fields
