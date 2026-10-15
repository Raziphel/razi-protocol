-- Project dashboards share the Expedition Journal window.
-- Research, receivers, shipments and victory remain owned by source systems.
local M={}
local dyson=require("scripts.galactic_dyson")
local trade=require("scripts.galactic_trade")
local convergence=require("scripts.razi_convergence")
local catalog=require("scripts.galactic_trade_catalog")
local dyson_runtime=require("scripts.galactic_dyson_runtime")
local icons=require("scripts.razi_journal_icons")
local L=function(k,...) return {"journal-ui."..k,...} end
local ids={"dyson","cargo","transceiver","convergence"}
function M.valid(id)
  for _,value in ipairs(ids) do if value==id then return true end end
  return false
end
function M.valid_cargo(force,chain,target)
  if not chain or not catalog.is_installed(force,chain) then return false end
  for _,entry in ipairs(catalog.chains) do
    if entry.id==chain then
      return not target or catalog.chain_for_technology(target)==chain
    end
  end
  return false
end
function M.research_related(name)
  if name=="razi-intergalactic-transceiver-signal"
    or name=="razi-convergence-commission"
    or name=="razi-convergence-synchronization"
    or name=="razi-convergence-ignition" then return true end
  for _,stage in ipairs(dyson.stages) do
    if stage[1]==name then return true end
  end
  return false
end
local function transceiver(parent,player,width)
  local tech=player.force.technologies["razi-intergalactic-transceiver-signal"]
  local active=player.force.get_entity_count("kr-activated-intergalactic-transceiver")>0
  local title=parent.add{type="label",caption=L("project-transceiver")}
  title.style.font="heading-2"
  local status=parent.add{type="label",caption=L(not tech
    and "project-transceiver-missing" or active
    and "project-transceiver-active" or tech.researched
    and "project-transceiver-researched" or "project-transceiver-waiting")}
  status.style.single_line=false
  status.style.maximal_width=width
  if tech and not tech.researched then
    for _,required in pairs(tech.prerequisites or {}) do
      if not required.researched then
        local note=parent.add{type="label",caption={
          "",L("project-transceiver-needs")," ",required.localised_name}}
        note.style.single_line=false
        note.style.maximal_width=width
      end
    end
  end
  local note=parent.add{type="label",caption=L("project-transceiver-desc")}
  note.style.single_line=false
  note.style.maximal_width=width
end
-- Four curated project dossiers. All completion values come from the
-- original mods: there is no fabricated megaproject percentage.
local HUES={
  ink={r=.94,g=.93,b=.89},
  quiet={r=.62,g=.68,b=.72},
  gold={r=.87,g=.73,b=.49},
  unused={r=.39,g=.46,b=.51}
}
local PROJECT_ART={
  dyson="razi-dyson-works-stage-",
  cargo="technology/interplanetary-trade-logistics",
  transceiver="technology/razi-intergalactic-transceiver-signal",
  convergence="technology/razi-convergence-commission"
}
local function art_for(id,force)
  if id=="dyson" then
    local finished=dyson.status(force)
    return PROJECT_ART.dyson..math.min(6,finished)
  end
  local path=PROJECT_ART[id]
  if helpers and helpers.is_valid_sprite_path
    and not helpers.is_valid_sprite_path(path) then
    return "razi-journal-book-icon"
  end
  return path
end
local function status_for(force,id)
  if id=="dyson" then
    local done,total=dyson.status(force)
    return done,total
  elseif id=="cargo" then
    local network=catalog.snapshot(force)
    return network.researched,network.available
  elseif id=="convergence" then
    if not convergence.available(force) then return 0,0 end
    local done,total=convergence.progress(force)
    return done,total
  end
  local tech=force.technologies["razi-intergalactic-transceiver-signal"]
  if not tech then return 0,0 end
  local active=force.get_entity_count
    and force.get_entity_count("kr-activated-intergalactic-transceiver")>0
  return (tech.researched or active) and 1 or 0,1
end
local function project_entry(parent,player,p,id,width,index)
  local selected=p.project==id
  local card=parent.add{type="flow",direction="vertical"}
  card.style.width=width
  card.style.vertical_spacing=6
  local head=card.add{type="flow",direction="horizontal"}
  head.style.horizontal_spacing=10
  head.style.vertical_align="center"
  -- The emblem itself is the navigation target, not a separate grey arrow.
  icons.button(head,art_for(id,player.force),"project_button",
    {razi_journal_action="project",id=id},L("project-caption-"..id))
  local copy=head.add{type="flow",direction="vertical"}
  copy.style.vertical_spacing=3
  local over=copy.add{type="label",caption=L("project-number",index)}
  over.style.font_color=selected and HUES.gold or HUES.quiet
  local name=copy.add{type="label",style="clickable_label",
    caption=L("project-"..id),tooltip=L("project-caption-"..id),
    tags={razi_journal_action="project",id=id}}
  name.style.font=selected and "default-bold" or "default"
  name.style.font_color=selected and HUES.ink or {r=.73,g=.78,b=.81}
  name.style.single_line=false
  name.style.maximal_width=math.max(100,width-73)
  if selected then
    local accent=card.add{type="progressbar",value=1}
    accent.style.width=math.max(110,width-18)
    accent.style.height=3
    accent.style.color=HUES.gold
  end
  local complete,total=status_for(player.force,id)
  local count=card.add{type="label",
    caption=total==0 and L("project-unavailable")
      or L("project-progress",tostring(complete),tostring(total))}
  count.style.font_color=HUES.quiet
  local meter=card.add{type="progressbar",
    value=total>0 and complete/total or 0}
  meter.style.width=math.max(110,width-18)
  meter.style.height=5
  meter.style.color=selected and HUES.gold or {r=.48,g=.62,b=.69}
end
local function project_reader(parent,player,p,size,width,compact)
  local reader=parent.add{type="frame",direction="vertical",
    style="inside_shallow_frame_with_padding"}
  reader.style.width=width
  local reader_height=compact
    and math.max(175,size.body-175) or size.body
  reader.style.height=reader_height
  reader.style.padding=13
  local folio=reader.add{type="label",caption=L("project-dossier")}
  folio.style.font="default-bold"
  folio.style.font_color=HUES.gold
  local header=reader.add{type="flow",direction="horizontal"}
  header.style.horizontal_spacing=12
  header.style.vertical_align="center"
  icons.sprite(header,art_for(p.project,player.force),"project_hero")
  local copy=header.add{type="flow",direction="vertical"}
  copy.style.vertical_spacing=4
  local title=copy.add{type="label",caption=L("project-"..p.project)}
  title.style.font="heading-1"
  title.style.font_color=HUES.ink
  title.style.single_line=false
  title.style.maximal_width=math.max(125,width-112)
  local description=copy.add{type="label",
    caption=L("project-caption-"..p.project)}
  description.style.single_line=false
  description.style.maximal_width=math.max(125,width-112)
  description.style.font_color=HUES.quiet
  local accent=reader.add{type="progressbar",value=1}
  accent.style.width=math.max(130,width-38)
  accent.style.height=3
  accent.style.color=HUES.gold
  local scroll=reader.add{type="scroll-pane",direction="vertical",
    name="razi_journal_project_reader"}
  scroll.style.width=width-32
  scroll.style.height=math.max(80,reader_height-(compact and 110 or 132))
  scroll.horizontal_scroll_policy="never"
  scroll.vertical_scroll_policy="dont-show-but-allow-scrolling"
  scroll.style.horizontally_squashable=true
  local content=scroll.add{type="flow",direction="vertical"}
  content.style.width=width-54
  content.style.vertical_spacing=10
  local options={embedded=true,width=width-68}
  if p.project=="dyson" then
    dyson.render(content,player,options)
  elseif p.project=="cargo" then
    trade.render(content,player,p,options)
  elseif p.project=="convergence" then
    convergence.render(content,player,options)
  else
    transceiver(content,player,width-68)
  end
end
function M.render(parent,player,p,size)
  p.project=M.valid(p.project) and p.project or "dyson"
  local compact=size.width<900
  if compact then
    local stack=parent.add{type="flow",direction="vertical"}
    stack.style.width=size.width-37
    stack.style.vertical_spacing=8
    local title=stack.add{type="label",caption=L("projects-heading")}
    title.style.font="default-bold"
    title.style.font_color=HUES.gold
    local grid=stack.add{type="table",column_count=2}
    grid.style.horizontal_spacing=9
    grid.style.vertical_spacing=9
    local cell=math.max(170,math.floor((size.width-55)/2))
    for index,id in ipairs(ids) do
      project_entry(grid,player,p,id,cell,
        string.format("%02d",index))
    end
    project_reader(stack,player,p,size,size.width-43,true)
  else
    local rail=parent.add{type="frame",direction="vertical",
      style="inside_shallow_frame_with_padding"}
    rail.style.width=size.rail
    rail.style.height=size.body
    rail.style.padding=13
    local section=rail.add{type="label",caption=L("projects-heading")}
    section.style.font="default-bold"
    section.style.font_color=HUES.gold
    local note=rail.add{type="label",caption=L("project-index-hint")}
    note.style.font_color=HUES.quiet
    note.style.single_line=false
    note.style.maximal_width=size.rail-40
    for index,id in ipairs(ids) do
      if index>1 then rail.add{type="line",direction="horizontal"} end
      project_entry(rail,player,p,id,size.rail-41,
        string.format("%02d",index))
    end
    project_reader(parent,player,p,size,size.reader,false)
  end
end
function M.refresh(force) dyson_runtime.invalidate(force) end
return M
