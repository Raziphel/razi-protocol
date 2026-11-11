-- Player-owned freight notes for the Cargo Network. They never move or
-- reserve items, inspect shipments or run outside an explicit Journal action.
local M={}
local catapult_network=require("scripts.compatibility.orbital-cannon.catapult_network")
local LIMIT=20
local MAX_COUNT=1000000

local function store(index)
  storage.razi_cargo_orders=storage.razi_cargo_orders or {}
  local saved=storage.razi_cargo_orders[index]
  if not saved then
    saved={draft={route=nil,item=nil,count=100},orders={},next_id=1}
    storage.razi_cargo_orders[index]=saved
  end
  saved.draft=saved.draft or {route=nil,item=nil,count=100}
  saved.orders=type(saved.orders)=="table" and saved.orders or {}
  if type(saved.next_id)~="number" or saved.next_id<1
    or math.floor(saved.next_id)~=saved.next_id then
    saved.next_id=1
  end
  return saved
end
M.store=store

function M.cleanup(index)
  if storage.razi_cargo_orders then
    storage.razi_cargo_orders[index]=nil
  end
end

local function item_prototype(name)
  return type(name)=="string" and prototypes and prototypes.item
    and prototypes.item[name] or nil
end

local function positive_count(value)
  local count=tonumber(value)
  if not (count and count==count and count>=1 and count<=MAX_COUNT
    and math.floor(count)==count) then
    return nil
  end
  return count
end
M.positive_count=positive_count

function M.route_id(entry,source)
  if not entry or (source~=entry.source and source~=entry.target) then
    return nil
  end
  local target=source==entry.source and entry.target or entry.source
  if type(source)~="string" or type(target)~="string" then return nil end
  return source..">"..target
end

function M.route(snapshot,force,id)
  if type(id)~="string" or not (snapshot and snapshot.installed
    and snapshot.enabled) then
    return nil
  end
  for _,entry in ipairs(snapshot.entries or {}) do
    if entry.state=="researched"
      and catapult_network.researched(force,entry.source)
      and catapult_network.researched(force,entry.target) then
      for _,source in ipairs({entry.source,entry.target}) do
        local route_id=M.route_id(entry,source)
        if route_id==id then
          return {
            id=route_id,corridor=entry.id,source=source,
            target=source==entry.source and entry.target or entry.source
          }
        end
      end
    end
  end
  return nil
end

function M.routes(snapshot,force)
  local result={}
  if not (snapshot and snapshot.installed and snapshot.enabled) then
    return result
  end
  for _,entry in ipairs(snapshot.entries or {}) do
    if entry.state=="researched" then
      for _,source in ipairs({entry.source,entry.target}) do
        local id=M.route_id(entry,source)
        local route=id and M.route(snapshot,force,id)
        if route then result[#result+1]=route end
      end
    end
  end
  return result
end

function M.select(player,snapshot,id)
  if not (player and player.index and player.force) then return false end
  if id~=nil and not M.route(snapshot,player.force,id) then return false end
  store(player.index).draft.route=id
  return true
end

function M.item_changed(player,name)
  if not (player and player.index) then return false end
  if name~=nil and not item_prototype(name) then return false end
  store(player.index).draft.item=name
  return true
end

function M.count_changed(player,value)
  if not (player and player.index) then return false end
  local count=positive_count(value)
  store(player.index).draft.count=count
  return count~=nil
end

function M.can_add(player,snapshot)
  if not (player and player.index and player.force) then return false end
  local saved=store(player.index)
  local draft=saved.draft
  return #saved.orders<LIMIT
    and M.route(snapshot,player.force,draft.route)~=nil
    and item_prototype(draft.item)~=nil
    and positive_count(draft.count)~=nil
end

function M.add(player,snapshot)
  if not (player and player.index and player.force) then return false end
  local saved=store(player.index)
  if #saved.orders>=LIMIT then return false,"full" end
  local draft=saved.draft
  local route=M.route(snapshot,player.force,draft.route)
  if not route then return false,"route" end
  if not item_prototype(draft.item) then return false,"item" end
  local count=positive_count(draft.count)
  if not count then return false,"count" end
  saved.orders[#saved.orders+1]={
    id=saved.next_id,route=route.id,item=draft.item,count=count,packed=false
  }
  saved.next_id=saved.next_id+1
  return true
end

function M.update(player,id,action)
  if not (player and player.index) or type(id)~="number" then
    return false
  end
  local saved=store(player.index)
  for index,order in ipairs(saved.orders) do
    if order.id==id then
      if action=="remove" then
        table.remove(saved.orders,index)
      elseif action=="packed" then
        order.packed=not order.packed
      elseif action=="up" and index>1 then
        saved.orders[index],saved.orders[index-1]=
          saved.orders[index-1],saved.orders[index]
      elseif action=="down" and index<#saved.orders then
        saved.orders[index],saved.orders[index+1]=
          saved.orders[index+1],saved.orders[index]
      else
        return false
      end
      return true
    end
  end
  return false
end

function M.clear(player)
  if not (player and player.index) then return end
  store(player.index).orders={}
end

function M.saved_count(player)
  if not (player and player.index) then return 0 end
  return #store(player.index).orders
end

function M.stacks(name,count)
  local prototype=item_prototype(name)
  local size=prototype and prototype.stack_size
  if not (size and size>0 and positive_count(count)) then return nil end
  return math.ceil(count/size)
end

function M.summary(player)
  local saved=store(player.index)
  local stacks=0
  for _,order in ipairs(saved.orders) do
    stacks=stacks+(M.stacks(order.item,order.count) or 0)
  end
  return #saved.orders,stacks
end

function M.orders(player,snapshot)
  local result={}
  if not (player and player.index and player.force) then return result end
  for _,order in ipairs(store(player.index).orders) do
    local route=M.route(snapshot,player.force,order.route)
    local prototype=item_prototype(order.item)
    local count=positive_count(order.count)
    if route and prototype and count then
      result[#result+1]={
        id=order.id,route=route,item=order.item,count=count,
        packed=order.packed==true,
        stacks=M.stacks(order.item,count)
      }
    end
  end
  return result
end

-- Inventory is counted once across rows in their saved order. A manual
-- packed marker changes the displayed state but reserves no inventory.
function M.readiness(player,listed)
  local planet=player and player.physical_surface
    and player.physical_surface.planet
  local current=planet and planet.name or nil
  local remaining={}
  local report={ready=0,short=0,remote=0,packed=0,planned_stacks=0,
    origin=current}
  for _,entry in ipairs(listed or {}) do
    report.planned_stacks=report.planned_stacks+(entry.stacks or 0)
    entry.origin_here=current~=nil and current==entry.route.source
    if entry.packed then
      entry.load_state="packed"
      report.packed=report.packed+1
    elseif not entry.origin_here then
      entry.load_state="remote"
      report.remote=report.remote+1
    else
      local stock=remaining[entry.item]
      if stock==nil then
        stock=player and player.get_item_count
          and math.max(0,player.get_item_count(entry.item) or 0) or 0
      end
      local available=math.min(stock,entry.count)
      entry.shortfall=entry.count-available
      remaining[entry.item]=math.max(0,stock-entry.count)
      if entry.shortfall==0 then
        entry.load_state="ready"
        report.ready=report.ready+1
      else
        entry.load_state="short"
        report.short=report.short+1
      end
    end
  end
  return report
end

-- Keep inaccessible plans opaque: only their numeric row IDs leave this module.
function M.unavailable(player,snapshot)
  local result={}
  if not (player and player.index and player.force) then return result end
  for _,order in ipairs(store(player.index).orders) do
    if not M.route(snapshot,player.force,order.route)
      or not item_prototype(order.item) then
      result[#result+1]=order.id
    end
  end
  return result
end

function M.drop_unavailable(player,snapshot)
  if not (player and player.index and player.force) then return 0 end
  local hidden={}
  for _,id in ipairs(M.unavailable(player,snapshot)) do hidden[id]=true end
  local saved=store(player.index)
  local kept,removed={},0
  for _,order in ipairs(saved.orders) do
    if hidden[order.id] then
      removed=removed+1
    else
      kept[#kept+1]=order
    end
  end
  saved.orders=kept
  return removed
end

return M
