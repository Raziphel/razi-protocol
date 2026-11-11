---@diagnostic disable: missing-fields, need-check-nil, param-type-mismatch, undefined-field
-- Huge asteroids on a space route only from route level 9 (prototypes/world/asteroids/huge_asteroid_gate.lua),
-- on a mocked data.raw.
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

rawset(_G, "log", function(_) end)

local function points(...)
	local result = {}
	for _, distance in ipairs({...}) do
		result[#result + 1] = {distance = distance, probability = 0.001, speed = 0.018, angle_when_stopped = 0.6}
	end
	return result
end

local shared
local function setup(level)
	local startup = {}
	if level then
		startup["razi-difficulty-preset"] = {value = level}
		startup["razi-asteroid-difficulty-scale"] = {value = "balanced"}
	end
	rawset(_G, "settings", {startup = startup})
	shared = {
		{type = "entity", asteroid = "huge-carbonic-asteroid", spawn_points = points(0.1, 0.5, 0.9)},
		{type = "entity", asteroid = "big-carbonic-asteroid", spawn_points = points(0.1, 0.5, 0.9)},
		{type = "asteroid-chunk", asteroid = "carbonic-asteroid-chunk", spawn_points = points(0.5)},
	}
	rawset(_G, "data", {raw = {
		asteroid = {
			["huge-carbonic-asteroid"] = {name = "huge-carbonic-asteroid"},
			["big-carbonic-asteroid"] = {name = "big-carbonic-asteroid"},
		},
		["space-connection"] = {
			-- levels 7 and 7, 30 000 km: about 7.75 in the middle
			["aquilo-balack"] = {from = "aquilo", to = "bm-balack", length = 30000, asteroid_spawn_definitions = shared},
			-- levels 7 to 10: level 9 is passed on the way
			["aquilo-edge"] = {from = "aquilo", to = "solar-system-edge", length = 30000, asteroid_spawn_definitions = shared},
			["edge-shattered"] = {from = "solar-system-edge", to = "shattered-planet", length = 30000,
				asteroid_spawn_definitions = shared},
		},
	}})
	package.loaded["prototypes.world.asteroids.huge_asteroid_gate"] = nil
	package.loaded["lib.difficulty.presets"] = nil
	package.loaded["lib.difficulty.asteroids"] = nil
	require("lib.difficulty.asteroids").prepare_routes(data.raw["space-connection"])
	return require("prototypes.world.asteroids.huge_asteroid_gate").data_final_fixes()
end

-- The distances of the points still above probability 0; every definition keeps all its points (the game needs two).
local function live(definition)
	local result = {}
	for _, point in ipairs(definition.spawn_points) do
		if point.probability > 0 then
			result[#result + 1] = point.distance
		end
	end
	return result
end

local function find(route, asteroid)
	for _, definition in ipairs(data.raw["space-connection"][route].asteroid_spawn_definitions) do
		if definition.asteroid == asteroid then
			return definition
		end
	end
end

-- Normal: no huge asteroid before level 9, big ones stay
check(setup() == 2, "two routes should change")
check(find("aquilo-balack", "huge-carbonic-asteroid") == nil, "huge asteroids stayed on a level 7 route")
check(#find("aquilo-balack", "big-carbonic-asteroid").spawn_points == 3, "big asteroids were touched")
check(find("aquilo-balack", "carbonic-asteroid-chunk") ~= nil, "chunks were touched")
local partial = find("aquilo-edge", "huge-carbonic-asteroid")
-- 7.57 at 0.1, 9.25 at 0.5, 9.97 at 0.9
check(partial and #partial.spawn_points == 3 and #live(partial) == 2 and live(partial)[1] == 0.5,
	"only the part of a rising route from level 9 keeps huge asteroids")
check(partial.spawn_points[1].probability == 0 and partial.spawn_points[1].speed == 0.018,
	"a point below level 9 should keep its fields at probability 0")
check(#find("edge-shattered", "huge-carbonic-asteroid").spawn_points == 3, "a level 10 route lost huge asteroids")
check(#shared[1].spawn_points == 3 and #shared == 3 and shared[1].spawn_points[1].probability == 0.001,
	"the shared spawn table was edited in place")

-- Nightmare raises the route level (relentless), as for Razi More Asteroids
-- aquilo-balack: 8.77 at the ends, 9.25 in the middle
check(setup("nightmare") == 1, "Nightmare should change only the level 7 route")
local middle = find("aquilo-balack", "huge-carbonic-asteroid")
check(middle and #middle.spawn_points == 3 and #live(middle) == 1 and live(middle)[1] == 0.5,
	"Nightmare should keep huge asteroids in the middle of a level 7 route")

-- No routes or asteroids: nothing fails
rawset(_G, "data", {raw = {}})
package.loaded["prototypes.world.asteroids.huge_asteroid_gate"] = nil
check(require("prototypes.world.asteroids.huge_asteroid_gate").data_final_fixes() == 0, "empty data changed")

print("test_huge_asteroid_gate: ok")
