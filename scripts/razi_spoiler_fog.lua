-- Optional spoiler fog, reversible and scoped to genuinely future research.
-- The general switch controls Razi technologies and the Journal.
-- The companion switch extends fog to other mods' future research.
-- Never change a technology that is already researched or whose real
-- prerequisites are complete. Never scan every tick.
local M={}
M.setting="razi-hide-spoilers"
M.external_setting="razi-hide-other-tech-spoilers"

local function value(name)
  local option=settings and settings.global and settings.global[name]
  return option and option.value==true or false
end
function M.enabled() return value(M.setting) end
function M.external_enabled()
  return M.enabled() and value(M.external_setting)
end

local function held()
  storage.razi_spoiler_technologies=
    storage.razi_spoiler_technologies or {}
  return storage.razi_spoiler_technologies
end
local function belongs_to_razi(technology)
  return type(technology.name)=="string"
    and technology.name:sub(1,5)=="razi-"
end
local function covered(technology)
  return technology and technology.valid~=false
    and not (technology.prototype and technology.prototype.hidden)
    and (belongs_to_razi(technology) or M.external_enabled())
end
local function ready(technology)
  for _,prerequisite in pairs(technology.prerequisites or {}) do
    if not prerequisite.researched then return false end
  end
  return true
end
M.ready=ready

local function restore(technology,managed,name)
  local previous=managed[name]
  if not previous then return end
  if technology and technology.valid~=false then
    -- Restore only values previously changed by Razi. Source mods may have
    -- enabled a technology in the meantime, so never set enabled=false here.
    if previous.enabled==true and technology.enabled==false then
      technology.enabled=true
    end
    if type(previous.visible)=="boolean" then
      technology.visible_when_disabled=previous.visible
    end
  end
  managed[name]=nil
end

local function apply_one(technology,managed)
  if not covered(technology) then return end
  local name=technology.name
  local tracked=managed[name]
  if technology.researched or ready(technology) then
    if tracked then restore(technology,managed,name) end
    return
  end
  if tracked then
    -- Explicit enablement from another mod overrides our earlier hide.
    -- This is not a license to force it disabled again.
    if technology.enabled then
      restore(technology,managed,name)
    end
    return
  end
  if not technology.enabled and not technology.visible_when_disabled then
    return
  end
  -- Do not confuse a disabled technology with a normal ready technology.
  -- Even technologies intentionally disabled by a source mod may be shown
  -- as future spoilers; hide their GUI row without changing enabled=false.
  managed[name]={
    enabled=technology.enabled==true,
    visible=technology.visible_when_disabled,
    scope=belongs_to_razi(technology) and "razi" or "external"
  }
  technology.visible_when_disabled=false
  if technology.enabled then technology.enabled=false end
end

function M.sync_force(force)
  if not (force and force.technologies) then return end
  local groups=held()
  local managed=groups[force.index] or {}
  groups[force.index]=managed
  local main=M.enabled()
  local other=M.external_enabled()

  -- Migrate old managed records which predate the external scope flag.
  for name,previous in pairs(managed) do
    local tech=force.technologies[name]
    local scope=previous.scope or
      (name:sub(1,5)=="razi-" and "razi" or "external")
    if not main or (scope=="external" and not other) or
       not tech or tech.researched or ready(tech) then
      restore(tech,managed,name)
    end
  end
  if main then
    for _,technology in pairs(force.technologies) do
      apply_one(technology,managed)
    end
  end
  if not next(managed) then groups[force.index]=nil end
end
function M.sync_all()
  if not game then return end
  for _,force in pairs(game.forces or {}) do M.sync_force(force) end
end

function M.on_research(event)
  local tech=event and event.research
  local force=tech and tech.force
  if not (force and force.technologies) then return end
  local groups=held()
  local managed=groups[force.index] or {}
  groups[force.index]=managed
  if not M.enabled() then
    M.sync_force(force)
    return
  end
  apply_one(tech,managed)
  for _,successor in pairs(tech.successors or {}) do
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
  for name,entry in pairs(previous or {}) do
    if not combined[name] then combined[name]=entry end
  end
  if source then groups[source]=nil end
  if next(combined) then groups[destination.index]=combined end
  M.sync_force(destination)
end
return M
