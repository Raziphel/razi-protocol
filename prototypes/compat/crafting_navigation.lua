-- Visual-only recipe navigation. No category, ingredients, results, technology,
-- machine or source item changes. Spoilable grouping is opt-in.
local M={}
local function enabled(name,default)
  local option=settings and settings.startup and settings.startup[name]
  if option then return option.value end
  return default
end
local function subgroup(name,group,order)
  if not (data.raw["item-group"] and data.raw["item-group"][group]) then
    return false
  end
  if not (data.raw["item-subgroup"] and data.raw["item-subgroup"][name]) then
    data:extend({{type="item-subgroup",name=name,group=group,order=order}})
  end
  return true
end
local function barrel_recipe(name)
  return name:match("^fill%-.+%-barrel$")~=nil
    or name:match("^empty%-.+%-barrel$")~=nil
end
local function perishable_result(recipe)
  if recipe.hidden then return false end
  local products=recipe.results
  if not products or #products~=1 then return false end
  local product=products[1]
  if product.type=="fluid" then return false end
  local item=data.raw.item and data.raw.item[product.name or product[1]]
  if not item or type(item.spoil_ticks)~="number"
    or item.spoil_ticks<=0 then return false end
  local current=data.raw["item-subgroup"]
    and data.raw["item-subgroup"][recipe.subgroup or item.subgroup]
  return current and current.group=="intermediate-products" or false
end
function M.data_final_fixes()
  local barrel=enabled("razi-group-barreling-recipes",true)
    and subgroup("razi-fluid-barreling","fluids","z[razi-barreling]")
  local perishables=enabled("razi-group-spoilable-recipes",false)
    and subgroup("razi-perishable-products","intermediate-products",
      "z[razi-perishables]")
  if not barrel and not perishables then return end
  for name,recipe in pairs(data.raw.recipe or {}) do
    if not recipe.hidden then
      if barrel and barrel_recipe(name) then
        recipe.subgroup="razi-fluid-barreling"
      elseif perishables and perishable_result(recipe) then
        recipe.subgroup="razi-perishable-products"
      end
    end
  end
end
M.barrel_recipe=barrel_recipe
M.perishable_result=perishable_result
return M
