-- A.6 multi-hop manifests are per-player, bounded and not shipments.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,msg) if not ok then error(msg,2) end end
storage={}
local enabled=true
local graph={nodes={vulcanus=true,castra=true,gleba=true,moshine=true},
 adj={vulcanus={},castra={},gleba={}}}
local route={legs={
 {from="vulcanus",to="castra",mode="catapult",id="catapult-out"},
 {from="castra",to="gleba",mode="platform",id="native-middle",km=200},
 {from="gleba",to="moshine",mode="catapult",id="catapult-in"}
},key="path",platform_km=200,platform_legs=1,switches=2}
local calls={graphs=0}
package.loaded["scripts.razi_supply_routes"]={
 graph=function() calls.graphs=calls.graphs+1;return graph end,
 origins=function()return enabled and {"gleba","vulcanus"} or {} end,
 paths=function(_,origin,dest)
  if enabled and origin=="vulcanus" and dest=="moshine" then
   return {route}
  end
  return {}
 end,
 valid_path=function(_,path)
  return enabled and #path.legs==3 and
    path.legs[1].id=="catapult-out" and
    path.legs[3].id=="catapult-in"
 end
}
local technology={researched=true}
local revised=false
local recipe={quest={tech="razi-test-supply"},site="moshine",
  technology=technology,recipe_enabled=true,
  recipe={ingredients={{name="iron-plate",amount=2}}}}
package.loaded["scripts.razi_supply_planner"]={
 catalog=function() return {recipe} end,
 recipe=function(_,name)
  if name=="razi-test-supply" then return recipe end end,
 batches=function(value)
  local n=tonumber(value)
  return n and n>=1 and n<=1000 and n==math.floor(n) and n or nil
 end,
 ingredients=function(_,batches)
  return {{name="iron-plate",count=(revised and 5 or 2)*batches,
      plannable=true},
    {name="copper-plate",count=3*batches,plannable=true},
    {name="water",kind="fluid",count=10*batches,plannable=false}}
 end
}
prototypes={item={
 ["iron-plate"]={localised_name="Iron"},
 ["copper-plate"]={localised_name="Copper"}},
 space_location={
 vulcanus={localised_name="Vulcanus"},
 castra={localised_name="Castra"},
 gleba={localised_name="Gleba"},
 moshine={localised_name="Moshine"}}}
game={tick=1234}
local module=require("scripts.razi_supply_multihop")
local player={index=10,force={index=2}}
local other={index=11,force=player.force}
local p={supply_recipe="razi-test-supply",
 supply_batches=4,supply_origin="vulcanus",supply_path=1,
 supply_path_key="path"}
check(module.save(player,p),
 "Valid researched factory should create manual manifest")
local key=p.supply_path_key
p.supply_path_key="stale-route-id"
check(not module.save(player,p),
 "Reordered route list must not silently save the wrong path")
p.supply_path_key=key
local one=storage.razi_supply_itineraries[player.index]
check(#one.plans==1 and one.plans[1].batches==4
 and #one.plans[1].materials==2
 and one.plans[1].materials[1].count==8
 and #one.plans[1].legs==3,
 "Stored bill and transport legs must be original source primitive data")
check(storage.razi_supply_itineraries[other.index]==nil,
 "Another player cannot inherit the first operator's itinerary")
check(module.visible(player,graph)[1].valid,
 "Visible manifest must be revalidated against current graph")
check(module.toggle_details(player,p,one.plans[1].id)
 and p.supply_expanded==one.plans[1].id,
 "Saved itinerary should expand only after explicit click")
check(module.toggle_details(player,p,one.plans[1].id)
 and p.supply_expanded==nil,
 "Saved itinerary should collapse to the compact summary")
revised=true
check(not module.visible(player,graph)[1].valid,
 "Rebalanced source ingredients invalidate outdated saved quantities")
revised=false
check(module.visible(player,graph)[1].valid,
 "Restored source recipe restores correctly matching itinerary bill")
local forged={supply_recipe=p.supply_recipe,
 supply_batches=4,supply_origin="sealed",supply_path=1}
check(not module.save(player,forged),
 "Forged / undiscovered source planet cannot create a manifest")
p.supply_path=99
check(not module.save(player,p),
 "Unknown path selection cannot bypass alternative list validation")
p.supply_path=1
p.supply_batches=0
check(not module.save(player,p),
 "Invalid factory batch must not reuse old material quantities")
p.supply_batches=4
technology.researched=false
check(not module.save(player,p),
 "Unavailable factory research must not create an itinerary")
technology.researched=true
enabled=false
check(not module.save(player,p) and not module.visible(player,graph)[1].valid
 and module.visible(player,graph)[1].plan==nil
 and not module.toggle_details(player,p,one.plans[1].id),
 "Lost route source or research must conceal saved contents")
check(module.remove(player,one.plans[1].id),
 "Concealed manifests must be removable with opaque ID")
check(#storage.razi_supply_itineraries[player.index].plans==0,
 "Deleted manifest cannot remain in save")
enabled=true
for i=1,12 do
 check(module.save(player,p),"Up to 12 manual manifests are allowed")
end
check(not module.save(player,p),
 "Over-cap itinerary list must not create a thirteenth entry")
check(#module.visible(player,graph)==12,
 "Visible saved itinerary view must respect the bounded list")
-- Render must use normal GUI tags rather than saving/loading on its own.
local actions={}
local function gui()
 local node={style={},children={}}
 function node.add(spec)
  local child=gui()
  child.spec=spec
  node.children[#node.children+1]=child
  if spec.tags and spec.tags.razi_ops_action then
   actions[spec.tags.razi_ops_action]=true
  end
  return child
 end
 return node
end
module.render(gui(),player,p,750,recipe)
check(actions["supply-origin"] and actions["supply-path"]
 and actions["supply-itinerary-save-all"]
 and actions["supply-itinerary-remove"]
 and actions["supply-itinerary-toggle"],
 "Source and route selection plus save/expand/remove must have native GUI tags")
module.cleanup(player.index)
check(storage.razi_supply_itineraries[player.index]==nil,
 "Removed player must not leave orphaned itinerary records")
print("Razi A.6 source-verified manual manifests and spoiler guard passed")
