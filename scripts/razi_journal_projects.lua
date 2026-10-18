-- Project dashboards share the Expedition Journal window.
-- Research, receivers, shipments and victory remain owned by source systems.
local M={}
local dyson=require("scripts.galactic_dyson")
local trade=require("scripts.galactic_trade")
local convergence=require("scripts.razi_convergence")
local catalog=require("scripts.galactic_trade_catalog")
local dyson_runtime=require("scripts.galactic_dyson_runtime")
local icons=require("scripts.razi_journal_icons")
-- Factorio prohibits require() inside GUI events; resolve this at control load.
local frontier=require("scripts.razi_journal_frontier")
local objectives=require("scripts.razi_journal_data")
local L=function(k,...) return {"journal-ui."..k,...} end
local ids={"dyson","cargo","recovery","transceiver","convergence"}
local project_technologies={
  dyson="slp-dyson-sphere",
  cargo="interplanetary-trade-logistics",
  recovery="razi-frontier-recovery-charter",
  transceiver="razi-intergalactic-transceiver-signal",
  convergence="razi-convergence-commission"
}
function M.visible(force,id)
  if not M.valid(id) then return false end
  local setting=settings and settings.global
    and settings.global["razi-hide-spoilers"]
  if not (setting and setting.value==true) then return true end
  local name=project_technologies[id]
  local tech=force and force.technologies and force.technologies[name]
  if not tech then return false end
  if tech.researched then return true end
  if tech.enabled==false then return false end
  for _,required in pairs(tech.prerequisites or {}) do
    if not required.researched then return false end
  end
  return true
end
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
    or name=="razi-frontier-recovery-charter"
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
-- Five curated project dossiers. All completion values come from the
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
  recovery="technology/razi-frontier-recovery-charter",
  transceiver="technology/razi-intergalactic-transceiver-signal",
  convergence="technology/razi-convergence-commission"
}
local function art_for(id,force,statuses)
  if id=="dyson" then
    local recorded=statuses and statuses.dyson
    local finished=recorded and recorded[1] or select(1,dyson.status(force))
    return PROJECT_ART.dyson..math.min(6,finished)
  end
  if id=="recovery" and not force.technologies["razi-frontier-recovery-charter"] then
    return "razi-journal-book-icon"
  end
  local path=PROJECT_ART[id]
  if helpers and helpers.is_valid_sprite_path
    and not helpers.is_valid_sprite_path(path) then
    return "razi-journal-book-icon"
  end
  return path
end
-- All six stages are actual force research or space-location unlocks.
-- Never synthesize percentage from platform or inventory counters.
local recovery_stages={
  {"athos",world="athos"},
  {"athos-particulate",tech="particulate-science-pack"},
  {"nulla",world="nulla"},
  {"nulla-electromagnetic",tech="electromagnetic-robotics"},
  {"nulla-robotic-science",tech="robotic-science-pack"},
  {"frontier-recovery-charter",tech="razi-frontier-recovery-charter"}
}
local function recovery_done(force,stage)
  if stage.world then
    for _,tech in pairs(force.technologies or {}) do
      for _,effect in pairs(tech.prototype and tech.prototype.effects or {}) do
        if effect.type=="unlock-space-location" and
          effect.space_location==stage.world and tech.researched then
          return true
        end
      end
    end
    return false
  end
  local name=stage.tech
  if stage[1]=="athos-particulate" then
    name=frontier.unlocking(
      "particulate-science-pack") or name
  end
  local tech=force.technologies and force.technologies[name]
  return tech~=nil and tech.researched==true
end
local function recovery_status(force)
  local done=0
  for _,stage in ipairs(recovery_stages) do
    if recovery_done(force,stage) then done=done+1 end
  end
  return done,#recovery_stages
end
M.recovery_status=recovery_status -- Read-only fixture target, no GUI needed.
local function recovery_reader(parent,player,width)
  local intro=parent.add{type="label",caption=L("project-recovery-description")}
  intro.style.single_line=false
  intro.style.maximal_width=width
  local done,total=recovery_status(player.force)
  local state=parent.add{type="label",
    caption=L("project-progress",tostring(done),tostring(total))}
  state.style.font="default-bold"
  state.style.font_color=HUES.gold
  for _,stage in ipairs(recovery_stages) do
    local line=parent.add{type="flow",direction="horizontal"}
    line.style.vertical_align="center"
    line.style.horizontal_spacing=9
    local completed=recovery_done(player.force,stage)
    local progress=line.add{type="label",
      caption=L(completed and "project-recovery-done"
        or "project-recovery-pending")}
    progress.style.font_color=completed and
      {r=.49,g=.83,b=.67} or HUES.quiet
    local link=line.add{type="label",style="clickable_label",
      caption=L("project-recovery-"..stage[1]),
      tags={razi_journal_action="select",id=stage[1]}}
    link.style.font=completed and "default" or "default-bold"
    link.style.font_color=completed and HUES.quiet or HUES.ink
    link.style.single_line=false
    link.style.maximal_width=math.max(120,width-74)
  end
  local note=parent.add{type="label",caption=L("project-recovery-native")}
  note.style.single_line=false
  note.style.maximal_width=width
  note.style.font_color=HUES.quiet
end

-- A completion bar measures the *named* native milestone, never a guessed
-- percentage of satellites built, ships delivered or worlds conquered.
-- The third snapshot value preserves detail for action guidance.
local function status_for(force,id)
  if id=="dyson" then
    return dyson.status(force)
  elseif id=="recovery" then
    return recovery_status(force)
  elseif id=="cargo" then
    local network=catalog.snapshot(force)
    return network.researched,network.available,network
  elseif id=="convergence" then
    if not convergence.available(force) then return 0,0 end
    return convergence.progress(force)
  end
  local tech=force.technologies["razi-intergalactic-transceiver-signal"]
  if not tech then return 0,0 end
  local active=force.get_entity_count
    and force.get_entity_count("kr-activated-intergalactic-transceiver")>0
  -- Research is not activation: the physical transceiver must exist.
  return active and 1 or 0,1,tech
end

local function unmet(tech)
  local missing={}
  for _,required in pairs(tech and tech.prerequisites or {}) do
    if not required.researched then missing[#missing+1]=required end
  end
  table.sort(missing,function(a,b)return a.name<b.name end)
  return missing
end

-- Read-only next step from real source research, discoveries and deliveries.
-- Return a localized caption and optional quest ID for a safe Journal link.
local function next_action(force,id,status)
  local done,total,detail=status[1],status[2],status[3]
  if total==0 then return L("project-next-unavailable") end
  if id=="dyson" then
    for _,stage in ipairs(detail or {}) do
      if not stage.tech.researched then
        local missing=unmet(stage.tech)
        if #missing>0 then
          return L("project-next-prerequisite",missing[1].localised_name)
        end
        if stage.tech.enabled==false then return L("project-next-disabled") end
        return L("project-next-research",stage.tech.localised_name)
      end
    end
    return L("project-next-dyson-build")
  elseif id=="cargo" then
    for _,row in ipairs(detail and detail.parts or {}) do
      if row.state.status=="ready" then
        return L("project-next-research",row.technology.localised_name),
          catalog.quest_for_technology(row.technology.name)
      end
    end
    for _,row in ipairs(detail and detail.parts or {}) do
      if row.state.status=="blocked" and row.state.missing[1] then
        return L("project-next-prerequisite",
          row.state.missing[1].localised_name)
      end
    end
    return done==total and L("project-next-cargo-build")
      or L("project-next-cargo-review")
  elseif id=="recovery" then
    for _,stage in ipairs(recovery_stages) do
      if not recovery_done(force,stage) then
        return L("project-next-recovery",
          L("project-recovery-"..stage[1])),stage[1]
      end
    end
    return L("project-next-recovery-done")
  elseif id=="transceiver" then
    if done==1 then return L("project-next-transceiver-done") end
    if detail and detail.researched then
      return L("project-next-transceiver-activate")
    end
    local missing=unmet(detail)
    if #missing>0 then
      return L("project-next-prerequisite",missing[1].localised_name)
    end
    if detail and detail.enabled==false then
      return L("project-next-disabled")
    end
    return L("project-next-transceiver-research")
  end
  if detail==true then return L("project-next-convergence-done") end
  local current=convergence.current(force)
  if current>#convergence.stages then
    return L("project-next-convergence-transmission")
  end
  local commission=force.technologies["razi-convergence-commission"]
  if commission and not commission.researched then
    return L("project-next-research",commission.localised_name)
  end
  local stage=convergence.stages[current]
  return stage and L("project-next-convergence-deliver",
    {"razi-ops.convergence-stage-"..stage.id})
    or L("project-next-unavailable")
end

-- Only link to entries already present and visible under the active
-- spoiler setting; never reveal a future milestone through this shortcut.
function M.next_quest(force,id)
  if not M.visible(force,id) then return nil end
  local status={status_for(force,id)}
  local _,quest_id=next_action(force,id,status)
  local quest=quest_id and objectives.by_id[quest_id]
  if not quest then return nil end
  local spoiler=settings and settings.global
    and settings.global["razi-hide-spoilers"]
  if spoiler and spoiler.value==true then
    if quest.tech then
      local tech=force.technologies and force.technologies[quest.tech]
      if not tech or (not tech.researched and tech.enabled==false) then
        return nil
      end
    elseif quest.world then
      -- World discovery links should not reveal locked native locations.
      local seen=false
      for _,tech in pairs(force.technologies or {}) do
        for _,effect in pairs(tech.prototype and tech.prototype.effects or {}) do
          if effect.type=="unlock-space-location"
            and effect.space_location==quest.world
            and (tech.researched or tech.enabled) then
            seen=true
            break
          end
        end
        if seen then break end
      end
      if not seen then return nil end
    end
  end
  return quest.id
end

local function project_progress(id,done,total)
  if total==0 then return L("project-unavailable") end
  return L("project-progress-"..id,tostring(done),tostring(total))
end

local function project_entry(parent,player,p,id,width,index,statuses)
  local selected=p.project==id
  -- Selected projects get the same gentle raised-paper treatment as
  -- selected quests. Unselected projects remain quiet index entries.
  local card=parent.add{type=selected and "frame" or "flow",
    direction="vertical",style=selected and "inside_shallow_frame" or nil}
  card.style.width=width
  card.style.padding=selected and 8 or 2
  if not selected then card.style.vertical_spacing=6 end
  local head=card.add{type="flow",direction="horizontal"}
  head.style.horizontal_spacing=10
  head.style.vertical_align="center"
  -- The emblem itself is the navigation target, not a separate grey arrow.
  icons.button(head,art_for(id,player.force,statuses),"project_button",
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
  local snapshot=statuses[id]
  local complete,total=snapshot[1],snapshot[2]
  local count=card.add{type="label",
    caption=project_progress(id,complete,total)}
  count.style.font_color=HUES.quiet
  local meter=card.add{type="progressbar",
    value=total>0 and complete/total or 0}
  meter.style.width=math.max(95,width-(selected and 32 or 18))
  meter.style.height=5
  meter.style.color=selected and HUES.gold or {r=.48,g=.62,b=.69}
end
local function project_reader(parent,player,p,size,width,compact,statuses)
  local reader=parent.add{type="frame",direction="vertical",
    style="inside_shallow_frame_with_padding"}
  reader.style.width=width
  local reader_height=compact
    and math.max(175,size.body-175) or size.body
  reader.style.height=reader_height
  reader.style.padding=11
  local folio=reader.add{type="label",caption=L("project-dossier")}
  folio.style.font="default-bold"
  folio.style.font_color=HUES.gold
  local header=reader.add{type="flow",direction="horizontal"}
  header.style.horizontal_spacing=12
  header.style.vertical_align="center"
  icons.sprite(header,art_for(p.project,player.force,statuses),"project_hero")
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
  gauge.style.width=math.max(130,width-38)
  gauge.style.height=6
  gauge.style.color=HUES.gold
  -- Put the *next actual action* before the long project ledger. The
  -- lead stays visible while the detailed dossier scrolls underneath.
  local next=reader.add{type="frame",direction="vertical",
    style="inside_shallow_frame"}
  next.style.width=math.max(130,width-37)
  next.style.padding=8
  next.style.vertical_spacing=4
  local eyebrow=next.add{type="label",caption=L("project-next-heading")}
  eyebrow.style.font="default-bold"
  eyebrow.style.font_color=HUES.gold
  local advice,quest_id=next_action(player.force,p.project,current)
  local guidance=next.add{type="label",caption=advice}
  guidance.style.single_line=false
  guidance.style.maximal_width=math.max(115,width-68)
  if quest_id and M.next_quest(player.force,p.project)==quest_id then
    next.add{type="button",caption=L("project-open-next"),
      tags={razi_journal_action="project-next"}}
  end
  local perspective=next.add{type="label",
    caption=L("project-measures-"..p.project)}
  perspective.style.single_line=false
  perspective.style.maximal_width=math.max(115,width-68)
  perspective.style.font_color=HUES.quiet
  local scroll=reader.add{type="scroll-pane",direction="vertical",
    name="razi_journal_project_reader"}
  scroll.style.width=width-32
  scroll.style.height=math.max(80,reader_height-(compact and 290 or 305))
  scroll.tags={razi_scroll_context=p.project}
  scroll.horizontal_scroll_policy="never"
  scroll.vertical_scroll_policy="dont-show-but-allow-scrolling"
  scroll.style.horizontally_squashable=true
  local content=scroll.add{type="flow",direction="vertical"}
  content.style.width=width-54
  content.style.vertical_spacing=14
  local options={embedded=true,width=width-68}
  if p.project=="dyson" then
    dyson.render(content,player,options)
  elseif p.project=="cargo" then
    trade.render(content,player,p,options)
  elseif p.project=="recovery" then
    recovery_reader(content,player,width-68)
  elseif p.project=="convergence" then
    convergence.render(content,player,options)
  else
    transceiver(content,player,width-68)
  end
end
function M.render(parent,player,p,size)
  local displayed={}
  for _,id in ipairs(ids) do
    if M.visible(player.force,id) then displayed[#displayed+1]=id end
  end
  if #displayed==0 then
    local empty=parent.add{type="label",caption=L("project-spoiler-locked")}
    empty.style.font_color=HUES.quiet
    return
  end
  if not M.visible(player.force,p.project) then p.project=displayed[1] end
  -- Each expensive source-owned project snapshot is evaluated once per
  -- redraw, even though the chosen project is drawn in two separate panes.
  local statuses={}
  for _,id in ipairs(displayed) do
    statuses[id]={status_for(player.force,id)}
  end
  local compact=size.width<900
  if compact then
    local stack=parent.add{type="flow",direction="vertical"}
    stack.style.width=size.width-37
    stack.style.vertical_spacing=8
    local title=stack.add{type="label",caption=L("projects-heading")}
    title.style.font="default-bold"
    title.style.font_color=HUES.gold
    local columns=size.width<620 and 1 or 2
    local grid=stack.add{type="table",column_count=columns}
    grid.style.horizontal_spacing=9
    grid.style.vertical_spacing=9
    local cell=math.max(170,math.floor((size.width-55-(columns-1)*9)/columns))
    for index,id in ipairs(displayed) do
      project_entry(grid,player,p,id,cell,
        string.format("%02d",index),statuses)
    end
    project_reader(stack,player,p,size,size.width-43,true,statuses)
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
    for index,id in ipairs(displayed) do
      if index>1 then rail.add{type="line",direction="horizontal"} end
      project_entry(rail,player,p,id,size.rail-41,
        string.format("%02d",index),statuses)
    end
    project_reader(parent,player,p,size,size.reader,false,statuses)
  end
end
function M.refresh(force) dyson_runtime.invalidate(force) end
return M
