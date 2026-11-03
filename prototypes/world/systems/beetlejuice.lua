PlanetsLib:extend({
    {
        type = "space-location",
        name = "beetlejuice",
        starmap_icon = "__razi-protocol__/graphics/icons/BeetleJuiceStar.png",
        starmap_icon_size = 1024,
        orbit = {
            parent = {
                type = "space-location",
                name = "star",
            },
            distance = 75,
            orientation = 0.72,
        },
        sprite_only = true,
        magnitude = 25,
    },
})

PlanetsLib:extend({
    {
        type = "space-location",
        name = "sye-beetlejuice",
        localised_name = {"space-location-name.sye-beetlejuice"},
        icon = "__space-age__/graphics/icons/solar-system-edge.png",
        solar_power_in_space = 20,
        orbit = {
            parent = {
                type = "space-location",
                name = "beetlejuice",
            },
            distance = 25,
            orientation = 0.3,
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
			orientation = 0.21,
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
		},
	},
	{
		type = "planet",
		name = "tenebris",
		distance = nil,
		orientation = nil,
		orbit = {
			parent = {
				type = "space-location",
				name = "beetlejuice",
			},
			distance = 22,
			orientation = 0.6,
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
		},
	},
	{
		type = "space-location",
		name = "secretas",
		distance = nil,
		orientation = nil,
		orbit = {
			parent = {
				type = "space-location",
				name = "beetlejuice",
			},
			distance = 32,
			orientation = 0.15,
		},
	},
	{
		type = "planet",
		name = "frozeta",
		distance = nil,
		orientation = nil,
		orbit = {
			parent = {
				type = "space-location",
				name = "secretas",
			},
			distance = 4.5,
			orientation = 0.18,
		},
	},
})

PlanetsLib:update({
	type = "space-location",
	name = "solar-system-edge",
    localised_name = {"space-location-name.razi-deep-space-edge"},
	orbit = {
		parent = {
			type = "space-location",
			name = "beetlejuice",
		},
		distance = 50,
		orientation = 0.0,
	},
})

require("util")
local asteroid_util = require("__space-age__.prototypes.planet.asteroid-spawn-definitions")

deleteRoute("vulcanus-cubium")
deleteRoute("gleba-cubium")
deleteRoute("cubium-aquilo")
deleteRoute("cubium-frozeta")
deleteRoute("paracelsin-aquilo")
deleteRoute("paracelsin-frozeta")
deleteRoute("aquilo-solar-system-edge")
deleteRoute("frozeta-solar-system-edge")
deleteRoute("vesta-aquilo")
deleteRoute("vesta-frozeta")
deleteRoute("aquilo-vesta")
deleteRoute("frozeta-vesta")
deleteRoute("nauvis-vesta")
deleteRoute("vulcanus-vesta")
deleteRoute("fulgora-vesta")
deleteRoute("gleba-vesta")
deleteRoute("vesta-solar-system-edge")
deleteRoute("nauvis-crucible")
deleteRoute("crucible-vulcanus")
deleteRoute("crucible-maraxsis")
deleteRoute("sye-vibrant-tenebris")
deleteRoute("tenebris-paracelsin")
deleteRoute("crucible-orbit-cubium")
deleteRoute("sye-beetlejuice-tenebris")
deleteRoute("cubium-vesta")
deleteRoute("sye-beetlejuice-vesta")
deleteRoute("sye-beetlejuice-aquilo")
deleteRoute("sye-beetlejuice-frozeta")
deleteRoute("sye-beetlejuice-secretas")
deleteRoute("vesta-secretas")
deleteRoute("secretas-frozeta")

data:extend({
	{
		type = "space-connection",
		name = "sye-beetlejuice-cubium",
		from = "sye-beetlejuice",
		to = "cubium",
		length = 15000,
		asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.fulgora_aquilo)
	},
	{
		type = "space-connection",
		name = "cubium-secretas",
		from = "cubium",
		to = "secretas",
		length = 15000,
		asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.fulgora_aquilo)
	},
	{
		type = "space-connection",
		name = "secretas-frozeta",
		from = "secretas",
		to = "frozeta",
		length = 7500,
		asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.gleba_aquilo)
	},
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
		name = "tenebris-crucible-orbit",
		from = "tenebris",
		to = "crucible-orbit",
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
		name = "secretas-solar-system-edge",
		from = "secretas",
		to = "solar-system-edge",
		length = 75000,
		asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.aquilo_solar_system_edge)
	},
})
