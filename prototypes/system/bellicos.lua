local bellicos = {}

local asteroid_util = require("__space-age__.prototypes.planet.asteroid-spawn-definitions")

local entry_gate = "calidus-bellicos-stargate-calidus"
local bellicos_gate = "calidus-bellicos-stargate-bellicos"
local old_calidus_entry_route = "sye-calidus-bellicos-stargate"
local deep_space_entry_route = "solar-system-edge-aegis-stargate"

local function remove_stock_entry_routes()
	deleteRoute("nauvis-stargate-connection")
	deleteRoute("fulgora-stargate-connection")
	deleteRoute(old_calidus_entry_route)
	deleteRoutesBetween("nauvis", entry_gate)
	deleteRoutesBetween("fulgora", entry_gate)
	deleteRoutesBetween("sye-calidus", entry_gate)
end

function bellicos.data()
	if not mods["bellicos-and-aegis"] then
		return
	end

	-- Bellicos is large enough to overwhelm the normal campaign systems. Anchor
	-- the whole expedition beyond the solar-system edge on the otherwise unused
	-- opposite bearing from the other deep-space branches. The entry gate and
	-- pulsar share a radial line, while the Bellicos gate sits on the pulsar's
	-- inward face so the inter-stargate route never crosses the star image.
	PlanetsLib:update({
		{
			type = "space-location",
			name = "pulsar",
			orbit = {
				parent = {type = "space-location", name = "solar-system-edge"},
				distance = 240,
				orientation = 0.5
			}
		},
		{
			type = "space-location",
			name = entry_gate,
			distance = nil,
			orientation = nil,
			orbit = {
				parent = {type = "space-location", name = "solar-system-edge"},
				distance = 30,
				orientation = 0.5
			},
			redrawn_connections_exclude = true
		},
		{
			type = "space-location",
			name = bellicos_gate,
			orbit = {
				parent = {type = "space-location", name = "pulsar"},
				distance = 58,
				orientation = 0.0
			},
			redrawn_connections_exclude = true
		}
	})

	remove_stock_entry_routes()
	deleteRoute(deep_space_entry_route)

	data:extend({
		{
			type = "space-connection",
			name = deep_space_entry_route,
			from = "solar-system-edge",
			to = entry_gate,
			length = 250000,
			asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.aquilo_solar_system_edge)
		}
	})
end

function bellicos.data_final_fixes()
	if not mods["bellicos-and-aegis"] then
		return
	end

	-- Other route compatibility passes can run after the source mod. Keep only
	-- Razi Protocol's deep-space entrance while preserving every route inside Aegis.
	remove_stock_entry_routes()
end

return bellicos
