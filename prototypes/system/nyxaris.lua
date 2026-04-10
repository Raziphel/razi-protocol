PlanetsLib:extend({
    {
        type = "space-location",
        name = "nyxaris",
        starmap_icon = "__razi-protocol__/graphics/icons/NyxarisStar.png",
        starmap_icon_size = 1024,
        orbit = {
            parent = {
                type = "space-location",
                name = "star-dea-dia",
            },
            distance = 70,
            orientation = 0.63,
        },
        sprite_only = true,
        magnitude = 12,
    },
})

PlanetsLib:extend({
    {
        type = "space-location",
        name = "sye-nyxaris",
        localised_name = "Nyxaris Slip Stream",
        icon = "__space-age__/graphics/icons/solar-system-edge.png",
        solar_power_in_space = 25,
        orbit = {
            parent = {
                type = "space-location",
                name = "nyxaris",
            },
            distance = 20,
            orientation = 0.9,
            sprite = {
                type = "sprite",
                filename = "__razi-protocol__/graphics/orbits/orbit_20.png",
                size = 1638,
            },
        },
    },
})

PlanetsLib:update({
    {
        type = "space-location",
        name = "apia-carnova-orbit",
        orbit = {
            parent = {
                type = "space-location",
                name = "nyxaris",
            },
            distance = 14,
            orientation = 0.09,
            sprite = {
                type = "sprite",
                filename = "__razi-protocol__/graphics/orbits/orbit_14.png",
                size = 1147,
            },
        },
    },
    {
        type = "planet",
        name = "moshine",
        orbit = {
            parent = {
                type = "space-location",
                name = "nyxaris",
            },
            distance = 6,
            orientation = 0.91,
            sprite = {
                type = "sprite",
                filename = "__razi-protocol__/graphics/orbits/orbit_6.png",
                size = 492,
            },
        },
    },
    {
        type = "planet",
        name = "panglia",
        orbit = {
            parent = {
                type = "space-location",
                name = "nyxaris",
            },
            distance = 18,
            orientation = 0.72,
            sprite = {
                type = "sprite",
                filename = "__razi-protocol__/graphics/orbits/orbit_18.png",
                size = 1475,
            },
        },
    },
    {
        type = "planet",
        name = "pelagos",
        orbit = {
            parent = {
                type = "space-location",
                name = "nyxaris",
            },
            distance = 25,
            orientation = 0.65,
            sprite = {
                type = "sprite",
                filename = "__razi-protocol__/graphics/orbits/orbit_25.png",
                size = 2048,
            },
        },
    },
})

require("util")
local asteroid_util = require("__space-age__.prototypes.planet.asteroid-spawn-definitions")

deleteRoute("gleba-corrundum")
deleteRoute("nauvis-corrundum")
deleteRoute("vulcanus-corrundum")
deleteRoute("aquilo-corrundum")
deleteRoute("dea-dia-edge")
deleteRoute("gleba-apia-carnova-orbit")
deleteRoute("apia-carnova-orbit-aquilo")
deleteRoute("pelagos-apia-carnova-orbit")
deleteRoute("nauvis-moshine")
deleteRoute("vulcanus-moshine")
deleteRoute("gleba-panglia")
deleteRoute("star-pelagos")
deleteRoute("pelagos-corrundum")
deleteRoute("maraxsis-pelagos")
deleteRoute("pelagos-aquilo")

data:extend({
	{
		type = "space-connection",
		name = "sye-nyxaris-apia-carnova-orbit",
		from = "sye-nyxaris",
		to = "apia-carnova-orbit",
		length = 25000,
		asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.nauvis_fulgora)
	},
	{
		type = "space-connection",
		name = "sye-nyxaris-moshine",
		from = "sye-nyxaris",
		to = "moshine",
		length = 25000,
		asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.nauvis_fulgora)
	},
	{
		type = "space-connection",
		name = "sye-nyxaris-panglia",
		from = "sye-nyxaris",
		to = "panglia",
		length = 25000,
		asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.nauvis_fulgora)
	},
	{
		type = "space-connection",
		name = "panglia-pelagos",
		from = "panglia",
		to = "pelagos",
		length = 25000,
		asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.nauvis_fulgora)
	},
})
