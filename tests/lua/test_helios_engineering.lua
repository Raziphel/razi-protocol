-- Unit fixtures for Project HELIOS without launching Factorio.
package.path="./?.lua;./?/init.lua;"..package.path
local function assert_ok(value,message)
 if not value then error(message,2) end
end
local function technology()
 return {prerequisites={},unit={count=100,time=30,
  ingredients={{"automation-science-pack",1}}},effects={}}
end
local materials={"tungsten-plate","lithium-plate","low-density-structure",
 "processing-unit","holmium-plate","carbon-fiber","superconductor",
 "slp-ds-satellite","slp-ds-planet-satellite"}
local function fixture(options)
 options=options or {}
 local items={}
 for _,id in ipairs(materials) do
  if not options.missing_lithium or id~="lithium-plate" then
   items[id]={name=id,icon="__base__/graphics/icons/iron-plate.png",
    icon_size=64}
  end
 end
 local technologies={}
 for _,id in ipairs({"planet-discovery-aquilo","planet-discovery-fulgora",
  "planet-discovery-vulcanus","planet-discovery-sunorbit",
  "slp-dyson-sphere","slp-dyson-sphere-grounded",
  "vibrant-discovery","vespera-discovery","moon-discovery-cerys"}) do
  technologies[id]=technology()
 end
 local recipes={
  ["source-dyson-satellite"]={
   categories={"crafting"},
   ingredients={{type="item",name="processing-unit",amount=20}},
   results={{type="item",name="slp-ds-satellite",amount=1}}},
  ["source-repeater-satellite"]={
   categories={"crafting"},
   ingredients={{type="item",name="low-density-structure",amount=20}},
   results={{type="item",name="slp-ds-planet-satellite",amount=1}}}}
 local raw={item=items,technology=technologies,recipe=recipes,
  ["assembling-machine"]={ordinary={ingredient_count=options.slots or 6,
   crafting_categories={"crafting"}}}}
 rawset(_G,"data",{raw=raw,extend=function(_,list)
  for _,entry in ipairs(list) do
   raw[entry.type]=raw[entry.type] or {}
   assert_ok(not raw[entry.type][entry.name],"duplicate "..entry.name)
   raw[entry.type][entry.name]=entry
  end
 end})
 rawset(_G,"mods",options.no_dyson and {} or {
  ["slp-dyson-sphere-reworked-fork"]="1.0.5"})
 rawset(_G,"settings",{startup={
  ["razi-helios-progression"]={value=options.progression or "late"},
  ["razi-helios-construction"]={value=options.construction or "satellites"}
 }})
 package.loaded["prototypes.compat.calidus_dyson"]={
  safe_link=function(target,prerequisite)
   local t=technologies[target]
   if not t or not technologies[prerequisite] then return false end
   for _,p in ipairs(t.prerequisites) do
    if p==prerequisite then return true end
   end
   t.prerequisites[#t.prerequisites+1]=prerequisite
   return true
  end}
 package.loaded["prototypes.compat.helios_engineering"]=nil
 return raw,require("prototypes.compat.helios_engineering")
end
local raw,engine=fixture()
assert_ok(engine.data_final_fixes(),"HELIOS should register full component chain")
for _,spec in ipairs(engine.components) do
 assert_ok(raw.recipe[spec.product]
   and raw.recipe[spec.product].categories
   and raw.recipe[spec.product].categories[1]=="advanced-crafting",
  "Factorio 2.1 machine recipe categories missing for "..spec.product)
 assert_ok(raw.item[spec.product] and raw.recipe[spec.product],
  "missing physical component "..spec.product)
 assert_ok(raw.technology[spec.tech] and #raw.technology[spec.tech].effects==1,
  "missing researched unlock "..spec.tech)
end
assert_ok(engine.reinforce_satellites()==2,
 "both supported SLP satellite products must receive a component")
assert_ok(#raw.recipe["source-dyson-satellite"].ingredients==2
 and #raw.recipe["source-repeater-satellite"].ingredients==2,
 "native ingredients should be preserved")
assert_ok(engine.reinforce_satellites()==0,
 "satellite components must never be added twice")
local limited,limited_engine=fixture({slots=1})
assert_ok(limited_engine.data_final_fixes(),"engineering should remain available")
assert_ok(limited_engine.reinforce_satellites()==0,
 "machine slot guard failed to prevent uncraftable source recipe")
assert_ok(#limited.recipe["source-dyson-satellite"].ingredients==1,
 "incompatible machine recipe was modified")
local missing,missing_engine=fixture({missing_lithium=true})
assert_ok(not missing_engine.data_final_fixes()
 and not missing.item["razi-helios-corona-shield"],
 "missing source material registered half of HELIOS")
local off,off_engine=fixture({construction="off"})
assert_ok(not off_engine.data_final_fixes() and off_engine.reinforce_satellites()==0,
 "off switch unexpectedly modified source content")
local legacy,legacy_engine=fixture({progression="legacy"})
assert_ok(not legacy_engine.data_final_fixes(),
 "legacy progression should leave native Dyson research untouched")
local no_source,no_source_engine=fixture({no_dyson=true})
assert_ok(not no_source_engine.data_final_fixes(),
 "missing SLP mod should skip HELIOS entirely")
print("HELIOS research, 3 components, satellite compatibility and off modes passed")
