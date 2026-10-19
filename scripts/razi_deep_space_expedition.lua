-- Physical Deep Space expedition for Convergence.
-- "Visited" means a real player was aboard a force-owned, arrived platform,
-- not remote view, discovery research, a platform sent without a crew, or
-- a scanned atlas tile. Team members may contribute to the force's record.
-- Only installed, connected, navigable named Deep Space destinations count.
local M={}
local candidates={
  "solar-system-edge","razi-deep-space-edge",
  "nexus","shattered-planet",
  "black-hole-approach","black-hole","oort-cloud","sol",
  -- Optional expedition arms. They become mandatory IF actually installed
  -- and linked to the same traversable Deep Space route graph.
  "skewer_shattered_planet","skewer_lost_beyond",
  "calidus-bellicos-stargate-calidus","near-bellicos-orbit",
  "bellicos-near-orbit","near_bellicos_orbit",
  "aegis-inner-edge","point-warden","aegis-outer-edge",
  "calidus-bellicos-stargate-bellicos"
}
M.candidates=candidates

local targets_cache
local function location(name)
  return prototypes and ((prototypes.space_location or {})[name]
    or (prototypes.planet or {})[name])
end
local function endpoint_name(value)
  if type(value)=="string" then return value end
  if type(value)=="table" or type(value)=="userdata" then
    return value.name
  end
end
-- Resolve once per control-script lifetime; prototype graph is immutable
-- until a mod update, which reloads the Lua environment.
function M.targets()
  if targets_cache then return targets_cache,true end
  if not (prototypes and prototypes.space_connection and
    location("solar-system-edge")) then
    return {},false
  end
  local graph={}
  local function attach(a,b)
    if not (a and b and location(a) and location(b)) then return end
    graph[a]=graph[a] or {}
    graph[b]=graph[b] or {}
    graph[a][b]=true
    graph[b][a]=true
  end
  for _,route in pairs(prototypes.space_connection) do
    if not route.hidden then
      attach(endpoint_name(route.from),endpoint_name(route.to))
    end
  end
  local visited={["solar-system-edge"]=true}
  local queue={"solar-system-edge"}
  local index=1
  while index<=#queue do
    local at=queue[index]
    index=index+1
    for neighbor in pairs(graph[at] or {}) do
      if not visited[neighbor] then
        visited[neighbor]=true
        queue[#queue+1]=neighbor
      end
    end
  end
  local results={}
  local included={}
  local function include(name)
    if included[name] then return end
    local proto=location(name)
    -- Runtime LuaSpaceLocationPrototype does not expose the data-stage
    -- sprite_only flag; sprite-only parents are removed before runtime.
    if proto and visited[name] and not proto.hidden then
      included[name]=true
      results[#results+1]={id=name,
        caption=proto.localised_name or {"",name}}
    end
  end
  for _,name in ipairs(candidates) do include(name) end
  -- The source Aegis/Bellicos and Shattered/Skewer families rename their
  -- endpoints across ports. Include every connected real location from
  -- those families rather than silently overlooking a new named Warden.
  local extra={}
  for name in pairs(prototypes.space_location or {}) do
    local lower=type(name)=="string" and name:lower() or ""
    if (lower:find("aegis",1,true)
      or lower:find("bellicos",1,true)
      or lower:find("warden",1,true)
      or lower:find("skewer",1,true))
      and not included[name] then
      extra[#extra+1]=name
    end
  end
  table.sort(extra)
  for _,name in ipairs(extra) do include(name) end
  -- A disconnected Edge cannot be presented as the whole expedition.
  -- If every route is missing, report an unavailable chart instead.
  if #queue==1 then return {},false end
  targets_cache=results
  return results,true
end

local function store(force)
  if not (storage and force and force.index) then return nil end
  storage.razi_deep_space_visits=storage.razi_deep_space_visits or {}
  local all=storage.razi_deep_space_visits
  all[force.index]=all[force.index] or {}
  return all[force.index]
end
local function recorded(force)
  return storage and storage.razi_deep_space_visits and force
    and storage.razi_deep_space_visits[force.index] or {}
end
function M.status(force)
  local destinations,available=M.targets()
  local saved=recorded(force)
  local rows,done={},0
  for _,entry in ipairs(destinations) do
    local visit=saved[entry.id]
    if visit then done=done+1 end
    rows[#rows+1]={
      id=entry.id,caption=entry.caption,visited=visit~=nil,
      by=visit and visit.by,platform=visit and visit.platform
    }
  end
  return done,#destinations,rows,available
end
function M.observe(player)
  if not (player and player.valid and player.force
    and player.character and player.character.valid) then return false end
  if defines and defines.controllers
    and player.controller_type==defines.controllers.remote then
    return false
  end
  local surface=player.character.surface
  local platform=surface and surface.platform
  if not (platform and platform.valid and platform.force==player.force
    and platform.hub and platform.hub.valid
    and (not platform.scheduled_for_deletion
      or platform.scheduled_for_deletion==0)
    and (platform.completed_trips or 0)>0) then
    return false
  end
  local current=platform.space_location
  local name=current and current.name
  if not name then return false end
  local destinations,available=M.targets()
  if not available then return false end
  local required=false
  for _,entry in ipairs(destinations) do
    if entry.id==name then required=true break end
  end
  if not required then return false end
  local saved=store(player.force)
  if not saved or saved[name] then return false end
  saved[name]={by=player.name,platform=platform.name,
    tick=game and game.tick or 0}
  return true
end
function M.observe_connected(platform)
  local changed=false
  for _,player in pairs(game and game.connected_players or {}) do
    -- Called for a particular platform event or for sparse reconciliation.
    local surface=player.character and player.character.surface
    if not platform or (surface and surface.platform==platform) then
      if M.observe(player) then changed=true end
    end
  end
  return changed
end
function M.forces_merged(event)
  local all=storage and storage.razi_deep_space_visits
  if not (all and event) then return end
  local source=all[event.source_index]
  if not source then return end
  local index=event.destination and event.destination.index
    or event.destination_index
  if not index then return end
  local destination=all[index] or {}
  for name,visit in pairs(source) do
    if not destination[name] then destination[name]=visit end
  end
  all[index]=destination
  all[event.source_index]=nil
end
return M
