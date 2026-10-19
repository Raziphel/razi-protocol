-- A.8: provenance-aware NATIVE cargo-pod evidence, not Catapult telemetry.
-- Correlation is accepted ONLY for the same actual Factorio pod unit_number,
-- force and two real planet surfaces. It proves an observed pod departure and
-- delivery, NEVER the contents, the transport mod or a planned freight order.
local M={}
local MAX_PENDING=96
local MAX_RECENT=24
local MAX_AGE=108000 -- 30 game minutes at 60 UPS
local function state()
  storage.razi_native_pod_trips=storage.razi_native_pod_trips or {}
  return storage.razi_native_pod_trips
end
local function identity(event)
  local pod=event and event.cargo_pod
  if not (pod and pod.valid and pod.force and pod.force.valid) then
    return nil
  end
  local force=pod.force.index
  local unit=pod.unit_number
  local tick=event.tick
  if type(force)~="number" or type(unit)~="number"
    or type(tick)~="number" or tick<0 then
    return nil
  end
  return force,unit,tick,pod
end
local function planet(pod)
  local p=pod.surface and pod.surface.planet
  return p and type(p.name)=="string" and p.name or nil
end
local function trim_pending(record,tick)
  local n=0
  for unit,row in pairs(record.pending) do
    if type(row)~="table" or type(row.tick)~="number"
      or row.tick>tick or tick-row.tick>MAX_AGE then
      record.pending[unit]=nil
    else
      n=n+1
    end
  end
  -- Deterministically retain the newest entries if an unusual mod floods
  -- the source event stream; this never invents a transport connection.
  if n>MAX_PENDING then
    local ordered={}
    for unit,row in pairs(record.pending) do
      ordered[#ordered+1]={unit=unit,tick=row.tick}
    end
    table.sort(ordered,function(a,b)
      if a.tick~=b.tick then return a.tick>b.tick end
      return a.unit>b.unit
    end)
    for i=MAX_PENDING+1,#ordered do
      record.pending[ordered[i].unit]=nil
    end
  end
end
local function recorded(record,unit)
  for _,row in ipairs(record.recent) do
    if row.unit==unit then return true end
  end
  return false
end
-- Factorio on_cargo_pod_started_ascending and on_cargo_pod_finished_ascending.
-- Only an actual origin planet is accepted, not an orbital platform surface.
function M.departed(event)
  local force,unit,tick,pod=identity(event)
  if not force then return false end
  local from=planet(pod)
  if not from then return false end
  local all=state()
  local record=all[force] or {pending={},recent={}}
  all[force]=record
  record.pending=record.pending or {}
  record.recent=record.recent or {}
  trim_pending(record,tick)
  if recorded(record,unit) then return false end
  local existing=record.pending[unit]
  -- Preserve the first source origin, never silently rewrite provenance.
  if existing then return existing.from==from end
  record.pending[unit]={from=from,tick=tick}
  trim_pending(record,tick)
  return true
end
-- Called alongside the existing A.3 destination-only pod event ledger.
-- Delivery event is authoritative for delivery time/location; it is NOT
-- authoritative for the contents or the source mod used for travel.
function M.delivered(event)
  local force,unit,tick,pod=identity(event)
  if not force then return false end
  local all=storage.razi_native_pod_trips
  local record=all and all[force]
  if not record then return false end
  record.pending=record.pending or {}
  record.recent=record.recent or {}
  trim_pending(record,tick)
  local from_row=record.pending[unit]
  record.pending[unit]=nil
  if not from_row or recorded(record,unit) then return false end
  local to=planet(pod)
  if not to or from_row.from==to then return false end
  if tick<from_row.tick or tick-from_row.tick>MAX_AGE then return false end
  table.insert(record.recent,1,{
    unit=unit,from=from_row.from,to=to,
    departed=from_row.tick,delivered=tick
  })
  while #record.recent>MAX_RECENT do table.remove(record.recent) end
  return true
end
local function unlocked(force,name)
  if not (force and type(name)=="string") then return false end
  local locations=prototypes and prototypes.space_location or {}
  local planets=game and game.planets or {}
  if not (locations[name] and planets[name]) then return false end
  if force.is_space_location_unlocked then
    return force.is_space_location_unlocked(name)==true
  end
  local t=force.technologies and
    force.technologies["planet-discovery-"..name]
  return t and t.researched==true or false
end
-- Returns actual native observations compatible with the *waypoints* of
-- one validated itinerary. Does not connect an event to that itinerary.
function M.for_legs(force,legs)
  local result={counts={},recent={},total=0}
  if not (force and type(force.index)=="number"
    and type(legs)=="table" and #legs>=1 and #legs<=6) then
    return result
  end
  local all=storage.razi_native_pod_trips
  local record=all and all[force.index]
  if not record then return result end
  local wanted={}
  for i,leg in ipairs(legs) do
    if type(leg)=="table" and unlocked(force,leg.from)
      and unlocked(force,leg.to) then
      wanted[leg.from.."\0"..leg.to]=wanted[leg.from.."\0"..leg.to]
        or {}
      table.insert(wanted[leg.from.."\0"..leg.to],i)
    end
  end
  for _,row in ipairs(record.recent or {}) do
    local hits=wanted[row.from.."\0"..row.to]
    if hits then
      for _,i in ipairs(hits) do
        result.counts[i]=(result.counts[i] or 0)+1
      end
      result.total=result.total+1
      if #result.recent<6 then
        result.recent[#result.recent+1]={
          from=row.from,to=row.to,departed=row.departed,
          delivered=row.delivered
        }
      end
    end
  end
  return result
end
function M.forces_merged(event)
  local src=event and event.source_index
  local dst=event and event.destination and event.destination.index
  local all=storage.razi_native_pod_trips
  if not (all and src and dst and src~=dst and all[src]) then return end
  local source=all[src]
  local target=all[dst] or {pending={},recent={}}
  target.pending=target.pending or {}
  target.recent=target.recent or {}
  local seen={}
  for _,row in ipairs(target.recent) do seen[row.unit]=true end
  -- In-flight evidence cannot safely bridge a force merge; discard it.
  for _,row in ipairs(source.recent or {}) do
    if not seen[row.unit] then
      target.recent[#target.recent+1]=row
      seen[row.unit]=true
    end
  end
  table.sort(target.recent,function(a,b)
    if a.delivered~=b.delivered then return a.delivered>b.delivered end
    return a.unit>b.unit
  end)
  while #target.recent>MAX_RECENT do table.remove(target.recent) end
  all[dst]=target
  all[src]=nil
end
return M
