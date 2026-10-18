-- The stock /cheat researches every technology in one engine call.
-- On a large modpack that can stall the simulation. This testing command
-- changes one research at a time and can be cancelled without a reset.
local M={}
local journal=require("scripts.razi_journal")
local spoiler_fog=require("scripts.razi_spoiler_fog")

local function say(index,message)
  local player=index and game.get_player(index)
  if player and player.valid then
    player.print("[Razi Protocol] "..message)
  else
    log("[Razi Protocol/cheat] "..message)
  end
end

-- This command grants research; SLP satellite construction is separate.
local function explain_dyson(index,force)
  local technologies=force and force.technologies
  local project=technologies and technologies["slp-dyson-sphere"]
  if project and project.researched then
    say(index,"Dyson research unlocked, but satellites still need launching. "..
      "Calidus's map star is static. See Galactic Ops > Stellar Works "..
      "for research-stage art and placed receivers.")
  end
end

local function eligible(tech)
  if not tech or tech.valid==false or tech.researched then return false end
  local proto=tech.prototype
  return proto and proto.enabled~=false and not proto.hidden
end

-- Prerequisite order gives scripted progression a more natural sequence.
-- Technology tables are scanned once on request, never every game tick.
local function make_plan(force)
  local candidates={}
  for name,tech in pairs(force.technologies) do
    if eligible(tech) then candidates[#candidates+1]=name end
  end
  table.sort(candidates)
  local ordered,seen={},{}
  local function visit(name)
    if seen[name] then return end
    seen[name]=true
    local tech=force.technologies[name]
    if not eligible(tech) then return end
    local parents={}
    for parent_name in pairs(tech.prerequisites or {}) do
      if eligible(force.technologies[parent_name]) then
        parents[#parents+1]=parent_name
      end
    end
    table.sort(parents)
    for _,parent in ipairs(parents) do visit(parent) end
    ordered[#ordered+1]=name
  end
  for _,name in ipairs(candidates) do visit(name) end
  return ordered
end

function M.command(event)
  local player=event.player_index and game.get_player(event.player_index)
  if not (player and player.valid) then
    log("[Razi Protocol/cheat] Run /razi-cheat from an admin player.")
    return
  end
  if not player.admin then
    say(player.index,"Only server admins can use /razi-cheat.")
    return
  end
  local action=(event.parameter or ""):match("^%s*(.-)%s*$"):lower()
  if action=="" then action="start" end
  if action~="start" and action~="status" and action~="cancel" then
    say(player.index,"Usage: /razi-cheat [start|status|cancel]")
    return
  end
  local force=player.force
  local jobs=storage.razi_cheat_jobs
  local job=jobs and jobs[force.name]
  if action=="status" then
    if job then
      say(player.index,("Researching %d of %d technologies.")
        :format(job.position-1,#job.names))
    else
      say(player.index,"No staged research is running for your force.")
    end
    return
  end
  if action=="cancel" then
    if job then
      jobs[force.name]=nil
      journal.defer_research_refresh(force)
      say(player.index,("Stopped after %d of %d technologies. Already granted research is kept.")
        :format(job.position-1,#job.names))
      if not next(jobs) then storage.razi_cheat_jobs=nil end
    else
      say(player.index,"There is no staged research to stop.")
    end
    return
  end
  if job then
    say(player.index,"Research is already running. Use /razi-cheat status or cancel.")
    return
  end
  local plan=make_plan(force)
  player.cheat_mode=true
  if #plan==0 then
    say(player.index,"All eligible technologies are already researched. Free crafting enabled.")
    explain_dyson(player.index,force)
    return
  end
  if not jobs then
    jobs={}
    storage.razi_cheat_jobs=jobs
  end
  jobs[force.name]={names=plan,position=1,completed=0,failed=0,
    last_reported=0,player_index=player.index}
  journal.defer_research_refresh(force)
  say(player.index,("Free crafting enabled. Researching %d technologies in small steps.")
    :format(#plan))
end

function M.tick()
  local jobs=storage.razi_cheat_jobs
  if not jobs then return end
  for force_name,job in pairs(jobs) do
    local force=game.forces[force_name]
    if not (force and force.valid~=false) then
      jobs[force_name]=nil
    else
      local name=job.names[job.position]
      if name then
        local tech=force.technologies[name]
        if eligible(tech) then
          local ok,err=pcall(function() tech.researched=true end)
          if ok then
            job.completed=job.completed+1
            -- Direct scripted research may not fire on_research_finished.
            -- Release exactly the now-reachable successors in spoiler mode.
            spoiler_fog.on_research{research=tech}
          else
            job.failed=job.failed+1
            if job.failed<=5 then
              log("[Razi Protocol/cheat] Failed to research "..name..": "..tostring(err))
            end
          end
        end
        job.position=job.position+1
        -- Hold Codex work until after the last change, even if writing the
        -- researched flag does not emit an on_research_finished event.
        journal.defer_research_refresh(force)
        local mark=math.floor((job.position-1)*10/#job.names)
        if mark>job.last_reported and mark<10 then
          job.last_reported=mark
          say(job.player_index,("Research progress: %d%%.") :format(mark*10))
        end
      end
      if job.position>#job.names then
        jobs[force_name]=nil
        say(job.player_index,("Staged research complete: %d granted, %d failed.")
          :format(job.completed,job.failed))
        explain_dyson(job.player_index,force)
        log(("[Razi Protocol/cheat] Force %s: %d completed, %d failed.")
          :format(force_name,job.completed,job.failed))
      end
    end
  end
  if not next(jobs) then storage.razi_cheat_jobs=nil end
end

-- Built-in commands belong to the engine, and Factorio does not provide
-- a cancellable pre-command hook. The console event is best-effort only.
local WARNING_COOLDOWN=600
local WARNING_TINT={r=1,g=0.77,b=0.47}
function M.warn_builtin(event)
  if not (event and type(event.command)=="string"
    and event.command:lower()=="cheat") then return end
  local option=(event.parameters or ""):match("^%s*(.-)%s*$"):lower()
  if option=="off" then return end

  local player=event.player_index and game.get_player(event.player_index)
  if not (player and player.valid) then return end
  local last=storage.razi_cheat_last_warning
    and storage.razi_cheat_last_warning[player.index]
  if last and game.tick-last<WARNING_COOLDOWN
    and game.tick>=last then return end
  storage.razi_cheat_last_warning=storage.razi_cheat_last_warning or {}
  storage.razi_cheat_last_warning[player.index]=game.tick
  player.print({"razi-cheat.builtin-warning"},{color=WARNING_TINT})
end

-- Players testing the pack need to see the alternative BEFORE trying
-- the built-in command. Show this only once per save, and only to admins.
function M.admin_tip(player)
  if not (player and player.valid and player.admin) then return end
  storage.razi_cheat_tip_seen=storage.razi_cheat_tip_seen or {}
  if storage.razi_cheat_tip_seen[player.index] then return end
  storage.razi_cheat_tip_seen[player.index]=true
  player.print({"razi-cheat.admin-tip"},{color=WARNING_TINT})
end

function M.on_player_removed(index)
  if storage.razi_cheat_tip_seen then
    storage.razi_cheat_tip_seen[index]=nil
  end
  if storage.razi_cheat_last_warning then
    storage.razi_cheat_last_warning[index]=nil
  end
end

return M
