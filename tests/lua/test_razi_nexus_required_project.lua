---@diagnostic disable: need-check-nil
-- The source Nexus Bosses remote.get_state API is the only
-- authoritative evidence for all nine force-owned victories.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,message) if not ok then error(message,2) end end
local bridge=require("scripts.razi_nexus_trials")
check(#bridge.order==9 and #bridge.circles==3,"Three real stages, nine bosses")
local force={name="Frontier",index=5,technologies={
 ["planet-discovery-nexus"]={researched=true}
}}
rawset(_G,"remote",nil)
check(bridge.snapshot(force)==nil,"Missing source must fail closed")
local state={defeated={}}
rawset(_G,"remote",{
 interfaces={["nexus-bosses"]={get_state=true,open_codex=true}},
 call=function(interface,method,...)
  check(interface=="nexus-bosses","Only source Nexus Bosses calls permitted")
  if method=="get_state" then return state end
  if method=="open_codex" then
    local player_index,boss_id=...
    check(player_index==77 and boss_id=="watcher",
      "Original Codex must open on click for requested boss")
    return
  end
  error("Unexpected remote mutation: "..tostring(method))
 end
})
local fresh=bridge.snapshot(force)
check(fresh.count==0 and fresh.total==9,
 "New forces must have zero recorded native boss victories")
state.defeated[force.name]={}
for i,id in ipairs(bridge.order) do
 state.defeated[force.name][id]=true
 local progress=bridge.snapshot(force)
 check(progress.count==i,"Victory count must reflect each source boss kill")
end
local won=bridge.snapshot(force)
for _,circle in ipairs(bridge.circles) do
 check(#circle.bosses==3,"Every Nexus circle must have three fights")
 for _,id in ipairs(circle.bosses) do
  check(bridge.defeated(won,id),"Each source defeat must be visible")
 end
end
check(bridge.open_codex({valid=true,index=77},"watcher"),
 "Codex must delegate to the source author's real UI")
state.defeated[force.name]["last-commander"]=false
check(bridge.snapshot(force).count==8,"Warp-key proxy must not fake final boss")
state.defeated[force.name]=nil
check(bridge.snapshot(force).count==0,"Different force cannot inherit victories")
state.defeated[force.name]="broken"
check(bridge.snapshot(force)==nil,"Malformed source records must fail closed")
print("Ninefold Signal: all nine genuine boss flags, Codex, failure guards passed")
