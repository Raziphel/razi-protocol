---@diagnostic disable: missing-fields, need-check-nil, assign-type-mismatch, undefined-field, param-type-mismatch
package.path="./?.lua;./?/init.lua;"..package.path

local function check(condition,message)
  if not condition then error(message,2) end
end

local function clone(value)
  if type(value)~="table" then return value end
  local out={}
  for k,v in pairs(value) do out[clone(k)]=clone(v) end
  return out
end
rawset(table,"deepcopy",clone)

local rules={
  {name="razi-modded-moshine-zinc-silicon",
    source="silicon-cell",output="silicon-cell",
    base_amount=1,batch=4,bonus=1,
    imports={"zinc-solder"},native="silicon-cell"},
  {name="razi-modded-vesta-rare-earth-supermagnets",
    source="supermagnet",output="supermagnet",
    base_amount=1,batch=4,bonus=1,
    imports={"rare-earth-powder","optical-cable"},native="supermagnet"}
}

local function i(name,count)
  return {type="item",name=name,amount=count}
end
local function f(name,count)
  return {type="fluid",name=name,amount=count}
end
local function native(name,ingredients,product,amount,category,surface,byproducts)
  local results={i(product,amount)}
  for _,entry in ipairs(byproducts or {}) do
    results[#results+1]=entry
  end
  return {
    type="recipe",name=name,enabled=false,
    icon="__base__/graphics/icons/iron-plate.png",icon_size=64,
    categories={category}, energy_required=8,
    ingredients=ingredients,results=results,
    surface_conditions=surface, allow_productivity=true
  }
end
local function tech(unlock)
  return {name=unlock,icon="__base__/graphics/technology/automation.png",
    icon_size=256,prerequisites={},
    effects={{type="unlock-recipe",recipe=unlock}}}
end
local origins={
  "planet-discovery-paracelsin","planet-discovery-moshine",
  "planet-discovery-vesta","linox-technology_planet-discovery-linox"
}

-- Factorio 2.1: the base science packs are "item" prototypes, the system
-- tech cards are "tool" prototypes. Moshine's silicon is Krastorio's kr-silicon.
local function setup(opts)
  opts=opts or {}
  local items={}
  for _,name in ipairs({
    "zinc-plate","optical-cable","zinc-solder","silicon-cell",
    "kr-silicon","electronic-circuit","rare-earth-powder","stone",
    "supermagnet","copper-cable","holmium-plate","iridium-plate",
    "chemical-science-pack","production-science-pack","utility-science-pack"
  }) do
    items[name]={icon="__base__/graphics/icons/iron-plate.png",icon_size=64}
  end
  local fluid_set={["sulfuric-acid"]={},["electrolyte"]={}}
  local recipes={
    ["silicon-cell"]=native("silicon-cell",
      {i("kr-silicon",5),i("electronic-circuit",1)},
      "silicon-cell",1,"crafting"),
    ["linox-recipe_rare-earth-refining"]=native(
      "linox-recipe_rare-earth-refining",
      {i("stone",100),f("sulfuric-acid",200)},
      "rare-earth-powder",2,"chemistry",
      {{property="pressure",min=5000,max=5000}}),
    ["supermagnet"]=native("supermagnet",
      {f("electrolyte",1000),i("copper-cable",200),
        i("iridium-plate",5),i("holmium-plate",5)},
      "supermagnet",1,"electromagnetics",
      {{property="gasous_atmosphere",min=100,max=100}}),
    ["zinc-plate"]=native("zinc-plate",{i("stone",1)},
      "zinc-plate",1,"smelting"),
    ["zinc-solder"]=native("zinc-solder",{i("zinc-plate",4)},
      "zinc-solder",4,"hand-crafting"),
    ["optical-cable"]=native("optical-cable",{i("kr-silicon",1)},
      "optical-cable",2,"crafting")
  }
  local technologies={}
  for _,name in ipairs(origins) do
    technologies[name]={name=name,prerequisites={},
      icon="__base__/graphics/technology/automation.png",icon_size=256}
  end
  for name in pairs(recipes) do
    technologies["unlock-"..name]=tech(name)
  end
  local raw={
    item=items,fluid=fluid_set,recipe=recipes,technology=technologies,
    tool={["solaris-tech-card"]={},["nyxaris-tech-card"]={},
      ["vibrant-tech-card"]={},["vespera-tech-card"]={}},
    lab={lab={inputs={"solaris-tech-card","nyxaris-tech-card",
      "vibrant-tech-card","vespera-tech-card",
      "chemical-science-pack","production-science-pack",
      "utility-science-pack"}}},
    planet={
      moshine={surface_properties={pressure=701}},
      ["linox-planet_linox"]={surface_properties={pressure=5000}},
      vesta={surface_properties={gasous_atmosphere=100}}
    },
    ["assembling-machine"]={
      assembler={crafting_categories={"crafting","advanced-crafting"}},
      chemical_plant={crafting_categories={"chemistry"},
        fluid_boxes={{production_type="input"}}},
      electromagnetic_plant={crafting_categories={"electromagnetics"},
        fluid_boxes={{production_type="input"}}}
    }
  }
  local flags={
    ["Krastorio2-spaced-out"]="2.0.17",
    Paracelsin="1.10.2",Moshine="1.2.10",linox="1.8.9",
    ["skewer_planet_vesta"]="2.1.27"
  }
  if opts.without_mod then flags[opts.without_mod]=nil end
  if opts.without_item then items[opts.without_item]=nil end
  if opts.without_recipe then recipes[opts.without_recipe]=nil end
  if opts.without_arrival then technologies[opts.without_arrival]=nil end
  if opts.without_native_unlock then
    technologies["unlock-"..opts.without_native_unlock].effects={}
  end
  if opts.bad_vesta_machine then
    raw["assembling-machine"].electromagnetic_plant.fluid_boxes={}
  end
  rawset(_G,"data",{raw=raw,extend=function(self,prototypes)
    for _,proto in ipairs(prototypes) do
      self.raw[proto.type]=self.raw[proto.type] or {}
      check(not self.raw[proto.type][proto.name],"Duplicate exchange")
      self.raw[proto.type][proto.name]=proto
    end
  end})
  rawset(_G,"mods",flags)
  package.loaded["prototypes.compat.planet_production_exchanges"]=nil
  package.loaded["prototypes.compat.modded_planet_exchanges"]=nil
  return raw,require("prototypes.compat.modded_planet_exchanges")
end

local function amount_of(recipe,list_name,name)
  for _,entry in ipairs(recipe[list_name] or {}) do
    if entry.name==name then return entry.amount end
  end
  return nil
end
local portfolio=require("prototypes.compat.industry_portfolio")
local raw,mod=setup()
local original=clone(raw.recipe)
mod.data_final_fixes()
for _,rule in ipairs(rules) do
  local recipe,technology=raw.recipe[rule.name],raw.technology[rule.name]
  check(portfolio.keep(rule.name),"Exchange missing from the portfolio: "..rule.name)
  check(recipe and technology, "Curated planet exchange missing: "..rule.name)
  check(recipe.enabled==false and not recipe.auto_recycle,
    "Alternative cannot replace or auto-recycle the original")
  check(recipe.allow_productivity==false and recipe.maximum_productivity==0,
    "Bonus manufacturing must never stack free productivity")
  check(#technology.unit.ingredients==2,
    "Source planets' combined research is missing")
  check(amount_of(recipe,"results",rule.output)
    == rule.base_amount*rule.batch+rule.bonus,
    "Incorrect cross-world bonus output: "..rule.name)
  -- No exchange adds more than a quarter to its native batch.
  check(rule.bonus<=rule.base_amount*rule.batch*0.25,
    "Bonus above the 25% ceiling: "..rule.name)
  for _,ingredient in ipairs(rule.imports) do
    check(amount_of(recipe,"ingredients",ingredient)>0,
      "Imported modded planet product missing: "..ingredient)
    local supplier="unlock-"..ingredient
    if supplier=="unlock-rare-earth-powder" then
      supplier="unlock-linox-recipe_rare-earth-refining"
    end
    local needs=false
    for _,name in ipairs(rawget(technology,"prerequisites") or {}) do
      if name==supplier then needs=true end
    end
    check(needs,"Supplier native technology was skipped: "..rule.name)
  end
  local native_unlocked=false
  for _,name in ipairs(rawget(technology,"prerequisites") or {}) do
    if name=="unlock-"..rule.native then native_unlocked=true end
  end
  check(native_unlocked,"Native source research was bypassed: "..rule.name)
  check(original[rule.source].results[1].amount
    ==raw.recipe[rule.source].results[1].amount,
    "Source author's production output was modified: "..rule.source)
end
check(amount_of(raw.recipe["razi-modded-moshine-zinc-silicon"],
  "ingredients","kr-silicon")==18,
  "Imported zinc solder must conserve raw Moshine kr-silicon")
check(amount_of(raw.recipe["razi-modded-vesta-rare-earth-supermagnets"],
  "ingredients","holmium-plate")==18,
  "Rare-earth magnets must substitute some native holmium")
check(raw.recipe["razi-modded-vesta-rare-earth-supermagnets"]
  .surface_conditions[1].property=="gasous_atmosphere",
  "Vesta's atmosphere restriction was lost")
mod.data_final_fixes()

-- Moshine optical cable is gated by Fulgora science even if its native
-- technology has no explicit Vibrant ancestor. The exchange must inherit
-- the real late-tier research cost without requiring that pack again.
local optical,optical_engine=setup()
optical.technology["unlock-optical-cable"].unit={
  count=350,time=30,
  ingredients={{"electromagnetic-science-pack",1}}
}
optical_engine.data_final_fixes()
local optical_bridge=optical.technology["razi-modded-vesta-rare-earth-supermagnets"]
check(optical_bridge and optical_bridge.unit.count>=950,
  "Optical-cable supplier science must raise its Razi exchange to Vibrant-tier pricing")
local has_unlock=false
for _,tech_name in ipairs(optical_bridge.prerequisites or {}) do
  if tech_name=="unlock-optical-cable" then has_unlock=true end
end
check(has_unlock,
  "Vesta exchange must remain blocked until Fulgora-gated optics research")

-- A bonus above a quarter of the native batch is refused by the engine:
-- one extra magnet per three native ones would be +33%.
local third=setup()
local engine=require("prototypes.compat.planet_production_exchanges")
engine.register_additional({{
  name="razi-modded-vesta-rare-earth-supermagnets",
  source_mod="skewer_planet_vesta",source="supermagnet",
  required_mods={"skewer_planet_vesta","linox","Moshine"},
  product="supermagnet",category="electromagnetics",working_world="vesta",
  planets={"planet-discovery-vesta",
    "linox-technology_planet-discovery-linox","planet-discovery-moshine"},
  keep_native_category=true,
  supplier_recipes={
    {recipe="linox-recipe_rare-earth-refining",product="rare-earth-powder"},
    {recipe="optical-cable",product="optical-cable"}},
  science={"vibrant-tech-card","vespera-tech-card"},
  additional={{type="item",name="rare-earth-powder",amount=3},
    {type="item",name="optical-cable",amount=3}},
  batch=3,bonus=1,max_bonus_fraction=0.25,count=1450,time=60,
  bonus_icon="rare-earth-powder"
}})
check(not third.recipe["razi-modded-vesta-rare-earth-supermagnets"],
  "A 33% bonus must be rejected by the 25% ceiling")

local function absent(options,names)
  local state,bridge=setup(options)
  bridge.data_final_fixes()
  for _,name in ipairs(names) do
    check(not state.recipe[name] and not state.technology[name],
      "Broken source should fail closed: "..name)
  end
end
absent({without_mod="Moshine"},{
  "razi-modded-moshine-zinc-silicon",
  "razi-modded-vesta-rare-earth-supermagnets"})
absent({without_mod="Paracelsin"},{"razi-modded-moshine-zinc-silicon"})
absent({without_mod="linox"},{"razi-modded-vesta-rare-earth-supermagnets"})
absent({without_mod="skewer_planet_vesta"},
  {"razi-modded-vesta-rare-earth-supermagnets"})
absent({without_item="kr-silicon"},{"razi-modded-moshine-zinc-silicon"})
absent({without_arrival="linox-technology_planet-discovery-linox"},
  {"razi-modded-vesta-rare-earth-supermagnets"})
-- Shared ingredients/unlocks intentionally disable every affected exchange,
-- not just the first recipe in the catalogue.
local no_cable,missing_cable=setup({without_native_unlock="optical-cable"})
missing_cable.data_final_fixes()
check(not no_cable.recipe["razi-modded-vesta-rare-earth-supermagnets"],
  "A supplier whose native unlock is missing must block the exchange")
local no_vesta,magnet=setup({bad_vesta_machine=true})
magnet.data_final_fixes()
check(not no_vesta.recipe["razi-modded-vesta-rare-earth-supermagnets"],
  "Supermagnet manufacturing was registered without an electrolyte inlet")
local no_k2,k2=setup({without_mod="Krastorio2-spaced-out"})
k2.data_final_fixes()
for _,rule in ipairs(rules) do
  check(not no_k2.recipe[rule.name],"Modded exchange appeared without K2SO")
end

-- The second production toggle controls these cross-mod bridges
-- independently of the ordinary K2SO production option.
local off_raw, off_mod = setup()
rawset(_G, "settings", {startup={
  ["razi-enable-modded-planet-exchanges"] = {value = false},
  ["razi-enable-k2so-production-exchanges"] = {value = true}
}})
off_mod.data_final_fixes()
for _, rule in ipairs(rules) do
  check(not off_raw.recipe[rule.name] and not off_raw.technology[rule.name],
    "Disabled modded world production recipe still exists: " .. rule.name)
  check(off_raw.recipe[rule.source],
    "Native production disappeared after disabling bridge")
end
rawset(_G, "settings", nil)

local file=assert(io.open("data-final-fixes.lua","r"))
local loaded=file:read("*a")
file:close()
check(loaded:find(
  'require("prototypes.compat.modded_planet_exchanges").data_final_fixes()',1,true),
  "Cross-mod planet exchanges are not registered in data-final-fixes")
print("Two modded-planet industrial exchanges and fail-closed guards passed")
