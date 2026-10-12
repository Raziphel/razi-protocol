-- Lightweight catalog/provenance tests: independent of Factorio's data stage.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(v,s) if not v then error(s,2) end end
local calls={}
package.loaded["prototypes.compat.planet_production_exchanges"]={
 register_additional=function(r) calls[#calls+1]=r end,
 register_k2so=function(r) calls[#calls+1]=r end
}
package.loaded["prototypes.compat.galactic_industry_bridges"]=nil
require("prototypes.compat.galactic_industry_bridges").data_final_fixes()
check(#calls==3 and #calls[1]==9 and #calls[2]==3 and #calls[3]==1,
  "Unbalanced partition of the multi-world industrial catalog")
local discovered={}
local total=0
for index,group in ipairs(calls) do
 for _,rule in ipairs(group) do
  total=total+1
  check(not discovered[rule.name],"Duplicate optional industry: "..rule.name)
  discovered[rule.name]=true
  check(#rule.planets>=3 and #rule.additional>=2,
    "A multi-world process lost suppliers: "..rule.name)
  check(rule.max_bonus_fraction==0.25 and rule.require_supplier_provenance,
    "Bonus/provenance safety guard missing: "..rule.name)
  -- These three source templates intentionally use Razi's existing
  -- metallurgy or Aquilo cryogenic category rather than the source
  -- recipe category. All other new variants preserve native categories.
  local converted=rule.source=="gold-plate"
    or rule.source=="vesta-foundation"
    or rule.source=="kr-energy-control-unit"
  check(rule.keep_native_category or converted,
    "Native category restriction unexpectedly removed: "..rule.name)
  check(rule.time_multiplier>=1.15 and rule.time_multiplier<=1.2,
    "Unbounded time advantage: "..rule.name)
  if index==1 then check(not rule.deep_only,"Deep recipe escaped into Balanced")
  else check(rule.deep_only,"Deep-only recipe lacks protection") end
  local seen={}
  for _,extra in ipairs(rule.additional) do
   check(extra.type=="item" and extra.amount>0,"Nonportable industrial import")
   check(not seen[extra.name],"Repeated material in one bonus recipe")
   seen[extra.name]=true
   local source=false
   for _,supplier in ipairs(rule.supplier_recipes) do
    if supplier.product==extra.name then source=true end
   end
   check(source,"Import has no declared source producer: "..extra.name)
  end
  check(seen[rule.bonus_icon],"Visual bonus icon must describe an import")
 end
end
check(total==13,"Unexpected new module recipe count")
local h=assert(io.open("data-final-fixes.lua","r"))
local s=h:read("*a") h:close()
check(s:find('require("prototypes.compat.galactic_industry_bridges").data_final_fixes()',1,true),
 "Catalog missing from last data-stage entrypoint")
print("Galactic industry 13 bonus catalogs and import safeguards passed")
