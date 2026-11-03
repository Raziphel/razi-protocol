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
local chapter_timing=require("scripts.journal.chapter_timing")
local journal_acts=require("scripts.journal.acts")
local marks=require("scripts.journal.marks")
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
local COLOR=widgets.COLOR
local label=widgets.label
local wrap=widgets.wrap
local tint=widgets.tint
local subtitle=widgets.subtitle
local accent_rule=widgets.accent_rule
local chapter_index=widgets.chapter_index
local show_player_option=widgets.show_player_option
local pref=require("scripts.journal.preferences")
local quest_state=require("scripts.journal.quest_state")
local completion_caption=quest_state.completion_caption
local state_matches_filter=quest_state.state_matches_filter
local matches_query=quest_state.matches_query
local render_tracker=require("scripts.journal.tracker")
local archive_view=require("scripts.journal.archive_view")
local record_open=archive_view.record_open
local render_archive=archive_view.render_archive
local render_details=require("scripts.journal.dossier")
local chapter_cover=require("scripts.journal.chapter_cover")
local render_chapter_cover=chapter_cover.render_chapter_cover
local navigator=require("scripts.journal.navigator")
local select_quest=navigator.select_quest
local render_chapters=navigator.render_chapters
M.chapter_theme=themes.get
M.chapter_icon=themes.icon

M.FRAME=FRAME
M.TOP=TOP
M.TRACKER=TRACKER




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
      local missing_start=not (player.force.technologies
        and player.force.technologies["automation"])
      wrap(empty,missing_start and L("bootstrap-research-missing")
        or L("missing-quest"),size.reader-40)
    end
  end
  -- No decorative footer: useful space belongs to the dossiers.
end
-- A new quest updates only the document, leaving the original chapter
-- scroll pane alive.
-- Razi 3.0: keep the native navigator and its scrollbar alive while the
-- right-hand dossier and source-backed status are refreshed independently.
local function update_reader(player,preserve_reader)
  local frame=player.gui.screen[FRAME]
  local body=frame and frame.valid and frame["razi_journal_content"]
  local reader=body and body.valid and body["razi_journal_reader_host"]
  local navigation=body and body.valid and body["razi_journal_navigation_panel"]
  local scroll=navigation and navigation.valid
    and navigation["razi_journal_navigation"]
  local column=scroll and scroll.valid and scroll["razi_journal_chapter_column"]
  if not (reader and reader.valid and column and column.valid) then
    draw(player)
    return
  end
  local p=pref(player.index)
  local translated=search_names.names(player.index)
  local context=M.context(player.force,player)
  local size=M.layout(player.display_resolution,player.display_scale)
  if p.reader_focus or size.single_column then size.reader=size.width-43 end
  local view=M.view_status(player.force,context)
  -- A newly discovered/visible quest needs its first native GUI row built.
  -- That is the exceptional case where a full redraw is actually required.
  for index,ch in ipairs(defs.chapters) do
    local data=view.chapters[ch.id]
    local card=column["razi_journal_chapter_"..index]
    ---@diagnostic disable-next-line: need-check-nil
    if #data.quests>0 and not card then draw(player);return end
    local entries=card and card["razi_journal_chapter_entries"]
    if entries then
      ---@diagnostic disable-next-line: need-check-nil, param-type-mismatch
      for _,quest in ipairs(data.quests) do
        if not entries["razi_journal_item_"..quest.id] then
          draw(player)
          return
        end
      end
    end
  end
  local plan=M.guidance(player.force,context,view)
  local selected=select_quest(player.force,p,context,plan)
  if size.single_column then
    navigation.visible=p.compact_index_open
    reader.visible=not p.compact_index_open
  end
  p.nexus_revision=nexus_revision(context.nexus)
  for index,ch in ipairs(defs.chapters) do
    local data=view.chapters[ch.id]
    local card=column["razi_journal_chapter_"..index]
    if card then
      local entries=card["razi_journal_chapter_entries"]
      local head=card["razi_journal_chapter_head"]
      local toggle=head and head["razi_journal_chapter_toggle"]
      local count_holder=card["razi_journal_chapter_status"]
      local count=count_holder and count_holder["razi_journal_chapter_count"]
      local heading=head and head["razi_journal_chapter_title"]
      local shown=0
      local matching_acts={}
      ---@diagnostic disable-next-line: need-check-nil, param-type-mismatch
      for _,quest in ipairs(data.quests) do
        local row=entries and entries["razi_journal_item_"..quest.id]
        if row then
          local state=view.states[quest.id]
          local matching=state_matches_filter(state,p.filter)
            and matches_query(quest,p.query,translated)
          row.visible=matching
          if matching then
            shown=shown+1
            local act=journal_acts.for_quest(quest)
            if act then matching_acts[act.key]=true end
          end
          local choice=row["razi_journal_item_choice"]
          local marker=row["razi_journal_item_control"]
          local chosen=p.selected==quest.id and not p.chapter_cover
          local milestone_time=completion_caption(
            chapter_timing.get(player.force,"milestones",quest.id),"milestone")
          local milestone_tooltip=milestone_time
            and {"",defs.quest_title(quest,player),"\n",milestone_time}
            or defs.quest_title(quest,player)
          if choice then choice.tooltip=milestone_tooltip end
          if marker then marker.tooltip=milestone_tooltip end
          local selection=row["razi_journal_item_rule"]
          if selection then selection.visible=chosen end
          if choice then
            choice.style.font=chosen and "default-bold" or "default"
            choice.style.font_color=chosen and COLOR.ink
              or state=="active" and themes.get(ch.id).soft or COLOR.muted
          end
          if marker then
            marker.caption=state=="complete" and marks.done
              or state=="active" and marks.active or marks.pending
            marker.style.font_color=chosen and themes.get(ch.id).primary
              or state=="complete" and COLOR.green
              or state=="active" and COLOR.amber or COLOR.quiet
          end
        end
      end
      card.visible=shown>0
      if entries then
        for _,act in ipairs(journal_acts.chapters[ch.id] or {}) do
          local divider=entries["razi_journal_act_"..ch.id.."_"..act.id]
          if divider then
            divider.visible=matching_acts[act.key]==true
            local stamp=divider["razi_journal_act_stamp"]
            if stamp then
              local caption=completion_caption(
                chapter_timing.get(player.force,"phases",act.key),"phase")
              stamp.caption=caption or ""
              stamp.visible=caption~=nil
            end
          end
        end
        local extra=entries["razi_journal_act_"..ch.id.."_additional"]
        if extra then
          extra.visible=matching_acts[ch.id..":additional"]==true
          local stamp=extra["razi_journal_act_stamp"]
          if stamp then
            local caption=completion_caption(chapter_timing.get(
              player.force,"phases",ch.id..":additional"),"phase")
            stamp.caption=caption or ""
            stamp.visible=caption~=nil
          end
        end
      end
      local expanded=shown>0 and (p.chapter==ch.id or p.query~="")
      if entries then entries.visible=expanded end
      if toggle then toggle.caption=expanded and marks.expanded or marks.collapsed end
      if count then
        count.caption=L("chapter-progress-short",
          ---@diagnostic disable-next-line: need-check-nil
          tostring(data.completed),tostring(data.total))
      end
      if count_holder then
        local stamped=completion_caption(
          chapter_timing.get(player.force,"chapters",ch.id),"chapter")
        local stamp=count_holder["razi_journal_chapter_time"]
        if stamp then
          stamp.caption=stamped or ""
          stamp.visible=stamped~=nil
        end
        if count then count.visible=expanded end
        count_holder.visible=expanded or stamped~=nil
      end
      if heading then
        heading.style.font=expanded and "default-bold" or "default"
        heading.style.font_color=expanded and COLOR.ink or COLOR.muted
      end
    end
  end
  local empty=column["razi_journal_no_results"]
  if empty then
    local any=false
    for index,_ in ipairs(defs.chapters) do
      local card=column["razi_journal_chapter_"..index]
      if card and card.visible then any=true;break end
    end
    empty.visible=not any
  end
  local lead=column["razi_journal_lead"]
  local lead_link=lead and lead["razi_journal_lead_link"]
  if lead_link then
    local next_quest=plan.primary and plan.primary.quest
    lead.visible=next_quest~=nil and p.query=="" and p.filter=="all"
    if next_quest then
      lead_link.caption=defs.quest_title(next_quest,player)
      lead_link.tags={razi_journal_action="guidance-select",id=next_quest.id}
    end
  end
  local overview=frame["razi_journal_overview"]
  local metrics=overview and overview["razi_journal_metrics"]
  local completion=metrics and metrics["razi_journal_completion"]
  local completed=completion and completion["razi_journal_completed"]
  local readiness=metrics and metrics["razi_journal_readiness"]
  local ready=readiness and readiness["razi_journal_ready"]
  local meter=overview and overview["razi_journal_meter"]
  local progress=meter and meter["razi_journal_progress"]
  if completed then
    completed.caption=L("completion-value",tostring(view.done),tostring(view.total))
  end
  if ready then ready.caption=L("ready-value",tostring(view.ready)) end
  if progress then progress.value=view.total>0 and view.done/view.total or 0 end
  local filterbar=navigation["razi_journal_filterbar"]
    or frame["razi_journal_filterbar"]
  if filterbar then
    for _,filter in ipairs({"all","ready","unfinished","done"}) do
      local button=filterbar["razi_journal_filter_"..filter]
      if button then
        button.style.font=p.filter==filter and "default-bold" or "default"
        button.style.font_color=p.filter==filter and COLOR.ink or COLOR.quiet
      end
    end
  end
  local picker=navigation["razi_journal_chapter_picker"]
  if picker and picker.selected_index~=chapter_index(p.chapter) then
    picker.selected_index=chapter_index(p.chapter)
  end
  local search=navigation["razi_journal_search"]
  if search and search.text~=(p.query or "") then search.text=p.query or "" end
  -- Keep typing focus and the chapter scrollbar untouched.
  if preserve_reader then return end
  reader.clear()
  if p.chapter_cover and render_chapter_cover(
    reader,player,p,context,size,view) then -- luacheck: ignore 542
  elseif selected then
    render_details(reader,player,selected,p,context,size,view)
  else
    local empty=reader.add{type="frame", -- luacheck: ignore 421
      style="inside_shallow_frame_with_padding"}
    empty.style.width=size.reader
    wrap(empty,L("missing-quest"),size.reader-40)
  end
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
