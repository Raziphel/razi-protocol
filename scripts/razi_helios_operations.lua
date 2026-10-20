-- HELIOS real commissioning: consumed cargo at source-owned solar orbits,
-- real dwell time on a force-owned platform and powered grid stations.
-- No private Dyson globals, invented satellite counts, simulated megawatts
-- or scheduled per-tick surface scans.
local M={}
local requirements={expedition={outer=8,inner=12,grid=2},
  monumental={outer=20,inner=24,grid=4}}
M.requirements=requirements
M.stages={
 outer={item="razi-helios-corona-shield",tech="razi-helios-corona-engineering",
   location_tech="planet-discovery-sunorbit",hold=3600},
 inner={item="razi-helios-orbital-lattice",tech="razi-helios-grid-commission",
   location_tech="slp-solar-system-sun2",hold=7200}
}
local function mode()
 local s=settings and settings.startup
   and settings.startup["razi-helios-commissioning"]
 return s and s.value or "expedition"
end
local function enabled()
 return requirements[mode()]~=nil
end
function M.targets()
 return requirements[mode()] or {outer=0,inner=0,grid=0}
end
local function saved()
 storage.razi_helios_commissions=storage.razi_helios_commissions or {}
 return storage.razi_helios_commissions
end
function M.record(force)
 if not force then return {outer=0,inner=0} end
 local all=saved()
 local key=force.index or force.name
 local row=all[key]
 if not row then
   row={outer=0,inner=0}
   all[key]=row
 end
 return row
end
function M.destination(tech_id)
 local tech=prototypes and prototypes.technology
   and prototypes.technology[tech_id]
 for _,effect in ipairs(tech and tech.effects or {}) do
   if effect.type=="unlock-space-location" and effect.space_location then
     return effect.space_location
   end
 end
end
local function valid_platform(player)
 if not (player and player.valid and player.character
   and player.character.valid) then return nil end
 if defines and defines.controllers
   and player.controller_type==defines.controllers.remote then
   return nil
 end
 local surface=player.character.surface
 local platform=surface and surface.platform
 if not (platform and platform.valid and platform.force==player.force
   and platform.space_location and not platform.space_connection) then
   return nil
 end
 return platform
end
local function holds()
 storage.razi_helios_holds=storage.razi_helios_holds or {}
 return storage.razi_helios_holds
end
-- Normal platform arrival event is an early witness. The GUI also starts
-- a hold lazily, so existing saves without arrival records remain playable.
function M.observe(platform)
 if not (enabled() and platform and platform.valid) then return end
 local location=platform.space_location and platform.space_location.name
 local key=platform.index
 -- This event is raised for *every* moving platform. Keep a hold record
 -- only for actual SLP solar destinations and discard stale departures.
 local relevant=location and not platform.space_connection
   and (location==M.destination("planet-discovery-sunorbit")
     or location==M.destination("slp-solar-system-sun2"))
 if not relevant then
   local all=storage and storage.razi_helios_holds
   if all then all[key]=nil end
   return
 end
 local all=holds()
 local known=all[key]
 if not known or known.location~=location then
   all[key]={location=location,since=game.tick or 0}
 end
end
-- Scheduled coronal communication outages are deterministic for all forces.
-- They interrupt physical commissioning, never the native SLP power logic.
-- Computed on demand, with no global timer, entity spawns or tick scans.
local surge_periods={
 occasional={cycle=36000,active=3600},
 volatile={cycle=24000,active=4800}
}
function M.coronal_surge(tick)
 local s=settings and settings.startup
   and settings.startup["razi-helios-coronal-surges"]
 local rule=surge_periods[s and s.value or "occasional"]
 if not rule then return false,0,nil end
 tick=math.max(0,tick or 0)
 local start=tick-math.fmod(tick,rule.cycle)
 local phase=tick-start
 local active=phase<rule.active
 local seconds=math.ceil((active and rule.active-phase
   or rule.cycle-phase)/60)
 local last_end=active and start-rule.cycle+rule.active
   or start+rule.active
 return active,seconds,last_end
end
function M.hold_seconds(player,stage)
 local spec=M.stages[stage]
 if not spec then return 0,false end
 local platform=valid_platform(player)
 local target=M.destination(spec.location_tech)
 if not (platform and target and platform.space_location.name==target) then
   return 0,false
 end
 M.observe(platform)
 local entry=holds()[platform.index]
 local active,_,last_end=M.coronal_surge(game.tick or 0)
 if active then return 0,false,true end
 local since=math.max(entry.since or 0,last_end or 0)
 local duration=math.max(0,(game.tick or 0)-since)
 return math.floor(duration/60),duration>=spec.hold,false
end
function M.deliver(player,stage)
 local spec=M.stages[stage]
 if not (enabled() and spec and player and player.force) then
   return "helios-not-ready",0
 end
 local needed=M.targets()[stage]
 local row=M.record(player.force)
 local delivered=row[stage] or 0
 if delivered>=needed then return "helios-complete",0 end
 local tech=player.force.technologies and player.force.technologies[spec.tech]
 if not (tech and tech.researched) then return "helios-need-research",0 end
 local elapsed,ready,surge=M.hold_seconds(player,stage)
 if surge then return "helios-need-surge",0 end
 if not ready then
   if elapsed==0 then return "helios-need-orbit",0 end
   return "helios-need-hold",0
 end
 if stage=="inner" and row.outer<M.targets().outer then
   return "helios-need-outer",0
 end
 local inv=player.get_main_inventory()
 if not (inv and inv.valid) then return "helios-no-cargo",0 end
 local available=inv.get_item_count(spec.item)
 local offered=math.min(needed-delivered,available)
 if offered<=0 then return "helios-no-cargo",0 end
 local removed=inv.remove{name=spec.item,count=offered}
 if not removed or removed<=0 then return "helios-no-cargo",0 end
 row[stage]=math.min(needed,delivered+removed)
 return "helios-delivered",removed
end
-- Never enumerate planet surfaces on every GUI redraw. The engine tracks
-- total anchor counts in O(1), while a three-second snapshot covers voltage
-- changes between physical build/remove events. The final cargo submission
-- can explicitly request a fresh result.
M.grid_cache_ticks=180
function M.invalidate_grid(force)
 local all=storage and storage.razi_helios_grid_cache
 if not all then return end
 if force and force.index then all[force.index]=nil
 else storage.razi_helios_grid_cache=nil end
end
function M.anchor_changed(entity)
 if entity and entity.valid and entity.name=="razi-helios-grid-anchor" then
   M.invalidate_grid(entity.force)
 end
end
function M.grid(force,refresh)
 local result={installed=0,powered=0,worlds={}}
 if not (enabled() and force and game and game.surfaces
   and force.get_entity_count) then return result end
 local name="razi-helios-grid-anchor"
 local total=force.get_entity_count(name) -- O(1), even on massive saves.
 if total==0 then
   M.invalidate_grid(force)
   return result
 end
 local tick=game.tick or 0
 local all=storage and storage.razi_helios_grid_cache
 local key=force.index or force.name
 local entry=all and all[key]
 if not refresh and entry and entry.total==total
   and tick>=entry.tick and tick-entry.tick<M.grid_cache_ticks then
   return entry.value
 end
 for _,surface in pairs(game.surfaces) do
   -- Planet surfaces only. No platform or unrelated entity enumeration.
   if surface.valid~=false and surface.planet and not surface.platform then
     local entities=surface.find_entities_filtered{name=name,force=force}
     local online=0
     for _,entity in ipairs(entities) do
       if entity.valid and type(entity.energy)=="number"
         and entity.energy>0 then
         online=online+1
       end
     end
     if #entities>0 then
       result.installed=result.installed+#entities
       result.powered=result.powered+online
       result.worlds[#result.worlds+1]={
         name=surface.planet.name,installed=#entities,powered=online}
     end
   end
 end
 table.sort(result.worlds,function(a,b)return a.name<b.name end)
 if storage then
   storage.razi_helios_grid_cache=storage.razi_helios_grid_cache or {}
   storage.razi_helios_grid_cache[key]={
     tick=tick,total=total,value=result}
 end
 return result
end
function M.status(force,refresh)
 local req=M.targets()
 local done=M.record(force)
 local grid=M.grid(force,refresh)
 local distinct=0
 for _,world in ipairs(grid.worlds) do
   if world.powered>0 then distinct=distinct+1 end
 end
 return {outer=done.outer or 0,inner=done.inner or 0,
   grid=grid,worlds=distinct,requirements=req,
   complete=not enabled() or ((done.outer or 0)>=req.outer
     and (done.inner or 0)>=req.inner and distinct>=req.grid)}
end
function M.ready(force,refresh)
 if not enabled() then return true end
 -- If an upstream update removed an essential native recipe or if a valid
 -- mod combination cannot register our hardware, the optional finale gate
 -- must never create an impossible permanent research deadlock.
 local technologies=force and force.technologies
 if not (technologies and technologies["razi-helios-grid-commission"]) then
   return true
 end
 return M.status(force,refresh).complete
end
function M.forces_merged(event)
 local all=storage and storage.razi_helios_commissions
 if not all then return end
 local src,dst=event.source_index,event.destination_index
 if not (src and dst and src~=dst) then return end
 M.invalidate_grid({index=src})
 M.invalidate_grid({index=dst})
 local source=all[src]
 if not source then return end
 local dest=all[dst] or {outer=0,inner=0}
 local req=M.targets()
 dest.outer=math.min(req.outer,(dest.outer or 0)+(source.outer or 0))
 dest.inner=math.min(req.inner,(dest.inner or 0)+(source.inner or 0))
 all[dst]=dest
 all[src]=nil
end
return M
