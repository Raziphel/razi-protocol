-- The Freight Desk shows a player's manual list against the current open
-- corridors and inventory. It never changes game cargo or reserves stock.
local style=require("scripts.journal.project_style")
local orders=require("scripts.cargo.orders")
local L=style.L
local HUES=style.HUES
local M={}

local function line(parent,caption,width,color,font)
  local label=parent.add{type="label",caption=caption}
  label.style.single_line=false
  label.style.maximal_width=math.max(110,width)
  if color then label.style.font_color=color end
  if font then label.style.font=font end
  return label
end

local function world_name(world) return {"space-location-name."..world} end

local function current_route(routes,id)
  for index,route in ipairs(routes) do
    if route.id==id then return index end
  end
  return 0
end

local function render_form(parent,player,width,snapshot,routes)
  local saved=orders.store(player.index)
  local draft=saved.draft
  local route_items={}
  for _,route in ipairs(routes) do
    route_items[#route_items+1]=L("cargo-route-choice",
      world_name(route.source),world_name(route.target))
  end
  local picker=parent.add{type="drop-down",name="razi_cargo_route_picker",
    items=route_items,selected_index=current_route(routes,draft.route),
    tags={razi_journal_action="cargo-route"}}
  picker.style.width=math.max(125,width-24)
  local editor=parent.add{type="flow",direction="horizontal"}
  editor.style.vertical_align="center"
  editor.style.horizontal_spacing=7
  local selected_item=draft.item and prototypes.item[draft.item]
    and draft.item or nil
  editor.add{type="choose-elem-button",name="razi_cargo_item",
    elem_type="item",elem_value=selected_item,
    tags={razi_journal_action="cargo-item"}}
  local count=editor.add{type="textfield",name="razi_cargo_count",
    text=draft.count and tostring(draft.count) or "",
    numeric=true,allow_decimal=false,allow_negative=false,
    tags={razi_journal_action="cargo-count"}}
  count.style.width=90
  editor.add{type="button",name="razi_cargo_add",
    caption=L("cargo-add"),enabled=orders.can_add(player,snapshot),
    tags={razi_journal_action="cargo-add"}}
end

local function state_label(entry)
  if entry.load_state=="packed" then return L("cargo-state-packed") end
  if entry.load_state=="ready" then return L("cargo-state-ready") end
  if entry.load_state=="short" then
    return L("cargo-state-short",tostring(entry.shortfall))
  end
  return L("cargo-state-remote")
end

local function render_order(parent,entry,width)
  local row=parent.add{type="flow",name="razi_cargo_order_"..entry.id,
    direction="vertical"}
  row.style.vertical_spacing=3
  local summary=row.add{type="flow",direction="horizontal"}
  summary.style.vertical_align="center"
  summary.style.horizontal_spacing=5
  summary.add{type="sprite-button",sprite="item/"..entry.item,
    style="slot_button",tooltip=prototypes.item[entry.item].localised_name}
  local details=line(summary,L("cargo-order-details",tostring(entry.count),
    tostring(entry.stacks),world_name(entry.route.source),
    world_name(entry.route.target)),math.max(110,width-58))
  details.style.font_color=HUES.ink
  local state=line(row,state_label(entry),width-16)
  state.style.font_color=(entry.load_state=="ready"
    or entry.load_state=="packed") and HUES.green or HUES.quiet
  local actions=row.add{type="flow",direction="horizontal"}
  actions.style.horizontal_spacing=5
  actions.add{type="button",style="tool_button",caption="↑",
    tooltip=L("cargo-move-up"),
    tags={razi_journal_action="cargo-order",id=entry.id,command="up"}}
  actions.add{type="button",style="tool_button",caption="↓",
    tooltip=L("cargo-move-down"),
    tags={razi_journal_action="cargo-order",id=entry.id,command="down"}}
  actions.add{type="button",caption=L(entry.packed
      and "cargo-unpack" or "cargo-packed"),
    tags={razi_journal_action="cargo-order",id=entry.id,command="packed"}}
  actions.add{type="button",style="tool_button",caption="×",
    tooltip=L("cargo-remove"),
    tags={razi_journal_action="cargo-order",id=entry.id,command="remove"}}
end

function M.render(parent,player,width,snapshot)
  line(parent,L("cargo-desk-guide"),width,HUES.quiet)
  local routes=orders.routes(snapshot,player.force)
  local listed=orders.orders(player,snapshot)
  orders.readiness(player,listed)
  if #routes>0 then
    render_form(parent,player,width,snapshot,routes)
  else
    local key=not snapshot.installed and "cargo-corridors-absent"
      or not snapshot.enabled and "cargo-corridors-off"
      or "cargo-no-open-routes"
    line(parent,L(key),width)
  end

  local hidden=orders.unavailable(player,snapshot)
  if #hidden>0 then
    local row=parent.add{type="flow",direction="horizontal"}
    row.style.vertical_align="center"
    row.style.horizontal_spacing=8
    line(row,L("cargo-hidden-count",tostring(#hidden)),
      math.max(110,width-160),HUES.quiet)
    row.add{type="button",caption=L("cargo-drop-hidden"),
      tags={razi_journal_action="cargo-drop-hidden"}}
  elseif #listed==0 then
    line(parent,L("cargo-list-empty"),width,HUES.quiet)
  end

  for _,entry in ipairs(listed) do
    render_order(parent,entry,width)
  end

  local count,stacks=orders.summary(player)
  line(parent,L("cargo-list-summary",tostring(count),tostring(stacks)),
    width,HUES.quiet)
  if count>0 then
    parent.add{type="button",caption=L("cargo-clear"),
      tags={razi_journal_action="cargo-clear"}}
  end
end

return M
