-- Pure Lua: texlua tests/test_foreign_numeric_source_effects.lua
package.path="./?.lua;./?/init.lua;"..package.path
local M=require("prototypes.compat.foreign_numeric_stage_effects")
local raw={recipe={
 ["space-science-pack"]={energy_required=7},
 ["interstellar-science-pack"]={ingredients={
  {type="item",name="rocket-fuel",amount=1},
  {type="fluid",name="muluna-astronomical-data",amount=10}
 }}
},technology={
 ["cerys-electromagnetic-tooling"]={unit={count=20}},
 ["cerys-fulgoran-cryogenics"]={research_trigger={type="craft-item",count=5}},
 ["unrelated-research"]={unit={count=50}},
 ["cerys-nuclear-scrap-recycling"]={research_trigger={count=7}}
}}
local startup={
 ["razi-difficulty-preset"]={value="hard"},
 ["space-science-pack-energy"]={value=7},
 ["muluna-balance-exploration-science-data-cost"]={value=10},
 ["cerys-undo-marathon-multiplier"]={value=1}
}
local enabled={["planet-muluna"]="2.7",["Cerys-Moon-of-Fulgora"]="4.24"}
local r=M.apply(raw,startup,enabled)
assert(r.recipes==2 and r.technology==2,"expected exact source field updates")
assert(raw.recipe["space-science-pack"].energy_required==9)
assert(raw.recipe["interstellar-science-pack"].ingredients[2].amount==14)
assert(raw.recipe["interstellar-science-pack"].ingredients[1].amount==1)
assert(raw.technology["cerys-electromagnetic-tooling"].unit.count==25)
assert(raw.technology["cerys-fulgoran-cryogenics"].research_trigger.count==7)
assert(raw.technology["unrelated-research"].unit.count==50)
assert(raw.technology["cerys-nuclear-scrap-recycling"].research_trigger.count==7)
local repeatRun=M.apply(raw,startup,enabled)
assert(repeatRun.recipes==0 and repeatRun.technology==0,"should be idempotent")
startup["razi-difficulty-preset"].value="nightmare"
M.apply(raw,startup,enabled)
assert(raw.recipe["space-science-pack"].energy_required==12)
assert(raw.recipe["interstellar-science-pack"].ingredients[2].amount==20)
assert(raw.technology["cerys-electromagnetic-tooling"].unit.count==34)
startup["razi-difficulty-preset"].value="normal"
M.apply(raw,startup,enabled)
assert(raw.recipe["space-science-pack"].energy_required==7)
assert(raw.recipe["interstellar-science-pack"].ingredients[2].amount==10)
assert(raw.technology["cerys-electromagnetic-tooling"].unit.count==20)
startup["razi-difficulty-preset"].value="custom"
assert(M.apply(raw,startup,enabled).recipes==0,"Custom has no effect")
-- Source mod options with non-default manual values are preserved in ratio.
local tech={unit={count=10}}
local changed=M.apply({technology={["cerys-electromagnetic-tooling"]=tech}},{
 ["razi-difficulty-preset"]={value="hard"},
 ["cerys-undo-marathon-multiplier"]={value=2}},{
 ["Cerys-Moon-of-Fulgora"]="4.24"})
assert(changed.technology==1)
assert(tech.unit.count==25,"saved multiplier/target ratio")
-- Do not fabricate missing prototypes or affect disabled mods.
assert(M.apply({recipe={}},startup,{}).recipes==0)
print("Foreign numeric source effects for Muluna and Cerys: PASS")
