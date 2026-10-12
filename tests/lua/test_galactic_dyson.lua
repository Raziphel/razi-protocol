package.path="./?.lua;./?/init.lua;"..package.path
local function check(x,m) if not x then error(m,2) end end
local m=require("scripts.galactic_dyson")
local t={}
for i,v in ipairs(m.stages) do
 t[v[1]]={researched=i<3,name=v[1],localised_name=v[1]}
end
local done,total,pending=m.status({technologies=t})
check(done==2 and total==6 and #pending==6,
 "Stellar Works progress counter incorrect")
local empty_done,empty_total,empty=m.status({technologies={}})
check(empty_done==0 and empty_total==0 and #empty==0,
 "Missing source mod must yield an empty but safe UI")
local catalog=require("scripts.galactic_catalog")
check(catalog.system("nauvis")=="calidus","Native Nauvis classification changed")
print("Read-only Dyson UI progress and missing-source fallback passed")

check(m.research_phase(0)=="survey" and m.research_phase(2)=="plasma"
 and m.research_phase(3)=="construction"
 and m.research_phase(4)=="distribution"
 and m.research_phase(6)=="mastery",
 "Research-phase art is not mapping native milestones")
