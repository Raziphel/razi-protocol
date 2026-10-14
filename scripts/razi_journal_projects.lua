-- Project dashboards share the Expedition Journal window.
-- Research, receivers, shipments and victory remain owned by source systems.
local M={}
local dyson=require("scripts.galactic_dyson")
local trade=require("scripts.galactic_trade")
local convergence=require("scripts.razi_convergence")
local catalog=require("scripts.galactic_trade_catalog")
local dyson_runtime=require("scripts.galactic_dyson_runtime")
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
function M.render(parent,player,p,size)
  local compact=size.width<760
  local columns=compact and 2 or 4
  local width=size.width-58
  p.project=M.valid(p.project) and p.project or "dyson"
  local header=parent.add{type="label",caption=L("projects-heading")}
  header.style.font="heading-2"
  local selector=parent.add{type="table",column_count=columns}
  selector.style.horizontal_spacing=5
  selector.style.vertical_spacing=5
  local button_width=math.floor((width-(columns-1)*5)/columns)
  for _,id in ipairs(ids) do
    local button=selector.add{type="button",
      caption=L("project-"..id),
      tags={razi_journal_action="project",id=id}}
    button.style.minimal_width=math.max(112,button_width)
    button.style.font=p.project==id and "default-bold" or "default"
  end
  local scroll=parent.add{type="scroll-pane",direction="vertical"}
  scroll.style.width=width
  scroll.style.height=math.max(105,size.body-(compact and 105 or 83))
  scroll.horizontal_scroll_policy="never"
  scroll.vertical_scroll_policy="dont-show-but-allow-scrolling"
  scroll.style.horizontally_squashable=true
  local content=scroll.add{type="flow",direction="vertical"}
  content.style.width=width-20
  content.style.vertical_spacing=9
  local options={embedded=true,width=width-28}
  if p.project=="dyson" then
    dyson.render(content,player,options)
  elseif p.project=="cargo" then
    trade.render(content,player,p,options)
  elseif p.project=="convergence" then
    convergence.render(content,player,options)
  else
    transceiver(content,player,width-28)
  end
end
function M.refresh(force) dyson_runtime.invalidate(force) end
return M
