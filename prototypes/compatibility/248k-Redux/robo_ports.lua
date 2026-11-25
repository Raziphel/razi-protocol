local M = {}

-- Space platforms have zero pressure, so roboports cannot operate there. The
-- 248k roboport prototypes define no surface conditions
-- (248k-Redux/prototypes/fission/fi_robo.lua:40-72,139-169).
local function note(message)
	if log then
		log("razi-protocol: 248k: " .. message)
	end
end

function M.data_final_fixes()
	if not (mods and mods["248k-Redux"]) then
		return
	end

	for name, roboport in pairs(data.raw.roboport or {}) do
		if name:find("fi_robo_", 1, true) then
			local pressure_condition
			local changed = false
			for _, condition in pairs(roboport.surface_conditions or {}) do
				if condition.property == "pressure" then
					pressure_condition = condition
					break
				end
			end

			if pressure_condition then
				if pressure_condition.min == nil or pressure_condition.min < 5 then
					pressure_condition.min = 5
					changed = true
				end
			else
				roboport.surface_conditions = roboport.surface_conditions or {}
				roboport.surface_conditions[#roboport.surface_conditions + 1] = {
					property = "pressure",
					min = 5,
				}
				changed = true
			end

			if changed then
				note(name .. " requires pressure of at least 5")
			end
		end
	end
end

return M
