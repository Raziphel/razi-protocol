-- The Archive folio: records unlocked by completed quests and the reader.
local M=require("scripts.journal.api")
local defs=require("scripts.journal.data")
local story=require("lib.story")
local great_projects=require("scripts.projects.great_projects")
local marks=require("scripts.journal.marks")
local themes=require("scripts.journal.themes")
local icons=require("scripts.journal.icons")
local widgets=require("scripts.journal.widgets")
local L=widgets.L
local COLOR=widgets.COLOR
local label=widgets.label
local wrap=widgets.wrap
local subtitle=widgets.subtitle
local accent_rule=widgets.accent_rule
local wheel_pane=widgets.wheel_pane
local art=require("scripts.journal.quest_art")
local quest_art=art.quest_art

-- An Archive record's title. Writer mode lists the record by its id until
-- the writer's own title exists.
local function record_title(player,id)
  if story.writer(player) then
    return story.text(player,"record-title",id,id)
  end
  return story.text(player,"record-title",id,{"journal-record-title."..id})
end
-- Whether an Archive record is open to this player: its quest is complete,
-- or writer mode opens every record.
local function record_open(player,quest,complete)
  return story.writer_records(player) or (quest~=nil and complete)
end

-- The archive is not another quest chain. Each story entry opens only
-- when its source-backed research milestone is actually completed.
function M.unlocked_records(force,context,player)
  context=context or M.context(force)
  local unlocked=0
  for _,record in ipairs(story.records(player)) do
    local q=defs.by_id[record.unlock]
    if record_open(player,q,q and M.complete(force,q,context)) then
      unlocked=unlocked+1
    end
  end
  return unlocked,#story.records(player)
end
local function render_archive(parent,player,p,context,size)
  local rail=parent.add{type="frame",name="razi_journal_archive_index",
    direction="vertical",style="razi_journal_index"}
  rail.visible=not p.reader_focus
  rail.style.width=size.rail
  rail.style.height=size.body
  rail.style.padding=10
  subtitle(rail,"archive-navigator",size.rail-38,themes.get("echoes"))
  -- Recovery ledger is derived solely from completed source milestones.
  -- Sealed titles remain concealed; only aggregate counts are shown.
  local counts={legacy={0,0},corporate={0,0},field={0,0}}
  for _,record in ipairs(story.records(player)) do
    local category=record.id:sub(1,5)~="corp-" and "legacy"
      or record.series=="field" and "field" or "corporate"
    local entry=counts[category]
    entry[2]=entry[2]+1
    local quest=defs.by_id[record.unlock]
    if record_open(player,quest,
      quest and M.complete(player.force,quest,context)) then
      entry[1]=entry[1]+1
    end
  end
  for _,category in ipairs({"legacy","corporate","field"}) do
    local progress=label(rail,L("archive-ledger-"..category,
      tostring(counts[category][1]),tostring(counts[category][2])))
    progress.style.font_color=COLOR.muted
  end
  local chooser=rail.add{type="table",column_count=2}
  chooser.style.horizontal_spacing=9
  chooser.style.vertical_spacing=8
  for _,category in ipairs({"all","legacy","corporate","field"}) do
    local chosen_filter=p.archive_filter==category
    local button=chooser.add{type="label",style="clickable_label",
      caption=L("archive-filter-"..category),
      tags={razi_journal_action="archive-filter",id=category}}
    button.style.font=chosen_filter and "default-bold" or "default"
    button.style.font_color=chosen_filter and COLOR.ink or COLOR.quiet
  end
  local left=wheel_pane(rail,"razi_journal_archive_navigation",
    size.rail-35,math.max(115,size.body-205))
  local collection=left.add{type="flow",direction="vertical"}
  collection.style.width=size.rail-56
  collection.style.vertical_spacing=5
  local chosen,focus
  local sealed=0
  local corporate_heading=false
  for _,record in ipairs(story.records(player)) do
    local quest=defs.by_id[record.unlock]
    local opened=record_open(player,quest,
      quest and M.complete(player.force,quest,context))
    if not opened then sealed=sealed+1 end
    -- Hide sealed pages entirely in spoiler mode. A counter replaces
    -- dozens of identical encrypted rows, without leaking future titles.
    local category=record.id:sub(1,5)~="corp-" and "legacy"
      or record.series=="field" and "field" or "corporate"
    if (p.archive_filter=="all" or p.archive_filter==category)
      and (opened or not M.hide_spoilers()) then
    if not corporate_heading and record.id:sub(1,5)=="corp-" then
      corporate_heading=true
      local heading=subtitle(collection,p.archive_filter=="field"
        and "archive-personal-heading" or "archive-corporate-heading",
        size.rail-64,themes.get("network"))
      heading.style.top_margin=10
    end
    local concealed=M.hide_spoilers() and not opened
    if opened and (not chosen or record.id==p.record) then chosen=record end
    local highlighted=opened and record.id==p.record
      or opened and not p.record and chosen==record
    local row=collection.add{type="flow",direction="horizontal"}
    row.style.padding=2
    row.style.horizontal_spacing=7
    local selection=row.add{type="progressbar",value=1}
    selection.style.width=3
    selection.style.height=20
    selection.style.color=COLOR.amber
    selection.visible=highlighted
    local mark
    if opened then
      mark=icons.button(row,quest_art(player.force,quest,context),
        "archive_button",{razi_journal_action="record",id=record.id},
        record_title(player,record.id))
    else
      mark=row.add{type="button",style="tool_button",
        caption=marks.pending,enabled=false,
        tooltip=concealed and L("spoiler-sealed-record")
          or record_title(player,record.id)}
      mark.style.font_color={r=.59,g=.62,b=.68}
    end
    mark.style.width=icons.size("archive_button")
    mark.style.height=icons.size("archive_button")
    local choice=row.add{type="label",
      style=opened and "clickable_label" or nil,
      caption={"",opened and p.story_unread and p.story_unread[record.id]
        and marks.active.." " or "",concealed and L("spoiler-sealed-record")
        or record_title(player,record.id)},
      tags=opened and {razi_journal_action="record",id=record.id} or nil}
    choice.style.single_line=false
    choice.style.maximal_width=size.rail-105
    choice.style.font_color=opened and {r=.95,g=.95,b=.95}
      or {r=.58,g=.60,b=.65}
    if opened and record.id==p.record then
      choice.style.font="default-bold"
      focus=choice
    end
    end
  end
  -- Recovered RAZI Archive Array signals are separate from the original
  -- 59 corporate records. Their three physical unlocks never inflate the
  -- source-research archive totals or expose a future signal title.
  great_projects.array(player.force)
  local array_count=great_projects.recovered(player.force)
  if array_count>0 then
    local array_label=label(collection,L("archive-array-heading"))
    array_label.style.font="default-bold"
    array_label.style.font_color=COLOR.amber
    for i=1,array_count do
      local select_row=collection.add{type="label",style="clickable_label",
        caption=L("archive-array-title-"..i),
        tags={razi_journal_action="array-record",id=i}}
      select_row.style.single_line=false
      select_row.style.maximal_width=size.rail-65
    end
  end
  if M.hide_spoilers() and sealed>0 then
    local note=wrap(collection,L("archive-sealed-count",
      tostring(sealed)),size.rail-64)
    note.style.font_color=COLOR.quiet
  end
  if focus then pcall(function() left.scroll_to_element(focus) end) end

  local paper=parent.add{type="frame",direction="vertical",
    style="razi_journal_paper"}
  paper.style.width=size.reader
  paper.style.height=size.body
  paper.style.padding=12
  local array_page=p.record and
    tonumber(p.record:match("^array%-(%d+)$"))
  if array_page and array_page>=1 and array_page<=array_count then
    local title=wrap(paper,L("archive-array-title-"..array_page),
      size.reader-48)
    title.style.font="heading-2"
    title.style.font_color=COLOR.ink
    local prose=wheel_pane(paper,"razi_journal_archive_reading",
      size.reader-38,size.body-140)
    wrap(prose,L("archive-array-record-"..array_page),size.reader-67)
    return
  end
  if not chosen then
    subtitle(paper,"archive-sealed-heading",size.reader-48)
    wrap(paper,L("archive-sealed"),size.reader-48)
    return
  end
  p.record=chosen.id
  local chosen_quest=defs.by_id[chosen.unlock]
  local archive_theme=themes.get(chosen_quest and chosen_quest.chapter or "echoes")
  subtitle(paper,chosen.series=="field" and
    "archive-field-heading" or "archive-entry-label",
    size.reader-48,archive_theme)
  accent_rule(paper,archive_theme,math.min(100,size.reader-42),2)
  local cover=paper.add{type="flow",direction="horizontal"}
  cover.style.horizontal_spacing=10
  local entry_quest=defs.by_id[chosen.unlock]
  if entry_quest then
    icons.sprite(cover,quest_art(player.force,entry_quest,context),
      "archive_cover")
  end
  local title=wrap(cover,record_title(player,chosen.id),size.reader-94)
  title.style.font="heading-2"
  title.style.font_color=COLOR.ink
  title.tooltip=story.key_tooltip(player,"record-title",chosen.id)
  local origin=label(paper,story.text(player,"record-origin",chosen.id,
    {"journal-record-origin."..chosen.id}))
  origin.style.font_color=COLOR.muted
  origin.tooltip=story.key_tooltip(player,"record-origin",chosen.id)
  if chosen_quest then
    local source=paper.add{type="button",
      caption=L("archive-open-source",
        defs.quest_title(chosen_quest,player)),
      tags={razi_journal_action="archive-source",id=chosen_quest.id},
      tooltip=L("archive-source-tooltip")}
    source.style.minimal_width=math.min(220,size.reader-58)
  end
  paper.add{type="line",direction="horizontal"}
  local reading=wheel_pane(paper,"razi_journal_archive_reading",
    size.reader-38,size.body-179)
  local page=reading.add{type="flow",direction="vertical"}
  page.style.width=size.reader-67
  page.style.vertical_spacing=12
  local body=wrap(page,story.text(player,"record-body",chosen.id,
    {"journal-record-body."..chosen.id}),size.reader-67)
  body.tooltip=story.key_tooltip(player,"record-body",chosen.id)
  wrap(paper,L("archive-disclaimer"),size.reader-48)
end

return {record_title=record_title,record_open=record_open,
  render_archive=render_archive}
