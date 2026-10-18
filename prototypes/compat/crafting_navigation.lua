-- Navigation-only recipe grouping; never modify ingredients, results,
-- crafting categories, technologies or source items. Spoilables are opt-in.
local M={}
local function enabled(name,default)
  local option=settings and settings.startup and settings.startup[name]
  if option then return option.value end
  return default
end
local function subgroup(name,group,order)
  if not (data.raw["item-group"] and data.raw["item-group"][group]) then return false end
  if not (data.raw["item-subgroup"] and data.raw["item-subgroup"][name]) then
    data:extend({{type="item-subgroup",name=name,group=group,order=order}})
  end
  return true
end
local function has(entries,kind,test)
  for _,entry in ipairs(entries or {}) do
    local entry_kind=entry.type or "item"
    local name=entry.name or entry[1]
    if entry_kind==kind and type(name)=="string" and test(name) then
      return true
    end
  end
  return false
end
local function is_filled_barrel(name)
  return name~="empty-barrel" and name:match("%-barrel$")~=nil
end
local function barrel_recipe(name,recipe)
  if not recipe then return false end
  local filling=name:match("^fill%-.+%-barrel$")~=nil
  local emptying=name:match("^empty%-.+%-barrel$")~=nil
  if not filling and not emptying then return false end
  local inputs,outputs=recipe.ingredients or {},recipe.results or {}
  if filling then
    return has(inputs,"fluid",function() return true end)
      and has(inputs,"item",function(n) return n=="empty-barrel" end)
      and has(outputs,"item",is_filled_barrel)
  end
  return has(inputs,"item",is_filled_barrel)
    and has(outputs,"fluid",function() return true end)
    and has(outputs,"item",function(n) return n=="empty-barrel" end)
end
-- Respect explicitly customized source groups rather than taking over
-- unrelated mod-owned recipe tabs merely because a name matches.
local function source_fluid_group(recipe)
  local source=recipe.subgroup
  if not source then return true end
  local prototype=data.raw["item-subgroup"] and data.raw["item-subgroup"][source]
  return prototype and prototype.group=="fluids" or false
end
local function perishable_result(recipe)
  if recipe.hidden or recipe.hide_from_player_crafting then return false end
  local products=recipe.results
  if not products or #products~=1 then return false end
  local product=products[1]
  if (product.type or "item")=="fluid" then return false end
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
    if not recipe.hidden and not recipe.hide_from_player_crafting then
      if barrel and source_fluid_group(recipe) and barrel_recipe(name,recipe) then
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
