-- A.5: recipe-backed supply calculations and player-authorized packing.
-- Never infer supplier provenance, live production, machine stock or delivery.
-- Runtime lookups happen only on an opened Journal Supply view/action.
local M={}
local industry=require("scripts.razi_industry_portfolio")
local routes=require("scripts.razi_catapult_network")
local freight=require("scripts.razi_freight_orders")
local L=function(key,...) return {"razi-ops."..key,...} end
local GOLD={r=.82,g=.69,b=.48}
local INK={r=.91,g=.87,b=.79}
local SOFT={r=.70,g=.76,b=.74}
local MAX_BATCHES=1000
local MAX_ROWS=50

function M.batches(value)
  local n=tonumber(value)
  if n and n==n and n>=1 and n<=MAX_BATCHES
    and math.floor(n)==n then return n end
  return nil
end

local function world_discovered(force,site)
  local tech=force and force.technologies
    and force.technologies["planet-discovery-"..site]
  local planet=game and game.planets and game.planets[site]
  return planet~=nil and tech and tech.researched==true
end

-- Only source-installed, actually researched destination planets appear.
-- Techs may be unresearched; those recipes remain preview-only.
function M.catalog(force)
  local result={}
  for _,row in ipairs(industry.snapshot(force,MAX_ROWS).entries) do
    if world_discovered(force,row.site) then
      result[#result+1]=row
    end
  end
  return result
end

function M.recipe(force,id)
  if type(id)~="string" then return nil end
  for _,row in ipairs(M.catalog(force)) do
    if row.quest.tech==id then return row end
  end
  return nil
end

-- This determines ROUTE AVAILABILITY only, not where any item is made.
-- Original directed IDs are validated again against Orbital Catapult's
-- real configured link manifest before displaying a source choice.
function M.inbound(force,destination)
  local result={}
  if type(destination)~="string" then return result end
  local network=routes.snapshot(force)
  for _,entry in ipairs(network.entries or {}) do
    if entry.state=="researched" and entry.source_researched
      and entry.target_researched
      and (entry.source==destination or entry.target==destination) then
      local source=entry.source==destination and entry.target or entry.source
      local id="razi-"..source.."-"..destination.."-catapult"
      local route=freight.route(force,id)
      if route and route.target==destination and route.source==source then
        result[#result+1]=route
      end
    end
  end
  table.sort(result,function(a,b)return a.id<b.id end)
  return result
end

-- No estimates for probabilistic / ranged / fractional item inputs.
-- Fluids remain visible for planning but are never put in item freight.
function M.ingredients(recipe,batches)
  local amount=M.batches(batches)
  if not (recipe and amount) then return {} end
  local list={}
  local found={}
  for _,ingredient in pairs(recipe.ingredients or {}) do
    local name=ingredient.name
    local kind=ingredient.type=="fluid" and "fluid" or "item"
    if type(name)=="string" then
      local key=kind..":"..name
      local row=found[key]
      if not row then
        row={name=name,kind=kind,count=0,plannable=true}
        found[key]=row
        list[#list+1]=row
      end
      local n=ingredient.amount
      if not (type(n)=="number" and n>0 and n==n
        and not ingredient.amount_min and not ingredient.amount_max
        and (not ingredient.probability or ingredient.probability==1)) then
        row.plannable=false
      else
        row.count=row.count+n*amount
      end
      if kind~="item" then row.plannable=false end
    end
  end
  for _,row in ipairs(list) do
    row.plannable=row.plannable and row.count>0
      and freight.positive_count(row.count)~=nil
      and prototypes and prototypes.item
      and prototypes.item[row.name]~=nil or false
    if row.plannable then row.stacks=freight.stacks(row.name,row.count) end
  end
  table.sort(list,function(a,b)
    if a.kind~=b.kind then return a.kind<b.kind end
    return a.name<b.name
  end)
  return list
end

-- Compute expected recipe outputs only when deterministic; do not claim
-- machine throughput, bonuses from quality or a running factory.
function M.outputs(recipe,batches)
  local amount=M.batches(batches)
  local result={}
  if not (recipe and amount) then return result end
  for _,product in pairs(recipe.products or {}) do
    if product.name and type(product.amount)=="number"
      and product.amount>0 and not product.amount_min
      and not product.amount_max
      and (not product.probability or product.probability==1) then
      result[#result+1]={name=product.name,
        kind=product.type=="fluid" and "fluid" or "item",
        count=product.amount*amount}
    end
  end
  table.sort(result,function(a,b)return a.name<b.name end)
  return result
end

local function confirmed_recipe(player,recipe_id,route_id)
  if not (player and player.force) then return nil end
  local row=M.recipe(player.force,recipe_id)
  if not (row and row.technology and row.technology.researched) then
    return nil
  end
  for _,option in ipairs(M.inbound(player.force,row.site)) do
    if option.id==route_id then return row end
  end
  return nil
end

function M.plan_all(player,recipe_id,route_id,batches)
  local row=confirmed_recipe(player,recipe_id,route_id)
  if not (row and M.batches(batches)) then return false end
  local specs={}
  for _,ingredient in ipairs(M.ingredients(row.recipe,batches)) do
    if ingredient.plannable and ingredient.kind=="item" then
      specs[#specs+1]={item=ingredient.name,count=ingredient.count}
    end
  end
  if #specs==0 then return false end
  return freight.add_many(player,route_id,specs)
end

function M.plan(player,recipe_id,route_id,item_name,batches)
  if type(item_name)~="string" then return false end
  local row=confirmed_recipe(player,recipe_id,route_id)
  if not row then return false end
  for _,ingredient in ipairs(M.ingredients(row.recipe,batches)) do
    if ingredient.name==item_name and ingredient.kind=="item"
      and ingredient.plannable then
      return freight.add_spec(player,route_id,item_name,ingredient.count)
    end
  end
  return false
end

local function wrap(parent,caption,width,bold,color)
  local l=parent.add{type="label",caption=caption}
  l.style.single_line=false
  l.style.maximal_width=math.max(120,width)
  l.style.font=bold and "default-bold" or "default"
  l.style.font_color=color or SOFT
  return l
end
local function name(world)
  local proto=prototypes and prototypes.space_location
    and prototypes.space_location[world]
  return proto and proto.localised_name or world
end
local function material(row)
  local pool=prototypes and (row.kind=="fluid" and prototypes.fluid
    or prototypes.item)
  local proto=pool and pool[row.name]
  return proto and proto.localised_name or row.name
end

function M.render(parent,player,p,width)
  local options=M.catalog(player.force)
  wrap(parent,L("supply-intro"),width)
  if #options==0 then
    wrap(parent,L("supply-empty"),width)
    return
  end
  local index=1
  for i,row in ipairs(options) do
    if row.quest.tech==p.supply_recipe then index=i;break end
  end
  local current=options[index]
  p.supply_recipe=current.quest.tech
  local editor=parent.add{type="frame",direction="vertical",
    style="inside_shallow_frame"}
  editor.style.horizontally_stretchable=true
  editor.style.padding=8
  wrap(editor,L("supply-factory-heading"),width-36,true,GOLD)
  local item_names={}
  for _,row in ipairs(options) do
    item_names[#item_names+1]=row.recipe.localised_name
  end
  local select=editor.add{type="drop-down",
    items=item_names,selected_index=index,
    tags={razi_ops_action="supply-recipe"}}
  select.style.minimal_width=math.max(175,math.min(width-80,420))
  wrap(editor,L("supply-factory-destination",name(current.site)),width-36)
  local researched=current.technology and current.technology.researched
  wrap(editor,L(researched and "supply-research-ready"
    or "supply-research-locked"),width-36,false,
    researched and {r=.56,g=.81,b=.67} or GOLD)
  local row=editor.add{type="flow",direction=width<670 and "vertical"
    or "horizontal"}
  row.style.vertical_align="center"
  row.style.horizontal_spacing=8
  wrap(row,L("supply-batches-heading"),150,true,INK)
  local batch=M.batches(p.supply_batches)
  local input=row.add{type="textfield",text=batch and tostring(batch) or "",
    numeric=true,allow_decimal=false,allow_negative=false,
    tags={razi_ops_action="supply-batches"}}
  input.style.width=90
  row.add{type="button",caption=L("supply-recalculate"),
    tags={razi_ops_action="supply-recalculate"}}
  if not batch then
    wrap(editor,L("supply-invalid-batches"),width-36)
    return
  end
  wrap(editor,L("supply-batch-limits",tostring(MAX_BATCHES)),width-36)
  local incoming=M.inbound(player.force,current.site)
  wrap(editor,L("supply-route-heading"),width-36,true,GOLD)
  if #incoming==0 then
    p.supply_route=nil
    wrap(editor,L("supply-no-direct-route"),width-36)
  else
    local chosen=false
    for _,route in ipairs(incoming) do
      if route.id==p.supply_route then chosen=true end
    end
    if not chosen then p.supply_route=incoming[1].id end
    for _,route in ipairs(incoming) do
      local active=route.id==p.supply_route
      local button=editor.add{type="button",
        caption=L("supply-route-choice",name(route.source),
          name(route.target)),
        tags={razi_ops_action="supply-route",value=route.id}}
      button.style.font=active and "default-bold" or "default"
      button.style.font_color=active and GOLD or SOFT
    end
    wrap(editor,L("supply-source-disclaimer"),width-36)
  end
  local outputs=M.outputs(current.recipe,batch)
  if #outputs>0 then
    wrap(parent,L("supply-output-heading"),width,true,GOLD)
    for _,product in ipairs(outputs) do
      local material=material(product)
      wrap(parent,L("supply-output-row",material,
        tostring(product.count)),width-35)
    end
  end
  local ingredients=M.ingredients(current.recipe,batch)
  wrap(parent,L("supply-materials-heading"),width,true,GOLD)
  if #ingredients==0 then wrap(parent,L("supply-no-ingredients"),width) end
  local max=math.min(#ingredients,24)
  for i=1,max do
    local item=ingredients[i]
    local card=parent.add{type="flow",direction="vertical"}
    card.style.vertical_spacing=3
    local amount=item.count>0 and tostring(item.count)
      or L("supply-unknown-amount")
    wrap(card,L("supply-material-row",material(item),amount,
      item.kind=="fluid" and L("supply-fluid") or
      L("supply-item")),width-30,true,INK)
    if item.plannable then
      wrap(card,L("supply-material-stacks",
        tostring(item.stacks or 0)),width-35)
      if researched and p.supply_route then
        card.add{type="button",
          caption=L("supply-create-plan"),
          tags={razi_ops_action="supply-plan",value=item.name}}
      end
    else
      wrap(card,L("supply-material-manual"),width-35)
    end
  end
  if #ingredients>max then
    wrap(parent,L("supply-truncated",tostring(#ingredients-max)),width)
  end
  local suitable=0
  for _,ingredient in ipairs(ingredients) do
    if ingredient.plannable then suitable=suitable+1 end
  end
  if researched and p.supply_route and suitable>0 then
    parent.add{type="button",
      caption=L("supply-plan-all",tostring(suitable)),
      tooltip=L("supply-plan-all-help"),
      tags={razi_ops_action="supply-plan-all"}}
  end
  wrap(parent,L("supply-footer"),width)
  parent.add{type="button",caption=L("supply-open-freight"),
    tags={razi_ops_action="supply-freight"}}
end
return M
