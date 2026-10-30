-- Regression: source-owned optional-world research must not inherit finale science.
package.path = "./?.lua;./?/init.lua;" .. package.path
local function check(value, message)
  if not value then error(message, 2) end
end
local tech = {
  ["vespera-discovery"]={},
  ["solaris-discovery"]={},["nyxaris-discovery"]={},
  ["beetlejuice-discovery"]={prerequisites={"vespera-discovery"}},
  ["stellar-discovery-solar-system-edge"]={prerequisites={"beetlejuice-discovery"}},
  ["planet-discovery-aquilo"]={prerequisites={"vespera-discovery"}},
  ["planet-discovery-paracelsin"]={prerequisites={"vespera-discovery"}},
  ["planet-discovery-ribbonia"]={prerequisites={"vespera-discovery"}},
  ["planet-discovery-khemia"]={
    prerequisites={"planet-discovery-paracelsin","space-discovery-asteroid-belt","automation-3"},
    effects={{type="unlock-space-location",space_location="alchemy-planet"}},
    unit={count=650,time=30,ingredients={{"space-science-pack",2}}}
  },
  ["promethium-science-pack"]={prerequisites={"stellar-discovery-solar-system-edge"}},
  ["discovery-aegis-outer"]={
    prerequisites={"stellar-discovery-solar-system-edge"},
    effects={{type="unlock-space-location",space_location="aegis-outer-edge"}}
  },
  ["discovery-aegis-inner"]={
    prerequisites={"discovery-aegis-outer"},
    effects={{type="unlock-space-location",space_location="aegis-inner-edge"}}
  },
  ["bm-planet-discovery-balack"]={
    prerequisites={"promethium-science-pack","automation-3"},
    effects={{type="unlock-space-location",space_location="bm-balack"}},
    unit={count=1000,time=60,ingredients={
      {"cryogenic-science-pack",1},
      {"promethium-science-pack",2},
      {"automation-science-pack",1}
    }}
  },
  ["bm-ai-control-unit"]={
    prerequisites={"bm-planet-discovery-balack"},
    unit={ingredients={{"promethium-science-pack",1}}}
  },
  ["planet-discovery-shchierbin"]={
    prerequisites={"vespera-discovery"},
    effects={{type="unlock-space-location",space_location="shchierbin"}}
  }
}
rawset(_G,"data",{raw={technology=tech,planet={["bm-balack"]={},shchierbin={},["alchemy-planet"]={}},
  ["space-location"]={["calidus-bellicos-stargate-calidus"]={}},
  tool={["cryogenic-science-pack"]={}}}})
rawset(_G,"mods",{["Krastorio2-spaced-out"]="2.1.0",
  ["bellicos-and-aegis"]="0.4.1"})
package.loaded["prototypes.compat.planet_arrival_pacing"]=nil
local module=require("prototypes.compat.planet_arrival_pacing")
module.data_final_fixes()
local function has(name,parent)
  for _, candidate in ipairs(tech[name].prerequisites or {}) do
    if candidate==parent then return true end
  end
  return false
end
local balack=tech["bm-planet-discovery-balack"]
check(has("bm-planet-discovery-balack","planet-discovery-aquilo"),
  "Balack must require Aquilo")
check(not has("bm-planet-discovery-balack","promethium-science-pack"),
  "Balack discovery must not depend on finale Promethium tech")
check(has("bm-planet-discovery-balack","automation-3"),
  "Balack native industrial research should survive")
local cryogenic,promethium=0,0
for _, ingredient in ipairs(balack.unit.ingredients) do
  if ingredient[1]=="cryogenic-science-pack" then
    cryogenic=cryogenic+1
    check(ingredient[2]==2,"Balack replacement should retain greatest quantity")
  end
  if ingredient[1]=="promethium-science-pack" then promethium=promethium+1 end
end
check(cryogenic==1 and promethium==0,"Promethium replacement duplicated or failed")
check(tech["bm-ai-control-unit"].unit.ingredients[1][1]=="promethium-science-pack",
  "Post-Balack native equipment science was changed")
check(has("discovery-aegis-outer","solaris-discovery") and
  has("discovery-aegis-outer","nyxaris-discovery") and
  not has("discovery-aegis-outer","vespera-discovery") and
  not has("discovery-aegis-outer","stellar-discovery-solar-system-edge"),
  "Aegis requires both first frontiers, without a later-system gate")
local native_gate=false
for _,effect in ipairs(tech["discovery-aegis-outer"].effects or {}) do
  if effect.type=="unlock-space-location" and
    effect.space_location=="calidus-bellicos-stargate-calidus" then
    native_gate=true
  end
end
check(native_gate,"Shared Aegis survey must unlock its native entry stargate")
check(has("discovery-aegis-inner","beetlejuice-discovery"),
  "The deeper Bellicos expedition must require tier three")
check(has("planet-discovery-shchierbin","planet-discovery-paracelsin"),
  "Shchierbin must follow exterior Paracelsin")
check(has("planet-discovery-khemia","planet-discovery-ribbonia")
  and not has("planet-discovery-khemia","planet-discovery-paracelsin")
  and not has("planet-discovery-khemia","space-discovery-asteroid-belt")
  and has("planet-discovery-khemia","automation-3"),
  "Inner Khemia cannot be gated behind exterior Paracelsin or the belt")
check(tech["planet-discovery-khemia"].unit.count==650
  and tech["planet-discovery-khemia"].effects[1].space_location=="alchemy-planet",
  "Do not replace native alchemy research costs or unlocks")
module.data_final_fixes()
local seen={}
for _, ingredient in ipairs(balack.unit.ingredients) do
  check(not seen[ingredient[1]],"Repeated reconciliation duplicated science")
  seen[ingredient[1]]=true
end
local khemia_ribbonia=0
for _,parent in ipairs(tech["planet-discovery-khemia"].prerequisites) do
  if parent=="planet-discovery-ribbonia" then khemia_ribbonia=khemia_ribbonia+1 end
end
check(khemia_ribbonia==1,"Repeated pass duplicated Khemia's Ribbonia prerequisite")
local parent_counts={}
for _, parent in ipairs(tech["discovery-aegis-inner"].prerequisites) do
  parent_counts[parent]=(parent_counts[parent] or 0)+1
  check(parent_counts[parent]==1,"Repeated reconciliation duplicated tech parent")
end
print("Optional world arrival pacing tests passed")
