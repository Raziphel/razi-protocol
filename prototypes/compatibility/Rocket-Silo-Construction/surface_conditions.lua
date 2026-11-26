local M = {}

local function copy(value)
	if type(value) ~= "table" then
		return value
	end

	local result = {}
	for key, child in pairs(value) do
		result[copy(key)] = copy(child)
	end
	return result
end

local function same_value(left, right)
	if left == right then
		return true
	end
	if type(left) ~= "table" or type(right) ~= "table" then
		return false
	end

	for key, value in pairs(left) do
		if not same_value(value, right[key]) then
			return false
		end
	end
	for key in pairs(right) do
		if left[key] == nil then
			return false
		end
	end
	return true
end

local function has_gravity(conditions)
	for _, condition in ipairs(conditions) do
		if condition.property == "gravity" then
			return true
		end
	end
	return false
end

function M.data_final_fixes()
	if not mods or not mods["Rocket-Silo-Construction"] then
		return
	end

	local raw = data and data.raw
	local silos = raw and raw["rocket-silo"]
	local rocket_silo = silos and silos["rocket-silo"]
	if not rocket_silo then
		return
	end

	-- RSC's construction site checks gravity (Rocket-Silo-Construction/data.lua:46-58); keep each stage within the
	-- same surface limits as the finished silo.
	local target = copy(rocket_silo.surface_conditions or {})
	local surface_properties = raw["surface-property"]
	if not has_gravity(target) and surface_properties and surface_properties.gravity then
		target[#target + 1] = { property = "gravity", min = 0.1 }
	end

	local machines = raw["assembling-machine"]
	if not machines then
		return
	end

	for index = 1, 6 do
		local name = "rsc-silo-stage" .. index
		local stage = machines[name]
		if stage and not same_value(stage.surface_conditions or {}, target) then
			stage.surface_conditions = copy(target)
			log("razi-protocol: Rocket-Silo Construction: copied rocket-silo surface conditions to " .. name)
		end
	end
end

return M
