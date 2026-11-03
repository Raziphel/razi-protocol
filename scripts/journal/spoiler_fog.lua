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
local RUBIA_PLACEHOLDER="rubia-unknown-technology-"
local function is_rubia_placeholder(technology)
  return technology and type(technology.name)=="string"
    and technology.name:sub(1,#RUBIA_PLACEHOLDER)==RUBIA_PLACEHOLDER
end
M.is_rubia_placeholder=is_rubia_placeholder
local function rubia_source(technology)
  if not is_rubia_placeholder(technology) then return nil end
  local name=technology.name:sub(#RUBIA_PLACEHOLDER+1)
  return technology.force and technology.force.technologies
    and technology.force.technologies[name]
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
    local original=rubia_source(technology)
    -- Rubia owns each placeholder's researched/available state. If its
    -- corresponding real tech is now available, do not revive an obsolete
    -- ? marker while restoring Razi's own earlier visibility change.
    local rubia_revealed=original and
      (original.researched or original.enabled)
    if rubia_revealed then
      technology.enabled=false
    elseif previous.enabled==true and technology.enabled==false then
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
  local placeholder=is_rubia_placeholder(technology)
  local source=placeholder and rubia_source(technology)
  -- Rubia's ? placeholders deliberately have no real prerequisites.
  -- Their underlying original technology determines whether the disguise
  -- is obsolete. Treat them as display-only while hiding spoilers.
  if technology.researched or (placeholder and source and
    (source.researched or source.enabled)) or
    (not placeholder and ready(technology)) then
    if tracked then restore(technology,managed,name) end
    return
  end
  if tracked then
    if placeholder then
      -- Rubia enables its own ? markers after a research or migration
      -- synchronization. Re-hide ONLY this presentation placeholder.
      technology.visible_when_disabled=false
      technology.enabled=false
    elseif technology.enabled then
      -- Other mods' explicit enablement wins for non-Rubia technologies.
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
    local placeholder=tech and is_rubia_placeholder(tech)
    local source=placeholder and rubia_source(tech)
    local obsolete=source and (source.researched or source.enabled)
    if not main or (scope=="external" and not other) or
       not tech or tech.researched or obsolete or
       (not placeholder and ready(tech)) then
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

-- Rubia performs its own delayed synchronization after world/research
-- changes. Use the Journal's existing 30-tick callback to reassert only
-- Rubia's non-researchable ? markers, once per relevant event, after Rubia
-- has finished. No permanent technology polling.
function M.defer(force)
  if not (force and force.index and M.external_enabled()) then return end
  local pending=storage.razi_rubia_spoiler_pending or {}
  pending[force.index]=(game and game.tick or 0)+2
  storage.razi_rubia_spoiler_pending=pending
end
function M.defer_all()
  if not (game and M.external_enabled()) then return end
  for _,force in pairs(game.forces or {}) do M.defer(force) end
end
function M.flush()
  local pending=storage.razi_rubia_spoiler_pending
  if not pending then return end
  local tick=game and game.tick or 0
  for index,due in pairs(pending) do
    if tick>=due then
      local force=game and game.forces and game.forces[index]
      if force and M.external_enabled() then
        local groups=held()
        local managed=groups[index] or {}
        groups[index]=managed
        for _,tech in pairs(force.technologies or {}) do
          if is_rubia_placeholder(tech) then apply_one(tech,managed) end
        end
        if not next(managed) then groups[index]=nil end
      end
      pending[index]=nil
    end
  end
  if not next(pending) then storage.razi_rubia_spoiler_pending=nil end
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
  M.defer(force)
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
  if source and storage.razi_rubia_spoiler_pending then
    storage.razi_rubia_spoiler_pending[source]=nil
  end
  M.sync_force(destination)
  M.defer(destination)
end
return M
