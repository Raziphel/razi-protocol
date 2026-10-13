-- Keep optional first-frontier freight independent of native research.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,msg) if not ok then error(msg,2) end end
local captured={}
package.loaded["prototypes.compat.planet_production_exchanges"]={
  register_additional=function(rules) captured=rules end
}
local frontier=require("prototypes.compat.first_frontier_industry")
frontier.data_final_fixes()
check(#captured==3,"Expected three optional frontier production alternatives")
local recipes={}
local required={
 ["razi-frontier-moshine-biometal-silicon"]={
   world="moshine",source="silicon-cell",
   imports={["kr-rare-metals"]=true,bioflux=true}},
 ["razi-frontier-gleba-photofiber"]={
   world="gleba",source="carbon-fiber",
   imports={["kr-rare-metals"]=true,["optical-cable"]=true}},
 ["razi-frontier-castra-composite-rounds"]={
   world="castra",source="piercing-rounds-magazine",
   imports={["carbon-fiber"]=true,["silicon-cell"]=true}}
}
for _,recipe in ipairs(captured) do
  local spec=required[recipe.name]
  check(spec and not recipes[recipe.name],"Unexpected or repeated exchange rule")
  recipes[recipe.name]=true
  check(recipe.working_world==spec.world and recipe.source==spec.source,
    "Native recipe or world changed for "..recipe.name)
  check(recipe.product==recipe.source and recipe.keep_native_category,
    "Only native-product alternatives in original categories are allowed")
  check(recipe.require_supplier_provenance and
    recipe.max_bonus_fraction==0.25 and recipe.batch==4 and recipe.bonus==1,
    "Bonus or provenance guard missing from "..recipe.name)
  check(recipe.time_multiplier>=1.1 and recipe.time_multiplier<=1.2,
    "Invalid crafting-time overhead")
  check(#recipe.science==2 and recipe.science[1]=="solaris-tech-card"
    and recipe.science[2]=="nyxaris-tech-card",
    "Both early-star cards are needed for "..recipe.name)
  local supplied={}
  for _,supplier in ipairs(recipe.supplier_recipes) do
    supplied[supplier.product]=true
  end
  local imported={}
  for _,ingredient in ipairs(recipe.additional) do
    check(ingredient.type=="item" and ingredient.amount>0,
      "Freight ingredients must be ordinary, positive item costs")
    imported[ingredient.name]=true
    check(supplied[ingredient.name],"Missing native producer for imported cargo")
  end
  for name in pairs(spec.imports) do
    check(imported[name],"Expected native freight input "..name)
  end
  check(#recipe.planets>=3,"This must genuinely connect several worlds")
end
for name in pairs(required) do check(recipes[name],"Missing "..name) end
print("First-frontier manufacturing rules and provenance passed")
