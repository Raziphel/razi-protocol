-- The project index entries and the dossier of the selected project.
local M=require("scripts.journal.project_api")
local style=require("scripts.journal.project_style")
require("scripts.journal.project_next")
local readers=require("scripts.journal.project_readers")
local cargo_view=require("scripts.cargo.view")
local dyson=require("scripts.dyson.dyson")
local convergence=require("scripts.convergence.convergence")
local icons=require("scripts.journal.icons")
local story=require("lib.story")
local L=style.L
local HUES=style.HUES
local art_for=style.art_for
local next_action=M.next_action
local platform_reader=readers.platform
local great_project_reader=readers.great
local nexus_trials_reader=readers.nexus_trials
local transceiver=readers.transceiver
local function project_progress(id,done,total)
  if total==0 then
    return L(id=="cargo" and "project-progress-cargo-none"
      or "project-unavailable")
  end
  return L("project-progress-"..id,tostring(done),tostring(total))
end

local function project_entry(parent,player,p,id,width,index,statuses)
  local selected=p.project==id
  -- Treat the left column as a project index, not ten stacked cards.
  -- Selection is expressed through type weight and a single small bar.
  local card=parent.add{type="flow",direction="vertical"}
  card.style.width=width
  card.style.padding=3
  card.style.vertical_spacing=4
  local head=card.add{type="flow",direction="horizontal"}
  head.style.horizontal_spacing=8
  head.style.vertical_align="center"
  -- The emblem itself is the navigation target, not a separate grey arrow.
  icons.button(head,art_for(id,player.force,statuses),"project_button",
    {razi_journal_action="project",id=id},L("project-caption-"..id))
  local copy=head.add{type="flow",direction="vertical"}
  copy.style.vertical_spacing=2
  local over=copy.add{type="label",caption=L("project-number",index)}
  over.style.font_color=selected and HUES.gold or HUES.quiet
  local name=copy.add{type="label",style="clickable_label",
    caption=L("project-"..id),tooltip=L("project-caption-"..id),
    tags={razi_journal_action="project",id=id}}
  name.style.font=selected and "default-bold" or "default"
  name.style.font_color=selected and HUES.ink or {r=.73,g=.78,b=.81}
  name.style.single_line=false
  name.style.maximal_width=math.max(100,width-73)
  local snapshot=statuses[id]
  local complete,total=snapshot[1],snapshot[2]
  local count=card.add{type="label",
    caption=project_progress(id,complete,total)}
  count.style.font_color=HUES.quiet
  local meter=card.add{type="progressbar",
    value=total>0 and complete/total or 0}
  meter.style.width=math.max(95,width-(selected and 32 or 18))
  meter.style.height=3
  meter.style.color=HUES.gold
  meter.visible=selected
end
local function project_reader(parent,player,p,size,width,compact,statuses,displayed,reader_override)
  local reader=parent.add{type="frame",direction="vertical",
    style="razi_journal_paper"}
  reader.style.width=width
  local reader_height=reader_override or (compact
    and math.max(175,size.body-175) or size.body)
  reader.style.height=reader_height
  reader.style.padding=11
  local controls=reader.add{type="flow",direction="horizontal"}
  controls.style.horizontally_stretchable=true
  controls.style.horizontal_spacing=7
  controls.style.vertical_align="center"
  local folio=controls.add{type="label",caption=L("project-dossier")}
  folio.style.font="default-bold"
  folio.style.font_color=HUES.gold
  local spacer=controls.add{type="empty-widget"}
  spacer.style.horizontally_stretchable=true
  for _,step in ipairs({-1,1}) do
    local target=M.adjacent(player.force,p.project,step,displayed)
    if target then
      controls.add{type="button",style="tool_button",
        caption=L(step<0 and "project-previous" or "project-next"),
        tooltip=L("project-"..target),
        tags={razi_journal_action="project-cycle",id=target}}
    end
  end
  local header=reader.add{type="flow",direction="horizontal"}
  header.style.horizontal_spacing=12
  header.style.vertical_align="center"
  icons.sprite(header,art_for(p.project,player.force,statuses),"project_hero")
  local copy=header.add{type="flow",direction="vertical"}
  copy.style.vertical_spacing=4
  local title=copy.add{type="label",caption=L("project-"..p.project)}
  title.style.font="heading-2"
  title.style.font_color=HUES.ink
  title.style.single_line=false
  title.style.maximal_width=math.max(125,width-112)
  local description=copy.add{type="label",
    caption=L("project-caption-"..p.project)}
  description.style.single_line=false
  description.style.maximal_width=math.max(125,width-112)
  description.style.font_color=HUES.quiet
  local accent=reader.add{type="progressbar",value=1}
  accent.style.width=math.min(104,width-38)
  accent.style.height=3
  accent.style.color=HUES.gold
  -- Real stage totals provide a compact project cover summary; the
  -- substantial source-owned construction detail remains in the reader.
  local current=statuses[p.project]
  local done,total=current[1],current[2]
  local digest=reader.add{type="flow",direction="horizontal"}
  digest.style.vertical_align="center"
  digest.style.horizontal_spacing=9
  local count=digest.add{type="label",
    caption=project_progress(p.project,done,total)}
  count.style.font="default-bold"
  count.style.font_color=total>0 and done==total
    and HUES.gold or HUES.quiet
  local gauge=reader.add{type="progressbar",
    value=total>0 and done/total or 0}
  gauge.style.width=math.min(240,width-38)
  gauge.style.height=4
  gauge.style.color=HUES.gold
  local scroll=reader.add{type="scroll-pane",direction="vertical",
    name="razi_journal_project_reader"}
  scroll.style.width=width-32
  scroll.style.height=math.max(80,reader_height-(compact and 185 or 202))
  scroll.tags={razi_scroll_context=p.project}
  scroll.horizontal_scroll_policy="never"
  scroll.vertical_scroll_policy="auto"
  scroll.style.horizontally_squashable=true
  local content=scroll.add{type="flow",direction="vertical"}
  content.style.width=width-54
  content.style.vertical_spacing=10
  -- Project advice belongs at the top of the dossier's own scroll area,
  -- leaving the narrow-screen reader free to show its real details.
  local next=content.add{type="frame",direction="vertical",
    style="razi_journal_callout"}
  next.style.width=math.max(120,width-72)
  next.style.padding=10
  -- FrameStyle has no vertical_spacing: spacing belongs to a nested Flow.
  local next_body=next.add{type="flow",direction="vertical"}
  next_body.style.horizontally_stretchable=true
  next_body.style.vertical_spacing=4
  local eyebrow=next_body.add{type="label",caption=L("project-next-heading")}
  eyebrow.style.font="default-bold"
  eyebrow.style.font_color=HUES.gold
  local advice,quest_id=next_action(player.force,p.project,current)
  local guidance=next_body.add{type="label",caption=advice}
  guidance.style.single_line=false
  guidance.style.maximal_width=math.max(100,width-98)
  if quest_id and M.next_quest(player.force,p.project,current)==quest_id then
    next_body.add{type="button",caption=L("project-open-next"),
      tags={razi_journal_action="project-next"}}
  end
  local perspective=next_body.add{type="label",
    caption=L("project-measures-"..p.project)}
  perspective.style.single_line=false
  perspective.style.maximal_width=math.max(100,width-98)
  perspective.style.font_color=HUES.quiet
  if story.visible(player) then
    local context=content.add{type="label",
      caption=story.text(player,"project-context",p.project,
        L("project-context-"..p.project)),
      tooltip=story.key_tooltip(player,"project-context",p.project)}
    context.style.single_line=false
    context.style.maximal_width=math.max(115,width-72)
    context.style.font_color=HUES.quiet
  end
  local options={embedded=true,width=width-68}
  if p.project=="platform" or p.project=="voyage" then
    platform_reader(content,player,width-68,p.project,current)
  elseif p.project=="skybridge" then
    great_project_reader(content,player,width-68,"skybridge",current)
  elseif p.project=="cargo" then
    cargo_view.render(content,player,width-68,current[3],p)
  elseif p.project=="beltbreaker" then
    great_project_reader(content,player,width-68,"beltbreaker",current)
  elseif p.project=="array" then
    great_project_reader(content,player,width-68,"array",current)
  elseif p.project=="nexus-trials" then
    nexus_trials_reader(content,player,width-68,current)
  elseif p.project=="ark" then
    great_project_reader(content,player,width-68,"ark",current)
  elseif p.project=="dyson" then
    dyson.render(content,player,options)
  elseif p.project=="convergence" then
    convergence.render(content,player,options)
  else
    transceiver(content,player,width-68)
  end
end
return {entry=project_entry,reader=project_reader}
