-- Geometry, ownership and duplication fixtures for Razi's native route colors.
package.path="./?.lua;./?/init.lua;"..package.path

local function check(ok,why)
  if not ok then error(why,2) end
end
local data_raw={
  planet={
    nauvis={distance=12,orientation=.25},
    vulcanus={origin={x=52,y=90},distance=18,orientation=.67},
    castra={origin={x=52,y=90},distance=37,orientation=.61},
    ["distant-one"]={origin={x=104,y=0},distance=31,orientation=.6},
    ["distant-two"]={origin={x=104,y=0},distance=31,orientation=.75},
    ["odd-world"]={origin={x=0,y=0},distance=300,orientation=.75}
  },
  ["space-location"]={
    ["sye-calidus"]={distance=20,orientation=.5},
    ["sye-solaris"]={origin={x=52,y=90},distance=34,orientation=.75},
    ["other"]={origin={x=145,y=70},distance=29,orientation=.5}
  },
  ["space-connection"]={},
  ["utility-sprites"]={default={starmap_star={layers={
    {filename="__base__/graphics/native-sun.png"}
  }}}}
}
rawset(_G,"data",{raw=data_raw})
rawset(_G,"mods",{})
rawset(_G,"settings",{startup={
  ["razi-route-overlay-mode"]={value="danger"},
  ["razi-route-overlay-scope"]={value="all"}
}})
local overlay=require("prototypes.system.route_highlights")
local safe={from="sye-calidus",to="sye-solaris",shape="line",
  asteroid_spawn_definitions={}}
local danger={from="vulcanus",to="castra",shape="line",
  asteroid_spawn_definitions={
    {type="entity",asteroid="huge-metallic-asteroid",probability=.08}
  }}
local colorsafe=overlay.color_for_route(safe)
local colordanger=overlay.color_for_route(danger)
check(colorsafe.b>colorsafe.r,"Safe routes should be blue")
check(colordanger.r>colordanger.g,"Huge asteroid route should be red")
local straight=overlay.strokes_for_connection(safe,"danger","all")
check(#straight>1 and #straight<=18,"Interstellar route should be subdivided")
for _,layer in ipairs(straight) do
  check(layer.x>=0 and layer.y>=0 and layer.size[1]==256,
    "Directional source tiles must fit the 2048px atlas")
  check(layer.scale>0 and layer.scale<1.25,
    "Thin strokes should never use the old stretched sprite scaling")
  check(layer.tint.a<=.42 and layer.tint.a>.05,
    "Overlay brightness must remain restrained")
end
local local_route=overlay.strokes_for_connection(danger,"danger","all")
check(#local_route>0,"Verified local route should be colorable in All")
check(#overlay.strokes_for_connection(danger,"danger","major")==0,
  "Major mode must not paint a dense local route web")
local region={from="distant-one",to="distant-two",shape="arc",
  origin={x=104,y=0},asteroid_spawn_definitions={}}
check(#overlay.strokes_for_connection(region,"danger","all")>0,
  "Confirmed native regional arc must have color")
local guessed={from="distant-one",to="distant-two",shape="arc",
  asteroid_spawn_definitions={}}
check(#overlay.strokes_for_connection(guessed,"danger","all")==0,
  "Never draw a guessed arc across star systems")
local runaway={from="nauvis",to="odd-world",shape="arc",
  origin={x=0,y=0},asteroid_spawn_definitions={}}
check(#overlay.strokes_for_connection(runaway,"danger","all")==0,
  "Runaway galactic arc must be skipped")
check(overlay.is_navigation_highlight(safe),
  "Core interstellar corridors must keep their hazard strokes")
check(not overlay.is_navigation_highlight(danger),
  "Decorative local routes must not receive doubled hazard strokes")
for _,world in ipairs({"carna","velora"}) do
  check(not overlay.is_navigation_highlight({
    from=world,to="sye-umbra",shape="line"}),
    "Optional world "..world.." must not draw a dangling red half-line")
end
check(not overlay.is_navigation_highlight(region),
  "Arbitrary source-mod regional arcs must remain native-only")
check(overlay.is_navigation_highlight({
  from="razi-umbra-belt-inner",to="razi-umbra-belt-outer"}),
  "The physical Umbra asteroid crossing must retain its overlay")
data_raw["space-connection"].major=safe
data_raw["space-connection"].regional=region
local sprite=data_raw["utility-sprites"].default.starmap_star.layers
local painted=overlay.data_final_fixes()
check(painted==1 and #sprite>2,
  "Renderer must paint interstellar corridors without unrelated local arcs")
local count=#sprite
check(overlay.data_final_fixes()==0 and #sprite==count,
  "Second run must not duplicate any route strokes")
settings.startup["razi-route-overlay-mode"].value="off"
sprite[2]=nil
check(#overlay.strokes_for_connection(safe,"off","all")==0,
  "Off mode must keep the original native routes")
print("Razi built-in route overlay geometry fixtures passed")
