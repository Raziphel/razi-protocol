-- Staged cheat regression without a Factorio binary.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,msg) if not ok then error(msg,2) end end
local journal=require("scripts.razi_journal")
local refreshed={}
journal.defer_research_refresh=function(force)
  refreshed[force.name]=(refreshed[force.name] or 0)+1
end
local M=require("scripts.razi_safe_cheat")
local technologies={
  ["science"]={name="science",researched=false,valid=true,
    prototype={enabled=true},prerequisites={}},
  ["rocket"]={name="rocket",researched=false,valid=true,
    prototype={enabled=true},prerequisites={science=true}},
  ["network"]={name="network",researched=false,valid=true,
    prototype={enabled=true},prerequisites={rocket=true}},
  ["hidden"]={name="hidden",researched=false,valid=true,
    prototype={enabled=true,hidden=true},prerequisites={}},
  ["disabled"]={name="disabled",researched=false,valid=true,
    prototype={enabled=false},prerequisites={}}
}
local force={name="player",valid=true,technologies=technologies}
local messages={}
local player={index=1,valid=true,admin=false,force=force,cheat_mode=false,
  print=function(text) messages[#messages+1]=text end}
rawset(_G,"storage",{})
rawset(_G,"game",{forces={player=force},get_player=function(index)
  if index==1 then return player end
end})
rawset(_G,"log",function(_) end)
local function command(arg) M.command({player_index=1,parameter=arg}) end
command("")
check(not storage.razi_cheat_jobs and not player.cheat_mode,
  "Non-admin cannot start staged research")
player.admin=true
command("")
check(player.cheat_mode and #storage.razi_cheat_jobs.player.names==3,
  "Admin should queue exactly the three eligible technologies")
local plan=storage.razi_cheat_jobs.player.names
check(plan[1]=="science" and plan[2]=="rocket" and plan[3]=="network",
  "Research must respect prerequisite order")
M.tick()
check(technologies.science.researched and not technologies.rocket.researched,
  "A tick must only research one technology")
command("status")
M.tick()
check(technologies.rocket.researched and not technologies.network.researched,
  "A tick must not research the entire tech tree")
command("cancel")
check(not storage.razi_cheat_jobs and not technologies.network.researched,
  "Cancel must stop future research without undoing completed techs")
command("start")
check(#storage.razi_cheat_jobs.player.names==1,
  "Resuming should only include the remaining technology")
-- Jobs live in storage; re-requiring the helper does not erase them.
package.loaded["scripts.razi_safe_cheat"]=nil
local resumed=require("scripts.razi_safe_cheat")
resumed.tick()
check(technologies.network.researched and not storage.razi_cheat_jobs,
  "Resumed run should complete and clear its saved job")
check(not technologies.hidden.researched and not technologies.disabled.researched,
  "Research must not grant hidden or source-disabled technologies")
check(refreshed.player>=4,"Codex should redraw only after deferred work")
print("Staged research: permissions, pacing, cancel and persistence passed")
