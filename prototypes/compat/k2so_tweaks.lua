local compat = {}

local xy_k2so_placeholder_connections = { -- Cuz fuckin hell xy loves to complain.
	{
		name = "nauvis-moshine",
		from = "nauvis",
		to = "moshine",
		length = 25000
	},
	{
		name = "vulcanus-moshine",
		from = "vulcanus",
		to = "moshine",
		length = 10000
	}
}

local function patch_xy_k2so_globals()
	if mods["xy-k2so-enhancements"] and not sounds then
		sounds = require("__base__.prototypes.entity.sounds")
	end
end

local function route_exists(name)
	return data.raw["space-connection"] and data.raw["space-connection"][name]
end

local function location_exists(name)
	return
		(data.raw.planet and data.raw.planet[name]) or
		(data.raw["space-location"] and data.raw["space-location"][name])
end

local function add_xy_k2so_placeholder_connections()
	if not mods["xy-k2so-enhancements"] then
		return
	end

	local asteroid_util = require("__space-age__.prototypes.planet.asteroid-spawn-definitions")

	for _, connection in pairs(xy_k2so_placeholder_connections) do
		if not route_exists(connection.name) and location_exists(connection.from) and location_exists(connection.to) then
			data:extend({
				{
					type = "space-connection",
					name = connection.name,
					subgroup = "planet-connections",
					from = connection.from,
					to = connection.to,
					length = connection.length,
					asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.nauvis_fulgora)
				}
			})
		end
	end
end

local function remove_xy_k2so_placeholder_connections()
	if not data.raw["space-connection"] then
		return
	end

	for _, connection in pairs(xy_k2so_placeholder_connections) do
		data.raw["space-connection"][connection.name] = nil
	end

	data.raw["space-connection"]["moshine-maraxsis"] = nil
end

function compat.data()
	patch_xy_k2so_globals()
	add_xy_k2so_placeholder_connections()
end

function compat.data_updates()
	patch_xy_k2so_globals()
	remove_xy_k2so_placeholder_connections()
end

return compat
