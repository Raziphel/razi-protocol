-- Components assembled from several planetary supply chains.
-- Skip registration when a material, machine or research unlock is missing.
local M={}
local mode=require("prototypes.compat.interdependence_mode")
local portfolio=require("prototypes.compat.industry_portfolio")
local factory=require("prototypes.compat.planet_production_exchanges")
local function raw(kind,id) return (data.raw[kind] or {})[id] end
local function entry_name(entry) return entry.name or entry[1] end
local function item(id)
  for _,kind in ipairs({"item","tool","module","ammo","capsule"}) do
    local obj=raw(kind,id)
    if obj and not obj.hidden then return obj end
  end
end
local function valid(entry)
  if (entry.type or "item")=="fluid" then
    local fluid=raw("fluid",entry_name(entry))
    return fluid and not fluid.hidden
  end
  return item(entry_name(entry))
end
local function produced(recipe,id)
  if not recipe then return false end
  if recipe.result==id then return true end
  for _,product in ipairs(recipe.results or {}) do
    if entry_name(product)==id and product.type~="fluid" then return true end
  end
  return false
end
local function unlock_index()
  local index={}
  for name,tech in pairs(data.raw.technology or {}) do
    if tech.enabled~=false and not tech.hidden then
      for _,effect in ipairs(tech.effects or {}) do
        if effect.type=="unlock-recipe" and effect.recipe then
          local list=index[effect.recipe] or {}
          list[#list+1]=name
          index[effect.recipe]=list
        end
      end
    end
  end
  for _,list in pairs(index) do table.sort(list) end
  return index
end
local function source_unlock(recipe_name,index)
  local recipe=raw("recipe",recipe_name)
  if not recipe or recipe.hidden then return nil end
  if recipe.enabled~=false then return true end
  return (index[recipe_name] or {})[1]
end
local function usable_supplier(source,index)
  if not item(source.product) then return nil end
  local recipe=raw("recipe",source.recipe)
  if not recipe or recipe.hidden or not produced(recipe,source.product)
    then return nil end
  for _,ingredient in ipairs(recipe.ingredients or {}) do
    if not valid(ingredient) then return nil end
  end
  return source_unlock(source.recipe,index)
end
local function lab_supports(science)
  for _,lab in pairs(data.raw.lab or {}) do
    local seen={}
    for _,pack in ipairs(lab.inputs or {}) do seen[pack]=true end
    local works=true
    for _,pack in ipairs(science) do
      if not seen[pack] then works=false break end
    end
    if works then return true end
  end
  return false
end
local function assembler_exists()
  for _,machine in pairs(data.raw["assembling-machine"] or {}) do
    if not machine.fixed_recipe then
      for _,category in ipairs(machine.crafting_categories or {}) do
        if category=="crafting" then return true end
      end
    end
  end
  return false
end
local function unique(list)
  local seen,result={},{}
  for _,id in ipairs(list) do
    if type(id)=="string" and not seen[id] then
      seen[id]=true; result[#result+1]=id
    end
  end
  return result
end
local function icon_layers(source)
  if source.icons then return table.deepcopy(source.icons) end
  if source.icon then
    return {{icon=source.icon,icon_size=source.icon_size or 64}}
  end
end
local parts={
  {
    name="razi-network-precision-matrix",
    source_icon="holmium-plate",accent_icon="optical-cable",
    required_mods={"Moshine","Paracelsin"},
    ingredients={
      {type="item",name="optical-cable",amount=3},
      {type="item",name="zinc-plate",amount=2},
      {type="item",name="holmium-plate",amount=1},
      {type="item",name="kr-rare-metals",amount=2}
    },
    suppliers={
      {recipe="optical-cable",product="optical-cable"},
      {recipe="zinc-plate",product="zinc-plate"},
      {recipe="holmium-plate",product="holmium-plate"},
      {recipe="kr-casting-rare-metals",product="kr-rare-metals"}
    },
    planets={
      "planet-discovery-vulcanus","planet-discovery-moshine",
      "planet-discovery-fulgora","planet-discovery-paracelsin"
    },
    science={"solaris-tech-card","nyxaris-tech-card"},
    count=420,energy=8,output=2
  },
  {
    name="razi-network-extreme-lattice",
    source_icon="craptonite-frame",accent_icon="chitosan",
    required_mods={"rubia","tenebris-prime","linox"},
    ingredients={
      {type="item",name="razi-network-precision-matrix",amount=1},
      {type="item",name="craptonite-frame",amount=2},
      {type="item",name="chitosan",amount=2},
      {type="item",name="rare-earth-powder",amount=2},
      {type="item",name="carbon-fiber",amount=2}
    },
    suppliers={
      {recipe="razi-network-precision-matrix",product="razi-network-precision-matrix"},
      {recipe="craptonite-casting",product="craptonite-frame"},
      {recipe="chitosan",product="chitosan"},
      {recipe="linox-recipe_rare-earth-refining",product="rare-earth-powder"},
      {recipe="carbon-fiber",product="carbon-fiber"}
    },
    planets={
      "planet-discovery-rubia","planet-discovery-tenebris",
      "linox-technology_planet-discovery-linox","planet-discovery-gleba"
    },
    science={"vibrant-tech-card","vespera-tech-card"},
    count=680,energy=12,output=2
  },
  {
    name="razi-network-panglia-optic-bond",
    source_icon="panglia_panglite_glass",accent_icon="optical-cable",
    required_mods={"panglia_planet","Moshine"},
    ingredients={
      {type="item",name="panglia_panglite_glass",amount=2},
      {type="item",name="optical-cable",amount=2},
      {type="item",name="holmium-plate",amount=1}
    },
    suppliers={
      {recipe="panglia_panglite_glass",product="panglia_panglite_glass"},
      {recipe="optical-cable",product="optical-cable"},
      {recipe="holmium-plate",product="holmium-plate"}
    },
    planets={"panglia_planet_discovery_panglia",
      "planet-discovery-moshine","planet-discovery-fulgora"},
    science={"solaris-tech-card","nyxaris-tech-card"},
    -- Eight bonds amortise the three imported materials over four
    -- boosted native batches instead of spending one glass per bonus.
    count=360,energy=10,output=8
  },
  {
    -- This is a late framework built from completed planetary industries.
    -- No unstable hydrogen plates or altered Crucible production loops.
    name="razi-network-umbra-pressure-frame",
    source_icon="supermagnet",accent_icon="holmium-plate",
    required_mods={"planet-crucible","skewer_planet_vesta",
      "linox","panglia_planet"},
    ingredients={
      {type="item",name="razi-network-panglia-optic-bond",amount=1},
      {type="item",name="holmium-plate",amount=2},
      {type="item",name="supermagnet",amount=2},
      {type="item",name="rare-earth-powder",amount=2}
    },
    suppliers={
      {recipe="razi-network-panglia-optic-bond",
        product="razi-network-panglia-optic-bond"},
      {recipe="holmium-plate",product="holmium-plate"},
      {recipe="supermagnet",product="supermagnet"},
      {recipe="linox-recipe_rare-earth-refining",product="rare-earth-powder"}
    },
    planets={"panglia_planet_discovery_panglia",
      "linox-technology_planet-discovery-linox",
      "planet-discovery-crucible","planet-discovery-vesta",
      "planet-discovery-fulgora"},
    science={"beetlejuice-tech-card","umbra-tech-card"},
    -- Fully material-driven late framework. The source Crucible milestone
    -- remains a gate, but no science pack is consumed as machine feedstock.
    -- Keep it available in Balanced as a real fourth network component.
    count=980,energy=20,output=8
  }
}
M.parts=parts
local function enabled(name)
  local setting=settings and settings.startup and settings.startup[name]
  return not setting or setting.value~=false
end
local function register_part(part,index)
  if part.deep_only and not mode.deep() then return false end
  for _,mod_name in ipairs(part.required_mods or {}) do
    if not (mods and mods[mod_name]) then return false end
  end
  if raw("item",part.name) or raw("recipe",part.name)
    or raw("technology",part.name) then return false end
  if not assembler_exists() then return false end
  local science=portfolio.science(part)
  if not lab_supports(science) then return false end
  for _,pack in ipairs(science) do
    if not raw("tool",pack) then return false end
  end
  for _,planet in ipairs(part.planets) do
    local t=raw("technology",planet)
    if not t or t.enabled==false or t.hidden then return false end
  end
  for _,ingredient in ipairs(part.ingredients) do
    if not valid(ingredient) then return false end
  end
  local source=item(part.source_icon)
  local icons=source and icon_layers(source)
  if not (icons and #icons>0) then return false end
  -- Layer two existing source-item icons for a distinctive hybrid product,
  -- without adding sprites or needing an asset bundle dependency.
  local badge=item(part.accent_icon)
  local badge_layers=badge and icon_layers(badge)
  local marker=badge_layers and badge_layers[1]
  if marker and marker.icon then
    local size=marker.icon_size or 64
    icons[#icons+1]={icon=marker.icon,icon_size=size,
      scale=0.25*64/size,shift={8,8}}
  end
  local prerequisites={}
  for _,name in ipairs(part.planets) do prerequisites[#prerequisites+1]=name end
  for _,supplier in ipairs(part.suppliers) do
    local unlock=usable_supplier(supplier,index)
    if not unlock then return false end
    if type(unlock)=="string" then
      prerequisites[#prerequisites+1]=unlock
    end
  end
  prerequisites=unique(prerequisites)
  local object={
    type="item",name=part.name,icons=table.deepcopy(icons),
    subgroup="intermediate-product",order="z[razi-industrial-network]-"..part.name,
    stack_size=100,weight=1000,
    localised_name={"item-name."..part.name},
    localised_description={"item-description."..part.name}
  }
  local recipe={
    type="recipe",name=part.name,categories={"crafting"},enabled=false,
    ingredients=table.deepcopy(part.ingredients),
    results={{type="item",name=part.name,amount=part.output}},
    energy_required=part.energy,main_product=part.name,
    icons=table.deepcopy(icons),
    localised_name={"recipe-name."..part.name},
    localised_description={"recipe-description."..part.name},
    allow_productivity=false,maximum_productivity=0,
    auto_recycle=false,allow_decomposition=false
  }
  local technology={
    type="technology",name=part.name,
    icons=table.deepcopy(icons),
    localised_name={"technology-name."..part.name},
    localised_description={"technology-description."..part.name},
    prerequisites=prerequisites,
    effects={{type="unlock-recipe",recipe=part.name}},
    unit={count=part.count,time=45,ingredients={}},
    order="f[razi-industry]-"..part.name
  }
  for _,pack in ipairs(science) do
    technology.unit.ingredients[#technology.unit.ingredients+1]={pack,1}
  end
  data:extend({object,recipe,technology})
  index[part.name]={part.name}
  return true
end

local function upgrade(name,source,product,category,world,planet_names,
  component,mod_name,options)
  options=options or {}
  local rule={
    name=name,source=source,product=product,category=category,
    working_world=world,source_mod=mod_name,
    planets=planet_names,science={"vibrant-tech-card","vespera-tech-card"},
    supplier_recipes={{recipe=component,product=component}},
    additional={{type="item",name=component,amount=1}},
    batch=options.batch or 4,bonus=options.bonus or 1,
    target_bonus_fraction=options.target_bonus_fraction,
    count=options.count or 900,time=60,
    bonus_icon=component,require_supplier_provenance=true,
    max_bonus_fraction=0.25,
    time_multiplier=options.time_multiplier or
      (options.deep and 1.2 or 1.15),
    deep_only=options.deep or nil,
    keep_native_category=options.native or nil,
    surface_source=options.surface_source,
    surface_world=options.surface_world
  }
  return rule
end

local precision="razi-network-precision-matrix"
local lattice="razi-network-extreme-lattice"
local bond="razi-network-panglia-optic-bond"
local frame="razi-network-umbra-pressure-frame"
local matrix_worlds={"planet-discovery-moshine","planet-discovery-paracelsin",
  "planet-discovery-vulcanus","planet-discovery-fulgora"}
local lattice_worlds={"planet-discovery-rubia","planet-discovery-tenebris",
  "linox-technology_planet-discovery-linox"}
local balanced_k2={
  upgrade("razi-network-matrix-cryo-controllers","kr-energy-control-unit",
    "kr-energy-control-unit","cryogenics","aquilo",
    {"planet-discovery-aquilo","planet-discovery-moshine",
     "planet-discovery-paracelsin","planet-discovery-fulgora"},precision,nil,
    {surface_source="kr-cryogenic-research-data",surface_world="aquilo"})
}
local balanced_modded={
  upgrade("razi-network-matrix-rubia-logistics","rubia-long-stack-inserter",
    "rubia-long-stack-inserter","advanced-crafting","rubia",
    {"planet-discovery-rubia","planet-discovery-moshine",
     "planet-discovery-paracelsin","planet-discovery-fulgora"},precision,"rubia",
    {native=true,batch=8,bonus=2}),
  upgrade("razi-network-matrix-linox-refining","linox-recipe_rare-earth-refining",
    "rare-earth-powder","chemistry","linox-planet_linox",
    {"linox-technology_planet-discovery-linox","planet-discovery-moshine",
     "planet-discovery-paracelsin","planet-discovery-fulgora"},precision,"linox",
    {native=true,batch=8,bonus=2}),
  upgrade("razi-network-lattice-vesta-magnets","supermagnet",
    "supermagnet","electromagnetics","vesta",
    {"planet-discovery-vesta","planet-discovery-rubia",
     "planet-discovery-tenebris","linox-technology_planet-discovery-linox"},
     lattice,"skewer_planet_vesta",{native=true,count=1150})
}
local return_modded={
  upgrade("razi-network-bond-paracelsin-coils","electric-coil",
    "electric-coil","mechanics","paracelsin",
    {"planet-discovery-paracelsin","panglia_planet_discovery_panglia",
     "planet-discovery-moshine","planet-discovery-fulgora"},
    bond,"Paracelsin",{native=true,count=520,
      target_bonus_fraction=0.20,time_multiplier=1.10}),
  upgrade("razi-network-bond-linox-refining","linox-recipe_rare-earth-refining",
    "rare-earth-powder","chemistry","linox-planet_linox",
    {"linox-technology_planet-discovery-linox",
     "panglia_planet_discovery_panglia",
     "planet-discovery-moshine","planet-discovery-fulgora"},
    bond,"linox",{native=true,count=650,
      target_bonus_fraction=0.20,time_multiplier=1.10})
}
local deep_modded={
  upgrade("razi-network-lattice-vesta-foundations","vesta-foundation",
    "vesta-foundation","metallurgy","vesta",
    {"planet-discovery-vesta","planet-discovery-rubia",
     "planet-discovery-tenebris","linox-technology_planet-discovery-linox"},
    lattice,"skewer_planet_vesta",{deep=true,count=1450}),
  upgrade("razi-network-lattice-balack-shielding","bm-radiation-sheilding",
    "bm-radiation-sheilding","bm-bio-cube","bm-balack",
    {"bm-planet-discovery-balack","planet-discovery-rubia",
     "planet-discovery-tenebris","linox-technology_planet-discovery-linox"},
    lattice,"biological-machines-planet-balack",
    {deep=true,native=true,count=1500})
}
local pressure_modded={
  upgrade("razi-network-frame-vesta-foundations","vesta-foundation",
    "vesta-foundation","metallurgy","vesta",
    {"planet-discovery-vesta","planet-discovery-crucible",
     "linox-technology_planet-discovery-linox",
     "panglia_planet_discovery_panglia"},
    frame,"skewer_planet_vesta",{deep=true,count=960,
      target_bonus_fraction=0.20,time_multiplier=1.12})
}
local pressure_k2={
  upgrade("razi-network-frame-aquilo-controllers","kr-energy-control-unit",
    "kr-energy-control-unit","cryogenics","aquilo",
    {"planet-discovery-aquilo","planet-discovery-vesta",
     "planet-discovery-crucible",
     "linox-technology_planet-discovery-linox",
     "panglia_planet_discovery_panglia"},
    frame,nil,{deep=true,count=1100,
      target_bonus_fraction=0.20,time_multiplier=1.12,
      surface_source="kr-cryogenic-research-data",surface_world="aquilo"})
}
M.premium={
  k2=balanced_k2,modded=balanced_modded,deep=deep_modded,
  return_modded=return_modded,pressure_modded=pressure_modded,
  pressure_k2=pressure_k2
}

function M.data_final_fixes()
  if not mode.enabled() or not (mods and mods["Krastorio2-spaced-out"])
    or not enabled("razi-enable-modded-planet-exchanges") then return end
  local index=unlock_index()
  for _,part in ipairs(parts) do register_part(part,index) end
end

function M.register_premium()
  -- Freight branches are independent: missing one source material must not
  -- silently disable every other optional factory upgrade.
  if raw("item",precision) then
    factory.register_k2so_balanced(balanced_k2)
    factory.register_additional(balanced_modded)
  end
  if raw("item",bond) then
    factory.register_additional(return_modded)
  end
  if raw("item",lattice) then
    factory.register_additional(deep_modded)
  end
  if raw("item",frame) then
    factory.register_additional(pressure_modded)
    factory.register_k2so(pressure_k2)
  end
end
return M
