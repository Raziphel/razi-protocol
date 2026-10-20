-- Run from the Razi Protocol root with: texlua tests/test_required_mod_difficulty.lua
-- Pure-Lua mock of source prototypes; no Factorio game or file mutations.
local mode="normal"
local overrides={}
local values={
 easy={["razi-factory-throughput"]="boosted",
   ["razi-fortification-durability"]="reinforced",
   ["razi-grid-resilience"]="robust"},
 normal={["razi-factory-throughput"]="normal",
   ["razi-fortification-durability"]="normal",
   ["razi-grid-resilience"]="normal"},
 hard={["razi-factory-throughput"]="constrained",
   ["razi-fortification-durability"]="fragile",
   ["razi-grid-resilience"]="limited"},
 nightmare={["razi-factory-throughput"]="strained",
   ["razi-fortification-durability"]="brittle",
   ["razi-grid-resilience"]="precarious"}
}
local resolver={
 effective=function(setting,default)
   return overrides[setting] or values[mode][setting] or default
 end
}
package.loaded["scripts.razi_difficulty_presets"]=resolver
local industrial=require("prototypes.compat.razi_industrial_difficulty")
local power=require("prototypes.compat.razi_power_difficulty")
local raw={
 ["assembling-machine"]={a={crafting_speed=1.5}},
 furnace={f={crafting_speed=2}},
 ["mining-drill"]={m={mining_speed=3},invalid={mining_speed="fast"}},
 lab={basic={},advanced={researching_speed=2}},
 wall={w={max_health=200}},
 gate={g={max_health=100}},
 ["ammo-turret"]={t={max_health=100,minable={result="ammo-turret"}}},
 ["electric-turret"]={t={max_health=120,placeable_by={item="laser"}}},
 ["fluid-turret"]={scripted={max_health=300}},
 turret={worm={max_health=200}},
 ["solar-panel"]={s={production="60kW"},weird={production="unparseable"}},
 accumulator={a={energy_source={type="electric",buffer_capacity="5MJ",
   input_flow_limit="300kW",output_flow_limit="300kW"}}}
}
local function eq(actual,expected,label)
 if actual~=expected then error(label..": got "..tostring(actual)..
   ", expected "..tostring(expected)) end
end
local function near(actual,expected,label)
 if math.abs(actual-expected)>0.000001 then
   error(label..": got "..tostring(actual)..", expected "..tostring(expected))
 end
end
local function applied()
 return industrial.apply(raw,resolver),power.apply(raw,resolver)
end
mode="easy"
local a,b=applied()
near(raw["assembling-machine"].a.crafting_speed,1.725,"easy assembler")
near(raw.furnace.f.crafting_speed,2.3,"easy furnace")
near(raw["mining-drill"].m.mining_speed,3.45,"easy mod miner")
eq(raw["mining-drill"].invalid.mining_speed,"fast","unparseable drill")
near(raw.lab.basic.researching_speed,1.15,"implicit lab default")
near(raw.lab.advanced.researching_speed,2.3,"mod lab")
eq(raw.wall.w.max_health,250,"wall")
eq(raw["ammo-turret"].t.max_health,125,"buildable turret")
eq(raw["electric-turret"].t.max_health,150,"placeable-by turret")
eq(raw["fluid-turret"].scripted.max_health,300,"scripted turret untouched")
eq(raw.turret.worm.max_health,200,"enemy worm untouched")
eq(raw["solar-panel"].s.production,"72kW","easy solar")
eq(raw.accumulator.a.energy_source.buffer_capacity,"6MJ","easy accumulator")
eq(raw.accumulator.a.energy_source.input_flow_limit,"300kW","flow unchanged")
eq(raw["solar-panel"].weird.production,"unparseable","invalid power untouched")
eq(a.mining_drills,1,"one valid miner")
eq(a.laboratories,2,"two labs")
eq(b.solar_panels,1,"one solar panel")
local unchanged1,unchanged2=applied()
eq(unchanged1.factories,0,"idempotent factory pass")
eq(unchanged2.accumulators,0,"idempotent accumulator pass")
mode="normal"
applied()
near(raw["assembling-machine"].a.crafting_speed,1.5,"normal assembler")
near(raw["mining-drill"].m.mining_speed,3,"normal mining")
eq(raw.lab.basic.researching_speed,nil,"restore native implicit lab speed")
eq(raw["ammo-turret"].t.max_health,100,"normal turret")
eq(raw["solar-panel"].s.production,"60kW","normal solar")
eq(raw.accumulator.a.energy_source.buffer_capacity,"5MJ","normal capacity")
mode="hard"
applied()
near(raw["mining-drill"].m.mining_speed,2.76,"hard miner")
eq(raw["ammo-turret"].t.max_health,90,"hard turret")
eq(raw["solar-panel"].s.production,"54kW","hard solar")
eq(raw.accumulator.a.energy_source.buffer_capacity,"4.5MJ","hard battery")
mode="nightmare"
applied()
near(raw["mining-drill"].m.mining_speed,2.46,"nightmare miner")
eq(raw["ammo-turret"].t.max_health,78,"nightmare turret")
eq(raw["solar-panel"].s.production,"48kW","nightmare solar")
eq(raw.accumulator.a.energy_source.buffer_capacity,"4MJ","nightmare battery")
overrides={
 ["razi-factory-throughput"]="boosted",
 ["razi-fortification-durability"]="reinforced",
 ["razi-grid-resilience"]="robust"}
applied()
near(raw["mining-drill"].m.mining_speed,3.45,"independent throughput override")
eq(raw["ammo-turret"].t.max_health,125,"independent turret override")
eq(raw["solar-panel"].s.production,"72kW","independent power override")
print("OK: cross-mod mining, labs, defenses and power difficulty regression tests")
