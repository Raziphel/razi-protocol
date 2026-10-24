-- Biological Machines: Planet Balack on Easy, Hard and Nightmare: speed and
-- pollution of the bio fabricator and its copies. Normal and Custom write
-- nothing; the research of Promethium Belts and belt speeds are not touched.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,msg) if not ok then error(msg,2) end end
rawset(_G,"log",function() end)
local bridge=require("prototypes.compat.biological_machines_difficulty")
---@type table<string,any>
local startup={
 ["razi-difficulty-preset"]={value="normal"},
 ["bm-cube-speed"]={value=2},
 ["bm-cube-pollution"]={value=9000},
 ["promethium-belt-science-count"]={value=6800},
}
local active={
 ["biological-machines-planet-balack"]="1.1.2",
 ["biological-machines-promethium-belts"]="1.0.1"}
local SPEED=0.1875*105/90
local raw={
 ["assembling-machine"]={
  ["bm-bio-cube"]={crafting_speed=2,crafting_categories={"bm-bio-cube"},energy_source={
   type="electric",emissions_per_minute={pollution=9000}},module_slots=8,
   energy_usage="10MW"},
  -- copies that other mods make of the finished machine
  ["harene-infused-bm-bio-cube"]={crafting_speed=2,crafting_categories={"bm-bio-cube"},
   energy_source={emissions_per_minute={pollution=9000}}},
  ["bioluminescent-bm-bio-cube"]={crafting_speed=3,crafting_categories={"bm-bio-cube"},
   energy_source={type="electric"}},
  ["other-cube"]={crafting_speed=3,crafting_categories={"crafting"}},
 },
 technology={
  ["promethium-transport-belt"]={unit={count=6800,ingredients={{"a",1}}}},
 },
 ["transport-belt"]={["promethium-transport-belt"]={speed=SPEED}},
}
local cube=raw["assembling-machine"]["bm-bio-cube"]
local harene=raw["assembling-machine"]["harene-infused-bm-bio-cube"]
local glow=raw["assembling-machine"]["bioluminescent-bm-bio-cube"]
local function near(a,b,msg) check(math.abs(a-b)<1e-8,msg.." ("..tostring(a).." != "..tostring(b)..")") end
local function mode(v) startup["razi-difficulty-preset"].value=v end
local function untouched(label)
 check(raw.technology["promethium-transport-belt"].unit.count==6800,label..": belt research changed")
 near(raw["transport-belt"]["promethium-transport-belt"].speed,SPEED,label..": belt speed changed")
 check(raw["assembling-machine"]["other-cube"].crafting_speed==3,label..": a machine of another category changed")
 check(cube.module_slots==8 and cube.energy_usage=="10MW",label..": other fields of the fabricator changed")
end

local normal=bridge.apply(raw,startup,active)
check(normal.machine==0 and normal.pollution==0,"Normal must write nothing")
check(cube.crafting_speed==2 and cube.energy_source.emissions_per_minute.pollution==9000,"Normal changed the fabricator")
untouched("Normal")

mode("easy")
local changed=bridge.apply(raw,startup,active)
check(changed.machine==3 and changed.pollution==2,
 "Easy: three machines (the cube and two copies), two pollution values")
near(cube.crafting_speed,1.25,"Easy: speed is the value of the level, not a multiple of the saved one")
near(cube.energy_source.emissions_per_minute.pollution,7500,"Easy: pollution")
near(harene.crafting_speed,1.25,"Easy: a copy of the fabricator follows")
near(harene.energy_source.emissions_per_minute.pollution,7500,"Easy: its pollution follows")
near(glow.crafting_speed,3*1.25/2,"Easy: a faster copy keeps its factor")
check(glow.energy_source.emissions_per_minute==nil,"a copy without pollution gets none")
untouched("Easy")
local repeatRun=bridge.apply(raw,startup,active)
check(repeatRun.machine==0 and repeatRun.pollution==0,"a second call must write nothing")

mode("hard")
bridge.apply(raw,startup,active)
near(cube.crafting_speed,0.85,"Hard: speed")
near(cube.energy_source.emissions_per_minute.pollution,16000,"Hard: pollution")
mode("nightmare")
bridge.apply(raw,startup,active)
near(cube.crafting_speed,0.65,"Nightmare: speed from the first value")
near(cube.energy_source.emissions_per_minute.pollution,25000,"Nightmare: pollution")
untouched("Nightmare")

-- Normal and Custom do not undo or add anything.
mode("normal")
check(bridge.apply(raw,startup,active).machine==0,"Normal writes nothing")
mode("custom")
check(bridge.apply(raw,startup,active).machine==0,"Custom writes nothing")
check(cube.crafting_speed==0.65,"Custom changed a value")
local plain={["assembling-machine"]={["bm-bio-cube"]={
 crafting_speed=3,crafting_categories={"bm-bio-cube"},energy_source={emissions_per_minute={pollution=6100}}}}}
mode("normal")
check(bridge.apply(plain,startup,active).machine==0,"Normal with changed settings writes nothing")
check(plain["assembling-machine"]["bm-bio-cube"].crafting_speed==3,"Normal changed a value set by hand")

-- No Balack, no fabricator, a wrong type.
mode("hard")
check(bridge.apply(raw,startup,{}).machine==0,"no mods: nothing")
check(bridge.apply({["assembling-machine"]={}},startup,active).machine==0,"no fabricator: nothing")
startup["bm-cube-speed"].value="x"
check(bridge.apply({["assembling-machine"]={["bm-bio-cube"]={crafting_speed=2,
 crafting_categories={"bm-bio-cube"}}}},startup,active).machine==0,"a wrong type is not coerced")
print("PASS test_biological_machines_difficulty")
