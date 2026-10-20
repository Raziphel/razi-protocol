-- Factorio/K2SO prototype throughput and fortification durability.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(x,msg) if not x then error(msg,2) end end
local engine=require("prototypes.compat.razi_industrial_difficulty")
local resolver=require("scripts.razi_difficulty_presets")
local function select(mode)
 local startup={["razi-difficulty-preset"]={value=mode}}
 for name,value in pairs(resolver.baseline) do
  startup[name]={value=value}
 end
 rawset(_G,"settings",{startup=startup})
end
local raw={
 ["assembling-machine"]={
   vanilla={crafting_speed=1.25,max_health=300},
   k2so={crafting_speed=3,max_health=700}},
 furnace={furnace={crafting_speed=2,max_health=250}},
 wall={stone={max_health=350},hardened={max_health=1000}},
 gate={gate={max_health=350}},
 unit={biter={max_health=100}}
}
select("easy")
local changes=engine.apply(raw,resolver)
check(changes.factories==3 and changes.defenses==3,
 "Easy should adjust all compatible source entities")
check(math.abs(raw["assembling-machine"].k2so.crafting_speed-3.45)<.00001,
 "K2SO factory's crafting speed was not modified")
check(raw.wall.hardened.max_health==1250,
 "Modded walls weren't reinforced on Easy")
check(raw.unit.biter.max_health==100,"Never edit enemy health")
changes=engine.apply(raw,resolver)
check(changes.factories==0 and changes.defenses==0,
 "An extra final-fixes call must not compound modifiers")
select("nightmare")
engine.apply(raw,resolver)
check(raw.wall.hardened.max_health==780,
 "Nightmare must use original maximum health")
check(math.abs(raw.furnace.furnace.crafting_speed-1.64)<.00001,
 "Nightmare furnaces must run more slowly")
print("Cross-mod industry and fortification presets passed")
