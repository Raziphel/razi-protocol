-- Huge asteroids only where railguns are within reach. Only railguns stop a huge asteroid, and the railgun research
-- needs the science of level 8 and 9 worlds (Ferrum, Crucible). Razi More Asteroids already adds its huge asteroids
-- only from route level 9; the routes of other mods and Razi's own profiles put them earlier: Khemia - Ribbonia,
-- Aquilo - Balack and Beetlejuice - Umbra reach about 6 to 8. A huge spawn point on a space route gets probability 0
-- where the route level at that point (lib/difficulty/asteroids.lua, with the asteroid difficulty scale, as More
-- Asteroids uses it) is below 9. No point is dropped: the game needs at least two. A definition with no point above 0
-- is removed. Between a zeroed point and a kept one the game blends the two, so huge asteroids fade in just before
-- level 9. Medium and big asteroids are not touched on routes.
--
-- Orbits: Razi More Asteroids (prototypes/compat/space_age_spawns.lua) gives the orbits of Nauvis, Vulcanus, Gleba,
-- Fulgora and Aquilo every size of its families, with the far end of its own route profiles, so big and huge
-- asteroids circle Vulcanus and Gleba (level 2). Its big and huge asteroids are removed from an orbit below the levels
-- its routes use (big 6, huge 9), with the same difficulty scale. Orbits of other mods keep what their authors gave
-- them.
local levels = require("lib.difficulty.asteroids")
local difficulty = require("lib.difficulty.presets")

local huge_asteroid_gate = {}

huge_asteroid_gate.minimum_level = 9
-- The route levels from which Razi More Asteroids adds its big and huge asteroids (more_asteroids_integration.lua).
huge_asteroid_gate.orbit_levels = {big = 6, huge = 9}

-- The size of a Razi More Asteroids asteroid ("big", "huge"), or nil.
local more_asteroids_size = {}
for _, family in ipairs({"uranium", "rock", "scrap", "organic", "chemical", "crystalline", "halide", "electrostatic"}) do
	for size in pairs(huge_asteroid_gate.orbit_levels) do
		more_asteroids_size[size .. "-" .. family .. "-asteroid"] = size
	end
end

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

-- The level of a planet or space location, raised by the difficulty scale as a route that starts and ends there.
local function orbit_level(name, mode)
	return levels.route_level({from = name, to = name}, 0, mode)
end

-- Removes the big and huge Razi More Asteroids asteroids from orbits below their levels. Returns the number removed.
local function gate_orbits(mode)
	local count = 0
	for _, kind in ipairs({"planet", "space-location"}) do
		for name, location in pairs(data.raw[kind] or {}) do
			local definitions = location.asteroid_spawn_definitions
			if type(definitions) == "table" then
				local result, changed = {}, false
				for _, definition in ipairs(definitions) do
					local size = type(definition) == "table" and (definition.type == nil or definition.type == "entity")
						and more_asteroids_size[definition.asteroid]
					local minimum = size and huge_asteroid_gate.orbit_levels[size]
					if minimum and orbit_level(name, mode) < minimum then
						changed = true
						count = count + 1
						log("razi-protocol: " .. name .. ": " .. definition.asteroid .. " removed, only from level "
							.. minimum)
					else
						result[#result + 1] = definition
					end
				end
				if changed then
					-- A new table: spawn tables can be shared between locations.
					location.asteroid_spawn_definitions = result
				end
			end
		end
	end
	return count
end

-- Returns the number of definitions changed or removed on routes and orbits.
function huge_asteroid_gate.data_final_fixes()
	local mode = difficulty.effective("razi-asteroid-difficulty-scale", "balanced")
	local count = gate_orbits(mode)
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
