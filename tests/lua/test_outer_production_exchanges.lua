---@diagnostic disable: missing-fields, need-check-nil, assign-type-mismatch, undefined-field
-- Guard optional outer-world supply exchanges against missing mods/recipes and
-- preserve all of the source authors' native production chains.
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
  if not ok then error(message, 2) end
end
local function clone(value)
  if type(value) ~= "table" then return value end
  local result = {}
  for key, item in pairs(value) do result[clone(key)] = clone(item) end
  return result
end
rawset(table, "deepcopy", clone)

local targets = {
  "razi-gleba-tenebris-biopolymer",
  "razi-linox-rare-earth-exchange",
  "razi-cubium-precious-metal-alloying",
  "razi-vesta-frontier-foundations"
}

local function item(name, n)
  return {type="item", name=name, amount=n}
end
local function fluid(name, n)
  return {type="fluid", name=name, amount=n}
end
local function recipe(name, inputs, results, category, conditions)
  return {
    type="recipe", name=name, icon="__base__/graphics/icons/iron-plate.png",
    icon_size=64, enabled=false, categories={category},
    ingredients=inputs, results=results, allow_productivity=true,
    surface_conditions=conditions
  }
end
local function technology(name, unlock)
  return {
    name=name, prerequisites={},
    icon="__base__/graphics/technology/automation.png", icon_size=256,
    effects=unlock and {{type="unlock-recipe", recipe=unlock}} or nil
  }
end
local function setup(options)
  options = options or {}
  local items = {}
  for _, name in ipairs({
    "chitin","plastic-bar","bioflux","stone","rare-earth-powder",
    "kr-rare-metals","holmium-plate","gold-ore","gold-plate",
    "iron-plate","ceramic","carbon","vesta-foundation",
    "bioluminescent-crystal"
  }) do
    items[name]={icon="__base__/graphics/icons/iron-plate.png", icon_size=64}
  end
  local recipes = {
    biopolymer=recipe("biopolymer", {item("chitin",1)},
      {item("plastic-bar",4)}, "organic",
      {{property="pressure", min=3000, max=3000}}),
    ["linox-recipe_rare-earth-refining"]=recipe(
      "linox-recipe_rare-earth-refining",
      {item("stone",100),fluid("sulfuric-acid",200)},
      {item("rare-earth-powder",2)}, "chemistry",
      {{property="pressure", min=5000, max=5000}}),
    ["gold-plate"]=recipe("gold-plate", {item("gold-ore",4)},
      {item("gold-plate",1)}, "metallurgy"),
    ["vesta-foundation"]=recipe("vesta-foundation",
      {fluid("vesta_nitrogen",1000),item("iron-plate",20),
       item("ceramic",10),item("carbon",10)},
      {item("vesta-foundation",10)}, "metallurgy")
  }
  local techs={}
  for _, name in ipairs({
    "planet-discovery-tenebris","planet-discovery-gleba",
    "planet-discovery-vulcanus","planet-discovery-fulgora",
    "planet-discovery-cubium","planet-discovery-secretas",
    "linox-technology_planet-discovery-linox",
    "planet-discovery-vesta","vibrant-discovery","vespera-discovery"
  }) do techs[name]=technology(name) end
  for _, pair in ipairs({
    {"tenebris-biopolymer","biopolymer"},
    {"linox-rare-earth-refining","linox-recipe_rare-earth-refining"},
    {"secretas-gold-processing","gold-plate"},
    {"vesta-foundation-tech","vesta-foundation"}
  }) do techs[pair[1]]=technology(pair[1],pair[2]) end
  local raw = {
    item=items, recipe=recipes,
    tool={["vibrant-tech-card"]={},["vespera-tech-card"]={}},
    fluid={["sulfuric-acid"]={},["vesta_nitrogen"]={}},
    technology=techs,
    lab={["kr-advanced-lab"]={inputs={"vibrant-tech-card",
      "vespera-tech-card"}}},
    planet={
      tenebris={surface_properties={pressure=3000}},
      ["linox-planet_linox"]={surface_properties={pressure=5000}},
      cubium={surface_properties={pressure=250}},
      vesta={surface_properties={gasous_atmosphere=100}}
    },
    ["assembling-machine"]={
      biochamber={crafting_categories={"organic"}},
      ["chemical-plant"]={crafting_categories={"chemistry"},
        fluid_boxes={{production_type="input"}}},
      foundry={crafting_categories={"metallurgy"},
        fluid_boxes={{production_type="input"}}}
    }
  }
  local enabled = {
    ["Krastorio2-spaced-out"]="2.0.17",
    ["tenebris-prime"]="1.3.12",
    linox="1.8.9",
    secretas="1.0.37",
    ["skewer_planet_vesta"]="2.1.27"
  }
  if options.disabled_mod then enabled[options.disabled_mod]=nil end
  if options.missing_item then items[options.missing_item]=nil end
  if options.missing_arrival then techs[options.missing_arrival]=nil end
  if options.missing_recipe then recipes[options.missing_recipe]=nil end
  if options.wrong_tenebris_pressure then
    raw.planet.tenebris.surface_properties.pressure=2000
  end
  if options.wrong_linox_pressure then
    raw.planet["linox-planet_linox"].surface_properties.pressure=3000
  end
  if options.missing_acid_port then
    raw["assembling-machine"]["chemical-plant"].fluid_boxes={}
  end
  if options.missing_vesta_port then
    raw["assembling-machine"].foundry.fluid_boxes={}
  end
  if options.native_unlock_missing then
    techs[options.native_unlock_missing].effects=nil
  end
  rawset(_G,"data",{raw=raw,extend=function(self,list)
    for _, prototype in ipairs(list) do
      local slot=self.raw[prototype.type] or {}
      self.raw[prototype.type]=slot
      check(not slot[prototype.name],"Duplicate outer-exchange prototype")
      slot[prototype.name]=prototype
    end
  end})
  rawset(_G,"mods",enabled)
  package.loaded["prototypes.compat.planet_production_exchanges"]=nil
  return raw,require("prototypes.compat.planet_production_exchanges")
end

local function product(recipe, wanted)
  for _, entry in ipairs(recipe.results or {}) do
    if entry.name==wanted then return entry.amount end
  end
end
local function ingredient(recipe, wanted)
  for _, entry in ipairs(recipe.ingredients or {}) do
    if entry.name==wanted then return entry.amount end
  end
end

local raw, exchange=setup()
local originals=clone(raw.recipe)
exchange.data_final_fixes()
for _, name in ipairs(targets) do
  local r,tech=raw.recipe[name],raw.technology[name]
  check(r and tech,"Missing guarded outer world production exchange: "..name)
  check(r.enabled==false and r.auto_recycle==false,
    "Optional exchange became a mandatory or recycling recipe")
  check(r.allow_productivity==false and r.maximum_productivity==0,
    "Cross-planet output bonus can be compounded by productivity")
  check(#r.icons>=1 and tech.icon,
    "Production exchange has no usable recipe or technology icon")
  check(#tech.unit.ingredients==2 and #tech.prerequisites>=3,
    "Outer exchange research is not tied to original planets")
  check(tech.effects[1].recipe==name,"Exchange unlock effect is missing")
end
check(product(raw.recipe[targets[1]],"plastic-bar")==10,
  "Gleba/Tenebris synergy must yield 10 from 8 original plastic")
check(ingredient(raw.recipe[targets[1]],"chitin")==2
  and ingredient(raw.recipe[targets[1]],"bioflux")==1,
  "Tenebris exchange bypasses chitin or omits Gleba's input")
check(raw.recipe[targets[1]].surface_conditions[1].property=="pressure",
  "Tenebris pressure restriction was lost")
check(product(raw.recipe[targets[2]],"rare-earth-powder")==5,
  "Linox refinement must yield five rare-earth powders from four")
check(ingredient(raw.recipe[targets[2]],"stone")==200
  and ingredient(raw.recipe[targets[2]],"sulfuric-acid")==400
  and ingredient(raw.recipe[targets[2]],"kr-rare-metals")==2,
  "Linox refinement dropped stone/acid or the K2SO import")
check(product(raw.recipe[targets[3]],"gold-plate")==5
  and ingredient(raw.recipe[targets[3]],"gold-ore")==16,
  "Cubium/Secretas synergy should output five gold plates from four batches")
check(ingredient(raw.recipe[targets[3]],"holmium-plate")==1,
  "Fulgora does not contribute to Cubium's gold processing")
check(product(raw.recipe[targets[4]],"vesta-foundation")==15,
  "Vesta's improved foundation yield is wrong")
check(ingredient(raw.recipe[targets[4]],"vesta_nitrogen")==1000
  and ingredient(raw.recipe[targets[4]],"bioluminescent-crystal")==2,
  "Vesta foundation lost original gas or Tenebris bioluminescence")
for _, original in ipairs({"biopolymer","linox-recipe_rare-earth-refining",
  "gold-plate","vesta-foundation"}) do
  check(product(raw.recipe[original],originals[original].results[1].name)
    ==product(originals[original],originals[original].results[1].name),
    "Native planet recipe changed: "..original)
end
exchange.data_final_fixes()
for _, name in ipairs(targets) do
  check(raw.recipe[name] and raw.technology[name],
    "Second pass broke exchange idempotence: "..name)
end

local function expected(option, absent)
  local fixture,mod=setup(option)
  mod.data_final_fixes()
  for _, name in ipairs(targets) do
    check((fixture.recipe[name]==nil)==(name==absent),
      "Unexpected exchange missing or created: "..name)
  end
end
expected({disabled_mod="tenebris-prime"},targets[1])
expected({disabled_mod="linox"},targets[2])
expected({disabled_mod="secretas"},targets[3])
expected({disabled_mod="skewer_planet_vesta"},targets[4])
expected({missing_item="bioflux"},targets[1])
expected({missing_item="rare-earth-powder"},targets[2])
expected({missing_item="gold-ore"},targets[3])
expected({missing_item="bioluminescent-crystal"},targets[4])
expected({missing_arrival="planet-discovery-secretas"},targets[3])
expected({missing_recipe="vesta-foundation"},targets[4])
expected({wrong_tenebris_pressure=true},targets[1])
expected({wrong_linox_pressure=true},targets[2])
expected({missing_acid_port=true},targets[2])
expected({missing_vesta_port=true},targets[4])
expected({native_unlock_missing="secretas-gold-processing"},targets[3])
print("Four outer-world production exchanges and fail-closed guards passed")
