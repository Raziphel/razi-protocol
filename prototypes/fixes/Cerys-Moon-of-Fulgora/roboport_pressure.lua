local roboport_pressure = {}

-- Cerys 4.25.0 relaxes the pressure of every roboport to min = 5 so that robots work on Cerys
-- (prototypes/override-final/entity.lua:25-27). That also takes the roboports made for one planet off that planet:
--
-- The Maraxsis pressure dome and its regulator are roboports, so the dome could be placed on every planet but Muluna
-- (reported on the Foundry Discord, #cerys, 2026-10-01). Off Maraxsis the dome script does not track the entities
-- (scripts/pressure-dome.lua:360-366 of 1.40.26): it disables the machines under a new dome until the dome has
-- atmosphere, leaves them disabled when the dome is taken down, and gives the regulator, a roboport without the dust
-- limit of the other roboports, to Arig. Their pressure goes back to what Maraxsis gives them, the range of its lamp
-- (maraxsis.surface_conditions(), lib/data-stage.lua:38-44), for the dome, the regulator and the logistic and
-- construction modes that Krastorio 2 makes of both. Only placing changes: the entities the dome script creates do
-- not check surface conditions.
--
-- Tenebris Prime 1.3.22 makes a bioluminescent copy of each roboport (prototypes/bioluminescent.lua:90-110 and :209):
-- no energy needed, pressure exactly 3000, so Tenebris only. Relaxed to 5..3000, these roboports without power went on
-- every planet up to the pressure of Tenebris. Every other bioluminescent copy still has min = max, and so do they
-- again.
--
-- A pull request to Cerys (https://github.com/danielmartin0/Cerys-Moon-of-Fulgora/pull/110) skips the roboports that
-- need more pressure than Nauvis; once it is released this file finds nothing to change.

---@class data.RoboportPrototype
---@field bioluminescent? boolean set by Tenebris Prime on its bioluminescent copies

---@alias PressureDomes table<string, { lamp: string, pressure_dome: string, regulator: string }>

local function pressure_condition(entity)
	for _, condition in pairs(entity and entity.surface_conditions or {}) do
		if condition.property == "pressure" then
			return condition
		end
	end

	return nil
end

local function restore(roboports, name, wanted_min)
	local condition = pressure_condition(roboports[name])

	if condition and (condition.min or 0) < wanted_min then
		log("razi-protocol: " .. name .. " pressure min " .. tostring(condition.min) .. " -> " .. wanted_min)
		condition.min = wanted_min
	end
end

function roboport_pressure.data_final_fixes()
	local roboports = data.raw.roboport or {}
	local constants = data.raw["mod-data"] and data.raw["mod-data"]["maraxsis-constants"]
	local domes = (constants and constants.data and constants.data.PRESSURE_DOMES or {}) --[[@as PressureDomes]]

	for _, dome in pairs(domes) do
		local lamp_condition = pressure_condition(data.raw.lamp and data.raw.lamp[dome.lamp])
		local wanted_min = lamp_condition and lamp_condition.min

		if wanted_min then
			for _, base_name in ipairs({dome.pressure_dome, dome.regulator}) do
				restore(roboports, base_name, wanted_min)
				restore(roboports, base_name .. "-logistic-mode", wanted_min)
				restore(roboports, base_name .. "-construction-mode", wanted_min)
			end
		end
	end

	local bioluminescent_names = {}
	for name, roboport in pairs(roboports) do
		if roboport.bioluminescent then
			bioluminescent_names[#bioluminescent_names + 1] = name
		end
	end
	table.sort(bioluminescent_names)

	for _, name in ipairs(bioluminescent_names) do
		local condition = pressure_condition(roboports[name])

		if condition and condition.max then
			restore(roboports, name, condition.max)
		end
	end
end

return roboport_pressure
