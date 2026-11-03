-- The Protocol Codex reads research progress from each force.
-- Player storage is just UI preferences, so an older save can reopen it.
local M=require("scripts.journal.api")
local journal_button_cleanup=require("scripts.journal.button_cleanup")
local defs=require("scripts.journal.data")
local story=require("lib.story")
-- The Archive records and the record notices, loaded here for the story.
story.attach(require("scripts.story.records"),
  require("scripts.story.dispatch"))
local trials=require("scripts.compatibility.nexus-bosses.trials")
local convergence=require("scripts.convergence.convergence")
local projects=require("scripts.journal.projects")
local systems=require("scripts.journal.systems")
local great_projects=require("scripts.projects.great_projects")
-- Clicks that only exist inside the story Archive tab.
local ARCHIVE_ACTIONS={
  ["array-record"]=true,["story-alerts"]=true,["record-next-unread"]=true,
  ["archive-filter"]=true,["archive-source"]=true,record=true
}
local themes=require("scripts.journal.themes")
local icons=require("scripts.journal.icons")
local search_names=require("scripts.journal.search_names")
local widgets=require("scripts.journal.widgets")
local FRAME=widgets.FRAME
local TOP=widgets.TOP
local TRACKER=widgets.TRACKER
local L=widgets.L
local show_player_option=widgets.show_player_option
local pref=require("scripts.journal.preferences")
local quest_state=require("scripts.journal.quest_state")
local matches_query=quest_state.matches_query
local render_tracker=require("scripts.journal.tracker")
local archive_view=require("scripts.journal.archive_view")
local record_open=archive_view.record_open
local window=require("scripts.journal.window")
local draw=window.draw
local open=window.open
local close=window.close
local nexus_revision=window.nexus_revision
local update_reader=require("scripts.journal.reader_update")
M.chapter_theme=themes.get
M.chapter_icon=themes.icon

M.FRAME=FRAME
M.TOP=TOP
M.TRACKER=TRACKER












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
function M.gui_click(event)
  local element=event and event.element
  if not (element and element.valid) then return end
  local tags=element.tags
  if not tags then return end
  local action=tags.razi_journal_action
  local native=tags.razi_ops_action
  if not action and not native then return end
  local player=game.get_player(event.player_index)
  if not (player and player.valid) then return end
  if native then
    local p=pref(player.index)
    if not (player.gui.screen[FRAME] and p.view=="projects") then return end
    if not (native=="convergence-deliver" and p.project=="convergence") then return end
    local known=false
    for _,stage in ipairs(convergence.stages) do
      if stage.id==tags.value then known=true;break end
    end
    if not known or not convergence.available(player.force) then return end
    local message,amount=convergence.deliver(player,tags.value)
    player.print({"razi-ops."..message,tostring(amount)})
    draw(player)
    return
  end
  if action=="toggle" then M.toggle(player);return end
  if action=="close" then close(player);return end
  if action=="systems-native" then
    local p=pref(player.index)
    local frame=player.gui.screen[FRAME]
    if not (frame and frame.valid and p.view=="systems") then return end
    -- Never redraw the folio for this control: preserve scroll position.
    p.native_controls_visible=not p.native_controls_visible
    systems.sync_companion_widgets(player,p.native_controls_visible)
    local bar=frame["razi_journal_filterbar"]
    local button=bar and bar["razi_journal_systems_native"]
    if button and button.valid then
      button.caption=L(p.native_controls_visible and "systems-native-hide"
        or "systems-native-show")
    end
    return
  end
  if action=="nexus-codex" then
    if not trials.open_codex(player,tags.id) then
      player.print(L("nexus-codex-unavailable"))
    end
    return
  end
  if action=="open-convergence" then
    local quest=defs.by_id[tags.id]
    if quest and M.available(player.force,quest,M.context(player.force,player))
      and convergence.available(player.force) then
      M.open_project(player,"convergence")
    end
    return
  end
  if action=="tracker-open" then
    local p=pref(player.index)
    p.selected=p.pinned
    open(player)
    return
  end
  local p=pref(player.index)
  local old_view=p.view
  if ARCHIVE_ACTIONS[action] and not story.visible(player) then return end
  if (action=="select" or action=="guidance-select") and
    defs.by_id[tags.id] and M.journal_visible(player.force,defs.by_id[tags.id],
      M.context(player.force,player)) then
    p.selected=tags.id
    p.chapter=defs.by_id[tags.id].chapter
    -- Keep a clicked search/filter result in its original list.
    -- Guidance links may jump outside the filter, so only they clear it.
    if action=="guidance-select" then
      p.filter="all"
      p.query=""
    end
    p.view="quests"
    p.chapter_cover=false
    p.compact_index_open=false
  elseif action=="mission-details" and p.view=="quests"
    and p.selected==tags.id then
    p.goal_expanded=p.goal_expanded_quest~=tags.id
      or not p.goal_expanded
    p.goal_expanded_quest=tags.id
  elseif action=="compact-index" and p.view=="quests"
    and M.layout(player.display_resolution,player.display_scale).single_column then
    p.reader_focus=false
    p.compact_index_open=not p.compact_index_open
  elseif action=="focus" and p.view~="systems" then
    p.reader_focus=not p.reader_focus
  elseif action=="chapter-dossier" then
    local known=false
    for _,ch in ipairs(defs.chapters) do
      if ch.id==tags.id then known=true;break end
    end
    if not known then return end
    if M.hide_spoilers() then
      local exposed=false
      local context=M.context(player.force,player)
      for _,candidate in ipairs(defs.quests) do
        if candidate.chapter==tags.id
          and M.journal_visible(player.force,candidate,context) then
          exposed=true;break
        end
      end
      if not exposed then return end
    end
    p.chapter=tags.id
    p.chapter_cover=true
    p.view="quests"
    p.compact_index_open=false
    p.filter="all"
    p.query=""
  elseif action=="chapter-continue" then
    local target=defs.by_id[tags.id]
    if not (target and M.journal_visible(player.force,target,
        M.context(player.force,player))) then return end
    p.selected=target.id
    p.chapter=target.chapter
    p.chapter_cover=false
    p.compact_index_open=false
    p.filter="all"
    p.query=""
  elseif action=="chapter" then
    if M.hide_spoilers() then
      local exposed=false
      local context=M.context(player.force,player)
      for _,candidate in ipairs(defs.quests) do
        if candidate.chapter==tags.id
          and M.journal_visible(player.force,candidate,context) then
          exposed=true;break
        end
      end
      if not exposed then return end
    end
    p.chapter=p.chapter==tags.id and false or tags.id
  elseif action=="view" and ({quests=true,projects=true,
      archive=story.visible(player),systems=true})[tags.id] then
    p.view=tags.id
  elseif action=="field-project" and
    projects.visible(player.force,tags.id) then
    M.open_project(player,tags.id)
    return
  elseif action=="project" and projects.visible(player.force,tags.id) then
    p.project=tags.id
  elseif action=="skybridge-sign" and p.view=="projects"
    and p.project=="skybridge" then
    if not great_projects.sign(player,tags.a,tags.b) then return end
  elseif action=="skybridge-deliver" and p.view=="projects"
    and p.project=="skybridge" then
    if not great_projects.deliver(player) then return end
  elseif action=="project-cycle" and p.view=="projects"
    and projects.visible(player.force,tags.id)
    and (projects.adjacent(player.force,p.project,-1)==tags.id
      or projects.adjacent(player.force,p.project,1)==tags.id) then
    p.project=tags.id
  elseif action=="project-next" and p.view=="projects" then
    local quest_id=projects.next_quest(player.force,p.project)
    if not quest_id or not M.open_quest(player,quest_id) then return end
    return
  elseif action=="array-record" and p.view=="archive" then
    local index=tonumber(tags.id)
    if not index or index<1 or index>great_projects.recovered(player.force)
      then return end
    p.record="array-"..index
    p.archive_filter="all"
  elseif action=="story-alerts" and p.view=="archive" then
    p.story_alerts=not p.story_alerts
  elseif action=="record-next-unread" and p.view=="archive" then
    local context=M.context(player.force,player)
    local found=false
    for _,record in ipairs(story.records(player)) do
      local quest=defs.by_id[record.unlock]
      if p.story_unread and p.story_unread[record.id]
        and record_open(player,quest,
          quest and M.complete(player.force,quest,context)) then
        p.record=record.id
        p.archive_filter="all"
        p.story_unread[record.id]=nil
        found=true
        break
      end
    end
    if not found then return end
  elseif action=="archive-filter" then
    if not ({all=true,legacy=true,corporate=true,field=true})[tags.id]
      then return end
    p.archive_filter=tags.id
    p.record=nil
  elseif action=="archive-source" then
    local quest=defs.by_id[tags.id]
    if not (quest and M.complete(player.force,quest,
        M.context(player.force,player))) then return end
    p.selected=quest.id
    p.chapter=quest.chapter
    p.chapter_cover=false
    p.view="quests"
    p.compact_index_open=false
    p.filter="all"
    p.query=""
  elseif action=="record" then
    local context=M.context(player.force,player)
    for _,record in ipairs(story.records(player)) do
      if record.id==tags.id then
        local quest=defs.by_id[record.unlock]
        if record_open(player,quest,
          quest and M.complete(player.force,quest,context)) then
          p.record=record.id
          p.archive_filter="all"
          p.view="archive"
          if p.story_unread then p.story_unread[record.id]=nil end
        end
        break
      end
    end
  elseif action=="filter-ready" then
    p.view="quests"
    p.filter="ready"
    p.query=""
    -- The counter is an actual navigation shortcut: open a ready entry
    -- rather than keeping a stale selection from another chapter.
    local context=M.context(player.force,player)
    local target=M.next_quest(player.force,context)
    if not (target and M.state(player.force,target,context)=="active") then
      target=nil
      for _,candidate in ipairs(defs.quests) do
        if M.state(player.force,candidate,context)=="active" then
          target=candidate
          break
        end
      end
    end
    if target then
      p.selected=target.id
      p.chapter=target.chapter
      p.compact_index_open=false
    end
  elseif action=="filter" and ({all=true,ready=true,unfinished=true,
      done=true})[tags.id] then
    p.filter=tags.id
  elseif action=="next" then
    local next=M.next_quest(player.force,M.context(player.force,player))
    if next then
      p.compact_index_open=false
      p.selected=next.id
      p.chapter=next.chapter
      p.filter="all"
      p.view="quests"
      p.query=""
      p.chapter_cover=false
    end
  elseif action=="next-in-chapter" or action=="previous-in-chapter" then
    local context=M.context(player.force,player)
    local choices={}
    for _,quest in ipairs(defs.quests) do
      if quest.chapter==p.chapter and M.journal_visible(player.force,quest,context)
        and M.show_in_filter(player.force,quest,p.filter,context) then
        choices[#choices+1]=quest
      end
    end
    for i,quest in ipairs(choices) do
      if quest.id==p.selected then
        local offset=action=="previous-in-chapter" and -2 or 0
        p.selected=choices[(i+offset)%#choices+1].id
        p.chapter_cover=false
        break
      end
    end
  elseif action=="clear-search" then
    p.query=""
  elseif action=="pin" and defs.by_id[tags.id] then
    if p.tracker and p.pinned==tags.id then
      p.tracker=false
    else
      p.pinned=tags.id;p.tracker=true
    end
    render_tracker(player)
  elseif action=="refresh" and p.view=="projects" then
    projects.refresh(player.force)
  elseif action=="refresh" and p.view=="systems" then
    systems.refresh(player)
  elseif action~="refresh" then return end
  -- Keep the navigation GUI (and its native scrollbar) on ordinary clicks.
  if old_view=="quests" and p.view=="quests" then
    if action=="select" or action=="guidance-select" or action=="chapter"
      or action=="next" or action=="chapter-dossier" or action=="chapter-continue"
      or action=="next-in-chapter" or action=="previous-in-chapter"
      or action=="filter" or action=="filter-ready" or action=="clear-search"
      or action=="mission-details" then
      update_reader(player,action=="chapter" or action=="filter")
      return
    elseif action=="pin" then
      local frame=player.gui.screen[FRAME]
      local body=frame and frame["razi_journal_content"]
      local reader=body and body["razi_journal_reader_host"]
      local panel=reader and reader.children[1]
      local scroll=panel and panel["razi_journal_reading"]
      local prose=scroll and scroll["razi_journal_prose"]
      local actions=prose and prose["razi_journal_actions"]
      local pin=actions and actions["razi_journal_pin_button"]
      if pin then
        pin.caption=L(p.tracker and p.pinned==tags.id
          and "tracker-hide" or "tracker-show")
      end
      return
    end
  end
  draw(player)
end
-- Select the first matching visible milestone so the reader follows search.
local function follow_search(player,p)
  local prior=p.selected
  local prior_cover=p.chapter_cover
  if p.query~="" then
    local context=M.context(player.force,player)
    local translated=search_names.names(player.index)
    for _,quest in ipairs(defs.quests) do
      if M.show_in_filter(player.force,quest,p.filter,context)
        and matches_query(quest,p.query,translated) then
        p.selected=quest.id
        p.chapter=quest.chapter
        p.chapter_cover=false
        break
      end
    end
  end
  update_reader(player,p.selected==prior and p.chapter_cover==prior_cover)
end
function M.text_changed(event)
  local element=event and event.element
  if not (element and element.valid) then return end
  if element.name~="razi_journal_search" then return end
  local player=game.get_player(event.player_index)
  if not (player and player.valid) then return end
  local p=pref(player.index)
  local query=(element.text or ""):sub(1,80)
  if p.query==query then return end
  p.query=query
  follow_search(player,p)
end
-- All translated names arrived: a typed query may match more now.
function M.search_names_ready(player_index)
  local player=game.get_player(player_index)
  if not (player and player.valid) then return end
  local frame=player.gui.screen[FRAME]
  if not (frame and frame.valid) then return end
  local p=pref(player.index)
  if p.query=="" then return end
  follow_search(player,p)
end
function M.selection_changed(event)
  local element=event and event.element
  if not (element and element.valid) then return end
  if element.name~="razi_journal_chapter_picker" then return end
  local chapter=defs.chapters[element.selected_index]
  local player=game.get_player(event.player_index)
  if not (chapter and player and player.valid) then return end
  local p=pref(player.index)
  local preserve=p.view=="quests" and p.query=="" and p.filter=="all"
  p.chapter=chapter.id
  p.filter="all"
  p.query=""
  p.chapter_cover=true
  local context=M.context(player.force,player)
  for _,quest in ipairs(defs.quests) do
    if quest.chapter==chapter.id
      and M.journal_visible(player.force,quest,context) then
      p.selected=quest.id
      break
    end
  end
  if preserve then update_reader(player) else draw(player) end
end
function M.gui_closed(event)
  if event.element and event.element.valid and event.element.name==FRAME then
    local player=game.get_player(event.player_index)
    if player then close(player) end
  end
end
function M.on_display_changed(event)
  local player=game.get_player(event.player_index)
  if not player then return end
  M.sync(player)
  if player.gui.screen[FRAME] then
    close(player)
    open(player)
  end
end
return M
