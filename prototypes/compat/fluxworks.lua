-- Optional FluxWorks industry bridge. Razi owns route unlocks, the story and
-- chapter science; FluxWorks owns its materials, machines and process recipes.
local M = {}

local domain_packs = {
  ["fw-industrial-methods-science-pack"] = true,
  ["fw-systems-analysis-science-pack"] = true,
  ["fw-flux-theory-science-pack"] = true,
  ["fw-planetary-convergence-science-pack"] = true,
}

-- Domain packs remain useful as specialist mastery research, but shouldn't be
-- a second compulsory science ladder in the seven-system campaign.
local mastery_projects = {
  ["fw-industrial-district-project"] = true,
  ["fw-autonomous-network-project"] = true,
  ["fw-spectrum-control-project"] = true,
  ["fw-convergence-directive-project"] = true,
}

local branches = {
  {
    chapter = "solaris-discovery",
    technology = "fw-vulcanus-industrial-symbiosis",
    name = "razi-fw-solaris-cermet-foundry",
    product = "fw-cermet",
    amount = 2,
    category = "metallurgy",
    time = 12,
    ingredients = {
      { type = "item", name = "kr-rare-metals", amount = 3 },
      { type = "item", name = "tungsten-carbide", amount = 4 },
      { type = "item", name = "fw-metal-mesh", amount = 2 },
      { type = "fluid", name = "fw-red-flux", amount = 90 },
    },
  },
  {
    chapter = "nyxaris-discovery",
    technology = "fw-gleba-regenerative-symbiosis",
    name = "razi-fw-nyxaris-bioresin-culture",
    product = "fw-resin",
    amount = 3,
    category = "organic",
    time = 12,
    ingredients = {
      { type = "item", name = "kr-biomass", amount = 8 },
      { type = "item", name = "bioflux", amount = 2 },
      { type = "item", name = "fw-inline-filter", amount = 2 },
      { type = "fluid", name = "fw-green-flux", amount = 70 },
    },
  },
  {
    chapter = "vibrant-discovery",
    technology = "fw-fulgora-electromagnetic-symbiosis",
    name = "razi-fw-vibrant-sensor-fabrication",
    product = "fw-sensor-package",
    amount = 2,
    category = "electromagnetics",
    time = 14,
    ingredients = {
      { type = "item", name = "kr-electronic-components", amount = 4 },
      { type = "item", name = "superconductor", amount = 2 },
      { type = "item", name = "fw-metal-mesh", amount = 2 },
      { type = "fluid", name = "fw-yellow-flux", amount = 80 },
    },
  },
  {
    chapter = "vespera-discovery",
    technology = "fw-aquilo-thermal-symbiosis",
    name = "razi-fw-vespera-crystal-stabilization",
    product = "fw-stabilized-flux-crystal",
    amount = 2,
    category = "cryogenics",
    time = 18,
    ingredients = {
      { type = "item", name = "kr-lithium", amount = 4 },
      { type = "item", name = "fw-crystalised-flux", amount = 5 },
      { type = "fluid", name = "fluoroketone-cold", amount = 40 },
      { type = "fluid", name = "fw-purple-flux", amount = 75 },
    },
  },
}

local function add_prerequisite(technology, name)
  if not (technology and data.raw.technology[name]) then return end
  technology.prerequisites = technology.prerequisites or {}
  for _, prerequisite in ipairs(technology.prerequisites) do
    if prerequisite == name then return end
  end
  technology.prerequisites[#technology.prerequisites + 1] = name
end

local function has_item(name)
  return (data.raw.item and data.raw.item[name])
    or (data.raw.tool and data.raw.tool[name])
end

local function can_craft(spec)
  if not (has_item(spec.product) and data.raw.technology[spec.technology]
    and data.raw.technology[spec.chapter] and data.raw["recipe-category"][spec.category])
  then return false end
  for _, ingredient in ipairs(spec.ingredients) do
    local available = ingredient.type == "fluid"
      and data.raw.fluid and data.raw.fluid[ingredient.name]
      or ingredient.type ~= "fluid" and has_item(ingredient.name)
    if not available then return false end
  end
  return true
end

local function add_recipe(spec, index)
  if not can_craft(spec) then
    log("Razi FluxWorks: skipped incomplete planetary process " .. spec.name)
    return false
  end

  local item = has_item(spec.product)
  if not data.raw.recipe[spec.name] then
    local recipe = {
      type = "recipe",
      name = spec.name,
      category = spec.category,
      subgroup = item.subgroup,
      order = ("zz[razi-fluxworks]-%02d"):format(index),
      enabled = false,
      energy_required = spec.time,
      allow_productivity = false,
      auto_recycle = false,
      ingredients = table.deepcopy(spec.ingredients),
      results = { { type = "item", name = spec.product, amount = spec.amount } },
      main_product = spec.product,
    }
    if item.icons then
      recipe.icons = table.deepcopy(item.icons)
    else
      recipe.icon = item.icon
      recipe.icon_size = item.icon_size
    end
    if not (recipe.icon or recipe.icons) then return false end
    data:extend({recipe})
  end

  local tech = data.raw.technology[spec.technology]
  tech.effects = tech.effects or {}
  local has_unlock = false
  for _, effect in ipairs(tech.effects) do
    if effect.type == "unlock-recipe" and effect.recipe == spec.name then
      has_unlock = true
      break
    end
  end
  if not has_unlock then
    tech.effects[#tech.effects + 1] = { type = "unlock-recipe", recipe = spec.name }
  end
  return true
end

function M.data_final_fixes()
  if not (mods and mods["FluxWorks"]) then return end
  local techs = data.raw.technology or {}
  local extraction = techs["fw-flux-extraction"]
  if not extraction then
    error("Razi Protocol requires a FluxWorks build containing the Flux industry")
  end

  local simplified = 0
  local revoked = 0
  for tech_name, tech in pairs(techs) do
    if tech_name:sub(1, 3) == "fw-" then
      -- Standalone FluxWorks unlocks the native Shattered Planet. In Razi that
      -- remains a space location controlled exclusively by Deep Space research.
      if tech.effects then
        for i = #tech.effects, 1, -1 do
          local effect = tech.effects[i]
          if effect.type == "unlock-space-location"
            and effect.space_location == "shattered-planet" then
            table.remove(tech.effects, i)
            revoked = revoked + 1
          end
        end
      end

      if tech.unit and tech.unit.ingredients and not mastery_projects[tech_name] then
        local kept = {}
        for _, ingredient in ipairs(tech.unit.ingredients) do
          local name = ingredient.name or ingredient[1]
          if not domain_packs[name] then
            kept[#kept + 1] = ingredient
          else
            simplified = simplified + 1
          end
        end
        -- A research unit must have at least one valid science ingredient.
        if #kept == 0 then kept[1] = {"automation-science-pack", 1} end
        tech.unit.ingredients = kept
      end
    end
  end

  local integrated = 0
  for index, branch in ipairs(branches) do
    if can_craft(branch) then
      add_prerequisite(techs[branch.technology], branch.chapter)
    end
    if add_recipe(branch, index) then integrated = integrated + 1 end
  end

  log(("Razi FluxWorks: %d optional industry recipes, %d science tolls removed, %d duplicate location unlocks removed")
    :format(integrated, simplified, revoked))
end

return M
