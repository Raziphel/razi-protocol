-- Real cargo, real destination, shared multiplayer progress.
-- This module is event/UI driven. No global platform or inventory scans.
-- The state, the delivery of cargo and the transmission sequence live here; the
-- panel that shows them is scripts/convergence/panel.lua, which adds M.render.
local M=require("scripts.convergence.api")
local defs=require("prototypes.technology.endgame.convergence")
local dyson_runtime=require("scripts.dyson.runtime")
local galactic_catalog=require("lib.galactic_catalog")
local deep_expedition=require("scripts.convergence.deep_space_expedition")
local nexus_trials=require("scripts.compatibility.nexus-bosses.trials")
local story=require("lib.story")
-- Adds M.render.
require("scripts.convergence.panel")
M.stages=defs.shipments
-- Native factory delivery starts a short, persistent transmission sequence.
M.transmission_beats={
 {tick=0,id="sealed",key="convergence-transmission-sealed"},
 {tick=1800,id="dyson",key="convergence-transmission-dyson"},
 {tick=3600,id="resonance",key="convergence-transmission-resonance"},
 {tick=5400,id="alignment",key="convergence-transmission-alignment"}
}
M.transmission_duration=7200
-- The beat captions are story text. Without the story each beat is just
-- its number in the sequence.
-- `player` is the one who reads it; chat lines for a whole force pass none.
local function beat_text(index,player)
 local key=M.transmission_beats[index].key
 if story.visible(player) then
  return story.text(player,"finale-beat",M.transmission_beats[index].id,
   {"razi-ops."..key})
 end
 return {"razi-story-off.transmission-stage",tostring(index),
  tostring(#M.transmission_beats)}
end
M.beat_text=beat_text
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
     ---@diagnostic disable-next-line: need-check-nil
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
   ---@diagnostic disable-next-line: undefined-field
   local amounts=saved and saved.materials and saved.materials[rule.id] or {}
   local requirements={{rule.item,rule.count}}
   for _,part in ipairs(rule.supplies or {}) do requirements[#requirements+1]=part end
   local fraction=0
   for _,part in ipairs(requirements) do
    ---@diagnostic disable-next-line: assign-type-mismatch
    fraction=fraction+math.min(1,(amounts[part[1]] or 0)/part[2])
   end
   ---@diagnostic disable-next-line: assign-type-mismatch
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
 story.dispatch.shipment(force,"victory")
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
  local section=story.enabled() and "razi-ops" or "razi-story-off"
  game.set_win_ending_info{
   title={section..".convergence-victory-title"},
   message={section..".convergence-victory-message"},
   bullet_points={
    {section..".convergence-victory-stellar"},
    {section..".convergence-victory-industry"},
    {section..".convergence-victory-deep"},
    {section..".convergence-victory-resonance"},
    {section..".convergence-victory-ignition"}
   },
   final_message={section..".convergence-victory-final"}
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
  story.dispatch.shipment(force,id)
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
   force.print(beat_text(1))
  end
  return "convergence-transmission-started",removed_total
 end
 return "convergence-delivered",removed_total
end
-- Only restore newly introduced recipe unlocks on an existing save.
-- Never reset the whole science tree or change another mod's research.
function M.repair_recipe_unlocks(force) -- luacheck: ignore 212
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
   ---@diagnostic disable-next-line: assign-type-mismatch
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
      force.print(beat_text(next_beat))
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
 ---@diagnostic disable-next-line: inject-field, undefined-field
 target.materials=target.materials or {}
 ---@diagnostic disable-next-line: undefined-field
 for id,parts in pairs(source.materials or {}) do
  ---@diagnostic disable-next-line: undefined-field
  target.materials[id]=target.materials[id] or {}
  for name,amount in pairs(parts) do
   ---@diagnostic disable-next-line: undefined-field
   target.materials[id][name]=math.max(target.materials[id][name] or 0,amount)
  end
 end
 for _,rule in ipairs(M.stages) do
  ---@diagnostic disable-next-line: assign-type-mismatch
  target.delivered[rule.id]=math.min(rule.count,
   (target.delivered[rule.id] or 0)
   +(source.delivered and source.delivered[rule.id] or 0))
 end
 target.victory=target.victory or source.victory
 target.victory_tick=target.victory_tick or source.victory_tick
 target.completed_by=target.completed_by or source.completed_by
 ---@diagnostic disable-next-line: undefined-field, inject-field
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
return M
