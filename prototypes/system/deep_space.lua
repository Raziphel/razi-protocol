PlanetsLib:update({
	{
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
	},
	{
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
	},
	{
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
	},
	{
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
	},
	{
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
	},
	{
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
	},
})

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

data:extend({
	{
		type = "space-connection",
		name = "solar-system-edge-nexus",
		from = "solar-system-edge",
		to = "nexus",
		length = 2000000,
		asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.aquilo_solar_system_edge)
	},
	{
		type = "space-connection",
		name = "solar-system-edge-black-hole-approach",
		from = "solar-system-edge",
		to = "black-hole-approach",
		length = 2000000,
		asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.aquilo_solar_system_edge)
	},
	{
		type = "space-connection",
		name = "black-hole-approach-black-hole",
		from = "black-hole-approach",
		to = "black-hole",
		length = 20000,
		asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.gleba_aquilo)
	},
	{
		type = "space-connection",
		name = "nexus-oort-cloud",
		from = "nexus",
		to = "oort-cloud",
		length = 2000000,
		asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.aquilo_solar_system_edge)
	},
	{
		type = "space-connection",
		name = "oort-cloud-sol",
		from = "oort-cloud",
		to = "sol",
		length = 2000000,
		asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.aquilo_solar_system_edge)
	},
})
