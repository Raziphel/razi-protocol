-- Razi Expedition Journal. A distinct, first-party story/learning interface.
-- Does not change research, grant items or replace source planetary progress.
-- All progress is read from LuaForce technology state; per-player storage
-- contains preferences only, making older saves and force merging safe.
local M={}
local defs=require("scripts.razi_journal_data")
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
  finale={r=.72,g=.77,b=1}
}
M.FRAME=FRAME
M.TOP=TOP
M.TRACKER=TRACKER

local function pref(index)
  storage.razi_expedition_journal=storage.razi_expedition_journal or {}
  local value=storage.razi_expedition_journal[index]
  if not value then
    value={selected=nil,pinned=nil,tracker=false}
    storage.razi_expedition_journal[index]=value
  end
  return value
end
M.preferences=pref
local function technology(force,quest)
  local t=force and force.technologies and force.technologies[quest.tech]
  if not t then return nil end
  local proto=t.prototype
  if proto and proto.hidden and not t.researched then return nil end
  return t
end
function M.available(force,quest)
  return technology(force,quest)~=nil
end
function M.complete(force,quest)
  local t=technology(force,quest)
  return t~=nil and t.researched==true
end
function M.state(force,quest)
  local t=technology(force,quest)
  if not t then return "unavailable" end
  if t.researched then return "complete" end
  for _,required in ipairs(quest.requires or {}) do
    local prior=defs.by_id[required]
    -- Source content not present in this modpack is not a phantom
    -- blocker. Its own technology controls actual research prerequisites.
    if prior and M.available(force,prior)
      and not M.complete(force,prior) then return "locked" end
  end
  return "active"
end
function M.summary(force)
  local completed,total,active=0,0,0
  for _,q in ipairs(defs.quests) do
    local state=M.state(force,q)
    if state~="unavailable" then
      total=total+1
      if state=="complete" then completed=completed+1
      elseif state=="active" then active=active+1 end
    end
  end
  return completed,total,active
end
function M.next_quest(force)
  -- Both first star branches and both later pairs can be active at once.
  for _,q in ipairs(defs.quests) do
    if M.state(force,q)=="active" then return q end
  end
  for _,q in ipairs(defs.quests) do
    if M.state(force,q)~="unavailable" then return q end
  end
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
local function select_quest(force,p)
  local selected=p.selected and defs.by_id[p.selected]
  if selected and M.available(force,selected) then return selected end
  selected=M.next_quest(force)
  p.selected=selected and selected.id or nil
  return selected
end
local function render_tracker(player)
  local area=player.gui.left
  local old=area[TRACKER]
  if old and old.valid then old.destroy() end
  local p=pref(player.index)
  if not p.tracker then return end
  local quest=p.pinned and defs.by_id[p.pinned]
  if not quest or not M.available(player.force,quest) then
    quest=M.next_quest(player.force)
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
  wrap(frame,L(M.complete(player.force,quest) and "tracker-done" or "tracker-pending"))
end
M.render_tracker=render_tracker
local function render_details(parent,player,quest,p)
  local panel=parent.add{type="frame",direction="vertical",
    style="inside_shallow_frame"}
  panel.style.horizontally_stretchable=true
  panel.style.vertically_stretchable=true
  local title=label(panel,{"journal-title."..quest.id})
  title.style.font="heading-2"
  label(panel,L("status-"..M.state(player.force,quest)))
  local objective_bar=panel.add{type="progressbar",
    value=M.complete(player.force,quest) and 1 or 0}
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
  local native=player.force.technologies[quest.tech]
  label(scroll,{"",L("objective-research",native and native.localised_name
      or quest.tech)})
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
  if not M.complete(player.force,quest) then
    for _,required in ipairs(quest.requires or {}) do
      local prior=defs.by_id[required]
      if prior and M.available(player.force,prior)
        and not M.complete(player.force,prior) then
        label(scroll,{"",L("requires-heading")," ",
          {"journal-title."..prior.id}})
      end
    end
  end
  local notes=label(scroll,L("tip-heading"))
  notes.style.font="default-bold"
  wrap(scroll,{"journal-tip."..quest.id})
  local actions=panel.add{type="flow",direction="horizontal"}
  local pinned=p.tracker and p.pinned==quest.id
  actions.add{type="button",caption=L(pinned and "tracker-hide" or "tracker-show"),
    tags={razi_journal_action="pin",id=quest.id}}
end
local function render_chapters(parent,player,p)
  local left=parent.add{type="scroll-pane",direction="vertical"}
  left.style.minimal_width=250
  left.style.maximal_width=330
  left.style.vertically_stretchable=true
  for _,chapter in ipairs(defs.chapters) do
    local available={}
    local completed=0
    for _,quest in ipairs(defs.quests) do
      if quest.chapter==chapter.id and M.available(player.force,quest) then
        available[#available+1]=quest
        if M.complete(player.force,quest) then completed=completed+1 end
      end
    end
    if #available>0 then
      local title=label(left,{"",
        {"journal-chapter."..chapter.id},"  ",L("chapter-progress",
         tostring(completed),tostring(#available))})
      title.style.font="default-bold"
      title.style.font_color=palette[chapter.id] or palette.calidus
      for _,quest in ipairs(available) do
        local state=M.state(player.force,quest)
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
  local done,total=M.summary(player.force)
  label(frame,L("summary",tostring(done),tostring(total)))
  local overall=frame.add{type="progressbar",
    value=total>0 and done/total or 0}
  overall.style.horizontally_stretchable=true
  local body=frame.add{type="flow",direction="horizontal"}
  body.style.horizontally_stretchable=true
  body.style.height=math.max(300,math.min(580,
    math.floor(player.display_resolution.height/math.max(1,player.display_scale)*.57)))
  local selected=select_quest(player.force,p)
  render_chapters(body,player,p)
  if selected then
    render_details(body,player,selected,p)
  else
    wrap(body,L("missing-quest"))
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
function M.on_research(event)
  -- Called only on a completed native technology, never each tick.
  local force=event and event.research and event.research.force
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
