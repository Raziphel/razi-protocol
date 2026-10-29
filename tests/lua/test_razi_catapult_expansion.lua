-- Additional real industry corridors: Solaris, Nyxaris, Vespera.
-- No off-system shortcuts, no research rewrites, no imaginary shipments.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,why) if not ok then error(why,2) end end
local catapult=require("prototypes.compat.orbital_catapult")
local planets={muria={},aquilo={},rubia={},maraxsis={},
  vulcanus={},castra={},gleba={},moshine={}}
local raw={planet=planets,["orbital-cannon-link"]={}}
local base=catapult.definitions(raw,true,true)
check(#base==6,"Existing Vespera corridors must remain six directed links")
local full=catapult.definitions(raw,true,true,true)
check(#catapult.active_links(true,true)==12,
  "The shared source manifest must include both independent route groups")
check(#full==12,"Six corridors require twelve source directed links")
local counted={}
for _,entry in ipairs(full) do
  check(planets[entry.source] and planets[entry.target],
    "Every source and destination must actually exist")
  check(entry.source~=entry.target and not counted[entry.name],
    "Link names must be distinct and must not loop to itself")
  check(entry.link_type=="transport" and entry.type=="orbital-cannon-link",
    "The source mod owns all catapult transport")
  counted[entry.name]=true
end
for _,pair in ipairs({
 {"vulcanus","castra"},{"gleba","moshine"},{"rubia","maraxsis"}
}) do
  local a,b=pair[1],pair[2]
  check(counted["razi-"..a.."-"..b.."-catapult"],"Outbound missing: "..a)
  check(counted["razi-"..b.."-"..a.."-catapult"],"Return missing: "..b)
end
check(#catapult.definitions(raw,true,false,true)==6,
 "Regional setting works independently of original Vespera switch")
check(#catapult.definitions(raw,true,true,false)==6,
 "Old switch still controls only its original corridors")
check(#catapult.definitions(raw,false,true,true)==0,
 "Missing upstream mod must not register custom types")
local missing={planet={muria={},aquilo={},rubia={},vulcanus={},castra={}}}
check(#catapult.definitions(missing,true,true,true)==8,
 "Missing Gleba/Moshine and Maraxsis should only skip affected pairs")
local writes={}
data={raw=raw,extend=function(self,rows)
 for _,record in ipairs(rows) do writes[#writes+1]=record end
end}
mods={["orbital-cannon"]="0.15.0"}
settings={startup={
 ["razi-orbital-catapult-local-links"]={value=true},
 ["razi-orbital-catapult-regional-links"]={value=true}
}}
catapult.data()
check(#writes==12,"Default startup configuration must export twelve links")
settings.startup["razi-orbital-catapult-local-links"].value=false
writes={}
catapult.data()
check(#writes==6,"Independent local OFF should leave six regional links")
settings.startup["razi-orbital-catapult-regional-links"].value=false
writes={}
catapult.data()
check(#writes==0,"Both OFF settings remove only Razi catapult links")
check(not raw["space-connection"] and not raw.technology and not raw.recipe,
  "No source research/recipes or native starmap links were rewritten")
print("Orbital Catapult regional extension and independence passed")
