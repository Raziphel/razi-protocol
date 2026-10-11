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
local function endpoint_type(name)
	if data.raw["space-location"] and data.raw["space-location"][name] then
		return "space-location"
	end
	if data.raw.planet and data.raw.planet[name] then
		return "planet"
	end
	return nil
end

local function position_expedition()
	-- Source mods can change or remove their optional starmap locations in
	-- data-updates/data-final-fixes. Never hand an absent prototype to PlanetsLib.
	local edge_type = endpoint_type("solar-system-edge")
	if not edge_type then return end

	local updates = {}
	local function place(name, parent_name, parent_type, distance, orientation,
		is_gate)
		local kind = endpoint_type(name)
		if not kind or not parent_type then return end
		local update = {
			type = kind, name = name,
			orbit = {
				parent = {type = parent_type, name = parent_name},
				distance = distance, orientation = orientation
			},
			draw_orbit = false
		}
		if is_gate then
			update.redrawn_connections_exclude = true
		end
		updates[#updates + 1] = update
	end

	-- The pulsar may be a differently typed location, or have been removed
	-- by an upstream compatibility pass. Both cases must remain load-safe.
	local pulsar_type = endpoint_type("pulsar")
	if pulsar_type then
		place("pulsar", "solar-system-edge", edge_type, 165, 0.25, false)
	end
	place(entry_gate, "solar-system-edge", edge_type, 36, 0.25, true)
	if pulsar_type then
		place(bellicos_gate, "pulsar", pulsar_type, 62, 0.75, true)
	else
		-- Without the source pulsar prototype, place the gate in the same
		-- annex rather than creating an orbit whose parent cannot resolve.
		place(bellicos_gate, "solar-system-edge", edge_type, 103, 0.25, true)
	end
	if #updates > 0 then PlanetsLib:update(updates) end
end

function bellicos.data()
	if not mods["bellicos-and-aegis"] then
		return
	end

	position_expedition()
	remove_stock_entry_routes()
	deleteRoute(deep_space_entry_route)

	-- When a different Aegis version omits the gateway, do not register a
	-- space connection with nonexistent endpoints.
	if not endpoint_type("solar-system-edge") or not endpoint_type(entry_gate) then
		return
	end

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
