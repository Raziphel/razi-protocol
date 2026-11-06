-- Keeps the Journal current: toolbar button and tracker, redraws after research,
-- boss and system changes, and the burst handling of bulk research.
local M=require("scripts.journal.api")
local journal_button_cleanup=require("scripts.journal.button_cleanup")
local defs=require("scripts.journal.data")
local trials=require("scripts.compatibility.nexus-bosses.trials")
local systems=require("scripts.journal.systems")
local icons=require("scripts.journal.icons")
local widgets=require("scripts.journal.widgets")
local FRAME=widgets.FRAME
local TOP=widgets.TOP
local L=widgets.L
local show_player_option=widgets.show_player_option
local pref=require("scripts.journal.preferences")
local render_tracker=require("scripts.journal.tracker")
local window=require("scripts.journal.window")
local draw=window.draw
local nexus_revision=window.nexus_revision
local update_reader=require("scripts.journal.reader_update")

function M.sync(player)
  if not (player and player.valid) then return end
  -- Return to the original top-left gold journal button.
  -- Clean failed placements without deleting player.gui.top[TOP].
  journal_button_cleanup.remove_other_placements(player,TOP)
  systems.sync_companion_widgets(player,pref(player.index).native_controls_visible)
  local top=player.gui.top[TOP]
  if show_player_option(player,"razi-journal-show-button") then
    if not (top and top.valid) then
      top=icons.button(player.gui.top,"razi-journal-book-icon","toolbar", -- luacheck: ignore 311
        {razi_journal_action="toggle"},L("button-tooltip"),TOP)
    end
  elseif top and top.valid then
    top.destroy()
  end
  render_tracker(player)
end
function M.sync_all()
  for _,player in pairs(game.connected_players or {}) do M.sync(player) end
end
function M.refresh_open()
  for _,player in pairs(game.connected_players or {}) do
    local frame=player.gui and player.gui.screen and player.gui.screen[FRAME]
    if frame and frame.valid then
      if pref(player.index).view=="quests" then update_reader(player)
      else draw(player) end
    end
    local p=storage.razi_expedition_journal
      and storage.razi_expedition_journal[player.index]
    if p and p.tracker then render_tracker(player) end
  end
end
function M.on_removed(index)
  if storage.razi_expedition_journal then
    storage.razi_expedition_journal[index]=nil
  end
end
local function refresh_force(force)
  if not force then return end
  for _,player in pairs(game.connected_players or {}) do
    if player.force==force then
      local frame=player.gui.screen[FRAME]
      if frame and frame.valid then
        if pref(player.index).view=="quests" then update_reader(player)
        else draw(player) end
      end
      local existing=storage.razi_expedition_journal
        and storage.razi_expedition_journal[player.index]
      if existing and existing.tracker then render_tracker(player) end
    end
  end
end
-- The cheat command can finish hundreds of Codex technologies in a
-- single burst. A normal unlock redraws on the next 30-tick maintenance
-- callback, but a bulk unlock gets one redraw after the events settle.
local RESEARCH_BURST_LIMIT=12
local RESEARCH_BURST_WINDOW=120
local RESEARCH_BURST_QUIET=180
-- Staged debug research changes technology flags directly. Keep the Codex
-- parked until the final unlock settles, without relying on research events.
function M.defer_research_refresh(force)
  if not (force and force.name) then return end
  local pending=storage.razi_journal_pending_forces
  if not pending then
    pending={}
    storage.razi_journal_pending_forces=pending
  end
  local tick=game and game.tick or 0
  pending[force.name]={count=RESEARCH_BURST_LIMIT,
    first_tick=tick,last_tick=tick}
end
function M.on_research(event)
  local research=event and event.research
  local force=research and research.force
  if not (force and M.research_affects_journal(research)) then return end
  local tick=game and game.tick or 0
  M.record_chapter_completions(force,false,tick)
  local pending=storage.razi_journal_pending_forces
  if not pending then
    pending={}
    storage.razi_journal_pending_forces=pending
  end
  local state=pending[force.name]
  if type(state)~="table" then
    state={count=0,first_tick=tick}
    pending[force.name]=state
  elseif tick-(state.first_tick or tick)>RESEARCH_BURST_WINDOW then
    state.count=0
    state.first_tick=tick
  end
  state.count=math.min(RESEARCH_BURST_LIMIT,(state.count or 0)+1)
  state.last_tick=tick
end
function M.flush_research_refreshes()
  local pending=storage.razi_journal_pending_forces
  if not pending then return end
  local tick=game and game.tick or 0
  for force_name,state in pairs(pending) do
    -- A boolean may still exist in an old save's deferred work table.
    local burst=type(state)=="table" and
      (state.count or 0)>=RESEARCH_BURST_LIMIT
    if not burst or tick-(state.last_tick or 0)>=RESEARCH_BURST_QUIET then
      pending[force_name]=nil
      refresh_force(game.forces[force_name])
    end
  end
  if not next(pending) then storage.razi_journal_pending_forces=nil end
end
function M.refresh_chapter_completions()
  for _,force in pairs(game.forces or {}) do
    if force.name~="enemy" and force.name~="neutral"
      and M.record_chapter_completions(force,false) then
      refresh_force(force)
    end
  end
end
-- Refresh only visible boss objectives during the existing ten-second
-- maintenance tick. No global entity scans or per-tick remote calls.
function M.refresh_convergence(force)
  if not force then return end
  for _,player in pairs(force.connected_players or {}) do
    local p=storage.razi_expedition_journal and storage.razi_expedition_journal[player.index]
    local frame=player.gui.screen[FRAME]
    if p and p.view=="projects" and p.project=="convergence"
      and frame and frame.valid then draw(player) end
  end
end
-- The progress indicator is a sampled ForceTechnology percentage, not
-- a separate quest state. This never rebuilds the reader or moves scroll.
function M.refresh_research_visible()
  for _,player in pairs(game.connected_players or {}) do
    local p=storage.razi_expedition_journal and
      storage.razi_expedition_journal[player.index]
    if p and p.view=="quests" and p.selected and not p.chapter_cover then
      local frame=player.gui.screen[FRAME]
      local body=frame and frame.valid and frame["razi_journal_content"]
      local host=body and body["razi_journal_reader_host"]
      local panel=host and host.children[1]
      local scroll=panel and panel["razi_journal_reading"]
      local prose=scroll and scroll["razi_journal_prose"]
      local mission=prose and prose["razi_journal_mission_plan"]
      local strip=mission and mission["razi_journal_research_row"]
      if strip and strip.valid then
        local quest=defs.by_id[p.selected]
        local current=player.force.current_research
        local active=current and quest and not quest.boss
          and not quest.convergence and quest.tech==current.name
        if current and quest and quest.world and not active then
          for _,effect in pairs(current.prototype and
              current.prototype.effects or {}) do
            if effect.type=="unlock-space-location"
              and effect.space_location==quest.world then
              active=true
              break
            end
          end
        end
        ---@diagnostic disable-next-line: need-check-nil
        active=active and current.researched~=true
        strip.visible=active==true
        if active then
          local value=player.force.research_progress
          value=type(value)=="number" and value or 0
          value=math.max(0,math.min(1,value))
          local percent=math.floor(value*100+.5)
          local text=strip["razi_journal_research_percent"]
          local bar=strip["razi_journal_research_progress"]
          if text then text.caption=L("mission-research-progress",
            tostring(percent)) end
          if bar then bar.value=value end
        end
      end
    end
  end
end

function M.refresh_systems_visible()
  -- A small reconciliation also catches companion GUIs rebuilt by their own
  -- join/research/configuration handlers; it never scans the world.
  for _,player in pairs(game.connected_players or {}) do
    local p=storage.razi_expedition_journal
      and storage.razi_expedition_journal[player.index]
    systems.sync_companion_widgets(player,p and p.native_controls_visible)
    if p and p.view=="systems" then systems.refresh(player) end
  end
end
function M.refresh_nexus_visible()
  if not (remote and remote.interfaces and
    remote.interfaces["nexus-bosses"]) then return end
  -- One source snapshot per force, not one remote call per open reader.
  local revisions={}
  for _,player in pairs(game.connected_players or {}) do
    local p=storage.razi_expedition_journal
      and storage.razi_expedition_journal[player.index]
    if p then
      local frame=player.gui.screen[FRAME]
      local relevant=(p.view=="quests" and
        (p.chapter=="deepworks"
          or (p.selected and defs.by_id[p.selected]
            and defs.by_id[p.selected].boss)))
        or (p.view=="projects"
          and (p.project=="nexus-trials" or p.project=="convergence"))
      if relevant and frame and frame.valid then
        local force=player.force
        local revision=revisions[force.index]
        if not revision then
          revision=nexus_revision(trials.snapshot(force))
          revisions[force.index]=revision
        end
        -- Preserve both scroll panes and search focus on ordinary polls.
        -- Only a real boss-victory change warrants a full redraw.
        if p.nexus_revision~=revision then
          if p.view=="quests" then update_reader(player)
          else draw(player) end
        end
      end
      if p.tracker and p.pinned and defs.by_id[p.pinned]
        and defs.by_id[p.pinned].boss then
        render_tracker(player)
      end
    end
  end
end
