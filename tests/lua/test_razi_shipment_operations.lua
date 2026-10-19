-- A.7 regression: authorized operator notes, source safety and lazy scans.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,msg) if not ok then error(msg,2) end end
storage={}
game={tick=100}
local graph={}
local valid=true
local plan={id=8,legs={
  {from="vulcanus",to="castra",mode="catapult",id="first"},
  {from="castra",to="gleba",mode="platform",id="second"},
  {from="gleba",to="moshine",mode="catapult",id="third"}}}
local player={index=11,force={index=3}}
local other={index=12,force=player.force}
local calls={inspect=0,receipt=0}
package.loaded["scripts.razi_supply_routes"]={
  graph=function() return graph end}
package.loaded["scripts.razi_supply_multihop"]={
  visible=function(p)
    if p.index==player.index then
      return {{id=8,valid=valid,plan=valid and plan or nil}}
    end
    return {}
  end}
package.loaded["scripts.razi_freight_infrastructure"]={
  inspect_worlds=function(_,worlds)
    calls.inspect=calls.inspect+1
    check(#worlds==4,"Inspect only the source-validated worlds")
    return {worlds={
      vulcanus={launcher_count=1,platforms=0},
      castra={launcher_count=1,platforms=1,unscheduled=1},
      gleba={launcher_count=0,platforms=0},
      moshine={launcher_count=0,platforms=0}}}
  end}
package.loaded["scripts.razi_catapult_network"]={
  snapshot=function() return {installed=true,enabled=true,entries={}} end}
package.loaded["scripts.razi_freight_receipts"]={
  snapshot=function()
    calls.receipt=calls.receipt+1
    return {worlds={castra=4}}
  end}
prototypes={space_location={
  vulcanus={localised_name="Vulcanus"},
  castra={localised_name="Castra"},
  gleba={localised_name="Gleba"},
  moshine={localised_name="Moshine"}}}
local M=require("scripts.razi_shipment_operations")
local initial=M.progress(plan)
check(initial and initial.received==0 and initial.leg==1
  and initial.next_action=="depart","Legacy manifests start with no notes")
check(not M.change(player,8,"arrive"),"Cannot skip departure")
check(not M.change(other,8,"depart"),"Other player cannot change record")
check(not M.change(player,99,"depart"),"Wrong plan ID must fail")
check(not M.change(player,8,"forge"),"Only known verbs may be stored")
check(M.change(player,8,"depart"),"First manual departure works")
check(plan.operation_events[1].kind=="depart"
 and plan.operation_events[1].leg==1
 and plan.operation_events[1].tick==100,"Store primitive checkpoint data")
game.tick=150
check(M.change(player,8,"arrive"),"Arrival follows departure")
check(not M.change(player,8,"arrive"),"Next departure must come first")
check(M.progress(plan).received==1,"Counts need paired manual notes")
check(M.change(player,8,"undo") and #plan.operation_events==1,
  "Undo removes only latest note")
check(M.progress(plan).next_action=="arrive","Undo restores next action")
valid=false
check(not M.change(player,8,"arrive")
 and not M.change(player,8,"undo"),
 "When route or research is revoked, all write actions stop")
valid=true
check(M.change(player,8,"arrive"),"Restored source allows new note")
game.tick=200
for i=2,3 do
  check(M.change(player,8,"depart"),"Manual departures are sequential")
  check(M.change(player,8,"arrive"),"Manual arrivals are sequential")
end
check(M.progress(plan).done and M.progress(plan).received==3
 and #plan.operation_events==6,"Every leg needs explicit ordered notes")
check(not M.change(player,8,"depart"),"Cannot extend completed log")
check(M.change(player,8,"undo") and not M.progress(plan).done,
 "Final arrival is reversible")
local original=plan.operation_events
plan.operation_events={{leg=2,kind="arrive",tick=0}}
check(M.progress(plan)==nil and not M.change(player,8,"depart"),
 "Forged or corrupt notes never authorize operations")
plan.operation_events=original
local actions={}
local function gui()
  local node={style={},children={}}
  function node.add(spec)
    local child=gui()
    child.spec=spec
    node.children[#node.children+1]=child
    if spec.tags and spec.tags.razi_ops_action then
      actions[spec.tags.razi_ops_action]=true
    end
    return child
  end
  return node
end
check(calls.inspect==0 and calls.receipt==0,
 "Manual events and collapsed manifests never scan native worlds")
M.render(gui(),player,plan,650)
check(calls.inspect==1 and calls.receipt==1,
 "Expanded operation logs read infrastructure and receipt snapshot once")
check(actions["supply-operation-arrive"] and actions["supply-operation-undo"],
 "Only legal next operator step and undo are available")
check(M.change(player,8,"arrive"),"Can finish after reviewing source evidence")
actions={}
M.render(gui(),player,plan,650)
check(not actions["supply-operation-arrive"]
 and actions["supply-operation-undo"],"Completed log allows undo only")
print("Razi A.7 operator shipment safety passed")
