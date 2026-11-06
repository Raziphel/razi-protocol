-- Project dashboards share the Expedition Journal window.
-- Research, receivers, shipments and victory remain owned by source systems.
--
-- This file is the entry point of the dashboards. The code lives in the parts next to it;
-- each part adds its functions to the public table of project_api.lua, and this file
-- loads them all, draws the dashboards and returns that table. Factorio forbids require()
-- inside events, so every part is loaded here, at load time.
local M=require("scripts.journal.project_api")
local dyson_runtime=require("scripts.dyson.runtime")
local platform_projects=require("scripts.projects.platform_projects")
local style=require("scripts.journal.project_style")
-- The parts, each after the parts it uses.
require("scripts.journal.project_state")
require("scripts.journal.project_next")
local views=require("scripts.journal.project_views")
local L=style.L
local HUES=style.HUES
local project_ids=M.project_ids
local status_for=M.status_for
local project_entry=views.entry
local project_reader=views.reader
function M.render(parent,player,p,size)
  local displayed={}
  for _,id in ipairs(project_ids()) do
    if M.visible(player.force,id) then displayed[#displayed+1]=id end
  end
  if #displayed==0 then
    local empty=parent.add{type="label",caption=L("project-spoiler-locked")}
    empty.style.font_color=HUES.quiet
    return
  end
  local known=false
  for _,id in ipairs(displayed) do
    if id==p.project then known=true break end
  end
  if not known then p.project=displayed[1] end
  -- Each expensive source-owned project snapshot is evaluated once per
  -- redraw, even though the chosen project is drawn in two separate panes.
  local statuses={}
  local ships=platform_projects.snapshot(player.force)
  for _,id in ipairs(displayed) do
    statuses[id]={status_for(player.force,id,ships)}
  end
  local compact=size.width<900
  if compact then
    local stack=parent.add{type="flow",direction="vertical"}
    stack.style.width=size.width-37
    stack.style.vertical_spacing=8
    local title=stack.add{type="label",caption=L("projects-heading")}
    title.visible=not p.reader_focus
    title.style.font="default-bold"
    title.style.font_color=HUES.gold
    local columns=size.width<620 and 1 or 2
    -- Ten project cards must not push the active dossier off a compact screen.
    local selector_height=math.max(88,math.min(148,math.floor(size.body*.28)))
    local selector=stack.add{type="scroll-pane",
      name="razi_journal_project_navigation",direction="vertical",
      horizontal_scroll_policy="never",vertical_scroll_policy="auto"}
    selector.style.width=size.width-43
    selector.style.height=selector_height
    selector.visible=not p.reader_focus
    local grid=selector.add{type="table",column_count=columns}
    grid.style.horizontal_spacing=9
    grid.style.vertical_spacing=9
    local cell=math.max(170,math.floor((size.width-55-(columns-1)*9)/columns))
    for index,id in ipairs(displayed) do
      project_entry(grid,player,p,id,cell,
        string.format("%02d",index),statuses)
    end
    project_reader(stack,player,p,size,size.width-43,true,statuses,displayed,
      math.max(170,size.body-(p.reader_focus and 35 or selector_height+42)))
  else
    local rail=parent.add{type="frame",name="razi_journal_project_index",
      direction="vertical",style="razi_journal_index"}
    rail.visible=not p.reader_focus
    rail.style.width=size.rail
    rail.style.height=size.body
    rail.style.padding=10
    local section=rail.add{type="label",caption=L("projects-heading")}
    section.style.font="default-bold"
    section.style.font_color=HUES.gold
    local selector=rail.add{type="scroll-pane",
      name="razi_journal_project_navigation",direction="vertical",
      horizontal_scroll_policy="never",vertical_scroll_policy="auto"}
    selector.style.width=size.rail-27
    selector.style.height=math.max(120,size.body-78)
    local entries=selector.add{type="flow",direction="vertical"}
    entries.style.width=size.rail-44
    entries.style.vertical_spacing=3
    for index,id in ipairs(displayed) do
      project_entry(entries,player,p,id,size.rail-45,
        string.format("%02d",index),statuses)
    end
    project_reader(parent,player,p,size,size.reader,false,statuses,displayed)
  end
end
function M.refresh(force) dyson_runtime.invalidate(force) end
return M
