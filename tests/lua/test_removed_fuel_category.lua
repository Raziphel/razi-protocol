---@diagnostic disable: missing-fields
package.path = "./?.lua;./?/init.lua;" .. package.path
local function check(value, message)
  if not value then error(message, 2) end
end
rawset(_G,"log",function() end)
local raw={
  item={
    ["kausimatic-crystal"]={fuel_category="alchemical-fuel",fuel_value="150kW"},
    ["coal"]={fuel_categories={"chemical"},fuel_value="4MJ"},
    ["iron-plate"]={},
    ["both"]={fuel_category="old",fuel_categories={"new"}}
  },
  capsule={["ambrosia"]={fuel_category="nutrients"}},
  ["utility-constants"]={default={}}
}
rawset(_G,"data",{raw=raw})
local fix=require("prototypes.compat.removed_fuel_category")
fix.data_final_fixes()
local crystal=raw.item["kausimatic-crystal"]
check(crystal.fuel_category==nil,"fuel_category is left on the item")
check(#crystal.fuel_categories==1 and crystal.fuel_categories[1]=="alchemical-fuel",
  "fuel_category was not moved into fuel_categories")
check(raw.capsule["ambrosia"].fuel_categories[1]=="nutrients",
  "Item subtypes other than item are not converted")
check(raw.item["coal"].fuel_categories[1]=="chemical" and #raw.item["coal"].fuel_categories==1,
  "An item that already uses fuel_categories was changed")
check(raw.item["iron-plate"].fuel_categories==nil,"A non-fuel item got fuel categories")
check(raw.item["both"].fuel_category==nil and raw.item["both"].fuel_categories[1]=="new"
  and #raw.item["both"].fuel_categories==1,
  "fuel_categories set by the mod was overwritten")
fix.data_final_fixes()
check(#crystal.fuel_categories==1,"The fix is not idempotent")
print("test_removed_fuel_category: ok")
