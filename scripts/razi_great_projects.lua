-- Physical Razi megaprojects; every counter reflects actual source-owned
-- machines, visited routes or explicitly registered freight. One-time force
-- records are persisted; there is no periodic all-surface polling.
local M={}
local catapult=require("scripts.razi_catapult_network")
local catalog=require("scripts.galactic_catalog")
local valid_crossings={
  vibrant={"asteroid-belt-inner-edge","asteroid-belt-outer-edge"},
  umbra={"razi-umbra-belt-inner","razi-umbra-belt-outer"}
}
M.ark_weight=1000000
local function store(force)
  if not (storage and force and force.index) then return nil end
  storage.razi_great_projects=storage.razi_great_projects or {}
  local all=storage.razi_great_projects
  if not all[force.index] then
    all[force.index]={belts={},pending={},skybridge={}}
  end
  local state=all[force.index]
  state.belts=state.belts or {}
  state.pending=state.pending or {}
  state.skybridge=state.skybridge or {}
  return state
end
local function active(platform)
  return platform and platform.valid and platform.hub
    and platform.hub.valid and
    (not platform.scheduled_for_deletion or
      platform.scheduled_for_deletion==0)
end
local function contains_pair(a,b,ends)
  return (a==ends[1] and b==ends[2])
    or (a==ends[2] and b==ends[1])
end
local function conn_ends(link)
  if not link then return nil,nil end
  local from,to=link.from,link.to
  return type(from)=="table" and from.name or from,
    type(to)=="table" and to.name or to
end
local function planet_surface(name)
  local world=game and game.planets and game.planets[name]
  return world and world.surface
end
-- Identify real native physical catapult entities, never RAZI's
-- decorative route prototypes or sprites. Unknown native versions fail
-- closed rather than pretending research is a real launcher.
local native_names
local function native_catapults()
  if native_names then return native_names end
  native_names={}
  local known=prototypes and prototypes.entity or {}
  for name,prototype in pairs(known) do
    local text=type(name)=="string" and name:lower() or ""
    if (text:find("orbital%-cannon") or
      text:find("orbital%-catapult"))
      and prototype.type~="projectile" and
      prototype.type~="explosion" and
      prototype.type~="corpse" and
      prototype.type~="simple-entity" then
      native_names[#native_names+1]=name
    end
  end
  table.sort(native_names)
  return native_names
end
local function installed(force,world,names)
  local surface=planet_surface(world)
  return surface and #names>0 and surface.count_entities_filtered
    and surface.count_entities_filtered{name=names,force=force}>0 or false
end
local function powered_relay(force,world)
  local surface=planet_surface(world)
  if not (surface and surface.find_entities_filtered) then return false end
  for _,entity in pairs(surface.find_entities_filtered{
    name="razi-archive-relay",force=force}) do
    if entity.valid and entity.energy and entity.energy>0 then return true end
  end
  return false
end
function M.array(force)
  local systems={}
  local sites={}
  -- The Factorio engine maintains this count; most saves have no relays.
  -- Avoid scanning every generated planet when the project is untouched.
  local known=force and force.get_entity_count and
    force.get_entity_count("razi-archive-relay") or 0
  if known<=0 then return 0,3,sites end
  for _,surface in pairs(game and game.surfaces or {}) do
    local world=surface.planet
    local id=world and world.name
    local system=id and catalog.system(id)
    if system and system~="unassigned" and system~="deep-space"
      and not systems[system]
      and surface.find_entities_filtered then
      for _,entity in pairs(surface.find_entities_filtered{
        name="razi-archive-relay",force=force}) do
        if entity.valid and entity.energy and entity.energy>0 then
          systems[system]=true
          sites[#sites+1]={system=system,world=id}
          break
        end
      end
    end
    if #sites>=3 then break end
  end
  table.sort(sites,function(a,b)return a.system<b.system end)
  -- Only genuine powered relays release each archive fragment. Once
  -- recovered, its historical text persists even if a relay is dismantled.
  local saved=store(force)
  if saved then saved.archive_recovered=math.max(
    saved.archive_recovered or 0,math.min(3,#sites)) end
  return #sites,3,sites
end
function M.recovered(force)
  local all=storage and storage.razi_great_projects
  local record=all and force and all[force.index]
  return record and record.archive_recovered or 0
end
local function lanes(force)
  return catapult.snapshot(force)
end
function M.skybridge(force)
  local past=store(force)
  if past and past.skybridge and past.skybridge.complete then
    return 3,3,{options={},chosen=past.skybridge,installed=true,
      missing=false,transport_unverified=true}
  end
  local snapshot=lanes(force)
  if not (snapshot.installed and snapshot.enabled) then
    return 0,3,{missing=true}
  end
  local names=native_catapults()
  local options={}
  for _,lane in ipairs(snapshot.entries) do
    if lane.source_researched and lane.target_researched
      and installed(force,lane.source,names)
      and installed(force,lane.target,names) then
      options[#options+1]=lane
    end
  end
  table.sort(options,function(a,b)return a.id<b.id end)
  local state=store(force)
  local chosen=state and state.skybridge
  local paired=#options>0
  local signed=chosen and chosen.from and chosen.to
  local delivered=signed and chosen.delivered
  return (paired and 1 or 0)+(signed and 1 or 0)+
    (delivered and 1 or 0),3,{
    options=options,chosen=chosen,installed=#names>0,
    missing=#names==0,transport_unverified=true
  }
end
local function current_planet(player)
  local surface=player and player.physical_surface
    or player and player.character and player.character.surface
  local planet=surface and surface.planet
  return planet and planet.name
end
function M.sign(player,source,target)
  if not (player and player.valid and player.character
    and source and target and source~=target) then return false end
  if current_planet(player)~=source then return false end
  local state=store(player.force).skybridge
  if state.complete or state.from then return false end
  local _,_,status=M.skybridge(player.force)
  local accepted=false
  for _,lane in ipairs(status.options or {}) do
    if lane.source==source and lane.target==target then
      accepted=true break
    end
  end
  if not accepted then return false end
  local inv=player.get_main_inventory()
  if not inv or inv.get_item_count("processing-unit")<20
    or not inv.can_insert{name="razi-skybridge-consignment",count=1}
    then return false end
  inv.remove{name="processing-unit",count=20}
  inv.insert{name="razi-skybridge-consignment",count=1}
  state.from=source
  state.to=target
  state.delivered=false
  return true
end
function M.deliver(player)
  if not (player and player.valid and player.character) then return false end
  local state=store(player.force).skybridge
  if not (state.to and current_planet(player)==state.to) then return false end
  local inv=player.get_main_inventory()
  if not inv or inv.get_item_count("razi-skybridge-consignment")<1 then
    return false
  end
  inv.remove{name="razi-skybridge-consignment",count=1}
  state.delivered=true
  state.complete=true
  return true
end
-- Only registered source-route departures and destination arrivals count
-- as Beltbreaker crossings, never mere visits to both belt rims.
local function qualified_ark(platform)
  if not active(platform) or (platform.weight or 0)<M.ark_weight
    then return false end
  local surface=platform.surface
  if not (surface and surface.count_entities_filtered) then return false end
  local force=platform.force
  return surface.count_entities_filtered{name="thruster",force=force}>=3
    and surface.count_entities_filtered{type="ammo-turret",force=force}>=4
    and surface.count_entities_filtered{type="assembling-machine",force=force}>=2
end
local deep={"solar-system-edge","razi-deep-space-edge",
  "nexus","shattered-planet"}
local function is_deep(name)
  for _,id in ipairs(deep) do if id==name then return true end end
  return false
end
function M.observe(platform)
  if not active(platform) then return false end
  local state=store(platform.force)
  if not state then return false end
  local index=platform.index
  if not index then return false end
  local previous=state.pending[index]
  local link=platform.space_connection
  local from,to=conn_ends(link)
  if from and to then
    local origin=platform.last_visited_space_location
    local last=origin and origin.name
    local pending={from=from,to=to,
      count=platform.completed_trips or 0,
      ark=qualified_ark(platform)}
    if previous and previous.from==from and previous.to==to then
      pending=previous
    end
    if (last==from or last==to) then
      state.pending[index]=pending
    end
    return false
  end
  if not previous then return false end
  local location=platform.space_location
  local arrived=location and location.name
  state.pending[index]=nil
  if not (arrived and
    (platform.completed_trips or 0)>previous.count) then return false end
  local changed=false
  for kind,ends in pairs(valid_crossings) do
    if not state.belts[kind] and
      contains_pair(previous.from,previous.to,ends)
      and (arrived==previous.from or arrived==previous.to) then
      state.belts[kind]=true
      changed=true
    end
  end
  if previous.ark and is_deep(arrived) and
    not state.ark then
    state.ark=true
    state.ark_name=platform.name
    changed=true
  end
  return changed
end
function M.beltbreaker(force)
  local state=store(force)
  local belts=state and state.belts or {}
  local done=(belts.vibrant and 1 or 0)+(belts.umbra and 1 or 0)
  return done,2,belts
end
function M.ark(force)
  local state=store(force)
  if state and state.ark then return 1,1,state.ark_name end
  local candidate
  for _,platform in pairs(force and force.platforms or {}) do
    if qualified_ark(platform) then
      candidate=platform.name
      break
    end
  end
  return 0,1,candidate
end
-- Arrival state events have historically been unreliable in some engine
-- builds. Only forces with an actual recorded outgoing crossing are checked
-- every 300 ticks; no idle-platform, entity or surface scans occur.
function M.flush_pending(forces)
  local all=storage and storage.razi_great_projects
  if not all then return false end
  local changed=false
  for force_index,state in pairs(all) do
    if next(state.pending or {}) then
      local force=forces and forces[force_index]
      if force then
        local current={}
        for _,platform in pairs(force.platforms or {}) do
          if platform.valid and platform.index then
            current[platform.index]=platform
          end
        end
        for index in pairs(state.pending) do
          local platform=current[index]
          if platform then
            if M.observe(platform) then changed=true end
          else
            state.pending[index]=nil
          end
        end
      end
    end
  end
  return changed
end

function M.forces_merged(event)
  local all=storage and storage.razi_great_projects
  if not (all and event) then return end
  local source=all[event.source_index]
  if not source then return end
  local target_index=event.destination and event.destination.index
    or event.destination_index
  if not target_index then return end
  local target=all[target_index] or {belts={},pending={},skybridge={}}
  target.belts=target.belts or {}
  for id,done in pairs(source.belts or {}) do
    if done then target.belts[id]=true end
  end
  target.archive_recovered=math.max(target.archive_recovered or 0,
    source.archive_recovered or 0)
  if source.ark and not target.ark then
    target.ark=true
    target.ark_name=source.ark_name
  end
  target.skybridge=target.skybridge or {}
  if source.skybridge and source.skybridge.delivered
    and not target.skybridge.delivered then
    target.skybridge=source.skybridge
  end
  target.pending={} -- Old platform indices change on force merges.
  all[target_index]=target
  all[event.source_index]=nil
end
return M
