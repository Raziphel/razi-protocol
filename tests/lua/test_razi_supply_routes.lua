-- A.6: only source-backed platform/catapult topology can form routes.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,msg) if not ok then error(msg,2) end end
local locations={}
for _,name in ipairs({"vulcanus","castra","gleba","moshine","rubia",
    "sye-solaris","sealed"}) do locations[name]={name=name} end
local connections={
 direct={name="direct",from=locations.vulcanus,
   to=locations.moshine,length=900},
 middle={name="middle",from=locations.castra,
   to=locations.gleba,length=400},
 star_a={name="star_a",from=locations.vulcanus,
   to=locations["sye-solaris"],length=200},
 star_b={name="star_b",from=locations["sye-solaris"],
   to=locations.moshine,length=200},
 secret={name="secret",from=locations.gleba,
   to=locations.sealed,length=10}
}
prototypes={space_location=locations,space_connection=connections}
game={planets={vulcanus={},castra={},gleba={},moshine={},rubia={}}}
local unlocked={
 vulcanus=true,castra=true,gleba=true,moshine=true,
 ["sye-solaris"]=true
}
local force={is_space_location_unlocked=function(name)
 return unlocked[name]==true
end}
local enabled=true
package.loaded["scripts.razi_catapult_network"]={
 snapshot=function()
  return {entries=enabled and {
    {source="vulcanus",target="castra",state="researched",
     source_researched=true,target_researched=true},
    {source="gleba",target="moshine",state="researched",
     source_researched=true,target_researched=true},
    {source="moshine",target="rubia",state="unresearched",
     source_researched=true,target_researched=false}
  } or {}}
 end}
package.loaded["scripts.razi_freight_orders"]={
 route=function(_,id)
  local valid={
   ["razi-vulcanus-castra-catapult"]=true,
   ["razi-castra-vulcanus-catapult"]=true,
   ["razi-gleba-moshine-catapult"]=true,
   ["razi-moshine-gleba-catapult"]=true
  }
  if enabled and valid[id] then
   local a,b=id:match("^razi%-(.-)%-(.-)%-catapult$")
   return {id=id,source=a,target=b}
  end
 end}
local routes=require("scripts.razi_supply_routes")
local graph=routes.graph(force)
check(graph.nodes.vulcanus and graph.nodes.moshine
 and graph.nodes["sye-solaris"]
 and not graph.nodes.sealed and not graph.nodes.rubia,
 "Only real unlocked location endpoints can appear in topology")
check(graph.edges>=10,"Bidirectional source routes must become directed edges")
local paths=routes.paths(graph,"vulcanus","moshine")
check(#paths>=3 and #paths<=4 and #paths[1].legs==1
 and paths[1].legs[1].id=="direct",
 "One-hop platform link should outrank true multi-hop alternatives")
local mixed
for _,path in ipairs(paths) do
 if #path.legs==3 and path.platform_legs==1 then mixed=path end
end
check(mixed and mixed.switches==2
 and mixed.legs[1].mode=="catapult"
 and mixed.legs[2].mode=="platform"
 and mixed.legs[3].mode=="catapult",
 "Three-hop journey must show both mode transfers")
check(routes.valid_path(graph,mixed),
 "Saved source route can be checked against current link identities")
local forged={legs={{from="vulcanus",to="moshine",mode="catapult",
 id="razi-cheat"}}}
check(not routes.valid_path(graph,forged),
 "Fake Catapult transport must never pass saved route validation")
local starts=routes.origins(graph,"moshine")
check(#starts>0 and starts[1]~="sye-solaris",
 "User origin selector must contain discovered planets, not star nodes")
local saw_vulcanus=false
for _,name in ipairs(starts) do
 if name=="vulcanus" then saw_vulcanus=true end
 if name=="rubia" then error("Research-locked Rubia leaked into origins") end
end
check(saw_vulcanus,"Reachable discovered home should be selectable")
unlocked["sye-solaris"]=false
local no_star=routes.graph(force)
for _,p in ipairs(routes.paths(no_star,"vulcanus","moshine")) do
 for _,leg in ipairs(p.legs) do
  check(leg.from~="sye-solaris" and leg.to~="sye-solaris",
    "Unresearched intermediate star cannot leak via preview")
 end
end
unlocked.moshine=false
local unknown=routes.graph(force)
check(#routes.paths(unknown,"vulcanus","moshine")==0,
 "Unknown destination must never offer a path")
unlocked.moshine=true
enabled=false
local no_catapult=routes.graph(force)
for _,p in ipairs(routes.paths(no_catapult,"vulcanus","moshine")) do
 for _,leg in ipairs(p.legs) do
  check(leg.mode=="platform",
    "Disabled Razi corridors must not remain in the multihop graph")
 end
end
check(#routes.paths(nil,"none","none")==0,
 "No graph must remain safely empty")
print("Razi A.6 researched map routing, transfer and origin guards passed")
