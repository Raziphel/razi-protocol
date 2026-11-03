-- The left rail of the quest folio: chapter picker, search, filters and the chapter list.
local M=require("scripts.journal.api")
local defs=require("scripts.journal.data")
local chapter_timing=require("scripts.journal.chapter_timing")
local journal_acts=require("scripts.journal.acts")
local marks=require("scripts.journal.marks")
local themes=require("scripts.journal.themes")
local icons=require("scripts.journal.icons")
local search_names=require("scripts.journal.search_names")
local widgets=require("scripts.journal.widgets")
local L=widgets.L
local COLOR=widgets.COLOR
local label=widgets.label
local subtitle=widgets.subtitle
local accent_rule=widgets.accent_rule
local wheel_pane=widgets.wheel_pane
local chapter_index=widgets.chapter_index
local quest_state=require("scripts.journal.quest_state")
local completion_caption=quest_state.completion_caption
local state_matches_filter=quest_state.state_matches_filter
local matches_query=quest_state.matches_query
local art=require("scripts.journal.quest_art")
local quest_art=art.quest_art
local chapter_cover=require("scripts.journal.chapter_cover")
local chapter_act=chapter_cover.chapter_act

local function select_quest(force,p,context,plan)
  local selected=p.selected and defs.by_id[p.selected]
  if selected and M.journal_visible(force,selected,context) then
    if p.chapter==nil then p.chapter=selected.chapter end
    return selected
  end
  selected=plan and plan.primary and plan.primary.quest
    or M.next_quest(force,context)
  p.selected=selected and selected.id or nil
  p.chapter=selected and selected.chapter or false
  return selected
end

-- Wrapped, selectable labels replace the old too-wide chapter and quest
-- buttons. One chapter jump selector covers distant chapters with no bars.
local function render_chapters(parent,player,p,context,size,view,plan)
  local frame=parent.add{type="frame",name="razi_journal_navigation_panel",direction="vertical",
    style="razi_journal_index"}
  frame.style.width=size.rail
  frame.style.height=size.body
  frame.style.padding=10
  local inner=size.rail-35
  local index_title=subtitle(frame,"navigator-title",inner)
  index_title.style.font_color=COLOR.amber
  local names={}
  for _,ch in ipairs(defs.chapters) do
    local chapter=view.chapters[ch.id]
    names[#names+1]=M.hide_spoilers() and chapter
      and #chapter.quests==0 and L("spoiler-unknown-chapter")
      or {"journal-chapter."..ch.id}
  end
  local dropdown=frame.add{type="drop-down",
    name="razi_journal_chapter_picker",items=names,
    selected_index=chapter_index(p.chapter)}
  dropdown.style.width=inner
  -- Search is immediately above its filters and the actual chapter list.
  local find_row=frame.add{type="flow",direction="horizontal"}
  find_row.style.horizontal_spacing=5
  local search=find_row.add{type="textfield",name="razi_journal_search",
    text=p.query or "",tooltip=L("search-tooltip")}
  search.style.width=inner-44
  local clear=find_row.add{type="button",style="tool_button",
    caption=marks.close,tooltip=L("clear-search"),
    tags={razi_journal_action="clear-search"}}
  clear.style.width=28
  clear.style.height=28
  local filters=frame.add{type="flow",name="razi_journal_filterbar",
    direction="horizontal"}
  filters.style.horizontal_spacing=9
  for _,filter in ipairs({"all","ready","unfinished","done"}) do
    local active=p.filter==filter
    local item=filters.add{type="label",style="clickable_label",
      name="razi_journal_filter_"..filter,
      caption=L("filter-"..filter),
      tags={razi_journal_action="filter",id=filter}}
    item.style.font=active and "default-bold" or "default"
    item.style.font_color=active and COLOR.ink or COLOR.quiet
  end
  local scroll=wheel_pane(frame,"razi_journal_navigation",
    inner,size.body-164)
  local column=scroll.add{type="flow",name="razi_journal_chapter_column",direction="vertical"}
  column.style.width=inner-13
  column.style.vertical_spacing=9
  local selected_element

  plan=plan or M.guidance(player.force,context,view)
  -- A compact next-objective link rather than the old tall dashboard card.
  if plan.primary and plan.primary.quest then
    local lead=column.add{type="flow",name="razi_journal_lead",direction="vertical"}
    lead.visible=p.query=="" and p.filter=="all"
    lead.style.width=inner-16
    lead.style.vertical_spacing=2
    lead.style.bottom_padding=5
    local title=label(lead,L("guidance-heading"))
    title.style.font="default-bold"
    title.style.font_color=COLOR.amber
    local entry=lead.add{type="label",name="razi_journal_lead_link",style="clickable_label",
      caption=defs.quest_title(plan.primary.quest,player),
      tags={razi_journal_action="guidance-select",id=plan.primary.quest.id}}
    entry.style.maximal_width=inner-24
    entry.style.single_line=false
    entry.style.font_color=COLOR.ink
  end
  local found=false
  local translated=search_names.names(player.index)

  for index,chapter in ipairs(defs.chapters) do
    local theme=themes.get(chapter.id)
    local data=view.chapters[chapter.id]
    local completed,total=data.completed,data.total
    -- Allocate visible quest rows once; later search/filter changes only
    -- toggle native GUI visibility, keeping the same scroll-pane instance.
    local available=data.quests
    local visible_count=0
    for _,quest in ipairs(available) do
      if state_matches_filter(view.states[quest.id],p.filter)
        and matches_query(quest,p.query,translated) then
        visible_count=visible_count+1
      end
    end
    if #available>0 then
      found=found or visible_count>0
      local open=p.query~="" or p.chapter==chapter.id
      -- Each chapter gets its own quiet inset surface. Separation remains
      -- visible when collapsed, without adding extra scrolling containers.
      local card=column.add{type="frame",name="razi_journal_chapter_"..index,
        direction="vertical",style="razi_journal_chapter_group"}
      card.style.width=inner-16
      card.style.padding=6
      card.visible=visible_count>0
      accent_rule(card,theme,math.min(72,inner-40),2)
      local head=card.add{type="flow",name="razi_journal_chapter_head",direction="horizontal"}
      head.style.horizontal_spacing=5
      icons.sprite(head,themes.icon(chapter.id),"chapter_button",
        {"journal-chapter."..chapter.id})
      local toggle=head.add{type="button",name="razi_journal_chapter_toggle",style="tool_button",
        caption=open and marks.expanded or marks.collapsed,
        tags={razi_journal_action="chapter",id=chapter.id},
        tooltip={"journal-chapter."..chapter.id}}
      toggle.style.width=20
      toggle.style.height=22
      toggle.style.font_color=open and theme.primary or COLOR.quiet
      local heading=head.add{type="label",name="razi_journal_chapter_title",
        style="clickable_label",
        caption={"",string.format("%02d",index)," / ",{"journal-chapter."..chapter.id}},
        tags={razi_journal_action="chapter",id=chapter.id}}
      heading.style.single_line=false
      heading.style.maximal_width=inner-85
      heading.style.font=open and "default-bold" or "default"
      heading.style.font_color=open and COLOR.ink or COLOR.muted
      heading.style.vertical_align="center"

      local counts=card.add{type="flow",name="razi_journal_chapter_status",direction="vertical"}
      counts.style.vertical_spacing=1
      counts.style.left_padding=45
      local stamped=completion_caption(
        chapter_timing.get(player.force,"chapters",chapter.id),"chapter")
      counts.visible=open or stamped~=nil
      local count=counts.add{type="label",name="razi_journal_chapter_count",
        caption=L("chapter-progress-short",tostring(completed),tostring(total))}
      count.visible=open
      count.style.font_color=COLOR.quiet
      local stamp=counts.add{type="label",name="razi_journal_chapter_time",
        caption=stamped or ""}
      stamp.visible=stamped~=nil
      stamp.style.font_color=COLOR.green
      stamp.tooltip=L("chapter-time-explanation")
      -- The numerical count is sufficient; redundant progress bars added
      -- visual noise eighteen times in a long chapter list.
      local entries=card.add{type="flow",name="razi_journal_chapter_entries",direction="vertical"}
      entries.visible=open and visible_count>0
      entries.style.vertical_spacing=4
      do
        local open_cover=entries.add{type="label",style="clickable_label",
          caption=L(p.chapter_cover and p.chapter==chapter.id
            and "chapter-cover-current" or "chapter-cover-open"),
          tooltip=L("chapter-cover-tooltip"),
          tags={razi_journal_action="chapter-dossier",id=chapter.id}}
        open_cover.style.font_color=theme.soft
        local last_act=nil
        for _,quest in ipairs(available) do
          local act=journal_acts.for_quest(quest)
          if act and act.key~=last_act then
            chapter_act(entries,act,theme,inner-34,player.force)
          end
          last_act=act and act.key
          local state=view.states[quest.id]
          local milestone_time=completion_caption(
            chapter_timing.get(player.force,"milestones",quest.id),"milestone")
          local milestone_tooltip=milestone_time
            and {"",defs.quest_title(quest,player),"\n",milestone_time}
            or defs.quest_title(quest,player)
          -- A selected entry is a single subtly raised row, not another
          -- full-width button. The native technology image stays bounded.
          local chosen=quest.id==p.selected and not p.chapter_cover
          local item=entries.add{type="flow",name="razi_journal_item_"..quest.id,
            direction="horizontal"}
          item.style.width=inner-34
          item.visible=state_matches_filter(state,p.filter)
            and matches_query(quest,p.query,translated)
          item.style.padding=2
          item.style.horizontal_spacing=5
          local select_rule=item.add{type="progressbar",
            name="razi_journal_item_rule",value=1}
          select_rule.style.width=3
          select_rule.style.height=18
          select_rule.style.color=theme.primary
          select_rule.visible=chosen
          icons.sprite(item,quest_art(player.force,quest,context),
            "quest_row")
          local control=item.add{type="button",name="razi_journal_item_control",style="tool_button",
            caption=state=="complete" and marks.done
              or state=="active" and marks.active or marks.pending,
            tags={razi_journal_action="select",id=quest.id},
            tooltip=milestone_tooltip}
          control.style.width=21
          control.style.height=21
          local color=state=="complete" and {r=.48,g=.85,b=.67}
            or state=="active" and {r=.98,g=.79,b=.46}
            or {r=.58,g=.61,b=.68}
          control.style.font_color=color
          local choice=item.add{type="label",name="razi_journal_item_choice",style="clickable_label",
            caption=defs.quest_title(quest,player),
            tags={razi_journal_action="select",id=quest.id},
            tooltip=milestone_tooltip}
          choice.style.single_line=false
          choice.style.maximal_width=inner-108
          choice.style.font_color=chosen and COLOR.ink
            or state=="active" and theme.soft or COLOR.muted
          if chosen then
            control.style.font_color=theme.primary
            choice.style.font="default-bold"
            selected_element=choice
          end
        end
      end
    end
  end
  local missing_start=not (player.force.technologies
    and player.force.technologies["automation"])
  local empty=column.add{type="label",name="razi_journal_no_results",
    caption=(not found and missing_start and p.query=="" and p.filter=="all")
      and L("bootstrap-research-missing") or L("nothing-found")}
  empty.style.single_line=false
  empty.style.maximal_width=inner-28
  empty.visible=not found
  -- A rebuilt list starts at the top, so bring the selected row back into
  -- view. Search results should not jump while the player is still typing.
  if selected_element and p.query=="" then
    pcall(function() scroll.scroll_to_element(selected_element) end)
  end
  return search
end

return {select_quest=select_quest,render_chapters=render_chapters}
