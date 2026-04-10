PlanetsLib:extend({
    {
        type = "space-location",
        name = "emberon",
        starmap_icon = "__razi-protocol__/graphics/icons/EmberonStar.png",
        starmap_icon_size = 1024,
        orbit = {
            parent = {
                type = "space-location",
                name = "nyxaris",
            },
            distance = 70,
            orientation = 0.77,
        },
        sprite_only = true,
        magnitude = 20,
    },
})

PlanetsLib:extend({
    {
        type = "space-location",
        name = "sye-emberon",
        localised_name = "Emberon Slip Stream",
        icon = "__space-age__/graphics/icons/solar-system-edge.png",
        solar_power_in_space = 25,
        orbit = {
            parent = {
                type = "space-location",
                name = "emberon",
            },
            distance = 25,
            orientation = 0.18,
            sprite = {
                type = "sprite",
                filename = "__razi-protocol__/graphics/orbits/orbit_25.png",
                size = 2048,
            },
        },
    },
})

PlanetsLib:update({
	type = "planet",
	name = "aquilo",
	orbit = {
		parent = {
			type = "space-location",
			name = "emberon",
		},
		distance = 25,
		orientation = 0.85,
		sprite = {
			type = "sprite",
			filename = "__razi-protocol__/graphics/orbits/orbit_25.png",
			size = 2048,
		},
	},
})



require("util")
local asteroid_util = require("__space-age__.prototypes.planet.asteroid-spawn-definitions")

deleteRoute("aquilo-solar-system-edge")
