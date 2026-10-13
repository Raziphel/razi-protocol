-- Read-only Cargo Network dashboard. Planet Express owns freight schedules;
-- the source mods own production and research, not this UI.
local M={}
local catalog=require("scripts.galactic_trade_catalog")
local signals=require("prototypes.compat.aai_signal_partnerships")
local function L(key,...) return {"razi-ops."..key,...} end
local function label(parent,caption,style)
  local obj=parent.add{type="label",caption=caption}
  if style then obj.style.font=style end
  return obj
end
local function wrap(parent,caption,width)
  local obj=label(parent,caption)
  obj.style.single_line=false
  obj.style.maximal_width=math.max(100,width)
  return obj
end
local function heading(parent,caption,width)
  local obj=wrap(parent,caption,width)
  obj.style.font="default-bold"
  obj.style.font_color={r=.57,g=.79,b=.97}
  return obj
end
local function valid_sprite(path)
  return helpers and helpers.is_valid_sprite_path
    and helpers.is_valid_sprite_path(path)
end
local function sprite_for(kind,name)
  local path=kind.."/"..name
  return valid_sprite(path) and path or nil
end
local function item_proto(name,kind)
  if not prototypes then return nil end
  local stock=kind=="fluid" and prototypes.fluid or prototypes.item
  return stock and stock[name] or nil
end
local function product_details(part)
  local recipe=prototypes and prototypes.recipe
    and prototypes.recipe[part.id]
  if not recipe then return nil end
  local amount=nil
  for _,result in pairs(recipe.products or {}) do
    if result.name==part.id then amount=result.amount or result.amount_min end
  end
  return {recipe=recipe,amount=amount}
end
local function world_title(name)
  local proto=prototypes and prototypes.space_location
    and prototypes.space_location[name]
  if proto then return proto.localised_name end
  return name:gsub("[_-]"," ")
end
local function layout(player)
  local scale=math.max(.5,player.display_scale or 1)
  local available=math.floor(player.display_resolution.width/scale)
  local height=math.floor(player.display_resolution.height/scale)
  local width=math.max(220,math.min(920,available-110))
  local compact=width<790
  return {
    width=width,compact=compact,
    card=compact and math.max(185,width-40)
      or math.floor((width-65)/2),
    scroll=math.max(160,math.min(510,math.floor(height*.56)))
  }
end
M.layout=layout

function M.summary(force)
  local tech=force.technologies and force.technologies["interplanetary-trade-logistics"]
  local ships,unscheduled,transit=0,0,0
  for _,ship in pairs(force.platforms or {}) do
    if ship.valid and not ship.hidden and ship.scheduled_for_deletion==0 then
      ships=ships+1
      local schedule=ship.schedule
      if not schedule or not schedule.records or #schedule.records==0 then
        unscheduled=unscheduled+1
      end
      if ship.space_connection then transit=transit+1 end
    end
  end
  return {
    research=tech,
    unlocked=tech and tech.researched or false,
    ships=ships,unscheduled=unscheduled,transit=transit
  }
end

local function status(parent,state,width)
  local key="trade-state-"..state.status
  local obj=wrap(parent,L(key),width)
  obj.style.font="default-bold"
  if state.status=="researched" then
    obj.style.font_color={r=.49,g=.87,b=.70}
  elseif state.status=="ready" then
    obj.style.font_color={r=.61,g=.79,b=.98}
  else
    obj.style.font_color={r=1,g=.72,b=.45}
  end
end

local function tile(parent,title,value,width,color)
  local tile=parent.add{type="frame",direction="vertical",
    style="inside_shallow_frame"}
  tile.style.width=width
  tile.style.padding=6
  local number=label(tile,tostring(value),"heading-2")
  number.style.font_color=color or {r=.58,g=.79,b=.98}
  wrap(tile,L(title),width-18)
end

local function source_worlds(parent,entry,width)
  heading(parent,L("trade-sources"),width)
  local grid=parent.add{type="table",column_count=2}
  grid.style.horizontal_spacing=6
  grid.style.vertical_spacing=4
  for _,name in ipairs(entry.worlds) do
    local line=grid.add{type="flow",direction="horizontal"}
    line.style.vertical_align="center"
    local icon=sprite_for("planet",name)
      or sprite_for("space-location",name)
    if icon then
      local art=line.add{type="sprite",sprite=icon}
      art.style.width=20
      art.style.height=20
    end
    wrap(line,world_title(name),math.max(80,math.floor((width-43)/2)))
  end
end

local function supplier_recipe(parent,part,width)
  local details=product_details(part)
  if not details then
    wrap(parent,L("trade-recipe-missing"),width)
    return
  end
  if details.amount then
    heading(parent,L("trade-yield",tostring(details.amount)),width)
  end
  local ingredients=details.recipe.ingredients or {}
  if #ingredients==0 then return end
  local grid=parent.add{type="table",column_count=2}
  grid.style.vertical_spacing=5
  grid.style.horizontal_spacing=5
  for i=1,math.min(6,#ingredients) do
    local input=ingredients[i]
    local name=input.name or input[1]
    if name then
      local kind=input.type=="fluid" and "fluid" or "item"
      local proto=item_proto(name,kind)
      local line=grid.add{type="flow",direction="horizontal"}
      line.style.vertical_align="center"
      local sprite=sprite_for(kind,name)
      if sprite then
        local art=line.add{type="sprite",sprite=sprite}
        art.style.width=20
        art.style.height=20
      end
      local amount=input.amount or input[2] or 1
      wrap(line,{"",tostring(amount)," × ",
        proto and proto.localised_name or name},
        math.max(82,math.floor((width-45)/2)))
    end
  end
end

-- Research requirements use Factorio's live technology state. They are
-- only drawn for expanded cards, not collected on every fleet refresh.
local function science_requirements(parent,tech,width)
  local ingredients=tech and tech.research_unit_ingredients or {}
  if #ingredients==0 then return end
  local count=tech.research_unit_count
  heading(parent,L("trade-science-heading"),width)
  if count and count>0 then
    wrap(parent,L("trade-science-units",tostring(count)),width)
  end
  local grid=parent.add{type="table",column_count=width<270 and 1 or 2}
  grid.style.horizontal_spacing=6
  grid.style.vertical_spacing=4
  for i=1,math.min(9,#ingredients) do
    local input=ingredients[i]
    local name=input.name or input[1]
    if name then
      local line=grid.add{type="flow",direction="horizontal"}
      line.style.vertical_align="center"
      local image=sprite_for("item",name)
      if image then
        local sprite=line.add{type="sprite",sprite=image}
        sprite.style.width=18
        sprite.style.height=18
      end
      local item=item_proto(name,"item")
      local amount=input.amount or input[2] or 1
      wrap(line,{"",tostring(amount)," × ",
        item and item.localised_name or name},
        math.max(90,math.floor(width/(width<270 and 1 or 2))-32))
    end
  end
  if #ingredients>9 then
    wrap(parent,L("trade-science-more",tostring(#ingredients-9)),width)
  end
end

local function blockers(parent,state,width)
  if state.status~="blocked" then return end
  heading(parent,L("trade-prerequisites",tostring(state.count)),width)
  for i=1,math.min(3,#state.missing) do
    wrap(parent,{"",L("trade-needs"),"  ",
      state.missing[i].localised_name},width)
  end
  if state.count>3 then
    wrap(parent,L("trade-more-prerequisites",tostring(state.count-3)),width)
  end
end

local function codex_link(parent,technology_name,caption)
  local id=catalog.quest_for_technology(technology_name)
  if not id then return false end
  parent.add{type="button",caption=caption,
    tooltip=L("trade-open-codex-tooltip"),
    tags={razi_ops_action="cargo-codex",value=technology_name}}
  return true
end

local function consumers(parent,row,width,p)
  if #row.upgrades==0 then
    wrap(parent,L("trade-no-upgrades"),width)
    return
  end
  heading(parent,L("trade-upgrades",tostring(row.researched_upgrades),
    tostring(#row.upgrades)),width)
  local bar=parent.add{type="progressbar",
    value=row.researched_upgrades/#row.upgrades}
  bar.style.width=math.max(140,width-25)
  bar.style.height=7
  bar.style.color={r=.47,g=.80,b=.67}
  for _,consumer in ipairs(row.upgrades) do
    local line=parent.add{type="flow",
      direction=width<350 and "vertical" or "horizontal"}
    line.style.vertical_align="center"
    if p.cargo_target==consumer.name then
      local selected=wrap(line,L("trade-linked-target"),width-30)
      selected.style.font_color={r=.68,g=.82,b=.98}
    end
    local image=sprite_for("technology",consumer.name)
    if image then
      local icon=line.add{type="sprite",sprite=image}
      icon.style.width=22
      icon.style.height=22
    end
    local entry=wrap(line,consumer.technology.localised_name,
      math.max(115,width-105))
    entry.tooltip=L("trade-upgrade-tooltip")
    local mark=label(line,L("trade-state-short-"..consumer.state.status))
    mark.style.font_color=consumer.state.status=="researched"
      and {r=.51,g=.88,b=.69} or {r=1,g=.75,b=.49}
    if catalog.quest_for_technology(consumer.name) then
      codex_link(parent,consumer.name,L("trade-open-codex-short"))
    end
    if p.cargo_focus==row.config.id and
      p.cargo_target==consumer.name then
      science_requirements(parent,consumer.technology,width)
      if consumer.state.status=="blocked" then
        blockers(parent,consumer.state,width)
      end
    end
  end
end

local function render_chain(parent,row,p,width)
  local entry=row.config
  local card=parent.add{type="frame",direction="vertical",
    style="inside_shallow_frame"}
  card.style.width=width
  card.style.padding=10
  local header=card.add{type="flow",direction="horizontal"}
  header.style.vertical_align="center"
  local icon=sprite_for("item",entry.id)
    or sprite_for("technology",entry.id)
  if icon then
    local art=header.add{type="sprite",sprite=icon}
    art.style.width=36
    art.style.height=36
  end
  local top=header.add{type="flow",direction="vertical"}
  top.style.vertical_spacing=2
  local name=wrap(top,row.technology.localised_name,width-77)
  name.style.font="heading-2"
  status(top,row.state,width-77)
  if entry.deep then
    local deep=wrap(card,L("trade-deep-only"),width-20)
    deep.style.font_color={r=.86,g=.67,b=.97}
  end
  wrap(card,L("trade-chain-"..entry.key),width-20)
  if p.cargo_target==entry.id then
    local selected=wrap(card,L("trade-linked-target"),width-20)
    selected.style.font_color={r=.67,g=.84,b=.98}
  end
  if p.cargo_focus==entry.id then
    source_worlds(card,entry,width-20)
    heading(card,L("trade-ingredients"),width-20)
    supplier_recipe(card,entry,width-20)
    science_requirements(card,row.technology,width-20)
    blockers(card,row.state,width-20)
  end
  consumers(card,row,width-20,p)
  local actions=card.add{type="flow",
    direction=width<350 and "vertical" or "horizontal"}
  actions.style.horizontal_spacing=8
  local action=actions.add{type="button",
    caption=L(p.cargo_focus==entry.id and "trade-hide-details"
      or "trade-details"),tags={razi_ops_action="cargo-focus",value=entry.id}}
  action.style.font="default-bold"
  codex_link(actions,entry.id,L("trade-open-codex"))
end

-- Read-only communication research and operator guide. AAI owns the
-- live circuit channels; unlike Planet Express, it provides no shipment
-- inventory to count here. Never invent connected transmitters.
local function signal_network(parent,player,width)
  if not (script and script.active_mods
    and script.active_mods["aai-signal-transmission"]
    and prototypes and prototypes.technology) then return end
  local name=signals.source_technology(prototypes.technology)
  if not name then return end
  local tech=player.force.technologies and player.force.technologies[name]
  if not tech then return end
  local frame=parent.add{type="frame",direction="vertical",
    style="inside_shallow_frame"}
  frame.style.horizontally_stretchable=true
  frame.style.padding=8
  heading(frame,L("trade-signal-heading"),width-36)
  local status=wrap(frame,L(tech.researched
    and "trade-signal-researched" or "trade-signal-locked"),width-36)
  status.style.font_color=tech.researched
    and {r=.51,g=.87,b=.71} or {r=1,g=.73,b=.46}
  wrap(frame,L("trade-signal-guide"),width-36)
  wrap(frame,L("trade-signal-ship-guide"),width-36)
  codex_link(frame,name,L("trade-signal-codex"))
end

function M.render(parent,player,p)
  p=p or {}
  local size=layout(player)
  local network=catalog.snapshot(player.force)
  local fleet=M.summary(player.force)
  local title=label(parent,L("trade-title"),"heading-2")
  title.style.font_color={r=.58,g=.80,b=.98}
  wrap(parent,L("trade-intro"),size.width)
  local metrics=parent.add{type="table",
    column_count=size.compact and 2 or 4}
  metrics.style.horizontal_spacing=5
  metrics.style.vertical_spacing=5
  local metric_width=size.compact
    and math.max(105,math.floor((size.width-30)/2))
    or math.floor((size.width-55)/4)
  tile(metrics,"trade-metric-parts",network.available,metric_width)
  tile(metrics,"trade-metric-researched",network.researched,metric_width,
    {r=.51,g=.87,b=.71})
  tile(metrics,"trade-metric-upgrades",network.upgrades,metric_width)
  tile(metrics,"trade-metric-transit",fleet.transit,metric_width)
  local freight=parent.add{type="frame",direction="vertical",
    style="inside_shallow_frame"}
  freight.style.horizontally_stretchable=true
  freight.style.padding=7
  local lead=wrap(freight,fleet.unlocked and L("trade-researched")
    or L("trade-not-researched"),size.width-30)
  lead.style.font_color=fleet.unlocked
    and {r=.50,g=.85,b=.68} or {r=1,g=.73,b=.46}
  wrap(freight,L("trade-fleet-counts",tostring(fleet.ships),
    tostring(fleet.transit),tostring(fleet.unscheduled)),size.width-30)

  signal_network(parent,player,size.width)

  local scroll=parent.add{type="scroll-pane",direction="vertical"}
  scroll.style.horizontally_stretchable=true
  scroll.horizontal_scroll_policy="never"
  scroll.style.height=size.scroll
  heading(scroll,L("trade-components"),size.width-20)
  if #network.parts==0 then
    wrap(scroll,L("trade-no-components"),size.width-30)
  else
    local grid=scroll.add{type="table",
      column_count=size.compact and 1 or 2}
    grid.style.horizontal_spacing=8
    grid.style.vertical_spacing=8
    for _,row in ipairs(network.parts) do
      render_chain(grid,row,p,size.card)
    end
    wrap(scroll,L("trade-research-not-production"),size.width-30)
  end
  local setup=scroll.add{type="frame",direction="vertical",
    style="inside_shallow_frame"}
  setup.style.horizontally_stretchable=true
  setup.style.padding=9
  heading(setup,L("trade-dispatch-guide"),size.width-40)
  for _,key in ipairs({"trade-hub-setup","trade-pad-setup",
                       "trade-ship-autonomy"}) do
    wrap(setup,L(key),size.width-45)
  end
  if fleet.research and not fleet.research.researched then
    local state=catalog.state(fleet.research)
    blockers(setup,state,size.width-45)
  end
end
return M
