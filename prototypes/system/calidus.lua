PlanetsLib:extend({
    {
        type = "space-location",
        name = "sye-calidus",
        localised_name = "Calidus Slip Stream",
        icon = "__space-age__/graphics/icons/solar-system-edge.png",
        solar_power_in_space = 25,
        orbit = {
            parent = {
                type = "space-location",
                name = "star",
            },
            distance = 32,
            orientation = 0.5,
            sprite = {
                type = "sprite",
                filename = "__razi-protocol__/graphics/orbits/orbit_32.png",
                size = 2621,
            },
        },
    },
})

require("util")
local asteroid_util = require("__space-age__.prototypes.planet.asteroid-spawn-definitions")

deleteRoute("nauvis-arig")
deleteRoute("vulcanus-arig")
deleteRoute("fulgora-arig")
deleteRoute("fulgora-hyarion")
deleteRoute("gleba-aquilo")
deleteRoute("fulgora-aquilo")
deleteRoute("dea-dia-edge")

data:extend({
	{
		type = "space-connection",
		name = "nauvis-sye-calidus",
		from = "nauvis",
		to = "sye-calidus",
		length = 25000,
		asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.nauvis_fulgora)
	},
})
data:extend({
	{
		type = "space-connection",
		name = "fulgora-sye-calidus",
		from = "fulgora",
		to = "sye-calidus",
		length = 25000,
		asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.nauvis_fulgora)
	},
})
data:extend({
	{
		type = "space-connection",
		name = "sye-calidus-sye-solaris",
		from = "sye-calidus",
		to = "sye-solaris",
		length = 1000,
		asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.nauvis_fulgora)
	},
})
data:extend({
	{
		type = "space-connection",
		name = "sye-calidus-sye-nyxaris",
		from = "sye-calidus",
		to = "sye-nyxaris",
		length = 1000,
		asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.nauvis_fulgora)
	},
})
data:extend({
	{
		type = "space-connection",
		name = "sye-calidus-sye-vibrant",
		from = "sye-calidus",
		to = "sye-vibrant",
		length = 1000,
		asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.nauvis_fulgora)
	},
})
data:extend({
	{
		type = "space-connection",
		name = "sye-calidus-sye-beetlejuice",
		from = "sye-calidus",
		to = "sye-beetlejuice",
		length = 1000,
		asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.nauvis_fulgora)
	},
})
