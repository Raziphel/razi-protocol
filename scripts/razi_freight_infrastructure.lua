-- Read-only infrastructure snapshot for the OPEN Cargo Network folio.
-- No stored LuaObjects, no periodic polling and no shipping assertions.
local M={}

-- Source prototypes are discovered from the installed game rather than
-- copied from Orbital Catapult. Treat matching hardware as CANDIDATES:
-- names/types cannot prove an active connection, sufficient power or cargo.
local entity_types={
  ["assembling-machine"]=true,["furnace"]=true,
  ["rocket-silo"]=true,["electric-energy-interface"]=true,
  ["container"]=true,["logistic-container"]=true,
  ["accumulator"]=true,["reactor"]=true
}
function M.launcher_names(known)
  local result={}
  for name,proto in pairs(known or (prototypes and prototypes.entity) or {}) do
    if type(name)=="string" and proto
      and entity_types[proto.type]
      and (name:find("^orbital%-cannon")
        or name:find("^orbital%-catapult")) then
      result[#result+1]=name
    end
  end
  table.sort(result)
  return result
end

local function built(platform)
  if not (platform and platform.valid and not platform.hidden
    and (not platform.scheduled_for_deletion
      or platform.scheduled_for_deletion==0)) then return false end
  local hub=platform.hub
  return hub and hub.valid==true or false
end

local function orbiting(force,world)
  if not force then return nil end
  if force.get_space_platforms then
    -- 2.1 returns only built platforms currently at this world. In flight
    -- platforms are NOT presented as orbiting or available for logistics.
    return force.get_space_platforms(world)
  end
  -- Fallback for tests/old runtime mocks; no assumption about schedules.
  local result={}
  if force.platforms then
    for _,platform in pairs(force.platforms) do
      local location=platform.space_location
      if location and location.name==world then
        result[#result+1]=platform
      end
    end
    return result
  end
  return nil
end

local function read_world(force,world,planet,names)
  local state={
    world=world,launcher_count=nil,launcher_state="unknown",
    platforms=nil,providers=nil,unscheduled=nil
  }
  -- A planet surface may not exist until first arrival. Do not create it.
  local surface=planet and planet.surface
  if #names>0 and surface and surface.valid~=false
    and surface.count_entities_filtered then
    local n=surface.count_entities_filtered{name=names,force=force}
    if type(n)=="number" and n>=0 then
      state.launcher_count=n
      state.launcher_state=n>0 and "candidate" or "none"
    end
  end
  local docked=orbiting(force,world)
  if docked then
    local count,providers,unscheduled=0,0,0
    for _,platform in pairs(docked) do
      if built(platform) then
        count=count+1
        if platform.hub.type=="space-platform-hub"
          and platform.hub.providing_to_other_platforms==true then
          providers=providers+1
        end
        local schedule=platform.schedule
        if not (schedule and schedule.records
          and #schedule.records>0) then
          unscheduled=unscheduled+1
        end
      end
    end
    state.platforms=count
    state.providers=providers
    state.unscheduled=unscheduled
  end
  return state
end

function M.snapshot(force,network,options)
  options=options or {}
  local result={worlds={},checked=0,
    platform_logistics=script and script.active_mods
      and script.active_mods["platform-logistics-overhaul"]~=nil or false}
  if not (force and network and network.installed and network.enabled) then
    return result
  end
  -- Only inspect genuinely discovered and visible configured corridors.
  -- Spoiler-off previews must not query or expose unresearched worlds.
  local wanted={}
  for _,lane in ipairs(network.entries or {}) do
    if lane.state=="researched"
      and lane.source_researched and lane.target_researched then
      wanted[lane.source]=true
      wanted[lane.target]=true
    end
  end
  if not next(wanted) then return result end
  local planets=options.planets or (game and game.planets) or {}
  local names=options.launcher_names or M.launcher_names()
  for world in pairs(wanted) do
    local planet=planets[world]
    if planet then
      result.worlds[world]=read_world(force,world,planet,names)
      result.checked=result.checked+1
    end
  end
  return result
end
return M
