-- Run from repository root: lua5.2 tests/lua/test_fluxworks_companion.lua
-- Small prototype mock; tests the optional bridge without a full mod install.
local function deepcopy(value)
  if type(value) ~= "table" then return value end
  local result = {}
  for key, entry in pairs(value) do result[deepcopy(key)] = deepcopy(entry) end
  return result
end
table.deepcopy = deepcopy

local function science(...)
  local result = {}
  for _, name in ipairs({...}) do result[#result + 1] = {name, 1} end
  return result
end

local raw = {
  technology = {},
  item = {},
  tool = {},
  fluid = {},
  recipe = {},
  ["recipe-category"] = {},
}
local chapters = {"solaris-discovery", "nyxaris-discovery", "vibrant-discovery", "vespera-discovery"}
local tech_names = {
  "fw-vulcanus-industrial-symbiosis", "fw-gleba-regenerative-symbiosis",
  "fw-fulgora-electromagnetic-symbiosis", "fw-aquilo-thermal-symbiosis",
}
for _, name in ipairs(chapters) do raw.technology[name] = {prerequisites = {}} end
for _, name in ipairs(tech_names) do
  raw.technology[name] = {prerequisites = {}, effects = {},
    unit = {ingredients = science("fw-flux-theory-science-pack", "chemical-science-pack")}}
end
raw.technology["fw-flux-extraction"] = {unit = {ingredients = science("automation-science-pack", "fw-industrial-methods-science-pack")}}
raw.technology["fw-industrial-district-project"] = {
  unit = {ingredients = science("automation-science-pack", "fw-industrial-methods-science-pack")},
}
raw.technology["fw-shattered-expedition-planning"] = {
  effects = {{type = "unlock-space-location", space_location = "shattered-planet"}},
}
raw.technology["razi-campaign-gate"] = {
  unit = {ingredients = science("automation-science-pack")},
}

local item_names = {
  "fw-cermet", "fw-resin", "fw-sensor-package", "fw-stabilized-flux-crystal",
  "kr-rare-metals", "tungsten-carbide", "fw-metal-mesh", "kr-biomass",
  "bioflux", "fw-inline-filter", "kr-electronic-components", "superconductor",
  "kr-lithium", "fw-crystalised-flux",
}
for _, name in ipairs(item_names) do
  raw.item[name] = {name = name, icon = "fake/" .. name .. ".png", icon_size = 64, subgroup = "intermediate-product"}
end
for _, name in ipairs({"fw-red-flux", "fw-green-flux", "fw-yellow-flux",
  "fw-purple-flux", "fluoroketone-cold"}) do
  raw.fluid[name] = {name = name}
end
for _, name in ipairs({"metallurgy", "organic", "electromagnetics", "cryogenics"}) do
  raw["recipe-category"][name] = {name = name}
end

_G.data = {raw = raw}
function data:extend(prototypes)
  for _, prototype in ipairs(prototypes) do
    assert(not raw[prototype.type][prototype.name], "Duplicate prototype " .. prototype.name)
    raw[prototype.type][prototype.name] = prototype
  end
end
_G.mods = {FluxWorks = "0.2.12"}
_G.log = function() end

local bridge = dofile("prototypes/compat/fluxworks.lua")
bridge.data_final_fixes()

local recipes = {
  "razi-fw-solaris-cermet-foundry",
  "razi-fw-nyxaris-bioresin-culture",
  "razi-fw-vibrant-sensor-fabrication",
  "razi-fw-vespera-crystal-stabilization",
}
for i, recipe_name in ipairs(recipes) do
  local recipe = assert(raw.recipe[recipe_name], "Missing guarded recipe " .. recipe_name)
  assert(recipe.enabled == false and recipe.allow_productivity == false)
  local technology = raw.technology[tech_names[i]]
  local chapter_found, unlock_found = false, false
  for _, name in ipairs(technology.prerequisites or {}) do
    if name == chapters[i] then chapter_found = true end
  end
  for _, effect in ipairs(technology.effects or {}) do
    if effect.type == "unlock-recipe" and effect.recipe == recipe_name then unlock_found = true end
  end
  assert(chapter_found and unlock_found, "Missing chapter or recipe unlock for " .. recipe_name)
  for _, ingredient in ipairs(technology.unit.ingredients) do
    assert(ingredient[1] ~= "fw-flux-theory-science-pack", "Flux science still mandatory")
  end
end
assert(#raw.technology["fw-flux-extraction"].unit.ingredients == 1)
assert(#raw.technology["fw-industrial-district-project"].unit.ingredients == 2,
  "Mastery project should keep its specialist research")
assert(#raw.technology["fw-shattered-expedition-planning"].effects == 0,
  "FluxWorks must not unlock Razi's Shattered Planet")
assert(#raw.technology["razi-campaign-gate"].unit.ingredients == 1,
  "Razi campaign science must remain untouched")

-- Idempotency matters when an integration pass is used in a test harness.
bridge.data_final_fixes()
for i, recipe_name in ipairs(recipes) do
  local effects = raw.technology[tech_names[i]].effects
  local count = 0
  for _, effect in ipairs(effects) do
    if effect.type == "unlock-recipe" and effect.recipe == recipe_name then count = count + 1 end
  end
  assert(count == 1, "Duplicate unlock for " .. recipe_name)
end
print("FluxWorks companion bridge: OK")
