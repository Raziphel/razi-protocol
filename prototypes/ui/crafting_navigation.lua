-- Recipe navigation and player crafting-menu cleanup.
-- No ingredient, product, technology, crafting category or enablement edits.
local M = {}

local function option(name, fallback)
  local entry = settings and settings.startup and settings.startup[name]
  if entry then return entry.value end
  return fallback
end

local function subgroup(name, group, order)
  if not (data.raw["item-group"] and data.raw["item-group"][group]) then
    return false
  end
  if not (data.raw["item-subgroup"] and data.raw["item-subgroup"][name]) then
    data:extend({{type="item-subgroup",name=name,group=group,order=order}})
  end
  return true
end

local function barrel_recipe(_, recipe)
  if not recipe then return false end
  local inputs, outputs = recipe.ingredients or {}, recipe.results or {}

  -- Factorio 2.x names filled-barrel recipes after their product and hides
  -- them from player crafting. Their subgroup and ingredients identify them.
  if recipe.subgroup == "fill-barrel"
    or recipe.subgroup == "empty-barrel" then
    return true
  end

  local function item(entry, expected)
    return (entry.type or "item") == "item"
      and (entry.name or entry[1]) == expected
      and (entry.amount == nil or entry.amount == 1)
  end
  local function fluid(entry)
    return entry.type == "fluid"
  end

  if #inputs == 2 and #outputs == 1 then
    local fluid_input, barrel_input = false, false
    for _, entry in ipairs(inputs) do
      if fluid(entry) then
        fluid_input = true
      elseif item(entry, "barrel") then
        barrel_input = true
      else
        return false
      end
    end
    local product = outputs[1]
    return fluid_input and barrel_input
      and (product.type or "item") == "item"
      and (product.amount == nil or product.amount == 1)
  end

  if #inputs == 1 and #outputs == 2 then
    local ingredient = inputs[1]
    if (ingredient.type or "item") ~= "item"
      or (ingredient.name or ingredient[1]) == "barrel"
      or (ingredient.amount ~= nil and ingredient.amount ~= 1) then
      return false
    end
    local fluid_output, barrel_output = false, false
    for _, entry in ipairs(outputs) do
      if fluid(entry) then
        fluid_output = true
      elseif item(entry, "barrel") then
        barrel_output = true
      else
        return false
      end
    end
    return fluid_output and barrel_output
  end
  return false
end

local function perishable_result(recipe)
  if recipe.hidden or recipe.hide_from_player_crafting then return false end
  local products = recipe.results
  if not products or #products ~= 1 then return false end
  local product = products[1]
  if (product.type or "item") == "fluid" then return false end
  local item = data.raw.item and data.raw.item[product.name or product[1]]
  if not item or type(item.spoil_ticks) ~= "number"
    or item.spoil_ticks <= 0 then return false end
  local current = data.raw["item-subgroup"]
    and data.raw["item-subgroup"][recipe.subgroup or item.subgroup]
  return current and current.group == "intermediate-products" or false
end

-- Union character categories to avoid hiding recipes usable by alternative
-- modded characters or the sandbox/god controller. The vanilla fallback is
-- ordinary crafting, even when a prototype leaves categories unspecified.
local function hand_categories()
  local allowed = {crafting=true}
  for _, kind in ipairs({"character","god-controller"}) do
    for _, prototype in pairs(data.raw[kind] or {}) do
      if type(prototype.crafting_categories) == "table" then
        for _, category in pairs(prototype.crafting_categories) do
          if type(category) == "string" then allowed[category] = true end
        end
      end
    end
  end
  return allowed
end

local function uses_fluid(entries)
  for _, entry in ipairs(entries or {}) do
    if entry.type == "fluid" then return true end
  end
  return false
end

local function hand_craftable(recipe, allowed)
  -- A fluid cannot go through a character's personal crafting queue.
  if uses_fluid(recipe.ingredients) or uses_fluid(recipe.results) then
    return false
  end
  -- Factorio 2.1 supports multiple alternative recipe categories; keep a
  -- recipe visible if *any* of them is craftable by a character.
  if type(recipe.categories) == "table" and next(recipe.categories) then
    for _, category in pairs(recipe.categories) do
      if allowed[category] then return true end
    end
    return false
  end
  return allowed[recipe.category or "crafting"] == true
end

function M.data_final_fixes()
  local barrels = option("razi-group-barreling-recipes",true)
    and subgroup("razi-fluid-barreling","fluids","z[razi-barreling]")
  local perishables = option("razi-group-spoilable-recipes",false)
    and subgroup("razi-perishable-products","intermediate-products",
      "z[razi-perishables]")

  -- Reorganize first so machine recipe selection retains useful subgroups,
  -- including recipes subsequently omitted from the hand-crafting panel.
  if barrels or perishables then
    for name, recipe in pairs(data.raw.recipe or {}) do
      if barrels and barrel_recipe(name,recipe) then
        recipe.subgroup="razi-fluid-barreling"
      elseif perishables and not recipe.hidden
        and not recipe.hide_from_player_crafting
        and perishable_result(recipe) then
        recipe.subgroup="razi-perishable-products"
      end
    end
  end

  local mode = option("razi-hand-crafting-cleanup","all")
  if mode ~= "all" and mode ~= "razi" then return end
  local allowed = hand_categories()
  for name, recipe in pairs(data.raw.recipe or {}) do
    if (mode == "all" or name:sub(1,5) == "razi-")
      and not recipe.hidden and not recipe.hide_from_player_crafting
      and not hand_craftable(recipe,allowed) then
      -- Unlike 'hidden', this ONLY removes the personal crafting tile.
      -- Source machines, technology unlocks and Factoriopedia still work.
      recipe.hide_from_player_crafting = true
    end
  end
end

M.barrel_recipe = barrel_recipe
M.perishable_result = perishable_result
M.hand_craftable = hand_craftable
return M
