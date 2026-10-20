-- Native plasma and short source route compatibility guards.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(value,message) if not value then error(message,2) end end
local outer,inner="test-outer-sun","test-inner-sun"
local plasma={
 type="entity",asteroid="source-plasma-clot",
 spawn_points={{distance=.5,probability=.42,speed=.03}}
}
local fallback={
 type="space-connection",name="razi-calidus-stellar-orbit",
 from="sye-calidus",to=outer,length=10500,
 asteroid_spawn_definitions={}
}
local source_route={
 type="space-connection",name="source-nauvis-to-star",
 from="nauvis",to=outer,length=9500,
 asteroid_spawn_definitions={plasma}
}
local inner_route={
 type="space-connection",name="source-inner-orbit",
 from=outer,to=inner,length=4500,
 asteroid_spawn_definitions={{type="entity",asteroid="source-plasma-clot",
  spawn_points={{distance=.4,probability=.21,speed=.025}}}}
}
local routes={[fallback.name]=fallback,
 [source_route.name]=source_route,[inner_route.name]=inner_route}
rawset(_G,"data",{raw={technology={
 ["planet-discovery-sunorbit"]={effects={
  {type="unlock-space-location",space_location=outer}}},
 ["slp-solar-system-sun2"]={effects={
  {type="unlock-space-location",space_location=inner}}}},
 ["space-location"]={[outer]={},[inner]={}},
 ["space-connection"]=routes}})
rawset(_G,"mods",{["slp-dyson-sphere-reworked-fork"]="1.0.5"})
rawset(_G,"settings",{startup={
 ["razi-helios-route-distance"]={value="extended"},
 ["razi-helios-route-danger"]={value="extreme"}}})
local calls={create=0,apply=0,field=0}
package.loaded["prototypes.system.asteroid_profiles"]={
 create=function()
  calls.create=calls.create+1
  return {{type="entity",asteroid="huge-metallic-asteroid",
   spawn_points={{distance=.50,probability=.02,speed=.015}}}}
 end,
 apply=function(route)
  calls.apply=calls.apply+1
 end,
 apply_field=function(route,strength)
  calls.field=calls.field+1
  route.test_field_strength=strength
 end
}
package.loaded["prototypes.compat.calidus_dyson"]=nil
local dyson=require("prototypes.compat.calidus_dyson")
check(dyson.fortify_routes()==3,
 "every retained solar connection must be reinforced")
check(fallback.length==125000 and source_route.length==125000,
 "source or Razi outer orbit retained an easy shortcut")
check(inner_route.length==65000,
 "inner solar orbit should demand a longer, harder voyage")
check(source_route.asteroid_spawn_definitions[1]==plasma,
 "native plasma encounter was overwritten or reordered")
check(#source_route.asteroid_spawn_definitions==2,
 "source plasma and late asteroids must coexist")
check(inner_route.test_field_strength>source_route.test_field_strength,
 "approaching the inner star must increase pressure")
settings.startup["razi-helios-route-distance"].value="marathon"
settings.startup["razi-helios-route-danger"].value="native"
check(dyson.fortify_routes()==3,
 "marathon setting did not modify routes")
check(fallback.length==175000 and inner_route.length==100000,
 "marathon distance thresholds not applied")
local original=#source_route.asteroid_spawn_definitions
settings.startup["razi-helios-route-distance"].value="native"
check(dyson.fortify_routes()==0 and
 #source_route.asteroid_spawn_definitions==original,
 "native/no-change mode unexpectedly modified source plasma")
print("HELIOS route distance, plasma preservation and intensity passed")
