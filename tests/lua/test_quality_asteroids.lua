---@diagnostic disable: need-check-nil, undefined-field, assign-type-mismatch
-- luacheck: ignore 122
-- Standalone regression: run with lua5.2 tests/lua/test_quality_asteroids.lua
package.path="./?.lua;./?/init.lua;"..package.path
local function ok(condition,message) if not condition then error(message,2) end end
package.loaded["scripts.galactic_catalog"]={
  system=function(name)
    if name=="nauvis" or name=="muluna" then return "calidus" end
    if name=="sye-vibrant" then return "vibrant" end
    if name=="sye-umbra" then return "umbra" end
    if name=="solar-system-edge" or name=="nexus" then return "deep-space" end
    return "unassigned"
  end
}
local difficulty=require("scripts.razi_asteroid_difficulty")
ok(difficulty.location_level("nauvis")==1,"Nauvis must remain level 1")
ok(difficulty.location_level("solar-system-edge")==10,"Deep Space must be level 10")
ok(difficulty.roll(1,.999)=="normal","Level 1 is always normal")
ok(difficulty.roll(10,0)=="legendary","Level 10 low roll must be legendary")
ok(difficulty.roll(10,.99999)=="legendary","Level 10 must be 100% legendary")
for level,weights in ipairs(difficulty.distributions) do
  local sum=0
  for _,weight in ipairs(weights) do
    ok(weight>=0 and weight<=1,"Out-of-bounds quality probability")
    sum=sum+weight
  end
  ok(math.abs(sum-1)<.00001,"Quality level "..level.." must sum to 1")
end
ok(#difficulty.route_colors==10 and #difficulty.route_color_hex==10,
  "Every asteroid danger level needs a unique route color")
for level=1,10 do
  local c=difficulty.route_color(level)
  local hex=difficulty.route_color_richtext(level)
  ok(c and type(hex)=="string" and hex:sub(1,1)=="#",
    "Quality color or tooltip hex code missing")
end
-- Every main chapter and all late optional worlds have an explicit
-- increasing danger level, not the old one-grade-per-system fallback.
local expected={
  nauvis=1,["sye-solaris"]=2,gleba=2,["sye-nyxaris"]=2,
  vulcanus=2,moshine=3,tellus=4,["sye-vibrant"]=4,
  ribbonia=5,muria=5,rubia=6,["asteroid-belt-outer-edge"]=6,
  aquilo=7,athos=7,["sye-beetlejuice"]=7,
  secretas=8,["sye-umbra"]=8,["crucible-orbit"]=9,vesta=9,
  obsidiax=9,["solar-system-edge"]=10,
  ["calidus-bellicos-stargate-calidus"]=6,
  ["aegis-outer-edge"]=7,["aegis-inner-edge"]=8,["aegis-warden"]=8,
  ["near-bellicos-orbit"]=8,["bellicos-orbit"]=8,
  ["skewer_lost_beyond"]=10,["black-hole-approach"]=10
}
for name,level in pairs(expected) do
  ok(difficulty.location_level(name)==level,
    name.." should be level "..level.." not a low fallback")
end
-- The Aegis approach from the first frontier ends at the gate's level 6 (not
-- above Rubia) and grows monotonically; inside Aegis the danger keeps rising.
for _,origin in ipairs({"sye-solaris","sye-nyxaris"}) do
  local approach={from=origin,to="calidus-bellicos-stargate-calidus",
    length=origin=="sye-solaris" and 112000 or 118000}
  local peak=0
  for _,t in ipairs({0,.1,.2,.3,.4,.5,.6,.7,.8,.9,1}) do
    peak=math.max(peak,difficulty.route_level(approach,t,"balanced"))
  end
  ok(difficulty.route_level(approach,0,"balanced")==2,
    origin.." approach must start at the Solaris/Nyxaris level")
  ok(difficulty.route_level(approach,1,"balanced")==6 and peak<=6,
    origin.." approach must end at level 6 and never exceed it")
end
ok(difficulty.route_level({from="calidus-bellicos-stargate-calidus",
  to="aegis-outer-edge",length=56000},0,"balanced")==6
  and difficulty.route_level({from="calidus-bellicos-stargate-calidus",
  to="aegis-outer-edge",length=56000},1,"balanced")==7,
  "Aegis gate to outer edge must ramp from 6 to 7")
-- Inside Aegis the danger stays at 8: the inner edge opens at the third
-- system gate, before a railgun is guaranteed. Only the mid-journey bump of
-- a long link may rise above that, by less than one level.
for _,link in ipairs({
  {"aegis-outer-edge","aegis-inner-edge",45000,7,8},
  {"bellicos-orbit","aegis-inner-edge",12000,8,8},
  {"aegis-inner-edge","aegis-warden",40000,8,8}
}) do
  local route={from=link[1],to=link[2],length=link[3]}
  local peak=0
  for _,t in ipairs({0,.1,.2,.3,.4,.5,.6,.7,.8,.9,1}) do
    peak=math.max(peak,difficulty.route_level(route,t,"balanced"))
  end
  ok(difficulty.route_level(route,0,"balanced")==link[4]
    and difficulty.route_level(route,1,"balanced")==link[5],
    link[1].." to "..link[2].." must run from level "..link[4].." to "..link[5])
  ok(peak<=9,link[1].." to "..link[2].." must stay below danger 9")
end
for _,name in ipairs({"point-warden","aegis-pulsar-variant"}) do
  ok(difficulty.location_level(name)==8,
    name.." must fall back to the inner Aegis level 8")
end
local unknown={
  a={from="sye-umbra",to="modded-late-moon"},
  b={from="modded-late-moon",to="modded-final-outpost"},
  c={from="modded-home-moon",to="nauvis"}
}
difficulty.prepare_routes(unknown)
ok(difficulty.location_level("modded-late-moon")==8,
  "Remote modded world should inherit Umbra's endgame danger")
ok(difficulty.location_level("modded-final-outpost")==8,
  "Second-generation late source moon should not reset to level 4")
ok(difficulty.location_level("modded-home-moon")==1,
  "Modded home moon should inherit Calidus safe tier")
difficulty.prepare_routes({})
ok(difficulty.location_level("modded-late-moon")==4,
  "Rebuilding the live graph must clear stale inferred worlds")

local route={from="nauvis",to="sye-vibrant",length=50000}
local beginning=difficulty.route_level(route,0,"balanced")
local center=difficulty.route_level(route,.5,"balanced")
local ending=difficulty.route_level(route,1,"balanced")
ok(beginning==1 and center>beginning and ending==4,
  "Danger must ramp during travel and match destination")
ok(difficulty.route_level({from="nauvis",to="muluna",length=8000},.5)==1,
  "Early shuttle cannot get forced higher quality")
local umbra={from="razi-umbra-belt-inner",to="razi-umbra-belt-outer",length=5000}
ok(difficulty.route_level(umbra,.5,"balanced")>9,
  "Umbra inner belt must exceed level 9 at its midpoint")
local deep={from="solar-system-edge",to="nexus",length=2000000}
ok(difficulty.route_level(deep,.5,"balanced")==10,
  "Deep Space route must reach level 10")
ok(difficulty.route_level(route,.5,"relentless")>center,
  "Optional challenge setting should work")
for _,t in ipairs({0,.01,.2,.5,.9,1}) do
  ok(difficulty.roll(10,t)=="legendary",
    "Legendary guarantee must hold at all roll endpoints")
end

local definitions={
  {type="entity",asteroid="big-metallic-asteroid",
    spawn_points={{distance=.1,probability=.2,speed=.015},
      {distance=.5,probability=.3,speed=.025}}},
  {type="asteroid-chunk",asteroid="metallic-asteroid-chunk",
    spawn_points={{distance=.5,probability=.12,speed=.035}}}
}
local chunk=definitions[2]
local raw={asteroid={
  ["big-metallic-asteroid"]={type="asteroid",name="big-metallic-asteroid",
    icon="__space-age__/test.png",icon_size=64},
},["space-connection"]={frontier={
  from="solar-system-edge",to="nexus",length=250000,hidden=false,
  asteroid_spawn_definitions=definitions
}},planet={nauvis={asteroid_spawn_definitions={
  {type="entity",asteroid="big-metallic-asteroid",probability=.04}
}}}}
rawset(_G,"data",{raw=raw,extend=function(self,items)
  for _,item in ipairs(items) do self.raw[item.type][item.name]=item end
end})
rawset(_G,"settings",{startup={
  ["razi-quality-asteroids"]={value=true},
  ["razi-asteroid-difficulty-scale"]={value="balanced"}
}})
rawset(_G,"mods",{})
local conversion=require("prototypes.system.quality_asteroids")
-- A disabled setting must stay disabled: no carriers and no rewritten spawns.
settings.startup["razi-quality-asteroids"].value=false
ok(conversion.data_final_fixes()==0,"Disabled setting must not convert anything")
ok(raw["space-connection"].frontier.asteroid_spawn_definitions==definitions
  and definitions[1].asteroid=="big-metallic-asteroid",
  "Disabled setting must leave spawn tables untouched")
ok(raw.asteroid["razi-quality-asteroid-big-metallic-asteroid"]==nil,
  "Disabled setting must not create carrier prototypes")
-- A missing setting falls back to the default, which is on.
settings.startup["razi-quality-asteroids"]=nil -- luacheck: ignore 122
ok(conversion.data_final_fixes()==1,"Missing setting must default to on; only Deep Space hostile spawn is rewritten")
local adjusted=raw["space-connection"].frontier.asteroid_spawn_definitions
ok(adjusted[1].asteroid=="razi-quality-asteroid-big-metallic-asteroid",
  "Native hostile must use trigger carrier")
ok(adjusted[2]==chunk,"Resource chunk must remain untouched")
ok(definitions[1].asteroid=="big-metallic-asteroid",
  "Original shared spawn table must not be modified")
ok(raw.planet.nauvis.asteroid_spawn_definitions[1].asteroid=="big-metallic-asteroid",
  "Calidus location must be untouched")
ok(raw.asteroid[adjusted[1].asteroid].created_effect.action_delivery
  .target_effects.effect_id==adjusted[1].asteroid,
  "Carrier must invoke exactly its own effect id")
ok(conversion.data_final_fixes()==0,"Conversion must be idempotent")

local called,removed=nil,false
local platform={space_connection={
  from={name="solar-system-edge"},to={name="nexus"},length=250000},distance=.5}
local surface={platform=platform}
surface.create_entity=function(options)
  called=options
  return {valid=true}
end
local source={name="razi-quality-asteroid-big-metallic-asteroid",
  valid=true,position={x=10,y=20},direction=3,force="neutral",surface=surface}
source.destroy=function() removed=true;source.valid=false end
rawset(_G,"prototypes",{quality={
  normal={},uncommon={},rare={},epic={},legendary={}
}})
local runtime=require("scripts.razi_quality_asteroids")
local info=runtime.route_metadata(platform.space_connection)
ok(info.from=="solar-system-edge" and info.to=="nexus"
  and runtime.route_metadata(platform.space_connection)==info,
  "Asteroid hot path should reuse identical route descriptors")
runtime.on_script_trigger_effect({effect_id="other-mod-script",
  source_entity=source})
ok(called==nil,"Unrelated scripted events must not be intercepted")
runtime.on_script_trigger_effect({effect_id=source.name,source_entity=source})
ok(called and called.name=="big-metallic-asteroid"
  and called.quality=="legendary" and removed,
  "Deep Space carrier must become one genuine legendary asteroid")
ok(called.position.x==10 and called.direction==3,
  "Replacement must preserve trajectory and origin")
print("Razi quality-asteroid ten-level ladder passed")
