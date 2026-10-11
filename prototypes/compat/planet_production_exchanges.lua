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
    working_world = "vulcanus",
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
  },
  -- Tenebris remains an independent chitin economy. Shipping stable Gleba
  -- bioflux only boosts its plastic output, never replaces its local chitin.
  {
    name = "razi-gleba-tenebris-biopolymer",
    source_mod = "tenebris-prime",
    source = "biopolymer",
    product = "plastic-bar",
    planets = {"planet-discovery-tenebris", "planet-discovery-gleba"},
    science = {"vibrant-tech-card", "vespera-tech-card"},
    category = "organic", working_world = "tenebris",
    additional = {{type="item", name="bioflux", amount=1}},
    batch = 2, bonus = 2, count = 950, time = 45,
    bonus_icon = "bioflux"
  },
  -- Linox's rare-earth metallurgy gets a meaningful late-game importer
  -- option using Fulgoran holmium and K2SO rare metals from prior industry.
  {
    name = "razi-linox-rare-earth-exchange",
    source_mod = "linox",
    source = "linox-recipe_rare-earth-refining",
    product = "rare-earth-powder",
    planets = {"linox-technology_planet-discovery-linox",
      "planet-discovery-vulcanus", "planet-discovery-fulgora"},
    science = {"vibrant-tech-card", "vespera-tech-card"},
    category = "chemistry", working_world = "linox-planet_linox",
    additional = {
      {type="item", name="kr-rare-metals", amount=2},
      {type="item", name="holmium-plate", amount=1}
    },
    batch = 2, bonus = 1, count = 1150, time = 60,
    bonus_icon = "holmium-plate"
  },
  -- Cubium provides an industrial home for gold arriving from Secretas.
  -- Preserve native gold smelting, let ore travel instead of requiring a
  -- nonexistent factory on Secretas's space-location prototype.
  {
    name = "razi-cubium-precious-metal-alloying",
    source_mod = "secretas",
    source = "gold-plate",
    product = "gold-plate",
    planets = {"planet-discovery-secretas", "planet-discovery-cubium",
      "planet-discovery-vulcanus", "planet-discovery-fulgora"},
    science = {"vibrant-tech-card", "vespera-tech-card"},
    category = "metallurgy", working_world = "cubium",
    additional = {
      {type="item", name="kr-rare-metals", amount=1},
      {type="item", name="holmium-plate", amount=1}
    },
    batch = 4, bonus = 1, count = 1100, time = 55,
    bonus_icon = "kr-rare-metals"
  },
  -- Building out Vesta stays possible with its own native foundation.
  -- A late premium version uses established mineral, electronics and
  -- bioluminescent supply lines without requiring a volatile gas export.
  {
    name = "razi-vesta-frontier-foundations",
    source_mod = "skewer_planet_vesta",
    source = "vesta-foundation",
    product = "vesta-foundation",
    planets = {"planet-discovery-vesta", "planet-discovery-tenebris",
      "planet-discovery-vulcanus", "planet-discovery-fulgora"},
    science = {"vibrant-tech-card", "vespera-tech-card"},
    category = "metallurgy", working_world = "vesta",
    additional = {
      {type="item", name="kr-rare-metals", amount=2},
      {type="item", name="holmium-plate", amount=2},
      {type="item", name="bioluminescent-crystal", amount=2}
    },
    batch = 1, bonus = 5, count = 1450, time = 60,
    bonus_icon = "bioluminescent-crystal"
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
        if not too_late and tech.enabled ~= false and not tech.hidden then
          choices[#choices + 1] = name
        end
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

local function matches_surface(recipe, world)
  if not world then return false end
  local conditions = recipe.surface_conditions or {}
  if #conditions == 0 then return true end
  if not world.surface_properties then return false end
  for _, condition in ipairs(conditions) do
    local value = world.surface_properties[condition.property]
    if type(value) ~= "number" then return false end
    if condition.min and value < condition.min then return false end
    if condition.max and value > condition.max then return false end
  end
  return true
end

local function distinct_fluid_count(entries)
  local fluids = {}
  for _, entry in ipairs(entries or {}) do
    if entry.type == "fluid" then fluids[name_of(entry)] = true end
  end
  local count = 0
  for _ in pairs(fluids) do count = count + 1 end
  return count
end

local function machine_fluid_ports(machine)
  local inputs, outputs = 0, 0
  for _, port in ipairs(machine.fluid_boxes or {}) do
    if port.production_type == "input" or port.production_type == "input-output" then
      inputs = inputs + 1
    end
    if port.production_type == "output" or port.production_type == "input-output" then
      outputs = outputs + 1
    end
  end
  return inputs, outputs
end

local function machine_can_craft(category, base, additional, world)
  local ingredients = {}
  for _, entry in ipairs(base.ingredients) do
    ingredients[#ingredients + 1] = entry
  end
  for _, entry in ipairs(additional) do
    ingredients[#ingredients + 1] = entry
  end
  local required_inputs = distinct_fluid_count(ingredients)
  local required_outputs = distinct_fluid_count(base.results)
  for _, family in ipairs({"assembling-machine", "furnace"}) do
    for _, machine in pairs(data.raw[family] or {}) do
      if not machine.fixed_recipe and matches_surface(machine, world) then
        local suitable_category = false
        for _, value in ipairs(machine.crafting_categories or {}) do
          if value == category then suitable_category = true break end
        end
        if suitable_category then
          local inputs, outputs = machine_fluid_ports(machine)
          if inputs >= required_inputs and outputs >= required_outputs then
            return true
          end
        end
      end
    end
  end
  return false
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

local function recipe_produces(base, target)
  if not base then return false end
  if base.result == target then return true end
  for _, output in ipairs(base.results or {}) do
    if name_of(output) == target then return true end
  end
  return false
end

local function source_supports_category(base, category)
  if not base then return false end
  local categories = base.categories or {base.category or "crafting"}
  for _, existing in ipairs(categories) do
    if existing == category then return true end
  end
  return false
end

local function register_exchange(rule)
  if rule.source_mod and not mods[rule.source_mod] then return end
  for _, needed_mod in ipairs(rule.required_mods or {}) do
    if not mods[needed_mod] then return end
  end
  local base = raw("recipe", rule.source)
  local world = raw("planet", rule.surface_world or rule.working_world)
  if not safe_template(base, rule.product)
    or (rule.keep_native_category and not source_supports_category(base, rule.category))
    or not raw("item", rule.product)
    -- A recipe built for a native world must still be legal there, even
    -- if a compatible machine exists for its category.
    or not matches_surface(base, world)
    or not machine_can_craft(rule.category, base, rule.additional, world)
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

  -- Optional imports can never be available *before* their source recipe.
  -- Simply knowing the supplying planet has been discovered is insufficient:
  -- some mods unlock manufacturing much later in their native progression.
  local supplier_unlocks = {}
  for _, supplied in ipairs(rule.supplier_recipes or {}) do
    local producer = raw("recipe", supplied.recipe)
    if not (producer and not producer.hidden
      and recipe_produces(producer, supplied.product)
      and valid_ingredient({type="item", name=supplied.product})) then return end
    -- A named supplier recipe is not proof of an obtainable ingredient if
    -- its own direct inputs no longer exist after other mods' final fixes.
    for _, upstream_input in ipairs(producer.ingredients or {}) do
      if not valid_ingredient(upstream_input) then return end
    end
    if producer.enabled == false then
      local unlock = unlock_technology(supplied.recipe, rule)
      if not unlock then return end
      supplier_unlocks[#supplier_unlocks + 1] = unlock
    end
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
    seen[native_unlock] = true
  end
  for _, supplier_unlock in ipairs(supplier_unlocks) do
    if not seen[supplier_unlock] then
      prerequisite_list[#prerequisite_list + 1] = supplier_unlock
      seen[supplier_unlock] = true
    end
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

-- Startup switches affect only Razi-owned alternate recipes. Missing settings
-- are treated as enabled so older mock environments preserve existing behavior.
local function enabled(name)
  local option = settings and settings.startup and settings.startup[name]
  return not option or option.value ~= false
end

function M.data_final_fixes()
  if not (mods and mods["Krastorio2-spaced-out"])
    or not enabled("razi-enable-k2so-production-exchanges") then return end
  for _, rule in ipairs(exchanges) do register_exchange(rule) end
end

function M.register_additional(rules)
  if not (mods and mods["Krastorio2-spaced-out"])
    or not enabled("razi-enable-modded-planet-exchanges") then return end
  for _, rule in ipairs(rules or {}) do register_exchange(rule) end
end

return M
