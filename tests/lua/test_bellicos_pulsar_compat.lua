---@diagnostic disable: inject-field, assign-type-mismatch
-- Regression for Aegis & Bellicos 0.4.4 removing the PlanetsLib pulsar.
-- Run from the repository root with: lua tests/lua/test_bellicos_pulsar_compat.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

package.loaded["__space-age__.prototypes.planet.asteroid-spawn-definitions"] = {
  aquilo_solar_system_edge = {},
  spawn_definitions = function() return {} end
}

local function check(ok, why)
  if not ok then error(why, 2) end
end

local entry = "calidus-bellicos-stargate-calidus"
local far = "calidus-bellicos-stargate-bellicos"

local function run(source, has_edge_position)
  local places = {
    [entry] = {name=entry},
    [far] = {name=far},
    ["solar-system-edge"] = {name="solar-system-edge",
      distance=has_edge_position and 250 or nil,
      orientation=has_edge_position and 0 or nil,
      origin={x=0,y=0}}
  }
  if source == "legacy" then
    places.pulsar = {name="pulsar"}
  elseif source == "native" then
    places["bellicos-pulsar"] = {name="bellicos-pulsar",
      origin={x=0,y=0}, distance=65, orientation=0.125}
  elseif source == "mixed" then
    places.pulsar = {name="pulsar"}
    places["bellicos-pulsar"] = {name="bellicos-pulsar"}
  end

  local routes, touched = {}, {}
  _G.mods = {["bellicos-and-aegis"]="0.4.4"}
  _G.data = {raw = {["space-location"]=places,["space-connection"]=routes,planet={}}}
  function data.extend(_, entries)
    for _, v in ipairs(entries) do routes[v.name] = v end
  end
  _G.deleteRoute = function(name) routes[name] = nil end
  _G.deleteRoutesBetween = function(a,b)
    for name, r in pairs(routes) do
      if (r.from==a and r.to==b) or (r.to==a and r.from==b) then
        routes[name]=nil
      end
    end
  end
  _G.PlanetsLib = {update=function(_, updates)
    for _, change in ipairs(updates) do
      check(places[change.name], "PlanetsLib requested missing prototype: "..change.name)
      touched[#touched+1] = change.name
      places[change.name].orbit=change.orbit
    end
  end}
  package.loaded["prototypes.system.bellicos"] = nil
  local module = require("prototypes.system.bellicos")
  module.data()
  module.data_final_fixes()
  check(routes["solar-system-edge-aegis-stargate"],
    "Razi deep-space approach disappeared")
  return places, touched
end

local legacy = run("legacy", true)
check(legacy.pulsar.orbit.parent.name=="solar-system-edge",
  "Legacy pulsar must retain PlanetsLib orbit")
check(legacy[far].orbit.parent.name=="pulsar",
  "Legacy far-side gate must retain its old source parent")

local native, new_updates = run("native", true)
for _, name in ipairs(new_updates) do
  check(name~="pulsar" and name~=far,
    "New Aegis release must not send old pulsar or dependent gates to PlanetsLib")
end
check(native["bellicos-pulsar"].distance==240
  and native["bellicos-pulsar"].orientation==0.5,
  "Native source star must take the Razi expedition bearing")
check(math.abs(native["bellicos-pulsar"].origin.y+250)<.001,
  "Native source star did not follow the solar-system-edge anchor")
check(native[entry].orbit.parent.name=="solar-system-edge",
  "Calidus-side Aegis entry stopped following the expedition")
check(native[far].orbit==nil,
  "New native Aegis far-side gate must remain source-owned")

local mixed,mixed_updates=run("mixed",true)
for _, name in ipairs(mixed_updates) do
  check(name~="pulsar", "Native Aegis must override stale old pulsar IDs")
end
check(mixed["bellicos-pulsar"].distance==240,
  "Mixed source prototypes did not prefer the native anchor")

local fallback=run("native",false)
check(fallback["bellicos-pulsar"].distance==65,
  "Unresolved edge must preserve native source star geometry")

local absent=run("missing",true)
check(absent[entry].orbit.parent.name=="solar-system-edge",
  "Missing optional pulsar should not break the remaining entry")

print("Aegis 0.4.3/0.4.4+ PlanetsLib compat and native-star fixture passed")
