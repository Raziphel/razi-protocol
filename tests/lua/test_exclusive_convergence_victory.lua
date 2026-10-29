-- Exclusive endgame policy: opt-outs, foreign native wins and migration.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(actual,why) if not actual then error(why,2) end end
local guard=require("scripts.razi_victory_guard")
local state={}
local issued={}
local loglines={}
log=function(message) loglines[#loglines+1]=message end
remote={interfaces={
 ["space_finish_script"]={set_no_victory=true},
 ["kr-intergalactic-transceiver"]={set_is_victory=true,get_is_victory=true},
 ["silo_script"]={set_no_victory=true,get_no_victory=true},
 ["unknown-custom-victory"]={set_no_victory=true}
},call=function(id,fn,value)
 if fn=="get_is_victory" then return state[id]~=false end
 if fn=="get_no_victory" then return state[id]==true end
 check((fn=="set_is_victory" and value==false)
   or (fn=="set_no_victory" and value==true),
   "Victory guard must NEVER re-enable native source endings")
 issued[id]=(issued[id] or 0)+1
 if fn=="set_is_victory" then state[id]=value else state[id]=true end
end}
storage={}
game={tick=4,finished=false,finished_but_continuing=false,
 reset_game_state=function() game.finished=false
   game.finished_but_continuing=false
   game.reset_count=(game.reset_count or 0)+1
 end}
guard.prepare()
check(storage.razi_victory_guard.inherited_finished==false,
 "A fresh save must start with a clean inherited-victory marker")
check(guard.enforce()==3,"Three supported source endings must be disabled")
check(guard.enforce()==1,
 "Endpoints with native getters must remain disabled, old Space Age reasserts")
check(issued["unknown-custom-victory"]==nil,
 "Do not blindly invoke other mods' undocumented remote interfaces")
local inspected=guard.inspect()
check(inspected[1].state=="unverified" and
 inspected[2].state=="disabled" and
 inspected[3].state=="disabled" and
 inspected[4].state=="unmanaged" and
 inspected[4].interface=="unknown-custom-victory",
 "Admin audit must distinguish verified, getter-less and unknown opt-outs")
remote.interfaces["kr-intergalactic-transceiver"].set_is_victory=nil
check(guard.enforce()==1,
 "Unsupported interface must be skipped without crashing")
check(guard.inspect()[2].state=="unsupported",
 "Unsupported source interface must be visible in the audit")
remote.interfaces["kr-intergalactic-transceiver"]=nil
check(guard.inspect()[2].state=="absent",
 "Missing mod interfaces must show absent rather than falsely disabled")
local saves_before=game.reset_count or 0
game.finished=true
check(guard.recover_unexpected(),"Unexpected vanilla win must be recovered")
check(not game.finished and (game.reset_count or 0)==saves_before+1,
 "Recovery should clear only unexpected native game victory state")
check(guard.recoveries()==1,"Recovery incident counter must increment once")
check(not guard.recover_unexpected(),"Reset must not repeat on clean state")
storage.razi_convergence={[1]={victory=true}}
game.finished=true
check(not guard.recover_unexpected() and game.finished,
 "Actual Convergence win must NEVER be reset")
-- A new save imported from before Razi with victory displayed is historical
-- and must not lose its already-earned ending on configuration change.
storage={}
game.finished=true
guard.prepare()
check(storage.razi_victory_guard.inherited_finished==true,
 "Existing finished save must be marked inherited")
check(not guard.recover_unexpected() and game.finished,
 "Historical victory must remain intact")
remote=nil
check(guard.enforce()==0 and guard.inspect()[1].state=="absent",
 "Headless modpack with no remote interfaces must be harmless")
print("Exclusive victory: source opt-outs, unknown mods, recovery, live and inherited wins passed")
