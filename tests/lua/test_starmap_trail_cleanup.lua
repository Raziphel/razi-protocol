-- Visual-only starmap sanitizer regression fixtures.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(value,message)
  if not value then error(message,2) end
end
local M=require("prototypes.system.starmap_trail_cleanup")
local assets={
  {filename="__orbital-cannon__/graphics/starmap/route.png"},
  {stripes={{filename="__orbital-cannon__/graphics/dotted-tail.png"}}},
  {filenames={"__orbital-cannon__/graphics/cannon-01.png"}},
  {filename="__razi-protocol__/graphics/route-highlights/directional-strokes.png",
    tint={r=1,g=.22,b=.3},shift={5*32,3*32}},
  {planetslib_orbit_name="carna",filename="__a__/orbits/decor.png"},
  {planetslib_orbit_name="velora",filename="__b__/orbits/decor.png"},
  {filename="__razi-protocol__/graphics/route-highlights/directional-strokes.png",
    tint={r=.76,g=.59,b=.95},shift={5*32,3*32}},
  {filename="__razi-protocol__/graphics/starmap/razi/glow-umbra.png",
    tint={r=.8,g=.2,b=.2},shift={5*32,3*32}},
  {filename="__razi-protocol__/graphics/route-highlights/directional-strokes.png",
    tint={r=1,g=.22,b=.3},shift={90*32,90*32}},
  {filename="__razi-protocol__/graphics/route-highlights/directional-strokes.png",
    tint={r=1,g=.22,b=.3},shift={5*32,40*32}},
  {filename="__base__/graphics/normal-orbit.png"}
}
local n,d=M.remove_layers(assets,{{x=5,y=3}})
check(n==6 and d.catapult==3 and d.orbit==2 and d.strokes==1,
  "Every catapult/Carna/Velora visual ribbon must be removed")
check(#assets==5,"Too many layers removed")
check(not M.is_catapult_sprite("__razi-protocol__/graphics/starmap/razi/glow-umbra.png"),
  "Other mods must not be affected")
check(M.remove_layers(assets,{{x=5,y=3}})==0,"Cleanup must be idempotent")
local connections={["carna-crucible"]={from="carna",to="crucible-orbit"}}
local links={["gleba-velora"]={source="gleba",target="velora"}}
data={raw={planet={carna={origin={x=0,y=0},distance=10,orientation=.25},
  velora={origin={x=20,y=20},distance=2,orientation=.4}},
  ["utility-sprites"]={default={starmap_star={layers={
    {filename="__orbital-cannon__/graphics/starmap/leftover.png"},
    {filename="__other__/star.png"}}}}},
  ["space-connection"]=connections,
  ["orbital-cannon-link"]=links
}}
local changed=M.data_final_fixes()
check(changed==1 and #data.raw["utility-sprites"].default.starmap_star.layers==1,
  "Actual final-stage invocation failed to remove catapult graphics")
check(data.raw["space-connection"]==connections
  and data.raw["orbital-cannon-link"]==links,
  "A visual cleanup must never modify real travel or catapult transport")
print("Catapult red starmap ribbon removal fixtures passed")
