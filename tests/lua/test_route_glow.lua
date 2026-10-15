-- End-to-end fixtures for Razi's continuous data-stage route overlay.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,reason)
 if not ok then error(reason,2) end
end
local raw={
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
  ["razi-umbra-belt-inner"]={origin={x=25,y=25},distance=12,orientation=.25},
  ["razi-umbra-belt-outer"]={origin={x=25,y=25},distance=24,orientation=.25}
 },
 ["space-connection"]={},
 ["utility-sprites"]={default={starmap_star={layers={
  {filename="__base__/graphics/native-sun.png"}
 }}}}
}
rawset(_G,"data",{raw=raw})
rawset(_G,"mods",{})
rawset(_G,"settings",{startup={
 ["razi-route-overlay-mode"]={value="danger"},
 ["razi-route-overlay-scope"]={value="all"}
}})
local M=require("prototypes.system.route_highlights")
local safe={from="sye-calidus",to="sye-solaris",shape="line",
 asteroid_spawn_definitions={}}
local medium={from="vulcanus",to="castra",shape="line",
 asteroid_spawn_definitions={{asteroid="medium-metallic-asteroid",probability=.2}}}
local huge={from="vulcanus",to="castra",shape="line",
 asteroid_spawn_definitions={{asteroid="huge-metallic-asteroid",probability=.1}}}
local belt={from="razi-umbra-belt-inner",to="razi-umbra-belt-outer",
 shape="line",asteroid_spawn_definitions={}}
check(M.threat_tier(safe)==1,"Empty asteroid spawns must remain low risk")
check(M.threat_tier(medium)==3,"Medium asteroids should be sage green")
check(M.threat_tier(huge)==5,"Huge asteroids should be muted red")
check(M.threat_tier(belt)==4,"Physical belt crossings need minimum caution")
local blue=M.color_for_route(safe)
local sage=M.color_for_route(medium)
local red=M.color_for_route(huge)
local amber=M.color_for_route(belt)
check(blue.b>blue.r and sage.g>sage.r and red.r>red.g
 and amber.r>amber.b,"Hazard palette must match actual asteroid sizes")
check(M.color_for_route(huge,"chapter")==red,
 "Optional chapter colors must never conceal huge asteroids")
local sheet="__razi-protocol__/graphics/route-highlights/continuous-strokes.png"
local line=M.strokes_for_connection(safe,"danger","all")
check(#line>5 and #line<=64,"Safe interstellar path must be joined and sampled")
for _,s in ipairs(line) do
 check(s.filename==sheet and s.size[1]==128,
  "Stroke must use new compact 64-bearing atlas")
 check(s.x>=0 and s.y>=0 and s.x<=896 and s.y<=896,
  "Atlas tile should fit 1024x1024 texture")
 check(s.scale>0 and s.scale<3 and s.tint.a<=.35,
  "Stroke must stay narrow and subdued")
 check(s.shift[1]==s.shift[1] and s.shift[2]==s.shift[2],
  "No invalid coordinates")
end
local lower=M.strokes_for_connection(medium,"danger","all")
check(#lower>0,"All scope should color valid nearby planetary connections")
check(#M.strokes_for_connection(medium,"danger","major")==0,
 "Major scope must not cover local routes")
local explicit_arc={from="distant-one",to="distant-two",
 shape="arc",origin={x=104,y=0},asteroid_spawn_definitions={}}
local guessed_arc={from="distant-one",to="distant-two",shape="arc",
 asteroid_spawn_definitions={}}
check(#M.strokes_for_connection(explicit_arc,"danger","all")>0,
 "Explicit regional arc must interpolate safely")
check(#M.strokes_for_connection(guessed_arc,"danger","all")==0,
 "Never invent a cross-star arc origin")
local long={from="nauvis",to="odd-world",shape="line",
 asteroid_spawn_definitions={}}
check(#M.strokes_for_connection(long,"danger","all")==0,
 "Long native line must be omitted instead of rendered as dotted leftovers")
check(M.is_navigation_highlight(safe) and
 not M.is_navigation_highlight(medium),
 "Major navigation scope must respect curated corridors")
check(M.is_navigation_highlight(medium,"all"),
 "All scope can display safe real source-owned routes")
for _,name in ipairs({"carna","gleba","velora"}) do
 check(not M.is_navigation_highlight({from=name,to="sye-umbra"},"all"),
  "Old Carna/Gleba/Velora red tail must never return: "..name)
end
check(M.is_navigation_highlight(belt),
 "Real Umbra asteroid corridor remains visible")
raw["space-connection"].major=safe
raw["space-connection"].near=medium
raw["space-connection"].arc=explicit_arc
raw["space-connection"].belt=belt
raw["space-connection"].long=long
local atlas=raw["utility-sprites"].default.starmap_star.layers
check(M.data_final_fixes()==4,
 "All scope should paint all four valid real native paths")
check(atlas[2].tint.a>=.32,"Belt hazard should get priority")
local count=#atlas
check(M.data_final_fixes()==0 and #atlas==count,
 "Multiple data passes cannot stack duplicate overlays")
settings.startup["razi-route-overlay-scope"].value="major"
raw["utility-sprites"].default.starmap_star.layers={
 {filename="__base__/graphics/native-sun.png"}}
check(M.data_final_fixes()==2,
 "Major scope should paint only the Razi interstellar and belt corridors")
settings.startup["razi-route-overlay-mode"].value="off"
raw["utility-sprites"].default.starmap_star.layers={
 {filename="__base__/graphics/native-sun.png"}}
check(M.data_final_fixes()==0,"Off must leave vanilla connections untouched")
settings.startup["razi-route-overlay-mode"].value="danger"
mods["space-route-overlay"]=true
check(M.data_final_fixes()==0,
 "Never double-paint if external overlay is forcibly installed")
print("Razi joined hazard route overlay: all geometry fixtures passed")
