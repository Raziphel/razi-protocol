-- Pure Lua regression for project research and stellar telemetry.
-- Read-only: no research, inventory or game state is modified.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,message) if not ok then error(message,2) end end
local cargo=require("scripts.galactic_trade_catalog")
local missing={name="prerequisite",researched=false}
local locked={name="locked-tech",enabled=false,researched=false,
  prerequisites={missing}}
local state=cargo.state(locked)
check(state.status=="disabled" and state.count==1
  and state.missing[1]==missing,
  "Disabled cargo technology must not appear research-ready")
locked.prerequisites={}
check(cargo.state(locked).status=="disabled",
  "A disabled technology is not ready even with no prerequisites")
locked.enabled=true
check(cargo.state(locked).status=="ready",
  "Enabled cargo research with no blockers should be ready")
locked.prerequisites={missing}
check(cargo.state(locked).status=="blocked",
  "Unresearched prerequisites must remain visible")
locked.researched=true
check(cargo.state(locked).status=="researched",
  "Completed cargo research must outrank disabled/blocked states")
locked.prototype={hidden=true}
check(cargo.state(locked).status=="absent",
  "Source-hidden cargo research must stay out of the ledger")

local dyson=require("scripts.galactic_dyson")
local runtime=require("scripts.galactic_dyson_runtime")
local technology=dyson.stages[1][1]
local force={technologies={
  [technology]={name=technology,enabled=false,researched=false,
    prerequisites={},prototype={hidden=false}}}}
local completed,total,stages=dyson.status(force)
check(completed==0 and total==1 and #stages==1,
  "Installed visible Dyson stages must be counted exactly once")
local displayed={}
local function node(spec)
  local el={style={},caption=spec.caption}
  if el.caption then displayed[#displayed+1]=el.caption end
  function el.add(child) return node(child) end
  return el
end
local old_snapshot=runtime.snapshot
runtime.snapshot=function()
  return {physical_available=false,sites={}}
end
dyson.render(node{}, {force=force}, {embedded=true,width=420})
runtime.snapshot=old_snapshot
local disabled,ready=false,false
for _,caption in ipairs(displayed) do
  if type(caption)=="table" then
    disabled=disabled or caption[1]=="razi-ops.dyson-disabled"
    ready=ready or caption[1]=="razi-ops.dyson-ready"
  end
end
check(disabled and not ready,
  "Disabled Dyson research must show a locked state, not 'ready'")
force.technologies[technology].prototype.hidden=true
check(select(2,dyson.status(force))==0,
  "Hidden source milestones must not inflate Dyson completion totals")

local registry={item={
  ["ds-energy-loader-mk1"]={place_result={name="ds-receiver"}}}}
local calls=0
local worlds={{valid=true,name="Nauvis",
  count_entities_filtered=function(filter)
    calls=calls+1
    check(filter.force==force and filter.name[1]=="ds-receiver",
      "Surface receiver query must respect force and entity identity")
    return 2
  end}}
force.get_entity_count=function(name)
  check(name=="ds-receiver","Must not count guessed receiver entities")
  return 0
end
local empty=runtime.inspect(force,worlds,registry)
check(empty.physical_available and empty.receivers==0
  and #empty.sites==0 and calls==0,
  "No receivers should avoid every costly surface scan")
force.get_entity_count=function() return 2 end
local populated=runtime.inspect(force,worlds,registry)
check(populated.receivers==2 and #populated.sites==1
  and populated.sites[1].count==2 and calls==1,
  "Installed receivers must retain a correct location breakdown")
print("Project dossiers: disabled/hidden research, honest Dyson states and zero-scan telemetry passed")
