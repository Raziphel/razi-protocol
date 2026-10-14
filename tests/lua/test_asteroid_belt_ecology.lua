-- Razi's first-party asteroid belts must be valuable, dangerous and safe to merge.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(x,msg) if not x then error(msg,2) end end
local util={
 nauvis_fulgora={},gleba_aquilo={},fulgora_aquilo={},
 aquilo_solar_system_edge={},
 spawn_definitions=function()
  return {
   {type="asteroid-chunk",asteroid="metallic-asteroid-chunk",
    spawn_points={{distance=0.1,probability=.007,speed=.04},
      {distance=.9,probability=.007,speed=.04}}},
   {type="entity",asteroid="medium-oxide-asteroid",
    spawn_points={{distance=.5,probability=.02,speed=.015}}},
   {type="asteroid-chunk",asteroid="modded-rare-asteroid-chunk",
    spawn_points={{distance=.3,probability=.18,speed=.02}}}
  }
 end
}
package.loaded["__space-age__.prototypes.planet.asteroid-spawn-definitions"]=util
package.loaded["prototypes.system.asteroid_profiles"]=nil
package.loaded["prototypes.system.belt_expeditions"]=nil
local raw={["asteroid-chunk"]={
 ["metallic-asteroid-chunk"]={},["oxide-asteroid-chunk"]={},
 ["carbonic-asteroid-chunk"]={}},["space-location"]={},
 ["space-connection"]={},planet={},asteroid={}}
rawset(_G,"data",{raw=raw})
local profiles=require("prototypes.system.asteroid_profiles")
local all={}
for _,system in ipairs({"vibrant","vespera","umbra"}) do
 local rim=profiles.belt_edge_resources(1.3,system)
 check(#rim==3,"Each installed rim must expose three native ore types")
 for _,def in ipairs(rim) do
  check(def.type=="asteroid-chunk" and def.probability>0,
   "Safe rim should never generate a combat asteroid")
 end
 all[system]={}
 for _,entry in ipairs(rim) do all[system][entry.asteroid]=entry.probability end
end
check(all.vibrant["metallic-asteroid-chunk"]>
 all.vibrant["carbonic-asteroid-chunk"],"Vibrant needs metallic enrichment")
check(all.vespera["oxide-asteroid-chunk"]>
 all.vespera["metallic-asteroid-chunk"],"Vespera needs oxide enrichment")
check(all.umbra["carbonic-asteroid-chunk"]>
 all.umbra["metallic-asteroid-chunk"],"Umbra needs carbonic enrichment")
local missing=raw["asteroid-chunk"]["oxide-asteroid-chunk"]
raw["asteroid-chunk"]["oxide-asteroid-chunk"]=nil
check(#profiles.belt_edge_resources(1,"vespera")==2,
 "Optional missing chunk prototype must be skipped")
raw["asteroid-chunk"]["oxide-asteroid-chunk"]=missing

local function lookup(route,id)
 for _,def in ipairs(route.asteroid_spawn_definitions or {}) do
  if def.asteroid==id then return def end
 end
end
local function sample_at(def,distance)
 for _,point in ipairs(def.spawn_points or {}) do
  if math.abs(point.distance-distance)<.0001 then return point.probability end
 end
end
local shared=util.spawn_definitions()
local custom=shared[3]
local original=shared[1].spawn_points
local reference={asteroid_spawn_definitions=shared}
local crossing={asteroid_spawn_definitions=shared}
check(profiles.enrich_belt_crossing(crossing,"vespera"),
 "Existing Vespera crossing should be enriched")
check(crossing.asteroid_spawn_definitions~=shared and
 shared[1].spawn_points==original and
 lookup(reference,"metallic-asteroid-chunk").spawn_points==original,
 "Never mutate a neighboring route sharing native asteroid tables")
check(lookup(crossing,"modded-rare-asteroid-chunk")==custom and
 custom.spawn_points[1].probability==.18,
 "Custom asteroid source definition must remain byte-for-byte")
local oxide=lookup(crossing,"oxide-asteroid-chunk")
check(oxide and sample_at(oxide,.5)>sample_at(oxide,.05),
 "Dangerous mid-belt oxide seam should be richer than the approach")
check(lookup(crossing,"metallic-asteroid-chunk").spawn_points~=original,
 "Existing vanilla chunk definition needs a detached midpoint curve")
local old=oxide
check(not profiles.enrich_belt_crossing(crossing,"vespera") and
 lookup(crossing,"oxide-asteroid-chunk")==old,
 "Reapplying belt logic may not stack resource probabilities")

local function pair(a,b)
 if a>b then a,b=b,a end
 return a.."|"..b
end
package.loaded["prototypes.system.route_reconcile"]={pair_key=pair}
local names={
 {"vibrant","asteroid-belt-inner-edge","asteroid-belt-outer-edge"},
 {"vespera","razi-vespera-belt-inner","razi-vespera-belt-outer"},
 {"umbra","razi-umbra-belt-inner","razi-umbra-belt-outer"}
}
for _,entry in ipairs(names) do
 raw["space-location"][entry[2]]={}
 raw["space-location"][entry[3]]={}
 raw["space-connection"][entry[1]]={
  name=entry[1],from=entry[2],to=entry[3],
  asteroid_spawn_definitions=util.spawn_definitions()
 }
end
local finale=require("prototypes.system.belt_expeditions")
local status=finale.data_final_fixes()
for _,entry in ipairs(names) do
 check(status[entry[1]],"Missing final curated crossing for "..entry[1])
 local route=raw["space-connection"][entry[1]]
 local rich=lookup(route,entry[1]=="umbra" and
  "carbonic-asteroid-chunk" or entry[1]=="vespera" and
  "oxide-asteroid-chunk" or "metallic-asteroid-chunk")
 check(rich and sample_at(rich,.5)>sample_at(rich,.05),
  "Distinct central harvesting field missing for "..entry[1])
end
raw["space-connection"]["umbra"]=nil
check(finale.data_final_fixes().umbra==false,
 "Missing physical crossing must not fabricate another route")
print("Three Razi native belt ecologies, route preservation and idempotence passed")
