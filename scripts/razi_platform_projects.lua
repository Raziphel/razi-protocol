-- Real force-owned space-platform milestones for the Expedition Journal.
-- A pending platform without its hub is NOT a completed build. The engine
-- owns platform and trip counts; storage only remembers attained milestones
-- if an old platform is later destroyed or a multiplayer force merges.
local M={}
local function record(force)
  if not (storage and force and force.index) then return nil end
  storage.razi_project_milestones=storage.razi_project_milestones or {}
  local by_force=storage.razi_project_milestones
  local value=by_force[force.index]
  if not value then
    value={platform=false,voyage=false}
    by_force[force.index]=value
  end
  return value
end
local function real_hub(platform)
  if not (platform and platform.valid) then return false end
  if platform.scheduled_for_deletion and
    platform.scheduled_for_deletion>0 then return false end
  local hub=platform.hub
  return hub~=nil and hub.valid==true
end
local function remember(force,platform,voyage,name)
  local saved=record(force)
  if not saved then return false end
  local changed=false
  if platform and not saved.platform then
    saved.platform=true
    saved.first_name=name
    changed=true
  end
  if voyage and not saved.voyage then
    saved.platform=true
    saved.voyage=true
    saved.voyage_name=name
    changed=true
  end
  return changed
end
function M.observe(platform)
  if not real_hub(platform) then return false end
  local voyage=type(platform.completed_trips)=="number"
    and platform.completed_trips>0
  return remember(platform.force,true,voyage,platform.name)
end
function M.snapshot(force)
  local saved=storage and storage.razi_project_milestones
    and force and storage.razi_project_milestones[force.index]
  local platform=saved and saved.platform==true or false
  local voyage=saved and saved.voyage==true or false
  local first=saved and saved.first_name or nil
  local ship=saved and saved.voyage_name or nil
  -- Only consult live platforms while at least one achievement is unknown.
  -- This is called from GUI snapshots/init, never every tick.
  if force and (not platform or not voyage) then
    for _,craft in pairs(force.platforms or {}) do
      if real_hub(craft) then
        if not platform then
          platform=true
          first=craft.name
        end
        if type(craft.completed_trips)=="number"
          and craft.completed_trips>0 then
          voyage=true
          ship=craft.name
        end
        if platform and voyage then break end
      end
    end
    if platform then remember(force,true,voyage,first or ship) end
  end
  return {platform=platform,voyage=voyage,
    first_name=first,voyage_name=ship}
end
function M.forces_merged(event)
  local table_by_force=storage and storage.razi_project_milestones
  if not table_by_force or not event then return end
  local source=table_by_force[event.source_index]
  if not source then return end
  local target_force=event.destination
  local dest_index=target_force and target_force.index
    or event.destination_index
  if not dest_index then return end
  local target=table_by_force[dest_index] or {}
  target.platform=target.platform or source.platform
  target.voyage=target.voyage or source.voyage
  target.first_name=target.first_name or source.first_name
  target.voyage_name=target.voyage_name or source.voyage_name
  table_by_force[dest_index]=target
  table_by_force[event.source_index]=nil
end
return M
