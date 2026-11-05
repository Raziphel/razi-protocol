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
-- Only effects that provide a repeatable bonus may be cloned. Other
-- infinite researches sometimes gate a recipe, planet or other one-off event.
-- Factorio 2.1's Modifier type list is authoritative for these identifiers.
local repeatable_effects = {
  ["ammo-damage"] = true, ["gun-speed"] = true, ["turret-attack"] = true,
  ["artillery-range"] = true, ["mining-drill-productivity-bonus"] = true,
  ["change-recipe-productivity"] = true, ["laboratory-productivity"] = true,
  ["laboratory-speed"] = true, ["worker-robot-speed"] = true,
  ["worker-robot-storage"] = true, ["worker-robot-battery"] = true,
  ["maximum-following-robots-count"] = true,
  ["follower-robot-lifetime"] = true, ["train-braking-force-bonus"] = true,
  ["inserter-stack-size-bonus"] = true,
  ["bulk-inserter-capacity-bonus"] = true,
  ["belt-stack-size-bonus"] = true, ["character-health-bonus"] = true,
  ["character-crafting-speed"] = true, ["character-mining-speed"] = true,
  ["character-running-speed"] = true, ["character-build-distance"] = true,
  ["character-item-drop-distance"] = true,
  ["character-reach-distance"] = true,
  ["character-resource-reach-distance"] = true,
  ["character-item-pickup-distance"] = true,
  ["character-loot-pickup-distance"] = true,
  ["character-inventory-slots-bonus"] = true,
  ["character-logistic-trash-slots"] = true,
  ["deconstruction-time-to-live"] = true,
  ["max-failed-attempts-per-tick-per-construction-queue"] = true,
  ["max-successful-attempts-per-tick-per-construction-queue"] = true,
  ["beacon-distribution"] = true, ["cargo-landing-pad-count"] = true,
  ["max-cargo-bay-unloading-distance"] = true
}

local function safe_effects(effects)
  if not effects or #effects == 0 then return false end
  for _, effect in ipairs(effects) do
    if not repeatable_effects[effect.type] then return false end
  end
  return true
end
-- Do not use 'upgrade' for eligibility. In the prototype it only changes
-- research-screen presentation, and valid infinite technologies can omit it.
local function reason_to_skip(source)
  if source.max_level ~= "infinite" then return "not-infinite" end
  if source.enabled == false or source.hidden then return "disabled-or-hidden" end
  if source.research_trigger then return "research-trigger" end
  if not source.unit or not source.unit.ingredients or #source.unit.ingredients == 0
    or not (source.unit.count_formula or source.unit.count) then
    return "no-research-units"
  end
  if not safe_effects(source.effects) then return "one-time-or-unknown-effects" end
  return nil
end

function M.data_final_fixes()
  local technology = data.raw.technology or {}
  local names = {}
  for name in pairs(technology) do names[#names + 1] = name end
  table.sort(names)
  local created, considered, skipped = 0, 0, {}
  local function skip(reason, name)
    skipped[reason] = skipped[reason] or {}
    skipped[reason][#skipped[reason] + 1] = name
  end
  for _, name in ipairs(names) do
    local source = technology[name]
    if source.max_level == "infinite" and name:sub(1, #PREFIX) ~= PREFIX then
      considered = considered + 1
      local next_name = PREFIX .. name .. "-cards"
      local reason = reason_to_skip(source)
      if not reason and #next_name > 200 then reason = "name-too-long" end
      if not reason and technology[next_name] then reason = "already-generated" end
      local ingredients = not reason and ingredients_for(source.unit.ingredients)
      if not reason and not ingredients then reason = "no-mapped-system-science" end
      if not reason and not lab_accepts(ingredients) then
        reason = "no-compatible-lab"
      end
      if reason then
        skip(reason, name)
      else
        local clone = table.deepcopy(source)
        -- A name ending -7 would start at level seven, not level one.
        -- Keep this ID stable for saves made by previous 3.x builds.
        clone.name = next_name
        clone.localised_name = {"",
          source.localised_name
            or {"technology-name." .. name:gsub("%-%d+$", "")},
          " ", {"razi-infinite-research.suffix"}
        }
        -- Do not print the same line twice when a source has no description.
        if source.localised_description then
          clone.localised_description = {"", source.localised_description,
            "\n", {"razi-infinite-research.consolidated"}}
        else
          clone.localised_description = {"razi-infinite-research.consolidated"}
        end
        clone.unit.ingredients = ingredients
        if clone.unit.count_formula then
          clone.unit.count_formula = shifted_formula(
            clone.unit.count_formula, start_level(name) + EARLY_LEVELS - 1)
        end
        -- The original infinite source cannot be a prerequisite: it never
        -- finishes. Runtime switches the force between its two research paths.
        clone.prerequisites = table.deepcopy(source.prerequisites or {})
        clone.enabled = false
        clone.visible_when_disabled = false
        clone.order = (source.order or "z"):sub(1, 176) .. "-razi-system"
        clone.max_level = "infinite"
        clone.upgrade = source.upgrade
        data:extend({clone})
        created = created + 1
      end
    end
  end
  if log then
    log("[Razi Protocol/infinite-research] " .. created .. " of " ..
      considered .. " infinite technologies have system-card continuations")
    local reasons = {}
    for reason in pairs(skipped) do reasons[#reasons + 1] = reason end
    table.sort(reasons)
    for _, reason in ipairs(reasons) do
      log("[Razi Protocol/infinite-research] skipped " .. reason ..
        ": " .. table.concat(skipped[reason], ", "))
    end
  end
end
M.prefix = PREFIX
M.early_levels = EARLY_LEVELS
M.start_level = start_level
M.shifted_formula = shifted_formula
return M
