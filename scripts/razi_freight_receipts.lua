-- A.3: real Factorio cargo-pod DELIVERY EVENT evidence, NOT catapult telemetry.
-- on_cargo_pod_delivered_cargo does not identify the sending planet, the
-- transport mod, any freight plan, or the quantities actually deposited.
-- Only plain values are saved and only configured regional endpoints count.
local M={}
local routes=require("prototypes.compat.orbital_catapult")
local MAX_RECENT=24
local endpoint={}
for _,link in ipairs(routes.active_links(true,true)) do
  endpoint[link[2]]=true
  endpoint[link[3]]=true
end

local function records()
  storage.razi_pod_receipts=storage.razi_pod_receipts or {}
  return storage.razi_pod_receipts
end

-- Called only by Factorio's on_cargo_pod_delivered_cargo event, after the
-- engine says cargo was delivered. A surface without a planet is ignored.
function M.on_delivered(event)
  local pod=event and event.cargo_pod
  if not (pod and pod.valid and pod.force and pod.force.valid) then
    return false
  end
  local surface=pod.surface
  local planet=surface and surface.planet
  local world=planet and planet.name
  if not (world and endpoint[world]) then return false end
  local force_index=pod.force.index
  local tick=event.tick
  if type(force_index)~="number" or type(tick)~="number" then
    return false
  end
  local all=records()
  local record=all[force_index]
  if not record then
    record={worlds={},recent={}}
    all[force_index]=record
  end
  local worlds=record.worlds
  worlds[world]=(worlds[world] or 0)+1
  local recent=record.recent
  -- The engine emits this once for a completed delivery, not when landing
  -- starts. The recent ring is not a source/destination shipment ledger.
  table.insert(recent,1,{world=world,tick=tick})
  if #recent>MAX_RECENT then table.remove(recent) end
  return true
end

-- Avoid leaking undiscovered endpoints, including when Hide Spoilers is
-- toggled OFF. Research is the authority for this operational evidence.
function M.snapshot(force,network)
  local result={worlds={},recent={},total=0}
  if not (force and force.index and network and network.installed
    and network.enabled) then return result end
  local allowed={}
  for _,lane in ipairs(network.entries or {}) do
    if lane.state=="researched" and lane.source_researched
      and lane.target_researched then
      allowed[lane.source]=true
      allowed[lane.target]=true
    end
  end
  local all=storage.razi_pod_receipts
  local record=all and all[force.index]
  if not record then return result end
  for world in pairs(allowed) do
    local count=record.worlds and record.worlds[world] or 0
    result.worlds[world]=count
    result.total=result.total+count
  end
  for _,item in ipairs(record.recent or {}) do
    if allowed[item.world] then
      result.recent[#result.recent+1]={world=item.world,tick=item.tick}
      if #result.recent>=8 then break end
    end
  end
  return result
end

function M.forces_merged(event)
  local source=event and event.source_index
  local dest=event and event.destination and event.destination.index
  local all=storage.razi_pod_receipts
  if not (all and source and dest and source~=dest and all[source]) then
    return
  end
  local old=all[source]
  local target=all[dest]
  if not target then
    all[dest]=old
    all[source]=nil
    return
  end
  target.worlds=target.worlds or {}
  for world,count in pairs(old.worlds or {}) do
    target.worlds[world]=(target.worlds[world] or 0)+count
  end
  local recent={}
  for _,entry in ipairs(target.recent or {}) do
    recent[#recent+1]=entry
  end
  for _,entry in ipairs(old.recent or {}) do
    recent[#recent+1]=entry
  end
  table.sort(recent,function(a,b)return a.tick>b.tick end)
  while #recent>MAX_RECENT do table.remove(recent) end
  target.recent=recent
  all[source]=nil
end
return M
