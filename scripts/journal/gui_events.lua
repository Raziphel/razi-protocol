-- Reactions to GUI events: clicks, search text, the chapter picker, closing and
-- display changes.
local M=require("scripts.journal.api")
local defs=require("scripts.journal.data")
local story=require("lib.story")
local trials=require("scripts.compatibility.nexus-bosses.trials")
local convergence=require("scripts.convergence.convergence")
local projects=require("scripts.journal.projects")
local systems=require("scripts.journal.systems")
local great_projects=require("scripts.projects.great_projects")
local search_names=require("scripts.journal.search_names")
local widgets=require("scripts.journal.widgets")
local FRAME=widgets.FRAME
local L=widgets.L
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
local update_reader=require("scripts.journal.reader_update")

-- Clicks that only exist inside the story Archive tab.
local ARCHIVE_ACTIONS={
  ["array-record"]=true,["story-alerts"]=true,["record-next-unread"]=true,
  ["archive-filter"]=true,["archive-source"]=true,record=true
}

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
