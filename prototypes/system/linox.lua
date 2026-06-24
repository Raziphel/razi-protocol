if not mods["linox"] then
	return
end

if not (data.raw.planet and data.raw.planet["linox-planet_linox"]) then
	return
end

PlanetsLib:update({
	{
		type = "planet",
		name = "linox-planet_linox",
		orbit = {
			parent = {
				type = "space-location",
				name = "beetlejuice",
			},
			distance = 19,
				orientation = 0.78,
			sprite = {
				type = "sprite",
				filename = "__razi-protocol__/graphics/orbits/orbit_19.png",
				size = 1556,
			},
		},
	},
})

require("util")
local asteroid_util = require("__space-age__.prototypes.planet.asteroid-spawn-definitions")

deleteRoute("linox-space-connection_vulcanus-linox")
deleteRoutesBetween("vulcanus", "linox-planet_linox")
deleteRoute("sye-solaris-linox")
deleteRoutesBetween("sye-solaris", "linox-planet_linox")
deleteRoutesBetween("hyarion", "linox-planet_linox")
deleteRoutesBetween("cubium", "linox-planet_linox")
deleteRoutesBetween("sye-beetlejuice", "linox-planet_linox")
deleteRoutesBetween("linox-planet_linox", "ribbonia")
deleteRoutesBetween("linox-planet_linox", "rubia")

data:extend({
	{
		type = "space-connection",
		name = "cubium-linox",
		from = "cubium",
		to = "linox-planet_linox",
		length = 16000,
		asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.nauvis_fulgora)
	},
})
