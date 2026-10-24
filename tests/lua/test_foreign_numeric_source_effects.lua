-- Settings that Muluna and Cerys read in their own data.lua: the finished
-- prototypes are scaled by target / saved, only the named fields, only on
-- Easy, Hard and Nightmare.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,msg) if not ok then error(msg,2) end end
rawset(_G,"log",function() end)
local M=require("prototypes.compat.foreign_numeric_stage_effects")
local function fresh()
 return {recipe={
  ["space-science-pack"]={energy_required=7},
  ["interstellar-science-pack"]={ingredients={
   {type="item",name="rocket-fuel",amount=1},
   {type="fluid",name="muluna-astronomical-data",amount=10}
  }},
  ["interstellar-science-pack-cooling"]={ingredients={
   {type="fluid",name="muluna-astronomical-data",amount=10}
  }},
  ["interstellar-science-pack-cubic"]={ingredients={
   {type="fluid",name="muluna-astronomical-data",amount=20}
  }}
 },technology={
  ["cerys-electromagnetic-tooling"]={unit={count=20}},
  ["cerys-fulgoran-cryogenics"]={research_trigger={type="craft-item",count=5}},
  ["unrelated-research"]={unit={count=50}},
  ["cerys-nuclear-scrap-recycling"]={research_trigger={count=7}}
 }}
end
local startup={
 ["razi-difficulty-preset"]={value="hard"},
 ["space-science-pack-energy"]={value=7},
 ["muluna-balance-exploration-science-data-cost"]={value=10},
 ["cerys-undo-marathon-multiplier"]={value=1}
}
local enabled={["planet-muluna"]="2.7.44",["Cerys-Moon-of-Fulgora"]="4.24.18"}
local raw=fresh()
local r=M.apply(raw,startup,enabled)
check(r.recipes==3 and r.technology==2,"Hard: three recipe fields and two research counts")
check(raw.recipe["interstellar-science-pack-cooling"].ingredients[1].amount==14,"Hard: the cooling variant follows")
check(raw.recipe["interstellar-science-pack-cubic"].ingredients[1].amount==20,"the cubic variant has its own price")
check(raw.recipe["space-science-pack"].energy_required==9,"Hard: 7 -> 9")
check(raw.recipe["interstellar-science-pack"].ingredients[2].amount==14,"Hard: data cost 10 -> 14")
check(raw.recipe["interstellar-science-pack"].ingredients[1].amount==1,"another ingredient changed")
check(raw.technology["cerys-electromagnetic-tooling"].unit.count==25,"Hard: Cerys 20 -> 25")
check(raw.technology["cerys-fulgoran-cryogenics"].research_trigger.count==7,"Hard: Cerys trigger 5 -> 7")
check(raw.technology["unrelated-research"].unit.count==50,"an unrelated technology changed")
check(raw.technology["cerys-nuclear-scrap-recycling"].research_trigger.count==7,
 "a Cerys technology that does not use the multiplier changed")
local again=M.apply(raw,startup,enabled)
check(again.recipes==0 and again.technology==0,"a second call must write nothing")
startup["razi-difficulty-preset"].value="nightmare"
M.apply(raw,startup,enabled)
check(raw.recipe["space-science-pack"].energy_required==12,"Nightmare: 12 from the first value, not from Hard")
check(raw.recipe["interstellar-science-pack"].ingredients[2].amount==20,"Nightmare: data cost 20")
check(raw.technology["cerys-electromagnetic-tooling"].unit.count==34,"Nightmare: ceil(20 / 0.6)")
startup["razi-difficulty-preset"].value="easy"
M.apply(raw,startup,enabled)
check(raw.recipe["space-science-pack"].energy_required==5,"Easy: 5")
check(raw.technology["cerys-electromagnetic-tooling"].unit.count==14,"Easy: ceil(20 / 1.5)")

-- Normal and Custom write nothing.
for _,level in ipairs({"normal","custom"}) do
 startup["razi-difficulty-preset"].value=level
 local plain=fresh()
 local result=M.apply(plain,startup,enabled)
 check(result.recipes==0 and result.technology==0,level.." must write nothing")
 check(plain.recipe["space-science-pack"].energy_required==7,level.." changed a recipe")
 check(plain.technology["cerys-electromagnetic-tooling"].unit.count==20,level.." changed a technology")
end

-- A saved value that is not the default: the ratio is target / saved, so the
-- result is what the owner would have built with the target.
startup["razi-difficulty-preset"].value="hard"
local tech={unit={count=10}}
startup["cerys-undo-marathon-multiplier"].value=2
local changed=M.apply({technology={["cerys-electromagnetic-tooling"]=tech}},startup,
 {["Cerys-Moon-of-Fulgora"]="4.24.18"})
check(changed.technology==1 and tech.unit.count==25,"saved 2 -> target 0.8: ceil(10 * 2 / 0.8)")
startup["cerys-undo-marathon-multiplier"].value=1

-- Missing prototypes are not made up, mods that are not installed are skipped.
check(M.apply({recipe={}},startup,{}).recipes==0,"no mods: no change")
check(M.apply({},startup,enabled).recipes==0,"no prototypes: no change")
check(M.apply({recipe={["space-science-pack"]={energy_required=7}}},startup,{}).recipes==0,
 "Muluna is not installed: its recipe stays")
-- Every Cerys technology is listed once, and the list holds only Cerys names.
local listed={}
for _,name in ipairs(M.cerys_technologies) do
 check(not listed[name],name.." is listed twice")
 listed[name]=true
end
check(#M.cerys_technologies==16,"Cerys builds 16 research counts with the multiplier")
print("PASS test_foreign_numeric_source_effects")
