package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,message) if not ok then error(message,2) end end
local tools,recipes,technologies,labs={},{},{},{}
local assemblers={native={crafting_categories={"crafting"},ingredient_count=6}}
local cards={"calidus-tech-card","solaris-tech-card",
 "nyxaris-tech-card","vibrant-tech-card","vespera-tech-card",
 "beetlejuice-tech-card","umbra-tech-card","deep-space-tech-card"}
for _,id in ipairs(cards) do
 tools[id]={icon="__base__/graphics/icons/lab.png",icon_size=64}
 recipes[id]={enabled=false,results={{type="item",name=id,amount=1}}}
end
local items={}
for _,id in ipairs({"processing-unit","low-density-structure",
 "kr-rare-metals","bioflux","holmium-plate","optical-cable",
 "craptonite-frame","promethium-science-pack"}) do
 items[id]={}
 recipes[id]={enabled=false,results={{type="item",name=id,amount=1}}}
end
for _,id in ipairs({"stellar-discovery-solar-system-edge",
 "razi-intergalactic-transceiver-signal","slp-dyson-sphere",
 "discovery-aegis-outer"}) do
 technologies[id]={prerequisites={}}
end
labs["kr-singularity-lab"]={inputs={"beetlejuice-tech-card","umbra-tech-card"}}
labs["omega-lab"]={inputs={"beetlejuice-tech-card","umbra-tech-card",
 "deep-space-tech-card"}}
rawset(_G,"data",{raw={item=items,tool=tools,recipe=recipes,
 technology=technologies,lab=labs,["assembling-machine"]=assemblers,
 ["item-subgroup"]={}}})
function data:extend(entries)
 for _,proto in ipairs(entries) do
  self.raw[proto.type]=self.raw[proto.type] or {}
  check(not self.raw[proto.type][proto.name],"duplicate "..proto.name)
  self.raw[proto.type][proto.name]=proto
 end
end
local m=require("prototypes.technology.convergence")
m.data_final_fixes()
local commission=assert(technologies[m.commission])
local ending=assert(technologies[m.authorization])
local ignition=assert(technologies[m.ignition])
check(ending.prerequisites[1]==m.commission,"final research needs opening")
check(#commission.effects==2 and #ending.effects==2
 and #ignition.effects==4,
 "Deep Space and Pulsar mandates require Synchronization; the final accord requires Ignition")
check(ignition.prerequisites[1]==m.authorization,
 "Ignition research must follow Synchronization")
local function has(table_,val)
 for _,v in ipairs(table_) do if v==val then return true end end
end
check(has(commission.prerequisites,"slp-dyson-sphere"),"Dyson preparation")
check(has(commission.prerequisites,"discovery-aegis-outer"),"Aegis expedition")
for _,r in ipairs(m.shipments) do
 check(items[r.item] and recipes[r.item],"missing manifest "..r.item)
 check(recipes[r.item].subgroup=="razi-convergence-mandates",
  "Each Mandate must appear in the dedicated manufacturing group")
 check(#recipes[r.item].ingredients<=6,
  "Every Mandate must fit an existing six-input assembler")
 local art=r.id=="industry" and "industrial" or r.id
 check(items[r.item].icon=="__razi-protocol__/graphics/icons/convergence/"..art..".png",
  "Each Mandate must use its original icon asset")
 check(recipes[r.item].allow_productivity==false,
  "Productivity may duplicate the required freight")
 check(recipes[r.item].auto_recycle==false,
  "Recycling manifest must not mint refunded science")
 for _,part in ipairs(r.ingredients) do
  check(items[part[1]] or tools[part[1]],"missing native supplier")
 end
end
m.data_final_fixes()
check(#commission.effects==2 and #ending.effects==2
 and #ignition.effects==4,
 "Idempotent research recipe unlock registration")
-- Without Nexus Omega Lab the final authorization falls back to existing
-- singularity labs, but the physical Deep Space cards stay mandatory.
technologies[m.commission]=nil
technologies[m.authorization]=nil
technologies[m.ignition]=nil
for _,rule in ipairs(m.shipments) do
 items[rule.item]=nil
 recipes[rule.item]=nil
end
for _,part in ipairs(m.assemblies) do
 items[part.item]=nil
 recipes[part.item]=nil
end
labs["omega-lab"]=nil
m.data_final_fixes()
local fallback=assert(technologies[m.authorization],
  "No-Nexus pack lost its Synchronization research")
local last=assert(technologies[m.ignition],
  "No-Nexus pack lost its final Ignition research")
check(#fallback.unit.ingredients==2,
  "Nexus-free lab fallback should use two installed outer cards")
check(#recipes[m.shipments[3].item].ingredients>=3
 and #recipes[m.shipments[5].item].ingredients==3,
 "Nexus-free finale must craft one accord from three assemblies")
local system_cards={}
for _,part in ipairs(m.assemblies) do
 local recipe=assert(recipes[part.item],"No-Nexus pack lost ignition component")
 check(#recipe.ingredients<=6,"Ignition component exceeds native slots")
 for _,input in ipairs(recipe.ingredients) do
  if input.name:find("tech-card",1,true) then
   system_cards[input.name]=true
  end
 end
end
for _,card in ipairs(cards) do
 check(system_cards[card],"Ignition lost mandatory system card "..card)
end
check(#last.unit.ingredients==2,
 "Ignition must be researchable without a Nexus Omega Lab")
print("Convergence prototypes: source goods, native labs, no-Nexus fallback passed")
