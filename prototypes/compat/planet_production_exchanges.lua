-- Optional production exchanges between K2SO's established planet industries.
-- These are alternate recipes, not replacements or ingredients for core science.
-- A shortcut must never unlock the native product before its original research.
local M = {}

local exchanges = {
  {
    name = "razi-bio-rare-metal-casting",
    source = "kr-casting-rare-metals",
    product = "kr-rare-metals",
    planets = {"planet-discovery-vulcanus", "planet-discovery-gleba"},
    science = {"calidus-tech-card"},
    category = "metallurgy",
    additional = {{type="item", name="bioflux", amount=2}},
    batch = 4, bonus = 1, count = 350, time = 30,
    bonus_icon = "bioflux",
    -- Industrial exchange opens in the first frontier, not after Fulgora.
    not_after = {"vibrant-discovery", "vespera-discovery"}
  },
  {
    name = "razi-electrobiological-components",
    source = "kr-electronic-components",
    product = "kr-electronic-components",
    planets = {"planet-discovery-fulgora", "planet-discovery-gleba"},
    science = {"solaris-tech-card", "nyxaris-tech-card"},
    category = "electromagnetics",
    surface_source = "kr-electromagnetic-research-data",
    surface_world = "fulgora",
    additional = {
      {type="item", name="bioflux", amount=1},
      {type="item", name="holmium-plate", amount=1}
    },
    batch = 1, bonus = 3, count = 550, time = 45,
    bonus_icon = "holmium-plate",
    not_after = {"beetlejuice-discovery", "umbra-discovery"}
  },
  {
    name = "razi-cryo-energy-control",
    source = "kr-energy-control-unit",
    product = "kr-energy-control-unit",
    planets = {"planet-discovery-aquilo", "planet-discovery-gleba",
      "planet-discovery-fulgora"},
    science = {"solaris-tech-card", "nyxaris-tech-card"},
    category = "cryogenics",
    surface_source = "kr-cryogenic-research-data",
    surface_world = "aquilo",
    additional = {
      {type="item", name="supercapacitor", amount=2},
      {type="item", name="carbon-fiber", amount=4},
      {type="fluid", name="fluoroketone-cold", amount=10}
    },
    batch = 1, bonus = 1, count = 900, time = 60,
    bonus_icon = "supercapacitor",
    not_after = {"beetlejuice-discovery", "umbra-discovery"}
  }
}

local function raw(kind, name)
  return data.raw[kind] and data.raw[kind][name]
end

local function deepcopy(value)
  return table.deepcopy(value)
end

local function name_of(entry)
  return entry.name or entry[1]
end

local function valid_ingredient(entry)
  local name = name_of(entry)
  if not name then return false end
  local kind = entry.type == "fluid" and "fluid" or "item"
  if kind == "fluid" then
    local fluid = raw("fluid", name)
    return fluid and not fluid.hidden
  end
  for _, family in ipairs({"item", "tool", "module", "ammo", "capsule"}) do
    local item = raw(family, name)
    if item and not item.hidden then return true end
  end
  return false
end

local function technologies()
  return data.raw.technology or {}
end

local function depends_on(start, sought, seen)
  if start == sought then return true end
  local t = technologies()[start]
  if not t then return false end
  seen = seen or {}
  if seen[start] then return false end
  seen[start] = true
  for _, parent in ipairs(t.prerequisites or {}) do
    if depends_on(parent, sought, seen) then return true end
  end
  return false
end

local function unlock_technology(recipe_name, guard)
  local choices = {}
  for name, tech in pairs(technologies()) do
    for _, effect in ipairs(tech.effects or {}) do
      if effect.type == "unlock-recipe" and effect.recipe == recipe_name then
        local too_late = false
        for _, gate in ipairs(guard.not_after or {}) do
          if depends_on(name, gate) then too_late = true break end
        end
        if not too_late then choices[#choices + 1] = name end
        break
      end
    end
  end
  table.sort(choices)
  return choices[1]
end

local function lab_can_research(packs)
  for _, lab in pairs(data.raw.lab or {}) do
    local available = {}
    for _, science in ipairs(lab.inputs or {}) do available[science] = true end
    local all = true
    for _, science in ipairs(packs) do
      if not available[science] then all = false break end
    end
    if all then return true end
  end
  return false
end

local function machine_can_craft(category)
  for _, family in ipairs({"assembling-machine", "furnace"}) do
    for _, machine in pairs(data.raw[family] or {}) do
      if not machine.fixed_recipe then
        for _, value in ipairs(machine.crafting_categories or {}) do
          if value == category then return true end
        end
      end
    end
  end
  return false
end

local function matches_surface(recipe, world)
  if not (world and world.surface_properties) then return false end
  for _, condition in ipairs(recipe.surface_conditions or {}) do
    local value = world.surface_properties[condition.property]
    if type(value) ~= "number" then return false end
    if condition.min and value < condition.min then return false end
    if condition.max and value > condition.max then return false end
  end
  return true
end

local function recipe_icon(base, product, bonus)
  local icons
  if base.icons then
    icons = deepcopy(base.icons)
  elseif base.icon then
    icons = {{icon=base.icon, icon_size=base.icon_size or 64}}
  else
    local result = raw("item", product)
    if not result then return nil end
    if result.icons then
      icons = deepcopy(result.icons)
    elseif result.icon then
      icons = {{icon=result.icon, icon_size=result.icon_size or 64}}
    else
      return nil
    end
  end
  local marker = raw("item", bonus)
  if marker and marker.icon then
    icons[#icons + 1] = {
      icon=marker.icon, icon_size=marker.icon_size or 64,
      scale=0.24, shift={8, 8}
    }
  end
  return icons
end

local function safe_template(base, output)
  if not (base and base.ingredients and base.results and not base.normal
      and not base.expensive and not base.hidden) then return false end
  local found = false
  for _, result in ipairs(base.results) do
    if name_of(result) == output then
      if result.type == "fluid" or result.probability
        or result.amount_min or result.amount_max or not result.amount then
        return false
      end
      found = true
    end
  end
  if not found then return false end
  for _, ingredient in ipairs(base.ingredients) do
    if not ingredient.amount or not valid_ingredient(ingredient) then
      return false
    end
  end
  return true
end

local function register_exchange(rule)
  local base = raw("recipe", rule.source)
  if not safe_template(base, rule.product)
    or not raw("item", rule.product)
    or not machine_can_craft(rule.category)
    or raw("recipe", rule.name) or technologies()[rule.name] then return end
  for _, arrival in ipairs(rule.planets) do
    if not technologies()[arrival] then return end
  end
  for _, extra in ipairs(rule.additional) do
    if not valid_ingredient(extra) then return end
  end
  for _, pack in ipairs(rule.science) do
    if not raw("tool", pack) then return end
  end
  if not lab_can_research(rule.science) then return end

  local native_unlock
  if base.enabled == false then
    native_unlock = unlock_technology(rule.source, rule)
    if not native_unlock then return end
  end

  local prerequisite_list, seen = {}, {}
  for _, name in ipairs(rule.planets) do
    if not seen[name] then
      prerequisite_list[#prerequisite_list + 1] = name
      seen[name] = true
    end
  end
  if native_unlock and not seen[native_unlock] then
    prerequisite_list[#prerequisite_list + 1] = native_unlock
  end

  local conditions
  if rule.surface_source then
    local reference = raw("recipe", rule.surface_source)
    local planet = raw("planet", rule.surface_world)
    if not (reference and reference.surface_conditions
      and #reference.surface_conditions > 0
      and matches_surface(reference, planet)) then return end
    conditions = deepcopy(reference.surface_conditions)
  elseif base.surface_conditions then
    conditions = deepcopy(base.surface_conditions)
  end

  local icons = recipe_icon(base, rule.product, rule.bonus_icon)
  if not icons then return end
  local visual = technologies()[native_unlock or rule.planets[1]]
  if not visual or not (visual.icon or visual.icons) then return end

  local alternative = deepcopy(base)
  alternative.type = "recipe"
  alternative.name = rule.name
  alternative.localised_name = {"recipe-name." .. rule.name}
  alternative.localised_description = {"recipe-description." .. rule.name}
  alternative.icon, alternative.icon_size = nil, nil
  alternative.icons = icons
  alternative.enabled = false
  alternative.hidden = false
  alternative.hide_from_player_crafting = false
  alternative.categories = {rule.category}
  alternative.category = nil
  alternative.surface_conditions = conditions
  alternative.energy_required = (base.energy_required or 1) * rule.batch * 1.3
  alternative.auto_recycle = false
  alternative.allow_decomposition = false
  -- Rewards cross-planet shipping without stacking free bonus throughput
  -- with productivity modifiers or automatic alternate-recipe recycling.
  alternative.allow_productivity = false
  alternative.maximum_productivity = 0

  for _, ingredient in ipairs(alternative.ingredients) do
    ingredient.amount = ingredient.amount * rule.batch
    if ingredient.ignored_by_stats then
      ingredient.ignored_by_stats = ingredient.ignored_by_stats * rule.batch
    end
  end
  for _, product in ipairs(alternative.results) do
    product.amount = product.amount * rule.batch
    for _, field in ipairs({"ignored_by_stats", "ignored_by_productivity",
      "catalyst_amount"}) do
      if product[field] then product[field] = product[field] * rule.batch end
    end
    if name_of(product) == rule.product then
      product.amount = product.amount + rule.bonus
    end
  end
  for _, ingredient in ipairs(rule.additional) do
    alternative.ingredients[#alternative.ingredients + 1] = deepcopy(ingredient)
  end

  local tech = {
    type = "technology",
    name = rule.name,
    localised_name = {"technology-name." .. rule.name},
    localised_description = {"technology-description." .. rule.name},
    icon = visual.icon,
    icons = visual.icons and deepcopy(visual.icons) or nil,
    icon_size = visual.icon_size or 256,
    prerequisites = prerequisite_list,
    effects = {{type="unlock-recipe", recipe=rule.name}},
    unit = {
      count = rule.count, time = rule.time,
      ingredients = {}
    },
    order = "fz[razi-exchanges]-" .. rule.name
  }
  for _, pack in ipairs(rule.science) do
    tech.unit.ingredients[#tech.unit.ingredients + 1] = {pack, 1}
  end
  data:extend({alternative, tech})
end

function M.data_final_fixes()
  if not (mods and mods["Krastorio2-spaced-out"]) then return end
  for _, rule in ipairs(exchanges) do register_exchange(rule) end
end

return M
