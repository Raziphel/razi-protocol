-- Checks and lookups the production exchanges are built from: the technology graph, the
-- native unlock of a recipe, the research cost, the laboratories and the machines that can
-- craft a recipe on a planet.
local portfolio = require("prototypes.industry.exchanges.industry_portfolio")
local Graph=require("__razi_lib__/lib/technology_graph")
local function raw(kind, name)
  return data.raw[kind] and data.raw[kind][name]
end

local item_families = {"item", "tool", "module", "ammo", "capsule"}

local function visible_item(name)
  for _, family in ipairs(item_families) do
    local item = raw(family, name)
    if item and not item.hidden then return item end
  end
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
  return visible_item(name) ~= nil
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

-- More than one technology may unlock the same native recipe. Iteration
-- order in the modded technology index is NOT progression order (the former
-- selected Outer Frontier Mastery-gated gold refining in one modpack).
-- Prefer the earliest legitimate source unlocker in the *actual graph*.
local ancestor_size={}
local function ancestor_count(name)
  if ancestor_size[name] then return ancestor_size[name] end
  local seen={}
  local function visit(current)
    local tech=technologies()[current]
    for _,parent in ipairs(tech and tech.prerequisites or {}) do
      if not seen[parent] then
        seen[parent]=true
        visit(parent)
      end
    end
  end
  visit(name)
  local total=0
  for _ in pairs(seen) do total=total+1 end
  ancestor_size[name]=total
  return total
end

local function unlock_technology(recipe_name, guard)
  local candidates={}
  for _,name in ipairs(native_unlockers()[recipe_name] or {}) do
    local tech=technologies()[name]
    if tech and tech.enabled~=false and not tech.hidden then
      local too_late=false
      for _,gate in ipairs(guard.not_after or {}) do
        if name==gate or depends_on(name,gate) then
          too_late=true break
        end
      end
      if not too_late then candidates[#candidates+1]=name end
    end
  end
  table.sort(candidates,function(a,b)
    local a_before_b=depends_on(b,a)
    local b_before_a=depends_on(a,b)
    if a_before_b~=b_before_a then return a_before_b end
    local ac,bc=ancestor_count(a),ancestor_count(b)
    if ac~=bc then return ac<bc end
    local at,bt=technologies()[a],technologies()[b]
    local au=at.unit and at.unit.count or 0
    local bu=bt.unit and bt.unit.count or 0
    if au~=bu then return au<bu end
    return a<b
  end)
  return candidates[1]
end

-- Set research effort by the highest *actual* required tier. An advanced
-- native unlock or source supplier can put an otherwise cheap blueprint
-- behind a late galaxy gate; research cost must acknowledge that.
local research_tiers={
  {"solaris-discovery",500},{"nyxaris-discovery",500},
  {"vibrant-discovery",950},{"vespera-discovery",950},
  {"beetlejuice-discovery",1450},{"umbra-discovery",1450},
  {"razi-outer-frontier-mastery",1950}
}
local function gated_research_count(rule,parents)
  local cost=rule.count
  local scanned={}
  local function science_ancestors(name)
    if scanned[name] then return end
    scanned[name]=true
    local node=technologies()[name]
    if not node then return end
    cost=math.max(cost,portfolio.science_floor(node))
    for _,parent in ipairs(node.prerequisites or {}) do
      science_ancestors(parent)
    end
  end
  for _,name in ipairs(parents) do
    science_ancestors(name)
    for _,entry in ipairs(research_tiers) do
      if technologies()[entry[1]] and
        (name==entry[1] or depends_on(name,entry[1])) then
        cost=math.max(cost,entry[2])
      end
    end
  end
  return cost
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
    local result = raw("item", product) or raw("ammo", product)
    if not result then return nil end
    if result.icons then
      icons = deepcopy(result.icons)
    elseif result.icon then
      icons = {{icon=result.icon, icon_size=result.icon_size or 64}}
    else
      return nil
    end
  end
  local marker = visible_item(bonus)
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
      or result.independent_probability~=nil or result.shared_probability~=nil
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

return {
  raw = raw,
  deepcopy = deepcopy,
  name_of = name_of,
  valid_ingredient = valid_ingredient,
  technologies = technologies,
  unlock_technology = unlock_technology,
  gated_research_count = gated_research_count,
  lab_can_research = lab_can_research,
  matches_surface = matches_surface,
  machine_can_craft = machine_can_craft,
  recipe_icon = recipe_icon,
  safe_template = safe_template,
}
