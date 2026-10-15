package.path="./?.lua;./?/init.lua;"..package.path
dofile("tests/lua/razi_lib_bootstrap.lua")
local function check(ok,why) if not ok then error(why,2) end end
local labs={
 lab={inputs={"automation-science-pack","solaris-tech-card"}},
 ["biolab"]={inputs={"automation-science-pack"}},
 ["kr-advanced-lab"]={inputs={"automation-science-pack",
   "chemical-science-pack","deep-space-tech-card"}},
 ["thermodynamics-lab"]={inputs={"automation-science-pack",
   "chemical-science-pack","vibrant-tech-card"}},
 ["kr-singularity-lab"]={inputs={"automation-science-pack",
   "chemical-science-pack","beetlejuice-tech-card"}},
 ["omega-lab"]={inputs={"automation-science-pack",
   "chemical-science-pack"}}
}
local items={}
local tools={}
for _,name in ipairs({"calidus-tech-card","solaris-tech-card",
 "nyxaris-tech-card","vibrant-tech-card","vespera-tech-card",
 "beetlejuice-tech-card","umbra-tech-card","deep-space-tech-card"}) do
 tools[name]={}
end
for _,name in ipairs({"optical-cable","holmium-plate",
 "kr-energy-control-unit"}) do items[name]={} end
local techs={
 ["thermodynamics-research"]={effects={{
  type="unlock-recipe",recipe="thermodynamics-lab"}},
  prerequisites={"optical-cable-research"}},
 ["optical-cable-research"]={effects={{
  type="unlock-recipe",recipe="optical-cable"}}},
 ["kr-singularity-lab-research"]={effects={{
  type="unlock-recipe",recipe="kr-singularity-lab"}},
  prerequisites={"holmium-research","controller-research"}},
 ["holmium-research"]={effects={{
  type="unlock-recipe",recipe="holmium-plate"}}},
 ["controller-research"]={effects={{
  type="unlock-recipe",recipe="kr-energy-control-unit"}}},
 ["mixed-vibrant-research"]={unit={ingredients={{
  "vibrant-tech-card",1},{"chemical-science-pack",1}}}
 }
}
local recipes={
 ["thermodynamics-lab"]={enabled=false,ingredients={{
   type="item",name="lab",amount=1}}},
 ["kr-singularity-lab"]={enabled=false,ingredients={{
   type="item",name="lab",amount=2}}},
 ["optical-cable"]={enabled=false,results={{name="optical-cable",amount=1}}},
 ["holmium-plate"]={enabled=false,results={{name="holmium-plate",amount=1}}},
 ["kr-energy-control-unit"]={enabled=false,results={{name="kr-energy-control-unit",amount=1}}}
}
rawset(_G,"data",{raw={lab=labs,technology=techs,
 item=items,tool=tools,recipe=recipes}})
local module=require("prototypes.compat.system_card_laboratories")
module.data_final_fixes()
local function contains(lab,input)
 for _,name in ipairs(lab.inputs) do if name==input then return true end end
 return false
end
check(not data.raw.item["razi-frontier-lab"],"No fabricated item")
check(not data.raw.lab["razi-astral-lab"],"No fabricated lab")
check(not contains(labs.lab,"solaris-tech-card"),
 "Basic laboratory must stop at Calidus")
check(not contains(labs["kr-advanced-lab"],"vibrant-tech-card"),
 "Advanced lab must not swallow the mid-tier")
check(contains(labs["thermodynamics-lab"],"vibrant-tech-card"),
 "Moshine's native lab handles middle system cards")
check(contains(labs["kr-singularity-lab"],"beetlejuice-tech-card"),
 "Native singularity lab handles the outer frontier")
check(contains(labs["omega-lab"],"deep-space-tech-card"),
 "Existing omega lab handles deep space")
check(#recipes["thermodynamics-lab"].ingredients==2,
 "Real supplier can improve a native lab recipe")
check(#recipes["kr-singularity-lab"].ingredients==3,
 "Both proven native materials should enrich the singularity lab")
local n=#recipes["kr-singularity-lab"].ingredients
module.data_final_fixes()
check(#recipes["kr-singularity-lab"].ingredients==n,
 "No duplicate recipe ingredients")
local unsafe={enabled=false,ingredients={{type="item",name="lab",amount=1}}}
recipes["kr-singularity-lab"]=unsafe
techs["kr-singularity-lab-research"].prerequisites={}
module.data_final_fixes()
check(#unsafe.ingredients==1,
 "Never add a supplier unlocked only after the source lab")
print("Native labs: tiered inputs, real upstream recipes and no new entities passed")
