-- The chapter cover (frontispiece) and the act dividers of a chapter.
local M=require("scripts.journal.api")
local defs=require("scripts.journal.data")
local story=require("lib.story")
local industrial_briefs=require("scripts.journal.planet_briefs")
local chapter_timing=require("scripts.journal.chapter_timing")
local journal_acts=require("scripts.journal.acts")
local marks=require("scripts.journal.marks")
local themes=require("scripts.journal.themes")
local icons=require("scripts.journal.icons")
local widgets=require("scripts.journal.widgets")
local L=widgets.L
local COLOR=widgets.COLOR
local label=widgets.label
local wrap=widgets.wrap
local accent_rule=widgets.accent_rule
local dossier_heading=widgets.dossier_heading
local section=widgets.section
local wheel_pane=widgets.wheel_pane
local chapter_index=widgets.chapter_index
local quest_state=require("scripts.journal.quest_state")
local completion_caption=quest_state.completion_caption
local art=require("scripts.journal.quest_art")
local quest_art=art.quest_art

-- One shared section renderer for every chapter, including Calidus.
local function chapter_act(parent,act,theme,width,force)
  if not act then return end
  local divider=parent.add{type="frame",name="razi_journal_act_"..
    act.chapter.."_"..act.id,direction="vertical",
    style="razi_journal_phase_divider"}
  divider.style.width=width
  divider.style.padding=7
  accent_rule(divider,theme,math.min(76,width-22),2)
  local name=label(divider,{"",string.format("%02d",act.order),
    " / ",journal_acts.caption(act)})
  name.style.font="default-bold"
  name.style.font_color=theme.soft
  name.style.single_line=false
  name.style.maximal_width=math.max(100,width-22)
  local stamped=completion_caption(
    chapter_timing.get(force,"phases",act.key),"phase")
  local stamp=divider.add{type="label",name="razi_journal_act_stamp",
    caption=stamped or ""}
  stamp.visible=stamped~=nil
  stamp.style.font_color=COLOR.quiet
end

-- A source-backed frontispiece for each chapter. It is a *view* of the
-- existing milestones, never a separate quest or a second progress store.
-- Only the chosen page is built on demand. No tick work, custom textures,
-- temporary render objects, or research mutations.
local function render_chapter_cover(parent,player,p,context,size,view)
  local chapter=p.chapter and view.chapters[p.chapter]
  if not chapter or (M.hide_spoilers() and #chapter.quests==0) then
    return false
  end
  local theme=themes.get(p.chapter)
  local width=size.reader
  local inner=width-38
  local panel=parent.add{type="frame",direction="vertical",
    style="razi_journal_paper"}
  panel.style.width=width
  panel.style.height=size.body
  panel.style.padding=12
  local labelline=panel.add{type="flow",direction="horizontal"}
  labelline.style.horizontal_spacing=7
  local over=label(labelline,L("chapter-cover-eyebrow",
    string.format("%02d",chapter_index(p.chapter))))
  over.style.font="default-bold"
  over.style.font_color=theme.primary
  local heading=panel.add{type="flow",direction="horizontal"}
  heading.style.horizontal_spacing=10
  heading.style.vertical_align="center"
  icons.sprite(heading,themes.icon(p.chapter),"chapter_seal")
  local cover_title=wrap(heading,{"journal-chapter."..p.chapter},inner-52)
  cover_title.style.font="heading-2"
  cover_title.style.font_color=COLOR.ink
  accent_rule(panel,theme,math.min(112,inner),2)
  if story.visible(player) then
    local mood=wrap(panel,story.text(player,"chapter-mood",p.chapter,
      {"journal-mood."..p.chapter}),inner)
    mood.style.font="default-bold"
    mood.style.font_color=theme.soft
    mood.tooltip=story.key_tooltip(player,"chapter-mood",p.chapter)
  end
  local line=panel.add{type="flow",direction="horizontal"}
  line.style.horizontal_spacing=9
  local count=label(line,L("chapter-progress-short",
    tostring(chapter.completed),tostring(chapter.total)))
  count.style.font="default-bold"
  count.style.font_color=COLOR.muted
  local stamped=completion_caption(
    chapter_timing.get(player.force,"chapters",p.chapter),"chapter")
  if stamped then
    local stamp=label(panel,stamped)
    stamp.style.font_color=COLOR.green
    stamp.tooltip=L("chapter-time-explanation")
  end
  local measure=panel.add{type="progressbar",
    value=chapter.total>0 and chapter.completed/chapter.total or 0}
  measure.style.width=math.min(inner,420)
  measure.style.height=4
  measure.style.color=theme.primary

  -- Limited-height outer folio, one scroll pane only. This lets even the
  -- largest chapter keep its narrative and real milestones scrollable.
  local scroll=wheel_pane(panel,"razi_journal_chapter_reading",
    inner,size.body-(size.compact and 248 or 265))
  local body=scroll.add{type="flow",direction="vertical"}
  local text_width=inner-18
  body.style.width=text_width
  body.style.vertical_spacing=12
  if story.visible(player) then
    section(body,"chapter-cover-story",
      story.text(player,"chapter-summary",p.chapter,
        {"journal-chapter-summary."..p.chapter}),text_width,theme,
      story.key_tooltip(player,"chapter-summary",p.chapter))
    -- The seven founding systems get distinct operating identities, kept
    -- inside the already-unlocked cover instead of leaking future names.
    local star=industrial_briefs.star_charter(p.chapter)
    if star then
      section(body,"star-charter-heading",
        story.text(player,"chapter-star",star,
          {"razi-star-signature."..star}),text_width,theme,
        story.key_tooltip(player,"chapter-star",star))
    end
    section(body,"chapter-cover-dispatch",
      story.text(player,"chapter-dispatch",p.chapter,
        {"journal-chapter-dispatch."..p.chapter}),text_width,theme,
      story.key_tooltip(player,"chapter-dispatch",p.chapter))
    section(body,"chapter-context",
      story.text(player,"chapter-context",p.chapter,
        {"journal-chapter-story."..p.chapter}),text_width,theme,
      story.key_tooltip(player,"chapter-context",p.chapter))
  end
  dossier_heading(body,"chapter-cover-entries",theme,text_width)

  local next_entry
  for _,quest in ipairs(chapter.quests) do
    if view.states[quest.id]=="active" then next_entry=quest;break end
  end
  if not next_entry then
    for _,quest in ipairs(chapter.quests) do
      if view.states[quest.id]=="locked" then next_entry=quest;break end
    end
  end
  if not next_entry then
    for _,quest in ipairs(chapter.quests) do
      if view.states[quest.id]=="complete" then next_entry=quest;break end
    end
  end

  -- A real chapter navigation log; each entry jumps to its existing
  -- quest dossier, with colours derived from actual force research.
  local shown=0
  local last_act=nil
  for _,quest in ipairs(chapter.quests) do
    if shown>=8 then break end
    shown=shown+1
    local act=journal_acts.for_quest(quest)
    if act and act.key~=last_act then
      chapter_act(body,act,theme,text_width,player.force)
    end
    last_act=act and act.key
    local state=view.states[quest.id]
    local row=body.add{type="flow",direction="horizontal"}
    row.style.horizontal_spacing=9
    row.style.vertical_align="center"
    icons.sprite(row,quest_art(player.force,quest,context),"quest_row")
    local marker=label(row,state=="complete" and marks.done
      or state=="active" and marks.active or marks.pending)
    marker.style.font_color=state=="complete" and COLOR.green
      or state=="active" and COLOR.amber or COLOR.quiet
    local link=row.add{type="label",style="clickable_label",
      caption=defs.quest_title(quest,player),
      tooltip=L("select-objective"),
      tags={razi_journal_action="select",id=quest.id}}
    link.style.single_line=false
    link.style.maximal_width=text_width-85
    link.style.font_color=quest==next_entry and COLOR.ink or COLOR.muted
    if quest==next_entry then link.style.font="default-bold" end
  end
  if #chapter.quests>shown then
    local extra=label(body,L("chapter-cover-more",
      tostring(#chapter.quests-shown)))
    extra.style.font_color=COLOR.quiet
  end
  if next_entry then
    -- Small screens keep the next-entry control inside the scrollable
    -- folio so it cannot force the whole reader beyond the display.
    local footer_parent=size.body<420 and body or panel
    local footer=footer_parent.add{type="flow",direction="horizontal"}
    footer.style.horizontal_spacing=8
    footer.style.vertical_align="center"
    local call=footer.add{type="button",
      caption=L(view.states[next_entry.id]=="complete"
        and "chapter-cover-review" or "chapter-cover-continue"),
      tags={razi_journal_action="chapter-continue",id=next_entry.id}}
    call.tooltip=defs.quest_title(next_entry,player)
  else
    wrap(panel,L("chapter-cover-unavailable"),inner)
  end
  return true
end

return {chapter_act=chapter_act,render_chapter_cover=render_chapter_cover}
