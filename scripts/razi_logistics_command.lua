-- The Journal's Galactic Logistics Command. Source-owned transport stays
-- outside Razi; this is a read-only operations desk and manual plan navigator.
-- Each tab renders on demand, with no new background polling or remote calls.
local M={}
local routes=require("scripts.razi_catapult_network")
local infrastructure=require("scripts.razi_freight_infrastructure")
local deliveries=require("scripts.razi_freight_receipts")
local orders=require("scripts.razi_freight_orders")
local board=require("scripts.razi_freight_dispatch_ui")
local L=function(key,...) return {"razi-ops."..key,...} end
local ink={r=.91,g=.87,b=.79}
local muted={r=.70,g=.75,b=.74}
local gold={r=.82,g=.69,b=.48}
local teal={r=.54,g=.78,b=.75}
local function text(parent,caption,width,bold,color)
  local label=parent.add{type="label",caption=caption}
  label.style.single_line=false
  label.style.maximal_width=math.max(110,width or 300)
  label.style.font=bold and "default-bold" or "default"
  label.style.font_color=color or muted
  return label
end
local function group(parent,title,width)
  local frame=parent.add{type="frame",style="inside_shallow_frame",
    direction="vertical"}
  frame.style.horizontally_stretchable=true
  frame.style.padding=9
  text(frame,title,width-35,true,gold)
  return frame
end
local function world_name(world)
  local proto=prototypes and prototypes.space_location
    and prototypes.space_location[world]
  return proto and proto.localised_name or world
end
local function count(value)
  return value~=nil and tostring(value) or L("logistics-unknown")
end
local function prepared(player)
  local listed=orders.orders(player)
  local queued=0
  for _,entry in ipairs(listed) do
    if not entry.packed then queued=queued+1 end
  end
  return listed,queued
end
local function direction_button(parent,player,a,b)
  local id="razi-"..a.."-"..b.."-catapult"
  if not orders.route(player.force,id) then return end
  local button=parent.add{type="button",
    caption=L("logistics-open-route",world_name(a),world_name(b)),
    tooltip=L("logistics-open-route-help"),
    tags={razi_ops_action="logistics-route",value=id}}
  button.style.font="default-small"
end

local function endpoint(parent,world,site,receipts,width)
  local heading=text(parent,world_name(world),width-40,true,ink)
  heading.tooltip=L("logistics-observation-tooltip")
  local n=site and site.launcher_count
  local hardware=n==nil and L("logistics-hardware-unknown")
    or L("logistics-hardware-candidates",tostring(n))
  text(parent,L("logistics-endpoint-hardware",hardware),width-40)
  if site and site.platforms~=nil then
    text(parent,L("logistics-endpoint-platforms",
      tostring(site.platforms),tostring(site.providers),
      tostring(site.unscheduled)),width-40)
    if site.vanilla_bays~=nil then
      text(parent,L("logistics-endpoint-bays",
        tostring(site.vanilla_bays)),width-40)
    end
  else
    text(parent,L("logistics-platform-unknown"),width-40)
  end
  text(parent,L("logistics-endpoint-arrivals",
    tostring(receipts.worlds[world] or 0)),width-40)
end

local function one_route(parent,player,entry,observed,receipts,width,compact)
  local pane=group(parent,L("logistics-corridor-title",
    world_name(entry.source),world_name(entry.target)),width)
  local status=entry.state=="researched" and
    L("logistics-route-surveyed") or L("logistics-route-unresearched")
  text(pane,L("logistics-corridor-status",status),width-40,
    false,entry.state=="researched" and teal or muted)
  if entry.purpose then
    text(pane,L("catapult-network-purpose-"..entry.purpose),width-40)
  end
  if entry.state=="researched" then
    local endpoints=pane.add{type="flow",
      direction=compact and "vertical" or "horizontal"}
    endpoints.style.horizontal_spacing=12
    endpoints.style.vertical_spacing=5
    local half=compact and width-40 or math.floor((width-40)/2)
    endpoint(endpoints,entry.source,observed.worlds[entry.source],
      receipts,half)
    endpoint(endpoints,entry.target,observed.worlds[entry.target],
      receipts,half)
    local controls=pane.add{type="flow",direction=compact and "vertical"
      or "horizontal"}
    controls.style.horizontal_spacing=6
    direction_button(controls,player,entry.source,entry.target)
    direction_button(controls,player,entry.target,entry.source)
  end
end

function M.overview(parent,player,width,fleet)
  local network=routes.snapshot(player.force)
  local receipts=deliveries.snapshot(player.force,network)
  local listed,pending=prepared(player)
  local observed=infrastructure.snapshot(player.force,network)
  local scanned=0
  for _,entry in ipairs(network.entries) do
    if entry.state=="researched" then scanned=scanned+1 end
  end
  text(parent,L("logistics-introduction"),width,false,muted)
  local strip=group(parent,L("logistics-overview-title"),width)
  local metrics=strip.add{type="flow",
    direction=width<650 and "vertical" or "horizontal"}
  metrics.style.horizontal_spacing=18
  metrics.style.vertical_spacing=5
  text(metrics,L("logistics-metric-routes",
    tostring(scanned),tostring(#network.entries)),width-36,true,teal)
  text(metrics,L("logistics-metric-plans",
    tostring(#listed),tostring(pending)),width-36,true,ink)
  text(metrics,L("logistics-metric-deliveries",
    tostring(receipts.total)),width-36,true,gold)
  text(strip,L("logistics-metric-ships",
    tostring(fleet.ships),tostring(fleet.transit),
    tostring(fleet.unscheduled)),width-36)
  text(strip,L("logistics-metric-caution"),width-36)
  local network_card=group(parent,L("logistics-network-summary"),width)
  if not network.enabled or #network.entries==0 then
    text(network_card,L("logistics-network-locked"),width-36)
  else
    local displayed=0
    for _,entry in ipairs(network.entries) do
      if entry.state=="researched" then
        displayed=displayed+1
        if displayed<=4 then
          local line=network_card.add{type="flow",direction="horizontal"}
          line.style.horizontal_spacing=8
          text(line,L("logistics-network-row",
            world_name(entry.source),world_name(entry.target)),width-48,
            true,ink)
          -- Connections displayed here are researched routes, NOT
          -- confirmed powered links or dispatches.
        end
      end
    end
    if displayed==0 then
      text(network_card,L("logistics-network-locked"),width-36)
    end
  end
  text(network_card,L("logistics-network-footnote",
    tostring(observed.checked)),width-36)
  local activity=group(parent,L("logistics-activity-title"),width)
  if #receipts.recent==0 then
    text(activity,L("logistics-activity-empty"),width-36)
  else
    local shown=0
    for _,record in ipairs(receipts.recent) do
      shown=shown+1
      if shown>5 then break end
      text(activity,L("logistics-activity-row",
        world_name(record.world),tostring(record.tick)),width-36)
    end
  end
  text(activity,L("logistics-activity-caution"),width-36)
  text(parent,L("logistics-navigation-help"),width)
end

function M.routes(parent,player,width)
  local network=routes.snapshot(player.force)
  local observed=infrastructure.snapshot(player.force,network)
  local receipts=deliveries.snapshot(player.force,network)
  text(parent,L("logistics-routes-intro"),width)
  if not network.enabled or #network.entries==0 then
    text(parent,L("logistics-network-locked"),width)
  else
    for _,entry in ipairs(network.entries) do
      one_route(parent,player,entry,observed,receipts,width,width<710)
    end
  end
  text(parent,L("logistics-routes-evidence"),width)
end

function M.freight(parent,player,width)
  local network=routes.snapshot(player.force)
  text(parent,L("logistics-freight-intro"),width)
  -- Clean mode suppresses repeated endpoint/arrival dossiers. The Freight
  -- Desk retains its existing order IDs, packing actions and safety checks.
  board.render(parent,player,network,width,{clean=true})
  if not network.installed then
    text(parent,L("logistics-source-missing"),width)
  end
end
return M
