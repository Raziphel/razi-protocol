-- Optional cross-planet production recipes.
-- Each alternative has to respect the original recipe's research unlock.
local M = {}
local interdependence = require("prototypes.industry.exchanges.interdependence_mode")
local portfolio = require("prototypes.industry.exchanges.industry_portfolio")
local exchanges = require("prototypes.industry.exchanges.exchange_rules")
local support = require("prototypes.industry.exchanges.exchange_support")
local Recipe=require("__razi_lib__/lib/recipe")
local raw = support.raw
local deepcopy = support.deepcopy
local name_of = support.name_of
local valid_ingredient = support.valid_ingredient
local technologies = support.technologies
local unlock_technology = support.unlock_technology
local gated_research_count = support.gated_research_count
local lab_can_research = support.lab_can_research
local matches_surface = support.matches_surface
local machine_can_craft = support.machine_can_craft
local recipe_icon = support.recipe_icon
local safe_template = support.safe_template

local recipe_produces=Recipe.produces

local function source_supports_category(base, category)
  if not base then return false end
  local categories = base.categories or {base.category or "crafting"}
  for _, existing in ipairs(categories) do
    if existing == category then return true end
  end
  return false
end

local function register_exchange(rule)
  -- Keep a small set of actually different production chains. Legacy
  -- duplicate variants and Ferrum/Balack dependencies are not generated.
  if not portfolio.keep(rule.name) then return end
  local profile=portfolio.profile(rule.name)
  if not profile then return end
  if rule.deep_only and not interdependence.deep() then return end
  if rule.source_mod and not mods[rule.source_mod] then return end
  for _, needed_mod in ipairs(rule.required_mods or {}) do
    if not mods[needed_mod] then return end
  end
  local base = raw("recipe", rule.source)
  local world = raw("planet", rule.surface_world or rule.working_world)
  if not safe_template(base, rule.product)
    or (rule.keep_native_category and not source_supports_category(base, rule.category))
    or not (raw("item", rule.product) or raw("ammo", rule.product))
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

  -- Stricter opt-in requirements for the newly introduced multi-world
  -- factories. All imports must be actual producer outputs, and all such
  -- recipes remain optional even when a supplier mod is missing.
  if rule.require_supplier_provenance then
    for _, extra in ipairs(rule.additional) do
      if extra.type~="item" then return end
      local proven=false
      for _, supplied in ipairs(rule.supplier_recipes or {}) do
        if supplied.product==name_of(extra) then proven=true break end
      end
      if not proven then return end
    end
  end
  if rule.time_multiplier~=nil
    and (type(rule.time_multiplier)~="number"
      or rule.time_multiplier<1.1 or rule.time_multiplier>1.3) then return end
  -- The early/middle partnerships may request a modest *per-machine*
  -- minimum output rate. This is not a promise of net freight profitability.
  if rule.min_throughput_ratio~=nil
    and (type(rule.min_throughput_ratio)~="number"
      or rule.min_throughput_ratio<1
      or rule.min_throughput_ratio>1.08) then return end
  if rule.max_bonus_fraction~=nil
    and (type(rule.max_bonus_fraction)~="number"
      or rule.max_bonus_fraction<=0
      or rule.max_bonus_fraction>0.30) then return end
  -- Compute the bonus from the *loaded* native recipe when requested.
  -- This matters for multi-output products such as Vesta foundations:
  -- a fixed +1 on forty native products would lose throughput.
  local native_amount
  for _, result in ipairs(base.results) do
    if name_of(result)==rule.product then native_amount=result.amount end
  end
  if type(native_amount)~="number" or native_amount<=0
    or type(rule.batch)~="number" or rule.batch<1 then return end
  local bonus=rule.bonus
  if rule.target_bonus_fraction~=nil then
    local share=rule.target_bonus_fraction
    if type(share)~="number" or share<0.16 or share>0.25 then return end
    bonus=math.max(1,math.floor(native_amount*rule.batch*share+0.000001))
  end
  if rule.min_throughput_ratio then
    -- Integer output rounding otherwise makes a nominal 20% recipe yield
    -- less than the time premium, particularly on 2-item native batches.
    local time_ratio=rule.time_multiplier or 1.15
    local base_output=native_amount*rule.batch
    local needed=math.ceil(base_output*
      (time_ratio*rule.min_throughput_ratio-1)-0.000001)
    bonus=math.max(bonus or 0,needed)
  end
  if type(bonus)~="number" or bonus<1 then return end
  -- No Razi exchange may increase a native deterministic batch by more
  -- than 30%; explicitly constrained modern freight recipes cap at 25%.
  if rule.deep_only then
    if #rule.planets<2 or #rule.additional==0
      or bonus>native_amount*rule.batch*0.30 then return end
  end
  if rule.max_bonus_fraction~=nil and bonus>native_amount*rule.batch
    *rule.max_bonus_fraction+0.000001 then return end
  if rule.min_throughput_ratio then
    local time_ratio=rule.time_multiplier or 1.15
    if (native_amount*rule.batch+bonus)/(native_amount*rule.batch*
      time_ratio)+0.000001<rule.min_throughput_ratio then return end
  end

  -- Source tech and every supplying planet still gate the unlock. Ordinary
  -- research packs pay for the blueprint, while actual cross-world resources
  -- must be imported for every production batch.
  local science=portfolio.science(rule)
  for _,pack in ipairs(science) do
    if not (raw("tool",pack) or raw("item",pack)) then return end
  end
  if not lab_can_research(science) then return end

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
  alternative.localised_description = {"",
    {"recipe-description." .. rule.name},"\n",
    {"razi-industry-profile." .. profile.kind}}
  alternative.icon, alternative.icon_size = nil, nil
  alternative.icons = icons
  alternative.enabled = false
  alternative.hidden = false
  alternative.hide_from_player_crafting = false
  alternative.categories = {rule.category}
  alternative.category = nil
  alternative.surface_conditions = conditions
  -- A 25% bonus with a 30% time penalty actually reduces throughput.
  -- Imported materials already pay the logistics price, so use a smaller
  -- default machine-time premium for legacy alternatives.
  alternative.energy_required = (base.energy_required or 0.5) * rule.batch
    * portfolio.time_multiplier(profile,native_amount,rule.batch,bonus,
      rule.time_multiplier or 1.15)
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
  -- Apply catalytic savings only to the cloned native ingredients after
  -- scaling. If the source author removed the targeted ingredient, do not
  -- publish a recipe whose advertised industrial effect is fictional.
  if not portfolio.conserve(alternative.ingredients,profile) then return end
  for _, product in ipairs(alternative.results) do
    product.amount = product.amount * rule.batch
    for _, field in ipairs({"ignored_by_stats", "ignored_by_productivity",
      "catalyst_amount"}) do
      if product[field] then product[field] = product[field] * rule.batch end
    end
    if name_of(product) == rule.product then
      product.amount = product.amount + bonus
    end
  end
  -- Deep mode means larger physical freight orders, NOT more earlier-tier
  -- science cards: every import is exactly 1.5 times its Balanced amount
  -- per crafted product. When that is not a whole number, the whole recipe
  -- (native inputs, products and crafting time) is doubled first, so the
  -- bonus, the profile and the output per second stay what they were.
  local freight_scale=1
  if interdependence.deep() then
    for _, ingredient in ipairs(rule.additional) do
      if (ingredient.amount*1.5)%1~=0 then freight_scale=2 break end
    end
    if freight_scale==2 then
      for _, ingredient in ipairs(alternative.ingredients) do
        ingredient.amount = ingredient.amount * 2
        if ingredient.ignored_by_stats then
          ingredient.ignored_by_stats = ingredient.ignored_by_stats * 2
        end
      end
      for _, product in ipairs(alternative.results) do
        product.amount = product.amount * 2
        for _, field in ipairs({"ignored_by_stats", "ignored_by_productivity",
          "catalyst_amount"}) do
          if product[field] then product[field] = product[field] * 2 end
        end
      end
      alternative.energy_required = alternative.energy_required * 2
    end
  end
  for _, ingredient in ipairs(rule.additional) do
    local import=deepcopy(ingredient)
    if interdependence.deep() then
      import.amount=import.amount*freight_scale*1.5
    end
    local duplicate
    for _, existing in ipairs(alternative.ingredients) do
      if name_of(existing) == name_of(ingredient)
        and (existing.type or "item") == (ingredient.type or "item") then
        duplicate = existing
        break
      end
    end
    if duplicate then
      duplicate.amount = duplicate.amount + import.amount
    else
      alternative.ingredients[#alternative.ingredients + 1] = import
    end
  end

  local tech = {
    type = "technology",
    name = rule.name,
    localised_name = {"technology-name." .. rule.name},
    localised_description = {"",
      {"technology-description." .. rule.name},"\n",
      {"razi-industry-profile." .. profile.kind}},
    icon = visual.icon,
    icons = visual.icons and deepcopy(visual.icons) or nil,
    -- The native technology may use a 64px icon with no icon_size field.
    -- Preserve its declared size (or Factorio's 64px default) rather than
    -- forcing 256px for an image that only contains 64x64 pixels.
    icon_size = visual.icon_size,
    prerequisites = prerequisite_list,
    effects = {{type="unlock-recipe", recipe=rule.name}},
    unit = {
      count = gated_research_count(rule,prerequisite_list),
      time = rule.time,
      ingredients = {}
    },
    order = "fz[razi-exchanges]-" .. rule.name
  }
  for _,pack in ipairs(science) do
    tech.unit.ingredients[#tech.unit.ingredients + 1] = {pack,1}
  end
  data:extend({alternative, tech})
end

function M.data_final_fixes()
  if not interdependence.enabled() or not (mods and mods["Krastorio2-spaced-out"]) then return end
  for _, rule in ipairs(exchanges) do register_exchange(rule) end
end

-- A K2SO manufacturing alternative that is available from Balanced onwards.
function M.register_k2so_balanced(rules)
  if not interdependence.enabled() or not (mods and mods["Krastorio2-spaced-out"]) then return end
  for _,rule in ipairs(rules or {}) do register_exchange(rule) end
end

function M.register_additional(rules)
  if not interdependence.enabled() or not (mods and mods["Krastorio2-spaced-out"]) then return end
  for _, rule in ipairs(rules or {}) do register_exchange(rule) end
end

return M
