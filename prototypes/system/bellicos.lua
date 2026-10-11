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

-- Keep the source pulsar's giant artwork and its local Aegis routes in
-- a compact annex to the RIGHT of Deep Space, not 240 units BELOW it.
-- Orientations use Factorio turns: east .25, west .75.
local function position_expedition()
	PlanetsLib:update({
		{
			type = "space-location", name = "pulsar",
			orbit = {
				parent = {type = "space-location", name = "solar-system-edge"},
				distance = 165, orientation = 0.25
			},
			draw_orbit = false
		},
		{
			type = "space-location", name = entry_gate,
			distance = nil, orientation = nil,
			orbit = {
				parent = {type = "space-location", name = "solar-system-edge"},
				distance = 36, orientation = 0.25
			},
			draw_orbit = false,
			redrawn_connections_exclude = true
		},
		{
			type = "space-location", name = bellicos_gate,
			orbit = {
				parent = {type = "space-location", name = "pulsar"},
				distance = 62, orientation = 0.75
			},
			draw_orbit = false,
			redrawn_connections_exclude = true
		}
	})
end

function bellicos.data()
	if not mods["bellicos-and-aegis"] then
		return
	end

	position_expedition()
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
	-- Source data-final-fixes may reparent its giant pulsar after data.lua.
	-- Reaffirm only the three Razi-managed anchors at the final stage.
	position_expedition()
end

return bellicos
