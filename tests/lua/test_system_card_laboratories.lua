-- Razi labs must form a craftable upgrade chain without rewriting
-- native planet-specific science, and must preserve combined research.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,msg) if not ok then error(msg,2) end end
local function clone(v)
 if type(v)~="table" then return v end
 local t={}
 for k,x in pairs(v) do t[k]=clone(x) end
 return t
end
table.deepcopy=clone
local labs={
 lab={type="lab",name="lab",inputs={"automation-science-pack"},
  minable={mining_time=.2,result="lab"},energy_usage="60kW"},
 ["kr-advanced-lab"]={name="kr-advanced-lab",
  inputs={"automation-science-pack","chemical-science-pack"}},
 ["kr-singularity-lab"]={name="kr-singularity-lab",
  inputs={"automation-science-pack","chemical-science-pack",
    "promethium-science-pack"}},
 biolab={name="biolab",inputs={"automation-science-pack"}},
 ["omega-lab"]={name="omega-lab",
  inputs={"automation-science-pack","promethium-science-pack"}}
}
local tools={}
for _,name in ipairs({"calidus-tech-card","solaris-tech-card",
  "nyxaris-tech-card","vibrant-tech-card","vespera-tech-card",
  "beetlejuice-tech-card","umbra-tech-card","deep-space-tech-card"}) do
 tools[name]={icon="__base__/graphics/icons/lab.png",icon_size=64}
end
local techs={}
for _,id in ipairs({"space-science-pack","solaris-discovery",
  "nyxaris-discovery","vibrant-discovery","vespera-discovery",
  "beetlejuice-discovery","umbra-discovery"}) do techs[id]={} end
techs["test-science-combination"]={
 unit={ingredients={{"vibrant-tech-card",1},{"chemical-science-pack",1}}}}
techs["test-early-frontier"]={
 unit={ingredients={{"calidus-tech-card",1},{"automation-science-pack",1}}}}
local items={lab={type="item",name="lab",icon="__base__/graphics/icons/lab.png",
 icon_size=64,subgroup="production-machine"}}
for _,id in ipairs({"processing-unit","low-density-structure",
 "kr-rare-metals","bioflux","optical-cable","holmium-plate",
 "kr-energy-control-unit","craptonite-frame","rare-earth-powder",
 "supermagnet"}) do items[id]={} end
local raw={lab=labs,tool=tools,item=items,technology=techs,recipe={}}
rawset(_G,"data",{raw=raw})
function data:extend(objects)
 for _,proto in ipairs(objects) do
  local kind=assert(self.raw[proto.type])
  check(not kind[proto.name],"Duplicate prototype "..proto.name)
  kind[proto.name]=proto
 end
end
local module=require("prototypes.compat.system_card_laboratories")
module.data_final_fixes()
local tiers={
 ["lab"]={"calidus-tech-card"},
 ["razi-frontier-lab"]={"solaris-tech-card","nyxaris-tech-card"},
 ["razi-constellation-lab"]={"vibrant-tech-card","vespera-tech-card"},
 ["razi-astral-lab"]={"beetlejuice-tech-card","umbra-tech-card"},
 ["razi-deep-space-lab"]={"deep-space-tech-card"}
}
local function has(lab,pack)
 for _,name in ipairs(lab.inputs) do if name==pack then return true end end
 return false
end
check(not has(labs.lab,"solaris-tech-card"),"Base lab bypasses frontier")
check(not has(labs["kr-advanced-lab"],"vibrant-tech-card"),
  "Native advanced lab bypasses constellation research")
check(not has(labs["kr-singularity-lab"],"deep-space-tech-card"),
  "Native singularity lab unexpectedly accepts endgame card")
for lab,packlist in pairs(tiers) do
 for _,pack in ipairs(packlist) do
  check(has(assert(labs[lab]),pack),
   "Laboratory "..lab.." does not support "..pack)
 end
end
for _,step in ipairs(module.steps) do
 check(raw.recipe[step.id] and techs[step.id] and items[step.id],
  "Missing buildable laboratory tier "..step.id)
 check(techs[step.id].effects[1].recipe==step.id,
  "Laboratory recipe not unlocked")
 check(#raw.recipe[step.id].ingredients==#step.materials,
  "Native freight materials not retained")
end
check(has(labs["razi-constellation-lab"],"chemical-science-pack"),
 "Tier 3 must preserve native science compatibility")
check(has(labs["razi-constellation-lab"],"vibrant-tech-card"),
 "Tier 3 cannot research a mixed native science target")
check(not has(labs.lab,"deep-space-tech-card"),
 "Coverage fallback must not unlock Deep Space in the starter lab")
check(has(labs["omega-lab"],"automation-science-pack"),
 "Native input unrelated to Razi must be preserved")
print("Razi labs: tier progression, production, legacy research coverage passed")
