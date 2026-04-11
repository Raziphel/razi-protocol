PlanetsLib:extend({
    {
        type = "space-location",
        name = "vibrant",
        starmap_icon = "__razi-protocol__/graphics/icons/VibrantStar.png",
        starmap_icon_size = 1024,
        orbit = {
            parent = {
                type = "space-location",
                name = "nyxaris",
            },
            distance = 90,
            orientation = 0.75,
        },
        sprite_only = true,
        magnitude = 20,
    },
})

PlanetsLib:extend({
    {
        type = "space-location",
        name = "sye-vibrant",
        localised_name = "Vibrant Slip Stream",
        icon = "__space-age__/graphics/icons/solar-system-edge.png",
        solar_power_in_space = 25,
        orbit = {
            parent = {
                type = "space-location",
                name = "vibrant",
            },
            distance = 37,
            orientation = 0.18,
            sprite = {
                type = "sprite",
                filename = "__razi-protocol__/graphics/orbits/orbit_37.png",
                size = 3031,
            },
        },
    },
})

PlanetsLib:update({
	{
		type = "planet",
		name = "tenebris",
		orbit = {
			parent = {
				type = "space-location",
				name = "vibrant",
			},
			distance = 22,
			orientation = 0.08,
			sprite = {
				type = "sprite",
				filename = "__razi-protocol__/graphics/orbits/orbit_22.png",
				size = 1802,
			},
		},
	},
	{
		type = "planet",
		name = "paracelsin",
		orbit = {
			parent = {
				type = "space-location",
				name = "vibrant",
			},
			distance = 32,
			orientation = 0.86,
			sprite = {
				type = "sprite",
				filename = "__razi-protocol__/graphics/orbits/orbit_32.png",
				size = 2621,
			},
		},
	},
	{
		type = "space-location",
		name = "secretas",
		orbit = {
			parent = {
				type = "space-location",
				name = "vibrant",
			},
			distance = 35,
			orientation = 0.32,
			sprite = {
				type = "sprite",
				filename = "__razi-protocol__/graphics/orbits/orbit_35.png",
				size = 2867,
			},
		},
	},
	{
		type = "planet",
		name = "frozeta",
		orbit = {
			parent = {
				type = "space-location",
				name = "secretas",
			},
			distance = 7,
			orientation = 0.18,
			sprite = {
				type = "sprite",
				filename = "__razi-protocol__/graphics/orbits/orbit_7.png",
				size = 573,
			},
		},
	},
	{
		type = "planet",
		name = "rubia",
		orbit = {
			parent = {
				type = "space-location",
				name = "vibrant",
			},
			distance = 19,
			orientation = 0.4,
			sprite = {
				type = "sprite",
				filename = "__razi-protocol__/graphics/orbits/orbit_19.png",
				size = 1556,
			},
		},
	},
	{
		type = "planet",
		name = "maraxsis",
		distance = nil,
		orientation = nil,
		orbit = {
			parent = {
				type = "space-location",
				name = "vibrant",
			},
			distance = 23,
			orientation = 0.70,
			sprite = {
				type = "sprite",
				filename = "__razi-protocol__/graphics/orbits/orbit_23.png",
				size = 1884,
			},
		},
	},
})



require("util")
local asteroid_util = require("__space-age__.prototypes.planet.asteroid-spawn-definitions")

deleteRoute("aquilo-solar-system-edge")
deleteRoute("fulgora-tenebris")
deleteRoute("tenebris-solar-system-edge")
deleteRoute("fulgora-paracelsin")
deleteRoute("paracelsin-aquilo")
deleteRoute("paracelsin-solar-system-edge")
deleteRoute("aquilo-secretas")
deleteRoute("secretas-edge")
deleteRoute("aquilo-frozeta")
deleteRoute("frozeta-edge")
deleteRoute("secretas-frozeta")
deleteRoute("vulcanus-maraxsis")
deleteRoute("fulgora-maraxsis")
deleteRoute("maraxsis-tenebris")
deleteRoute("maraxsis-tellus")
deleteRoute("maraxsis-hyarion")
deleteRoute("sye-vibrant-maraxsis")
deleteRoute("vulcanus-rubia")
deleteRoute("gleba-rubia")
deleteRoute("corrundum-rubia")

data:extend({
	{
		type = "space-connection",
		name = "sye-vibrant-tenebris",
		from = "sye-vibrant",
		to = "tenebris",
		length = 20000,
		asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.nauvis_fulgora)
	},
	{
		type = "space-connection",
		name = "sye-vibrant-secretas",
		from = "sye-vibrant",
		to = "secretas",
		length = 40000,
		asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.nauvis_fulgora)
	},
	{
		type = "space-connection",
		name = "secretas-rubia",
		from = "secretas",
		to = "rubia",
		length = 25000,
		asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.nauvis_fulgora)
	},
	{
		type = "space-connection",
		name = "rubia-maraxsis",
		from = "rubia",
		to = "maraxsis",
		length = 30000,
		asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.nauvis_fulgora)
	},
	{
		type = "space-connection",
		name = "secretas-frozeta",
		from = "secretas",
		to = "frozeta",
		length = 7500,
		asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.nauvis_fulgora)
	},
    {
		type = "space-connection",
		name = "tenebris-paracelsin",
		from = "tenebris",
		to = "paracelsin",
		length = 40000,
		asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.nauvis_fulgora)
	},
})
