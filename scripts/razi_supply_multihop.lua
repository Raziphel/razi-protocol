-- A.6: Manual multi-hop supply itinerary proposals. Does NOT schedule
-- space platforms, reserve stock, or claim operational service/delivery.
-- Runtime graph + factory validation is authoritative for every save action.
local M={}
local graph_module=require("scripts.razi_supply_routes")
local supply=require("scripts.razi_supply_planner")
local operations=require("scripts.razi_shipment_operations")
local handoff=require("scripts.razi_shipment_handoff")
local MAX_PLANS=12
local MAX_MATERIALS=24
local L=function(key,...) return {"razi-ops."..key,...} end

local function store(index)
  storage.razi_supply_itineraries=storage.razi_supply_itineraries or {}
  local all=storage.razi_supply_itineraries
  if not all[index] then
    all[index]={plans={},next_id=1}
  end
  return all[index]
end
function M.cleanup(index)
  if storage.razi_supply_itineraries then
    storage.razi_supply_itineraries[index]=nil
  end
end

local function choices(force,destination,graph)
  graph=graph or graph_module.graph(force)
  return graph_module.origins(graph,destination),graph
end

local function eligible(row,batches,item)
  local result={}
  for _,material in ipairs(supply.ingredients(row.recipe,batches)) do
    if material.plannable and (not item or item==material.name) then
      result[#result+1]={name=material.name,count=material.count}
    end
  end
  if item and #result~=1 then return nil end
  if #result==0 or #result>MAX_MATERIALS then return nil end
  return result
end

function M.save(player,preferences,item)
  if not (player and player.index and player.force and preferences
    and (item==nil or type(item)=="string")) then return false end
  local row=supply.recipe(player.force,preferences.supply_recipe)
  local batches=supply.batches(preferences.supply_batches)
  if not (row and row.technology and row.technology.researched
    and row.recipe_enabled and batches) then return false end
  local graph=graph_module.graph(player.force)
  local origins=choices(player.force,row.site,graph)
  local origin=preferences.supply_origin
  local accepted=false
  for _,world in ipairs(origins) do
    if world==origin then accepted=true;break end
  end
  if not accepted then return false end
  local paths=graph_module.paths(graph,origin,row.site)
  local index=preferences.supply_path or 1
  if type(index)~="number" or index~=math.floor(index)
    or index<1 or index>#paths then return false end
  local itinerary=paths[index]
  -- An index alone is not proof that the route shown when clicked still
  -- exists. A mod/research change can reorder alternatives on the next tick.
  if not (itinerary and preferences.supply_path_key==itinerary.key)
    or not graph_module.valid_path(graph,itinerary) then return false end
  local materials=eligible(row,batches,item)
  if not materials then return false end
  local data=store(player.index)
  if #data.plans>=MAX_PLANS then return false end
  local path={}
  for _,leg in ipairs(itinerary.legs) do
    path[#path+1]={from=leg.from,to=leg.to,mode=leg.mode,
      id=leg.id,km=leg.km}
  end
  -- Store only primitive values; never stash LuaRecipes or prototype refs.
  data.plans[#data.plans+1]={
    id=data.next_id,recipe=row.quest.tech,origin=origin,
    destination=row.site,batches=batches,selected_item=item,legs=path,
    materials=materials,tick=game and game.tick or 0
  }
  data.next_id=data.next_id+1
  return true
end

function M.remove(player,id)
  if not (player and player.index and type(id)=="number") then return false end
  local data=store(player.index)
  for i,plan in ipairs(data.plans) do
    if plan.id==id then table.remove(data.plans,i);return true end
  end
  return false
end

-- Merely recording the manifest never stages source Catapult freight or
-- schedules any platform. Re-check worlds and edges on EACH rendering.
function M.visible(player,graph)
  local records=store(player.index).plans
  local result={}
  -- One portfolio snapshot for the entire bounded list rather than one
  -- full factory catalog rebuild for every saved itinerary.
  local catalog={}
  for _,recipe in ipairs(supply.catalog(player.force)) do
    catalog[recipe.quest.tech]=recipe
  end
  for _,plan in ipairs(records) do
    local recipe=catalog[plan.recipe]
    local path={legs=plan.legs}
    local revealed=recipe and recipe.site==plan.destination
      and recipe.technology and recipe.technology.researched
      and recipe.recipe_enabled and supply.batches(plan.batches)
      and graph_module.valid_path(graph,path)
      and plan.legs[1].from==plan.origin
      and plan.legs[#plan.legs].to==plan.destination
    -- Upstream recipe rebalance/removal must invalidate stale quantities.
    -- Never show a "current" bill of materials with old source costs.
    if revealed then
      local current={}
      local expected=0
      for _,part in ipairs(supply.ingredients(
          recipe.recipe,plan.batches)) do
        if part.plannable and (not plan.selected_item
          or part.name==plan.selected_item) then
          current[part.name]=part.count
          expected=expected+1
        end
      end
      local materials=plan.materials
      if type(materials)~="table" or #materials~=expected
        or expected==0 or expected>MAX_MATERIALS then
        revealed=false
      else
        local seen={}
        for _,part in ipairs(materials) do
          if type(part)~="table" or type(part.name)~="string"
            or seen[part.name] or current[part.name]~=part.count
            or not (prototypes and prototypes.item
              and prototypes.item[part.name]) then
            revealed=false
            break
          end
          seen[part.name]=true
        end
      end
    end
    result[#result+1]={id=plan.id,valid=revealed==true,
      plan=revealed and plan or nil}
  end
  return result
end

function M.toggle_details(player,p,id)
  if not (player and p and type(id)=="number") then return false end
  local graph=graph_module.graph(player.force)
  local found=false
  for _,entry in ipairs(M.visible(player,graph)) do
    if entry.id==id and entry.valid then found=true;break end
  end
  if not found then return false end
  p.supply_expanded=p.supply_expanded==id and nil or id
  return true
end

local function wrap(parent,caption,width,bold,color)
  local l=parent.add{type="label",caption=caption}
  l.style.single_line=false
  l.style.maximal_width=math.max(120,width)
  l.style.font=bold and "default-bold" or "default"
  if color then l.style.font_color=color end
  return l
end
local function name(world)
  local proto=prototypes and prototypes.space_location
    and prototypes.space_location[world]
  return proto and proto.localised_name or world
end
local function heading(parent,caption,width)
  return wrap(parent,caption,width,true,{r=.82,g=.69,b=.48})
end
local function step(parent,leg,width)
  wrap(parent,L(leg.mode=="catapult" and "supply-hop-catapult"
    or "supply-hop-platform",name(leg.from),name(leg.to)),width)
  if leg.mode=="platform" and type(leg.km)=="number" then
    wrap(parent,L("supply-hop-distance",tostring(leg.km)),width)
  end
end

function M.render(parent,player,p,width,current)
  if not current then return end
  local region=parent.add{type="frame",
    style="inside_shallow_frame",direction="vertical"}
  region.style.horizontally_stretchable=true
  region.style.padding=9
  heading(region,L("supply-multihop-title"),width-40)
  wrap(region,L("supply-multihop-intro"),width-40)
  local graph=graph_module.graph(player.force)
  local origins=choices(player.force,current.site,graph)
  if graph.limited then
    wrap(region,L("supply-multihop-limited"),width-45)
  end
  if #origins==0 then
    wrap(region,L("supply-multihop-no-origins"),width-45)
  else
    local current_index=1
    for i,world in ipairs(origins) do
      if world==p.supply_origin then current_index=i;break end
    end
    p.supply_origin=origins[current_index]
    local list={}
    for _,world in ipairs(origins) do list[#list+1]=name(world) end
    heading(region,L("supply-multihop-origin"),width-45)
    local select=region.add{type="drop-down",items=list,
      selected_index=current_index,
      tags={razi_ops_action="supply-origin"}}
    select.style.minimal_width=math.max(170,math.min(width-80,360))
    wrap(region,L("supply-multihop-origin-disclaimer"),width-45)
    local paths=graph_module.paths(graph,p.supply_origin,current.site)
    if #paths==0 then
      wrap(region,L("supply-multihop-no-path"),width-45)
    else
      local selected=p.supply_path
      if type(selected)~="number" or selected<1
        or selected>#paths then selected=1 end
      p.supply_path=selected
      -- A changed graph never silently grants authorization to a
      -- different path that now occupies the same numeric selection.
      if p.supply_path_key and p.supply_path_key~=paths[selected].key then
        p.supply_path_key=nil
      end
      heading(region,L("supply-multihop-alternatives",
        tostring(#paths)),width-45)
      for index,path in ipairs(paths) do
        local chosen=index==selected
        local btn=region.add{type="button",
          caption=L("supply-multihop-choice",tostring(index),
            tostring(#path.legs),tostring(path.switches),
            tostring(path.platform_legs)),
          tags={razi_ops_action="supply-path",value=index}}
        btn.style.font=chosen and "default-bold" or "default"
        if chosen then btn.style.font_color={r=.82,g=.69,b=.48} end
      end
      local chosen=paths[selected]
      if not p.supply_path_key then
        wrap(region,L("supply-multihop-confirm-path"),width-45)
      end
      local route=region.add{type="flow",direction="vertical"}
      route.style.vertical_spacing=3
      heading(route,L("supply-multihop-legs"),width-45)
      for index,leg in ipairs(chosen.legs) do
        step(route,leg,width-52)
        if index<#chosen.legs and leg.mode~=chosen.legs[index+1].mode then
          wrap(route,L("supply-multihop-transfer"),width-55)
        end
      end
      wrap(region,L("supply-multihop-platform-km",
        tostring(chosen.platform_km)),width-45)
      wrap(region,L("supply-multihop-no-guarantees"),width-45)
      if p.supply_path_key==chosen.key and current.technology
        and current.technology.researched
        and current.recipe_enabled and supply.batches(p.supply_batches) then
        region.add{type="button",caption=L("supply-itinerary-save-all"),
          tags={razi_ops_action="supply-itinerary-save-all"}}
      else
        wrap(region,L("supply-itinerary-research-needed"),width-45)
      end
    end
  end

  local saved=M.visible(player,graph)
  local archive=parent.add{type="flow",direction="vertical"}
  archive.style.vertical_spacing=4
  heading(archive,L("supply-itinerary-list",
    tostring(#saved),tostring(MAX_PLANS)),width)
  if #saved==0 then wrap(archive,L("supply-itinerary-empty"),width) end
  for _,entry in ipairs(saved) do
    local lane=archive.add{type="frame",
      style="inside_shallow_frame",direction="vertical"}
    lane.style.horizontally_stretchable=true
    lane.style.padding=7
    if entry.valid then
      local plan=entry.plan
      wrap(lane,L("supply-itinerary-entry",
        name(plan.origin),name(plan.destination),
        tostring(#plan.legs),tostring(#plan.materials)),width-40,true)
      local logged=operations.progress(plan)
      if logged then
        wrap(lane,L("supply-operation-compact",
          tostring(logged.received),tostring(logged.total)),width-42)
      end
      local expanded=p.supply_expanded==plan.id
      lane.add{type="button",caption=L(expanded and
        "supply-itinerary-collapse" or "supply-itinerary-expand"),
        tags={razi_ops_action="supply-itinerary-toggle",value=entry.id}}
      if expanded then
        heading(lane,L("supply-multihop-legs"),width-45)
        for index,leg in ipairs(plan.legs) do
          step(lane,leg,width-48)
          if index<#plan.legs
            and leg.mode~=plan.legs[index+1].mode then
            wrap(lane,L("supply-multihop-transfer"),width-48)
          end
        end
        for _,material in ipairs(plan.materials) do
          local prototype=prototypes and prototypes.item
            and prototypes.item[material.name]
          wrap(lane,L("supply-itinerary-material",
            prototype and prototype.localised_name or material.name,
            tostring(material.count)),width-48)
        end
        operations.render(lane,player,plan,width-42)
        handoff.render(lane,player,p,plan,width-42)
      end
    else
      wrap(lane,L("supply-itinerary-inaccessible"),width-42)
    end
    lane.add{type="button",caption=L("supply-itinerary-remove"),
      tags={razi_ops_action="supply-itinerary-remove",value=entry.id}}
  end
end
return M
