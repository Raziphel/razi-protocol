PlanetsLib:extend({
    {
        type = "space-location",
        name = "nyxaris",
        starmap_icon = "__razi-protocol__/graphics/icons/NyxarisStar.png",
        starmap_icon_size = 1024,
        orbit = {
            parent = {
                type = "space-location",
                name = "star",
            },
            distance = 75,
            orientation = 0.36,
        },
        sprite_only = true,
        magnitude = 12,
    },
})

if mods["dea-dia-system"] then
	PlanetsLib:update({
		{
			type = "space-location",
			name = "star-dea-dia",
			orbit = {
				parent = {
					type = "space-location",
					name = "nyxaris",
				},
				distance = 32,
				orientation = 0.08,
			},
		},
		{
			type = "space-location",
			name = "dea-dia-system-edge",
			localised_name = {"space-location-name.razi-dea-dia-slip-stream"},
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
end

PlanetsLib:extend({
    {
        type = "space-location",
        name = "sye-nyxaris",
        localised_name = {"space-location-name.sye-nyxaris"},
        icon = "__space-age__/graphics/icons/solar-system-edge.png",
        solar_power_in_space = 25,
        orbit = {
            parent = {
                type = "space-location",
                name = "nyxaris",
            },
            distance = 20,
            orientation = 0.9,
        },
    },
})

local nyxaris_locations = {
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
        },
    },
}

if mods["pelagos"] then
    table.insert(nyxaris_locations, {
        type = "planet",
        name = "pelagos",
        orbit = {
            parent = {
                type = "space-location",
                name = "nyxaris",
            },
            distance = 25,
            orientation = 0.65,
        },
    })
end

PlanetsLib:update(nyxaris_locations)

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
deleteRoute("sye-calidus-dea-dia-system-edge")

local connections = {
	{
		type = "space-connection",
		name = "sye-nyxaris-apia-carnova-orbit",
		from = "sye-nyxaris",
		to = "apia-carnova-orbit",
		length = 15000,
		asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.nauvis_fulgora)
	},
	{
		type = "space-connection",
		name = "sye-nyxaris-moshine",
		from = "sye-nyxaris",
		to = "moshine",
		length = 15000,
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
}

local function location_exists(name)
	return (data.raw.planet and data.raw.planet[name])
		or (data.raw["space-location"] and data.raw["space-location"][name])
end

local function add_connection_if_locations_exist(connection)
	if location_exists(connection.from) and location_exists(connection.to) then
		table.insert(connections, connection)
	end
end

if mods["dea-dia-system"] then
	add_connection_if_locations_exist({
		type = "space-connection",
		name = "sye-nyxaris-dea-dia-system-edge",
		from = "sye-nyxaris",
		to = "dea-dia-system-edge",
		length = 15000,
		asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.nauvis_fulgora)
	})
	add_connection_if_locations_exist({
		type = "space-connection",
		name = "dea-dia-system-edge-lemures",
		from = "dea-dia-system-edge",
		to = "lemures",
		length = 3000,
		asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.nauvis_fulgora)
	})
end

if mods["pelagos"] then
	add_connection_if_locations_exist({
		type = "space-connection",
		name = "panglia-pelagos",
		from = "panglia",
		to = "pelagos",
		length = 15000,
		asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.nauvis_fulgora)
	})
end

data:extend(connections)
