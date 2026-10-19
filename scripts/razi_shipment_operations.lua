-- A.7: operator-authored shipment notes, not actual transport telemetry.
local M={}
local L=function(k,...) return {"razi-ops."..k,...} end
local MAX_LEGS=6
local function label(parent,value,width,bold)
  local l=parent.add{type="label",caption=value}
  l.style.single_line=false
  l.style.maximal_width=math.max(120,width)
  if bold then l.style.font="default-bold" end
  return l
end
local function world(id)
  local p=prototypes and prototypes.space_location
    and prototypes.space_location[id]
  return p and p.localised_name or id
end
-- Every departure and arrival is an explicit player statement. No source
-- event may advance this notebook, and finished does not mean delivered.
function M.progress(plan)
  if not (plan and type(plan.legs)=="table" and #plan.legs>=1
    and #plan.legs<=MAX_LEGS) then return nil end
  local entries=plan.operation_events or {}
  if type(entries)~="table" or #entries>#plan.legs*2 then return nil end
  for i,e in ipairs(entries) do
    local expected=i%2==1 and "depart" or "arrive"
    if type(e)~="table" or e.leg~=math.floor((i+1)/2)
      or e.kind~=expected or type(e.tick)~="number" then
      return nil
    end
  end
  local received=math.floor(#entries/2)
  local done=received==#plan.legs
  return {entries=entries,received=received,total=#plan.legs,
    done=done,leg=done and nil or received+1,
    next_action=done and nil or (#entries%2==0 and "depart" or "arrive")}
end
-- The graph, native recipe, force research and materials are revalidated
-- for EVERY mutation; GUI plan IDs are never authoritative.
local function authorized(player,id)
  if not (player and player.index and player.force
    and type(id)=="number" and id>=1 and id==math.floor(id)) then
    return nil
  end
  local multi=require("scripts.razi_supply_multihop")
  local routes=require("scripts.razi_supply_routes")
  for _,entry in ipairs(multi.visible(player,routes.graph(player.force))) do
    if entry.id==id and entry.valid then return entry.plan end
  end
end
function M.change(player,id,action)
  if action~="depart" and action~="arrive" and action~="undo" then
    return false
  end
  local plan=authorized(player,id)
  local p=M.progress(plan)
  if not p then return false end
  if action=="undo" then
    if #p.entries==0 then return false end
    table.remove(p.entries)
    plan.operation_events=p.entries
    return true
  end
  if p.done or action~=p.next_action then return false end
  local events=p.entries
  events[#events+1]={leg=p.leg,kind=action,
    tick=game and type(game.tick)=="number" and game.tick or 0}
  plan.operation_events=events
  return true
end
local function hardware(leg,sites)
  if leg.mode=="catapult" then
    local a=sites[leg.from] and sites[leg.from].launcher_count
    local b=sites[leg.to] and sites[leg.to].launcher_count
    if a==nil or b==nil then
      return L("supply-operation-hardware-unknown")
    end
    return L("supply-operation-catapult-candidates",
      tostring(a),world(leg.from),tostring(b),world(leg.to))
  end
  local source=sites[leg.from]
  if not (source and source.platforms~=nil) then
    return L("supply-operation-platform-unknown",world(leg.from))
  end
  if source.platforms==0 then
    return L("supply-operation-platform-none",world(leg.from))
  end
  return L("supply-operation-platform-candidates",
    tostring(source.platforms),world(leg.from),
    tostring(source.unscheduled or 0))
end
-- Called ONLY for an expanded and source-validated manifest; max seven
-- waypoints and one native observation, never any tick-time polling.
function M.render(parent,player,plan,width)
  local p=M.progress(plan)
  if not p then label(parent,L("supply-operation-invalid"),width);return end
  local box=parent.add{type="frame",style="inside_shallow_frame",
    direction="vertical"}
  box.style.horizontally_stretchable=true
  box.style.padding=7
  label(box,L("supply-operation-heading"),width-16,true)
  label(box,L("supply-operation-caution"),width-16)
  label(box,L("supply-operation-progress",
    tostring(p.received),tostring(p.total)),width-16,true)
  local worlds,seen={},{}
  for _,leg in ipairs(plan.legs) do
    for _,where in ipairs({leg.from,leg.to}) do
      if not seen[where] then seen[where]=true;worlds[#worlds+1]=where end
    end
  end
  local infra=require("scripts.razi_freight_infrastructure")
  local sites=infra.inspect_worlds(player.force,worlds).worlds
  local catapult=require("scripts.razi_catapult_network")
  local receipts=require("scripts.razi_freight_receipts")
  local arrivals=receipts.snapshot(player.force,
    catapult.snapshot(player.force)).worlds
  for i,leg in ipairs(plan.legs) do
    local mode=leg.mode=="catapult" and
      L("supply-operation-catapult") or L("supply-operation-platform")
    label(box,L("supply-operation-leg",tostring(i),
      world(leg.from),world(leg.to),mode),width-20,true)
    local status
    if i<=p.received then
      status=L("supply-operation-received")
    elseif i==p.leg then
      status=L(p.next_action=="arrive" and
        "supply-operation-departed" or "supply-operation-next")
    else
      status=L("supply-operation-waiting")
    end
    label(box,status,width-25)
    label(box,hardware(leg,sites),width-25)
    local observed=arrivals[leg.to]
    if type(observed)=="number" and observed>0 then
      label(box,L("supply-operation-pods",
        world(leg.to),tostring(observed)),width-25)
    end
  end
  for _,entry in ipairs(p.entries) do
    label(box,L(entry.kind=="depart" and
      "supply-operation-event-depart" or "supply-operation-event-arrive",
      tostring(entry.leg),tostring(entry.tick)),width-25)
  end
  if p.done then
    label(box,L("supply-operation-finished"),width-16,true)
  else
    local action=p.next_action
    box.add{type="button",
      caption=L(action=="depart" and "supply-operation-mark-depart"
        or "supply-operation-mark-arrive"),
      tags={razi_ops_action="supply-operation-"..action,value=plan.id}}
  end
  if #p.entries>0 then
    box.add{type="button",caption=L("supply-operation-undo"),
      tags={razi_ops_action="supply-operation-undo",value=plan.id}}
  end
end
return M
