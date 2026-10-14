-- Real cargo, real destination, shared multiplayer progress.
-- This module is event/UI driven. No global platform or inventory scans.
local M={}
local defs=require("prototypes.technology.convergence")
local dyson_runtime=require("scripts.galactic_dyson_runtime")
M.stages=defs.shipments
-- Native factory delivery starts a short, persistent transmission sequence.
M.transmission_beats={
 {tick=0,key="convergence-transmission-sealed"},
 {tick=180,key="convergence-transmission-dyson"},
 {tick=360,key="convergence-transmission-resonance"},
 {tick=540,key="convergence-transmission-alignment"}
}
M.transmission_duration=720
M.module_colors={
 stellar={r=.98,g=.72,b=.39},
 industry={r=.43,g=.75,b=.92},
 ["deep-space"]={r=.67,g=.55,b=.95},
 resonance={r=.91,g=.53,b=.75},
 ignition={r=.52,g=.91,b=.76}
}
-- Source receiver entity counts are maintained by the Factorio engine.
-- Actual satellite count and generated megawatts cannot be inferred here.
function M.dyson_readiness(force)
 local names=dyson_runtime.resolve_receiver_names(prototypes)
 if #names==0 or not (force and force.get_entity_count) then
  return true,nil
 end
 local count=0
 for _,name in ipairs(names) do
  count=count+force.get_entity_count(name)
 end
 return count>0,count
end
local destinations={
 ["solar-system-edge"]=true,
 ["shattered-planet"]=true,
 ["nexus"]=true,
 ["razi-deep-space-edge"]=true,
 ["black-hole-approach"]=true
}
function M.record(force)
 storage.razi_convergence=storage.razi_convergence or {}
 local key=force.index
 local value=storage.razi_convergence[key]
 if not value then
  value={delivered={},victory=false}
  storage.razi_convergence[key]=value
 end
 value.delivered=value.delivered or {}
 return value
end
function M.available(force)
 local techs=force and force.technologies
 return techs and techs[defs.commission]
  and techs[defs.authorization] and techs[defs.ignition]
end
function M.location(player)
 -- Remote View cannot submit cargo, even if the physical character
 -- is left standing aboard a legitimate expedition platform.
 if not player or (defines and defines.controllers
   and player.controller_type==defines.controllers.remote) then
  return nil
 end
 local character=player.character
 if not (character and character.valid) then return nil end
 local surface=character.surface
 local platform=surface and surface.platform
 if not (platform and platform.valid and platform.force==player.force
  and platform.space_location) then return nil end
 local name=platform.space_location.name
 return destinations[name] and name or nil
end
local function stage_ready(force,index)
 if not M.available(force) or not force.technologies[defs.commission].researched then
  return false,"convergence-need-research"
 end
 if index>=3 and not force.technologies[defs.authorization].researched then
  return false,"convergence-need-synchronization"
 end
 if index>=5 then
  if not force.technologies[defs.ignition].researched then
   return false,"convergence-need-ignition"
  end
  if not M.dyson_readiness(force) then
   return false,"convergence-need-receiver"
  end
 end
 return true
end
function M.current(force)
 local saved=M.record(force)
 -- Earlier winners keep their completed 2.1.57 campaign.
 if saved.victory then return #M.stages+1 end
 for i,rule in ipairs(M.stages) do
  if (saved.delivered[rule.id] or 0)<rule.count then return i end
 end
 return #M.stages+1
end
function M.completed(force,id)
 -- Displaying a Codex page should not allocate save-state on first view.
 local all=storage and storage.razi_convergence
 local saved=all and all[force.index]
 if not saved then return false end
 if id=="victory" then return saved.victory==true end
 if saved.victory then
  for _,rule in ipairs(M.stages) do
   if rule.id==id then return true end
  end
 end
 for _,rule in ipairs(M.stages) do
  if rule.id==id then
   return (saved.delivered[id] or 0)>=rule.count
  end
 end
 return false
end
-- Fractional build completion makes each real partial shipment visible.
-- Deliberately weight the five engineering sections equally.
function M.assembly_fraction(force)
 local all=storage and storage.razi_convergence
 local saved=all and all[force.index]
 if saved and saved.victory then return 1 end
 local credit=0
 for _,rule in ipairs(M.stages) do
  local donated=saved and saved.delivered
   and saved.delivered[rule.id] or 0
  credit=credit+math.min(1,math.max(0,donated/rule.count))
 end
 return credit/#M.stages
end
function M.progress(force)
 local saved=M.record(force)
 if saved.victory then return #M.stages,#M.stages,true end
 local complete=0
 for _,rule in ipairs(M.stages) do
  if (saved.delivered[rule.id] or 0)>=rule.count then
   complete=complete+1
  end
 end
 return complete,#M.stages,saved.victory==true
end
local function finish(force,player)
 local saved=M.record(force)
 if saved.victory then return end
 saved.victory=true
 saved.victory_tick=game.tick
 saved.completed_by=player.name
 saved.completed_site=saved.transmission and saved.transmission.site
  or saved.completed_site
 if game.print then
  game.print({"razi-ops.convergence-broadcast",force.name})
 end
 -- An old save may already have displayed a source-mod victory
 -- before installing Razi 2.1.56. Re-arm the engine ONLY when the real
 -- final shipment is accepted, never on load or at the transceiver.
 if game.finished or game.finished_but_continuing then
  game.reset_game_state()
 end
 do
  game.set_win_ending_info{
   title={"razi-ops.convergence-victory-title"},
   message={"razi-ops.convergence-victory-message"},
   bullet_points={
    {"razi-ops.convergence-victory-stellar"},
    {"razi-ops.convergence-victory-industry"},
    {"razi-ops.convergence-victory-deep"},
    {"razi-ops.convergence-victory-resonance"},
    {"razi-ops.convergence-victory-ignition"}
   },
   final_message={"razi-ops.convergence-victory-final"}
  }
  game.set_game_state{game_finished=true,player_won=true,
   can_continue=true}
 end
end
-- Called only from a validated GUI click, never by events on picked-up cargo.
function M.deliver(player,id)
 local force=player and player.force
 if not force then return "convergence-no-force",0 end
 local index=M.current(force)
 local rule=M.stages[index]
 if not rule or rule.id~=id then
  return "convergence-wrong-stage",0
 end
 local allowed,why=stage_ready(force,index)
 if not allowed then return why,0 end
 if not M.location(player) then return "convergence-need-platform",0 end
 local inv=player.get_main_inventory()
 if not (inv and inv.valid) then
  return "convergence-no-cargo",0
 end
 local saved=M.record(force)
 local needed=rule.count-(saved.delivered[id] or 0)
 if needed<=0 then return "convergence-wrong-stage",0 end
 local offered=math.min(needed,inv.get_item_count(rule.item))
 if offered<=0 then return "convergence-no-cargo",0 end
 -- Inventory removal returns the actual removed count. Nothing is ever
 -- credited merely because an item was expected or a GUI was opened.
 local removed=inv.remove{name=rule.item,count=offered}
 if removed<=0 then return "convergence-no-cargo",0 end
 saved.delivered[id]=math.min(rule.count,
  (saved.delivered[id] or 0)+removed)
 if index==#M.stages and M.current(force)>#M.stages then
  -- Consumed cargo has been accepted. Keep the finale in save storage,
  -- surviving reloads and disconnects without spending the item twice.
  saved.transmission={
   started=game.tick,beat=1,operator=player.name,site=M.location(player)
  }
  storage.razi_convergence_pending=storage.razi_convergence_pending or {}
  storage.razi_convergence_pending[force.index]=true
  if force.print then
   force.print({"razi-ops."..M.transmission_beats[1].key})
  end
  return "convergence-transmission-started",removed
 end
 return "convergence-delivered",removed
end
-- Only restore newly introduced recipe unlocks on an existing save.
-- Never reset the whole science tree or change another mod's research.
function M.repair_recipe_unlocks(force)
 if not (force and force.technologies and force.recipes) then return end
 for _,rule in ipairs(M.stages) do
  local research=force.technologies[rule.unlock or defs.commission]
  local recipe=force.recipes[rule.item]
  if research and research.researched and recipe then
   recipe.enabled=true
  end
 end
end
-- Only visit actively transmitting forces, once per second.
function M.advance(tick)
 local waiting=storage and storage.razi_convergence_pending
 if not waiting then return nil end
 local changed={}
 for index in pairs(waiting) do
  local saved=storage.razi_convergence and storage.razi_convergence[index]
  local force=game.forces[index]
  if not (force and saved and saved.transmission) or saved.victory then
   waiting[index]=nil
  else
   local sequence=saved.transmission
   local elapsed=math.max(0,tick-sequence.started)
   if elapsed>=M.transmission_duration then
    finish(force,{name=sequence.operator or "Expedition"})
    saved.transmission=nil
    waiting[index]=nil
    changed[#changed+1]=index
   else
    local next_beat=(sequence.beat or 1)+1
    local updated=false
    while M.transmission_beats[next_beat]
      and elapsed>=M.transmission_beats[next_beat].tick do
     sequence.beat=next_beat
     if force.print then
      force.print({"razi-ops."..M.transmission_beats[next_beat].key})
     end
     updated=true
     next_beat=next_beat+1
    end
    if updated then changed[#changed+1]=index end
   end
  end
 end
 return changed
end
function M.restore_pending()
 local saved=storage and storage.razi_convergence
 if not saved then return end
 storage.razi_convergence_pending=storage.razi_convergence_pending or {}
 for index,state in pairs(saved) do
  if state.transmission and not state.victory then
   storage.razi_convergence_pending[index]=true
  end
 end
end
function M.forces_merged(event)
 local saved=storage.razi_convergence
 if not saved then return end
 local source=saved[event.source_index]
 if not source then return end
 local dest=event.destination
 local dest_index=dest and dest.index or event.destination_index
 if not dest_index then return end
 local target=saved[dest_index] or {delivered={},victory=false}
 target.delivered=target.delivered or {}
 for _,rule in ipairs(M.stages) do
  target.delivered[rule.id]=math.min(rule.count,
   (target.delivered[rule.id] or 0)
   +(source.delivered and source.delivered[rule.id] or 0))
 end
 target.victory=target.victory or source.victory
 target.victory_tick=target.victory_tick or source.victory_tick
 target.completed_by=target.completed_by or source.completed_by
 target.completed_site=target.completed_site or source.completed_site
 if not target.victory then
  local a,b=target.transmission,source.transmission
  if b and (not a or b.started<a.started) then
   target.transmission=b
  end
 else
  target.transmission=nil
 end
 local waiting=storage.razi_convergence_pending
 if waiting then
  waiting[event.source_index]=nil
  waiting[dest_index]=target.transmission and not target.victory or nil
 end
 saved[dest_index]=target
 saved[event.source_index]=nil
end
local function L(key,...)
 return {"razi-ops."..key,...}
end
local function line(parent,key,width,...)
 local label=parent.add{type="label",caption=L(key,...)}
 label.style.single_line=false
 label.style.maximal_width=width
 return label
end
function M.render(parent,player)
 local layout_width=math.max(320,math.min(850,
  (player.display_resolution.width or 1280)/
   math.max(player.display_scale or 1,.5)-100))
 local width=math.floor(layout_width)-28
 local heading=line(parent,"convergence-heading",width)
 heading.style.font="heading-1"
 heading.style.font_color={r=.88,g=.73,b=1}
 line(parent,"convergence-overview",width)
 local scroll=parent.add{type="scroll-pane",direction="vertical"}
 scroll.style.horizontally_stretchable=true
 scroll.horizontal_scroll_policy="never"
 scroll.style.height=math.min(560,math.max(230,
  math.floor(player.display_resolution.height/
   math.max(player.display_scale or 1,.5)*.59)))
 if not M.available(player.force) then
  line(scroll,"convergence-unavailable",width)
  return
 end
 local force=player.force
 local progress,total,won=M.progress(force)
 local saved=M.record(force)
 local stat=line(scroll,"convergence-progress",width,
  tostring(progress),tostring(total))
 stat.style.font="default-bold"
 local fraction=M.assembly_fraction(force)
 local overall=scroll.add{type="progressbar",value=fraction}
 overall.style.horizontally_stretchable=true
 overall.style.height=16
 overall.style.color={r=.73,g=.58,b=.97}
 local percent=line(scroll,"convergence-assembly-percent",width,
  tostring(math.floor(fraction*100+.5)))
 percent.style.font="default-bold"
 local assembly=line(scroll,"convergence-assembly-heading",width)
 assembly.style.font="heading-2"
 line(scroll,"convergence-assembly-subtitle",width)
 local tiles=scroll.add{type="table",
  column_count=width>=560 and 5 or (width>=380 and 3 or 2)}
 tiles.style.horizontally_stretchable=true
 tiles.style.horizontal_spacing=6
 tiles.style.vertical_spacing=6
 for _,rule in ipairs(M.stages) do
  local donated=won and rule.count or
   math.max(0,math.min(rule.count,saved.delivered[rule.id] or 0))
  local completed=donated==rule.count
  local shade=M.module_colors[rule.id]
  local tile=tiles.add{type="frame",style="inside_shallow_frame",
   direction="vertical"}
  tile.style.padding=6
  local image=tile.add{type="sprite",sprite="item/"..rule.item}
  image.style.width=32
  image.style.height=32
  local caption=tile.add{type="label",caption=
   {"razi-ops.convergence-stage-"..rule.id}}
  caption.style.single_line=false
  caption.style.maximal_width=135
  caption.style.font="default-bold"
  caption.style.font_color=shade
  local fill=tile.add{type="progressbar",value=donated/rule.count}
  fill.style.width=math.min(122,math.max(66,
   math.floor((width-30)/(width>=560 and 5 or
    (width>=380 and 3 or 2))-18)))
  fill.style.height=7
  fill.style.color=shade
  local marker=tile.add{type="label",caption={
   "razi-ops."..(completed and "convergence-tile-complete"
    or "convergence-tile-pending")}}
  marker.style.font_color=completed and {r=.48,g=.9,b=.72}
    or {r=.92,g=.74,b=.50}
 end
 if won then
  local win=line(scroll,"convergence-won",width)
  win.style.font_color={r=.48,g=.9,b=.72}
  local archive=scroll.add{type="frame",
   style="inside_shallow_frame",direction="vertical"}
  archive.style.horizontally_stretchable=true
  local title=line(archive,"convergence-archive-title",width)
  title.style.font="heading-2"
  line(archive,"convergence-archive-message",width)
  if saved.completed_by then
   line(archive,"convergence-archive-operator",width,saved.completed_by)
  end
  if saved.completed_site then
   local site=saved.completed_site:gsub("-"," ")
   line(archive,"convergence-archive-site",width,site)
  end
  if saved.victory_tick then
   local seconds=math.floor(saved.victory_tick/60)
   local hours=math.floor(seconds/3600)
   local minutes=math.floor(seconds%3600/60)
   local secs=seconds%60
   line(archive,"convergence-archive-time",width,
    string.format("%d:%02d:%02d",hours,minutes,secs))
  end
 end
 -- A built, force-owned receiver is tangible evidence of the Dyson grid.
 -- The source mod remains authoritative for real satellite count and MW.
 local receiver_ready,receivers=M.dyson_readiness(force)
 local dyson=scroll.add{type="frame",style="inside_shallow_frame",
   direction="vertical"}
 dyson.style.horizontally_stretchable=true
 local heading=line(dyson,"convergence-dyson-title",width)
 heading.style.font="heading-2"
 line(dyson,receivers==nil and "convergence-dyson-unknown"
  or (receiver_ready and "convergence-dyson-ready"
  or "convergence-dyson-missing"),width,tostring(receivers or 0))
 for _,id in ipairs({"slp-dyson-sphere",
    "slp-dyson-sphere-grounded","ds-energy-loader-mk2"}) do
  local tech=force.technologies[id]
  if tech then
   line(dyson,tech.researched and "convergence-dyson-tech-done"
    or "convergence-dyson-tech-pending",width,tech.localised_name)
  end
 end
 local sequence=saved.transmission
 if sequence and not won then
  local panel=scroll.add{type="frame",style="inside_shallow_frame",
   direction="vertical"}
  panel.style.horizontally_stretchable=true
  local title=line(panel,"convergence-transmission-heading",width)
  title.style.font="heading-2"
  local elapsed=math.max(0,game.tick-sequence.started)
  local meter=panel.add{type="progressbar",
   value=math.min(1,elapsed/M.transmission_duration)}
  meter.style.horizontally_stretchable=true
  line(panel,"convergence-transmission-duration",width,
   tostring(math.max(0,math.ceil(
    (M.transmission_duration-elapsed)/60))))
  for i,beat in ipairs(M.transmission_beats) do
   local label=line(panel,
    i<=(sequence.beat or 1) and "convergence-transmission-beat-done"
     or "convergence-transmission-beat-pending",width,
    {"razi-ops."..beat.key})
   if i==sequence.beat then label.style.font="default-bold" end
  end
 end
 local where=M.location(player)
 line(scroll,where and "convergence-at-site"
  or "convergence-travel",width)
 local commission=force.technologies[defs.commission]
 local sync=force.technologies[defs.authorization]
 local ignition=force.technologies[defs.ignition]
 line(scroll,commission.researched and "convergence-commission-complete"
  or "convergence-commission-pending",width)
 line(scroll,sync.researched and "convergence-sync-complete"
  or "convergence-sync-pending",width)
 line(scroll,ignition.researched and "convergence-ignition-complete"
  or "convergence-ignition-pending",width)
 if won and (saved.delivered.resonance or 0)<M.stages[4].count then
  line(scroll,"convergence-legacy-victory",width)
 end
 local next_index=M.current(force)
 if not won and not saved.transmission then
  local next_rule=M.stages[next_index]
  if next_rule then
   local advice=scroll.add{type="frame",
     style="inside_shallow_frame",direction="vertical"}
   advice.style.horizontally_stretchable=true
   local title=line(advice,"convergence-next-action-title",width)
   title.style.font="heading-2"
   line(advice,"convergence-next-action-stage",width,
    {"razi-ops.convergence-stage-"..next_rule.id})
   local researched=commission.researched
    and (next_index<3 or sync.researched)
    and (next_index<5 or ignition.researched)
   local required=not researched and (not commission.researched
     and commission or (next_index<5 and sync or ignition))
   if required then
    line(advice,"convergence-next-action-research",width,
     required.localised_name)
    local shown=0
    for _,prior in pairs(required.prerequisites or {}) do
     if not prior.researched and shown<3 then
      line(advice,"convergence-next-action-prereq",width,
       prior.localised_name)
      shown=shown+1
     end
    end
   elseif next_index==5 and not receiver_ready then
    line(advice,"convergence-next-action-receiver",width)
   else
    line(advice,"convergence-next-action-freight",width)
   end
  end
 end
 -- Read one player's carried freight when the panel opens or redraws.
 -- No background inventory scans, and a remote camera cannot deliver it.
 local inventory=player.get_main_inventory()
 for i,rule in ipairs(M.stages) do
  local card=scroll.add{type="frame",style="inside_shallow_frame",
   direction="vertical"}
  card.style.horizontally_stretchable=true
  card.style.padding=9
  local title=card.add{type="flow",direction="horizontal"}
  local sprite=title.add{type="sprite",sprite="item/"..rule.item}
  sprite.style.width=35
  sprite.style.height=35
  local display=title.add{type="label",caption=L(
    "convergence-stage-"..rule.id)}
  display.style.font="heading-2"
  local donated=won and rule.count
   or math.min(rule.count,saved.delivered[rule.id] or 0)
  local amount=line(card,"convergence-stage-progress",width,
   tostring(donated),tostring(rule.count))
  amount.style.font_color=donated>=rule.count
   and {r=.49,g=.87,b=.71} or {r=.98,g=.74,b=.49}
  local meter=card.add{type="progressbar",
   value=math.min(1,donated/rule.count)}
  meter.style.horizontally_stretchable=true
  meter.style.height=12
  local status=i<next_index and "finished"
   or (i>next_index and "pending")
   or (i>=5 and not ignition.researched and "ignition")
   or (i>=3 and not sync.researched and "synchronization")
   or "active"
  local state=line(card,"convergence-status-"..status,width)
  state.style.font="default-bold"
  local carried=inventory and inventory.valid
   and inventory.get_item_count(rule.item) or 0
  line(card,"convergence-carried",width,tostring(carried))
  line(card,"convergence-stage-description-"..rule.id,width)
  local build=card.add{type="label",caption=L(
    "convergence-build-"..rule.id)}
  build.style.single_line=false
  build.style.maximal_width=width
  local button=card.add{type="button",
   caption=L("convergence-submit"),
   tags={razi_ops_action="convergence-deliver",value=rule.id}}
  button.enabled=i==next_index and carried>0 and where~=nil
   and (i<3 or sync.researched)
   and (i<5 or (ignition.researched and receiver_ready))
   and commission.researched
 end
 line(scroll,"convergence-continued-play",width)
end
return M
