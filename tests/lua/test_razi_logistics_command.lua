-- The A.4 command is a navigational reader, not a freight transport API.
-- Mock its dependencies to check bounded, read-only rendering without Factorio.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,msg) if not ok then error(msg,2) end end
local route_calls,infra_calls,receipt_calls,board_calls=0,0,0,0
local snapshot={installed=true,enabled=true,entries={
  {id="razi-muria-rubia-catapult",source="muria",target="rubia",
   state="researched",source_researched=true,target_researched=true,
   purpose="materials-transfer"}
}}
package.loaded["scripts.razi_catapult_network"]={
 snapshot=function() route_calls=route_calls+1;return snapshot end}
package.loaded["scripts.razi_freight_infrastructure"]={
 snapshot=function()
   infra_calls=infra_calls+1
   return {checked=2,worlds={
     muria={launcher_count=1,platforms=2,providers=1,
       unscheduled=0,vanilla_bays=3},
     rubia={launcher_count=0,platforms=0,providers=0,
       unscheduled=0,vanilla_bays=0}}}
 end}
package.loaded["scripts.razi_freight_receipts"]={
 snapshot=function()
   receipt_calls=receipt_calls+1
   return {total=3,worlds={muria=1,rubia=2},
     recent={{world="rubia",tick=100},{world="muria",tick=80}}}
 end}
package.loaded["scripts.razi_freight_orders"]={
 orders=function() return {{packed=false},{packed=true}} end,
 route=function(_,id)
   if id=="razi-muria-rubia-catapult"
      or id=="razi-rubia-muria-catapult" then return {id=id} end
   return nil
 end}
package.loaded["scripts.razi_freight_dispatch_ui"]={
 render=function(_,_,_,_,opts)
   board_calls=board_calls+1
   check(opts and opts.clean==true,
     "Freight view must avoid duplicate infrastructure and delivery rows")
 end}
prototypes={space_location={
 muria={localised_name={"planet-name.muria"}},
 rubia={localised_name={"planet-name.rubia"}}}}
local nodes={}
local function container()
 local node={style={},children={}}
 function node.add(spec)
   local child=container()
   child.spec=spec
   node.children[#node.children+1]=child
   nodes[#nodes+1]=child
   return child
 end
 return node
end
local command=require("scripts.razi_logistics_command")
local player={force={index=1},index=2}
command.overview(container(),player,760,
 {ships=3,transit=1,unscheduled=1})
check(route_calls==1 and infra_calls==1 and receipt_calls==1,
 "Command overview should take just one snapshot from each live provider")
check(board_calls==0,"Overview must never render the packing form")
command.routes(container(),player,760)
local actions={}
for _,node in ipairs(nodes) do
 local tags=node.spec and node.spec.tags
 if tags and tags.razi_ops_action=="logistics-route" then
   actions[tags.value]=true
 end
end
check(actions["razi-muria-rubia-catapult"]
   and actions["razi-rubia-muria-catapult"],
 "Routes should offer only real, source-verified directed route IDs")
check(infra_calls==2 and receipt_calls==2,
 "Routes should snapshot observed network just once on render")
command.freight(container(),player,760)
check(board_calls==1 and infra_calls==2 and receipt_calls==2,
 "Freight tab should defer source evidence to the other sections")
snapshot.entries={{source="muria",target="rubia",
 state="unresearched",source_researched=true,target_researched=false}}
nodes={}
command.routes(container(),player,400)
local leaks=0
for _,node in ipairs(nodes) do
 local tags=node.spec and node.spec.tags
 if tags and tags.razi_ops_action=="logistics-route" then leaks=leaks+1 end
end
check(leaks==0,
 "Undiscovered routes must never expose a planning action")
print("Razi A.4 Command/Routes/Freight separation and safe nav passed")
