-- The freight upgrades of the network components: native recipes of other planets that are
-- boosted by shipping a component to them.
local parts = require("prototypes.industry.components.network_parts")
local precision = parts.precision
local lattice = parts.lattice
local bond = parts.bond
local frame = parts.frame

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

local balanced_k2={
  upgrade("razi-network-matrix-cryo-controllers","kr-energy-control-unit",
    "kr-energy-control-unit","cryogenics","aquilo",
    {"planet-discovery-aquilo","planet-discovery-moshine",
     "planet-discovery-paracelsin","planet-discovery-fulgora"},precision,nil,
    {surface_source="kr-cryogenic-research-data",surface_world="aquilo"})
}
local balanced_modded={
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
local pressure_modded={
  upgrade("razi-network-frame-vesta-foundations","vesta-foundation",
    "vesta-foundation","metallurgy","vesta",
    {"planet-discovery-vesta","planet-discovery-crucible",
     "linox-technology_planet-discovery-linox",
     "panglia_planet_discovery_panglia"},
    frame,"skewer_planet_vesta",{deep=true,count=960,
      target_bonus_fraction=0.20,time_multiplier=1.12})
}
return {
 k2 = balanced_k2,
 modded = balanced_modded,
 return_modded = return_modded,
 pressure_modded = pressure_modded,
}
