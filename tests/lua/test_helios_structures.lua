-- HELIOS native-prototype integration fixture.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(value,message) if not value then error(message,2) end end
local materials={"razi-helios-corona-shield","razi-helios-stellar-frame",
 "razi-helios-relay-matrix","holmium-plate","superconductor",
 "processing-unit","low-density-structure","radar"}
local items={}
for _,name in ipairs(materials) do
 items[name]={name=name,icon="__base__/graphics/icons/radar.png",icon_size=64}
end
local function tech()
 return {enabled=true,hidden=false,prerequisites={},
 unit={count=100,time=30,ingredients={{"space-science-pack",1}}}}
end
local raw={item=items,recipe={},radar={
 radar={name="radar",type="radar",icon="__base__/graphics/icons/radar.png",
 icon_size=64,energy_source={type="electric",buffer_capacity="5MJ"},
 energy_usage="300kW"}},technology={
 ["razi-helios-swarm-engineering"]=tech(),
 ["razi-helios-relay-engineering"]=tech(),
 ["slp-dyson-sphere-grounded"]=tech(),
 ["ds-energy-loader-mk3"]=tech()}}
rawset(_G,"data",{raw=raw,extend=function(_,entries)
 for _,entry in ipairs(entries) do
  raw[entry.type]=raw[entry.type] or {}
  check(not raw[entry.type][entry.name],"duplicate "..entry.name)
  raw[entry.type][entry.name]=entry
 end
end})
rawset(_G,"mods",{["slp-dyson-sphere-reworked-fork"]="1.0.5"})
rawset(_G,"settings",{startup={
 ["razi-helios-progression"]={value="late"},
 ["razi-helios-construction"]={value="satellites"},
 ["razi-helios-commissioning"]={value="expedition"}}})
package.loaded["prototypes.compat.calidus_dyson"]={
 safe_link=function(target,prerequisite)
  local current=raw.technology[target]
  check(current and raw.technology[prerequisite],
    "invalid mocked technology prerequisite")
  table.insert(current.prerequisites,prerequisite)
  return true
 end}
package.loaded["prototypes.compat.helios_structures"]=nil
local helios=require("prototypes.compat.helios_structures")
check(helios.data_final_fixes(),"Physical construction should register")
check(raw.radar["razi-helios-grid-anchor"].energy_usage=="15MW",
 "Grid anchor must consume 15MW")
check(raw.radar["razi-helios-grid-anchor"].energy_source.buffer_capacity=="150MJ",
 "Grid buffer must support the calibration load")
check(raw.item["razi-helios-orbital-lattice"]
 and raw.recipe["razi-helios-orbital-lattice"],
 "Physical lattice cargo is not craftable")
check(raw.item["razi-helios-grid-anchor"].place_result=="razi-helios-grid-anchor",
 "Calibration station cannot be placed")
check(raw.technology["razi-helios-grid-commission"],
 "Grid calibration science is missing")
local mk3=raw.technology["ds-energy-loader-mk3"]
check(mk3.prerequisites[#mk3.prerequisites]=="razi-helios-grid-commission",
 "Native final connector did not depend on HELIOS grid commissioning")
print("HELIOS data-stage structures, energy demand and research passed")
