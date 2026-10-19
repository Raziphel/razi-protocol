-- A.9: two-step, physically local, atomic manual freight staging.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,msg) if not ok then error(msg,2) end end
storage={}
game={tick=100}
local route_enabled=true
local visible=true
local tech_ready=true
local source="muria"
local stock={["iron-plate"]=40,["copper-plate"]=10}
local leg={from="muria",to="rubia",mode="catapult",id="razi-muria-rubia-catapult"}
local plan={id=5,recipe="ra-recipe",batches=2,origin="muria",
  materials={{name="iron-plate",count=30},
             {name="copper-plate",count=8}},
  legs={leg}}
local status={leg=1,done=false,next_action="depart"}
local player={index=3,force={index=1},get_item_count=function(item)
  return stock[item] or 0 end}
local pref={supply_expanded=5}
local queued={}
local add_calls=0
local capacity=true
local freight={
 route=function(_,id)
  if route_enabled and id==leg.id then
    return {id=leg.id,source=leg.from,target=leg.to}
  end
 end,
 positive_count=function(n)
  return type(n)=="number" and n==math.floor(n)
    and n>=1 and n<=1000000 and n or nil
 end,
 add_many=function(_,id,specs)
  add_calls=add_calls+1
  if not capacity or id~=leg.id then return false end
  for _,v in ipairs(specs) do
    queued[#queued+1]={route=id,item=v.item,count=v.count}
  end
  return true
 end
}
package.loaded["scripts.razi_freight_orders"]=freight
package.loaded["scripts.razi_supply_routes"]={graph=function() return {} end}
package.loaded["scripts.razi_supply_multihop"]={
 visible=function()
  return {{id=5,valid=visible and tech_ready,
    plan=visible and tech_ready and plan or nil}}
 end}
package.loaded["scripts.razi_shipment_operations"]={
 progress=function() return status end}
prototypes={item={
 ["iron-plate"]={localised_name="Iron"},
 ["copper-plate"]={localised_name="Copper"}}}
player.physical_surface={planet={name=source}}
local M=require("scripts.razi_shipment_handoff")
check(not M.confirm(player,pref,5),"Confirmation requires explicit review")
check(not M.review(player,{supply_expanded=99},5),
 "Hidden/collapsed itinerary must not authorize staging")
check(M.review(player,pref,5),"Visible local plan can be reviewed")
check(#queued==0 and add_calls==0,
 "Review is non-mutating and cannot dispatch items")
check(M.confirm(player,pref,5),"Second click stages guarded orders")
check(#queued==2 and queued[1].count==30 and queued[2].count==8
 and plan.freight_handoffs[1].count==2,
 "Staged native directed route and exact ingredient quantities")
check(not M.confirm(player,pref,5) and not M.review(player,pref,5),
 "Consumed review and handoff marker prevent duplicate orders")
check(add_calls==1,"Duplicate clicks do not call order creation")
-- New authorized itinerary, but no stock on the departure world.
plan.freight_handoffs=nil
source="aquilo"
player.physical_surface={planet={name=source}}
check(not M.review(player,pref,5),
 "Physically remote players cannot stage source-world orders")
source="muria"
player.physical_surface={planet={name=source}}
stock["iron-plate"]=29
check(not M.review(player,pref,5),
 "Carried stock must satisfy every ingredient of the selected leg")
stock["iron-plate"]=40
check(M.review(player,pref,5),"Stock restore permits new review")
game.tick=3701
check(not M.confirm(player,pref,5),
 "Old confirmation cannot be used after 3600 ticks")
game.tick=4000
check(M.review(player,pref,5),"Fresh confirmation allowed")
route_enabled=false
check(not M.confirm(player,pref,5),
 "Removed source Catapult link rejects reviewed authorization")
route_enabled=true
check(M.review(player,pref,5),"Restore source route and review")
tech_ready=false
check(not M.confirm(player,pref,5),
 "Research rollback rejects previously reviewed route")
tech_ready=true
check(M.review(player,pref,5),"Current researched recipe allows review")
plan.materials[1].count=31
check(not M.confirm(player,pref,5),
 "Changed source quantities invalidate the handoff token")
plan.materials[1].count=30
check(M.review(player,pref,5),"Source materials restored")
capacity=false
check(not M.confirm(player,pref,5)
 and plan.freight_handoffs==nil,
 "Exhausted queue causes no handoff marker or staged orders")
capacity=true
check(M.review(player,pref,5),"Queue capacity restored")
status.next_action="arrive"
check(not M.confirm(player,pref,5),
 "Already departed leg cannot be staged with an old review")
status.next_action="depart"
check(M.review(player,pref,5),"Source-revalidated review works again")
local tags={}
local function gui()
 local node={style={},children={}}
 function node.add(spec)
  local c=gui()
  c.spec=spec
  node.children[#node.children+1]=c
  if spec.tags and spec.tags.razi_ops_action then
    tags[spec.tags.razi_ops_action]=true
  end
  return c
 end
 return node
end
M.render(gui(),player,pref,plan,600)
check(tags["supply-handoff-confirm"],
 "Current review is exposed by a real confirm button")
check(M.confirm(player,pref,5),"Final current handoff stages successfully")
check(plan.freight_handoffs[1].count==2,
 "Only a successful atomic Freight Desk add gets a handoff marker")
check(add_calls==3,
 "Failed queue capacity may attempt one atomic addition, never partial")
print("Razi A.9 guarded itinerary-to-Freight-Desk handoff passed")
