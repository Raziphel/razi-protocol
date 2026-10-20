-- Razi Rocket Reusability owns wreck spawning, beacons and salvage outputs.
-- These optional, source-safe bulk recipes reuse its *final* K2SO/Muluna-
-- adjusted output rather than copying or replacing another mod's economy.
-- No prerequisite is added to a planet, rocket silo or source technology.
local M = {}

local function present(kind, name)
  return data.raw[kind] and data.raw[kind][name]
end

local function ingredient_ready(entry)
  return entry.name and present("item", entry.name)
end

local function unlocked_technology(name)
  local tech = present("technology", name)
  return tech and tech.hidden ~= true and tech.enabled ~= false
end

local function boosted_outputs(native, batches, small_bonus)
  local outputs = table.deepcopy(native.results or {})
  local bonus_given = false
  for _, result in ipairs(outputs) do
    if result.amount then result.amount = result.amount * batches end
    if result.amount_min then result.amount_min = result.amount_min * batches end
    if result.amount_max then result.amount_max = result.amount_max * batches end
    -- The first native non-chunk output gets a small fixed handling bonus.
    -- This adapts to incomplete rocket parts AND K2SO's source-safe fallback.
    if not bonus_given and result.name ~= "rocket-chunk"
      and (result.type == nil or result.type == "item") then
      if result.amount_min and result.amount_max then
        result.amount_min = result.amount_min + small_bonus
        result.amount_max = result.amount_max + small_bonus
        bonus_given = true
      elseif result.amount then
        result.amount = result.amount + small_bonus
        bonus_given = true
      end
    end
  end
  return bonus_given and outputs or nil
end

local tiers = {
  {
    name = "razi-rocket-salvage-precision",
    prerequisites = {"remnant-beacon", "planet-discovery-fulgora"},
    ingredients = {
      {type="item", name="rocket-chunk", amount=3},
      {type="item", name="holmium-plate", amount=1}
    },
    batches=3, bonus=1, time_factor=0.85, count=550, order="a"
  },
  {
    name = "razi-rocket-salvage-cryogenic",
    prerequisites = {"razi-rocket-salvage-precision", "planet-discovery-aquilo"},
    ingredients = {
      {type="item", name="rocket-chunk", amount=4},
      {type="item", name="ice", amount=15},
      {type="item", name="processing-unit", amount=2}
    },
    batches=4, bonus=1, time_factor=0.75, count=900, order="b"
  },
  {
    name = "razi-rocket-salvage-network",
    prerequisites = {
      "razi-rocket-salvage-cryogenic",
      "razi-network-precision-matrix", "interplanetary-trade-logistics"
    },
    ingredients = {
      {type="item", name="rocket-chunk", amount=6},
      {type="item", name="razi-network-precision-matrix", amount=1}
    },
    batches=6, bonus=2, time_factor=0.70, count=1500, order="c"
  }
}

function M.data_final_fixes()
  if not (mods and mods["razi-rocket-reusability"]) then return end
  local native = present("recipe","rocket-chunk-processing")
  local beacon = present("technology","remnant-beacon")
  if not (native and native.results and beacon and beacon.unit
    and beacon.unit.ingredients and ingredient_ready({name="rocket-chunk"})) then
    return
  end

  for _, tier in ipairs(tiers) do
    local valid = not present("technology",tier.name)
      and not present("recipe",tier.name.."-processing")
    for _, prereq in ipairs(tier.prerequisites) do
      valid = valid and unlocked_technology(prereq)
    end
    for _, ingredient in ipairs(tier.ingredients) do
      valid = valid and ingredient_ready(ingredient)
    end
    local outputs = boosted_outputs(native,tier.batches,tier.bonus)
    if valid and outputs then
      local recipe = table.deepcopy(native)
      recipe.name = tier.name.."-processing"
      recipe.localised_name = {"recipe-name."..recipe.name}
      recipe.localised_description = {"recipe-description."..recipe.name}
      recipe.enabled = false
      recipe.ingredients = table.deepcopy(tier.ingredients)
      recipe.results = outputs
      recipe.energy_required = math.max(1, (native.energy_required or 2)
        * tier.batches * tier.time_factor)
      -- No productivity stacking on bulk bonus recipes.
      recipe.allow_productivity = false
      recipe.auto_recycle = false
      recipe.order = "z[razi-salvage]-"..tier.order
      local tech = {
        type = "technology",
        name = tier.name,
        icon = "__razi-rocket-reusability__/graphics/icons/rocket-reusability-research.png",
        icon_size = 190,
        prerequisites = table.deepcopy(tier.prerequisites),
        effects = {{type="unlock-recipe",recipe=recipe.name}},
        unit = {
          count = tier.count,
          ingredients = table.deepcopy(beacon.unit.ingredients),
          time = beacon.unit.time or 60
        },
        order = "z[razi-salvage]-"..tier.order
      }
      data:extend({recipe,tech})
    end
  end
end

return M
