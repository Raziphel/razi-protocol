-- Mapping follows the tiers in technology/systems/progression.lua. Unknown or
-- lab-specific science is deliberately kept instead of guessed.
local M = {}
local PREFIX = "razi-system-infinite-"
local EARLY_LEVELS = 5
local cards = {
  base = "calidus-tech-card",
  solaris = "solaris-tech-card",
  nyxaris = "nyxaris-tech-card",
  vibrant = "vibrant-tech-card",
  vespera = "vespera-tech-card",
  beetlejuice = "beetlejuice-tech-card",
  umbra = "umbra-tech-card",
  deep_space = "deep-space-tech-card"
}
local tiers = {
  base = {
    "automation-science-pack", "logistic-science-pack", "military-science-pack",
    "chemical-science-pack", "production-science-pack", "utility-science-pack",
    "space-science-pack", "metallurgic-science-pack",
    "electromagnetic-science-pack", "agricultural-science-pack",
    "lithium-science-pack", "tungsten-science-pack", "lunar-science-pack",
    "interstellar-science-pack", "advanced-space-science-pack",
    "cerysian-science-pack", "kr-basic-tech-card", "kr-automation-tech-card",
    "kr-logistic-tech-card", "kr-military-tech-card", "kr-chemical-tech-card",
    "kr-production-tech-card", "kr-utility-tech-card", "kr-space-tech-card"
  },
  solaris = {
    "battlefield-science-pack", "planetaris-compression-science-pack",
    "planetaris-polishing-science-pack", "planetaris-bioengineering-science-pack",
    "planetaris-pathological-science-pack", "planetaris-refraction-science-pack",
    "electrochemical-science-pack"
  },
  nyxaris = {
    "aerospace-science-pack", "dea-dia-science-pack", "insulation-science-pack",
    "thermodynamic-science-pack", "nuclear-science-pack",
    "apicultural-science-pack", "pelagos-science-pack"
  },
  vibrant = {
    "ribbonia-alien-science-pack", "galvanization-science-pack",
    "paracelsin-galvanization-science-pack"
  },
  vespera = {
    "acidworking-science-pack", "cryogenic-science-pack",
    "biorecycling-science-pack", "rubia-biofusion-science-pack",
    "hydraulic-science-pack"
  },
  beetlejuice = {"golden-science-pack", "promethium-science-pack"},
  umbra = {
    "bioluminescent-science-pack", "gas-manipulation-science-pack",
    "planet-crucible-science-pack"
  },
  deep_space = {
    "space-logistic-science-pack", "pulsar-science-pack",
    "void-science-pack", "voidp-void-science-pack"
  }
}
local pack_to_card = {}
for tier, names in pairs(tiers) do
  for _, name in ipairs(names) do pack_to_card[name] = cards[tier] end
end
local system_cards = {}
for _, card in pairs(cards) do system_cards[card] = true end

local function name_of(ingredient)
  return ingredient.name or ingredient[1]
end
local function amount_of(ingredient)
  return ingredient.amount or ingredient[2] or 1
end
local function available(card)
  return (data.raw.tool and data.raw.tool[card])
    or (data.raw.item and data.raw.item[card])
end
local function lookup(name)
  local card = pack_to_card[name]
  if not card then
    local source = name:match("^razi%-(.+%-science%-pack)%-tech%-card$")
    card = source and pack_to_card[source]
  end
  return card and available(card) and card or nil
end
local function ingredients_for(original)
  local ingredients, positions = {}, {}
  local replaced = false
  for _, input in ipairs(original) do
    local source = name_of(input)
    local card = lookup(source)
    local target = card or source
    if card and card ~= source then replaced = true end
    if positions[target] then
      local previous = ingredients[positions[target]]
      -- A composite system card includes the lower-science inputs already.
      local amount = math.max(amount_of(previous), amount_of(input))
      if previous.name then previous.amount = amount else previous[2] = amount end
    else
      local entry = table.deepcopy(input)
      if entry.name then entry.name = target else entry[1] = target end
      positions[target] = #ingredients + 1
      ingredients[#ingredients + 1] = entry
    end
  end
  return replaced and ingredients or nil
end
local function lab_accepts(ingredients)
  for _, lab in pairs(data.raw.lab or {}) do
    local accepted = {}
    for _, item in ipairs(lab.inputs or {}) do accepted[item] = true end
    local all = true
    for _, entry in ipairs(ingredients) do
      if not accepted[name_of(entry)] then all = false break end
    end
    if all then return true end
  end
  return false
end
local function start_level(name)
  return tonumber(name:match("%-(%d+)$")) or 1
end
local function shifted_formula(formula, amount)
  -- L/l is Factorio's research level; keep the native exponential growth.
  return (formula:gsub("%f[%w][Ll]%f[^%w]", "(L+" .. amount .. ")"))
end
local function safe_effects(effects)
  if not effects or #effects == 0 then return false end
  for _, effect in ipairs(effects) do
    -- Never duplicate technology unlocks, scripted milestones or location gates.
    if effect.type == "unlock-recipe" or effect.type == "unlock-space-location"
      or effect.type == "give-item" or effect.type == "nothing" then return false end
  end
  return true
end
function M.data_final_fixes()
  local technology = data.raw.technology or {}
  local names = {}
  for name in pairs(technology) do names[#names + 1] = name end
  table.sort(names)
  local created = 0
  for _, name in ipairs(names) do
    local source = technology[name]
    if name:sub(1, #PREFIX) ~= PREFIX and source.max_level == "infinite"
      and source.upgrade == true and source.enabled ~= false
      and not source.hidden and not source.research_trigger
      and source.unit and source.unit.ingredients and safe_effects(source.effects)
      and #(PREFIX .. name .. "-cards") <= 200
      and not technology[PREFIX .. name .. "-cards"] then
      local ingredients = ingredients_for(source.unit.ingredients)
      if ingredients and lab_accepts(ingredients) then
        local clone = table.deepcopy(source)
        -- A -7 suffix starts Factorio research at level seven, so append a
        -- nonnumeric suffix: every continuation must begin at level one.
        clone.name = PREFIX .. name .. "-cards"
        clone.localised_name = source.localised_name
          or {"technology-name." .. name:gsub("%-%d+$", "")}
        clone.localised_description = source.localised_description
          or {"razi-infinite-research.consolidated"}
        clone.unit.ingredients = ingredients
        if clone.unit.count_formula then
          clone.unit.count_formula = shifted_formula(
            clone.unit.count_formula, start_level(name) + EARLY_LEVELS - 1)
        end
        -- Do not use the original infinite tech as a prerequisite: it can never
        -- be completed. Force-level switching makes the new tier available.
        clone.prerequisites = table.deepcopy(source.prerequisites or {})
        clone.enabled = false
        clone.visible_when_disabled = false
        clone.order = (source.order or "z"):sub(1, 176) .. "-razi-system"
        clone.max_level = "infinite"
        clone.upgrade = true
        data:extend({clone})
        created = created + 1
      end
    end
  end
  if log then
    log("[Razi Protocol/infinite-research] " .. created
      .. " compatible infinite research continuations")
  end
end
M.prefix = PREFIX
M.early_levels = EARLY_LEVELS
M.start_level = start_level
M.shifted_formula = shifted_formula
return M
