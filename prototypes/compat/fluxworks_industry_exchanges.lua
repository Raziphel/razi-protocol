-- Optional inter-system workshops. Import materials from two established
-- industrial specializations and receive a useful alternative production line.
-- The extra research is never a prerequisite for a Razi campaign or planet gate.
local M = {}

local function part(name,amount,kind)
  return {type=kind or "item",name=name,amount=amount}
end

local exchanges={
  {
    id="calidus-solaris",first="calidus",second="solaris",
    world="vulcanus",colour="red",partner="yellow",
    category="fw-arc-smelting",product="low-density-structure",
    amount=4,time=14,count=340,
    science={"chemical-science-pack","solaris-tech-card"},
    inputs={
      part("fw-metal-mesh",3),part("fw-annealed-cermet",2),
      part("copper-plate",12),part("fw-red-flux",30,"fluid")
    },
  },
  {
    id="nyxaris-vibrant",first="nyxaris",second="vibrant",
    world="fulgora",colour="green",partner="yellow",
    category="fw-flux-synthesis",product="processing-unit",
    amount=5,time=16,count=560,
    science={"utility-science-pack","vibrant-tech-card"},
    inputs={
      part("fw-nutrient-bed",2),part("fw-resonance-substrate",2),
      part("superconductor",1),
      part("fw-green-flux",25,"fluid"),part("fw-yellow-flux",25,"fluid")
    },
  },
  {
    id="solaris-vespera",first="solaris",second="vespera",
    world="aquilo",colour="red",partner="purple",
    category="fw-flux-synthesis",product="fw-thermal-buffer",
    amount=5,time=18,count=680,
    science={"production-science-pack","vespera-tech-card"},
    inputs={
      part("fw-annealed-cermet",2),part("fw-aquilo-cryogel",2),
      part("fw-cermet",2),
      part("fw-red-flux",25,"fluid"),part("fw-purple-flux",25,"fluid")
    },
  },
  {
    id="vibrant-beetlejuice",first="vibrant",second="beetlejuice",
    world="secretas",colour="yellow",partner="purple",
    category="fw-flux-synthesis",product="fw-flux-resonance-cell",
    amount=5,time=24,count=930,
    science={"utility-science-pack","beetlejuice-tech-card"},
    inputs={
      part("fw-resonance-substrate",3),part("fw-quantum-computer",1),
      part("fw-stabilized-flux-crystal",3),
      part("fw-yellow-flux",40,"fluid"),part("fw-purple-flux",35,"fluid")
    },
  },
  {
    id="nyxaris-umbra",first="nyxaris",second="umbra",
    world="tenebris",colour="green",partner="purple",
    category="fw-flux-synthesis",product="fw-rift-stabilizer",
    amount=2,time=26,count=1000,
    science={"utility-science-pack","umbra-tech-card"},
    inputs={
      part("fw-nutrient-bed",2),part("fw-flux-phase-manifold",1),
      part("chitosan",2),
      part("fw-green-flux",40,"fluid"),part("fw-purple-flux",40,"fluid")
    },
  },
}

local function item(name)
  for _,kind in ipairs({"item","tool","module","capsule"}) do
    local entry=data.raw[kind] and data.raw[kind][name]
    if entry then return entry end
  end
end

local function can_add(spec)
  local techs=data.raw.technology or {}
  if not (techs["razi-fw-"..spec.first.."-industry"]
    and techs["razi-fw-"..spec.second.."-industry"]
    and item(spec.product)
    and data.raw["recipe-category"]
    and data.raw["recipe-category"][spec.category]) then
    return false
  end
  for _,name in ipairs(spec.science) do
    if not item(name) then return false end
  end
  local fluids=0
  for _,entry in ipairs(spec.inputs) do
    if entry.type=="fluid" then
      fluids=fluids+1
      if not (data.raw.fluid and data.raw.fluid[entry.name]) then return false end
    elseif not item(entry.name) then
      return false
    end
  end
  return fluids<=2 and #spec.inputs<=6
end

local function picture(product,colour,partner)
  local icons
  if product.icons then
    icons=table.deepcopy(product.icons)
  elseif product.icon then
    icons={{icon=product.icon,icon_size=product.icon_size or 64}}
  else
    return
  end
  for _,entry in ipairs({{colour,-13},{partner,13}}) do
    icons[#icons+1]={
      icon="__FluxWorksAssets__/graphics/icons/fluids/flux-"..entry[1]..".png",
      icon_size=256,scale=0.072,shift={entry[2],16},
    }
  end
  return icons
end

local function register(spec,index)
  local name="razi-fw-"..spec.id.."-exchange"
  local recipe_name="razi-fw-"..spec.id.."-assembly"
  local icons=picture(item(spec.product),spec.colour,spec.partner)
  if not icons then return false end

  if not data.raw.recipe[recipe_name] then
    data:extend({{
      type="recipe",name=recipe_name,icons=table.deepcopy(icons),
      localised_name={"recipe-name."..recipe_name},
      localised_description={"recipe-description."..recipe_name},
      category=spec.category,enabled=false,auto_recycle=false,
      allow_productivity=false,
      subgroup=item(spec.product).subgroup or "intermediate-product",
      order=("zz[fw-regional-exchange]-%02d"):format(index),
      energy_required=spec.time,
      ingredients=table.deepcopy(spec.inputs),
      results={{type="item",name=spec.product,amount=spec.amount}},
      main_product=spec.product,
    }})
  end

  if not data.raw.technology[name] then
    local costs={}
    for _,pack in ipairs(spec.science) do
      costs[#costs+1]={pack,1}
    end
    data:extend({{
      type="technology",name=name,icons=table.deepcopy(icons),
      localised_name={"technology-name."..name},
      localised_description={"technology-description."..name},
      prerequisites={
        "razi-fw-"..spec.first.."-industry",
        "razi-fw-"..spec.second.."-industry",
      },
      unit={count=spec.count,time=45,ingredients=costs},
      effects={{type="unlock-recipe",recipe=recipe_name}},
      order=("zz[fw-regional-exchange]-%02d"):format(index),
    }})
  end
  return true
end

function M.data_final_fixes()
  if not (mods and mods["FluxWorks"]) then return 0 end
  local added=0
  for index,spec in ipairs(exchanges) do
    if can_add(spec) and register(spec,index) then
      added=added+1
    else
      log("Razi FluxWorks: skipping optional exchange "..spec.id)
    end
  end
  log("Razi FluxWorks: "..added.." optional regional exchanges ready")
  return added
end

return M
