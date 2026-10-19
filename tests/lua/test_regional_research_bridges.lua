package.path="./?.lua;./?/init.lua;"..package.path
local function assertok(v,msg) if not v then error(msg,2) end end
local function tech(parents,effects)
 return {prerequisites=parents or {},unit={ingredients={{"space-science-pack",1}}},
   effects=effects or {}}
end
local function unlock(world,parents)
 return tech(parents,{{type="unlock-space-location",space_location=world}})
end
local techs={
 ["solaris-discovery"]=tech(),["nyxaris-discovery"]=tech(),
 ["vibrant-discovery"]=tech({"solaris-discovery","nyxaris-discovery"}),
 ["vespera-discovery"]=tech({"solaris-discovery","nyxaris-discovery"}),
 ["beetlejuice-discovery"]=tech({"vibrant-discovery","vespera-discovery"}),
 ["umbra-discovery"]=tech({"vibrant-discovery","vespera-discovery"}),
 ["planet-discovery-corrundum"]=tech(),
 ["planet-discovery-apia-carnova"]=tech(),
 ["planet-discovery-tellus"]=tech(),
 ["planet-discovery-secretas"]=tech(),
 ["planet-discovery-tenebris"]=tech(),
 ["planet-discovery-crucible"]=tech(),
 ["planet-discovery-cubium"]=tech(),
 ["planet-discovery-frozeta"]=tech(),
 ["research-igrys"]=unlock("igrys",{"solaris-discovery"}),
 ["research-foliax"]=unlock("foliax",{"nyxaris-discovery"}),
 ["research-cerys"]=unlock("cerys",{"vibrant-discovery"}),
 ["research-obsidiax"]=unlock("obsidiax",{"umbra-discovery"})
}
rawset(_G,"data",{raw={technology=techs,
 planet={igrys={},foliax={},cerys={},obsidiax={}},["space-location"]={}}})
local module=require("prototypes.technology.regional_research_bridges")
local function parent(node,want)
 for _,p in ipairs(techs[node].prerequisites or {}) do
   if p==want then return true end
 end
 return false
end
for _,edge in ipairs(module.bridges) do
 assertok(techs[edge[1]] and techs[edge[2]],"Test source missing")
end
-- Turning off planetary interdependence must switch off BOTH research
-- passes. The original campaign gates remain in seven_system_gates.
rawset(_G,"settings",{startup={
  ["razi-planetary-interdependence"]={value="off"}
}})
module.data_final_fixes()
assertok(not parent("planet-discovery-corrundum",
  "planet-discovery-apia-carnova"),
  "Off mode must not silently add regional bridge prerequisites")
settings.startup["razi-planetary-interdependence"]={value="balanced"} -- luacheck: ignore 122
module.data_final_fixes()
for _,edge in ipairs(module.bridges) do
 assertok(parent(edge[1],edge[2]),"Missing native cross-system edge")
end
for _,gate in ipairs({"vibrant-discovery","vespera-discovery"}) do
 assertok(parent(gate,"research-igrys") and parent(gate,"research-foliax"),
   "Missing early worlds from the middle frontier")
end
for _,gate in ipairs({"beetlejuice-discovery","umbra-discovery"}) do
 assertok(parent(gate,"research-cerys")
  and not parent(gate,"research-obsidiax"),
  "Outer discovery must not require its own Obsidiax side world")
end
module.data_final_fixes()
assertok(#techs["vibrant-discovery"].prerequisites==4,
  "Repeated weave duplicated first-stage prerequisites")
-- Native Cerys research after the outer gate may not become a shortcut.
techs["research-cerys"].prerequisites={"beetlejuice-discovery"}
techs["beetlejuice-discovery"].prerequisites={
 "vibrant-discovery","vespera-discovery"}
techs["umbra-discovery"].prerequisites={
 "vibrant-discovery","vespera-discovery"}
module.data_final_fixes()
assertok(not parent("beetlejuice-discovery","research-cerys")
 and not parent("umbra-discovery","research-cerys"),
 "Late-world source could gate an earlier chapter")
-- Prevent a technology with no explicit future-gate dependency but
-- a later-only science pack from becoming a mandatory chapter entrance.
techs["research-cerys"].prerequisites={"vibrant-discovery"}
techs["future-science-pack"]=tech({"beetlejuice-discovery"})
techs["research-obsidiax"].unit.ingredients={{"future-science-pack",1}}
techs["beetlejuice-discovery"].prerequisites={
 "vibrant-discovery","vespera-discovery"}
techs["umbra-discovery"].prerequisites={
 "vibrant-discovery","vespera-discovery"}
module.data_final_fixes()
assertok(not parent("beetlejuice-discovery","research-obsidiax")
 and not parent("umbra-discovery","research-obsidiax"),
 "Future-only science cannot gate the preceding system")
-- A recipe unlock *behind* a paired gateway is unsafe even when the
-- research ingredient has no technology with the same name.
techs["research-obsidiax"].unit.ingredients={{"late-ingredient",1}}
techs["future-ingredient-unlock"]=tech({"beetlejuice-discovery"},{
  {type="unlock-recipe",recipe="late-ingredient-recipe"}})
data.raw.recipe={
  ["late-ingredient-recipe"]={type="recipe",name="late-ingredient-recipe",enabled=false,results={{
    type="item",name="late-ingredient",amount=1}}}}
techs["beetlejuice-discovery"].prerequisites={
  "vibrant-discovery","vespera-discovery"}
techs["umbra-discovery"].prerequisites={
  "vibrant-discovery","vespera-discovery"}
module.data_final_fixes()
assertok(not parent("beetlejuice-discovery","research-obsidiax")
  and not parent("umbra-discovery","research-obsidiax"),
  "Hidden future recipe unlock created a research softlock")
rawset(_G,"settings",nil)
-- Missing optional mods cannot create fake destination technologies.
rawset(_G,"data",{raw={technology={
 ["vibrant-discovery"]=tech(),["vespera-discovery"]=tech()
},planet={},["space-location"]={}}})
-- With no candidate worlds installed, skip the giant recipe and
-- technology scan. The direct named prerequisite checks still work.
setmetatable(data.raw.technology,{__pairs=function()
  error("Unnecessary world/research scan with no candidate worlds")
end})
module.data_final_fixes()
assertok(not data.raw.technology["research-cerys"],
  "The weave fabricated an absent optional mod")
print("Regional bridge links, parallel chapters, cycle safety passed")
