-- Compact operator UI for manual regional freight plans.
-- Uses source-backed routes and real item stack sizes; NEVER claims
-- catapult launch detection, automatic stock reservation or delivery.
local M={}
local orders=require("scripts.razi_freight_orders")
local infrastructure=require("scripts.razi_freight_infrastructure")
local function L(key,...) return {"razi-ops."..key,...} end
local function line(parent,caption,width)
  local label=parent.add{type="label",caption=caption}
  label.style.single_line=false
  label.style.maximal_width=math.max(width,120)
  return label
end
local function name(world)
  local proto=prototypes and prototypes.space_location
    and prototypes.space_location[world]
  return proto and proto.localised_name or world
end
-- Display an observed installation count, not power, delivery, actual
-- catapult targeting or item transfer availability.
local function hardware(site)
  if not site or site.launcher_count==nil then
    return L("freight-infra-hardware-unknown")
  end
  if site.launcher_count==0 then
    return L("freight-infra-hardware-none")
  end
  return L("freight-infra-hardware-count",tostring(site.launcher_count))
end
local function platforms(site)
  if not site or site.platforms==nil then
    return L("freight-infra-platforms-unknown")
  end
  return L("freight-infra-platforms-count",
    tostring(site.platforms),tostring(site.providers),
    tostring(site.unscheduled))
end
local function render_infrastructure(parent,route,report,width)
  if not route then return end
  local from=report.worlds[route.source]
  local to=report.worlds[route.target]
  local physical=line(parent,L("freight-infra-endpoints",
    name(route.source),hardware(from),
    name(route.target),hardware(to)),width-48)
  physical.style.font_color={r=.72,g=.78,b=.82}
  local orbit=line(parent,L("freight-infra-orbit",
    name(route.source),platforms(from),
    name(route.target),platforms(to)),width-48)
  orbit.style.font_color={r=.72,g=.78,b=.82}
end
function M.render(parent,player,snapshot,width)
  if not snapshot.installed then return end
  if not snapshot.enabled and orders.saved_count(player)==0 then return end
  local panel=parent.add{type="frame",direction="vertical",
    style="inside_shallow_frame"}
  panel.style.horizontally_stretchable=true
  panel.style.padding=9
  local title=line(panel,L("freight-board-heading"),width-36)
  title.style.font="default-bold"
  title.style.font_color={r=.86,g=.73,b=.49}
  line(panel,L("freight-board-explainer"),width-44)
  local data=orders.store(player.index)
  -- At most one read per discovered world for this explicit Journal render.
  local observed=infrastructure.snapshot(player.force,snapshot)
  if snapshot.visible==0 then
    line(panel,L("freight-board-undiscovered"),width-44)
    -- Even fully concealed or temporarily disabled routes must not leave
    -- a player trapped at the 20-order cap with no removal controls.
    local hidden=orders.unavailable(player)
    if #hidden>0 then
      line(panel,L("freight-board-unavailable",tostring(#hidden)),width-44)
      for _,entry in ipairs(hidden) do
        local row=panel.add{type="flow",direction="horizontal"}
        row.style.vertical_align="center"
        line(row,L("freight-board-hidden-plan"),math.max(110,width-190))
        row.add{type="button",caption=L("freight-board-remove"),
          tags={razi_ops_action="freight-remove",value=entry.id}}
      end
      panel.add{type="button",caption=L("freight-board-clear"),
        tags={razi_ops_action="freight-clear"}}
    end
    return
  end
  for _,entry in ipairs(snapshot.entries) do
    if entry.state=="researched" then
      local group=panel.add{type="flow",
        direction=width<680 and "vertical" or "horizontal"}
      group.style.vertical_align="center"
      group.style.horizontal_spacing=6
      for _,pair in ipairs({
        {entry.source,entry.target},{entry.target,entry.source}
      }) do
        local id="razi-"..pair[1].."-"..pair[2].."-catapult"
        if orders.route(player.force,id) then
          local button=group.add{type="button",
            caption=L("freight-board-direction",
              name(pair[1]),name(pair[2])),
            tags={razi_ops_action="freight-select",value=id}}
          button.style.minimal_width=85
          button.style.font="default-small"
        end
      end
    end
  end
  local draft=data.draft
  local selected=orders.route(player.force,draft.route)
  if selected then
    local selected_line=line(panel,L("freight-board-selected",
      name(selected.source),name(selected.target)),width-44)
    selected_line.style.font="default-bold"
    render_infrastructure(panel,selected,observed,width)
    local editor=panel.add{type="flow",direction="horizontal"}
    editor.style.vertical_align="center"
    editor.style.horizontal_spacing=8
    editor.add{type="choose-elem-button",elem_type="item",
      elem_value=draft.item,
      tags={razi_ops_action="freight-item"}}
    local count=editor.add{type="textfield",
      text=draft.count and tostring(draft.count) or "",
      numeric=true,allow_decimal=false,allow_negative=false,
      tags={razi_ops_action="freight-count"}}
    count.style.width=96
    editor.add{type="button",caption=L("freight-board-add"),
      tags={razi_ops_action="freight-add"}}
    local stacks=orders.stacks(draft.item,draft.count)
    if stacks then
      line(panel,L("freight-board-stacks",tostring(stacks)),width-44)
    else
      line(panel,L("freight-board-select-item"),width-44)
    end
  else
    line(panel,L("freight-board-pick-route"),width-44)
  end
  local listed=orders.orders(player)
  if selected or #listed>0 then
    line(panel,L("freight-infra-disclaimer"),width-44)
    line(panel,L(observed.platform_logistics and
      "freight-infra-companion-installed" or
      "freight-infra-companion-absent"),width-44)
  end
  local readiness=orders.readiness(player,listed)
  local total=orders.saved_count(player)
  if total>0 then
    local status=line(panel,L("freight-board-readiness",
      tostring(readiness.ready),tostring(readiness.short),
      tostring(readiness.remote),tostring(readiness.packed)),width-44)
    status.style.font_color={r=.74,g=.82,b=.82}
    line(panel,L("freight-board-readiness-caution"),width-44)
    local header=panel.add{type="flow",direction="horizontal"}
    header.style.vertical_align="center"
    header.style.horizontal_spacing=8
    local title=line(header,L("freight-board-list"),math.max(120,width-180))
    title.style.font="default-bold"
    header.add{type="button",caption=L("freight-board-clear"),
      tags={razi_ops_action="freight-clear"}}
    local hidden=orders.unavailable(player)
    if #hidden>0 then
      line(panel,L("freight-board-unavailable",
        tostring(#hidden)),width-44)
      for _,entry in ipairs(hidden) do
        local concealed=panel.add{type="flow",direction="horizontal"}
        concealed.style.vertical_align="center"
        line(concealed,L("freight-board-hidden-plan"),math.max(110,width-190))
        concealed.add{type="button",
          caption=L("freight-board-remove"),
          tags={razi_ops_action="freight-remove",value=entry.id}}
      end
    end
  end
  for _,entry in ipairs(listed) do
    local container=panel.add{type="flow",
      direction=width<680 and "vertical" or "horizontal"}
    container.style.vertical_align="center"
    container.style.horizontal_spacing=6
    local proto=prototypes.item[entry.item]
    local description=line(container,L("freight-board-order",
      tostring(entry.count),proto.localised_name,
      name(entry.route.source),name(entry.route.target),
      tostring(entry.stacks or "?"),
      L(entry.packed and "freight-board-packed"
        or "freight-board-planned")),math.max(135,
      width<680 and width-52 or width-326))
    description.style.font_color=entry.packed
      and {r=.55,g=.84,b=.70} or {r=.72,g=.78,b=.82}
    render_infrastructure(panel,entry.route,observed,width)
    -- Real inventory state is local to this player. It is not a
    -- measurement of launchpad storage or the destination's inventory.
    if player.get_item_count then
      local carried=player.get_item_count(entry.item) or 0
      local note=line(panel,L("freight-board-carried",
        tostring(carried),tostring(entry.count)),width-48)
      note.style.font_color=carried>=entry.count
        and {r=.55,g=.84,b=.70} or {r=.72,g=.78,b=.82}
    end
    if entry.load_state=="ready" then
      local note=line(panel,L("freight-board-load-ready"),width-48)
      note.style.font_color={r=.55,g=.84,b=.70}
    elseif entry.load_state=="short" then
      local note=line(panel,L("freight-board-load-short",
        tostring(entry.shortfall)),width-48)
      note.style.font_color={r=.86,g=.73,b=.49}
    elseif entry.load_state=="remote" then
      line(panel,L("freight-board-load-remote",
        name(entry.route.source)),width-48)
    elseif entry.load_state=="packed" then
      line(panel,L("freight-board-load-packed"),width-48)
    else
      line(panel,L("freight-board-load-unknown"),width-48)
    end
    container.add{type="button",caption="↑",
      tooltip=L("freight-board-move-up"),
      tags={razi_ops_action="freight-up",value=entry.id}}
    container.add{type="button",caption="↓",
      tooltip=L("freight-board-move-down"),
      tags={razi_ops_action="freight-down",value=entry.id}}
    container.add{type="button",
      caption=L(entry.packed and "freight-board-undo"
        or "freight-board-pack"),
      tags={razi_ops_action="freight-packed",value=entry.id}}
    container.add{type="button",caption=L("freight-board-remove"),
      tags={razi_ops_action="freight-remove",value=entry.id}}
  end
  line(panel,L("freight-board-manual"),width-44)
end
return M
