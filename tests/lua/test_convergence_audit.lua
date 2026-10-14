-- Pure Lua regression for the read-only loaded-modpack health check.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,message) if not ok then error(message,2) end end
local defs=require("prototypes.technology.convergence")
local audit=require("scripts.razi_convergence_audit")
local registry={item={},recipe={},entity={
 ["existing-lab"]={type="lab",lab_inputs={
  "beetlejuice-tech-card","umbra-tech-card","deep-space-tech-card"
 }}
}}
registry.item["ds-energy-loader-mk1"]={
 place_result={name="test-receiver"}}
registry.entity["test-receiver"]={type="electric-energy-interface"}
registry.entity["existing-assembler"]={type="assembling-machine",
 crafting_categories={crafting=true},ingredient_count=50}
rawset(_G,"prototypes",registry)
rawset(_G,"storage",{})
local force={name="Audited Force",index=9,technologies={},recipes={},
 get_entity_count=function() return 1 end}
local science={
 {name="beetlejuice-tech-card",amount=1},
 {name="umbra-tech-card",amount=1},
 {name="deep-space-tech-card",amount=1}
}
for _,id in ipairs({defs.commission,defs.authorization,defs.ignition}) do
 force.technologies[id]={name=id,researched=true,enabled=true,
  research_unit_ingredients=science,prerequisites={}}
end
local producers=0
for _,stage in ipairs(defs.shipments) do
 local ingredients={}
 for _,ingredient in ipairs(stage.ingredients) do
  local name=ingredient[1]
  ingredients[#ingredients+1]={type="item",name=name,
   amount=ingredient[2]}
  if not registry.recipe["producer-"..name] then
   registry.recipe["producer-"..name]={
    name="producer-"..name,hidden=false,
    products={{type="item",name=name,amount=1}}}
   producers=producers+1
  end
 end
 force.recipes[stage.item]={name=stage.item,enabled=true,
  categories={"crafting"},ingredients=ingredients}
end
for _,part in ipairs(defs.assemblies or {}) do
 local ingredients={}
 for _,entry in ipairs(part.ingredients) do
  ingredients[#ingredients+1]={type="item",name=entry[1],amount=entry[2]}
 end
 force.recipes[part.item]={name=part.item,enabled=true,
   categories={"crafting"},ingredients=ingredients}
end
local result=audit.inspect(force,registry)
check(result.locked_sources>0 and result.missing_producers==0,
 "Sources that exist but are not researched must not be called missing")
local first_source=defs.shipments[1].ingredients[1][1]
force.recipes["producer-"..first_source]={enabled=true}
local upgraded=audit.inspect(force,registry)
check(upgraded.locked_sources<result.locked_sources,
 "A genuinely unlocked native recipe must lower pending sources")
check(#result.errors==0 and result.stages==5 and result.components==3 and result.labs==1,
 "Correct native science and recipes should have zero blockers")
check(storage.razi_convergence==nil,
 "Inspection must not allocate any persistent save data")
local previous=registry.entity["existing-lab"].lab_inputs
registry.entity["existing-lab"].lab_inputs={"beetlejuice-tech-card"}
local no_lab=audit.inspect(force,registry)
check(#no_lab.errors==3,
 "No single native lab accepting the entire research set must be reported")
registry.entity["existing-lab"].lab_inputs=previous
registry.entity["existing-assembler"].ingredient_count=2
local undersized=audit.inspect(force,registry)
check(#undersized.errors==7,
 "A real recipe needs a native assembler with enough ingredient slots")
registry.entity["existing-assembler"].ingredient_count=50
local component=defs.assemblies[1].item
force.recipes[component].enabled=false
check(#audit.inspect(force,registry).errors==1,
 "Researched but locked new component must be a hard audit blocker")
force.recipes[component].enabled=true
local last=defs.shipments[#defs.shipments].item
force.recipes[last].enabled=false
check(#audit.inspect(force,registry).errors==1,
 "Researched but disabled final freight must be reported")
force.recipes[last].enabled=true
local recipe=force.recipes[last]
force.recipes[last]=nil
check(#audit.inspect(force,registry).errors==1,
 "Missing mandatory recipe must be reported")
force.recipes[last]=recipe
local final=force.technologies[defs.ignition]
local sync=force.technologies[defs.authorization]
final.prerequisites={synchronization=sync}
sync.prerequisites={ignition=final}
local cycle=audit.inspect(force,registry)
check(#cycle.errors==1
 and cycle.errors[1]:find("cycle",1,true),
 "Native technology cycles must not be hidden")
sync.prerequisites={}
final.prerequisites={}
local sample=defs.shipments[1].ingredients[1][1]
registry.recipe["producer-"..sample]=nil
local missing=audit.inspect(force,registry)
check(#missing.errors==0 and missing.missing_producers>0,
 "Recipe-less source goods might be scripted: report advisory only")
check(storage.razi_convergence==nil,
 "Multiple audits should never allocate Convergence save state")
print("Convergence audit: native lab inputs, unlocks, missing producers, cycles and read-only save safety passed")
