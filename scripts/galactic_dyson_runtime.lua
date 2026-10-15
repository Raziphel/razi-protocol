-- Source-safe Stellar Works telemetry for Factorio 2.1.
-- No private SLP storage, satellite counter guesses or force-wide scans
-- on game ticks. Only registered placeable receiver entity prototypes
-- are counted through Factorio's native count_entities_filtered API.
local M={}
M.receiver_items={
  "ds-energy-loader-mk1",
  "ds-energy-loader-mk2",
  "ds-energy-loader-mk3",
  "ds-energy-loader"
}
M.cache_ticks=600

-- Validated data fields are deliberately nil until SLP exposes a
-- documented read-only API. Nil is NOT zero satellites or zero MW.
function M.resolve_receiver_names(registry)
  local candidates,found={},{}
  local items=registry and registry.item or {}
  local entities=registry and registry.entity or {}
  for _,item_name in ipairs(M.receiver_items) do
    local prototype=items[item_name]
    local placed=prototype and prototype.place_result
    local name=placed and placed.name
    if not name and entities[item_name] then name=item_name end
    if name and not found[name] then
      found[name]=true
      candidates[#candidates+1]=name
    end
  end
  table.sort(candidates)
  return candidates
end
local function empty()
  return {
    receivers=nil, sites={}, named_receivers={}, satellite_count=nil,
    repeater_satellites=nil, allocated_mw=nil, physical_available=false
  }
end
function M.inspect(force,worlds,registry)
  local result=empty()
  if not force then return result end
  local names=M.resolve_receiver_names(registry)
  if #names==0 then return result end
  result.physical_available=true
  result.named_receivers=names
  result.receivers=0
  -- LuaForce::get_entity_count is O(1) and avoids enumerating entities.
  for _,name in ipairs(names) do
    result.receivers=result.receivers+force.get_entity_count(name)
  end
  -- Most forces have no stellar receivers yet. A zero count is definitive;
  -- do not traverse every surface to confirm what the native force index
  -- already knows.
  if result.receivers==0 then return result end
  -- Surface breakdown is only sampled when a player opens/refreshes
  -- Stellar Works. Never scan on a periodic game tick.
  for _,surface in pairs(worlds or {}) do
    if surface.valid~=false then
      local count=surface.count_entities_filtered{
        name=names,force=force
      }
      if count>0 then
        local label=surface.platform and surface.platform.name
          or surface.name
        result.sites[#result.sites+1]={
          name=label,count=count,platform=surface.platform~=nil
        }
      end
    end
  end
  table.sort(result.sites,function(a,b)
    if a.count~=b.count then return a.count>b.count end
    return a.name<b.name
  end)
  return result
end

-- Store only primitive, serializable snapshots, never LuaForce/LuaSurface
-- objects. Cache expires on UI access after ten seconds (at 60 ticks/s).
function M.snapshot(force,refresh)
  if not force then return empty() end
  local registry=prototypes
  local surfaces=game and game.surfaces
  local tick=game and game.tick or 0
  if not (registry and surfaces) then return empty() end
  local container=storage
  local cache
  if container then
    container.razi_dyson_status=container.razi_dyson_status or {}
    cache=container.razi_dyson_status
  end
  local key=force.index or force.name or 0
  local prev=cache and cache[key]
  if not refresh and prev and tick>=prev.tick
    and tick-prev.tick<M.cache_ticks then return prev.status end
  local status=M.inspect(force,surfaces,registry)
  if cache then cache[key]={tick=tick,status=status} end
  return status
end
function M.invalidate(force)
  if storage and storage.razi_dyson_status and force then
    storage.razi_dyson_status[force.index or force.name or 0]=nil
  end
end
return M
