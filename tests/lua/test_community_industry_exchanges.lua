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
local raw,engine=fixture()
local before={}
for _,name in ipairs(bases) do before[name]=clone(raw.recipe[name]) end
engine.data_final_fixes()
local specs={
  {name=names[1],native=bases[1],output="ferrum-rare-earth-magnet",
    original=1,batch=3,bonus=1,inputs={"rare-earth-powder","optical-cable"},
    prerequisite="ferrum-rare-earth-processing",fluids=2},
  {name=names[2],native=bases[2],output="bm-radiation-sheilding",
    original=5,batch=2,bonus=2,
    inputs={"craptonite-frame","chitosan"},
    prerequisite="bm-planet-discovery-balack",fluids=1}
}
for _,spec in ipairs(specs) do
  local r,t=raw.recipe[spec.name],raw.technology[spec.name]
  check(r and t,"Community production exchange missing: "..spec.name)
  check(r.enabled==false and rawget(r,"auto_recycle")==false,
    "Bonus recipe must not replace native production")
  check(r.allow_productivity==false and rawget(r,"maximum_productivity")==0,
    "Trade bonus cannot stack with productivity")
  check(amount(r.results,spec.output)==spec.original*spec.batch+spec.bonus,
    "Incorrect trade output yield: "..spec.name)
  local unit=rawget(t,"unit") or {}
  local packs=rawget(unit,"ingredients") or {}
  local prerequisites=rawget(t,"prerequisites") or {}
  check(#packs==2 and #prerequisites>=3,
    "Trade exchange has bypassed research: "..spec.name)
  local original_unlock=false
  for _,prereq in ipairs(rawget(t,"prerequisites") or {}) do
    if prereq==spec.prerequisite then original_unlock=true end
  end
  check(original_unlock,"Native research was skipped: "..spec.name)
  for _,name in ipairs(spec.inputs) do
    check((amount(r.ingredients,name) or 0)>0,
      "Supplier ingredient missing: "..name)
  end
end
-- Native Ferrum chemistry and Balack promethium
-- are always scaled with the original base recipe rather than replaced.
check(amount(raw.recipe[names[1]].ingredients,"electrolyte")==30
  and amount(raw.recipe[names[1]].ingredients,"molten-iron")==60,
  "Ferrum native chemistry was shortcut")
check(amount(raw.recipe[names[2]].ingredients,"promethium-asteroid-chunk")==2
  and amount(raw.recipe[names[2]].ingredients,"heavy-oil")==20,
  "Balack native promethium and oil costs were bypassed")
for _,name in ipairs(bases) do
  check(amount(raw.recipe[name].results,before[name].results[1].name)
    ==before[name].results[1].amount,
    "Native recipe changed during import exchange")
end
engine.data_final_fixes()
local function absent(opts,without)
  local state,m=fixture(opts)
  m.data_final_fixes()
  for _,name in ipairs(without) do
    check(not state.recipe[name] and not state.technology[name],
      "Missing prerequisite still advertised alternate: "..name)
  end
end
absent({off=true},names)
absent({mod="planet-ferrum"},{names[1]})
absent({mod="Moshine"},{names[1]})
absent({mod="biological-machines-planet-balack"},{names[2]})
absent({mod="rubia"},{names[2]})
absent({ingredient="chitosan"},{names[2]})
absent({ingredient="rare-earth-powder"},{names[1]})
absent({native_recipe="ferrum-rare-earth-magnet"},{names[1]})
absent({native_unlock="ferrum-rare-earth-processing"},{names[1]})
absent({homeworld="bm-balack"},{names[2]})
absent({fluid_ports="foundry"},{names[1]})
absent({fluid_ports="bm-bio-cube"},{names[2]})
absent({wrong_category="bm-radiation-sheilding"},{names[2]})
local f=assert(io.open("data-final-fixes.lua","r"))
local entry=f:read("*a") f:close()
local established=assert(entry:find(
  'require("prototypes.compat.modded_planet_exchanges").data_final_fixes()',1,true))
local expanded=assert(entry:find(
  'require("prototypes.compat.community_industry_exchanges").data_final_fixes()',1,true))
check(established<expanded,"Community exchanges should follow modded production setup")
print("Ferrum and Balack optional industry exchanges passed")
