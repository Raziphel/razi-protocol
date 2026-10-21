-- texlua tests/test_biological_machines_difficulty.lua
package.path="./?.lua;./?/init.lua;"..package.path
local bridge=require("prototypes.compat.biological_machines_difficulty")
local originals={
 ["bm-cube-speed"]=2,
 ["bm-cube-pollution"]=9000,
 ["promethium-belt-science-count"]=6800,
 ["promethium-belt-speed"]=105,
}
local startup={["razi-difficulty-preset"]={value="normal"}}
for k,v in pairs(originals) do startup[k]={value=v} end
local active={
 ["biological-machines-planet-balack"]="1.1.2",
 ["biological-machines-promethium-belts"]="1.0.0"}
local raw={
 ["assembling-machine"]={
  ["bm-bio-cube"]={crafting_speed=2,energy_source={
   type="electric",emissions_per_minute={pollution=9000}},module_slots=8,
   energy_usage="10MW"},
  ["other-cube"]={crafting_speed=3},
 },
 technology={
  ["promethium-transport-belt"]={unit={count=6800,ingredients={{"a",1}}}},
  ["another-tech"]={unit={count=750}},
 },
 ["transport-belt"]={["promethium-transport-belt"]={speed=0.1875*105/90}},
 ["underground-belt"]={["promethium-underground-belt"]={speed=0.1875*105/90}},
 splitter={["promethium-splitter"]={speed=0.1875*105/90}},
 loader={["promethium-loader"]={speed=0.1875*105/90}},
}
local cube=raw["assembling-machine"]["bm-bio-cube"]
local transport=raw["transport-belt"]["promethium-transport-belt"]
local function near(a,b) assert(math.abs(a-b)<0.00000001,tostring(a).." != "..tostring(b)) end
local function mode(v) startup["razi-difficulty-preset"].value=v end
local normal=bridge.apply(raw,startup,active)
assert(normal.machine==0 and normal.pollution==0
 and normal.technology==0 and normal.belts==0)
assert(cube.crafting_speed==2 and cube.energy_source.emissions_per_minute.pollution==9000)
assert(raw.technology["promethium-transport-belt"].unit.count==6800)
assert(raw["assembling-machine"]["other-cube"].crafting_speed==3)
mode("easy")
local changed=bridge.apply(raw,startup,active)
assert(changed.machine==1 and changed.pollution==1 and
 changed.technology==1 and changed.belts==4)
near(cube.crafting_speed,1.25)
near(cube.energy_source.emissions_per_minute.pollution,7500)
assert(raw.technology["promethium-transport-belt"].unit.count==3000)
near(transport.speed,0.1875*120/90)
assert(raw.technology["another-tech"].unit.count==750)
assert(cube.module_slots==8 and cube.energy_usage=="10MW")
local repeatRun=bridge.apply(raw,startup,active)
assert(repeatRun.machine==0 and repeatRun.pollution==0
 and repeatRun.technology==0 and repeatRun.belts==0)
mode("hard")
bridge.apply(raw,startup,active)
near(cube.crafting_speed,0.85)
near(cube.energy_source.emissions_per_minute.pollution,16000)
assert(raw.technology["promethium-transport-belt"].unit.count==7500)
near(transport.speed,0.1875)
mode("nightmare")
bridge.apply(raw,startup,active)
near(cube.crafting_speed,0.65)
near(cube.energy_source.emissions_per_minute.pollution,25000)
assert(raw.technology["promethium-transport-belt"].unit.count==12000)
near(transport.speed,0.1875*75/90)
-- Mid-stage changes are artificial: a real startup mode change reloads mods.
-- Normal and Custom must still perform no writes to previously scaled values.
mode("normal")
local saved=transport.speed
assert(bridge.apply(raw,startup,active).belts==0)
assert(transport.speed==saved)
mode("custom")
assert(bridge.apply(raw,startup,active).machine==0)
assert(cube.crafting_speed==0.65)
-- Fresh Normal with actual manually customized source options.
local untouched={["assembling-machine"]={["bm-bio-cube"]={
 crafting_speed=3,energy_source={emissions_per_minute={pollution=6100}}
}}}
mode("normal")
assert(bridge.apply(untouched,startup,active).machine==0)
assert(untouched["assembling-machine"]["bm-bio-cube"].crafting_speed==3)
mode("hard")
assert(bridge.apply(raw,startup,{}) .machine==0)
assert(bridge.apply({["assembling-machine"]={}},startup,active).machine==0)
print("Biological Machines numeric difficulty: PASS")
