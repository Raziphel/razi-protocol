-- Pure data-stage compatibility fixtures for the Factorio 2.1 SLP port.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(x,m) if not x then error(m,2) end end
local function tech(parents,effects)
  return {prerequisites=parents or {},effects=effects or {},
    unit={count=100,time=30,ingredients={{"space-science-pack",1}}}}
end
local function unlock(id) return {{type="unlock-space-location",space_location=id}} end
local function setup(options)
 options=options or {}
 local t={
  ["planet-discovery-vulcanus"]=tech(),
  ["planet-discovery-fulgora"]=tech(),
  ["planet-discovery-gleba"]=tech(),
  ["moon-discovery-cerys"]=tech(),
  ["cerys-advanced-structure-repair"]=tech(),
  ["moshine-tech-data-processor-building"]=tech(),
  ["planet-discovery-aquilo"]=tech(),
  ["maraxsis-project-seadragon"]=tech(),
  ["razi-outer-frontier-mastery"]=tech(),
  ["razi-singularity-test-fire"]=tech({"razi-singularity-theory"}),
  ["razi-singularity-theory"]=tech(),
  ["planet-discovery-sunorbit"]=tech({},unlock("slp-solar-orbit-outer")),
  ["slp-solar-system-sun2"]=tech({},unlock("slp-solar-orbit-inner")),
  ["slp-dyson-sphere"]=tech(),
  ["slp-dyson-sphere-grounded"]=tech(),
  ["ds-energy-loader-mk2"]=tech(),
  ["ds-energy-loader-mk3"]=tech()
 }
 if options.cycle then
  t["maraxsis-project-seadragon"].prerequisites={"ds-energy-loader-mk2"}
 end
 local loc={
  ["slp-solar-orbit-outer"]={icon="source-outer",orbit={sprite="original-outer"}},
  ["slp-solar-orbit-inner"]={icon="source-inner",orbit={sprite="original-inner"}}
 }
 local raw={technology=t,["space-location"]=loc,
   planet={},["space-connection"]={}}
 local registered={}
 rawset(_G,"data",{raw=raw,extend=function(_,values)
   for _,entry in ipairs(values) do
     check(not raw["space-connection"][entry.name],"Duplicate Calidus route")
     raw["space-connection"][entry.name]=entry
     registered[#registered+1]=entry
   end
 end})
 rawset(_G,"mods",options.missing and {} or {
  ["slp-dyson-sphere-reworked-fork"]="1.0.5"})
 rawset(_G,"settings",{startup={
  ["razi-dyson-milestone-weave"]={value=not options.no_research},
  ["razi-dyson-calidus-layout"]={value=not options.no_layout}
 }})
 package.loaded["prototypes.compat.calidus_dyson"]=nil
 package.loaded["prototypes.system.route_icons"]={
   assign=function(route)route.icon="__razi-protocol__/graphics/icons/routes/planetary-route.png"
     route.icon_size=64;return route end
 }
 return raw,require("prototypes.compat.calidus_dyson"),registered
end
local function has(t,name)
 for _,id in ipairs(t.prerequisites or {}) do
   if id==name then return true end
 end
 return false
end
local raw,mod,routes=setup()
mod.data_final_fixes()
for _,stage in ipairs(mod.stages) do
 for _,parent in ipairs(stage.parents) do
  check(has(raw.technology[stage.id],parent),
   "Dyson project ignored source milestone "..stage.id.." -> "..parent)
 end
end
check(has(raw.technology["razi-singularity-test-fire"],
 "slp-dyson-sphere-grounded"),"Dyson receiver absent from endgame test-fire")
local outer=raw["space-location"]["slp-solar-orbit-outer"]
local inner=raw["space-location"]["slp-solar-orbit-inner"]
check(outer.distance==10 and inner.distance==5,
 "Solar locations not arranged as two Calidus inner orbits")
check(outer.orbit.sprite=="original-outer" and inner.icon=="source-inner",
 "A native solar orbit icon or sprite was replaced")
raw["space-location"]["sye-calidus"]={icon="home-hub"}
mod.connect_calidus()
check(#routes==1 and routes[1].to=="slp-solar-orbit-outer"
 and routes[1].from=="sye-calidus" and routes[1].length==10500,
 "Calidus solar access corridor not constructed")
mod.connect_calidus()
check(#routes==1,"Duplicate solar route after repeated registration")
local connected,c=setup()
connected["space-location"]["sye-calidus"]={icon="home-hub"}
connected["space-connection"]["source-nauvis-solar-orbit"]={
  name="source-nauvis-solar-orbit",from="nauvis",
  to="slp-solar-orbit-outer",length=9500,shape="arc"}
c.connect_calidus()
check(not connected["space-connection"]["razi-calidus-stellar-orbit"],
  "Existing Nauvis solar-orbit access must not get a second crossing hub link")
local count=#raw.technology["slp-dyson-sphere"].prerequisites
mod.data_final_fixes()
check(#raw.technology["slp-dyson-sphere"].prerequisites==count,
 "Repeated source tech pass duplicated dependencies")
local cycle,m=setup({cycle=true})
m.data_final_fixes()
check(not has(cycle.technology["ds-energy-loader-mk2"],
 "maraxsis-project-seadragon"),"Cyclic MK2 dependency not rejected")
local disabled,d=setup({no_research=true,no_layout=true})
d.data_final_fixes()
check(#disabled.technology["slp-dyson-sphere"].prerequisites==0
 and disabled["space-location"]["slp-solar-orbit-outer"].distance==nil,
 "Disabling Razi Dyson rework changed source orbital research/layout")
check(not has(disabled.technology["razi-singularity-test-fire"],
 "slp-dyson-sphere-grounded"),
 "Disabling Dyson research links retained the endgame prerequisite")
local missing,n=setup({missing=true})
n.data_final_fixes()
check(#missing.technology["slp-dyson-sphere"].prerequisites==0,
 "Missing source mod triggered Razi build integration")
print("Dyson research, Calidus solar orbit, safety, toggles passed")
