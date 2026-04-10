PlanetsLib:extend({
    {
        type = "space-location",
        name = "beetlejuice",
        starmap_icon = "__razi-protocol__/graphics/icons/BeetleJuiceStar.png",
        starmap_icon_size = 1024,
        orbit = {
            parent = {
                type = "space-location",
                name = "emberon",
            },
            distance = 120,
            orientation = 0.0,
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
        solar_power_in_space = 25,
        orbit = {
            parent = {
                type = "space-location",
                name = "beetlejuice",
            },
            distance = 32,
            orientation = 0.4,
            sprite = {
                type = "sprite",
                filename = "__razi-protocol__/graphics/orbits/orbit_25.png",
                size = 2048,
            },
        },
    }
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
			filename = "__razi-protocol__/graphics/orbits/orbit_50.png",
			-- size = 4096,
            size = 1,
		},
	},
})

PlanetsLib:update({
	type = "space-location",
	name = "shattered-planet",
	orbit = {
		parent = {
			type = "space-location",
			name = "solar-system-edge",
		},
		distance = 80,
		orientation = 0.15,
	},
})
