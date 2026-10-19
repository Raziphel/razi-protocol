-- A.5: native recipe quantities and explicit source-route authorisation.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(value,msg) if not value then error(msg,2) end end
local recipe={
 localised_name={"recipe-name.razi-frontier-castra-composite-rounds"},
 ingredients={
  {name="iron-plate",type="item",amount=4},
  {name="iron-plate",type="item",amount=2},
  {name="copper-plate",type="item",amount=3},
  {name="lubricant",type="fluid",amount=20},
  {name="variable-token",type="item",amount_min=1,amount_max=4},
  {name="probability-token",type="item",amount=2,probability=0.5}
 }
}
prototypes={
 item={["iron-plate"]={name="iron-plate",localised_name="Iron",stack_size=100},
   ["copper-plate"]={name="copper-plate",localised_name="Copper",stack_size=100},
   ["variable-token"]={name="variable-token",stack_size=100},
   ["probability-token"]={name="probability-token",stack_size=100}},
 fluid={lubricant={localised_name="Lubricant"}},
 space_location={castra={localised_name="Castra"},vulcanus={localised_name="Vulcanus"}}
}
game={planets={castra={},vulcanus={}}}
local tech={researched=true}
local id="razi-frontier-castra-composite-rounds"
local force={index=1,recipes={[id]={enabled=true}},technologies={
 ["planet-discovery-castra"]={researched=true},
 ["planet-discovery-vulcanus"]={researched=true},
 ["razi-frontier-castra-composite-rounds"]=tech
}}
local row={quest={tech=id},site="castra",recipe=recipe,technology=tech}
package.loaded["scripts.razi_industry_portfolio"]={
 snapshot=function() return {entries={row}} end}
local enabled=true
package.loaded["scripts.razi_catapult_network"]={
 snapshot=function()
  return {entries=enabled and {{
   source="vulcanus",target="castra",state="researched",
   source_researched=true,target_researched=true
  }} or {}}
 end}
local route_id="razi-vulcanus-castra-catapult"
local added={}
package.loaded["scripts.razi_freight_orders"]={
 route=function(_,candidate)
  if enabled and candidate==route_id then
   return {id=route_id,source="vulcanus",target="castra"}
  end
  return nil
 end,
 positive_count=function(v)
  local n=tonumber(v)
  return n and n>=1 and n<=1000000 and n==math.floor(n) and n or nil
 end,
 stacks=function(_,n)return math.ceil(n/100) end,
 add_spec=function(_,rid,item,amount)
  added[#added+1]={route=rid,item=item,count=amount}
  return true
 end,
 add_many=function(_,rid,specs)
  check(rid==route_id and #specs==2,
    "Bulk planning must select only two deterministic item inputs")
  for _,spec in ipairs(specs) do
   added[#added+1]={route=rid,item=spec.item,count=spec.count}
  end
  return true
 end}
local planner=require("scripts.razi_supply_planner")
check(planner.batches("3")==3 and planner.batches("0")==nil
 and planner.batches("1.5")==nil and planner.batches("1001")==nil
 and planner.batches("oops")==nil,
 "Batch counts must be bounded, integral and reject invalid text")
local lines=planner.ingredients(recipe,3)
local index={}
for _,v in ipairs(lines) do index[v.name]=v end
check(index["iron-plate"].count==18
 and index["iron-plate"].plannable and index["iron-plate"].stacks==1,
 "Duplicate item ingredients must combine without invented output")
check(index["copper-plate"].count==9 and index["copper-plate"].plannable,
 "Actual copper recipe quantity must scale with crafts")
check(index.lubricant.count==60 and not index.lubricant.plannable,
 "Real fluid cost visible, but cannot be added as an item shipment")
check(not index["variable-token"].plannable
 and not index["probability-token"].plannable,
 "Probabilistic / ranged items must fail closed")
check(#planner.catalog(force)==1 and planner.recipe(force,id)==row,
 "Only researched destination worlds reveal their installed recipes")
local inbound=planner.inbound(force,"castra")
check(#inbound==1 and inbound[1].source=="vulcanus",
 "Only real surveyed inbound routes may be selected")
check(#planner.inbound(force,"vulcanus")==0,
 "Reverse manufacturing destination cannot forge a source route")
local player={index=2,force=force}
check(planner.plan(player,id,route_id,"iron-plate",3),
 "Validated source-backed materials should create a manual order")
check(#added==1 and added[1].count==18
 and added[1].route==route_id and added[1].item=="iron-plate",
 "Created freight plan must contain exact source ingredient quantity")
check(#planner.outputs({products={{name="machine",type="item",amount=2},
 {name="waste",type="item",amount=1,probability=.5}}},3)==1,
 "Recipe outputs must exclude probabilistic product claims")
check(planner.plan_all(player,id,route_id,3),
 "All eligible deterministic item ingredients should stage together")
check(#added==3 and added[2].item=="copper-plate"
 and added[2].count==9 and added[3].item=="iron-plate"
 and added[3].count==18,
 "Bulk order counts must retain the exact native input quantities")
check(not planner.plan(player,id,"razi-cheat-castra-catapult","iron-plate",3)
 and not planner.plan(player,id,route_id,"lubricant",3)
 and not planner.plan(player,id,route_id,"probability-token",3)
 and not planner.plan(player,id,route_id,"missing",3)
 and not planner.plan(player,id,route_id,"iron-plate",0),
 "Forged route, fluid, probabilistic, missing or invalid batch must fail")
tech.researched=false
check(not planner.plan(player,id,route_id,"iron-plate",3),
 "Research previews must not create plans before unlock")
tech.researched=true
force.recipes[id].enabled=false
check(not planner.plan(player,id,route_id,"iron-plate",3)
 and not planner.plan_all(player,id,route_id,3),
 "Research does not override a force-disabled recipe")
force.recipes[id].enabled=true
force.technologies["planet-discovery-castra"].researched=false
check(#planner.catalog(force)==0
 and not planner.plan(player,id,route_id,"iron-plate",3),
 "Undiscovered factory worlds must stay hidden and unplannable")
force.technologies["planet-discovery-castra"].researched=true
enabled=false
check(#planner.inbound(force,"castra")==0
 and not planner.plan(player,id,route_id,"iron-plate",3),
 "Disabled routes must not produce manual orders")
enabled=true
check(#added==3,"Failed actions must not mutate the freight board")

-- The small Journal renderer keeps a real drop-down, batch input and
-- source options and uses existing action tags instead of remote transport.
local rendered={}
local function node()
 local element={style={},children={}}
 function element.add(spec)
  local child=node()
  child.spec=spec
  element.children[#element.children+1]=child
  rendered[#rendered+1]=child
  return child
 end
 return element
end
local pref={supply_batches=2}
planner.render(node(),player,pref,760)
check(pref.supply_recipe==id and pref.supply_route==route_id,
 "Renderer must select a validated installed recipe and inbound route")
local actions={}
for _,obj in ipairs(rendered) do
 local tags=obj.spec and obj.spec.tags
 if tags and tags.razi_ops_action then
  actions[tags.razi_ops_action]=true
 end
end
check(actions["supply-recipe"] and actions["supply-batches"]
 and actions["supply-plan"] and actions["supply-route"]
 and actions["supply-freight"] and actions["supply-plan-all"],
 "All Supply view native selectors and planning actions must be interactive")
print("Razi A.5 real recipe imports, provenance and quantity guards passed")
