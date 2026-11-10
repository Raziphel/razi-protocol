-- Freight Desk input. Every action is accepted only while Cargo is the open
-- Journal project, and every route is checked against the current snapshot.
local pref=require("scripts.journal.preferences")
local orders=require("scripts.cargo.orders")
local catapult_network=require("scripts.compatibility.orbital-cannon.catapult_network")
local FRAME=require("scripts.journal.widgets").FRAME
local L=function(key) return {"journal-ui."..key} end
local M={}
local ORDER_ACTIONS={remove=true,packed=true,up=true,down=true}

local function starts(value,prefix)
  return type(value)=="string" and value:sub(1,#prefix)==prefix
end

function M.owns(element)
  if not (element and element.valid) then return false end
  local tags=element.tags or {}
  return starts(tags.razi_journal_action,"cargo-")
    or starts(element.name,"cargo-")
end

local function active(player)
  if not (player and player.valid) then return false end
  local frame=player.gui.screen[FRAME]
  if not (frame and frame.valid) then return false end
  local state=pref(player.index)
  return state.view=="projects" and state.project=="cargo",state
end

local function snapshot(player)
  return catapult_network.snapshot(player.force)
end

function M.click(player,element)
  local open,state=active(player)
  if not open then return false end
  local tags=element.tags or {}
  local action=tags.razi_journal_action
  if action=="cargo-tab" then
    if element.type~="label" and element.type~="button" then return false end
    if tags.tab~="overview" and tags.tab~="freight" then return false end
    state.cargo_tab=tags.tab
    return true
  elseif action=="cargo-route" and element.type=="button" then
    if type(tags.id)~="string" or tags.tab~="freight" then return false end
    local report=snapshot(player)
    if not orders.select(player,report,tags.id) then
      player.print(L("cargo-route-unavailable"))
      return true
    end
    state.cargo_tab="freight"
    return true
  elseif action=="cargo-add" then
    if element.type~="button" then return false end
    local report=snapshot(player)
    local added,reason=orders.add(player,report)
    if not added and reason=="full" then
      player.print(L("cargo-list-full"))
    elseif not added and reason=="route" then
      player.print(L("cargo-route-unavailable"))
    end
    return true
  elseif action=="cargo-order" then
    if element.type~="button" or type(tags.id)~="number"
      or math.floor(tags.id)~=tags.id or not ORDER_ACTIONS[tags.command] then
      return false
    end
    local report=snapshot(player)
    local visible=false
    for _,entry in ipairs(orders.orders(player,report)) do
      if entry.id==tags.id then visible=true;break end
    end
    if not visible then return false end
    return orders.update(player,tags.id,tags.command)
  elseif action=="cargo-clear" then
    if element.type~="button" then return false end
    orders.clear(player)
    return true
  elseif action=="cargo-drop-hidden" then
    if element.type~="button" then return false end
    orders.drop_unavailable(player,snapshot(player))
    return true
  end
  return false
end

function M.text_changed(player,element)
  local open=active(player)
  if not open or element.type~="textfield"
    or element.name~="razi_cargo_count"
    or (element.tags or {}).razi_journal_action~="cargo-count"
    or type(element.text)~="string" then
    return false
  end
  orders.count_changed(player,element.text)
  local add=element.parent and element.parent["razi_cargo_add"]
  if add and add.valid then
    add.enabled=orders.can_add(player,snapshot(player))
  end
  return true
end

function M.selection_changed(player,element)
  local open=active(player)
  if not open or (element.tags or {}).razi_journal_action~="cargo-route"
    or element.type~="drop-down"
    or element.name~="razi_cargo_route_picker" then
    return false
  end
  local report=snapshot(player)
  local routes=orders.routes(report,player.force)
  local index=element.selected_index
  if type(index)~="number" or math.floor(index)~=index
    or index<0 or index>#routes then
    return false
  end
  local id=index==0 and nil or routes[index].id
  return orders.select(player,report,id)
end

function M.elem_changed(player,element)
  local open=active(player)
  if not open or (element.tags or {}).razi_journal_action~="cargo-item"
    or element.type~="choose-elem-button"
    or element.name~="razi_cargo_item" then
    return false
  end
  return orders.item_changed(player,element.elem_value)
end

return M
