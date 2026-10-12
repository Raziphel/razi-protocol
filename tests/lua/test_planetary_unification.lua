-- Test the final endgame research weave without loading source modpacks.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,msg) if not ok then error(msg,2) end end
local function setup(opts)
 opts=opts or {}
 local techs={
  ["razi-stable-intergalactic-singularity"]={prerequisites={"razi-singularity-test-fire"}},
  ["razi-singularity-test-fire"]={prerequisites={}},
  ["planet-discovery-fulgora"]={prerequisites={}},
  ["moon-discovery-cerys"]={
   prerequisites={"planet-discovery-fulgora"},
   effects={{type="unlock-space-location",space_location="cerys"}}},
  ["native-wit-research"]={
   prerequisites={},
   effects={{type="unlock-space-location",space_location="bm-wit"}}},
  ["native-balack-research"]={
   prerequisites=opts.cycle and {"razi-stable-intergalactic-singularity"} or {},
   effects={{type="unlock-space-location",space_location="bm-balack"}}}
 }
 local raw={
  technology=techs,
  planet={cerys={},["bm-wit"]={},["bm-balack"]={}},
  ["space-location"]={}
 }
 if opts.no_wit then raw.planet["bm-wit"]=nil end
 rawset(_G,"data",{raw=raw})
 package.loaded["prototypes.technology.planetary_unification"]=nil
 return raw,require("prototypes.technology.planetary_unification")
end
local function has(tech,needle)
 for _,t in ipairs(tech.prerequisites or {}) do
  if t==needle then return true end
 end
 return false
end
local raw,m=setup()
m.data_final_fixes()
local finale=raw.technology["razi-stable-intergalactic-singularity"]
check(has(finale,"moon-discovery-cerys"),"Cerys required research omitted")
check(has(finale,"native-wit-research"),"Wit required research omitted")
check(has(finale,"native-balack-research"),"Balack research omitted")
local n=#finale.prerequisites
m.data_final_fixes()
check(#finale.prerequisites==n,"Repeated pass duplicated native tech requirements")
local raw2,m2=setup({cycle=true,no_wit=true})
m2.data_final_fixes()
local e=raw2.technology["razi-stable-intergalactic-singularity"]
check(has(e,"moon-discovery-cerys"),"Independent Cerys discovery removed")
check(not has(e,"native-balack-research"),"Native late branch created a cycle")
check(not has(e,"native-wit-research"),"Missing planet still mandated")
check(#m2.worlds>=35,"Planetary atlas unexpectedly shrank")
print("Native world discovery milestones and cycle protection passed")
