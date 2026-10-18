-- Friendly onboarding without erasing existing worlds' chat histories.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,why) if not ok then error(why,2) end end
storage={}
local settings_map={
 ["razi-clean-startup-chat"]={value=true},
 ["razi-show-welcome"]={value=true}}
settings={get_player_settings=function(_) return settings_map end,
 global={["razi-hide-spoilers"]={value=true}}}
local received,cleared={},0
local player={valid=true,connected=true,index=1,admin=true,
 print=function(msg) received[#received+1]=msg end,
 clear_console=function() cleared=cleared+1 end}
game={tick=1,get_player=function(index)
 if index==1 then return player end end}
local module=require("scripts.razi_welcome")
module.on_player_created(player)
module.on_player_joined(player)
check(#received==0 and cleared==0,
 "New game should wait briefly for third-party splash messages")
game.tick=150
module.flush()
check(#received==0,"Message must not appear before the cleanup window")
game.tick=181
module.flush()
check(cleared==1 and #received==8,
 "An admin should see one eight-line spoiler-safe operations welcome")
check(received[1][1]=="razi-welcome.header"
 and received[3][1]=="razi-welcome.status-initial"
 and received[5][1]=="razi-welcome.priority-initial"
 and received[6][1]=="razi-welcome.journal"
 and received[6][3][1]=="razi-welcome.spoilers-on"
 and received[8][1]=="razi-welcome.admin",
 "Localized welcome should use genuine locale keys")
module.on_player_joined(player)
game.tick=250
module.flush()
check(cleared==1 and #received==8,
 "Returning player must never be greeted or cleared again")
module.command{player_index=1}
check(#received==16 and cleared==1,
 "/razi-welcome should be repeatable without clearing chat")
module.command{player_index=1,parameter="clear"}
check(#received==24 and cleared==2,
 "/razi-welcome clear must only erase chat on explicit request")
module.on_player_removed(1)
settings_map["razi-clean-startup-chat"].value=false
received={}
game.tick=2
module.on_player_created(player)
game.tick=200
module.flush()
check(cleared==2 and #received==8,
 "Opt-out must preserve all chat lines while keeping welcome enabled")
module.on_player_removed(1)
settings_map["razi-show-welcome"].value=false
received={}
game.tick=3
module.on_player_created(player)
game.tick=200
module.flush()
check(cleared==2 and #received==0,
 "Welcome opt-out must not print chat or re-clear the console")
module.on_player_removed(1)
settings_map["razi-show-welcome"].value=true
settings_map["razi-clean-startup-chat"].value=true
received={}
game.tick=3500
module.on_player_joined(player)
check(#received==8 and cleared==2,
 "Old saves should get the welcome once without deleting prior messages")
-- The resume briefing may only name research already completed.
player.force={technologies={automation={researched=true},
  ["space-platform"]={researched=false},
  ["interplanetary-trade-logistics"]={researched=false},
  ["razi-convergence-commission"]={researched=false}}}
check(module.signal(player)=="status-local",
  "Operations status should only reflect real researched technologies")
check(module.priority(player)=="priority-local",
  "The welcome directive must follow actual researched milestones")
settings.global["razi-hide-spoilers"].value=false
check(module.spoiler_status()=="spoilers-off",
  "Current spoiler setting OFF must be reflected in the welcome")
received={}
module.command{player_index=1}
check(received[6][3][1]=="razi-welcome.spoilers-off",
  "Replay must display the actual current spoiler state")
settings.global["razi-hide-spoilers"].value=true
player.force.technologies["space-platform"].researched=true
check(module.signal(player)=="status-flight","Platform flight signal")
player.force.technologies["interplanetary-trade-logistics"].researched=true
check(module.signal(player)=="status-network","Real freight network signal")
player.force.technologies["razi-convergence-commission"].researched=true
check(module.signal(player)=="status-commission","Real commission signal")
player.force.technologies["razi-convergence-commission"].researched=false
print("Razi startup welcome, options, replay and existing-save safety passed")
