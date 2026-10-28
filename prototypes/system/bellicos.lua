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

-- Aegis & Bellicos (and compatibility mods) may define parallel connections
-- between the same two expedition locations under different prototype names.
-- Keep the route with the most complete asteroid data so that the journey
-- stays challenging and route-overlay mods can classify its actual hazards.
-- Never replace the source mod's asteroid patterns with artificial ones.
local function is_aegis_location(name)
	return type(name) == "string" and (
		name == "pulsar" or
		name == entry_gate or
		name == bellicos_gate or
		name:find("aegis", 1, true) ~= nil or
		name:find("bellicos", 1, true) ~= nil or
		name:find("warden", 1, true) ~= nil
	)
end

local function deduplicate_aegis_connections()
	local connections = data.raw["space-connection"] or {}
	local names = {}
	for name in pairs(connections) do
		names[#names + 1] = name
	end
	table.sort(names)

	local kept_by_pair = {}
	for _, name in ipairs(names) do
		local route = connections[name]
		if route and is_aegis_location(route.from) and is_aegis_location(route.to) then
			local a, b = route.from, route.to
			if a > b then
				a, b = b, a
			end
			local pair = a .. "\0" .. b
			local kept_name = kept_by_pair[pair]
			if not kept_name then
				kept_by_pair[pair] = name
			else
				local kept = connections[kept_name]
				local current_count = #(route.asteroid_spawn_definitions or {})
				local kept_count = #(kept.asteroid_spawn_definitions or {})
				if current_count > kept_count then
					connections[kept_name] = nil
					kept_by_pair[pair] = name
				else
					connections[name] = nil
				end
			end
		end
	end
end

function bellicos.data_final_fixes()
	if not mods["bellicos-and-aegis"] then
		return
	end

	-- Other route compatibility passes can run after the source mod. Keep only
	-- Razi Protocol's deep-space entrance while preserving every route inside Aegis.
	remove_stock_entry_routes()
	deduplicate_aegis_connections()
end

return bellicos
