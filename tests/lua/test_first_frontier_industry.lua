---@diagnostic disable: missing-fields, need-check-nil, assign-type-mismatch, undefined-field, param-type-mismatch, inject-field
-- Keep optional first-frontier freight independent of native research.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,msg) if not ok then error(msg,2) end end
local captured={}
-- Modpack fixture: Castra overrides the native magazine crafting category.
data={raw={recipe={
  ["piercing-rounds-magazine"]={
    name="piercing-rounds-magazine",category="castra-crafting"}
}}}
package.loaded["prototypes.compat.planet_production_exchanges"]={
  register_additional=function(rules) captured=rules end
}
local frontier=require("prototypes.compat.first_frontier_industry")
frontier.data_final_fixes()
check(#captured==1,"Expected one optional frontier production alternative")
local recipe=captured[1]
check(recipe.name=="razi-frontier-castra-composite-rounds",
  "Unexpected exchange rule")
check(recipe.working_world=="castra" and recipe.source=="piercing-rounds-magazine",
  "Native recipe or world changed for "..recipe.name)
check(recipe.product==recipe.source and recipe.keep_native_category,
  "Only native-product alternatives in original categories are allowed")
check(recipe.category=="castra-crafting",
  "Castra piercing rounds must retain castra-crafting, not base crafting")
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
check(imported["carbon-fiber"] and imported["silicon-cell"],
  "Castra must import Gleba carbon fiber and Moshine silicon cells")
check(#recipe.planets>=3,"This must genuinely connect several worlds")
-- A different source-mod version can change the category again.
data.raw.recipe["piercing-rounds-magazine"].category="castra-special-assembly"
package.loaded["prototypes.compat.first_frontier_industry"]=nil
require("prototypes.compat.first_frontier_industry").data_final_fixes()
check(captured[1].category=="castra-special-assembly",
  "Castra bridge must use the current source category, not a hardcoded guess")
print("First-frontier manufacturing rules and provenance passed")
