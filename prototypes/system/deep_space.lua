local function planet_exists(name)
	return data.raw.planet and data.raw.planet[name]
end

local function space_location_exists(name)
	return data.raw["space-location"] and data.raw["space-location"][name]
end

local function route_endpoint_exists(name)
	return planet_exists(name) or space_location_exists(name)
end

local deep_space_updates = {}

if space_location_exists("shattered-planet") and space_location_exists("solar-system-edge") then
	table.insert(deep_space_updates, {
		type = "space-location",
		name = "shattered-planet",
		distance = nil,
		orientation = nil,
		orbit = {
			parent = {
				type = "space-location",
				name = "solar-system-edge",
			},
			distance = 75,
			orientation = 0.0,
		},
	})
end

if planet_exists("nexus") and space_location_exists("solar-system-edge") then
	table.insert(deep_space_updates, {
		type = "planet",
		name = "nexus",
		distance = nil,
		orientation = nil,
		orbit = {
			parent = {
				type = "space-location",
				name = "solar-system-edge",
			},
			distance = 50,
			orientation = 0.12,
			sprite = {
				type = "sprite",
				filename = "__razi-protocol__/graphics/orbits/orbit_0.png",
				size = 369,
			},
		},
	})
end

if space_location_exists("black-hole-approach") and space_location_exists("solar-system-edge") then
	table.insert(deep_space_updates, {
		type = "space-location",
		name = "black-hole-approach",
		distance = nil,
		orientation = nil,
		orbit = {
			parent = {
				type = "space-location",
				name = "solar-system-edge",
			},
			distance = 50,
			orientation = 0.9,
			sprite = {
				type = "sprite",
				filename = "__razi-protocol__/graphics/orbits/orbit_0.png",
				size = 369,
			},
		},
	})
end

if space_location_exists("black-hole") and space_location_exists("black-hole-approach") then
	table.insert(deep_space_updates, {
		type = "space-location",
		name = "black-hole",
		distance = nil,
		orientation = nil,
		orbit = {
			parent = {
				type = "space-location",
				name = "black-hole-approach",
			},
			distance = 4.5,
			orientation = 0.75,
			sprite = {
				type = "sprite",
				filename = "__razi-protocol__/graphics/orbits/orbit_4.5.png",
				size = 369,
			},
		},
	})
end

if space_location_exists("oort-cloud") and planet_exists("nexus") then
	table.insert(deep_space_updates, {
		type = "space-location",
		name = "oort-cloud",
		distance = nil,
		orientation = nil,
		orbit = {
			parent = {
				type = "planet",
				name = "nexus",
			},
			distance = 22,
			orientation = 0.28,
			sprite = {
				type = "sprite",
				filename = "__razi-protocol__/graphics/orbits/orbit_0.png",
				size = 369,
			},
		},
	})
end

if space_location_exists("sol") and space_location_exists("oort-cloud") then
	table.insert(deep_space_updates, {
		type = "space-location",
		name = "sol",
		distance = nil,
		orientation = nil,
		orbit = {
			parent = {
				type = "space-location",
				name = "oort-cloud",
			},
			distance = 25,
			orientation = 0.18,
			sprite = {
				type = "sprite",
				filename = "__razi-protocol__/graphics/orbits/orbit_0.png",
				size = 369,
			},
		},
	})
end

if #deep_space_updates > 0 then
	PlanetsLib:update(deep_space_updates)
end

require("util")
local asteroid_util = require("__space-age__.prototypes.planet.asteroid-spawn-definitions")

deleteRoute("fulgora-nexus")
deleteRoute("solar-system-edge-approach")
deleteRoute("approach-black-hole")
deleteRoute("approach-shattered-planet")
deleteRoute("solar-system-edge-nexus")
deleteRoute("nexus-oort-cloud")
deleteRoute("oort-cloud-sol")
deleteRoute("solar-system-edge-oort-cloud")

local deep_space_connections = {}

local function add_connection_if_locations_exist(connection)
	if route_endpoint_exists(connection.from) and route_endpoint_exists(connection.to) then
		table.insert(deep_space_connections, connection)
	end
end

add_connection_if_locations_exist({
	type = "space-connection",
	name = "solar-system-edge-nexus",
	from = "solar-system-edge",
	to = "nexus",
	length = 2000000,
	asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.aquilo_solar_system_edge)
})

add_connection_if_locations_exist({
	type = "space-connection",
	name = "solar-system-edge-black-hole-approach",
	from = "solar-system-edge",
	to = "black-hole-approach",
	length = 2000000,
	asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.aquilo_solar_system_edge)
})

add_connection_if_locations_exist({
	type = "space-connection",
	name = "black-hole-approach-black-hole",
	from = "black-hole-approach",
	to = "black-hole",
	length = 20000,
	asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.gleba_aquilo)
})

add_connection_if_locations_exist({
	type = "space-connection",
	name = "nexus-oort-cloud",
	from = "nexus",
	to = "oort-cloud",
	length = 2000000,
	asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.aquilo_solar_system_edge)
})

add_connection_if_locations_exist({
	type = "space-connection",
	name = "oort-cloud-sol",
	from = "oort-cloud",
	to = "sol",
	length = 2000000,
	asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.aquilo_solar_system_edge)
})

if #deep_space_connections > 0 then
	data:extend(deep_space_connections)
end
