-- Four middle-star factory profiles, requiring real native suppliers.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,why) if not ok then error(why,2) end end
local captured
package.loaded["prototypes.compat.planet_production_exchanges"]={
  register_additional=function(rules) captured=rules end}
local module=require("prototypes.compat.middle_frontier_industry")
module.data_final_fixes()
check(#captured==4,"Expected four distinct middle-frontier workshops")
local wanted={
 ["razi-middle-fulgora-resilient-capacitors"]="fulgora",
 ["razi-middle-aquilo-capacitor-controls"]="aquilo",
 ["razi-middle-paracelsin-shielded-coils"]="paracelsin",
 ["razi-middle-rubia-conductive-frames"]="rubia"
}
local seen={}
for _,rule in ipairs(captured) do
  check(wanted[rule.name]==rule.working_world and not seen[rule.name],
    "Factory in wrong chapter, or duplicate prototype")
  seen[rule.name]=true
  check(rule.bonus==1 and rule.batch==4 and
    rule.max_bonus_fraction==0.25 and rule.require_supplier_provenance,
    "Missing native recipe, output or provenance guards")
  check(rule.time_multiplier>=1.1 and rule.time_multiplier<=1.2,
    "Unbalanced freight time penalty")
  check(#rule.science==2 and rule.science[1]=="vibrant-tech-card"
    and rule.science[2]=="vespera-tech-card",
    "True middle industry needs both system research cards")
  local suppliers={}
  for _,s in ipairs(rule.supplier_recipes) do
    suppliers[s.product]=true
  end
  for _,ingredient in ipairs(rule.additional) do
    check(suppliers[ingredient.name] and ingredient.type=="item" and
      ingredient.amount>0,"Imported cargo has no named native supplier")
  end
  check(#rule.not_after==2,"Every source producer needs late-gate guards")
end
for name in pairs(wanted) do check(seen[name],"Missing "..name) end
print("Vibrant/Vespera native factory profiles and source guards passed")
