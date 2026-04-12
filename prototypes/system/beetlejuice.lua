PlanetsLib:extend({
    {
        type = "space-location",
        name = "beetlejuice",
        starmap_icon = "__razi-protocol__/graphics/icons/BeetleJuiceStar.png",
        starmap_icon_size = 1024,
        orbit = {
            parent = {
                type = "space-location",
                name = "vibrant",
            },
            distance = 75,
            orientation = 0.85,
        },
        sprite_only = true,
        magnitude = 25,
    },
})

PlanetsLib:extend({
    {
        type = "space-location",
        name = "sye-beetlejuice",
        localised_name = "Beetlejuice Slip Stream",
        icon = "__space-age__/graphics/icons/solar-system-edge.png",
        solar_power_in_space = 20,
        orbit = {
            parent = {
                type = "space-location",
                name = "beetlejuice",
            },
            distance = 25,
            orientation = 0.25,
            sprite = {
                type = "sprite",
                filename = "__razi-protocol__/graphics/orbits/orbit_25.png",
                size = 2048,
            },
        },
    }
})

PlanetsLib:update({
	{
		type = "planet",
		name = "cubium",
		distance = nil,
		orientation = nil,
		orbit = {
			parent = {
				type = "space-location",
				name = "beetlejuice",
			},
			distance = 21,
			orientation = 0.6,
			sprite = {
				type = "sprite",
				filename = "__razi-protocol__/graphics/orbits/orbit_21.png",
				size = 1720,
			},
		},
	},
	{
		type = "space-location",
		name = "crucible-orbit",
		distance = nil,
		orientation = nil,
		orbit = {
			parent = {
				type = "space-location",
				name = "beetlejuice",
			},
			distance = 23,
			orientation = 0.5,
			sprite = {
				type = "sprite",
				filename = "__razi-protocol__/graphics/orbits/orbit_23.png",
				size = 1884,
			},
		},
	},
	{
		type = "planet",
		name = "crucible",
		distance = nil,
		orientation = nil,
		orbit = {
			parent = {
				type = "space-location",
				name = "crucible-orbit",
			},
			distance = 1,
			orientation = 0.5,
			sprite = {
				type = "sprite",
				filename = "__razi-protocol__/graphics/orbits/orbit_0.png",
				size = 369,
			},
		},
	},
	{
		type = "planet",
		name = "aquilo",
		distance = nil,
		orientation = nil,
		orbit = {
			parent = {
				type = "space-location",
				name = "beetlejuice",
			},
			distance = 32,
			orientation = 0.15,
			sprite = {
				type = "sprite",
				filename = "__razi-protocol__/graphics/orbits/orbit_32.png",
				size = 2621,
			},
		},
	},
	{
		type = "planet",
		name = "vesta",
		distance = nil,
		orientation = nil,
		orbit = {
			parent = {
				type = "space-location",
				name = "beetlejuice",
			},
			distance = 25,
			orientation = 0.4,
			sprite = {
				type = "sprite",
				filename = "__razi-protocol__/graphics/orbits/orbit_25.png",
				size = 2048,
			},
		},
	},
})

PlanetsLib:update({
	type = "space-location",
	name = "solar-system-edge",
    localised_name = "Edge of Deep Space",
	orbit = {
		parent = {
			type = "space-location",
			name = "beetlejuice",
		},
		distance = 50,
		orientation = 0.0,
        sprite = {
			type = "sprite",
			filename = "__razi-protocol__/graphics/orbits/orbit_0.png",
            size = 369,
		},
	},
})

require("util")
local asteroid_util = require("__space-age__.prototypes.planet.asteroid-spawn-definitions")

deleteRoute("vulcanus-cubium")
deleteRoute("gleba-cubium")
deleteRoute("cubium-aquilo")
deleteRoute("paracelsin-aquilo")
deleteRoute("aquilo-solar-system-edge")
deleteRoute("vesta-aquilo")
deleteRoute("aquilo-vesta")
deleteRoute("nauvis-vesta")
deleteRoute("vulcanus-vesta")
deleteRoute("fulgora-vesta")
deleteRoute("gleba-vesta")
deleteRoute("vesta-solar-system-edge")
deleteRoute("nauvis-crucible")
deleteRoute("crucible-vulcanus")
deleteRoute("crucible-maraxsis")

data:extend({
	{
		type = "space-connection",
		name = "sye-beetlejuice-vesta",
		from = "sye-beetlejuice",
		to = "vesta",
		length = 15000,
		asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.fulgora_aquilo)
	},
	{
		type = "space-connection",
		name = "crucible-orbit-cubium",
		from = "crucible-orbit",
		to = "cubium",
		length = 15000,
		asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.fulgora_aquilo)
	},
	{
		type = "space-connection",
		name = "crucible-orbit-vesta",
		from = "crucible-orbit",
		to = "vesta",
		length = 15000,
		asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.gleba_aquilo)
	},
	{
		type = "space-connection",
		name = "sye-beetlejuice-aquilo",
		from = "sye-beetlejuice",
		to = "aquilo",
		length = 15000,
		asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.gleba_aquilo)
	},
	{
		type = "space-connection",
		name = "aquilo-solar-system-edge",
		from = "aquilo",
		to = "solar-system-edge",
		length = 75000,
		asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.aquilo_solar_system_edge)
	},
})
