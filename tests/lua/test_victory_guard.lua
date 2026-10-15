-- Only Razi Convergence calls set_game_state; all known external
-- endpoints expose opt-out APIs that must be reasserted safely.
package.path="./?.lua;./?/init.lua;"..package.path
local guard=require("scripts.razi_victory_guard")
local seen={}
local state={}
rawset(_G,"remote",{interfaces={
  ["space_finish_script"]={set_no_victory=true},
  ["kr-intergalactic-transceiver"]={set_no_victory=true,get_no_victory=true},
  ["silo_script"]={set_no_victory=true,get_no_victory=true},
  ["unrelated"]={set_no_victory=true}
},call=function(interface,method,value)
  if method=="get_no_victory" then return state[interface] or false end
  assert(method=="set_no_victory" and value==true,"Victory enable attempted")
  seen[interface]=(seen[interface] or 0)+1
  state[interface]=true
end})
assert(guard.enforce()==3,"All three supported victories must be disabled")
assert(guard.enforce()==1,"Already-disabled source APIs should not be reset")
assert(seen.unrelated==nil,"Do not invoke unrelated source interfaces")
assert(state["space_finish_script"] and state["kr-intergalactic-transceiver"]
  and state["silo_script"],"Missing mandatory opt-out")
remote.interfaces["silo_script"]=nil
assert(guard.enforce()==1,"Missing optional endpoint must be harmless")
rawset(_G,"remote",nil)
assert(guard.enforce()==0,"Missing remote API must be harmless")
print("Only Convergence win: optional remote opt-out safety passed")
