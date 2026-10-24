-- One event, one real asteroid; no scanning, timers or extra child chains.
-- A native hidden carrier asteroid is immediately replaced by a real entity.
local M={}
local engine=require("scripts.razi_asteroid_difficulty")
local levels=require("scripts.razi_difficulty_presets")
local PREFIX="razi-quality-asteroid-"
local length=#PREFIX
-- Startup options are immutable while a Factorio save runs.
-- Resolve once instead of repeating setting and connection lookups for
-- every generated asteroid on busy Deep Space platforms.
local active_mode
local function mode()
  if not active_mode then
    active_mode=levels.effective("razi-asteroid-difficulty-scale",
      "balanced")
  end
  return active_mode
end
local connection_routes=setmetatable({},{__mode="k"})
local function route_metadata(connection)
  local cached=connection_routes[connection]
  if cached then return cached end
  local from,to=connection.from,connection.to
  cached={from=from and from.name,to=to and to.name,
    length=connection.length}
  connection_routes[connection]=cached
  return cached
end
M.route_metadata=route_metadata
-- Runtime prototypes expose the same final connection graph that was used
-- for route art in data-final-fixes. Cache inference once on first trigger,
-- so third-party far-end asteroids receive the same difficulty as the map.
local prepared=false
local function prepare_runtime_levels()
  if prepared then return end
  prepared=true
  if prototypes and prototypes.space_connection then
    engine.prepare_routes(prototypes.space_connection)
  end
end
local function current_level(platform)
  prepare_runtime_levels()
  if not platform then return 1 end
  local connection=platform.space_connection
  if connection then
    return engine.route_level(route_metadata(connection),
      platform.distance,mode())
  end
  local location=platform.space_location
    or platform.last_visited_space_location
  local level=engine.location_level(location and location.name)
  local difficulty=mode()
  if level>1 and difficulty=="challenging" then level=level+.75 end
  if level>1 and difficulty=="relentless" then level=level+1.5 end
  return math.min(10,level)
end
function M.on_script_trigger_effect(event)
  local id=event and event.effect_id
  if type(id)~="string" or id:sub(1,length)~=PREFIX then return end
  local source=event.source_entity
  if not (source and source.valid and source.name==id) then return end
  local surface=source.surface
  if not surface then return end
  local original=id:sub(length+1)
  if original=="" then return end
  local platform=surface.platform
  local rank=current_level(platform)
  local quality=engine.roll(rank,math.random())
  -- Factorio's five vanilla quality prototypes are required by Space Age.
  -- If a broken mod removed a quality, degrade gracefully to normal.
  if not (prototypes and prototypes.quality
      and prototypes.quality[quality]) then quality="normal" end
  local options={
    name=original,position=source.position,direction=source.direction,
    force=source.force,quality=quality,
    raise_built=false,create_build_effect_smoke=false
  }
  local ok,created=pcall(surface.create_entity,options)
  if (not ok or not created) and quality~="normal" then
    options.quality="normal"
    ok,created=pcall(surface.create_entity,options)
  end
  -- Retain carrier if placement fails, rather than silently deleting it.
  if ok and created and created.valid then source.destroy() end
end
M.current_level=current_level
return M
