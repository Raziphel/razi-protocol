-- A.9: Explicit, guarded handoff from a validated itinerary to A.1
-- Freight Desk. NEVER performs native item transfer, launch or dispatch.
-- Review and confirm are distinct clicks; neither trusts unvalidated tags.
local M={}
local L=function(k,...) return {"razi-ops."..k,...} end
local REVIEW_TICKS=3600
local MAX_ITEMS=20

local function now()
  return game and type(game.tick)=="number" and game.tick or 0
end
local function freight() return require("scripts.razi_freight_orders") end
local function route_graph()
  return require("scripts.razi_supply_routes")
end
local function multi()
  return require("scripts.razi_supply_multihop")
end
local function operations()
  return require("scripts.razi_shipment_operations")
end
local function label(parent,key,width,...)
  local node=parent.add{type="label",caption=L(key,...)}
  node.style.single_line=false
  node.style.maximal_width=math.max(120,width-20)
  return node
end
local function prepared(player,id)
  if not (player and player.index and player.force
    and type(id)=="number" and id>=1 and id==math.floor(id)) then
    return nil
  end
  -- One catalog read across the bounded list, including current source
  -- recipe inputs and current discovered route graph.
  local graph=route_graph().graph(player.force)
  local candidate
  for _,entry in ipairs(multi().visible(player,graph)) do
    if entry.id==id and entry.valid then
      candidate=entry.plan
      break
    end
  end
  if not candidate then return nil end
  local status=operations().progress(candidate)
  if not (status and not status.done and status.next_action=="depart"
    and status.leg and status.leg<=#candidate.legs) then
    return nil
  end
  local leg=candidate.legs[status.leg]
  if not (leg and leg.mode=="catapult" and type(leg.id)=="string") then
    return nil
  end
  local existing=candidate.freight_handoffs
  if type(existing)=="table" and existing[status.leg] then return nil end
  local real=freight().route(player.force,leg.id)
  if not (real and real.id==leg.id
    and real.source==leg.from and real.target==leg.to) then return nil end
  -- The character must actually be on the source planet. Selecting a
  -- planned origin is not evidence of presence or stocked launchers.
  local surface=player.physical_surface
  local planet=surface and surface.planet
  if not (planet and planet.name==leg.from
    and player.get_item_count) then return nil end
  local materials=candidate.materials
  if not (type(materials)=="table" and #materials>=1
    and #materials<=MAX_ITEMS) then return nil end
  local specs,totals={},{}
  for _,row in ipairs(materials) do
    local item=row and row.name
    local amount=row and freight().positive_count(row.count)
    if not (type(item)=="string" and amount and
      prototypes and prototypes.item and prototypes.item[item]) then
      return nil
    end
    if not totals[item] then
      specs[#specs+1]={item=item,count=0}
      totals[item]=#specs
    end
    local pos=totals[item]
    local total=specs[pos].count+amount
    if not freight().positive_count(total) then return nil end
    specs[pos].count=total
  end
  if #specs==0 or #specs>MAX_ITEMS then return nil end
  local short={}
  for _,row in ipairs(specs) do
    local stock=player.get_item_count(row.item)
    if type(stock)~="number" or stock<row.count then
      short[#short+1]={item=row.item,
        needed=row.count,held=math.max(0,type(stock)=="number" and stock or 0)}
    end
  end
  -- Stable hash-like signature of all primitive source inputs, not a
  -- secret. Authorization comes from recomputing the real plan each time.
  local parts={tostring(candidate.id),candidate.recipe,
    tostring(candidate.batches),tostring(status.leg),leg.id,
    leg.from,leg.to}
  for _,row in ipairs(specs) do
    parts[#parts+1]=row.item..":"..tostring(row.count)
  end
  return {plan=candidate,leg=status.leg,route=real,
    specs=specs,short=short,key=table.concat(parts,"|")}
end

-- Only a real button action starts/replaces a short-lived review.
function M.review(player,p,id)
  if not (p and p.supply_expanded==id) then return false end
  local proposal=prepared(player,id)
  if not proposal or #proposal.short~=0 then
    p.supply_handoff=nil
    return false
  end
  p.supply_handoff={id=id,leg=proposal.leg,
    key=proposal.key,tick=now()}
  return true
end

function M.confirm(player,p,id)
  if not (p and p.supply_expanded==id) then return false end
  local review=p.supply_handoff
  -- Consume the review regardless of outcome. Double clicking cannot
  -- reuse a token even if the event arrives in the same tick.
  p.supply_handoff=nil
  if not (type(review)=="table" and review.id==id
    and type(review.tick)=="number" and now()>=review.tick
    and now()-review.tick<=REVIEW_TICKS) then return false end
  local proposal=prepared(player,id)
  if not (proposal and proposal.leg==review.leg
    and proposal.key==review.key and #proposal.short==0) then
    return false
  end
  -- A.1 atomically validates current native directed route, every item
  -- prototype/count and available 20-order slots BEFORE adding anything.
  if not freight().add_many(player,proposal.route.id,proposal.specs) then
    return false
  end
  local plan=proposal.plan
  plan.freight_handoffs=plan.freight_handoffs or {}
  plan.freight_handoffs[proposal.leg]={
    route=proposal.route.id,tick=now(),count=#proposal.specs
  }
  return true
end

-- Called only within an expanded and source-validated A.6 record.
-- No player stock scan for collapsed/invalidated manifests.
function M.render(parent,player,p,plan,width)
  local handoffs=plan.freight_handoffs or {}
  local step=operations().progress(plan)
  if not step or step.done then return end
  local leg=plan.legs[step.leg]
  if not leg or leg.mode~="catapult" then return end
  label(parent,"handoff-heading",width)
  if handoffs[step.leg] then
    label(parent,"handoff-already-staged",width,
      tostring(handoffs[step.leg].count))
    return
  end
  if step.next_action~="depart" then
    label(parent,"handoff-departed",width)
    return
  end
  local candidate=prepared(player,plan.id)
  if not candidate then
    label(parent,"handoff-unavailable",width)
    return
  end
  label(parent,"handoff-readiness",width,
    tostring(#candidate.specs),tostring(#candidate.short))
  label(parent,"handoff-disclaimer",width)
  if #candidate.short>0 then
    for _,missing in ipairs(candidate.short) do
      local proto=prototypes.item[missing.item]
      local item=proto and proto.localised_name or missing.item
      label(parent,"handoff-shortfall",width,item,
        tostring(missing.held),tostring(missing.needed))
    end
    return
  end
  local review=p.supply_handoff
  if type(review)=="table" and review.id==plan.id
    and review.leg==candidate.leg and review.key==candidate.key
    and type(review.tick)=="number" and now()>=review.tick
    and now()-review.tick<=REVIEW_TICKS then
    parent.add{type="button",caption=L("handoff-confirm"),
      tags={razi_ops_action="supply-handoff-confirm",value=plan.id}}
  else
    parent.add{type="button",caption=L("handoff-review"),
      tags={razi_ops_action="supply-handoff-review",value=plan.id}}
  end
end
return M
