-- Read-only Cargo Network dashboard. Planet Express owns freight schedules;
-- the source mods own production and research, not this UI.
local M={}
local catalog=require("scripts.galactic_trade_catalog")
local portfolio=require("scripts.razi_industry_portfolio")
local signals=require("prototypes.compat.aai_signal_partnerships")
local icons=require("scripts.razi_journal_icons")
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
local function fixed_sprite(parent,kind,name,role)
  local path=sprite_for(kind,name)
  if path then return icons.sprite(parent,path,role) end
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
local function layout(player,limit)
  local scale=math.max(.5,player.display_scale or 1)
  local available=math.floor(player.display_resolution.width/scale)
  local height=math.floor(player.display_resolution.height/scale)
  local width=math.max(220,math.min(920,available-110,limit or 920))
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
    if icon then icons.sprite(line,icon,"cargo_world") end
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
      fixed_sprite(line,kind,name,"cargo_material")
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
      fixed_sprite(line,"item",name,"cargo_science")
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
  if (state.status~="blocked" and state.status~="disabled")
    or state.count==0 then return end
  heading(parent,L("trade-prerequisites",tostring(state.count)),width)
  for i=1,math.min(3,#state.missing) do
    wrap(parent,{"",L("trade-needs"),"  ",
      state.missing[i].localised_name},width)
  end
  if state.count>3 then
    wrap(parent,L("trade-more-prerequisites",tostring(state.count-3)),width)
  end
end

local function codex_link(parent,technology_name,caption,inline)
  local id=catalog.quest_for_technology(technology_name)
  if not id then return false end
  local control=parent.add{type=inline and "label" or "button",
    style=inline and "clickable_label" or nil,caption=caption,
    tooltip=L("trade-open-codex-tooltip"),
    tags={razi_ops_action="cargo-codex",value=technology_name}}
  if inline then control.style.font_color={r=.60,g=.80,b=.97} end
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
  bar.style.width=math.max(110,width-10)
  bar.style.height=6
  bar.style.color={r=.47,g=.80,b=.67}
  local list=parent.add{type="flow",direction="vertical"}
  list.style.vertical_spacing=8
  for index,consumer in ipairs(row.upgrades) do
    -- Keep all details of a research milestone in one contained row. Native
    -- tech sprites can be huge; each is now a fixed 19px Codex emblem.
    local entry=list.add{type="flow",direction="vertical"}
    entry.style.width=width
    entry.style.vertical_spacing=3
    local line=entry.add{type="flow",direction="horizontal"}
    line.style.horizontal_spacing=8
    line.style.vertical_align="top"
    fixed_sprite(line,"technology",consumer.name,"cargo_research")
    local copy=line.add{type="flow",direction="vertical"}
    copy.style.vertical_spacing=3
    local name=wrap(copy,consumer.technology.localised_name,
      math.max(105,width-56))
    name.style.font="default-bold"
    name.tooltip=L("trade-upgrade-tooltip")
    local narrow=width<275
    local metadata=copy.add{type="flow",
      direction=narrow and "vertical" or "horizontal"}
    -- Factorio exposes distinct HorizontalFlow/VerticalFlow GuiStyle types.
    -- Writing vertical_spacing to a HorizontalFlow crashes on_gui_click.
    if narrow then
      metadata.style.vertical_spacing=3
    else
      metadata.style.horizontal_spacing=12
    end
    local state=label(metadata,L("trade-state-short-"..consumer.state.status))
    state.style.font_color=consumer.state.status=="researched"
      and {r=.51,g=.88,b=.69} or {r=1,g=.75,b=.49}
    codex_link(metadata,consumer.name,L("trade-open-codex-short"),true)
    if p.cargo_target==consumer.name then
      local selected=wrap(entry,L("trade-linked-target"),width-12)
      selected.style.font_color={r=.68,g=.82,b=.98}
    end
    if p.cargo_focus==row.config.id and
      p.cargo_target==consumer.name then
      science_requirements(entry,consumer.technology,width)
      blockers(entry,consumer.state,width)
    end
    if index<#row.upgrades then
      local separator=entry.add{type="line",direction="horizontal"}
      separator.style.horizontally_stretchable=true
    end
  end
end

local function render_chain(parent,row,p,width,index)
  local entry=row.config
  local card=parent.add{type="frame",direction="vertical",
    style="inside_shallow_frame"}
  card.style.width=width
  card.style.padding=12
  local inner=width-32
  local folio=label(card,L("trade-chain-folio",string.format("%02d",index)))
  folio.style.font="default-bold"
  folio.style.font_color=p.cargo_focus==entry.id
    and {r=.91,g=.75,b=.52} or {r=.58,g=.71,b=.79}
  local header=card.add{type="flow",direction="horizontal"}
  header.style.horizontal_spacing=10
  header.style.vertical_align="center"
  local icon=sprite_for("item",entry.id)
    or sprite_for("technology",entry.id)
  if icon then icons.sprite(header,icon,"cargo_chain") end
  local top=header.add{type="flow",direction="vertical"}
  top.style.vertical_spacing=4
  local name=wrap(top,row.technology.localised_name,
    math.max(105,inner-56))
  name.style.font="heading-2"
  status(top,row.state,math.max(105,inner-56))
  local description=wrap(card,L("trade-chain-"..entry.key),inner)
  description.style.font_color={r=.80,g=.83,b=.85}
  if entry.deep then
    local deep=wrap(card,L("trade-deep-only"),inner)
    deep.style.font_color={r=.86,g=.67,b=.97}
  end
  if p.cargo_target==entry.id then
    local selected=wrap(card,L("trade-linked-target"),inner)
    selected.style.font_color={r=.67,g=.84,b=.98}
  end
  if p.cargo_focus==entry.id then
    source_worlds(card,entry,inner)
    heading(card,L("trade-ingredients"),inner)
    supplier_recipe(card,entry,inner)
    science_requirements(card,row.technology,inner)
    blockers(card,row.state,inner)
  end
  consumers(card,row,inner,p)
  local narrow=inner<275
  local actions=card.add{type="flow",
    direction=narrow and "vertical" or "horizontal"}
  if narrow then
    actions.style.vertical_spacing=4
  else
    actions.style.horizontal_spacing=12
  end
  local action=actions.add{type="button",
    caption=L(p.cargo_focus==entry.id and "trade-hide-details"
      or "trade-details"),tags={razi_ops_action="cargo-focus",value=entry.id}}
  action.style.font="default-bold"
  codex_link(actions,entry.id,L("trade-open-codex-short"),true)
end

-- Browse real optional industry researches without claiming factory or freight
-- telemetry. Only installed technologies with loaded recipes are displayed.
-- Selecting an opportunity jumps to its existing Expedition Journal dossier.
local function factory_opportunities(parent,player,width)
  local snapshot=portfolio.snapshot(player.force,8)
  if snapshot.available==0 then return end
  local card=parent.add{type="frame",direction="vertical",
    style="inside_shallow_frame"}
  card.style.horizontally_stretchable=true
  card.style.padding=10
  heading(card,L("trade-portfolio-heading"),width-36)
  local overview=wrap(card,L("trade-portfolio-summary",
    tostring(snapshot.available),tostring(snapshot.researched),
    tostring(snapshot.ready)),width-40)
  overview.style.font_color={r=.70,g=.79,b=.82}
  local instruction=wrap(card,L("trade-portfolio-disclaimer"),width-40)
  instruction.style.font_color={r=.63,g=.70,b=.75}
  for _,entry in ipairs(snapshot.entries) do
    local line=card.add{type="flow",direction="horizontal"}
    line.style.horizontal_spacing=8
    line.style.vertical_align="center"
    fixed_sprite(line,"technology",entry.quest.tech,"cargo_research")
    local copy=line.add{type="flow",direction="vertical"}
    copy.style.vertical_spacing=2
    local title=copy.add{type="label",style="clickable_label",
      caption=entry.technology.localised_name,
      tags={razi_journal_action="guidance-select",id=entry.quest.id},
      tooltip=L("trade-portfolio-open")}
    title.style.single_line=false
    title.style.maximal_width=math.max(140,width-108)
    local metadata=wrap(copy,{"",L("trade-state-short-"..entry.status),
      " / ",world_title(entry.site)},math.max(140,width-108))
    metadata.style.font_color={r=.66,g=.74,b=.78}
    -- A real per-craft native product quantity is more useful than an
    -- invented "profit" label. Never label probabilistic outputs as fixed.
    for _,product in ipairs(entry.recipe.products or {}) do
      local amount=product.amount
      if type(amount)=="number" and amount>0
        and (product.probability==nil or product.probability==1)
        and not product.amount_min and not product.amount_max then
        local kind=product.type=="fluid" and "fluid" or "item"
        local prototype=product.name and item_proto(product.name,kind)
        local output=wrap(copy,L("trade-portfolio-output",tostring(amount),
          prototype and prototype.localised_name or product.name or "?"),
          math.max(140,width-108))
        output.style.font_color={r=.62,g=.77,b=.67}
        break
      end
    end
  end
  if snapshot.available>#snapshot.entries then
    wrap(card,L("trade-portfolio-more",
      tostring(snapshot.available-#snapshot.entries)),width-40)
  end
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

function M.render(parent,player,p,options)
  p=p or {}
  options=options or {}
  local size=layout(player,options.width)
  local network=catalog.snapshot(player.force)
  local fleet=M.summary(player.force)
  local masthead=parent.add{type="flow",direction="horizontal"}
  masthead.style.horizontal_spacing=9
  masthead.style.vertical_align="center"
  fixed_sprite(masthead,"technology","interplanetary-trade-logistics","cargo_header")
  local title=label(masthead,L("trade-title"),"heading-2")
  title.style.font_color={r=.58,g=.80,b=.98}
  wrap(parent,L("trade-intro"),size.width)
  -- A single logistics ledger replaces four generic dashboard tiles.
  -- These counts describe known technologies, never phantom shipments.
  local ledger=parent.add{type="flow",direction="vertical"}
  ledger.style.horizontally_stretchable=true
  ledger.style.vertical_spacing=5
  local row=ledger.add{type="flow",direction="horizontal"}
  row.style.horizontal_spacing=8
  local researched=label(row,tostring(network.researched),"heading-2")
  researched.style.font_color={r=.85,g=.88,b=.85}
  local of=label(row,L("trade-ledger-progress",tostring(network.available)))
  of.style.font_color={r=.64,g=.72,b=.76}
  local count=label(ledger,
    L("trade-ledger-upgrades",tostring(network.upgrades),tostring(fleet.transit)))
  count.style.font_color={r=.66,g=.73,b=.76}
  local meter=ledger.add{type="progressbar",
    value=network.available>0 and network.researched/network.available or 0}
  meter.style.width=math.max(160,size.width-40)
  meter.style.height=7
  meter.style.color={r=.49,g=.69,b=.72}
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

  -- Installed companion field notes. No remote calls or repeated scans;
  -- this section is created only when the Cargo dossier is opened.
  local companion_ids={
    {"Various_Cargo_Bays","companion-pod-bays"},
    {"space-age-railway-expansion","companion-trains"},
    {"shield-generators","companion-shields"},
    {"CircuitLaunchableRockets","companion-circuits"},
    {"CargoBayLimitResearch","companion-bay-limits"},
    {"platform-logistics-overhaul","companion-platform-hubs"},
    {"orbital-cannon","companion-catapult"}
  }
  local installed=script and script.active_mods or {}
  local active={}
  for _,entry in ipairs(companion_ids) do
    if installed[entry[1]] then active[#active+1]=entry[2] end
  end
  if #active>0 then
    local companions=parent.add{type="flow",direction="vertical"}
    companions.style.vertical_spacing=5
    local heading=companions.add{type="label",
      caption=L("companion-ledger-heading")}
    heading.style.font="default-bold"
    heading.style.font_color={r=.71,g=.83,b=.87}
    for _,key in ipairs(active) do
      local line=wrap(companions,L(key),size.width-38)
      line.style.font_color={r=.73,g=.77,b=.80}
    end
  end

  local scroll=options.embedded and parent
    or parent.add{type="scroll-pane",direction="vertical"}
  if not options.embedded then
    scroll.style.horizontally_stretchable=true
    scroll.horizontal_scroll_policy="never"
    scroll.style.height=size.scroll
  end
  heading(scroll,L("trade-components"),size.width-20)
  if #network.parts==0 then
    wrap(scroll,L("trade-no-components"),size.width-30)
  else
    local grid=scroll.add{type="table",
      column_count=size.compact and 1 or 2}
    grid.style.horizontal_spacing=8
    grid.style.vertical_spacing=8
    for index,row in ipairs(network.parts) do
      render_chain(grid,row,p,size.card,index)
    end
    wrap(scroll,L("trade-research-not-production"),size.width-30)
  end
  factory_opportunities(scroll,player,size.width)
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
