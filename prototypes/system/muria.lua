if not mods["Muria"] then
	return
end

if not (data.raw.planet and data.raw.planet["muria"]) then
	return
end

PlanetsLib:update({
	{
		type = "planet",
		name = "muria",
		orbit = {
			parent = {
				type = "space-location",
				name = "vibrant",
			},
			distance = 20,
			orientation = 0.68,
			sprite = {
				type = "sprite",
				filename = "__razi-protocol__/graphics/orbits/orbit_20.png",
				size = 1638,
			},
		},
	},
})

require("util")
local asteroid_util = require("__space-age__.prototypes.planet.asteroid-spawn-definitions")

deleteRoute("gleba-muria")
deleteRoute("muria-aquilo")
deleteRoute("sye-vibrant-muria")
deleteRoutesBetween("sye-vibrant", "muria")

data:extend({
	{
		type = "space-connection",
		name = "muria-aquilo",
		from = "muria",
		to = "aquilo",
		length = 18000,
		asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.gleba_aquilo)
	},
})
