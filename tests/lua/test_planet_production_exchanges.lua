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
      ["nyxaris-tech-card"]={}},
    planet={fulgora={surface_properties={["magnetic-field"]=99}},
      aquilo={surface_properties={pressure=300}}},
    lab={["kr-advanced-lab"]={inputs={"calidus-tech-card",
      "solaris-tech-card","nyxaris-tech-card"}}},
    ["assembling-machine"]={
      foundry={crafting_categories={"metallurgy"}},
      ["electromagnetic-plant"]={crafting_categories={"electromagnetics"}},
      cryogenic_plant={crafting_categories={"cryogenics"}}
    }
  }
  if options.hidden_bioflux then items.bioflux.hidden=true end
  if options.missing_magnetic_field then
    raw.planet.fulgora.surface_properties["magnetic-field"]=20
  end
  if options.late_native_unlock then
    techs["kr-electronic-components"].prerequisites={"beetlejuice-discovery"}
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
local original=clone(full.recipe)
module.data_final_fixes()
local names={
  "razi-bio-rare-metal-casting",
  "razi-electrobiological-components",
  "razi-cryo-energy-control"
}
for _, name in ipairs(names) do
  local recipe, tech=full.recipe[name],full.technology[name]
  check(recipe and tech,"Missing integrated production exchange: "..name)
  check(recipe.enabled==false and recipe.auto_recycle==false,
    "Production exchange auto-unlocked or has recursive recycling")
  check(recipe.allow_productivity==false and recipe.maximum_productivity==0,
    "Cross-planet recipe can multiply bonus with productivity")
  check(#recipe.icons>=1 and tech.icon,"Recipe or technology icon missing")
  check(tech.effects[1].recipe==name,"Exchange not unlocked by its research")
end
check(product(full.recipe[names[1]],"kr-rare-metals")==5,
  "Bioflux metallurgy should output five rare metals from four batches")
check(ingredient(full.recipe[names[1]],"kr-molten-rare-metals")==40,
  "Bio-molten casting lost its native molten rare-metal input")
check(ingredient(full.recipe[names[1]],"bioflux")==2,
  "Gleba is not providing industrial bioflux")
check(product(full.recipe[names[1]],"kr-dirty-water")==20,
  "Native casting byproduct was not preserved and scaled")
check(product(full.recipe[names[2]],"kr-electronic-components")==7,
  "Fulgora and Gleba electronics should improve component yield")
check(ingredient(full.recipe[names[2]],"holmium-plate")==1
  and ingredient(full.recipe[names[2]],"bioflux")==1,
  "Missing Fulgora or Gleba import")
check(full.recipe[names[2]].surface_conditions[1].property=="magnetic-field",
  "Electromagnetic exchange escaped Fulgora's magnetic-field restriction")
check(product(full.recipe[names[3]],"kr-energy-control-unit")==2,
  "Cryogenic control units need a tangible higher-output exchange")
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
for _, name in ipairs(names) do
  check(full.recipe[name] and full.technology[name],
    "Repeated integration removed or duplicated a recipe")
end

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
