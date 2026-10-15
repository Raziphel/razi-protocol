-- Regression for the duplicated green route visible in Factorio.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(v,msg) if not v then error(msg,2) end end
local raw={planet={
  a={distance=10,orientation=.25},
  b={distance=68,orientation=.25},
  c={distance=35,orientation=.5},
  d={distance=72,orientation=.5}},
 ["space-location"]={
  ["razi-umbra-belt-inner"]={distance=12,orientation=.25},
  ["razi-umbra-belt-outer"]={distance=22,orientation=.25}},
 ["space-connection"]={},
 ["utility-sprites"]={default={starmap_star={layers={
  {filename="__base__/graphics/native-sun.png"}}}}}}
rawset(_G,"data",{raw=raw})
rawset(_G,"mods",{})
rawset(_G,"settings",{startup={
 ["razi-route-overlay-mode"]={value="danger"},
 ["razi-route-overlay-scope"]={value="all"}}})
local m=require("prototypes.system.route_highlights")
local safe={from="a",to="b",shape="line",asteroid_spawn_definitions={}}
local medium={from="c",to="d",shape="line",
 asteroid_spawn_definitions={{asteroid="medium-metallic-asteroid",probability=.2}}}
local huge={from="c",to="d",shape="line",
 asteroid_spawn_definitions={{asteroid="huge-metallic-asteroid",probability=.2}}}
local belt={from="razi-umbra-belt-inner",to="razi-umbra-belt-outer",
 shape="line",asteroid_spawn_definitions={}}
check(m.threat_tier(medium)==3 and m.threat_tier(huge)==5,
 "Threat rankings must not change")
check(#m.strokes_for_connection(safe,"danger","all")==0,
 "Safe line must remain entirely native")
check(#m.strokes_for_connection(medium,"danger","all")==0,
 "Medium asteroid route must not have a doubled green stripe")
check(#m.strokes_for_connection(huge,"danger","all")==1,
 "Severe hazard must have one warning")
check(#m.strokes_for_connection(belt,"danger","major")==1,
 "Belt crossing gets one warning")
local marker=m.marker_for_connection(huge,"danger","all")
check(marker.size[1]==64 and marker.scale<.4 and marker.tint.a<.7,
 "Badges are compact and translucent")
check(#m.strokes_for_connection(safe,"chapter","all")==1,
 "Chapter setting may place a small noncontinuous marker")
local arc={from="c",to="d",shape="arc",
 asteroid_spawn_definitions={{asteroid="huge-metallic-asteroid",probability=.2}}}
check(#m.strokes_for_connection(arc,"danger","all")==0,
 "Do not guess distant arc shapes")
raw["space-connection"]={safe=safe,medium=medium,huge=huge,belt=belt}
local layers=raw["utility-sprites"].default.starmap_star.layers
check(m.data_final_fixes()==2,"Only real severe hazards and belts get icons")
local total=#layers
check(m.data_final_fixes()==0 and #layers==total,
 "Do not duplicate warning sprites on another data pass")
settings.startup["razi-route-overlay-mode"].value="off"
layers[1]={filename="__razi-protocol__/graphics/route-highlights/continuous-strokes.png"}
check(m.data_final_fixes()==0 and #layers==total-1,
 "Old stretched route sprites must be removed even in Off mode")
print("Route sprite doubling and severe hazard regression passed")
