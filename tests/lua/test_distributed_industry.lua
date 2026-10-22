-- Standalone Factorio 2.1 data-stage fixtures. Never modify a real save.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,msg) if not ok then error(msg,2) end end
local M=require("prototypes.technology.distributed_industry")
local extra={"metallurgic-science-pack","agricultural-science-pack",
 "electromagnetic-science-pack","nuclear-science-pack"}
local function node(parents)
 return {prerequisites=parents or {},unit={count=100,time=30,
  ingredients={{"automation-science-pack",1},
   {"logistic-science-pack",1},{"chemical-science-pack",1}}}}
end
local function fixture()
 local techs={
  ["space-science-pack"]=node(),["rocket-silo"]=node(),
  ["space-platform"]=node(),["robotics"]=node(),
  ["planet-discovery-vulcanus"]=node(),
  ["planet-discovery-gleba"]=node(),
  ["planet-discovery-fulgora"]=node(),
  ["moon-discovery-cerys"]=node(),
  ["metallurgic-science-pack"]=node({"planet-discovery-vulcanus"}),
  ["agricultural-science-pack"]=node({"planet-discovery-gleba"}),
  ["electromagnetic-science-pack"]=node({"planet-discovery-fulgora"}),
  ["nuclear-science-pack"]=node({"moon-discovery-cerys"}),
  ["construction-robotics"]=node({"robotics"}),
  ["logistic-robotics"]=node({"robotics"}),
  ["nuclear-power"]=node({"uranium-processing"}),
  ["uranium-processing"]=node(),
  ["personal-roboport-equipment"]=node({"construction-robotics"}),
  ["logistic-system"]=node({"logistic-robotics"}),
  ["nuclear-fuel-reprocessing"]=node({"nuclear-power"}),
  ["interplanetary-trade-logistics"]=node({"space-platform"})
 }
 local recipes,items={},{}
 for _,pack in ipairs(extra) do
  items[pack]={}
  recipes[pack]={results={{type="item",name=pack,amount=1}}}
 end
 local lab={inputs={"automation-science-pack","logistic-science-pack",
   "chemical-science-pack"}}
 for _,pack in ipairs(extra) do lab.inputs[#lab.inputs+1]=pack end
 return {technology=techs,recipe=recipes,tool=items,
  lab={["lab"]=lab}}
end
local function contains(list,wanted)
 for _,entry in ipairs(list or {}) do
  if (type(entry)=="table" and (entry.name or entry[1]) or entry)==wanted
    then return true end
 end
 return false
end
local raw=fixture()
rawset(_G,"data",{raw=raw})
rawset(_G,"mods",{["planet-express"]=true})
rawset(_G,"settings",{startup={
 ["razi-distributed-technology"]={value=true}
}})
M.data_final_fixes()
for _,spec in ipairs(M.core) do
 local target=raw.technology[spec.tech]
 for _,p in ipairs(spec.parents) do
  check(contains(target.prerequisites,p),
    spec.tech.." missing native planetary prerequisite "..p)
 end
 for _,pack in ipairs(spec.packs) do
  check(contains(target.unit.ingredients,pack),
    spec.tech.." missing research from a real planet "..pack)
 end
end
for _,spec in ipairs(M.optional) do
 for _,p in ipairs(spec.parents) do
  check(contains(raw.technology[spec.tech].prerequisites,p),
    "Installed mod technology did not gain a real system milestone")
 end
end
for _,name in ipairs({"rocket-silo","robotics","space-platform",
 "space-science-pack"}) do
 check(#raw.technology[name].prerequisites==0 and
  #raw.technology[name].unit.ingredients==3,
  "Bootstrap technology was changed: "..name)
end
check(#M.core==2 and M.core[1].tech=="nuclear-power"
  and M.core[2].tech=="nuclear-fuel-reprocessing",
  "Only nuclear technologies may be spread over the planets")
for _,name in ipairs({"construction-robotics","logistic-robotics",
 "personal-roboport-equipment","logistic-system"}) do
 local tech=raw.technology[name]
 check(#tech.unit.ingredients==3 and not contains(tech.prerequisites,
  "planet-discovery-gleba") and not contains(tech.prerequisites,
  "planet-discovery-fulgora") and not contains(tech.prerequisites,
  "planet-discovery-vulcanus"),
  "Robots and logistics must stay on Nauvis: "..name)
end
check(#raw.technology["logistic-system"].prerequisites==1 and
 raw.technology["logistic-system"].prerequisites[1]=="logistic-robotics" and
 #raw.technology["construction-robotics"].prerequisites==1 and
 #raw.technology["logistic-robotics"].prerequisites==1 and
 #raw.technology["personal-roboport-equipment"].prerequisites==1,
 "Robot and logistic prerequisites must stay as in the source")
check(#raw.technology["nuclear-power"].prerequisites==5 and
 #raw.technology["nuclear-power"].unit.ingredients==5,
 "Nuclear power must get four planetary prerequisites and two packs")
local size=#raw.technology["nuclear-power"].unit.ingredients
M.data_final_fixes()
check(#raw.technology["nuclear-power"].unit.ingredients==size,
 "Re-applying a data pass must not duplicate research ingredients")
local safe=fixture()
safe.technology["agricultural-science-pack"].prerequisites={
 "nuclear-power"}
check(not M.apply(safe,M.core[1]),
 "Must not gate nuclear power behind a science producer using it")
check(not contains(safe.technology["nuclear-power"].prerequisites,
 "agricultural-science-pack"),"Failed guard left half the research change")
local missing=fixture()
missing.recipe["metallurgic-science-pack"]=nil
check(not M.apply(missing,M.core[1]),
 "A missing science producer must not gate nuclear power")
local no_lab=fixture()
no_lab.lab["lab"].inputs={
 "automation-science-pack","logistic-science-pack","chemical-science-pack",
 "metallurgic-science-pack"}
check(not M.apply(no_lab,M.core[1]),
 "No research lab may accept an impossible dual-source pack mixture")
local absent=fixture()
absent.technology["planet-discovery-gleba"]=nil
check(not M.apply(absent,M.core[1]),
 "Missing source mod/discovery must not break a vanilla reactor")
local disabled=fixture()
disabled.technology["nuclear-power"].enabled=false
check(not M.apply(disabled,M.core[1]),
 "Disabled native technologies must stay disabled and unmodified")
local trigger=fixture()
trigger.technology["nuclear-power"].research_trigger={type="craft-item",
 item="nuclear-reactor",count=1}
check(not M.apply(trigger,M.core[1]),
 "Native trigger research must not be converted into science units")
local before=fixture()
data.raw=before
settings.startup["razi-distributed-technology"].value=false -- luacheck: ignore 122
M.data_final_fixes()
check(#before.technology["nuclear-power"].prerequisites==1 and
 #before.technology["nuclear-power"].unit.ingredients==3,
 "Legacy startup switch must preserve the original native tech tree")
print("Distributed nuclear, Cerys and modded technologies passed")
