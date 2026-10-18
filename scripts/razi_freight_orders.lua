-- Player-owned, manual freight packing board for source Orbital Catapult.
-- This does NOT read real shipments, launch machines or inventory contents.
-- All saved values are plain serializable primitives. No per-tick loops.
local M={}
local network=require("scripts.razi_catapult_network")
local manifest=require("prototypes.compat.orbital_catapult")
local LIMIT=20
local MAX_ITEMS=1000000
local function store(index)
  storage.razi_freight_orders=storage.razi_freight_orders or {}
  local s=storage.razi_freight_orders[index]
  if not s then
    s={draft={route=nil,item=nil,count=100},orders={},next_id=1}
    storage.razi_freight_orders[index]=s
  end
  s.draft=s.draft or {count=100}
  s.orders=s.orders or {}
  s.next_id=s.next_id or 1
  return s
end
M.store=store
function M.cleanup(index)
  if storage.razi_freight_orders then
    storage.razi_freight_orders[index]=nil
  end
end
local function tech_ready(force,world)
  if not (force and force.technologies) then return false end
  local tech=force.technologies["planet-discovery-"..world]
  return tech and tech.researched==true or false
end
function M.route(force,id)
  if type(id)~="string" then return nil end
  local report=network.snapshot(force,{hide=false})
  if not report.installed or not report.enabled then return nil end
  for _,spec in ipairs(manifest.active_links(
    report.local_enabled,report.regional_enabled)) do
    if spec[1]==id then
      if not (tech_ready(force,spec[2]) and
        tech_ready(force,spec[3])) then return nil end
      for _,entry in ipairs(report.entries) do
        if (entry.source==spec[2] and entry.target==spec[3])
          or (entry.source==spec[3] and entry.target==spec[2]) then
          return {id=id,source=spec[2],target=spec[3]}
        end
      end
    end
  end
  return nil
end
local function item(name)
  return type(name)=="string" and prototypes and
    prototypes.item and prototypes.item[name] or nil
end
local function positive_count(value)
  local n=tonumber(value)
  if not (n and n==n and n>=1 and n<=MAX_ITEMS
    and math.floor(n)==n) then return nil end
  return n
end
M.positive_count=positive_count
function M.select(player,id)
  if not M.route(player.force,id) then return false end
  store(player.index).draft.route=id
  return true
end
function M.item_changed(player,name)
  local draft=store(player.index).draft
  if name~=nil and not item(name) then return false end
  draft.item=name
  return true
end
function M.count_changed(player,value)
  local count=positive_count(value)
  -- Invalidate a stale draft rather than silently using the previous
  -- value when the currently typed quantity is zero or malformed.
  store(player.index).draft.count=count
  return count~=nil
end
function M.add(player)
  local s=store(player.index)
  local d=s.draft
  local route=M.route(player.force,d.route)
  local proto=item(d.item)
  local count=positive_count(d.count)
  if not (route and proto and count and #s.orders<LIMIT) then
    return false
  end
  s.orders[#s.orders+1]={
    id=s.next_id,route=route.id,item=d.item,count=count,
    packed=false
  }
  s.next_id=s.next_id+1
  return true
end
function M.update(player,id,action)
  local s=store(player.index)
  if type(id)~="number" then return false end
  for i,order in ipairs(s.orders) do
    if order.id==id then
      if action=="remove" then table.remove(s.orders,i)
      elseif action=="packed" then order.packed=not order.packed
      else return false end
      return true
    end
  end
  return false
end
function M.clear(player)
  local s=store(player.index)
  s.orders={}
end
function M.saved_count(player)
  return #store(player.index).orders
end
function M.stacks(name,count)
  local proto=item(name)
  local size=proto and proto.stack_size
  if not (size and size>0 and positive_count(count)) then
    return nil
  end
  return math.ceil(count/size)
end
function M.orders(player)
  local s=store(player.index)
  local result={}
  for _,order in ipairs(s.orders) do
    local route=M.route(player.force,order.route)
    local proto=item(order.item)
    if route and proto then
      result[#result+1]={
        id=order.id,route=route,item=order.item,
        count=order.count,packed=order.packed,
        stacks=M.stacks(order.item,order.count)
      }
    end
  end
  return result
end
return M
