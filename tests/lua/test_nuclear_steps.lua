---@diagnostic disable: missing-fields, need-check-nil, undefined-field, inject-field
-- Nuclear Steps next to Gleba (prototypes/compatibility/nuclear-steps/asteroid_field.lua) on mocked prototypes: the
-- asteroid field orbits Gleba, the bodies behind it keep the author's layout at three quarters of its size, and
-- nothing moves without the mod or once something else has placed the field.
-- Run from the mod root:
--   lua5.2 tests/lua/test_nuclear_steps.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local function near(a, b)
	return math.abs(a - b) < 1e-6
end

local function polar(distance, turn)
	return distance * math.sin(2 * math.pi * turn), -distance * math.cos(2 * math.pi * turn)
end

local function route(from, to)
	return {type = "space-connection", name = from .. "-to-" .. to, from = from, to = to, length = 5000}
end

-- Nuclear Steps 0.3.4 (prototypes/space-locations/space-locations.lua), or the bodies of a later release.
local function world(installed, bodies, routes)
	local planet = {gleba = {name = "gleba", orbit = {parent = {type = "space-location", name = "nyxaris"},
		distance = 32, orientation = 0.17}}}
	local place = {}
	for name, body in pairs(bodies) do
		local kind = body.kind == "planet" and planet or place
		kind[name] = {name = name, distance = body[1], orientation = body[2]}
	end
	local connections = {}
	for _, pair in ipairs(routes) do
		local r = route(pair[1], pair[2])
		connections[r.name] = r
	end
	rawset(_G, "data", {raw = {planet = planet, ["space-location"] = place, ["space-connection"] = connections}})
	rawset(_G, "mods", installed and {["nuclear-steps"] = "0.3.4"} or {})
	rawset(_G, "log", function() end)
	local calls = {}
	-- PlanetsLib refuses a parent it does not know (lib/planet.lua: update_data_orbit)
	rawset(_G, "PlanetsLib", {update = function(_, list)
		for _, config in ipairs(list) do
			local parent = config.orbit.parent
			assert(data.raw[parent.type][parent.name], "PlanetsLib.update: invalid parent " .. parent.name)
			calls[#calls + 1] = config
		end
	end})
	package.loaded["prototypes.compatibility.nuclear-steps.asteroid_field"] = nil
	return require("prototypes.compatibility.nuclear-steps.asteroid_field"), calls
end

local released = {
	["asteroid-0"] = {60, 0.125, kind = "planet"},
	["asteroid-1"] = {75, 0.13, kind = "planet"},
	["asteroid-2"] = {70, 0.10},
	["mesnard-black-hole"] = {75, 0.165},
	["mesnard-white-hole"] = {85, 0.095},
}
local released_routes = {
	{"gleba", "asteroid-0"}, {"asteroid-0", "mesnard-black-hole"}, {"asteroid-0", "asteroid-1"},
	{"asteroid-1", "mesnard-black-hole"}, {"asteroid-0", "asteroid-2"}, {"asteroid-1", "asteroid-2"},
	{"asteroid-2", "mesnard-white-hole"}, {"gleba", "moshine"},
}

-- with the mod: the field around Gleba first, then the four bodies around the field
local field, calls = world(true, released, released_routes)
field.data_updates()
check(#calls == 5, "the field and four bodies move, got " .. #calls)
check(calls[1].name == "asteroid-0" and calls[1].type == "planet", "the asteroid field moves first")
local orbit = calls[1].orbit
check(orbit.parent.type == "planet" and orbit.parent.name == "gleba", "the asteroid field orbits Gleba")
check(orbit.distance == 30 and orbit.orientation == 0.34, "the asteroid field at 30 units, turn 0.34")

local moved = {}
for i = 2, #calls do
	local config = calls[i]
	check(config.orbit.parent.name == "asteroid-0" and config.orbit.parent.type == "planet",
		config.name .. " orbits the asteroid field")
	check(config.type == (released[config.name].kind or "space-location"), config.name .. " keeps its type")
	moved[config.name] = config.orbit
end
-- the author's offsets from the field, three quarters of them
local fx, fy = polar(60, 0.125)
for name, body in pairs(released) do
	if name ~= "asteroid-0" then
		check(moved[name], name .. " was not moved")
		local bx, by = polar(body[1], body[2])
		local ox, oy = polar(moved[name].distance, moved[name].orientation)
		check(near(ox, (bx - fx) * 0.75) and near(oy, (by - fy) * 0.75), name .. " lost the author's layout")
	end
end
check(not moved.gleba and not moved.moshine, "Gleba and its other neighbours stay")
-- the black hole keeps clear of the field: half its magnitude (10) and more
check(moved["mesnard-black-hole"].distance > 10, "the black hole is too close to the field")

-- a later release with other names: found by the routes, not by name
field, calls = world(true, {
	["asteroid-0"] = {60, 0.125, kind = "planet"},
	["gargante-black-hole"] = {75, 0.165},
	["nuclear-steps-white-hole"] = {75, 0.095},
}, {{"gleba", "asteroid-0"}, {"asteroid-0", "gargante-black-hole"}, {"asteroid-0", "nuclear-steps-white-hole"},
	{"gargante-black-hole", "nuclear-steps-white-hole"}})
field.data_updates()
check(#calls == 3 and calls[2].name == "gargante-black-hole" and calls[3].name == "nuclear-steps-white-hole",
	"renamed bodies move with the field")

-- without the mod nothing moves
field, calls = world(false, released, released_routes)
field.data_updates()
check(#calls == 0, "without Nuclear Steps nothing moves")

-- a field that already orbits something else is left alone
field, calls = world(true, released, released_routes)
data.raw.planet["asteroid-0"].orbit = {parent = {type = "planet", name = "gleba"}, distance = 12, orientation = 0.5}
field.data_updates()
check(#calls == 0, "a field placed by someone else stays")

-- a body that Razi Protocol places itself is not taken along
field, calls = world(true, released, released_routes)
data.raw.planet.vulcanus = {name = "vulcanus", distance = 10, orientation = 0.2}
data.raw["space-connection"]["asteroid-2-to-vulcanus"] = route("asteroid-2", "vulcanus")
field.data_updates()
for _, config in ipairs(calls) do
	check(config.name ~= "vulcanus", "an anchored world was moved with the field")
end
check(#calls == 5, "the anchored neighbour changed the cluster")

-- without Gleba nothing moves
field, calls = world(true, released, released_routes)
data.raw.planet.gleba = nil
field.data_updates()
check(#calls == 0, "without Gleba nothing moves")

print("test_nuclear_steps: ok")
