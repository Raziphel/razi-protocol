-- Version-safe star-centered route curvature with no native overwrites.
package.path="./?.lua;./?/init.lua;"..package.path
-- The route reconciler imports Space Age's native spawn presets.
-- Stub only that external dependency so this fixture runs under stock Lua.
package.loaded["__space-age__.prototypes.planet.asteroid-spawn-definitions"]={
  nauvis_fulgora={},nauvis_gleba={},vulcanus_castra={},
  fulgora_aquilo={},gleba_aquilo={},aquilo_solar_system_edge={},
  spawn_definitions=function() return {} end
}
local mod=require("prototypes.system.route_reconcile")
rawset(_G,"mods",{base="2.1.19"})
assert(mod.regional_origin("vulcanus","arig","arc")==nil,
  "Old clients must not get a future prototype field")
mods.base="2.1.20"
local coords=mod.regional_origin("vulcanus","arig","arc")
assert(coords and math.abs(coords.x-52)<.01 and
  math.abs(coords.y-90.06664)<.01,"Solaris curve centre lost")
assert(mod.regional_origin("sye-solaris","sye-vibrant","line")==nil,
  "Straight crossing must not be curved")
assert(mod.regional_origin("aquilo","rubia","arc")~=nil,
  "A known Vespera arc should be centred locally")
assert(mod.regional_origin("vulcanus","gleba","arc")==nil,
  "Mixed-star connection cannot use local arc centre")
mods.base="2.1.21"
assert(mod.regional_origin("gleba","moshine","arc")~=nil,
  "Nyxaris routes must support latest 2.1 clients")
print("Factorio-version-gated regional arc fixtures passed")
