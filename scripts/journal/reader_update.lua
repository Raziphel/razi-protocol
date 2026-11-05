-- Updates the open quest folio in place, so the chapter list keeps its scroll position.
local M=require("scripts.journal.api")
local defs=require("scripts.journal.data")
local chapter_timing=require("scripts.journal.chapter_timing")
local journal_acts=require("scripts.journal.acts")
local marks=require("scripts.journal.marks")
local themes=require("scripts.journal.themes")
local search_names=require("scripts.journal.search_names")
local widgets=require("scripts.journal.widgets")
local FRAME=widgets.FRAME
local L=widgets.L
local COLOR=widgets.COLOR
local wrap=widgets.wrap
local chapter_index=widgets.chapter_index
local pref=require("scripts.journal.preferences")
local quest_state=require("scripts.journal.quest_state")
local completion_caption=quest_state.completion_caption
local state_matches_filter=quest_state.state_matches_filter
local matches_query=quest_state.matches_query
local render_details=require("scripts.journal.dossier")
local chapter_cover=require("scripts.journal.chapter_cover")
local render_chapter_cover=chapter_cover.render_chapter_cover
local navigator=require("scripts.journal.navigator")
local select_quest=navigator.select_quest
local window=require("scripts.journal.window")
local draw=window.draw
local nexus_revision=window.nexus_revision

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
          local divider=entries["razi_journal_act_"..act.chapter.."_"..act.id]
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

return update_reader
