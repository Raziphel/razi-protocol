-- Research Exchanges create an optional, late-game manufacturing bridge
-- between planet science packs and Razi Protocol's existing system tech cards.
-- This runs after lab_cards and progression so the source recipes are final.
-- No existing recipe, research prerequisite, or transport connection is changed.
local exchanges = {}

local definitions = {
  {
    id = "calidus", card = "calidus-tech-card",
    bridge = "solaris-tech-card",
    prerequisites = {"nyxaris-discovery"}, count = 400,
    main = {"planetaris-compression-science-pack", "electrochemical-science-pack"},
    branches = {
      {"lunar-science-pack", "cerysian-science-pack"}
    }
  },
  {
    id = "solaris", card = "solaris-tech-card",
    bridge = "nyxaris-tech-card",
    prerequisites = {"vibrant-discovery"}, count = 600,
    main = {"thermodynamic-science-pack", "apicultural-science-pack"},
    branches = {
      {"insulation-science-pack", "aerospace-science-pack"}
    }
  },
  {
    id = "nyxaris", card = "nyxaris-tech-card",
    bridge = "vibrant-tech-card",
    prerequisites = {"beetlejuice-discovery"}, count = 800,
    main = {"ribbonia-alien-science-pack", "rubia-biofusion-science-pack"},
    branches = {
      {"pelagos-science-pack", "dea-dia-science-pack"}
    }
  },
  {
    id = "vibrant", card = "vibrant-tech-card",
    bridge = "beetlejuice-tech-card",
    prerequisites = {"planet-discovery-cubium", "planet-discovery-tenebris"},
    count = 1000,
    main = {"bioluminescent-science-pack", "gas-manipulation-science-pack"},
    branches = {
      {"muriatic-science-pack", "paracelsin-galvanization-science-pack"}
    }
  },
  {
    id = "beetlejuice", card = "beetlejuice-tech-card",
    bridge = "promethium-science-pack",
    prerequisites = {"razi-singularity-theory"}, count = 1400,
    main = {"promethium-science-pack", "planet-crucible-science-pack"},
    branches = {
      {"pulsar-science-pack", "promethium-882-science-pack"}
    }
  }
}

local function item_exists(name)
  return (data.raw.tool and data.raw.tool[name]) or
    (data.raw.item and data.raw.item[name])
end

local function technology_exists(name)
  return data.raw.technology and data.raw.technology[name]
end

local function validate_science_pair(pair)
  if not pair or #pair ~= 2 or pair[1] == pair[2] then return false end
  return item_exists(pair[1]) and item_exists(pair[2])
end

local function doubled_source_ingredients(recipe)
  if not (recipe and recipe.ingredients and #recipe.ingredients > 0) then
    return nil
  end
  local ingredients = {}
  local positions = {}
  for _, source in ipairs(recipe.ingredients) do
    -- Base card recipes are made from normal item science packs only.
    -- If another mod changes that assumption, do not create a broken exchange.
    local name = source.name or source[1]
    local amount = source.amount or source[2]
    if not name or (source.type and source.type ~= "item") or
      type(amount) ~= "number" or amount <= 0 or not item_exists(name) then
      return nil
    end
    if positions[name] then
      ingredients[positions[name]].amount = ingredients[positions[name]].amount + amount * 2
    else
      ingredients[#ingredients + 1] = {type = "item", name = name, amount = amount * 2}
      positions[name] = #ingredients
    end
  end
  return ingredients, positions
end

local function make_exchange_recipe(definition, source, item, pair, variant)
  if not validate_science_pair(pair) then return nil end
  local ingredients, indexes = doubled_source_ingredients(source)
  if not ingredients then return nil end

  -- Every variant uses TWO complete batches of the original card recipe,
  -- then adds one science pack from each of two other planetary disciplines.
  -- The three-card result never makes those specialist packs free.
  for _, name in ipairs(pair) do
    if indexes[name] then
      ingredients[indexes[name]].amount = ingredients[indexes[name]].amount + 1
    else
      ingredients[#ingredients + 1] = {type = "item", name = name, amount = 1}
      indexes[name] = #ingredients
    end
  end

  local name = "razi-" .. definition.id .. "-research-exchange" ..
    (variant == "branch" and "-branch" or "")
  if data.raw.recipe and data.raw.recipe[name] then return nil end

  return {
    type = "recipe",
    name = name,
    localised_name = {"recipe-name." .. name},
    localised_description = {"recipe-description.razi-research-exchange"},
    icon = item.icon,
    icon_size = item.icon_size or 256,
    categories = {"crafting"},
    subgroup = source.subgroup or "system-tech-card",
    order = "zz[razi-exchange]-" .. definition.id .. "-" .. variant,
    enabled = false,
    energy_required = math.max(20, (source.energy_required or 10) * 2),
    ingredients = ingredients,
    results = {{type = "item", name = definition.card, amount = 3}},
    allow_productivity = false,
    auto_recycle = false,
    allow_decomposition = false,
    allow_as_intermediate = true
  }
end

local function build_exchange(definition)
  local source = data.raw.recipe and data.raw.recipe[definition.card]
  local item = item_exists(definition.card)
  if not (source and item and item.icon and item_exists(definition.bridge)) then
    return
  end
  for _, prerequisite in ipairs(definition.prerequisites) do
    if not technology_exists(prerequisite) then return end
  end
  local variants = {}
  local normal = make_exchange_recipe(definition, source, item, definition.main, "main")
  if normal then variants[#variants + 1] = normal end
  -- Optional branches never become prerequisites for the standard recipe.
  for _, pair in ipairs(definition.branches or {}) do
    local branch = make_exchange_recipe(definition, source, item, pair, "branch")
    if branch then variants[#variants + 1] = branch end
  end
  if #variants == 0 then return end

  local technology_name = "razi-" .. definition.id .. "-research-exchange"
  if technology_exists(technology_name) then return end
  local effects = {}
  for _, recipe in ipairs(variants) do
    effects[#effects + 1] = {type = "unlock-recipe", recipe = recipe.name}
  end
  data:extend(variants)
  data:extend({
    {
      type = "technology",
      name = technology_name,
      localised_name = {"technology-name." .. technology_name},
      localised_description = {"technology-description." .. technology_name},
      icon = item.icon,
      icon_size = item.icon_size or 256,
      prerequisites = definition.prerequisites,
      effects = effects,
      unit = {
        count = definition.count,
        time = 45,
        ingredients = {
          {type = "item", name = definition.card, amount = 1},
          {type = "item", name = definition.bridge, amount = 1}
        }
      },
      order = "ez[razi-research-exchange]-" .. definition.id
    }
  })
end

function exchanges.data_final_fixes()
  for _, definition in ipairs(definitions) do
    build_exchange(definition)
  end
end

return exchanges
