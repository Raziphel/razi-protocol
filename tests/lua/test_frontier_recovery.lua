-- Unit fixture: required Athos and Nulla science must produce an honest
-- late research bridge, with no duplicate labs, cards or prerequisites.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(value,message) if not value then error(message,2) end end
rawset(_G,"mods",{nulla="1.0.2",PlanetAthos="1.1.3"})
local tech={
  ["planet-discovery-nulla"]={
    icon="nulla.png",icon_size=256,
    effects={{type="unlock-space-location",space_location="nulla"}},
    prerequisites={"planet-discovery-aquilo"}
  },
  ["planet-discovery-athos"]={
    effects={{type="unlock-space-location",space_location="athos"}},
    prerequisites={"planet-discovery-vulcanus"}
  },
  ["robotic-science-pack"]={prerequisites={"planet-discovery-nulla"}},
  ["athos-particulates"]={
    prerequisites={"planet-discovery-athos"},
    effects={{type="unlock-recipe",recipe="athos-particulate-powder"}}
  },
  ["razi-outer-frontier-mastery"]={prerequisites={"planet-discovery-vesta"}}
}
local raw={technology=tech,recipe={
  ["athos-particulate-powder"]={
    results={{type="item",name="particulate-science-pack",amount=1}},
    enabled=false
  }
},tool={
  ["particulate-science-pack"]={},
  ["robotic-science-pack"]={},
  ["cryogenic-science-pack"]={}
},lab={
  ["kr-singularity-lab"]={inputs={"cryogenic-science-pack"}}
}}
rawset(_G,"data",{raw=raw,extend=function(self,items)
  for _,item in ipairs(items) do
    check(item.type=="technology","Charter must not fabricate a new lab")
    self.raw.technology[item.name]=item
  end
end})
package.loaded["prototypes.compat.frontier_recovery"]=nil
local recovery=require("prototypes.compat.frontier_recovery")
check(recovery.unlock("athos-particulate-powder")=="athos-particulates",
  "Native Athos science unlocking research must be discovered")
check(recovery.data_final_fixes(),"Valid source worlds must register charter")
local charter=tech["razi-frontier-recovery-charter"]
check(charter and charter.essential and #charter.unit.ingredients==3,
  "Charter must use real science and expose an essential milestone")
check(charter.prerequisites[1]=="planet-discovery-nulla"
  and charter.prerequisites[2]=="planet-discovery-athos"
  and charter.prerequisites[3]=="robotic-science-pack"
  and charter.prerequisites[4]=="athos-particulates",
  "Native source unlock milestones must precede frontier partnership")
local labs=raw.lab["kr-singularity-lab"].inputs
check(#labs==3 and labs[2]=="robotic-science-pack"
  and labs[3]=="particulate-science-pack",
  "Add only science compatibility to the existing high-tier laboratory")
local mastery=tech["razi-outer-frontier-mastery"]
check(#mastery.prerequisites==2 and mastery.prerequisites[2]==charter.name,
  "Outer mastery must follow the joint native science research")
check(recovery.data_final_fixes(),"Repeat data pass should be idempotent")
check(#labs==3 and #mastery.prerequisites==2,
  "Repeated passes must not add lab inputs or duplicate research arrows")
check(#tech["planet-discovery-athos"].prerequisites==1
  and #tech["planet-discovery-nulla"].prerequisites==1,
  "Native planet discovery research must not receive future science")
-- Unsupported upstream science cannot create a false required milestone.
raw.tool["particulate-science-pack"]=nil
tech["razi-frontier-recovery-charter"]=nil
mastery.prerequisites={"planet-discovery-vesta"}
check(not recovery.data_final_fixes(),
  "Missing source science cannot fabricate a valid research chain")
check(#mastery.prerequisites==1,
  "Absent native supplier must never become a campaign blocker")
print("Required frontier recovery: real sources, late lab, idempotence and bootstrap guards passed")
