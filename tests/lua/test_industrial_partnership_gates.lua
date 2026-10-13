-- Middle/outer gate links must be source-aware, reversible by startup
-- setting and idempotent on duplicate data-stage registration.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,why) if not ok then error(why,2) end end
local function node(parents)
  return {prerequisites=parents or {},unit={ingredients={{"vibrant-tech-card",1}}}}
end
local function fixture(mode)
  rawset(_G,"settings",{startup={["razi-planetary-interdependence"]=
    {value=mode}}})
  local techs={
    ["solaris-discovery"]=node(),
    ["nyxaris-discovery"]=node(),
    ["vibrant-discovery"]=node({"solaris-discovery","nyxaris-discovery"}),
    ["vespera-discovery"]=node({"solaris-discovery","nyxaris-discovery"}),
    ["beetlejuice-discovery"]=node({"vibrant-discovery","vespera-discovery"}),
    ["umbra-discovery"]=node({"vibrant-discovery","vespera-discovery"}),
    ["planet-discovery-vulcanus"]=node({"solaris-discovery"}),
    ["planet-discovery-gleba"]=node({"nyxaris-discovery"}),
    ["planet-discovery-moshine"]=node({"nyxaris-discovery"}),
    ["planet-discovery-fulgora"]=node({"vibrant-discovery"}),
    ["planet-discovery-paracelsin"]=node({"vibrant-discovery"}),
    ["planet-discovery-rubia"]=node({"vespera-discovery"}),
    ["razi-first-frontier-relay-components"]=node({
      "planet-discovery-vulcanus","planet-discovery-gleba",
      "planet-discovery-moshine"}),
    ["razi-middle-paracelsin-shielded-coils"]=node({
      "planet-discovery-paracelsin","planet-discovery-rubia"}),
    ["razi-middle-rubia-conductive-frames"]=node({
      "planet-discovery-rubia","planet-discovery-paracelsin"})
  }
  rawset(_G,"data",{raw={technology=techs}})
  package.loaded["prototypes.technology.industrial_partnership_gates"]=nil
  return techs,require("prototypes.technology.industrial_partnership_gates")
end
local function contains(target,parent)
  for _,x in ipairs(target.prerequisites) do
    if x==parent then return true end
  end
  return false
end
local balanced,b=fixture("balanced")
b.data_final_fixes()
for _,id in ipairs({"vibrant-discovery","vespera-discovery"}) do
  check(contains(balanced[id],"razi-first-frontier-relay-components"),
    "One practical early workshop should unlock the next pair")
  check(not contains(balanced[id],"razi-middle-paracelsin-shielded-coils"),
    "Middle industries cannot gate the earlier pair")
end
for _,id in ipairs({"beetlejuice-discovery","umbra-discovery"}) do
  check(contains(balanced[id],"razi-middle-paracelsin-shielded-coils")
    and contains(balanced[id],"razi-middle-rubia-conductive-frames"),
    "Both middle industrial chapters should support outer research")
end
local lengths={}
for name,node_data in pairs(balanced) do
  lengths[name]=#node_data.prerequisites
end
b.data_final_fixes()
for name,node_data in pairs(balanced) do
  check(#node_data.prerequisites==lengths[name],
    "Repeated registration duplicated research on "..name)
end
local no_middle,missing=fixture("balanced")
no_middle["razi-middle-rubia-conductive-frames"]=nil
missing.data_final_fixes()
check(contains(no_middle["beetlejuice-discovery"],
    "razi-middle-paracelsin-shielded-coils")
  and not contains(no_middle["beetlejuice-discovery"],
    "razi-middle-rubia-conductive-frames"),
  "Missing recipe research must suppress only that requirement")
local late,late_module=fixture("balanced")
late["razi-middle-rubia-conductive-frames"].prerequisites={
  "beetlejuice-discovery"}
late_module.data_final_fixes()
check(not contains(late["beetlejuice-discovery"],
  "razi-middle-rubia-conductive-frames")
  and not contains(late["umbra-discovery"],
  "razi-middle-rubia-conductive-frames"),
  "Research from an outer system must never gate either outer system")
local fallback,fallback_module=fixture("balanced")
fallback["razi-first-frontier-relay-components"]=nil
fallback["razi-galactic-vulcanus-bioptic-casting"]=node({
 "planet-discovery-vulcanus","planet-discovery-gleba",
 "planet-discovery-moshine"})
fallback_module.data_final_fixes()
check(contains(fallback["vibrant-discovery"],
  "razi-galactic-vulcanus-bioptic-casting"),
  "Next valid first-frontier research should be a safe fallback")
local off,o=fixture("off")
o.data_final_fixes()
check(not contains(off["beetlejuice-discovery"],
  "razi-middle-rubia-conductive-frames")
  and not contains(off["vibrant-discovery"],
  "razi-first-frontier-relay-components"),
  "Off mode must not impose industrial prerequisites")
local weird,w=fixture("balanced")
weird["razi-first-frontier-relay-components"].prerequisites={
  "vibrant-discovery"}
w.data_final_fixes()
check(not contains(weird["vibrant-discovery"],
  "razi-first-frontier-relay-components"),
  "An optional source moved later cannot create a technology cycle")
print("Industrial partnership research: stages, modes, fallback, missing source and cycle checks passed")
