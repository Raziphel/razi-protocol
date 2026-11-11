-- Huge asteroids only where railguns are within reach. Only railguns stop a huge asteroid, and the railgun research
-- needs the science of level 8 and 9 worlds (Ferrum, Crucible). Razi More Asteroids already adds its huge asteroids
-- only from route level 9; the routes of other mods and Razi's own profiles put them earlier: Khemia - Ribbonia,
-- Aquilo - Balack and Beetlejuice - Umbra reach about 6 to 8. A huge spawn point on a space route is dropped where the
-- route level at that point (lib/difficulty/asteroids.lua, with the asteroid difficulty scale, as More Asteroids uses
-- it) is below 9; a definition with no point left is removed. Medium and big asteroids are not touched, nor orbits.
local levels = require("lib.difficulty.asteroids")
local difficulty = require("lib.difficulty.presets")

local huge_asteroid_gate = {}

huge_asteroid_gate.minimum_level = 9

local function is_huge(definition)
	if type(definition) ~= "table" or (definition.type ~= nil and definition.type ~= "entity") then
		return false
	end
	local name = definition.asteroid
	return type(name) == "string" and name:find("^huge%-.+%-asteroid$") ~= nil
		and (data.raw.asteroid or {})[name] ~= nil
end

-- The spawn points that stay, or nil when all stay.
local function gated_points(route, definition, mode)
	local kept, dropped = {}, 0
	for _, point in ipairs(definition.spawn_points or {}) do
		local distance = type(point) == "table" and (point.distance or point[1])
		if type(distance) == "number"
			and levels.route_level(route, distance, mode) < huge_asteroid_gate.minimum_level then
			dropped = dropped + 1
		else
			kept[#kept + 1] = point
		end
	end
	if dropped == 0 then
		return nil
	end
	return kept
end

-- Returns the number of huge definitions changed or removed.
function huge_asteroid_gate.data_final_fixes()
	local mode = difficulty.effective("razi-asteroid-difficulty-scale", "balanced")
	local count = 0
	for name, route in pairs(data.raw["space-connection"] or {}) do
		local definitions = route.asteroid_spawn_definitions
		if type(definitions) == "table" then
			local result, changed = {}, false
			for _, definition in ipairs(definitions) do
				local kept = is_huge(definition) and gated_points(route, definition, mode)
				if kept then
					changed = true
					count = count + 1
					if #kept > 0 then
						-- Spawn tables can be shared between routes: copy, never edit in place.
						local copy = {}
						for key, value in pairs(definition) do
							copy[key] = value
						end
						copy.spawn_points = kept
						result[#result + 1] = copy
					end
					log("razi-protocol: " .. name .. ": " .. definition.asteroid .. " only from route level "
						.. huge_asteroid_gate.minimum_level .. (#kept > 0 and "" or ", removed"))
				else
					result[#result + 1] = definition
				end
			end
			if changed then
				route.asteroid_spawn_definitions = result
			end
		end
	end
	return count
end

return huge_asteroid_gate
