-- Razi Expedition Journal. A distinct, first-party story/learning interface.
-- Does not change research, grant items or replace source planetary progress.
-- All progress is read from LuaForce technology state; per-player storage
-- contains preferences only, making older saves and force merging safe.
local M={}
local defs=require("scripts.razi_journal_data")
local records=require("scripts.razi_journal_records")
local trials=require("scripts.razi_nexus_trials")
local weather=require("scripts.razi_weather_guide")
local FRAME="razi_expedition_journal"
local TOP="razi_expedition_journal_button"
local TRACKER="razi_expedition_objective_tracker"
local L=function(key,...) return {"journal-ui."..key,...} end
local palette={
  calidus={r=1,g=.72,b=.40},
  solaris={r=1,g=.57,b=.33},
  nyxaris={r=.35,g=.87,b=.72},
  vibrant={r=.68,g=.59,b=1},
  vespera={r=.59,g=.85,b=1},
  beetlejuice={r=1,g=.50,b=.70},
  umbra={r=.80,g=.50,b=.61},
  stellar={r=1,g=.81,b=.50},
  network={r=.54,g=.86,b=.84},
  finale={r=.72,g=.77,b=1},
  foundations={r=.85,g=.76,b=.60},
  fleet={r=.53,g=.79,b=.99},
  outposts={r=.60,g=.85,b=.63},
  sciences={r=.72,g=.65,b=.95},
  defense={r=1,g=.62,b=.49},
  deepworks={r=.67,g=.73,b=.94},
  echoes={r=.98,g=.79,b=.58}
}
M.FRAME=FRAME
M.TOP=TOP
M.TRACKER=TRACKER

local function pref(index)
  storage.razi_expedition_journal=storage.razi_expedition_journal or {}
  local value=storage.razi_expedition_journal[index]
  if not value then
    value={selected=nil,pinned=nil,tracker=false,
      chapter=nil,filter="all",view="quests",record=nil}
    storage.razi_expedition_journal[index]=value
  end
  value.filter=value.filter or "all"
  value.view=value.view or "quests"
  return value
end
M.preferences=pref

-- Find actual native world-discovery research via source mod effect data.
-- One pass per journal view, rather than guessing 19 third-party tech IDs
-- or rescanning thousands of technologies for each side-world quest.
function M.discovery_index(force)
  local indexed={}
  for _,tech in pairs(force and force.technologies or {}) do
    local proto=tech.prototype
    if proto and not proto.hidden then
      for _,effect in pairs(proto.effects or {}) do
        if effect.type=="unlock-space-location" and effect.space_location then
          local existing=indexed[effect.space_location]
          if not existing or (tech.researched and not existing.researched) then
            indexed[effect.space_location]=tech
          end
        end
      end
    end
  end
  return indexed
end
function M.context(force)
  return {discoveries=M.discovery_index(force),nexus=trials.snapshot(force)}
end
local function technology(force,quest,context)
  local t
  if quest.world then
    local index=context and context.discoveries or M.discovery_index(force)
    t=index[quest.world]
  else
    t=force and force.technologies and force.technologies[quest.tech]
  end
  if not t then return nil end
  local proto=t.prototype
  if proto and proto.hidden and not t.researched then return nil end
  return t
end
function M.available(force,quest,context)
  if not technology(force,quest,context) then return false end
  if quest.boss then
    return (context or M.context(force)).nexus~=nil
  end
  return true
end
function M.complete(force,quest,context)
  if quest.boss then
    local snapshot=(context or M.context(force)).nexus
    return M.available(force,quest,context)
      and trials.defeated(snapshot,quest.boss)
  end
  local t=technology(force,quest,context)
  return t~=nil and t.researched==true
end
function M.state(force,quest,context)
  if not M.available(force,quest,context) then return "unavailable" end
  if M.complete(force,quest,context) then return "complete" end
  for _,required in ipairs(quest.requires or {}) do
    local prior=defs.by_id[required]
    -- Source content not present in this modpack is not a phantom
    -- blocker. Its own technology controls actual research prerequisites.
    if prior and M.available(force,prior,context)
      and not M.complete(force,prior,context) then return "locked" end
  end
  return "active"
end
function M.summary(force,context)
  local completed,total,active=0,0,0
  context=context or M.context(force)
  for _,q in ipairs(defs.quests) do
    local state=M.state(force,q,context)
    if state~="unavailable" then
      total=total+1
      if state=="complete" then completed=completed+1
      elseif state=="active" then active=active+1 end
    end
  end
  return completed,total,active
end
function M.next_quest(force,context)
  -- Both first-star branches and each later pair can be active at once.
  context=context or M.context(force)
  for _,q in ipairs(defs.quests) do
    if M.state(force,q,context)=="active" then return q end
  end
  for _,q in ipairs(defs.quests) do
    if M.state(force,q,context)~="unavailable" then return q end
  end
end
function M.show_in_filter(force,quest,filter,context)
  local state=M.state(force,quest,context)
  if state=="unavailable" then return false end
  if filter=="ready" then return state=="active" end
  if filter=="unfinished" then return state~="complete" end
  if filter=="done" then return state=="complete" end
  return true
end
local function label(parent,caption)
  return parent.add{type="label",caption=caption}
end
local function wrap(parent,caption)
  local element=label(parent,caption)
  element.style.single_line=false
  element.style.horizontally_stretchable=true
  return element
end
local function select_quest(force,p,context)
  local selected=p.selected and defs.by_id[p.selected]
  if selected and M.available(force,selected,context) then
    if p.chapter==nil then p.chapter=selected.chapter end
    return selected
  end
  selected=M.next_quest(force,context)
  p.selected=selected and selected.id or nil
  p.chapter=selected and selected.chapter or false
  return selected
end
local function render_tracker(player)
  local area=player.gui.left
  local old=area[TRACKER]
  if old and old.valid then old.destroy() end
  local p=pref(player.index)
  if not p.tracker then return end
  local context=M.context(player.force)
  local quest=p.pinned and defs.by_id[p.pinned]
  if not quest or not M.available(player.force,quest,context) then
    quest=M.next_quest(player.force,context)
    p.pinned=quest and quest.id or nil
  end
  if not quest then return end
  local frame=area.add{type="frame",name=TRACKER,direction="vertical",
    caption=L("tracker-title")}
  frame.style.maximal_width=265
  local heading=frame.add{type="button",
    caption={"journal-title."..quest.id},
    tags={razi_journal_action="tracker-open"}}
  heading.style.horizontally_stretchable=true
  wrap(frame,L(quest.boss
    and (M.complete(player.force,quest,context)
      and "tracker-boss-done" or "tracker-boss-pending")
    or (M.complete(player.force,quest,context)
      and "tracker-done" or "tracker-pending")))
end
M.render_tracker=render_tracker
local function render_details(parent,player,quest,p,context)
  local panel=parent.add{type="frame",direction="vertical",
    style="inside_shallow_frame"}
  panel.style.horizontally_stretchable=true
  panel.style.vertically_stretchable=true
  local title=label(panel,{"journal-title."..quest.id})
  title.style.font="heading-2"
  label(panel,L("status-"..M.state(player.force,quest,context)))
  local objective_bar=panel.add{type="progressbar",
    value=M.complete(player.force,quest,context) and 1 or 0}
  objective_bar.style.horizontally_stretchable=true
  local scroll=panel.add{type="scroll-pane",direction="vertical"}
  scroll.style.horizontally_stretchable=true
  scroll.style.vertically_stretchable=true
  local chapter_intro=label(scroll,{"journal-chapter."..quest.chapter})
  chapter_intro.style.font="default-bold"
  chapter_intro.style.font_color=palette[quest.chapter] or palette.calidus
  wrap(scroll,{"journal-chapter-story."..quest.chapter})
  local section=label(scroll,L("story-heading"))
  section.style.font="default-bold"
  wrap(scroll,{"journal-story."..quest.id})
  local objective=label(scroll,L("objective-heading"))
  objective.style.font="default-bold"
  local native=technology(player.force,quest,context)
  if quest.boss then
    label(scroll,{"",L("objective-boss")," ",
      {"nexus-bosses.boss-"..quest.boss}})
    local record=context.nexus
    if record then
      label(scroll,L("nexus-victories",tostring(record.count),tostring(record.total)))
    end
  else
    label(scroll,{"",L(quest.world and "objective-discovery" or "objective-research",
      native and native.localised_name or quest.world or quest.tech)})
  end
  if native and not native.researched then
    local blockers={}
    for _,prior in pairs(native.prerequisites or {}) do
      if not prior.researched then blockers[#blockers+1]=prior end
    end
    table.sort(blockers,function(a,b) return a.name<b.name end)
    for i=1,math.min(4,#blockers) do
      label(scroll,{"",L("native-prerequisite")," ",
        blockers[i].localised_name})
    end
  end
  if not M.complete(player.force,quest,context) then
    for _,required in ipairs(quest.requires or {}) do
      local prior=defs.by_id[required]
      if prior and M.available(player.force,prior,context)
        and not M.complete(player.force,prior,context) then
        label(scroll,{"",L("requires-heading")," ",
          {"journal-title."..prior.id}})
      end
    end
  end
  local notes=label(scroll,L("tip-heading"))
  notes.style.font="default-bold"
  wrap(scroll,{"journal-tip."..quest.id})
  local forecast=weather.for_quest(quest)
  if forecast then
    local climate_title=label(scroll,L("weather-heading"))
    climate_title.style.font="default-bold"
    wrap(scroll,{"journal-weather."..forecast.world})
    label(scroll,L(forecast.enabled
      and "weather-active" or "weather-inactive"))
  end
  local actions=panel.add{type="flow",direction="horizontal"}
  if quest.boss then
    actions.add{type="button",caption=L("nexus-open-codex"),
      tags={razi_journal_action="nexus-codex",id=quest.boss}}
  end
  local pinned=p.tracker and p.pinned==quest.id
  actions.add{type="button",caption=L(pinned and "tracker-hide" or "tracker-show"),
    tags={razi_journal_action="pin",id=quest.id}}
end
local function render_chapters(parent,player,p,context)
  local left=parent.add{type="scroll-pane",direction="vertical"}
  left.style.minimal_width=250
  left.style.maximal_width=330
  left.style.vertically_stretchable=true
  for _,chapter in ipairs(defs.chapters) do
    local available={}
    local completed,total=0,0
    for _,quest in ipairs(defs.quests) do
      if quest.chapter==chapter.id
        and M.available(player.force,quest,context) then
        total=total+1
        if M.complete(player.force,quest,context) then
          completed=completed+1
        end
        if M.show_in_filter(player.force,quest,p.filter,context) then
          available[#available+1]=quest
        end
      end
    end
    if #available>0 then
      local is_open=p.chapter==chapter.id
      local title=left.add{type="button",
        caption={"",is_open and "▾ " or "▸ ",
          {"journal-chapter."..chapter.id},"  ",
          L("chapter-progress",tostring(completed),tostring(total))},
        tags={razi_journal_action="chapter",id=chapter.id}}
      title.style.font="default-bold"
      title.style.horizontally_stretchable=true
      if is_open then
        for _,quest in ipairs(available) do
          local state=M.state(player.force,quest,context)
          local btn=left.add{type="button",
            caption={"",state=="complete" and "[color=#7CD9AD]✓[/color] "
                or state=="active" and "[color=#F2CE83]●[/color] "
                or "[color=#9B9FAE]○[/color] ",
              {"journal-title."..quest.id}},
            tags={razi_journal_action="select",id=quest.id}}
          btn.style.horizontally_stretchable=true
          if quest.id==p.selected then btn.style.font="default-bold" end
        end
      end
    end
  end
end
-- The archive is not another quest chain. Each story entry opens only
-- when its source-backed research milestone is actually completed.
function M.unlocked_records(force,context)
  context=context or M.context(force)
  local unlocked=0
  for _,record in ipairs(records) do
    local q=defs.by_id[record.unlock]
    if q and M.complete(force,q,context) then unlocked=unlocked+1 end
  end
  return unlocked,#records
end
local function render_archive(parent,player,p,context)
  local left=parent.add{type="scroll-pane",direction="vertical"}
  left.style.minimal_width=245
  left.style.maximal_width=315
  left.style.vertically_stretchable=true
  local chosen
  for _,record in ipairs(records) do
    local quest=defs.by_id[record.unlock]
    local opened=quest and M.complete(player.force,quest,context)
    if opened and (not chosen or record.id==p.record) then chosen=record end
    local button=left.add{type="button",
      caption={"",opened and "[color=#7CD9AD]◈[/color] "
          or "[color=#999BA4]◇[/color] ",
        {"journal-record-title."..record.id}},
      tags={razi_journal_action="record",id=record.id}}
    button.style.horizontally_stretchable=true
    button.enabled=opened and true or false
  end
  if not chosen then
    label(parent,L("archive-sealed"))
    return
  end
  p.record=chosen.id
  local pane=parent.add{type="scroll-pane",direction="vertical"}
  pane.style.horizontally_stretchable=true
  pane.style.vertically_stretchable=true
  local title=label(pane,{"journal-record-title."..chosen.id})
  title.style.font="heading-2"
  local origin=label(pane,{"journal-record-origin."..chosen.id})
  origin.style.font_color=palette.echoes
  wrap(pane,{"journal-record-body."..chosen.id})
  label(pane,L("archive-disclaimer"))
end

local function draw(player)
  local frame=player.gui.screen[FRAME]
  if not (frame and frame.valid) then return end
  local p=pref(player.index)
  frame.clear()
  local head=frame.add{type="flow",direction="horizontal"}
  head.style.horizontally_stretchable=true
  local name=label(head,L("window"))
  name.style.font="heading-2"
  local drag=head.add{type="empty-widget",style="draggable_space"}
  drag.style.horizontally_stretchable=true
  drag.style.height=30
  drag.drag_target=frame
  head.add{type="button",caption=L("refresh"),
    tags={razi_journal_action="refresh"}}
  head.add{type="button",caption=L("close"),
    tags={razi_journal_action="close"}}
  wrap(frame,L("subtitle"))
  local context=M.context(player.force)
  local done,total,ready=M.summary(player.force,context)
  label(frame,L("summary",tostring(done),tostring(total),tostring(ready)))
  local overall=frame.add{type="progressbar",
    value=total>0 and done/total or 0}
  overall.style.horizontally_stretchable=true
  local actions=frame.add{type="flow",direction="horizontal"}
  actions.style.horizontally_stretchable=true
  for _,view in ipairs({"quests","archive"}) do
    local button=actions.add{type="button",caption=L("view-"..view),
      tags={razi_journal_action="view",id=view}}
    if p.view==view then button.style.font="default-bold" end
  end
  if p.view~="archive" then
    actions.add{type="button",caption=L("next-milestone"),
      tags={razi_journal_action="next"}}
  end
  if p.view=="archive" then
    local opened,all=M.unlocked_records(player.force,context)
    label(frame,L("archive-progress",tostring(opened),tostring(all)))
  else
    for _,filter in ipairs({"all","ready","unfinished","done"}) do
      local button=actions.add{type="button",
        caption=L("filter-"..filter),
        tags={razi_journal_action="filter",id=filter}}
      if p.filter==filter then button.style.font="default-bold" end
    end
  end
  local body=frame.add{type="flow",direction="horizontal"}
  body.style.horizontally_stretchable=true
  body.style.height=math.max(300,math.min(580,
    math.floor(player.display_resolution.height/math.max(1,player.display_scale)*.57)))
  if p.view=="archive" then
    render_archive(body,player,p,context)
  else
    local selected=select_quest(player.force,p,context)
    render_chapters(body,player,p,context)
    if selected then
      render_details(body,player,selected,p,context)
    else
      wrap(body,L("missing-quest"))
    end
  end
  wrap(frame,L("no-reward"))
end
M.draw=draw
local function open(player)
  local frame=player.gui.screen[FRAME]
  if frame and frame.valid then draw(player);return end
  local scale=math.max(1,player.display_scale)
  local width=math.max(480,math.min(960,
    math.floor(player.display_resolution.width/scale)-64))
  frame=player.gui.screen.add{type="frame",name=FRAME,direction="vertical"}
  frame.style.width=width
  frame.location={x=math.max(8,math.floor(
    (player.display_resolution.width/scale-width)/2)),
    y=math.max(20,math.floor(player.display_resolution.height/scale*.07))}
  player.opened=frame
  draw(player)
end
M.open=open
local function close(player)
  local frame=player.gui.screen[FRAME]
  if frame and frame.valid then frame.destroy() end
end
M.close=close
function M.toggle(player)
  if player.gui.screen[FRAME] then close(player) else open(player) end
end
function M.sync(player)
  if not (player and player.valid) then return end
  local top=player.gui.top[TOP]
  if not (top and top.valid) then
    top=player.gui.top.add{type="sprite-button",
      name=TOP,sprite="razi-journal-book-icon",
      style="slot_button",tooltip=L("button-tooltip"),
      tags={razi_journal_action="toggle"}}
    top.style.width=36
    top.style.height=36
  end
  render_tracker(player)
end
function M.sync_all()
  for _,player in pairs(game.connected_players or {}) do M.sync(player) end
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
      if frame and frame.valid then draw(player) end
      local p=pref(player.index)
      if p.tracker then render_tracker(player) end
    end
  end
end
function M.on_research(event)
  -- /cheat and other scripted unlocks can finish hundreds of technologies in
  -- one simulation tick. Rebuilding an open journal for every event overloads
  -- Factorio's GUI renderer, so collapse that burst into one later refresh.
  local force=event and event.research and event.research.force
  if not force then return end
  if event.by_script then
    storage.razi_journal_pending_forces=
      storage.razi_journal_pending_forces or {}
    storage.razi_journal_pending_forces[force.name]=true
    return
  end
  refresh_force(force)
end
function M.flush_research_refreshes()
  local pending=storage.razi_journal_pending_forces
  if not pending then return end
  storage.razi_journal_pending_forces=nil
  for force_name in pairs(pending) do
    refresh_force(game.forces[force_name])
  end
end
-- Refresh only visible boss objectives during the existing ten-second
-- maintenance tick. No global entity scans or per-tick remote calls.
function M.refresh_nexus_visible()
  if not (remote and remote.interfaces and
    remote.interfaces["nexus-bosses"]) then return end
  for _,player in pairs(game.connected_players or {}) do
    local p=storage.razi_expedition_journal
      and storage.razi_expedition_journal[player.index]
    if p then
      local frame=player.gui.screen[FRAME]
      if frame and frame.valid and (p.chapter=="deepworks"
        or (p.selected and defs.by_id[p.selected]
          and defs.by_id[p.selected].boss)) then
        draw(player)
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
  local action=tags and tags.razi_journal_action
  if not action then return end
  local player=game.get_player(event.player_index)
  if not (player and player.valid) then return end
  if action=="toggle" then M.toggle(player);return end
  if action=="close" then close(player);return end
  if action=="nexus-codex" then
    if not trials.open_codex(player,tags.id) then
      player.print(L("nexus-codex-unavailable"))
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
  if action=="select" and defs.by_id[tags.id]
    and M.available(player.force,defs.by_id[tags.id]) then
    p.selected=tags.id
    p.chapter=defs.by_id[tags.id].chapter
  elseif action=="chapter" then
    p.chapter=p.chapter==tags.id and false or tags.id
  elseif action=="view" and (tags.id=="quests" or tags.id=="archive") then
    p.view=tags.id
  elseif action=="record" then
    local context=M.context(player.force)
    for _,record in ipairs(records) do
      if record.id==tags.id then
        local quest=defs.by_id[record.unlock]
        if quest and M.complete(player.force,quest,context) then
          p.record=record.id
          p.view="archive"
        end
        break
      end
    end
  elseif action=="filter" and ({all=true,ready=true,unfinished=true,
      done=true})[tags.id] then
    p.filter=tags.id
  elseif action=="next" then
    local next=M.next_quest(player.force)
    if next then
      p.selected=next.id
      p.chapter=next.chapter
      p.filter="all"
      p.view="quests"
    end
  elseif action=="pin" and defs.by_id[tags.id] then
    if p.tracker and p.pinned==tags.id then
      p.tracker=false
    else
      p.pinned=tags.id;p.tracker=true
    end
    render_tracker(player)
  elseif action~="refresh" then return end
  draw(player)
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
  if player.gui.screen[FRAME] then
    close(player)
    open(player)
  end
end
return M
