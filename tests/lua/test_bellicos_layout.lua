---@diagnostic disable: missing-fields, need-check-nil, undefined-field
-- Guards against optional Aegis & Bellicos prototype changes between stages.
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(condition, message)
  if not condition then error(message, 2) end
end

package.loaded["__space-age__.prototypes.planet.asteroid-spawn-definitions"] = {
  aquilo_solar_system_edge = {},
  spawn_definitions = function() return {} end
}

local gate_a = "calidus-bellicos-stargate-calidus"
local gate_b = "calidus-bellicos-stargate-bellicos"
local route_name = "solar-system-edge-aegis-stargate"

local function run(options)
  options = options or {}
  local places = {
    ["solar-system-edge"] = {name="solar-system-edge"},
    [gate_a] = {name=gate_a},
    [gate_b] = {name=gate_b}
  }
  local planets = {}
  if options.pulsar == "space-location" then
    places.pulsar = {name="pulsar"}
  elseif options.pulsar == "planet" then
    planets.pulsar = {name="pulsar"}
  end
  if options.no_entry_gate then places[gate_a] = nil end
  if options.near then
    places["near-bellicos-orbit"]={name="near-bellicos-orbit"}
    places["aegis-inner-edge"]={name="aegis-inner-edge"}
    places["aegis-outer-edge"]={name="aegis-outer-edge"}
    places["point-warden"]={name="point-warden"}
  end
  local routes = {}
  rawset(_G, "data", {
    raw = {["space-location"]=places, planet=planets,
      ["space-connection"]=routes},
    extend = function(self, entries)
      for _, entry in ipairs(entries) do
        check(not routes[entry.name], "Duplicate expedition route")
        routes[entry.name] = entry
      end
    end
  })
  rawset(_G, "mods", {["bellicos-and-aegis"]="0.4.1"})
  rawset(_G, "deleteRoute", function(name) routes[name] = nil end)
  rawset(_G, "deleteRoutesBetween", function(a, b)
    for name, route in pairs(routes) do
      if (route.from==a and route.to==b)
        or (route.from==b and route.to==a) then routes[name]=nil end
    end
  end)
  local updates = {}
  rawset(_G, "PlanetsLib", {update=function(_, entries)
    for _, entry in ipairs(entries) do
      local bucket = data.raw[entry.type]
      local place = bucket and bucket[entry.name]
      check(place, "Updated missing prototype: " .. entry.name)
      local parent = entry.orbit.parent
      check(data.raw[parent.type] and data.raw[parent.type][parent.name],
        "Orbit parent missing: " .. parent.name)
      place.orbit = entry.orbit
      updates[#updates + 1] = entry.name
    end
  end})
  package.loaded["prototypes.system.bellicos"] = nil
  local module = require("prototypes.system.bellicos")
  module.data()
  module.data_final_fixes()
  return module, places, planets, routes, updates
end

local _, present, _, connected = run({pulsar="space-location"})
check(present.pulsar.orbit.parent.name == "solar-system-edge",
  "Present native pulsar did not join deep-space annex")
check(present[gate_b].orbit.parent.name == "pulsar",
  "Present pulsar gateway not attached to pulsar")
check(present[gate_a].orbit.parent.name == "solar-system-edge",
  "Entry gateway not attached to deep-space edge")
check(connected[route_name] and connected[route_name].length==250000,
  "Original expedition route gameplay length changed")

local _, missing, _, fallback = run()
check(missing[gate_b].orbit.parent.name=="solar-system-edge",
  "Missing pulsar must attach gateway to existing annex instead")
check(missing[gate_b].orbit.distance==140,
  "Missing pulsar fallback no longer separates the two gates")
check(fallback[route_name], "Missing pulsar must not remove expedition route")

local _, near_locations=run({near=true})
check(near_locations["near-bellicos-orbit"].orbit.parent.name=="solar-system-edge",
  "Visible Bellicos orbit should be detached from the central galaxy")
check(near_locations["near-bellicos-orbit"].orbit.distance==145,
  "Visible Bellicos orbit was not moved north of Deep Space")
check(near_locations["aegis-inner-edge"].orbit.parent.name=="near-bellicos-orbit"
  and near_locations["aegis-outer-edge"].orbit.parent.name=="near-bellicos-orbit",
  "Native Aegis belt nodes were left behind")
check(near_locations[gate_b].orbit.parent.name=="near-bellicos-orbit",
  "Remote Bellicos stargate is detached from its destination")

local _, alt_locations, alt_planets = run({pulsar="planet"})
check(alt_planets.pulsar.orbit.parent.name=="solar-system-edge",
  "Retyped native pulsar was not found in data.raw.planet")
check(alt_locations[gate_b].orbit.parent.type=="planet",
  "Gateway orbit does not use the actual pulsar prototype type")

local _, absent, _, no_route = run({no_entry_gate=true})
check(not absent[gate_a] and not no_route[route_name],
  "Razi created a route with a missing native entry gateway")

-- Simulate the exact crash: an upstream data-final-fixes removes the pulsar
-- that was present in data.lua, before Razi's final-stage positioning runs.
local disappearing, disappearing_locations = run({pulsar="space-location"})
disappearing_locations.pulsar = nil
disappearing.data_final_fixes()
check(disappearing_locations[gate_b].orbit.parent.name=="solar-system-edge",
  "Final-stage removed pulsar still referenced as orbit parent")

-- Late gateway removal also invalidates the route Razi registered in data.lua.
local no_longer_present, late_locations, _, late_routes =
  run({pulsar="space-location"})
late_locations[gate_a] = nil
no_longer_present.data_final_fixes()
check(not late_routes[route_name],
  "Final-stage removed gateway left an invalid space connection")

print("Bellicos missing/retyped/removed prototype compatibility passed")
