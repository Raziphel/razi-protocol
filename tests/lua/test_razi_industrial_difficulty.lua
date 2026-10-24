-- Factory speed and wall strength of the difficulty level: machines, furnaces,
-- walls and gates players build; what is left alone; Normal writes nothing.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,msg) if not ok then error(msg,2) end end
rawset(_G,"log",function() end)
local engine=require("prototypes.compat.razi_industrial_difficulty")
local resolver=require("scripts.razi_difficulty_presets")
local function selected(mode,overrides)
 local startup={["razi-difficulty-preset"]={value=mode}}
 for name,value in pairs(resolver.baseline) do startup[name]={value=value} end
 for name,value in pairs(overrides or {}) do startup[name]={value=value} end
 rawset(_G,"settings",{startup=startup})
end
-- Items that place the buildable entities. "scripted", "helper" and the wreck
-- have no item; "variant" and "variant2" are mined into the item of a machine.
local function raw()
 return {
  item={
   assembler={place_result="assembler"},
   k2={place_result="k2"},
   scanner={place_result="scanner"},
   hidden={place_result="hidden"},
   broken={place_result="broken"},
   kiln={place_result="kiln"},
   ["stone-wall"]={place_result="stone-wall"},
   hardened={place_result="hardened"},
   gate={place_result="gate"},
   bridge={place_result="bridge"},
   ["iron-plate"]={stack_size=100},
  },
  ["assembling-machine"]={
   assembler={crafting_speed=1.25,max_health=300},
   k2={crafting_speed=3,max_health=700},
   scanner={crafting_speed=1,fixed_recipe="scan"},
   hidden={crafting_speed=1,hidden=true},
   variant={crafting_speed=1,hidden=true,minable={result="assembler"}},
   variant2={crafting_speed=2,hidden=true,
    minable={results={{type="item",name="k2",amount=1}}}},
   scripted={crafting_speed=1},
   helper={crafting_speed=1,hidden=true,minable={result="iron-plate"}},
   wreck={crafting_speed=1,fixed_recipe="repair"},
   broken={crafting_speed=0},
  },
  furnace={kiln={crafting_speed=2,max_health=250}},
  wall={["stone-wall"]={max_health=350},hardened={max_health=1000},
   unplaced={max_health=500}},
  gate={gate={max_health=350},bridge={max_health=1000,hidden=true}},
  unit={biter={max_health=100,crafting_speed=7}},
  turret={gun={max_health=400}},
  ["rocket-silo"]={silo={crafting_speed=1,max_health=5000,rocket_parts_required=50}},
 }
end
local function near(a,b) return math.abs(a-b)<.00001 end

-- Normal: nothing changes.
selected("normal")
local data_raw=raw()
local count=engine.apply(data_raw,resolver)
check(count.factories==0 and count.defenses==0,"Normal must write nothing")
check(data_raw["assembling-machine"].k2.crafting_speed==3,"Normal changed a speed")
check(data_raw.wall.hardened.max_health==1000,"Normal changed a wall")

-- Easy: all buildable machines, walls and gates.
selected("easy")
data_raw=raw()
count=engine.apply(data_raw,resolver)
check(count.factories==6 and count.defenses==4,
 "Easy: 6 machines, 4 walls and gates, got "..count.factories.."/"..count.defenses)
check(near(data_raw["assembling-machine"].k2.crafting_speed,3.45),"Easy: k2 speed")
check(near(data_raw.furnace.kiln.crafting_speed,2.3),"Easy: furnace speed")
check(near(data_raw["assembling-machine"].hidden.crafting_speed,1.15),
 "Easy: a hidden machine that an item places is built by players")
check(near(data_raw["assembling-machine"].variant.crafting_speed,1.15),
 "Easy: a variant mined into a machine item")
check(near(data_raw["assembling-machine"].variant2.crafting_speed,2.3),
 "Easy: a variant with a result list")
check(data_raw.wall.hardened.max_health==1250,"Easy: modded wall")
check(data_raw.gate.gate.max_health==438,"Easy: gate health is rounded")
check(data_raw["assembling-machine"].assembler.max_health==300,
 "Machine health is not a lever")

-- What is left alone, at every level.
for _,level in ipairs({"easy","hard","nightmare"}) do
 selected(level)
 data_raw=raw()
 count=engine.apply(data_raw,resolver)
 local m=data_raw["assembling-machine"]
 check(m.scanner.crafting_speed==1,level..": fixed recipe machine scaled")
 check(m.wreck.crafting_speed==1,level..": wreck scaled")
 check(m.scripted.crafting_speed==1,level..": machine no item places scaled")
 check(m.helper.crafting_speed==1,level..": helper mined into a plate scaled")
 check(m.broken.crafting_speed==0,level..": zero speed changed")
 check(data_raw.wall.unplaced.max_health==500,level..": unplaced wall scaled")
 check(data_raw.unit.biter.max_health==100 and data_raw.unit.biter.crafting_speed==7,
  level..": enemy units are never edited")
 check(data_raw.turret.gun.max_health==400,level..": turrets are never edited")
 local silo=data_raw["rocket-silo"].silo
 check(silo.crafting_speed==1 and silo.max_health==5000,level..": silo scaled here")
 check(count.skipped==4,level..": 4 machines left out, got "..count.skipped)
end

-- A second call never compounds; a later level reads the first value.
selected("hard")
data_raw=raw()
engine.apply(data_raw,resolver)
check(near(data_raw["assembling-machine"].k2.crafting_speed,2.76),"Hard: k2 speed")
check(data_raw.wall.hardened.max_health==900,"Hard: modded wall")
check(data_raw.gate.bridge.max_health==900,"Hard: a hidden gate that an item places")
count=engine.apply(data_raw,resolver)
check(count.factories==0 and count.defenses==0,"A second call must not compound")
selected("nightmare")
engine.apply(data_raw,resolver)
check(data_raw.wall.hardened.max_health==780,"Nightmare reads the first health")
check(near(data_raw.furnace.kiln.crafting_speed,1.64),"Nightmare reads the first speed")

-- Each lever by hand; a missing table does not fail.
selected("normal",{["razi-factory-throughput"]="strained"})
data_raw=raw()
count=engine.apply(data_raw,resolver)
check(count.factories==6 and count.defenses==0,"Only the lever that was set applies")
selected("hard")
check(engine.apply({},resolver).factories==0,"No machines at all")
check(engine.apply(nil,resolver).defenses==0,"No data.raw at all")

-- Balack's bio fabricator: its own setting covers Easy, Hard and Nightmare
-- when Balack is installed; Custom and the lever by hand still scale it.
local function with_cube()
 local r=raw()
 r.item.cube={place_result="cube"}
 r["assembling-machine"].cube={crafting_speed=1,crafting_categories={"bm-bio-cube"}}
 return r
end
rawset(_G,"mods",{["biological-machines-planet-balack"]="1.1.2"})
selected("hard")
data_raw=with_cube()
engine.apply(data_raw,resolver)
check(data_raw["assembling-machine"].cube.crafting_speed==1,
 "Hard: the bio fabricator follows Balack's setting only")
check(near(data_raw["assembling-machine"].k2.crafting_speed,2.76),"Hard: other machines still scale")
selected("custom",{["razi-factory-throughput"]="strained"})
data_raw=with_cube()
engine.apply(data_raw,resolver)
check(near(data_raw["assembling-machine"].cube.crafting_speed,.82),
 "Custom: the lever by hand scales the bio fabricator")
rawset(_G,"mods",{})
selected("hard")
data_raw=with_cube()
engine.apply(data_raw,resolver)
check(near(data_raw["assembling-machine"].cube.crafting_speed,.92),
 "Without Balack the machine is an ordinary factory")
rawset(_G,"mods",nil)
print("Factory speed and wall strength passed")
