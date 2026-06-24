if not mods["shchierbin"] then
	return
end

if not (data.raw.planet and data.raw.planet["shchierbin"]) then
	return
end

PlanetsLib:update({
	{
		type = "planet",
		name = "shchierbin",
		orbit = {
			parent = {
				type = "space-location",
				name = "vibrant",
			},
			distance = 17,
			orientation = 0.82,
			sprite = {
				type = "sprite",
				filename = "__razi-protocol__/graphics/orbits/orbit_17.png",
				size = 1393,
			},
		},
	},
})

require("util")
local asteroid_util = require("__space-age__.prototypes.planet.asteroid-spawn-definitions")

deleteRoute("fulgora-shchierbin")
deleteRoute("gleba-shchierbin")
deleteRoute("sye-vibrant-shchierbin")
deleteRoutesBetween("sye-vibrant", "shchierbin")
deleteRoutesBetween("paracelsin", "shchierbin")

data:extend({
	{
		type = "space-connection",
		name = "paracelsin-shchierbin",
		from = "paracelsin",
		to = "shchierbin",
		length = 22000,
		asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.fulgora_shchierbin or asteroid_util.fulgora_aquilo)
	},
})
