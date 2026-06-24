if not mods["moon-eneas"] then
	return
end

if not (data.raw.planet and data.raw.planet["eneas"]) then
	return
end

PlanetsLib:update({
	{
		type = "planet",
		name = "eneas",
		distance = nil,
		orientation = nil,
		orbit = {
			parent = {
				type = "planet",
				name = "nauvis",
			},
			distance = 7,
			orientation = 0.82,
			sprite = {
				type = "sprite",
				filename = "__razi-protocol__/graphics/orbits/orbit_7.png",
				size = 573,
			},
		},
	},
})

require("util")
local asteroid_util = require("__space-age__.prototypes.planet.asteroid-spawn-definitions")

deleteRoutesBetween("nauvis", "eneas")

data:extend({
	{
		type = "space-connection",
		name = "nauvis-eneas",
		from = "nauvis",
		to = "eneas",
		length = 8000,
		asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.nauvis_fulgora)
	},
})
