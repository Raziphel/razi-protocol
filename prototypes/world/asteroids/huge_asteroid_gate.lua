-- Huge asteroids only where railguns are within reach. Only railguns stop a huge asteroid, and the railgun research
-- needs the science of level 8 and 9 worlds (Ferrum, Crucible). Razi More Asteroids already adds its huge asteroids
-- only from route level 9; the routes of other mods and Razi's own profiles put them earlier: Khemia - Ribbonia,
-- Aquilo - Balack and Beetlejuice - Umbra reach about 6 to 8. A huge spawn point on a space route gets probability 0
-- where the route level at that point (lib/difficulty/asteroids.lua, with the asteroid difficulty scale, as More
-- Asteroids uses it) is below 9. No point is dropped: the game needs at least two. A definition with no point above 0
-- is removed. Between a zeroed point and a kept one the game blends the two, so huge asteroids fade in just before
-- level 9. Medium and big asteroids are not touched, nor orbits.
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

-- The spawn points with the ones below the minimum level at probability 0, and the number of points left above 0;
-- nil when no point is below the minimum level.
local function gated_points(route, definition, mode)
	local points, dropped, live = {}, 0, 0
	for _, point in ipairs(definition.spawn_points or {}) do
		local distance = type(point) == "table" and (point.distance or point[1])
		if type(distance) == "number"
			and levels.route_level(route, distance, mode) < huge_asteroid_gate.minimum_level then
			dropped = dropped + 1
			local zero = {}
			for key, value in pairs(point) do
				zero[key] = value
			end
			zero.probability = 0
			points[#points + 1] = zero
		else
			points[#points + 1] = point
			live = live + 1
		end
	end
	if dropped == 0 then
		return nil
	end
	return points, live
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
				local kept, live
				if is_huge(definition) then
					kept, live = gated_points(route, definition, mode)
				end
				if kept then
					changed = true
					count = count + 1
					if live > 0 then
						-- Spawn tables can be shared between routes: copy, never edit in place.
						local copy = {}
						for key, value in pairs(definition) do
							copy[key] = value
						end
						copy.spawn_points = kept
						result[#result + 1] = copy
					end
					log("razi-protocol: " .. name .. ": " .. definition.asteroid .. " only from route level "
						.. huge_asteroid_gate.minimum_level .. (live > 0 and "" or ", removed"))
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
