-- The Journal window: its size, the full redraw and opening and closing it.
local M=require("scripts.journal.api")
local defs=require("scripts.journal.data")
local story=require("lib.story")
local trials=require("scripts.compatibility.nexus-bosses.trials")
local projects=require("scripts.journal.projects")
local systems=require("scripts.journal.systems")
local marks=require("scripts.journal.marks")
local themes=require("scripts.journal.themes")
local icons=require("scripts.journal.icons")
local search_names=require("scripts.journal.search_names")
local widgets=require("scripts.journal.widgets")
local FRAME=widgets.FRAME
local L=widgets.L
local COLOR=widgets.COLOR
local label=widgets.label
local wrap=widgets.wrap
local tint=widgets.tint
local subtitle=widgets.subtitle
local accent_rule=widgets.accent_rule
local pref=require("scripts.journal.preferences")
local archive_view=require("scripts.journal.archive_view")
local record_open=archive_view.record_open
local render_archive=archive_view.render_archive
local render_details=require("scripts.journal.dossier")
local chapter_cover=require("scripts.journal.chapter_cover")
local render_chapter_cover=chapter_cover.render_chapter_cover
local navigator=require("scripts.journal.navigator")
local select_quest=navigator.select_quest
local render_chapters=navigator.render_chapters

-- Dimensions are in Factorio GUI units, after the player's UI scale.
-- Explicitly budget both columns to prevent the horizontal scroll bars
-- caused by oversized localized labels and autosizing buttons.
function M.layout(resolution,scale)
  scale=math.max(0.5,scale or 1)
  local screen_w=math.floor((resolution and resolution.width or 1600)/scale)
  local screen_h=math.floor((resolution and resolution.height or 900)/scale)
  local width=math.min(1190,math.max(420,screen_w-52))
  local height=math.min(930,math.max(390,screen_h-64))
  local compact=width<1020 or height<660
  -- Below this width, two simultaneous columns make the dossier unreadable.
  -- Present a full-size document and switch to its index on demand.
  local single_column=width<740
  local rail=math.min(compact and 282 or 302,
    math.max(228,math.floor(width*(compact and .30 or .255))))
  local reader=width-rail-43
  return {width=width,height=height,rail=rail,reader=reader,
    body=math.max(200,height-(compact and 183 or 204)),
    compact=compact,single_column=single_column}
end

-- Factorio does not expose a scroll-pane's pixel offset to scripts.
-- Remember which *source-owned* boss victories the open Codex last rendered
-- so ten-second Nexus polls cannot destroy a player's scrolled reading pane.
local function nexus_revision(snapshot)
  if not snapshot then return "unavailable" end
  local bits={}
  for _,id in ipairs(trials.order) do
    bits[#bits+1]=trials.defeated(snapshot,id) and "1" or "0"
  end
  return table.concat(bits)
end
local function draw(player,focus_search)
  local frame=player.gui.screen[FRAME]
  if not (frame and frame.valid) then return end
  local p=pref(player.index)
  search_names.request(player,defs.quests,defs.quest_title)
  -- Retired and uninstalled optional chapters must never leave the reader
  -- stranded on an old chapter ID when an existing save is reopened.
  if p.chapter then
    local present=false
    for _,chapter in ipairs(defs.chapters) do
      if chapter.id==p.chapter then present=true break end
    end
    if not present then
      p.chapter=false
      p.chapter_cover=false
    end
  end
  if p.selected and not defs.by_id[p.selected] then p.selected=nil end
  if p.pinned and not defs.by_id[p.pinned] then p.pinned=nil end
  local context=M.context(player.force,player)
  if M.hide_spoilers() then
    local quest=p.selected and defs.by_id[p.selected]
    if quest and not M.journal_visible(player.force,quest,context) then
      p.selected=nil
    end
    if p.chapter then
      local exposed=false
      for _,candidate in ipairs(defs.quests) do
        if candidate.chapter==p.chapter
          and M.journal_visible(player.force,candidate,context) then
          exposed=true;break
        end
      end
      if not exposed then
        p.chapter=false
        p.chapter_cover=false
      end
    end
  end
  local size=M.layout(player.display_resolution,player.display_scale)
  -- Focus widens only the quest reader. Hidden chapter widgets stay alive,
  -- so opening the index again does not lose its scroll position.
  if (p.view~="systems" and p.reader_focus)
    or (p.view=="quests" and size.single_column) then
    size.reader=size.width-43
  end
  local chapter_theme=p.view=="systems" and "network"
    or (p.view=="projects" and "stellar" or p.chapter or "calidus")
  local window_theme=themes.get(chapter_theme)
  frame.clear()
  frame.style.width=size.width
  frame.style.padding=10
  local head=frame.add{type="flow",direction="horizontal"}
  head.style.horizontally_stretchable=true
  head.style.vertical_align="center"
  head.style.horizontal_spacing=8
  icons.sprite(head,"razi-corporate-emblem","window_emblem")
  local heading=head.add{type="flow",direction="vertical"}
  heading.style.vertical_spacing=1
  local title=label(heading,L(size.compact and "window-compact" or "window"))
  title.style.font="heading-2"
  title.style.font_color=COLOR.ink
  local kicker=tint(label(heading,L("header-eyebrow")),COLOR.muted)
  kicker.style.font="default"
  kicker.visible=not size.compact
  local drag=head.add{type="empty-widget",style="draggable_space_header"}
  drag.style.horizontally_stretchable=true
  drag.style.height=19
  drag.drag_target=frame
  local focus=head.add{type="button",
    caption=L(p.reader_focus and "focus-show-index" or "focus-read"),
    tooltip=L("focus-tooltip"),
    tags={razi_journal_action="focus"}}
  focus.visible=p.view~="systems"
    and not (p.view=="quests" and size.single_column)
  local compact_switch=head.add{type="button",
    caption=L(p.compact_index_open and "compact-read" or "compact-index"),
    tags={razi_journal_action="compact-index"},
    tooltip=L("compact-index-tooltip")}
  compact_switch.visible=p.view=="quests" and size.single_column
  focus.style.minimal_width=size.compact and 55 or 94
  local refresh=head.add{type="button",style="tool_button",
    caption=marks.refresh,tooltip=L("refresh"),
    tags={razi_journal_action="refresh"}}
  refresh.style.width=30
  refresh.style.height=30
  local dismiss=head.add{type="button",style="tool_button",
    caption=marks.close,tooltip=L("close"),
    tags={razi_journal_action="close"}}
  dismiss.style.width=30
  dismiss.style.height=30
  -- The old subtitle restated the masthead and consumed a full screen row.

  p.nexus_revision=nexus_revision(context.nexus)
  local view=p.view=="quests" and M.view_status(player.force,context) or nil
  local plan=view and M.guidance(player.force,context,view)
  local done,total,ready
  if view then
    done,total,ready=view.done,view.total,view.ready
  else
    done,total,ready=M.summary(player.force,context)
  end
  -- Editorial status strip: honest progress, no generic dashboard tiles.
  local totals=frame.add{type="flow",name="razi_journal_overview",direction="vertical"}
  totals.visible=p.view~="systems"
  totals.style.horizontally_stretchable=true
  totals.style.vertical_spacing=2
  local metrics_row=totals.add{type="flow",name="razi_journal_metrics",direction="horizontal"}
  metrics_row.style.horizontally_stretchable=true
  metrics_row.style.vertical_align="center"
  metrics_row.style.horizontal_spacing=size.compact and 8 or 18
  local metric=metrics_row.add{type="flow",name="razi_journal_completion",direction="horizontal"}
  metric.style.horizontal_spacing=5
  subtitle(metric,"completion-heading")
  local completed=metric.add{type="label",name="razi_journal_completed",
    caption=L("completion-value",tostring(done),tostring(total))}
  completed.tooltip=L("progress-tooltip")
  completed.style.font="default-bold"
  completed.style.font_color=COLOR.ink
  local readiness=metrics_row.add{type="flow",name="razi_journal_readiness",direction="horizontal"}
  readiness.style.horizontal_spacing=5
  subtitle(readiness,"ready-heading")
  local ready_label=readiness.add{type="label",name="razi_journal_ready",style="clickable_label",
    caption=L("ready-value",tostring(ready)),
    tooltip=L("filter-ready-tooltip"),
    tags={razi_journal_action="filter-ready"}}
  ready_label.style.font="default-bold"
  ready_label.style.font_color=COLOR.amber
  local meter=totals.add{type="flow",name="razi_journal_meter",direction="vertical"}
  meter.style.horizontally_stretchable=true
  meter.style.vertical_spacing=2
  local overall=meter.add{type="progressbar",name="razi_journal_progress",
    value=total>0 and done/total or 0}
  overall.style.width=math.min(250,math.floor(size.width*.2))
  overall.style.height=3
  overall.style.color=window_theme.primary

  local toolbar=frame.add{type="flow",direction="horizontal"}
  toolbar.style.horizontal_spacing=size.single_column and 8
    or size.compact and 15 or 24
  toolbar.style.vertical_align="bottom"
  -- The three folios use typographic navigation and a slender active rule.
  for _,view in ipairs(story.visible(player) -- luacheck: ignore 421
      and {"quests","projects","archive","systems"}
      or {"quests","projects","systems"}) do
    local active=p.view==view
    local folio=toolbar.add{type="flow",direction="vertical"}
    folio.style.vertical_spacing=3
    local line=folio.add{type="flow",direction="horizontal"}
    line.style.horizontal_spacing=size.single_column and 3 or 5
    line.style.vertical_align="center"
    local theme_id=view=="quests" and (p.chapter or "calidus")
      or view=="projects" and "stellar"
      or view=="archive" and "echoes" or "network"
    icons.sprite(line,themes.icon(theme_id),"tab_icon")
    local button=line.add{type="label",style="clickable_label",
      caption=L("view-"..view),tags={razi_journal_action="view",id=view}}
    button.style.font=active and "default-bold" or "default"
    button.style.font_color=active and COLOR.ink or COLOR.muted
    if active then accent_rule(folio,window_theme,76,2) end
  end
  if p.view=="quests" and not size.single_column then
    local spacer=toolbar.add{type="empty-widget"}
    spacer.style.horizontally_stretchable=true
    toolbar.add{type="button",caption=L("next-milestone"),
      tags={razi_journal_action="next"}}
  end
  local filterbar=frame.add{type="flow",name="razi_journal_filterbar",direction="horizontal"}
  -- Quest filters now live beside their chapter search, not in a separate
  -- window-wide toolbar that competes with the four primary folios.
  filterbar.visible=p.view~="quests"
  filterbar.style.horizontal_spacing=6
  filterbar.style.vertical_align="center"
  if p.view=="archive" then
    local unlocked,all=M.unlocked_records(player.force,context,player)
    tint(label(filterbar,L("archive-progress",
      tostring(unlocked),tostring(all))),themes.get("echoes").primary)
    local unread=0
    for _,record in ipairs(story.records(player)) do
      local q=defs.by_id[record.unlock]
      if p.story_unread and p.story_unread[record.id]
        and record_open(player,q,q and M.complete(player.force,q,context)) then
        unread=unread+1
      end
    end
    if unread>0 then
      local news=label(filterbar,L("archive-unread",tostring(unread)))
      news.style.font_color=COLOR.amber
      filterbar.add{type="button",
        caption=L("archive-read-next"),
        tags={razi_journal_action="record-next-unread"}}
    end
    local spacer=filterbar.add{type="empty-widget"}
    spacer.style.horizontally_stretchable=true
    filterbar.add{type="label",style="clickable_label",
      caption=L(p.story_alerts and "archive-alerts-on" or "archive-alerts-off"),
      tooltip=L("archive-alerts-tooltip"),
      tags={razi_journal_action="story-alerts"}}
  elseif p.view=="projects" then
    tint(label(filterbar,L("projects-hint")),window_theme.soft)
  elseif p.view=="systems" then
    tint(label(filterbar,{"journal-systems.status-strip"}),window_theme.soft)
    local spacer=filterbar.add{type="empty-widget"}
    spacer.style.horizontally_stretchable=true
    filterbar.add{type="button",name="razi_journal_systems_native",
      caption=L(p.native_controls_visible and "systems-native-hide" or
        "systems-native-show"),
      tooltip=L("systems-native-tooltip"),
      tags={razi_journal_action="systems-native"}}
  else
    subtitle(filterbar,"filter-heading")
    for _,filter in ipairs({"all","ready","unfinished","done"}) do
      local active=p.filter==filter
      local button=filterbar.add{type="label",name="razi_journal_filter_"..filter,
        style="clickable_label",
        caption=L("filter-"..filter),
        tags={razi_journal_action="filter",id=filter}}
      button.style.font=active and "default-bold" or "default"
      button.style.font_color=active and COLOR.ink or COLOR.quiet
    end
  end

  local body=frame.add{type="flow",
    name=p.view=="systems" and "razi_journal_systems_body" or "razi_journal_content",
    direction="horizontal"}
  body.style.width=size.width-33
  body.style.height=size.body
  body.style.horizontal_spacing=10
  if p.view=="archive" then
    render_archive(body,player,p,context,size)
  elseif p.view=="projects" then
    projects.render(body,player,p,size)
  elseif p.view=="systems" then
    systems.render(body,player,size)
  else
    local selected=select_quest(player.force,p,context,plan)
    local search=render_chapters(body,player,p,context,size,view,plan)
    local navigation=body["razi_journal_navigation_panel"]
    local on_small_screen=size.single_column
    if navigation then
      navigation.visible=on_small_screen and p.compact_index_open
        or (not on_small_screen and not p.reader_focus)
    end
    local reader=body.add{type="flow",name="razi_journal_reader_host",direction="vertical"}
    reader.visible=not (on_small_screen and p.compact_index_open)
    reader.style.width=size.reader
    if focus_search then pcall(function() search.focus() end) end
    if p.chapter_cover and render_chapter_cover(
      reader,player,p,context,size,view) then -- luacheck: ignore 542
      -- A full chapter frontispiece replaces the quest reader until a
      -- real quest entry is selected.
    elseif selected then
      render_details(reader,player,selected,p,context,size,view)
    else
      local empty=reader.add{type="frame",
        style="inside_shallow_frame_with_padding"}
      empty.style.width=size.reader
      local missing_start=not M.available(player.force,
        defs.by_id["first-signal"],context)
      wrap(empty,missing_start and L("bootstrap-research-missing")
        or L("missing-quest"),size.reader-40)
    end
  end
  -- No decorative footer: useful space belongs to the dossiers.
end

M.draw=draw
local function open(player)
  local frame=player.gui.screen[FRAME]
  if frame and frame.valid then draw(player);return end
  local size=M.layout(player.display_resolution,player.display_scale)
  local scale=math.max(.5,player.display_scale or 1)
  frame=player.gui.screen.add{type="frame",name=FRAME,direction="vertical"}
  frame.style.width=size.width
  frame.location={
    x=math.max(8,math.floor((player.display_resolution.width/scale-size.width)/2)),
    y=math.max(10,math.floor((player.display_resolution.height/scale-size.height)/2))
  }
  player.opened=frame
  draw(player)
end
M.open=open
function M.open_project(player,id)
  if not (player and player.valid) then return false end
  if id=="recovery" then
    -- The old project ID now points to its actual research milestones.
    return M.open_quest(player,"athos")
  elseif id and not projects.visible(player.force,id) then
    return false
  end
  local p=pref(player.index)
  p.view="projects"
  p.project=id or p.project
  open(player)
  return true
end
function M.open_quest(player,id)
  local quest=defs.by_id[id]
  if not (player and player.valid and quest
    and M.journal_visible(player.force,quest,M.context(player.force,player)))
  then return false end
  local p=pref(player.index)
  p.selected=quest.id
  p.chapter=quest.chapter
  p.filter="all"
  p.query=""
  p.view="quests"
  p.chapter_cover=false
  p.compact_index_open=false
  open(player)
  return true
end
-- Opens the cover of one chapter. False for an unknown chapter.
function M.open_chapter(player,id)
  if not (player and player.valid) then return false end
  local known=false
  for _,chapter in ipairs(defs.chapters) do
    if chapter.id==id then known=true;break end
  end
  if not known then return false end
  local p=pref(player.index)
  p.view="quests"
  p.chapter=id
  p.chapter_cover=true
  p.filter="all"
  p.query=""
  p.compact_index_open=false
  open(player)
  return true
end
-- Opens the Archive tab. False while the player cannot see the story.
function M.open_archive(player)
  if not (player and player.valid and story.visible(player)) then return false end
  pref(player.index).view="archive"
  open(player)
  return true
end
local function close(player)
  local frame=player.gui.screen[FRAME]
  if frame and frame.valid then frame.destroy() end
end
M.close=close
function M.toggle(player)
  if player.gui.screen[FRAME] then close(player) else open(player) end
end

return {draw=draw,open=open,close=close,nexus_revision=nexus_revision}
