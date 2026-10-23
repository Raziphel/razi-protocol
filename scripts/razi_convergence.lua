-- Real cargo, real destination, shared multiplayer progress.
-- This module is event/UI driven. No global platform or inventory scans.
local M={}
local defs=require("prototypes.technology.convergence")
local dyson_runtime=require("scripts.galactic_dyson_runtime")
local helios_operations=require("scripts.razi_helios_operations")
local galactic_catalog=require("scripts.galactic_catalog")
local deep_expedition=require("scripts.razi_deep_space_expedition")
local nexus_trials=require("scripts.razi_nexus_trials")
local story_dispatch=require("scripts.razi_story_dispatch")
M.stages=defs.shipments
-- Native factory delivery starts a short, persistent transmission sequence.
M.transmission_beats={
 {tick=0,key="convergence-transmission-sealed"},
 {tick=1800,key="convergence-transmission-dyson"},
 {tick=3600,key="convergence-transmission-resonance"},
 {tick=5400,key="convergence-transmission-alignment"}
}
M.transmission_duration=7200
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
-- Witness anchors are RAZI's physical, decentralized veto. Each of the
-- seven founding systems must independently keep a genuine powered station.
M.witness_systems={
 "calidus","solaris","nyxaris","vibrant","vespera","beetlejuice","umbra"
}
function M.witness_status(force)
 local locations={}
 local found={}
 local total=#M.witness_systems
 local known=force and force.get_entity_count
  and force.get_entity_count("radar")
 if known==0 then
  for _,system in ipairs(M.witness_systems) do
   locations[#locations+1]={system=system}
  end
  return 0,total,locations
 end
 for _,surface in pairs(game and game.surfaces or {}) do
  local planet=surface.planet
  local system=planet and galactic_catalog.system(planet.name)
  if system and not found[system]
   and surface.find_entities_filtered then
   for _,entity in pairs(surface.find_entities_filtered{
     name="radar",force=force}) do
    if entity.valid and (entity.energy or 0)>0 then
     found[system]=planet.name
     break
    end
   end
  end
 end
 local active=0
 for _,system in ipairs(M.witness_systems) do
  if found[system] then active=active+1 end
  locations[#locations+1]={system=system,planet=found[system]}
 end
 return active,total,locations
end
function M.expedition_status(force)
 return deep_expedition.status(force)
end
function M.nexus_status(force)
 return nexus_trials.snapshot(force)
end
function M.core_status(player)
 if not M.location(player) then return false end
 local surface=player.character.surface
 if not (surface and surface.find_entities_filtered) then return false end
 for _,entity in pairs(surface.find_entities_filtered{
  name="razi-convergence-array-core",force=player.force}) do
  if entity.valid and (entity.energy or 0)>0 then return true end
 end
 return false
end
-- Actual recovered evidence, not unlocked by an early research tooltip.
function M.blackbox(force)
 local saved=storage and storage.razi_convergence
 local record=saved and force and saved[force.index]
 if record and record.victory then return 3 end
 local delivered=record and record.delivered or {}
 if (delivered.resonance or 0)>=M.stages[4].count then
  return 2
 elseif (delivered["deep-space"] or 0)>=M.stages[3].count then
  return 1
 end
 return 0
end
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
  local witness=force.technologies["razi-convergence-witness-network"]
  if not (witness and witness.researched) then
   return false,"convergence-need-witness-research"
  end
  -- Native Nexus Bosses is the authority for every fight.
  -- Neither Nexus research nor the Silence warp key substitutes for wins.
  local nexus=M.nexus_status(force)
  if not nexus then
   return false,"convergence-need-nexus-source"
  end
  if nexus.count<nexus.total then
   return false,"convergence-need-nexus-trials"
  end
  if select(1,M.witness_status(force))<7 then
   return false,"convergence-need-witnesses"
  end
  local visited,required,_,chart_ready=M.expedition_status(force)
  if not chart_ready or required==0 then
   return false,"convergence-need-deep-chart"
  end
  if visited<required then
   return false,"convergence-need-deep-expedition"
  end
  if not M.dyson_readiness(force) then
   return false,"convergence-need-receiver"
  end
  local proof=settings and settings.startup
    and settings.startup["razi-helios-convergence-proof"]
  if proof and proof.value==true
    and not helios_operations.ready(force,true) then
    return false,"convergence-need-helios"
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
  if saved and saved.delivered and (saved.delivered[rule.id] or 0)>=rule.count then
   credit=credit+1
  else
   local amounts=saved and saved.materials and saved.materials[rule.id] or {}
   local requirements={{rule.item,rule.count}}
   for _,part in ipairs(rule.supplies or {}) do requirements[#requirements+1]=part end
   local fraction=0
   for _,part in ipairs(requirements) do
    fraction=fraction+math.min(1,(amounts[part[1]] or 0)/part[2])
   end
   credit=credit+fraction/#requirements
  end
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
 -- The epilogue is earned only by the actual victory state, never
 -- by researching Ignition or loading a previously completed save.
 story_dispatch.shipment(force,"victory")
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
 -- Native-only finale: no custom core entity required.
 local inv=player.get_main_inventory()
 if not (inv and inv.valid) then
  return "convergence-no-cargo",0
 end
 local saved=M.record(force)
 saved.materials=saved.materials or {}
 local amounts=saved.materials[id] or {}
 saved.materials[id]=amounts
 local supplies={{rule.item,rule.count}}
 for _,part in ipairs(rule.supplies or {}) do supplies[#supplies+1]=part end
 local removed_total=0
 -- Complete batches may be delivered across multiple visits. Each
 -- source-native ingredient is credited once and consumed only on receipt.
 for _,part in ipairs(supplies) do
  local name,required=part[1],part[2]
  local previous=amounts[name] or 0
  -- Existing save progress predates the multi-industry supply manifest.
  if name==rule.item then previous=math.max(previous,saved.delivered[id] or 0) end
  local offered=math.min(required-previous,inv.get_item_count(name))
  if offered>0 then
   local removed=inv.remove{name=name,count=offered}
   amounts[name]=previous+removed
   removed_total=removed_total+removed
  else
   amounts[name]=previous
  end
 end
 if removed_total<=0 then return "convergence-no-cargo",0 end
 local all=true
 for _,part in ipairs(supplies) do
  if (amounts[part[1]] or 0)<part[2] then all=false break end
 end
 if all then
  saved.delivered[id]=rule.count
  story_dispatch.shipment(force,id)
 end
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
  return "convergence-transmission-started",removed_total
 end
 return "convergence-delivered",removed_total
end
-- Only restore newly introduced recipe unlocks on an existing save.
-- Never reset the whole science tree or change another mod's research.
function M.repair_recipe_unlocks(force)
 -- Source mods exclusively own their recipe unlocks. Never unlock native
 -- products from Razi research or mutate already-researched saves.
 return
end

-- Only visit actively transmitting forces, once per second.
function M.advance(tick)
 local waiting=storage and storage.razi_convergence_pending
 if not waiting or not next(waiting) then return nil end
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
 target.materials=target.materials or {}
 for id,parts in pairs(source.materials or {}) do
  target.materials[id]=target.materials[id] or {}
  for name,amount in pairs(parts) do
   target.materials[id][name]=math.max(target.materials[id][name] or 0,amount)
  end
 end
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
function M.render(parent,player,options)
 options=options or {}
 local layout_width=options.width or math.max(320,math.min(850,
  (player.display_resolution.width or 1280)/
   math.max(player.display_scale or 1,.5)-100))
 local width=math.max(250,math.floor(layout_width)-28)
 if not options.embedded then
  local heading=line(parent,"convergence-heading",width)
  heading.style.font="heading-1"
  heading.style.font_color={r=.88,g=.73,b=1}
 end
 line(parent,"convergence-overview",width)
 local scroll=options.embedded and parent
   or parent.add{type="scroll-pane",direction="vertical"}
 if not options.embedded then
   scroll.style.horizontally_stretchable=true
   scroll.horizontal_scroll_policy="never"
   scroll.style.height=math.min(560,math.max(230,
     math.floor(player.display_resolution.height/
       math.max(player.display_scale or 1,.5)*.59)))
 end
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
 -- Budget each card's real width, including padding and spacing,
 -- rather than squeezing five 135px labels into a narrow panel.
 local columns=width>=780 and 5 or (width>=480 and 3 or 2)
 local cell_width=math.floor((width-24-(columns-1)*6)/columns)
 local tiles=scroll.add{type="table",column_count=columns}
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
  caption.style.maximal_width=math.max(72,cell_width-20)
  caption.style.font="default-bold"
  caption.style.font_color=shade
  local fill=tile.add{type="progressbar",value=donated/rule.count}
  fill.style.width=math.max(58,cell_width-24)
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
 -- Nexus trials are independently earned through real source-owned fights.
 -- The nine boss flags are authoritative; this panel does not spawn bosses.
 local trials_panel=scroll.add{type="frame",
  style="inside_shallow_frame",direction="vertical"}
 trials_panel.style.horizontally_stretchable=true
 local nexus=M.nexus_status(force)
 local count=nexus and nexus.count or 0
 local total=#nexus_trials.order
 local trials_title=line(trials_panel,"convergence-nexus-heading",width)
 trials_title.style.font="heading-2"
 line(trials_panel,nexus and "convergence-nexus-count"
  or "convergence-nexus-unavailable",width,
  tostring(count),tostring(total))
 if nexus and count<total then
  for _,boss in ipairs(nexus_trials.order) do
   if not nexus_trials.defeated(nexus,boss) then
    line(trials_panel,"convergence-nexus-missing",width,
      {"nexus-bosses.boss-"..boss})
   end
  end
 end
 -- Seven powered, independently built systems are the new physical
 -- countersignature. Never count technologies as functioning transmitters.
 local network=scroll.add{type="frame",
  style="inside_shallow_frame",direction="vertical"}
 network.style.horizontally_stretchable=true
 local wdone,wtotal,sites=M.witness_status(force)
 local witness_title=line(network,"convergence-witness-heading",width)
 witness_title.style.font="heading-2"
 line(network,"convergence-witness-count",width,
   tostring(wdone),tostring(wtotal))
 local network_research=force.technologies["razi-convergence-witness-network"]
 if network_research and not network_research.researched then
  line(network,"convergence-witness-research",width)
 end
 for _,site in ipairs(sites) do
  line(network,site.planet and "convergence-witness-online"
   or "convergence-witness-offline",width,
   {"razi-ops.convergence-system-"..site.system})
  if site.planet then
   local testimony=line(network,
     "convergence-witness-testimony-"..site.system,width)
   testimony.style.font_color={r=.73,g=.77,b=.82}
  end
 end
 line(network,M.core_status(player)
   and "convergence-core-ready"
   or "convergence-core-missing",width)
 -- Black-box recovery is shipment-gated; the reveal has tangible evidence.
 local blackbox=M.blackbox(force)
 if blackbox>0 then
  local archive=scroll.add{type="frame",
    style="inside_shallow_frame",direction="vertical"}
  archive.style.horizontally_stretchable=true
  local label=line(archive,"convergence-blackbox-heading",width)
  label.style.font="heading-2"
  for i=1,blackbox do
    line(archive,"convergence-blackbox-"..i,width)
  end
 end
 -- Complete personal landings, not technology research or an empty
 -- autopilot tour. Multiple real crew members may sign for one force.
 local expedition=scroll.add{type="frame",
   style="inside_shallow_frame",direction="vertical"}
 expedition.style.horizontally_stretchable=true
 local landed,required,stops,chart_ready=M.expedition_status(force)
 local expedition_title=line(expedition,"convergence-deep-tour-heading",width)
 expedition_title.style.font="heading-2"
 line(expedition,chart_ready and "convergence-deep-tour-count"
   or "convergence-deep-tour-unavailable",width,
   tostring(landed),tostring(required))
 for _,stop in ipairs(stops) do
   local item=line(expedition,stop.visited
     and "convergence-deep-tour-arrived"
     or "convergence-deep-tour-missing",width,stop.caption)
   item.style.font_color=stop.visited
     and {r=.48,g=.9,b=.72} or {r=.94,g=.72,b=.49}
 end
 line(expedition,"convergence-deep-tour-proof",width)
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
 local proof=settings and settings.startup
   and settings.startup["razi-helios-convergence-proof"]
 if proof and proof.value==true then
   local info=helios_operations.status(force)
   line(dyson,info.complete and "convergence-helios-ready"
     or "convergence-need-helios",width)
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
     and commission or (not sync.researched and sync or ignition))
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
   elseif next_index==5 and not nexus then
    line(advice,"convergence-next-action-nexus-source",width)
   elseif next_index==5 and count<total then
    line(advice,"convergence-next-action-nexus",width,
      tostring(count),tostring(total))
   elseif next_index==5 and wdone<wtotal then
    line(advice,"convergence-next-action-witnesses",width)
   elseif next_index==5 and (not chart_ready or landed<required) then
    line(advice,"convergence-next-action-deep-tour",width)
   elseif next_index==5 and not M.core_status(player) then
    line(advice,"convergence-next-action-core",width)
   elseif next_index==5 and not receiver_ready then
    line(advice,"convergence-next-action-receiver",width)
   elseif not (force.recipes and force.recipes[next_rule.item]
    and force.recipes[next_rule.item].enabled) then
    line(advice,"convergence-next-action-recipe",width)
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
  local cargo_available=false
  local amounts=saved.materials and saved.materials[rule.id] or {}
  local requirements={{rule.item,rule.count}}
  for _,part in ipairs(rule.supplies or {}) do requirements[#requirements+1]=part end
  for _,part in ipairs(requirements) do
   local credited=amounts[part[1]] or 0
   if part[1]==rule.item then
    credited=math.max(credited,saved.delivered[rule.id] or 0)
   end
   local owned=inventory and inventory.valid
    and inventory.get_item_count(part[1]) or 0
   if owned>0 and credited<part[2] then cargo_available=true end
   local row=card.add{type="label",caption={
    "", "[item="..part[1].."] ",tostring(credited),"/",tostring(part[2]),
    "  (",tostring(owned)," carried)"
   }}
   row.style.single_line=false
   row.style.maximal_width=width
  end
  line(card,"convergence-carried",width,tostring(carried))
  local recipe=force.recipes and force.recipes[rule.item]
  local recipe_state=not recipe and "convergence-recipe-unavailable"
   or (recipe.enabled and "convergence-recipe-ready"
   or "convergence-recipe-locked")
  line(card,recipe_state,width)
  line(card,"convergence-stage-description-"..rule.id,width)
  if i==#M.stages then
   local part_title=line(card,"convergence-component-heading",width)
   part_title.style.font="default-bold"
   for _,part in ipairs(defs.assemblies or {}) do
    local owned=inventory and inventory.valid
     and inventory.get_item_count(part.item) or 0
    local part_recipe=force.recipes and force.recipes[part.item]
    local row=card.add{type="flow",direction="horizontal"}
    row.style.horizontal_spacing=7
    local picture=row.add{type="sprite",sprite="item/"..part.item}
    picture.style.width=25
    picture.style.height=25
    local status=line(row,"convergence-component-line",width-44,
     {"item-name."..part.item},tostring(owned),
     part_recipe and part_recipe.enabled
       and {"razi-ops.convergence-component-craftable"}
       or {"razi-ops.convergence-component-research"})
    status.style.single_line=false
    status.style.font_color=owned>0 and {r=.49,g=.87,b=.71}
     or {r=.89,g=.76,b=.94}
    -- Read the force's ACTUAL installed recipe, including its optional
    -- source-material choices. No guessed shopping list or tick polling.
    if part_recipe and part_recipe.enabled then
     local ingredients={"",L("convergence-component-inputs")}
     for j,input in ipairs(part_recipe.ingredients or {}) do
      if j>1 then ingredients[#ingredients+1]="   " end
      ingredients[#ingredients+1]="[item="..input.name.."] "..
       tostring(input.amount or 1)
     end
     local detail=card.add{type="label",caption=ingredients}
     detail.style.single_line=false
     detail.style.maximal_width=width
    end
   end
  end
  local build=card.add{type="label",caption=L(
    "convergence-build-"..rule.id)}
  build.style.single_line=false
  build.style.maximal_width=width
  local button=card.add{type="button",
   caption=L("convergence-submit"),
   tags={razi_ops_action="convergence-deliver",value=rule.id}}
  button.enabled=i==next_index and cargo_available and where~=nil
   and (i<3 or sync.researched)
   and (i<5 or (ignition.researched and receiver_ready
     and ((not settings or not settings.startup
       or not settings.startup["razi-helios-convergence-proof"]
       or settings.startup["razi-helios-convergence-proof"].value~=true)
       or helios_operations.ready(force))))
   and commission.researched
 end
 line(scroll,"convergence-continued-play",width)
end
return M
