-- Data-stage fixtures: absent companions never modify game definitions.
package.path="./?.lua;./?/init.lua;"..package.path
local function ok(value,why) if not value then error(why,2) end end
local integration=require("prototypes.compat.frontier_companions")
local cannon=require("prototypes.compat.orbital_catapult")
local function tech(parents,effects)
 return {prerequisites=parents or {},effects=effects or {},
   unit={count=150,time=30,ingredients={{"automation-science-pack",1}}}}
end
local raw={technology={
 ["nuclear-power"]=tech(),["planet-discovery-aquilo"]=tech(),
 ["planet-discovery-fulgora"]=tech(),["electromagnetic-science-pack"]=tech(),
 ["vespera-tech-card"]=tech(),["beetlejuice-discovery"]=tech(),
 ["beetlejuice-tech-card"]=tech(),
 ["train-fusion-locomotive-mk1"]=tech({},{
   {type="unlock-recipe",recipe="train-fusion-locomotive-mk1"}}),
 ["shield-superconducting-technology"]=tech({},{
   {type="unlock-recipe",recipe="shield-superconducting-recharge"}}),
 ["cargo-bay"]=tech(),["rocket-silo"]=tech(),["space-platform"]=tech()
 },recipe={
 ["vespera-tech-card"]={results={{type="item",name="vespera-tech-card"}}},
 ["electromagnetic-science-pack"]={
   results={{type="item",name="electromagnetic-science-pack"}}}},
 tool={["vespera-tech-card"]={},["electromagnetic-science-pack"]={}},
 lab={lab={inputs={"automation-science-pack","vespera-tech-card",
   "electromagnetic-science-pack"}}}}
rawset(_G,"data",{raw=raw})
rawset(_G,"mods",{})
rawset(_G,"settings",{startup={["razi-companion-science-weave"]={value=true}}})
integration.data_final_fixes()
ok(#raw.technology["train-fusion-locomotive-mk1"].prerequisites==0,
  "Uninstalled mods must not add optional research")
mods["space-age-railway-expansion"]=true
mods["shield-generators"]=true
integration.data_final_fixes()
local function includes(list,name)
 for _,value in ipairs(list) do
  if (type(value)=="table" and (value.name or value[1]) or value)==name
    then return true end
 end
 return false
end
ok(includes(raw.technology["train-fusion-locomotive-mk1"].prerequisites,
  "planet-discovery-aquilo"),"Rail upgrade missing Aquilo research gate")
ok(includes(raw.technology["train-fusion-locomotive-mk1"].unit.ingredients,
  "vespera-tech-card"),"Rail upgrade missing Vespera card")
ok(includes(raw.technology["shield-superconducting-technology"].prerequisites,
  "planet-discovery-fulgora"),"Shield upgrade missing Fulgora gate")
ok(not includes(raw.technology["rocket-silo"].prerequisites,
 "planet-discovery-aquilo"),"Rocket bootstrap must be untouched")
local total=#raw.technology["train-fusion-locomotive-mk1"].unit.ingredients
integration.data_final_fixes()
ok(#raw.technology["train-fusion-locomotive-mk1"].unit.ingredients==total,
 "Reapplying weave duplicated required packs")
settings.startup["razi-companion-science-weave"].value=false
local absent={technology={["experimental-fusion-locomotive"]=tech()}}
data.raw=absent
integration.data_final_fixes()
ok(#absent.technology["experimental-fusion-locomotive"].prerequisites==0,
 "Disabling the weave should preserve upstream research")
ok(#cannon.definitions({planet={muria={},aquilo={}}},false,true)==0,
 "Catapult never registers when uninstalled")
ok(#cannon.definitions({planet={muria={},aquilo={}}},true,false)==0,
 "Catapult never registers without deliberate opt-in")
local links=cannon.definitions({planet={muria={},aquilo={}}},true,true)
ok(#links==2,"Catapult links should be exactly two one-way local lanes")
for _,link in ipairs(links) do
 ok((link.source=="muria" and link.target=="aquilo")
    or (link.source=="aquilo" and link.target=="muria"),
    "Catapult must never shortcut a Razi asteroid belt")
end
ok(#cannon.definitions({planet={muria={}}},true,true)==0,
 "Missing destination cannot create invalid links")
print("Frontier companions: optional research, idempotence and safe catapult links passed")
