-- Razi's old static color strokes are retired; native route geometry is
-- the only source of truth and the external mod handles route overlays.
package.path="./?.lua;./?/init.lua;"..package.path

local pass=require("prototypes.system.route_highlights")
local src={
  from="sye-solaris",to="vulcanus",shape="line",
  asteroid_spawn_definitions={{asteroid="big-metallic-asteroid",probability=.08}}
}
local normal={
  from="sye-solaris",to="vulcanus",shape="line",
  asteroid_spawn_definitions={}
}
local dangerous=pass.color_for_route(src)
local quiet=pass.color_for_route(normal)
assert(type(dangerous)=="table" and type(quiet)=="table",
  "Route danger palette must remain available without a sprite renderer")
assert(type(dangerous.r)=="number" and type(quiet.b)=="number",
  "Tooltip danger colors must remain numeric")
assert(#pass.strokes_for_connection(src,"clear")==0,
  "Retired static strokes must never be emitted")
assert(#pass.layers_for_guide({},quiet,"clear")==0,
  "Retired manual masks must never be emitted")
assert(pass.field_marker()==nil,"Retired route ornaments must stay absent")
local sprites={{filename="native-background"}}
rawset(_G,"data",{raw={["utility-sprites"]={default={starmap_star={
  layers=sprites
}}}}})
assert(pass.data_final_fixes()==0 and #sprites==1,
  "Disabled Razi renderer must not touch the native atlas")
assert(sprites[1].filename=="native-background",
  "Native starmap sprite was altered")
print("Native route ownership and overlay retirement fixtures passed")
