

PlanetsLib:extend({
    {
        type = "space-location",
        name = "solaris",
        starmap_icon = "__razi-protocol__/graphics/icons/SolarisStar.png",
        starmap_icon_size = 1024,
        orbit = {
            parent = {
                type = "space-location",
                name = "star",
            },
            distance = 70,
            orientation = 0.18,
        },
        sprite_only = true,
        magnitude = 12,
    },
	{
        type = "space-location",
        name = "sye-solaris",
        localised_name = "Solaris Slip Stream",
        icon = "__space-age__/graphics/icons/solar-system-edge.png",
        solar_power_in_space = 25,
        orbit = {
            parent = {
                type = "space-location",
                name = "solaris",
            },
            distance = 20,
            orientation = 0.6,
            sprite = {
                type = "sprite",
                filename = "__razi-protocol__/graphics/orbits/orbit_20.png",
                -- size = 2048,
                size = 1,
            },
        },
    },
})

PlanetsLib:update({
	{
		type = "planet",
		name = "castra",
		orbit = {
			parent = {
				type = "space-location",
				name = "solaris",
			},
			distance = 14,
			orientation = 0.58,
			sprite = {
                type = "sprite",
                filename = "__razi-protocol__/graphics/orbits/orbit_14.png",
                size = 1147,
            },
		},
	},
    {
		type = "planet",
		name = "corrundum",
		orbit = {
			parent = {
				type = "space-location",
				name = "solaris",
			},
			distance = 18,
			orientation = 0.25,
			sprite = {
                type = "sprite",
                filename = "__razi-protocol__/graphics/orbits/orbit_18.png",
                size = 1475,
            },
		},
	},
	{
		type = "planet",
		name = "arig",
		orbit = {
			parent = {
				type = "space-location",
				name = "solaris",
			},
			distance = 11,
			orientation = 0.75,
			sprite = {
                type = "sprite",
                filename = "__razi-protocol__/graphics/orbits/orbit_11.png",
                size = 901,
            },
		},
	},
    {
		type = "planet",
		name = "tellus",
		orbit = {
			parent = {
				type = "space-location",
				name = "solaris",
			},
			distance = 15,
			orientation = 0.08,
			sprite = {
                type = "sprite",
                filename = "__razi-protocol__/graphics/orbits/orbit_15.png",
                size = 1229,
            },
		},
	},
    {
		type = "planet",
		name = "hyarion",
		orbit = {
			parent = {
				type = "space-location",
				name = "solaris",
			},
			distance = 18,
			orientation = 0.42,
			sprite = {
                type = "sprite",
                filename = "__razi-protocol__/graphics/orbits/orbit_18.png",
                size = 1475,
            },
		},
	},
})


-- -----------------------------
-- MOVE DIA DEA TO ITS OWN SPOT
-- -----------------------------

-- Put Dea Dia in its own spot!
PlanetsLib:update({
	{
		type = "space-location",
		name = "star-dea-dia",
		orbit = {
			parent = {
				type = "space-location",
				name = "solaris",
			},
			distance = 50,
			orientation = 0.48,
        -- sprite = {
        --         type = "sprite",
        --         filename = "__razi-protocol__/graphics/orbits/orbit_.png",
        --         size = 2621,
        --     },
		},
	},
})

PlanetsLib:update({
	{
		type = "space-location",
		name = "dea-dia-system-edge",
        localised_name = "Dea Dia Slip Stream",
		orbit = {
			parent = {
				type = "space-location",
				name = "star-dea-dia",
			},
			distance = 10,
			orientation = 0.58,
		},
	},
})

require("util")
local asteroid_util = require("__space-age__.prototypes.planet.asteroid-spawn-definitions")
local castra_asteroids = asteroid_util.vulcanus_castra or asteroid_util.nauvis_fulgora

deleteRoute("vulcanus-castra")
deleteRoute("gleba-castra")

data:extend({
	{
		type = "space-connection",
		name = "sye-solaris-castra",
		from = "sye-solaris",
		to = "castra",
		length = 10000,
		asteroid_spawn_definitions = asteroid_util.spawn_definitions(castra_asteroids)
	},
})
data:extend({
	{
		type = "space-connection",
		name = "castra-arig",
		from = "castra",
		to = "arig",
		length = 12000,
		asteroid_spawn_definitions = asteroid_util.spawn_definitions(castra_asteroids)
	},
})
data:extend({
	{
		type = "space-connection",
		name = "arig-hyarion",
		from = "arig",
		to = "hyarion",
		length = 17500,
		-- asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.nauvis_fulgora)
	},
})
data:extend({
	{
		type = "space-connection",
		name = "hyarion-tellus",
		from = "hyarion",
		to = "tellus",
		length = 20000,
		-- asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.nauvis_fulgora)
	},
})
data:extend({
	{
		type = "space-connection",
		name = "tellus-corrundum",
		from = "tellus",
		to = "corrundum",
		length = 15000,
		-- asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.nauvis_fulgora)
	},
})
data:extend({
	{
		type = "space-connection",
		name = "hyarion-corrundum",
		from = "hyarion",
		to = "corrundum",
		length = 15000,
		-- asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.nauvis_fulgora)
	},
})
data:extend({
	{
		type = "space-connection",
		name = "sye-calidus-dea-dia-system-edge",
		from = "sye-calidus",
		to = "dea-dia-system-edge",
		length = 15000,
		asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.nauvis_fulgora)
	},
})
data:extend({
	{
		type = "space-connection",
		name = "dea-dia-system-edge-lemures",
		from = "dea-dia-system-edge",
		to = "lemures",
		length = 3000,
		asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.nauvis_fulgora)
	},
})
