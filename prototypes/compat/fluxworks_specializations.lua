-- Seven optional factory specializations, one per Razi star system.
-- These add technologies and recipes only; they never gate discovery, native
-- science cards, asteroid routes, or existing FluxWorks production.
local M = {}

local function item(name)
  return {type="item",name=name,amount=1}
end
local function ingredient(name,amount,kind)
  return {type=kind or "item",name=name,amount=amount}
end

local regions = {
  {
    system="calidus", world="nauvis", colour="yellow",
    base="fw-flux-stabilization", gate="space-science-pack",
    count=260, science={"automation-science-pack","logistic-science-pack","chemical-science-pack"},
    output="fw-metal-mesh", amount=5, category="fw-flux-synthesis", duration=9,
    inputs={
      ingredient("iron-plate",8), ingredient("copper-plate",10),
      ingredient("fw-crystalised-flux",2),ingredient("fw-yellow-flux",24,"fluid"),
    },
  },
  {
    system="solaris", world="vulcanus", colour="red",
    base="fw-vulcanus-industrial-symbiosis",gate="solaris-discovery",
    count=460,science={"chemical-science-pack","metallurgic-science-pack","solaris-tech-card"},
    output="fw-annealed-cermet",amount=4,category="fw-arc-smelting",duration=12,
    inputs={
      ingredient("fw-cermet",3),ingredient("tungsten-carbide",3),
      ingredient("fw-foundry-lining",1),ingredient("fw-red-flux",48,"fluid"),
    },
  },
  {
    system="nyxaris",world="gleba",colour="green",
    base="fw-gleba-regenerative-symbiosis",gate="nyxaris-discovery",
    count=500,science={"chemical-science-pack","agricultural-science-pack","nyxaris-tech-card"},
    output="fw-nutrient-bed",amount=5,category="fw-flux-synthesis",duration=13,
    inputs={
      ingredient("bioflux",2),ingredient("spoilage",20),
      ingredient("fw-inline-filter",2),ingredient("fw-green-flux",36,"fluid"),
    },
  },
  {
    system="vibrant",world="fulgora",colour="yellow",
    base="fw-fulgora-electromagnetic-symbiosis",gate="vibrant-discovery",
    count=650,science={"production-science-pack","electromagnetic-science-pack","vibrant-tech-card"},
    output="fw-resonance-substrate",amount=3,category="fw-flux-synthesis",duration=15,
    inputs={
      ingredient("superconductor",2),ingredient("holmium-plate",3),
      ingredient("fw-circuit-substrate",3),ingredient("fw-yellow-flux",55,"fluid"),
    },
  },
  {
    system="vespera",world="aquilo",colour="purple",
    base="fw-aquilo-thermal-symbiosis",gate="vespera-discovery",
    count=850,science={"production-science-pack","cryogenic-science-pack","vespera-tech-card"},
    output="fw-aquilo-cryogel",amount=4,category="fw-flux-synthesis",duration=19,
    inputs={
      ingredient("ice",12),ingredient("lithium-plate",4),
      ingredient("fluoroketone-cold",40,"fluid"),
      ingredient("fw-purple-flux",30,"fluid"),
    },
  },
  {
    system="beetlejuice",world="secretas",colour="purple",partner="yellow",
    base="fw-cross-planetary-industrial-convergence",gate="beetlejuice-discovery",
    arrival="planet-discovery-secretas",
    count=1250,science={"utility-science-pack","beetlejuice-tech-card"},
    output="fw-quantum-computer",amount=1,category="fw-flux-synthesis",duration=26,
    inputs={
      ingredient("gold-plate",2),ingredient("fw-logic-matrix",4),
      ingredient("fw-sensor-package",2),
      ingredient("fw-purple-flux",65,"fluid"),
      ingredient("fw-yellow-flux",35,"fluid"),
    },
  },
  {
    system="umbra",world="tenebris",colour="green",partner="purple",
    base="fw-flux-phase-engineering",gate="umbra-discovery",
    arrival="planet-discovery-tenebris",
    count=1350,science={"utility-science-pack","umbra-tech-card"},
    output="fw-flux-phase-manifold",amount=2,category="fw-flux-synthesis",duration=28,
    inputs={
      ingredient("chitosan",4),ingredient("fw-condensed-flux-matrix",3),
      ingredient("fw-resonance-substrate",4),
      ingredient("fw-purple-flux",60,"fluid"),
      ingredient("fw-green-flux",50,"fluid"),
    },
  },
}

local function prototype_item(name)
  for _,kind in ipairs({"item","tool","module","capsule"}) do
    local found=data.raw[kind] and data.raw[kind][name]
    if found then return found end
  end
end

local function valid(spec)
  local techs=data.raw.technology or {}
  local categories=data.raw["recipe-category"] or {}
  if not (prototype_item(spec.output) and techs[spec.base] and techs[spec.gate]
    and categories[spec.category]) then return false end
  if spec.arrival and not techs[spec.arrival] then return false end
  for _,pack in ipairs(spec.science) do
    if not prototype_item(pack) then return false end
  end
  local fluids=0
  for _,v in ipairs(spec.inputs) do
    if v.type=="fluid" then
      if not (data.raw.fluid and data.raw.fluid[v.name]) then return false end
      fluids=fluids+1
    elseif not prototype_item(v.name) then
      -- K2SO can replace Space Age's lithium-plate with kr-lithium.
      if not (v.name=="lithium-plate" and prototype_item("kr-lithium")) then
        return false
      end
    end
  end
  -- Keep these optional recipes approachable: three component lanes
  -- and two fluids at most, without disturbing native source-mod recipes.
  return fluids<=2 and #spec.inputs<=5
end

local function icons(product,colour,partner)
  local layers
  if product.icons then layers=table.deepcopy(product.icons)
  elseif product.icon then
    layers={{icon=product.icon,icon_size=product.icon_size or 64}}
  else return end
  local function overlay(spectrum,x)
    layers[#layers+1]={
      icon="__FluxWorksAssets__/graphics/icons/fluids/flux-"..spectrum..".png",
      icon_size=256,scale=0.075,shift={x,16}
    }
  end
  overlay(colour,partner and -14 or 15)
  if partner then overlay(partner,14) end
  return layers
end

local function tech_recipe(spec,index)
  local product=prototype_item(spec.output)
  local picture=icons(product,spec.colour,spec.partner)
  if not picture then return end

  local tech_name="razi-fw-"..spec.system.."-industry"
  local recipe_name="razi-fw-"..spec.system.."-specialty"
  if not data.raw.recipe[recipe_name] then
    local recipe={
      type="recipe",name=recipe_name,icons=table.deepcopy(picture),
      localised_name={"recipe-name."..recipe_name},
      localised_description={"recipe-description."..recipe_name},
      subgroup=product.subgroup or "intermediate-product",
      order=("zz[razi-fw-specialty]-%02d"):format(index),
      category=spec.category,enabled=false,auto_recycle=false,
      allow_productivity=false,energy_required=spec.duration,
      ingredients=table.deepcopy(spec.inputs),
      results={{type="item",name=spec.output,amount=spec.amount}},
      main_product=spec.output,
    }
    for _,entry in ipairs(recipe.ingredients) do
      if entry.name=="lithium-plate" and not prototype_item("lithium-plate")
        and prototype_item("kr-lithium") then
        entry.name="kr-lithium"
      end
    end
    data:extend({recipe})
  end
  if not data.raw.technology[tech_name] then
    local prerequisites={spec.gate,spec.base}
    if spec.arrival then prerequisites[#prerequisites+1]=spec.arrival end
    local science={}
    for _,name in ipairs(spec.science) do science[#science+1]={name,1} end
    local tech={
      type="technology",name=tech_name,icons=table.deepcopy(picture),
      localised_name={"technology-name."..tech_name},
      localised_description={"technology-description."..tech_name},
      prerequisites=prerequisites,
      unit={count=spec.count,time=45,ingredients=science},
      effects={{type="unlock-recipe",recipe=recipe_name}},
      order=("zz[razi-fw-industry]-%02d"):format(index),
    }
    data:extend({tech})
  end
  return tech_name
end

function M.data_final_fixes()
  if not (mods and mods["FluxWorks"]) then return 0 end
  local added=0
  for index,spec in ipairs(regions) do
    if valid(spec) then
      if tech_recipe(spec,index) then added=added+1 end
    else
      log("Razi FluxWorks: skipped optional "..spec.system.." specialization; missing source prototype")
    end
  end
  log("Razi FluxWorks: "..added.." optional planetary specializations available")
  return added
end

return M
