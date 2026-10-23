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
local old_route = "razi-vespera-aegis-stargate"

local function run(options)
  options = options or {}
  local places = {
    ["solar-system-edge"] = {name="solar-system-edge"},
    ["sye-vespera"] = {name="sye-vespera"},
    ["sye-calidus"] = {name="sye-calidus"},
    [gate_a] = {name=gate_a},
    [gate_b] = {name=gate_b}
  }
  local planets = {}
  if options.pulsar == "space-location" then
    places.pulsar = {name="pulsar",orbit={sprite={filename="__aegis_graphics__/pulsar-atlas.png"}}}
  elseif options.pulsar == "planet" then
    planets.pulsar = {name="pulsar",orbit={sprite={filename="__aegis_graphics__/pulsar-atlas.png"}}}
  end
  if options.no_entry_gate then places[gate_a] = nil end
  if options.near then
    if options.dual_warden then
      planets["point-warden"]={name="point-warden"}
    end
    places["near-bellicos-orbit"]={name="near-bellicos-orbit",
      orbit={sprite={filename="__aegis_graphics__/belt-visual.png"}}}
    places["aegis-inner-edge"]={name="aegis-inner-edge"}
    places["aegis-outer-edge"]={name="aegis-outer-edge"}
    if options.alias_warden then
      places["aegis-point-warden"]={name="aegis-point-warden"}
    else
      places["point-warden"]={name="point-warden"}
    end
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
check(present.pulsar.orbit.sprite
  and present.pulsar.orbit.sprite.filename=="__aegis_graphics__/pulsar-atlas.png",
  "Bellicos relocation erased the source pulsar image")
local pulsar_image=present.pulsar.orbit.sprite
local good_pulsar=present.pulsar
-- Verify the dedicated data-updates recovery does not clear artwork if
-- another mod's data-updates temporarily touched the pulsar placement.
local check_module=require("prototypes.system.bellicos")
check_module.data_updates()
check(good_pulsar.orbit.sprite==pulsar_image,
  "Bellicos pre-render reparenting removed its preserved source sprite")
check(present.pulsar.orbit.parent.name == "sye-calidus"
  and present.pulsar.orbit.distance==190,
  "Pulsar did not join shared southern frontier")
check(present[gate_b].orbit.parent.name == "pulsar",
  "Present pulsar gateway not attached to pulsar")
check(present[gate_a].orbit.parent.name == "sye-calidus"
  and present[gate_a].orbit.distance==153
  and present[gate_a].orbit.orientation==0.53,
  "Aegis entry must lie north of the pulsar")
check(not connected[old_route], "Legacy Vespera-only route was not retired")

local _, missing, _, fallback = run()
check(missing[gate_b].orbit.parent.name=="sye-calidus",
  "Missing pulsar must attach gateway to southern frontier")
check(missing[gate_b].orbit.distance>225
  and missing[gate_b].orbit.distance<260,
  "Missing pulsar fallback must stay in southern frontier")
check(not fallback[old_route], "Legacy route resurfaced on pulsar fallback")

-- Exercise the REAL data-final-fixes path, including the near/pulsar drift
-- diagnostic. An 'and native_point(near)' expression discarded the Y return,
-- making this fixture crash with 'arithmetic on local ny (a nil value)'.
local ok, near_mod_or_error, near_locations=pcall(run,{near=true})
check(ok, "Bellicos near-orbit must load without nil-Y crash: "..
  tostring(near_mod_or_error))
check(near_locations["near-bellicos-orbit"].orbit.sprite
  and near_locations["near-bellicos-orbit"].orbit.sprite.filename=="__aegis_graphics__/belt-visual.png",
  "Bellicos relocation erased source asteroid-belt art")
check(near_locations["near-bellicos-orbit"].orbit.parent.name=="sye-calidus",
  "Visible Bellicos orbit should be detached from the central galaxy")
check(near_locations["near-bellicos-orbit"].orbit.distance>189
  and near_locations["near-bellicos-orbit"].orbit.distance<194,
  "Visible Aegis belt was not moved below initial pair")
check(near_locations["aegis-inner-edge"].orbit.parent.name=="near-bellicos-orbit"
  and near_locations["aegis-outer-edge"].orbit.parent.name=="near-bellicos-orbit",
  "Native Aegis belt nodes were left behind")
check(near_locations[gate_b].orbit.parent.name=="near-bellicos-orbit",
  "Remote Bellicos stargate is detached from its destination")
-- Prevent a regression to the flat row of "Aegis Point Warden" labels.
-- The native fields must agree with the PlanetsLib source orbit angles.
local function actual_position(name)
  local body=near_locations[name]
  local center=body.origin
  local angle=body.orientation*2*math.pi
  return center.x+body.distance*math.sin(angle),
    center.y-body.distance*math.cos(angle)
end
local near_x,near_y=actual_position("near-bellicos-orbit")
local inner_x,inner_y=actual_position("aegis-inner-edge")
local point_x,point_y=actual_position("point-warden")
local outer_x,outer_y=actual_position("aegis-outer-edge")
local gate_x,gate_y=actual_position(gate_b)
check(outer_y<inner_y-10 and inner_y<near_y
  and point_y>inner_y+20 and gate_y>point_y+12,
  "Aegis route spine is overlapping or running back into its source belt")
check(outer_x<inner_x and inner_x<point_x and point_x<gate_x,
  "Aegis waypoints no longer advance from outer rim toward Bellicos")
-- Two long nearly coincident Inner-Edge departures looked like a doubled
-- route. Require distinct bearings WITHOUT removing any source game route.
local wx,wy=point_x-inner_x,point_y-inner_y
local ox,oy=outer_x-inner_x,outer_y-inner_y
local spread=math.abs(wx*oy-wy*ox)/
  (math.sqrt(wx*wx+wy*wy)*math.sqrt(ox*ox+oy*oy))
check(spread>0.45,"Aegis Inner Edge routes became nearly parallel again")
local gate_dx,gate_dy=gate_x-point_x,gate_y-point_y
check(math.sqrt((gate_x-point_x)^2+(gate_y-point_y)^2)<35,
  "Bellicos stargate must be close to Point Warden")
for _,name in ipairs({"aegis-inner-edge","point-warden",
   "aegis-outer-edge",gate_b}) do
  local body=near_locations[name]
  local orbit=body.orbit
  check(type(body.distance)=="number"
    and type(body.orientation)=="number",
    "Missing absolute native coordinate: "..name)
  check(body.origin.x==0 and body.origin.y==0,
    "Late Factorio coordinates must be independent of relative source origin: "..name)
  check(type(orbit)=="table" and orbit.parent.name=="near-bellicos-orbit",
    "Aegis still has the wrong navigation parent: "..name)
end
-- Local radii are stored in orbit metadata; native fields are absolute.
check(math.abs(near_locations["aegis-inner-edge"].orbit.distance-29)<.001
  and math.abs(near_locations["point-warden"].orbit.distance-48)<.001
  and math.abs(near_locations["aegis-outer-edge"].orbit.distance-35)<.001
  and math.abs(near_locations[gate_b].orbit.distance-74)<.001,
  "Aegis sector local radii drifted")


local _, alt_locations, alt_planets = run({pulsar="planet"})
check(alt_planets.pulsar.orbit.parent.name=="sye-calidus",
  "Retyped native pulsar was not found in data.raw.planet")
check(alt_locations[gate_b].orbit.parent.type=="planet",
  "Gateway orbit does not use the actual pulsar prototype type")

local _, absent, _, no_route = run({no_entry_gate=true})
check(not absent[gate_a] and not no_route[old_route],
  "Razi created a route with a missing native entry gateway")

-- Simulate the exact crash: an upstream data-final-fixes removes the pulsar
-- that was present in data.lua, before Razi's final-stage positioning runs.
local disappearing, disappearing_locations = run({pulsar="space-location"})
disappearing_locations.pulsar = nil
disappearing.data_final_fixes()
check(disappearing_locations[gate_b].orbit.parent.name=="sye-calidus",
  "Final-stage removed pulsar still referenced as orbit parent")

-- Late gateway removal also invalidates the route Razi registered in data.lua.
local no_longer_present, late_locations, _, late_routes =
  run({pulsar="space-location"})
late_locations[gate_a] = nil
no_longer_present.data_final_fixes()
check(not late_routes[old_route],
  "Final-stage removed gateway left an invalid space connection")

-- Factorio's Lua 5.2 math.atan(y,x) ignores the x argument. Simulate the
-- old one-argument-only behavior in any standalone Lua test version so the
-- missing-pulsar fallback cannot accidentally rely on two-arg math.atan.
local lua_atan,lua_atan2=math.atan,math.atan2
math.atan=function(value) return lua_atan(value) end
math.atan2=lua_atan2 or function(y,x) return lua_atan(y,x) end
local no_pulsar,orbit_locations=run({near=true})
local layout=require("prototypes.system.galaxy_layout")
local edge_x,edge_y=layout.anchor_position("sye-calidus")
local p_x=edge_x+190*math.sin(2*math.pi*.5)
local p_y=edge_y-190*math.cos(2*math.pi*.5)
local function absolute(name)
  local body=orbit_locations[name]
  check(body and body.origin,"Expected native Aegis prototype: "..name)
  local origin=body.origin
  local theta=2*math.pi*body.orientation
  return origin.x+body.distance*math.sin(theta),
    origin.y-body.distance*math.cos(theta)
end
local near_px,near_py=absolute("near-bellicos-orbit")
check(math.sqrt((near_px-p_x)^2+(near_py-p_y)^2)<3.01,
  "Missing pulsar sent Near Bellicos Orbit sideways from southern frontier")
check(near_py>edge_y+188 and math.abs(near_px-edge_x)<5,
  "Near Bellicos Orbit must be south of two starter stars")
for _,name in ipairs({"aegis-inner-edge","point-warden",
    "aegis-outer-edge",gate_b}) do
  local cx,cy=absolute(name)
  local distance=math.sqrt((cx-near_px)^2+(cy-near_py)^2)
  check(distance<=75,"Aegis location outside its pulsar system: "..name)
end
local w_x,w_y=absolute("point-warden")
check(math.sqrt((w_x-near_px)^2+(w_y-near_py)^2)>40
  and math.sqrt((w_x-near_px)^2+(w_y-near_py)^2)<50,
  "Point Warden must remain in its intended Aegis lane")
-- Redo the final pass after the pulsar disappears; it must stay put.
no_pulsar.reconcile_final_positions()
local again_x,again_y=absolute("near-bellicos-orbit")
check(math.abs(again_x-near_px)<.01 and math.abs(again_y-near_py)<.01,
  "Repeated final pass moved the Aegis sector away from its pulsar")
math.atan,math.atan2=lua_atan,lua_atan2

-- Source releases can rename Warden without changing the UI label.
-- Check the discovered native prototype and not only the old literal ID.
local alt,alternate=run({near=true,alias_warden=true})
local extra=alternate["aegis-point-warden"]
check(extra and extra.origin and extra.origin.x==0 and extra.origin.y==0,
  "Alternate source Warden ID remained marooned near Secretas")
check(extra.orbit.parent.name=="near-bellicos-orbit"
  and math.abs(extra.orbit.distance-48)<.001,
  "Alternate Warden source orbit was not retained")
local alt_near=alternate["near-bellicos-orbit"]
local function pos2(body)
  local x,y=body.origin.x,body.origin.y
  local a=body.orientation*2*math.pi
  return x+body.distance*math.sin(a),y-body.distance*math.cos(a)
end
local ax,ay=pos2(extra)
local nx,ny=pos2(alt_near)
check(math.abs(math.sqrt((ax-nx)^2+(ay-ny)^2)-48)<.01,
  "Alternate Warden still renders outside Bellicos")
alt.reconcile_final_positions()
local repeat_x,repeat_y=pos2(extra)
check(math.abs(repeat_x-ax)<.001 and math.abs(repeat_y-ay)<.001,
  "Reconciliation must remain stable for a renamed Warden")

-- Reproduce the player's screenshot: Warden was relocated to Beetlejuice
-- even though the pulsar/asteroid field had already moved to Deep Space.
-- The final pass must correct BOTH prototype types and leave sprite art
-- anchored at the vanished sprite-only pulsar, without late PlanetsLib API.
local dual,dual_places,dual_planets=run({
  near=true,pulsar="space-location",dual_warden=true})
dual_places.pulsar=nil -- sprite-only parent removed by PlanetsLib
local near=dual_places["near-bellicos-orbit"]
for _,body in ipairs({dual_places["point-warden"],dual_planets["point-warden"]}) do
  body.origin={x=83,y=-160} -- old Beetlejuice/Secretas chart vicinity
  body.distance=14
  body.orientation=.25
  body.orbit={parent={type="space-location",name="beetlejuice"},
    distance=14,orientation=.25}
end
local original_art={filename="__bellicos-graphics__/aegis-debris.png",
  planetslib_orbit_name="near-bellicos-orbit",
  planetslib_orbit_shift={16,-8},shift={0,0}}
data.raw["utility-sprites"]={default={starmap_star={
  layers={original_art}}}}
-- Any accidental late PlanetsLib:update is forbidden after pulsar deletion.
PlanetsLib.update=function()
  error("Late PlanetsLib:update would displace Bellicos child locations")
end
local n,art=dual.reconcile_final_positions()
check(n>=5 and art==1,"Bellicos reconciliation failed or lost source art")
local near_x,near_y=actual_position("near-bellicos-orbit")
for _,body in ipairs({dual_places["point-warden"],dual_planets["point-warden"]}) do
  check(body.origin.x==0 and body.origin.y==0
    and math.abs(body.orbit.distance-48)<.001
    and math.abs(body.orbit.orientation-.32)<.001
    and body.orbit.parent.name=="near-bellicos-orbit",
    "A Warden native prototype is still marooned near Secretas")
end
local edge_x,edge_y=require("prototypes.system.galaxy_layout")
  .anchor_position("sye-calidus")
local source_x=edge_x+190*math.sin(2*math.pi*.5)
local source_y=edge_y-190*math.cos(2*math.pi*.5)
check(math.abs(original_art.shift[1]-(16+source_x*32))<.01
  and math.abs(original_art.shift[2]-(-8+source_y*32))<.01,
  "Aegis belt art abandoned the native pulsar when the parent was deleted")
check(dual.reconcile_final_positions()>=5
  and math.abs(original_art.shift[1]-(16+source_x*32))<.01,
  "Repeated final reconciliation must not move artwork or Warden again")
print("Bellicos late-stage Warden, duplicate-prototype and sprite tests passed")
