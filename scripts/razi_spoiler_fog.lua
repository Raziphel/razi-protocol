-- Razi-only research fog. Never disable or relabel third-party technology.
-- Disabled future *Razi* technologies disappear from Factorio's research
-- screen until all their real prerequisites have been researched.
-- Their prior enabled/visible settings are saved and can be restored.
-- This is event-driven: no game tick, force-wide inventory or GUI scanning.
local M={}
M.setting="razi-hide-spoilers"
function M.enabled()
  local option=settings and settings.global and settings.global[M.setting]
  return option and option.value==true or false
end
local function held()
  storage.razi_spoiler_technologies=storage.razi_spoiler_technologies or {}
  return storage.razi_spoiler_technologies
end
local function owned(technology)
  return technology and type(technology.name)=="string"
    and technology.name:sub(1,5)=="razi-"
    and not (technology.prototype and technology.prototype.hidden)
end
local function ready(technology)
  for _,requirement in pairs(technology.prerequisites or {}) do
    if not requirement.researched then return false end
  end
  return true
end
M.ready=ready
local function restore(technology,managed,name)
  local previous=managed[name]
  if not previous then return end
  if technology and technology.valid~=false then
    -- Only re-enable techs which THIS feature disabled. Never revive a
    -- source technology whose default state is disabled.
    technology.enabled=previous.enabled
    technology.visible_when_disabled=previous.visible
  end
  managed[name]=nil
end
local function apply_one(technology,managed)
  if not owned(technology) then return end
  local name=technology.name
  local tracked=managed[name]
  if technology.researched or ready(technology) then
    if tracked then restore(technology,managed,name) end
    return
  end
  if tracked then return end
  if not technology.enabled then return end
  managed[name]={enabled=true,visible=technology.visible_when_disabled}
  technology.visible_when_disabled=false
  technology.enabled=false
end
function M.sync_force(force)
  if not (force and force.technologies) then return end
  local groups=held()
  local managed=groups[force.index] or {}
  groups[force.index]=managed
  if not M.enabled() then
    for name in pairs(managed) do
      restore(force.technologies[name],managed,name)
    end
    groups[force.index]=nil
    return
  end
  -- First clear stale entries (removed technologies or mod migrations).
  for name in pairs(managed) do
    local tech=force.technologies[name]
    if not tech or tech.researched or ready(tech) then
      restore(tech,managed,name)
    end
  end
  for _,technology in pairs(force.technologies) do
    apply_one(technology,managed)
  end
  if not next(managed) then groups[force.index]=nil end
end
function M.sync_all()
  if not game then return end
  for _,force in pairs(game.forces or {}) do M.sync_force(force) end
end
function M.on_research(event)
  local technology=event and event.research
  local force=technology and technology.force
  if not (force and force.technologies) then return end
  local groups=held()
  local managed=groups[force.index] or {}
  if not M.enabled() then
    if groups[force.index] then M.sync_force(force) end
    return
  end
  groups[force.index]=managed
  apply_one(technology,managed)
  -- A newly completed source research can open a Razi technology even
  -- though the source mod itself is otherwise completely untouched.
  for _,successor in pairs(technology.successors or {}) do
    apply_one(successor,managed)
  end
  if not next(managed) then groups[force.index]=nil end
end
function M.on_forces_merged(event)
  local source=event and event.source_index
  local destination=event and (event.destination or
    (game and game.forces and game.forces[event.destination_index]))
  if not destination then return end
  local groups=held()
  local previous=source and groups[source]
  local combined=groups[destination.index] or {}
  -- Preserve any old saved visibility values without replaying settings.
  for name,entry in pairs(previous or {}) do
    if not combined[name] then combined[name]=entry end
  end
  if source then groups[source]=nil end
  if next(combined) then groups[destination.index]=combined end
  M.sync_force(destination)
end
return M
