-- Optional cross-planet production recipes.
-- Each alternative has to respect the original recipe's research unlock.
local M = {}
local interdependence = require("prototypes.compat.interdependence_mode")
local portfolio = require("prototypes.compat.industry_portfolio")

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
    batch = 4, bonus = 1, target_bonus_fraction = 0.20,
    max_bonus_fraction = 0.25, time_multiplier = 1.12,
    count = 550, time = 45,
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
    batch = 4, bonus = 1, target_bonus_fraction = 0.20,
    max_bonus_fraction = 0.25, time_multiplier = 1.12,
    count = 780, time = 60,
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
    batch = 4, bonus = 1, target_bonus_fraction = 0.20,
    max_bonus_fraction = 0.25, time_multiplier = 1.12,
    count = 980, time = 60,
    bonus_icon = "bioluminescent-crystal"
  },
  {
    name="razi-galactic-vulcanus-bioptic-casting",
    source="kr-casting-rare-metals",product="kr-rare-metals",
    category="metallurgy",working_world="vulcanus",
    required_mods={"Moshine"},
    planets={"planet-discovery-vulcanus","planet-discovery-gleba",
      "planet-discovery-moshine"},
    science={"solaris-tech-card","nyxaris-tech-card"},
    supplier_recipes={{recipe="bioflux",product="bioflux"},
      {recipe="optical-cable",product="optical-cable"}},
    additional={{type="item",name="bioflux",amount=2},
      {type="item",name="optical-cable",amount=2}},
    batch=4,bonus=1,count=750,time=45,
    bonus_icon="optical-cable",require_supplier_provenance=true,
    max_bonus_fraction=0.25,time_multiplier=1.15
  },
  -- Let the Calidus factory benefit from supplies developed across the
  -- first two stars. Every source recipe and supplier unlock still applies.
  {
    name="razi-first-frontier-relay-components",
    source="kr-electronic-components",product="kr-electronic-components",
    category="crafting",working_world="nauvis",
    required_mods={"Moshine"},
    planets={"planet-discovery-vulcanus","planet-discovery-gleba",
      "planet-discovery-moshine"},
    science={"solaris-tech-card","nyxaris-tech-card"},
    supplier_recipes={{recipe="kr-casting-rare-metals",product="kr-rare-metals"},
      {recipe="bioflux",product="bioflux"},
      {recipe="optical-cable",product="optical-cable"}},
    additional={{type="item",name="kr-rare-metals",amount=2},
      {type="item",name="bioflux",amount=1},
      {type="item",name="optical-cable",amount=2}},
    batch=4,bonus=1,count=600,time=45,
    bonus_icon="optical-cable",require_supplier_provenance=true,
    max_bonus_fraction=0.25,time_multiplier=1.12
  }
}

local Graph=require("__razi_lib__/lib/technology_graph")
local Recipe=require("__razi_lib__/lib/recipe")
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

local function depends_on(start,sought)
  return Graph.reaches(technologies(),start,sought)
end

-- Building an index once beats rescanning every technology for every
-- native recipe and imported supplier (especially with dozens of planets).
-- Only Razi exchange techs are created after this first lookup, so the
-- original source-mod unlocks are already stable by this final-fixes pass.
local indexed_technologies, unlockers_by_recipe

local function native_unlockers()
  local techs = technologies()
  if indexed_technologies == techs and unlockers_by_recipe then
    return unlockers_by_recipe
  end
  local index=Graph.unlock_index(techs)
  indexed_technologies, unlockers_by_recipe = techs, index
  return index
end

local function unlock_technology(recipe_name, guard)
  for _, name in ipairs(native_unlockers()[recipe_name] or {}) do
    local tech = technologies()[name]
    if tech and tech.enabled ~= false and not tech.hidden then
      local too_late = false
      for _, gate in ipairs(guard.not_after or {}) do
        if depends_on(name, gate) then too_late = true break end
      end
      if not too_late then return name end
    end
  end
  return nil
end

-- Lab inputs are stable by the time the exchange modules run.
-- Building this once is cheaper than rebuilding each lab's set per recipe.
local lab_input_sets
local function lab_can_research(packs)
  if not lab_input_sets then
    lab_input_sets={}
    for _,lab in pairs(data.raw.lab or {}) do
      local accepted={}
      for _,science in ipairs(lab.inputs or {}) do accepted[science]=true end
      lab_input_sets[#lab_input_sets+1]=accepted
    end
  end
  for _,available in ipairs(lab_input_sets) do
    local all=true
    for _,science in ipairs(packs) do
      if not available[science] then all=false break end
    end
    if all then return true end
  end
  return false
end

local function matches_surface(recipe, world)
  if not world then return false end
  local conditions = recipe.surface_conditions or {}
  if #conditions == 0 then return true end
  for _, condition in ipairs(conditions) do
    -- An omitted per-planet surface property uses the registered Factorio
    -- surface property's default_value. Missing is NOT automatically zero
    -- or a mismatch: e.g. Cerys ambient radiation on Aquilo cryo machines.
    local properties=world.surface_properties or {}
    local value=properties[condition.property]
    if value==nil then
      local property=raw("surface-property",condition.property)
      value=property and property.default_value
    end
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

-- The big packs can have hundreds of assemblers and furnaces. Their
-- categories and fluid ports don't change while these recipes are created.
local machines_by_category
local function crafting_machine_index()
  if machines_by_category then return machines_by_category end
  local index={}
  for _,family in ipairs({"assembling-machine","furnace"}) do
    for _,machine in pairs(data.raw[family] or {}) do
      if not machine.fixed_recipe then
        local inputs,outputs=machine_fluid_ports(machine)
        for _,category in ipairs(machine.crafting_categories or {}) do
          local list=index[category]
          if not list then list={} index[category]=list end
          list[#list+1]={machine=machine,inputs=inputs,outputs=outputs}
        end
      end
    end
  end
  machines_by_category=index
  return index
end

-- Some machines (notably older assemblers and source-mod variants) have
-- explicit recipe ingredient slot limits. Imported ingredients may add new
-- *kinds* of input but repeated ingredients are merged by register_exchange.
-- Check distinct type+name pairs to match the final generated recipe.
local function distinct_ingredient_count(entries)
  local names={}
  local count=0
  for _,entry in ipairs(entries or {}) do
    local name=name_of(entry)
    if name then
      local kind=entry.type=="fluid" and "fluid" or "item"
      local key=kind..":"..name
      if not names[key] then
        names[key]=true
        count=count+1
      end
    end
  end
  return count
end

local function machine_can_craft(category, base, additional, world)
  local ingredients={}
  for _,entry in ipairs(base.ingredients) do ingredients[#ingredients+1]=entry end
  for _,entry in ipairs(additional) do ingredients[#ingredients+1]=entry end
  local required_ingredients=distinct_ingredient_count(ingredients)
  local required_inputs=distinct_fluid_count(ingredients)
  local required_outputs=distinct_fluid_count(base.results)
  for _,candidate in ipairs(crafting_machine_index()[category] or {}) do
    local capacity=candidate.machine.ingredient_count
    -- Nil means no explicit prototype limit. A numeric limit is authoritative.
    if (type(capacity)~="number" or capacity>=required_ingredients)
      and candidate.inputs>=required_inputs and candidate.outputs>=required_outputs
      and matches_surface(candidate.machine,world) then
      return true
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
  -- Community items and Razi's own shared components may use layered
  -- `icons` without a plain `icon`. Show the shipping input on the
  -- premium recipe regardless of which valid icon representation it uses.
  local layer = marker and (marker.icon
    and {icon=marker.icon, icon_size=marker.icon_size or 64}
    or marker.icons and marker.icons[1])
  if layer and layer.icon then
    local size=layer.icon_size or 64
    icons[#icons + 1] = {
      icon=layer.icon,icon_size=size,
      scale=0.24*64/size,shift={8,8}
    }
  end
  return icons
end

local function safe_template(base, output)
  if not (base and base.ingredients and base.results and not base.normal
      and not base.expensive and not base.hidden) then return false end
  local found = false
  -- We scale *every* native result when building a freight alternative,
  -- not just the requested bonus product. A source mod may return random
  -- byproducts, range-based amounts or catalysts with a missing amount.
  -- Never attempt arithmetic on one of those templates.
  for _, result in ipairs(base.results) do
    if type(result.amount)~="number" or result.amount<=0
      or result.probability~=nil
      or result.amount_min~=nil or result.amount_max~=nil then
      return false
    end
    if name_of(result) == output then
      if result.type == "fluid" then return false end
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
    if not raw("tool",pack) then return end
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
  for _, ingredient in ipairs(rule.additional) do
    local import=deepcopy(ingredient)
    -- Deep mode means larger physical freight orders, NOT more earlier-tier
    -- science cards. Keep the bonus fixed and never alter native recipes.
    if interdependence.deep() then
      import.amount=math.ceil(import.amount*1.5)
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
      count = rule.count, time = rule.time,
      ingredients = {}
    },
    order = "fz[razi-exchanges]-" .. rule.name
  }
  for _,pack in ipairs(science) do
    tech.unit.ingredients[#tech.unit.ingredients + 1] = {pack,1}
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
  if not interdependence.enabled() or not (mods and mods["Krastorio2-spaced-out"])
    or not enabled("razi-enable-k2so-production-exchanges") then return end
  for _, rule in ipairs(exchanges) do register_exchange(rule) end
end

-- A K2SO manufacturing alternative that is available from Balanced onwards.
-- Respect the independent K2SO exchange toggle rather than unintentionally
-- routing K2SO recipes through the modded-world toggle.
function M.register_k2so_balanced(rules)
  if not interdependence.enabled() or not (mods and mods["Krastorio2-spaced-out"])
    or not enabled("razi-enable-k2so-production-exchanges") then return end
  for _,rule in ipairs(rules or {}) do register_exchange(rule) end
end

function M.register_additional(rules)
  if not interdependence.enabled() or not (mods and mods["Krastorio2-spaced-out"])
    or not enabled("razi-enable-modded-planet-exchanges") then return end
  for _, rule in ipairs(rules or {}) do register_exchange(rule) end
end

-- Deep industry can use either catalog without changing the two legacy
-- independent toggles. A single startup setting remains the master switch.
function M.register_k2so(rules)
  if not interdependence.deep() or not (mods and mods["Krastorio2-spaced-out"])
    or not enabled("razi-enable-k2so-production-exchanges") then return end
  for _, rule in ipairs(rules or {}) do register_exchange(rule) end
end

return M
