-- Source Orbital Catapult API fixtures, with required dependency semantics.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,message) if not ok then error(message,2) end end
local catapult=require("prototypes.compat.orbital_catapult")
local planets={muria={},rubia={},aquilo={}}
local full={planet=planets,["space-connection"]={
  ["muria-aquilo"]={name="muria-aquilo",from="muria",to="aquilo"}
}}
local source=catapult.definitions(full,true,true)
check(#source==6,"Three reversible Vespera corridors should have six directed links")
local direction,ids={},{}
for _,link in ipairs(source) do
  check(link.type=="orbital-cannon-link" and link.link_type=="transport",
    "All links must obey Orbital Catapult's source API")
  check(planets[link.source] and planets[link.target],
    "Only present planet prototypes may receive catapult links")
  check(link.source~=link.target and not ids[link.name],
    "Catapult routes must have unique names and separate planets")
  check(not link.requested_slots,"Don't assume an unverified source slot API")
  ids[link.name]=true
  direction[link.source..">"..link.target]=true
end
for _,edge in ipairs({
  "muria>aquilo","aquilo>muria",
  "muria>rubia","rubia>muria",
  "aquilo>rubia","rubia>aquilo"
}) do check(direction[edge],"Missing directed corridor "..edge) end
check(ids["razi-muria-aquilo-catapult"]
  and ids["razi-aquilo-muria-catapult"],
  "Old 3.0 catapult link IDs must not be renamed")
check(#catapult.definitions(full,false,true)==0,
  "Never register a source-owned link type when the mod is missing")
check(#catapult.definitions(full,true,false)==0,
  "OFF setting must omit all Razi-owned catapult lanes")
check(#catapult.definitions({planet={muria={},aquilo={}}},true,true)==2,
  "Missing Rubia must skip only corridors touching Rubia")
check(#catapult.definitions({planet={rubia={}}},true,true)==0,
  "Never make stranded or self-referencing catapult links")
local occupied={planet=planets,["orbital-cannon-link"]={
  ["razi-muria-aquilo-catapult"]={name="razi-muria-aquilo-catapult"}}}
check(#catapult.definitions(occupied,true,true)==5,
  "Don't collide with existing source or third-party catapult IDs")
local installed={}
data={raw=full,extend=function(_,rows)
  for _,link in ipairs(rows) do installed[#installed+1]=link end
end}
mods={["orbital-cannon"]="0.15.0"}
settings={startup={["razi-orbital-catapult-local-links"]={value=true}}}
catapult.data()
check(#installed==6,"Enabled source mod must register each Vespera link")
settings.startup["razi-orbital-catapult-local-links"].value=false
catapult.data()
check(#installed==6,"Disabling Razi catapult lanes must not add new links")
check(full["space-connection"]["muria-aquilo"] and
  full.planet.muria and full.planet.rubia and full.planet.aquilo,
  "Catapult integration must not mutate platform routes or native planets")
print("Vespera Orbital Catapult dependency, corridors and safety guards passed")
