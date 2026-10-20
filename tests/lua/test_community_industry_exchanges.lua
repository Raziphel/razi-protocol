---@diagnostic disable: missing-fields, need-check-nil, assign-type-mismatch
package.path="./?.lua;./?/init.lua;"..package.path

local function check(ok, reason)
  if not ok then error(reason, 2) end
end
local function clone(obj)
  if type(obj)~="table" then return obj end
  local next_obj={}
  for key,val in pairs(obj) do next_obj[clone(key)]=clone(val) end
  return next_obj
end
rawset(table,"deepcopy",clone)
local function item(name,n)
  return {type="item",name=name,amount=n}
end
local function fluid(name,n)
  return {type="fluid",name=name,amount=n}
end
local function recipe(name,category,inputs,results,conditions)
  return {type="recipe",name=name,enabled=false,
    categories={category},energy_required=5,
    ingredients=inputs,results=results,
    surface_conditions=conditions,allow_productivity=true}
end

local names={
  "razi-ferrum-linox-optical-magnets",
  "razi-balack-rubia-chitosan-shielding"
}
local bases={
  "ferrum-rare-earth-magnet",
  "bm-radiation-sheilding"
}

local function fixture(opts)
  opts=opts or {}
  local available={}
  for _,name in ipairs({
    "ferrum-rare-earth-oxide","ferrum-rare-earth-magnet",
    "rare-earth-powder","stone","optical-cable",
    "low-density-structure","lithium-plate",
    "quantum-processor","supercapacitor","bm-mixed-gas-power-cell",
    "bm-radiation-sheilding","tungsten-carbide","carbon-fiber",
    "promethium-asteroid-chunk","bioflux","craptonite-frame","chitosan",
    "copper-cable","chitin","plastic-bar"
  }) do
    available[name]={icon="__base__/graphics/icons/iron-plate.png",
      icon_size=64}
  end
  local recipes={
    ["ferrum-rare-earth-magnet"]=recipe("ferrum-rare-earth-magnet",
      "metallurgy",{
        item("ferrum-rare-earth-oxide",5),
        fluid("electrolyte",10),fluid("molten-iron",20)},
      {item("ferrum-rare-earth-magnet",1)}),
    ["bm-radiation-sheilding"]=recipe("bm-radiation-sheilding",
      "bm-bio-cube",{
        item("tungsten-carbide",5),item("carbon-fiber",10),
        item("low-density-structure",1),
        item("promethium-asteroid-chunk",1),
        item("bioflux",5),fluid("heavy-oil",10)},
      {item("bm-radiation-sheilding",5)}),
    ["linox-recipe_rare-earth-refining"]=recipe(
      "linox-recipe_rare-earth-refining","chemistry",
      {item("stone",100),fluid("sulfuric-acid",200)},
      {item("rare-earth-powder",2)}),
    ["optical-cable"]=recipe("optical-cable","crafting",
      {item("copper-cable",2)},{item("optical-cable",2)}),
    ["craptonite-casting"]=recipe("craptonite-casting","organic",
      {item("stone",10)},{item("craptonite-frame",1)}),
    ["chitosan"]=recipe("chitosan","chemistry",
      {item("chitin",8),fluid("sulfuric-acid",50)},
      {item("chitosan",4)})
  }
  -- Native unlock for Ferrum magnets and Balack shielding
  -- are real technology IDs, not convenient synthetic names.
  local unlocks={
    ["ferrum-rare-earth-processing"]="ferrum-rare-earth-magnet",
    ["bm-planet-discovery-balack"]="bm-radiation-sheilding",
    ["linox-refining"]="linox-recipe_rare-earth-refining",
    ["moshine-optics"]="optical-cable",
    ["rubia-casting"]="craptonite-casting",
    ["tenebris-chitosan"]="chitosan"
  }
  local technologies={}
  for name,output in pairs(unlocks) do
    technologies[name]={name=name,prerequisites={},
      icon="__base__/graphics/technology/automation.png",icon_size=256,
      effects={{type="unlock-recipe",recipe=output}}}
  end
  for _,name in ipairs({
    "planet-discovery-ferrum","linox-technology_planet-discovery-linox",
    "planet-discovery-moshine",
    "planet-discovery-rubia","planet-discovery-tenebris"}) do
    technologies[name]=technologies[name] or {
      name=name,prerequisites={},
      icon="__base__/graphics/technology/automation.png",icon_size=256}
  end
  local planets={
    ferrum={surface_properties={pressure=2000,["ferrum-habitability"]=100}},
    ["bm-balack"]={surface_properties={pressure=1500}}
  }
  local machine={
    foundry={crafting_categories={"metallurgy"},
      fluid_boxes={{production_type="input"},{production_type="input"}}},
    ["electromagnetic-plant"]={
      crafting_categories={"electromagnetics"}},
    ["bm-bio-cube"]={crafting_categories={"bm-bio-cube"},
      fluid_boxes={{production_type="input"}}}
  }
  local loaded={
    ["Krastorio2-spaced-out"]="2.0.17",
    ["planet-ferrum"]="0.1.4",linox="1.8.9",
    Moshine="1.2.10",
    ["biological-machines-planet-balack"]="1.1.2",
    rubia="0.69.159",["tenebris-prime"]="1.3.12"
  }
  if opts.mod then loaded[opts.mod]=nil end
  if opts.ingredient then available[opts.ingredient]=nil end
  if opts.native_recipe then recipes[opts.native_recipe]=nil end
  if opts.native_unlock then
    technologies[opts.native_unlock].effects=nil
  end
  if opts.native_disabled then
    technologies[opts.native_disabled].enabled=false
  end
  if opts.homeworld then planets[opts.homeworld]=nil end
  if opts.fluid_ports then
    machine[opts.fluid_ports].fluid_boxes={}
  end
  if opts.wrong_category then
    recipes[opts.wrong_category].categories={"unsafe-only"}
  end
  local raw={
    item=available,fluid={electrolyte={},["molten-iron"]={},
      ["heavy-oil"]={},["sulfuric-acid"]={}},
    recipe=recipes,technology=technologies,
    planet=planets,["assembling-machine"]=machine,
    tool={["vibrant-tech-card"]={},["vespera-tech-card"]={}},
    lab={advanced={inputs={"vibrant-tech-card","vespera-tech-card"}}}
  }
  rawset(_G,"data",{raw=raw,extend=function(_,protos)
    for _,proto in ipairs(protos) do
      check(not raw[proto.type][proto.name],"Duplicate community exchange")
      raw[proto.type][proto.name]=proto
    end
  end})
  rawset(_G,"mods",loaded)
  rawset(_G,"settings",opts.off and {startup={
    ["razi-enable-modded-planet-exchanges"]={value=false}
  }} or nil)
  package.loaded["prototypes.compat.planet_production_exchanges"]=nil
  package.loaded["prototypes.compat.community_industry_exchanges"]=nil
  return raw,require("prototypes.compat.community_industry_exchanges")
end
local function amount(parts,name)
  for _,part in ipairs(parts or {}) do
    if part.name==name then return part.amount end
  end
end
-- Ferrum and Balack remain independent third-party industries. Their Razi
-- bonus variants duplicate existing routes and are no longer in the small
-- Balanced/Deep cargo portfolio.
local portfolio=require("prototypes.compat.industry_portfolio")
for _,name in ipairs(names) do
  check(not portfolio.keep(name),
    "Ferrum/Balack duplication should stay out of curated freight")
end
local raw,engine=fixture()
local before={}
for _,name in ipairs(bases) do before[name]=clone(raw.recipe[name]) end
engine.data_final_fixes()
for _,name in ipairs(names) do
  check(not raw.recipe[name] and not raw.technology[name],
    "Retired bonus variant must not appear: "..name)
end
for _,name in ipairs(bases) do
  local now=raw.recipe[name]
  check(now and now.results[1].amount==before[name].results[1].amount,
    "Original source output changed when retiring optional freight")
  check(#now.ingredients==#before[name].ingredients,
    "Original source materials changed when retiring optional freight")
end
-- Native source mods still load independently; absent modules cannot
-- resurrect removed Razi alternatives.
for _,options in ipairs({
  {off=true},{mod="planet-ferrum"},{mod="Moshine"},
  {mod="biological-machines-planet-balack"},{mod="rubia"},
  {ingredient="chitosan"},{ingredient="rare-earth-powder"}
}) do
  local state,m=fixture(options)
  m.data_final_fixes()
  for _,name in ipairs(names) do
    check(not state.recipe[name] and not state.technology[name],
      "Retired optional exchange resurrected: "..name)
  end
end
local f=assert(io.open("data-final-fixes.lua","r"))
local entry=f:read("*a");f:close()
check(entry:find(
  'require("prototypes.compat.community_industry_exchanges").data_final_fixes()',1,true),
  "Compatibility entrypoint must remain for modpack stability")
print("Community freight: duplicate alternatives retired without changing source industries")
