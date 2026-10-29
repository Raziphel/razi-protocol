---@diagnostic disable: need-check-nil
-- Vespera freight is source-backed, discovery-aware and spoiler-safe.
-- Read-only: never inferred shipments or automatic Orbital Catapult activity.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(condition,reason) if not condition then error(reason,2) end end
local force={technologies={
 ["planet-discovery-muria"]={researched=false},
 ["planet-discovery-rubia"]={researched=false},
 ["planet-discovery-aquilo"]={researched=false}
}}
settings={startup={["razi-orbital-catapult-local-links"]={value=true}},
 global={["razi-hide-spoilers"]={value=true}}}
script={active_mods={["orbital-cannon"]="0.15.0"}}
-- Reproduce Factorio's strict LuaPrototypes behavior: missing keys throw.
prototypes=setmetatable({}, {__index=function(_,key)
 error("Unexpected LuaPrototypes field: "..tostring(key))
end})
game={planets={muria={},rubia={},aquilo={}}}
local network=require("scripts.razi_catapult_network")
local report=network.snapshot(force)
check(report.installed and report.enabled and report.total==3,
 "Three configured Vespera corridors expected")
check(report.visible==0 and report.concealed==3 and #report.entries==0,
 "Early-game Journal must not reveal future destination names")
force.technologies["planet-discovery-muria"].researched=true
report=network.snapshot(force)
check(report.visible==0 and report.concealed==3,
 "One world researched must not reveal undiscovered catapult destinations")
force.technologies["planet-discovery-rubia"].researched=true
report=network.snapshot(force)
check(report.visible==1 and report.concealed==2 and #report.entries==1,
 "Only the fully surveyed Muria–Rubia corridor should be visible")
local first=report.entries[1]
check((first.source=="muria" and first.target=="rubia")
   or (first.source=="rubia" and first.target=="muria"),
 "A researched local route must be Muria–Rubia")
check(first.state=="researched" and first.purpose=="materials-transfer",
 "Muria–Rubia industrial guidance must match the manifest")
check(#network.for_world(report,"aquilo")==0,
 "Hide Spoilers must not leak Aquilo from the local dossier")
force.technologies["planet-discovery-aquilo"].researched=true
report=network.snapshot(force)
check(report.visible==3 and report.concealed==0,
 "All three corridors must appear after native discovery research")
check(#network.for_world(report,"muria")==2,
 "Muria must have exactly two distinct catapult neighbors")
check(#network.for_world(report,"rubia")==2,
 "Rubia must have exactly two distinct catapult neighbors")
check(#network.for_world(report,"aquilo")==2,
 "Aquilo must have exactly two distinct catapult neighbors")
local statuses={}
for _,entry in ipairs(report.entries) do
 check(not statuses[entry.id] and entry.purpose,
   "Each local corridor must have a unique ID and useful note")
 statuses[entry.id]=true
end
-- Spoilers OFF may preview future locations, but cannot claim research.
force.technologies["planet-discovery-rubia"].researched=false
settings.global["razi-hide-spoilers"].value=false
report=network.snapshot(force)
check(report.visible==3 and report.concealed==0,
 "Spoilers OFF must show all three installed route definitions")
local pending=0
for _,entry in ipairs(report.entries) do
 if entry.state=="unresearched" then pending=pending+1 end
end
check(pending==2,"Real native research must be reflected in route status")
settings.startup["razi-orbital-catapult-local-links"].value=false
report=network.snapshot(force)
check(not report.enabled and #report.entries==0,
 "Disabled Razi startup switch must hide its declared routes")
settings.startup["razi-orbital-catapult-local-links"].value=true
script.active_mods["orbital-cannon"]=nil
report=network.snapshot(force)
check(not report.installed and #report.entries==0,
 "Missing source mod must not invent a live route")
script.active_mods["orbital-cannon"]="0.15.0"
local missing=network.snapshot(force,{
 planets={muria={},aquilo={}},hide=false
})
check(missing.total==1 and missing.visible==1,
 "Missing Rubia must remove only its affected corridors")
check(#network.for_world(nil,"muria")==0,
 "Missing snapshot must be handled safely")
print("Razi Orbital Catapult discovery, spoiler and dashboard guards passed")
