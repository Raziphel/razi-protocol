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
  -- Aegis & Bellicos 0.4.4 removed the PlanetsLib-only "pulsar" and
  -- replaced it with a real "bellicos-pulsar" location. Never send the
  -- deleted name to PlanetsLib:update: that aborts the entire mod pack.
  local locations = data.raw["space-location"] or {}
  local native_pulsar = locations["bellicos-pulsar"]
    or (data.raw.planet or {})["bellicos-pulsar"]
  local legacy_pulsar = not native_pulsar and locations.pulsar
  local updates = {}
  if legacy_pulsar then
    updates[#updates + 1] = {
      type = "space-location",
      name = "pulsar",
      orbit = {
        parent = {type = "space-location", name = "solar-system-edge"},
        distance = 240,
        orientation = 0.5
      }
    }
  end

  if locations[entry_gate] and locations["solar-system-edge"] then
    updates[#updates + 1] = {
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
    }
  end

  -- The original far-side gate orbited the old sprite-only pulsar.
  -- New releases position their locations using the native star instead.
  if legacy_pulsar and locations[bellicos_gate] then
    updates[#updates + 1] = {
      type = "space-location",
      name = bellicos_gate,
      orbit = {
        parent = {type = "space-location", name = "pulsar"},
        distance = 58,
        orientation = 0.0
      },
      redrawn_connections_exclude = true
    }
  end
  if #updates > 0 then PlanetsLib:update(updates) end

  if native_pulsar then
    -- Aegis 0.4.4+ moves all native pulsar satellites and graphics in its
    -- data-updates phase. Relocate the real star BEFORE that source pass,
    -- rather than reparenting any of its dependent locations in PlanetsLib.
    local edge = locations["solar-system-edge"]
    local origin = edge and edge.origin
    local ox = origin and (origin.x or origin[1]) or 0
    local oy = origin and (origin.y or origin[2]) or 0
    if edge and type(edge.distance) == "number"
      and type(edge.orientation) == "number"
      and type(ox) == "number" and type(oy) == "number" then
      local angle = 2 * math.pi * edge.orientation
      native_pulsar.origin = {
        x = ox + edge.distance * math.sin(angle),
        y = oy - edge.distance * math.cos(angle)
      }
      native_pulsar.distance = 240
      native_pulsar.orientation = 0.5
    elseif type(log) == "function" then
      -- Preserve source coordinates if the edge hasn't resolved yet.
      log("[Razi Protocol/Bellicos] Native solar-system edge unavailable; keeping Aegis' source star position")
    end
  end

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
