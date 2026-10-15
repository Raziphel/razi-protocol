-- Preserve K2SO's intended advanced-machine roles after every planet mod
-- has made its final crafting-category changes. Never grant categories that
-- belong exclusively to a source planet's specialist machinery.
local machines = {}

local parity = {
  {
    upgrade = "kr-advanced-assembling-machine",
    baseline = "assembling-machine-3",
    anchor = "crafting",
    categories = {"crafting", "advanced-crafting", "crafting-with-fluid"}
  },
  {
    upgrade = "kr-advanced-chemical-plant",
    baseline = "chemical-plant",
    anchor = "chemistry",
    categories = {"chemistry", "chemistry-or-cryogenics"}
  },
  {
    upgrade = "kr-advanced-furnace",
    baseline = "foundry",
    anchor = "metallurgy",
    categories = {"metallurgy"}
  }
}

-- The K2SO machines should appear after the actual destination where their
-- native ingredients/science originate. Keep all K2SO-native prerequisites
-- and never move an early bootstrap machine into a later frontier.
local research_links = {
  {"kr-advanced-furnace", "planet-discovery-vulcanus"},
  {"kr-geothermal", "planet-discovery-vulcanus"},
  {"kr-advanced-chemical-plant", "planet-discovery-gleba"},
  {"kr-energy-storage", "planet-discovery-fulgora"},
  {"kr-quantum-computer", "planet-discovery-aquilo"},
  {"kr-matter-tech-card", "planet-discovery-aquilo"}
}

local function includes(list, value)
  for _, existing in ipairs(list or {}) do
    if existing == value then return true end
  end
  return false
end

local function interfaces(machine)
  local inputs, outputs = 0, 0
  for _, box in ipairs(machine.fluid_boxes or {}) do
    if box.production_type == "input" or box.production_type == "input-output" then
      inputs = inputs + 1
    end
    if box.production_type == "output" or box.production_type == "input-output" then
      outputs = outputs + 1
    end
  end
  return inputs, outputs
end

local function sufficient_fluid_interfaces(baseline, upgrade)
  local baseline_inputs, baseline_outputs = interfaces(baseline)
  local upgrade_inputs, upgrade_outputs = interfaces(upgrade)
  return upgrade_inputs >= baseline_inputs and upgrade_outputs >= baseline_outputs
end

local function preserve_machine_capabilities()
  local prototypes = data.raw["assembling-machine"] or {}
  for _, rule in ipairs(parity) do
    local baseline, upgrade = prototypes[rule.baseline], prototypes[rule.upgrade]
    if baseline and upgrade and baseline.crafting_categories
      and upgrade.crafting_categories
      and includes(upgrade.crafting_categories, rule.anchor)
      and sufficient_fluid_interfaces(baseline, upgrade) then
      for _, category in ipairs(rule.categories) do
        -- The base machine proves this is a standard capability. Never copy
        -- custom planet recipes or their surface conditions by name.
        if includes(baseline.crafting_categories, category)
          and not includes(upgrade.crafting_categories, category) then
          upgrade.crafting_categories[#upgrade.crafting_categories + 1] = category
        end
      end
    end
  end
end

local function technology(name)
  return data.raw.technology and data.raw.technology[name]
end

local function depends_on(start, ancestor, seen)
  if start == ancestor then return true end
  local t = technology(start)
  if not t then return false end
  seen = seen or {}
  if seen[start] then return false end
  seen[start] = true
  for _, name in ipairs(t.prerequisites or {}) do
    if depends_on(name, ancestor, seen) then return true end
  end
  return false
end

local function anchor_machine_research()
  for _, pair in ipairs(research_links) do
    local name, world = pair[1], pair[2]
    local t = technology(name)
    if t and technology(world) and not depends_on(world, name)
      and not depends_on(name, world) then
      t.prerequisites = t.prerequisites or {}
      t.prerequisites[#t.prerequisites + 1] = world
    end
  end
end

function machines.data_final_fixes()
  if not (mods and mods["Krastorio2-spaced-out"]) then return end
  preserve_machine_capabilities()
  if require("prototypes.compat.interdependence_mode").enabled() then
    anchor_machine_research()
  end
end

return machines
