---@diagnostic disable: missing-fields, need-check-nil, assign-type-mismatch, undefined-field
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(value, reason)
  if not value then error(reason, 2) end
end

local function clone(value)
  if type(value) ~= "table" then return value end
  local copied = {}
  for key, inner in pairs(value) do copied[clone(key)] = clone(inner) end
  return copied
end
rawset(table, "deepcopy", clone)

local function ingredients(list)
  local result = {}
  for _, pair in ipairs(list) do
    result[#result + 1] = {type=pair[1], name=pair[2], amount=pair[3]}
  end
  return result
end

local function source_recipe(name, output, results, materials, category)
  return {
    type="recipe", name=name, enabled=false,
    category=category, energy_required=2, allow_productivity=true,
    icon="__base__/graphics/icons/iron-plate.png", icon_size=64,
    ingredients=ingredients(materials), results=ingredients(results),
    main_product=output
  }
end

local function setup(options)
  options = options or {}
  local items={}
  for _, name in ipairs({
    "kr-rare-metals", "bioflux", "kr-electronic-components",
    "kr-silicon", "kr-glass", "plastic-bar", "holmium-plate",
    "kr-energy-control-unit", "low-density-structure",
    "kr-imersite-crystal", "kr-lithium-sulfur-battery",
    "supercapacitor", "carbon-fiber"
  }) do
    items[name]={icon="__base__/graphics/icons/iron-plate.png",icon_size=64}
  end
  local fluids={}
  for _, name in ipairs({"kr-molten-rare-metals", "water", "kr-dirty-water",
    "fluoroketone-cold"}) do fluids[name]={} end
  local recipes={
    ["kr-casting-rare-metals"]=source_recipe("kr-casting-rare-metals",
      "kr-rare-metals",{
        {"item", "kr-rare-metals", 1},{"fluid", "kr-dirty-water", 5}
      },{
        {"fluid", "kr-molten-rare-metals", 10},
        {"fluid", "water", 10}
      },"metallurgy"),
    ["kr-electronic-components"]=source_recipe("kr-electronic-components",
      "kr-electronic-components",{{"item","kr-electronic-components",4}},{
        {"item","kr-silicon",2},{"item","kr-glass",2},
        {"item","plastic-bar",2}
      },"crafting"),
    ["kr-energy-control-unit"]=source_recipe("kr-energy-control-unit",
      "kr-energy-control-unit",{{"item","kr-energy-control-unit",1}},{
        {"item","low-density-structure",6},
        {"item","kr-imersite-crystal",3},
        {"item","kr-electronic-components",9},
        {"item","kr-lithium-sulfur-battery",3}
      },"crafting"),
    ["kr-electromagnetic-research-data"]={
      surface_conditions={{property="magnetic-field",min=99,max=99}}},
    ["kr-cryogenic-research-data"]={
      surface_conditions={{property="pressure",min=300,max=300}}}
  }
  recipes["kr-casting-rare-metals"].results[2].ignored_by_productivity=5
  local techs={}
  for _, name in ipairs({
    "planet-discovery-vulcanus","planet-discovery-gleba",
    "planet-discovery-fulgora","planet-discovery-aquilo",
    "vibrant-discovery","vespera-discovery",
    "beetlejuice-discovery","umbra-discovery"
  }) do
    techs[name]={name=name,prerequisites={},
      icon="__base__/graphics/technology/automation.png",icon_size=256}
  end
  for _, rule in ipairs({
    {"foundry","kr-casting-rare-metals"},
    {"kr-electronic-components","kr-electronic-components"},
    {"kr-energy-control-unit","kr-energy-control-unit"}
  }) do
    techs[rule[1]]=techs[rule[1]] or {name=rule[1],prerequisites={},
      icon="__base__/graphics/technology/automation.png",icon_size=256}
    techs[rule[1]].effects={{type="unlock-recipe",recipe=rule[2]}}
  end
  local raw={
    item=items,fluid=fluids,recipe=recipes,technology=techs,
    tool={["calidus-tech-card"]={},["solaris-tech-card"]={},
      ["nyxaris-tech-card"]={},
      ["automation-science-pack"]={},["logistic-science-pack"]={},
      ["chemical-science-pack"]={},["production-science-pack"]={},
      ["utility-science-pack"]={}},
    planet={vulcanus={surface_properties={pressure=4000}},
      fulgora={surface_properties={["magnetic-field"]=99}},
      aquilo={surface_properties={pressure=300}}},
    lab={["kr-advanced-lab"]={inputs={"calidus-tech-card",
      "solaris-tech-card","nyxaris-tech-card",
      "automation-science-pack","logistic-science-pack",
      "chemical-science-pack","production-science-pack",
      "utility-science-pack"}}},
    ["assembling-machine"]={
      foundry={crafting_categories={"metallurgy"},fluid_boxes={
        {production_type="input"},{production_type="input"},
        {production_type="output"}}},
      ["electromagnetic-plant"]={crafting_categories={"electromagnetics"}},
      cryogenic_plant={crafting_categories={"cryogenics"},fluid_boxes={
        {production_type="input"}}}
    }
  }
  if options.hidden_bioflux then items.bioflux.hidden=true end
  if options.missing_magnetic_field then
    raw.planet.fulgora.surface_properties["magnetic-field"]=20
  end
  if options.late_native_unlock then
    techs["kr-electronic-components"].prerequisites={"beetlejuice-discovery"}
  end
  if options.tenebris_style_icon then
    -- Tenebris chitin-processing uses a 64px icon with no icon_size field.
    techs["kr-electronic-components"].icon=
      "__tenebris-prime__/graphics/icons/chitin.png"
    techs["kr-electronic-components"].icon_size=nil
  end
  if options.layered_native_icon then
    techs["kr-electronic-components"].icon=nil
    techs["kr-electronic-components"].icon_size=nil
    techs["kr-electronic-components"].icons={{
      icon="__base__/graphics/icons/iron-plate.png",icon_size=64
    }}
  end
  if options.unavailable_native_unlock then
    techs["kr-electronic-components"].effects={}
  end
  if options.remove_cryo_machine then
    raw["assembling-machine"].cryogenic_plant=nil
  end
  if options.incomplete_native_recipe then
    recipes["kr-energy-control-unit"].results={}
  end
  if options.without_second_lab then
    raw.lab={}
  end
  if options.cryo_ports_missing then
    raw["assembling-machine"].cryogenic_plant.fluid_boxes={}
  end
  if options.no_vulcanus_foundry_output then
    raw["assembling-machine"].foundry.fluid_boxes={
      {production_type="input"},{production_type="input"}}
  end
  if options.electromagnetic_machine_excluded then
    raw["assembling-machine"]["electromagnetic-plant"].surface_conditions={
      {property="magnetic-field", max=20}}
  end
  if options.electromagnetic_ingredient_limit then
    raw["assembling-machine"]["electromagnetic-plant"].ingredient_count=
      options.electromagnetic_ingredient_limit
  end
  rawset(_G,"data",{raw=raw,extend=function(self,prototypes)
    for _, prototype in ipairs(prototypes) do
      self.raw[prototype.type]=self.raw[prototype.type] or {}
      check(not self.raw[prototype.type][prototype.name],
        "Duplicate production exchange prototype")
      self.raw[prototype.type][prototype.name]=prototype
    end
  end})
  rawset(_G,"mods",options.no_k2 and {} or {
    ["Krastorio2-spaced-out"]="2.0.17"
  })
  package.loaded["prototypes.compat.planet_production_exchanges"]=nil
  return raw,require("prototypes.compat.planet_production_exchanges")
end

local function ingredient(recipe, name)
  for _, item in ipairs(recipe.ingredients or {}) do
    if item.name==name then return item.amount end
  end
end

local function product(recipe, name)
  for _, item in ipairs(recipe.results or {}) do
    if item.name==name then return item.amount end
  end
end

local full, module=setup()
-- Even with a large machine/lab catalogue, exchange checks should only
-- enumerate both catalogues once across all candidate recipes.
local machine_scans,lab_scans=0,0
setmetatable(full["assembling-machine"],{__pairs=function(t)
  machine_scans=machine_scans+1
  return next,t,nil
end})
setmetatable(full.lab,{__pairs=function(t)
  lab_scans=lab_scans+1
  return next,t,nil
end})
-- Irrelevant technologies must not change native unlock selection.
for i=1,600 do
  full.technology["unrelated-tech-"..i]={
    name="unrelated-tech-"..i,
    effects={{type="unlock-recipe",recipe="some-other-product-"..i}}
  }
end
local original=clone(full.recipe)
module.data_final_fixes()
check(machine_scans==1 and lab_scans==1,
  "Manufacturing compatibility rebuilt its machine or lab catalog per recipe")
local names={
  "razi-bio-rare-metal-casting",
  "razi-electrobiological-components",
  "razi-cryo-energy-control"
}
for _,name in ipairs(names) do
  local rule=require("prototypes.compat.industry_portfolio")
  check(rule.keep(name),"A core cross-world exchange must be curated")
end
for _, name in ipairs(names) do
  local recipe, tech=full.recipe[name],full.technology[name]
  check(recipe and tech,"Missing integrated production exchange: "..name)
  check(recipe.enabled==false and recipe.auto_recycle==false,
    "Production exchange auto-unlocked or has recursive recycling")
  check(recipe.allow_productivity==false and recipe.maximum_productivity==0,
    "Cross-planet recipe can multiply bonus with productivity")
  check(#recipe.icons>=1 and tech.icon,"Recipe or technology icon missing")
  check(tech.effects[1].recipe==name,"Exchange not unlocked by its research")
  for _,ingredient in ipairs(tech.unit.ingredients) do
    check(not ingredient[1]:find("tech%-card"),
      "Exchange research must not demand earlier-star tech cards")
  end
end
check(product(full.recipe[names[1]],"kr-rare-metals")==5,
  "Bioflux metallurgy should output five rare metals from four batches")
check(ingredient(full.recipe[names[1]],"kr-molten-rare-metals")==36,
  "Bio-molten casting lost its native molten rare-metal input")
check(ingredient(full.recipe[names[1]],"bioflux")==2,
  "Gleba is not providing industrial bioflux")
check(product(full.recipe[names[1]],"kr-dirty-water")==20,
  "Native casting byproduct was not preserved and scaled")
check(product(full.recipe[names[2]],"kr-electronic-components")==19,
  "Fulgora electronics must yield 19 from sixteen native components")
check(ingredient(full.recipe[names[2]],"kr-silicon")==8,
  "Electronics must retain all four native silicon batches")
check(ingredient(full.recipe[names[2]],"holmium-plate")==1
  and ingredient(full.recipe[names[2]],"bioflux")==1,
  "Missing Fulgora or Gleba import")
check(full.recipe[names[2]].surface_conditions[1].property=="magnetic-field",
  "Electromagnetic exchange escaped Fulgora's magnetic-field restriction")
check(product(full.recipe[names[3]],"kr-energy-control-unit")==5,
  "Cryogenic energy controls should still produce the promised batch")
check(ingredient(full.recipe[names[3]],"kr-electronic-components")==32,
  "Imported superconducting parts should conserve 4 native electronic components")
local fast=full.recipe["razi-electrobiological-components"]
local native_batch=16
local output_per_second=19/fast.energy_required
local native_per_second=native_batch/(4*2)
check(output_per_second>native_per_second and
  output_per_second/native_per_second<=1.1700001,
  "Electrobiological acceleration must be worthwhile but bounded")
check(product(full.recipe[names[3]],"kr-energy-control-unit")==5,
  "Cryogenic controllers must yield five from four native units")
check(ingredient(full.recipe[names[3]],"carbon-fiber")==4
  and ingredient(full.recipe[names[3]],"supercapacitor")==2
  and ingredient(full.recipe[names[3]],"fluoroketone-cold")==10,
  "Cryogenic exchange lost Gleba, Fulgora or Aquilo components")
check(full.recipe[names[3]].surface_conditions[1].property=="pressure",
  "Aquilo control units escaped the native cryogenic pressure restriction")
for _, native in ipairs({
  "kr-casting-rare-metals","kr-electronic-components","kr-energy-control-unit"
}) do
  local before=original[native]
  local after=full.recipe[native]
  check(product(before, native=="kr-casting-rare-metals" and "kr-rare-metals"
    or native)==product(after,
      native=="kr-casting-rare-metals" and "kr-rare-metals" or native),
    "Native production recipe altered: "..native)
end
check(#full.technology[names[1]].prerequisites==3,
  "Vulcanus/Gleba/native foundry research are required")
check(#full.technology[names[2]].prerequisites==3,
  "Fulgora/Gleba/native electronics research are required")
check(#full.technology[names[3]].prerequisites==4,
  "Aquilo, Gleba, Fulgora and native energy control research required")
module.data_final_fixes()
check(machine_scans==1 and lab_scans==1,
  "Repeated exchange registration scanned all machines or labs again")
for _, name in ipairs(names) do
  check(full.recipe[name] and full.technology[name],
    "Repeated integration removed or duplicated a recipe")
end

-- Copying a third-party technology icon must not upscale a 64px image
-- into a 256px source rectangle (e.g. Tenebris Prime's chitin.png).
local tenebris, tenebris_module=setup({tenebris_style_icon=true})
tenebris_module.data_final_fixes()
local copied_chitin=tenebris.technology["razi-electrobiological-components"]
check(copied_chitin and copied_chitin.icon==
  "__tenebris-prime__/graphics/icons/chitin.png",
  "Exchange research lost its native Tenebris icon")
check(copied_chitin.icon_size==nil,
  "Missing native icon_size must retain Factorio's 64px default")
check(tenebris.technology["kr-electronic-components"].icon_size==nil,
  "Exchange registration unexpectedly modified source technology icon size")

local layered, layered_module=setup({layered_native_icon=true})
layered_module.data_final_fixes()
local copied_layers=layered.technology["razi-electrobiological-components"]
check(copied_layers and copied_layers.icon==nil and copied_layers.icon_size==nil
  and copied_layers.icons and copied_layers.icons[1].icon_size==64,
  "Layered native technology icons must preserve their own image dimensions")
check(full.technology["razi-electrobiological-components"].icon_size==256,
  "Explicit 256px technology artwork was not preserved")

local function absent(options, expected)
  local raw, compat=setup(options)
  compat.data_final_fixes()
  for _, name in ipairs(names) do
    if expected[name] then
      check(raw.recipe[name],"Optional guard suppressed another valid exchange")
    else
      check(not raw.recipe[name] and not raw.technology[name],
        "Guard incorrectly added an exchange: "..name)
    end
  end
end
absent({no_k2=true},{})
absent({hidden_bioflux=true},{
  ["razi-cryo-energy-control"]=true
})
absent({missing_magnetic_field=true},{
  ["razi-bio-rare-metal-casting"]=true,
  ["razi-cryo-energy-control"]=true
})
absent({late_native_unlock=true},{
  ["razi-bio-rare-metal-casting"]=true,
  ["razi-cryo-energy-control"]=true
})
absent({unavailable_native_unlock=true},{
  ["razi-bio-rare-metal-casting"]=true,
  ["razi-cryo-energy-control"]=true
})
absent({remove_cryo_machine=true},{
  ["razi-bio-rare-metal-casting"]=true,
  ["razi-electrobiological-components"]=true
})
absent({incomplete_native_recipe=true},{
  ["razi-bio-rare-metal-casting"]=true,
  ["razi-electrobiological-components"]=true
})
absent({without_second_lab=true},{})
absent({cryo_ports_missing=true},{
  ["razi-bio-rare-metal-casting"]=true,
  ["razi-electrobiological-components"]=true
})
absent({no_vulcanus_foundry_output=true},{
  ["razi-electrobiological-components"]=true,
  ["razi-cryo-energy-control"]=true
})
absent({electromagnetic_machine_excluded=true},{
  ["razi-bio-rare-metal-casting"]=true,
  ["razi-cryo-energy-control"]=true
})
-- An optional premium recipe must fit a real machine's distinct input slots.
-- The native electromagnetics recipe has three items; the freight recipe
-- adds bioflux and holmium, for five distinct ingredients.
absent({electromagnetic_ingredient_limit=4},{
  ["razi-bio-rare-metal-casting"]=true,
  ["razi-cryo-energy-control"]=true
})
local enough, enough_engine=setup({electromagnetic_ingredient_limit=5})
enough_engine.data_final_fixes()
check(enough.recipe["razi-electrobiological-components"],
  "Five-slot electromagnetic machine unexpectedly rejected a valid upgrade")

-- Disabling this optional category must not disturb native K2SO recipes.
local disabled_raw, disabled_module = setup()
rawset(_G, "settings", {startup={
  ["razi-enable-k2so-production-exchanges"] = {value = false}
}})
disabled_module.data_final_fixes()
for _, name in ipairs(names) do
  check(not disabled_raw.recipe[name] and not disabled_raw.technology[name],
    "Disabled K2SO exchange still appeared: " .. name)
end
check(disabled_raw.recipe["kr-energy-control-unit"],
  "Disabling optional exchange removed native K2SO manufacturing")
rawset(_G, "settings", nil)

-- Imports already used by a native recipe are merged rather than duplicated.
local merged_raw, merged_mod = setup()
local native = merged_raw.recipe["kr-casting-rare-metals"]
native.ingredients[#native.ingredients+1]={type="item",name="bioflux",amount=1}
merged_mod.data_final_fixes()
local duplicate_count=0
for _, ing in ipairs(merged_raw.recipe["razi-bio-rare-metal-casting"].ingredients) do
  if ing.name=="bioflux" then
    duplicate_count=duplicate_count+1
    check(ing.amount==6,"Native/import batch amounts failed to merge")
  end
end
check(duplicate_count==1,"Import duplicate was not eliminated")
-- The master Off mode overrides both independently enabled catalogs.
local off_raw, off_module = setup()
rawset(_G, "settings", {startup={
  ["razi-planetary-interdependence"]={value="off"}
}})
off_module.data_final_fixes()
for _, name in ipairs(names) do
  check(not off_raw.recipe[name] and not off_raw.technology[name],
    "Master Off still created an interplanetary exchange: "..name)
end
check(off_raw.recipe["kr-casting-rare-metals"],
  "Master Off must retain K2SO's original production")
rawset(_G, "settings", nil)

-- Fixture-only alternative names must be opted into the curated policy so
-- the production arithmetic can still be tested independently of the
-- shipping portfolio without enabling these names in a real modpack.
local portfolio=require("prototypes.compat.industry_portfolio")
for _,name in ipairs({
  "razi-fixture-bulk-electronics","razi-fixture-default-energy",
  "razi-fixture-legacy-economy","razi-fixture-paced-economy",
  "razi-fixture-low-bonus-ceiling","razi-fixture-unsafe-bonus"
}) do
  portfolio.retained[name]=true
  portfolio.profiles[name]={kind="bulk"}
end

-- Native recipes with many outputs need proportional bonus math. A
-- fixed +1 on 16 components would be worse than the old four native runs.
local economic, economic_engine=setup()
economic["assembling-machine"].standard={crafting_categories={"crafting"}}
local rule={
  name="razi-fixture-bulk-electronics",source="kr-electronic-components",
  product="kr-electronic-components",category="crafting",
  working_world="fulgora",
  planets={"planet-discovery-fulgora","planet-discovery-gleba"},
  science={"solaris-tech-card","nyxaris-tech-card"},
  additional={{type="item",name="holmium-plate",amount=1}},
  batch=4,bonus=1,target_bonus_fraction=0.20,
  count=80,time=40,bonus_icon="holmium-plate",
  max_bonus_fraction=0.25,time_multiplier=1.12
}
economic_engine.register_k2so_balanced({rule})
local bulk=economic.recipe[rule.name]
check(bulk and product(bulk,"kr-electronic-components")==19,
  "Four native 4-item batches must gain three guarded bonus items")
check(math.abs(bulk.energy_required-8.96)<0.0001,
  "Four native 2s runs must retain the exact 12% time premium")
check(rule.bonus==1,
  "Scaled bonuses must not mutate shared author rules between registrations")
check(ingredient(bulk,"kr-silicon")==8
  and ingredient(bulk,"holmium-plate")==1,
  "Dynamic bonuses must not change native supply or imported material costs")
local excluded,ex_engine=setup()
excluded["assembling-machine"].standard={crafting_categories={"crafting"}}
local bad=clone(rule)
bad.name="razi-fixture-unsafe-bonus"
bad.target_bonus_fraction=0.40
ex_engine.register_k2so_balanced({bad})
check(not excluded.recipe[bad.name] and not excluded.technology[bad.name],
  "Unsafe >25% dynamic yield must be rejected")
local implicit,implicit_engine=setup()
implicit["assembling-machine"].standard={crafting_categories={"crafting"}}
implicit.recipe["kr-electronic-components"].energy_required=nil
local default_rule=clone(rule)
default_rule.name="razi-fixture-default-energy"
implicit_engine.register_k2so_balanced({default_rule})
check(implicit.recipe[default_rule.name]
  and math.abs(implicit.recipe[default_rule.name].energy_required-2.24)<0.0001,
  "Factorio's implicit 0.5s recipe time must not become a 1s source batch")
local legacy,legacy_engine=setup()
legacy["assembling-machine"].standard={crafting_categories={"crafting"}}
local legacy_rule=clone(rule)
legacy_rule.name="razi-fixture-legacy-economy"
legacy_rule.target_bonus_fraction=nil
legacy_rule.bonus=4
legacy_rule.time_multiplier=nil
legacy_engine.register_k2so_balanced({legacy_rule})
check(legacy.recipe[legacy_rule.name]
  and math.abs(legacy.recipe[legacy_rule.name].energy_required-9.2)<0.0001,
  "Default interplanetary batches should cost 15%, not 30%, extra time")

-- Fifth-pass integer rounding: preserve the 4% per-machine advantage.
local paced,paced_engine=setup()
paced["assembling-machine"].standard={crafting_categories={"crafting"}}
local paced_rule=clone(rule)
paced_rule.name="razi-fixture-paced-economy"
paced_rule.time_multiplier=1.15
paced_rule.min_throughput_ratio=1.04
paced_engine.register_k2so_balanced({paced_rule})
check(paced.recipe[paced_rule.name] and
  product(paced.recipe[paced_rule.name],"kr-electronic-components")==20,
  "Sixteen original components should earn four premium components")
check(paced_rule.bonus==1,"Bonus normalization mutated the input rule")
local constrained,constrained_engine=setup()
constrained["assembling-machine"].standard={crafting_categories={"crafting"}}
local capped=clone(paced_rule)
capped.name="razi-fixture-low-bonus-ceiling"
capped.max_bonus_fraction=0.20
constrained_engine.register_k2so_balanced({capped})
check(not constrained.recipe[capped.name],
  "Impossible throughput targets must respect the gross output ceiling")

-- Deep must require heavier physical shipments, never a third research
-- card or extra item output. Native production must stay untouched.
rawset(_G,"settings",{startup={
  ["razi-planetary-interdependence"]={value="deep"}
}})
local deep_raw,deep_engine=setup()
deep_engine.data_final_fixes()
local deep_recipe=deep_raw.recipe["razi-bio-rare-metal-casting"]
check(deep_recipe and ingredient(deep_recipe,"bioflux")==3,
  "Deep trade must increase actual imported bioflux by 50%")
check(product(deep_recipe,"kr-rare-metals")==5,
  "Deep material penalty must not inflate a recipe's bonus yield")
check(ingredient(deep_raw.recipe["kr-casting-rare-metals"],"kr-molten-rare-metals")==10,
  "Deep mode must never mutate the native factory")
for _,pack in ipairs(deep_raw.technology["razi-bio-rare-metal-casting"].unit.ingredients) do
  check(not pack[1]:find("tech%-card"),
    "Deep trade must not reintroduce old-system tech card costs")
end
rawset(_G,"settings",nil)

local f=assert(io.open("data-final-fixes.lua","r"))
local source=f:read("*a")
f:close()
local integration=assert(source:find(
  'require("prototypes.compat.k2so_planet_integration").data_final_fixes()',1,true))
local production=assert(source:find(
  'require("prototypes.compat.planet_production_exchanges").data_final_fixes()',1,true))
check(production>integration,
  "K2SO material reconciliation must precede production exchanges")
print("Cross-planet K2SO industrial exchange, safety and progression passed")
