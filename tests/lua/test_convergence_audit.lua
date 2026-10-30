-- Pure Lua regression for the read-only loaded-modpack health check.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,message) if not ok then error(message,2) end end
local defs=require("prototypes.technology.convergence")
local audit=require("scripts.razi_convergence_audit")
local registry={item={},recipe={},entity={}}
for _,stage in ipairs(defs.shipments) do
 registry.item[stage.item]={name=stage.item}
end
rawset(_G,"prototypes",registry)
rawset(_G,"storage",{})
local force={name="Audited Force",index=9,technologies={},recipes={}}
for _,id in ipairs({defs.commission,defs.authorization,defs.ignition,
  "razi-convergence-witness-network"}) do
 force.technologies[id]={name=id,researched=true,enabled=true}
end
for _,stage in ipairs(defs.shipments) do
 force.recipes[stage.item]={name=stage.item,enabled=true}
end
local result=audit.inspect(force,registry)
check(#result.errors==0 and result.stages==#defs.shipments,
 "Present native shipments and research must pass the read-only audit")
check(result.locked_sources==0 and result.missing_producers==0
  and storage.razi_convergence==nil,
 "The audit must not invent source progress or allocate save state")
local missing=defs.shipments[1].item
registry.item[missing]=nil
local missing_result=audit.inspect(force,registry)
check(#missing_result.errors==1 and missing_result.stages==#defs.shipments-1,
 "A missing native shipment must be reported as a blocker")
registry.item[missing]={name=missing}
force.recipes[missing].enabled=false
local locked=audit.inspect(force,registry)
check(#locked.errors==0 and #locked.notes==1,
 "An unresearched native recipe is advisory, not a hard blocker")
force.recipes[missing].enabled=true
force.technologies[defs.ignition]=nil
local missing_research=audit.inspect(force,registry)
check(#missing_research.errors==1,
 "Missing Convergence research must be reported")
check(storage.razi_convergence==nil,
 "Multiple audits must remain read-only")
print("Convergence audit: native shipments, research blockers and read-only save safety passed")
