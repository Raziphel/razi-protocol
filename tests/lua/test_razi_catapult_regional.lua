-- Regional catapult planner uses native discovery and shared spoiler setting.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,msg) if not ok then error(msg,2) end end
local worlds={"muria","rubia","aquilo","maraxsis",
  "vulcanus","castra","gleba","moshine"}
local planets,technologies={},{}
for _,world in ipairs(worlds) do
  planets[world]={}
  technologies["planet-discovery-"..world]={researched=false}
end
prototypes=setmetatable({}, {__index=function(_,key)
 error("Unexpected LuaPrototypes field: "..tostring(key))
end})
game={planets=planets}
settings={startup={
  ["razi-orbital-catapult-local-links"]={value=true},
  ["razi-orbital-catapult-regional-links"]={value=true}},
  global={["razi-hide-spoilers"]={value=true}}}
script={active_mods={["orbital-cannon"]="0.15.0"}}
local force={technologies=technologies}
local network=require("scripts.razi_catapult_network")
local state=network.snapshot(force)
check(state.total==6 and state.visible==0 and state.concealed==6,
  "Hide Spoilers ON should conceal all six undiscovered corridors")
for _,world in ipairs({"vulcanus","castra","gleba","moshine"}) do
  technologies["planet-discovery-"..world].researched=true
end
state=network.snapshot(force)
check(state.total==6 and state.visible==2 and state.concealed==4,
  "Source research should uncover Solaris/Nyxaris without other world leaks")
local expected={solaris=false,nyxaris=false}
for _,entry in ipairs(state.entries) do
 check(entry.region and entry.purpose and entry.state=="researched",
   "Revealed route should have true source status and purpose")
 check(expected[entry.region]~=nil,"Unknown region leaked")
 expected[entry.region]=true
end
check(expected.solaris and expected.nyxaris,"Missing revealed local systems")
check(#network.for_world(state,"maraxsis")==0,
  "Undiscovered Maraxsis must not be named in the Journal")
for _,world in ipairs({"muria","rubia","aquilo","maraxsis"}) do
  technologies["planet-discovery-"..world].researched=true
end
state=network.snapshot(force)
check(state.visible==6 and state.concealed==0,
  "All six routes must be visible once worlds are researched")
check(#network.for_world(state,"rubia")==3,
  "Rubia now has three corridors, including Maraxsis")
check(#network.for_world(state,"vulcanus")==1,
  "Vulcanus should have only Castra as a local catapult neighbor")
local ranks={solaris=1,nyxaris=2,vespera=3}
local last=0
for _,entry in ipairs(state.entries) do
  check(ranks[entry.region]>=last,"Region grouping must sort geographically")
  last=ranks[entry.region]
end
settings.startup["razi-orbital-catapult-regional-links"].value=false
state=network.snapshot(force)
check(state.total==3 and state.visible==3,
  "New startup switch must remove only new regional corridors")
settings.startup["razi-orbital-catapult-local-links"].value=false
settings.startup["razi-orbital-catapult-regional-links"].value=true
state=network.snapshot(force)
check(state.total==3 and state.visible==3,
  "Extended routes must work independently of the older setting")
technologies["planet-discovery-castra"].researched=false
settings.global["razi-hide-spoilers"].value=false
state=network.snapshot(force)
local pending=false
for _,entry in ipairs(state.entries) do
  if entry.region=="solaris" then
    pending=entry.state=="unresearched"
  end
end
check(pending,"Spoilers OFF may preview Solaris but cannot fake its research")
print("Razi regional catapult discovery, sorting, and settings passed")
