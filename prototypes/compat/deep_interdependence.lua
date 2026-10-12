-- More specialised imports for Deep interdependence.
-- Keep the extra output below 30% of the original batch.
local mode = require("prototypes.compat.interdependence_mode")
local production = require("prototypes.compat.planet_production_exchanges")
local M = {}

local k2so = {
  {
    name="razi-deep-vulcanus-zinc-metals", deep_only=true,
    source="kr-casting-rare-metals",product="kr-rare-metals",
    required_mods={"Paracelsin"},
    category="metallurgy",working_world="vulcanus",
    planets={"planet-discovery-vulcanus","planet-discovery-paracelsin"},
    supplier_recipes={{recipe="zinc-plate",product="zinc-plate"}},
    science={"solaris-tech-card","nyxaris-tech-card"},
    additional={{type="item",name="zinc-plate",amount=3}},
    batch=4,bonus=1,count=850,time=45,bonus_icon="zinc-plate"
  },
  {
    name="razi-deep-fulgora-optical-components",deep_only=true,
    source="kr-electronic-components",product="kr-electronic-components",
    required_mods={"Moshine"},
    category="electromagnetics",surface_source="kr-electromagnetic-research-data",
    surface_world="fulgora",
    planets={"planet-discovery-fulgora","planet-discovery-moshine"},
    supplier_recipes={{recipe="optical-cable",product="optical-cable"}},
    science={"solaris-tech-card","nyxaris-tech-card"},
    additional={{type="item",name="optical-cable",amount=3},
      {type="item",name="holmium-plate",amount=1}},
    batch=2,bonus=1,count=900,time=45,bonus_icon="optical-cable"
  },
  {
    name="razi-deep-aquilo-optical-controllers",deep_only=true,
    source="kr-energy-control-unit",product="kr-energy-control-unit",
    required_mods={"Moshine"},
    category="cryogenics",surface_source="kr-cryogenic-research-data",
    surface_world="aquilo",
    planets={"planet-discovery-aquilo","planet-discovery-fulgora",
      "planet-discovery-moshine"},
    supplier_recipes={{recipe="optical-cable",product="optical-cable"}},
    science={"vibrant-tech-card","vespera-tech-card"},
    additional={{type="item",name="optical-cable",amount=4},
      {type="item",name="holmium-plate",amount=2},
      {type="fluid",name="fluoroketone-cold",amount=10}},
    batch=4,bonus=1,count=1250,time=60,bonus_icon="optical-cable"
  }
}

local modded = {
  {
    name="razi-deep-moshine-holmium-silicon",deep_only=true,
    source_mod="Moshine",source="silicon-cell",product="silicon-cell",
    category="crafting",keep_native_category=true,working_world="moshine",
    planets={"planet-discovery-moshine","planet-discovery-fulgora"},
    science={"solaris-tech-card","nyxaris-tech-card"},
    additional={{type="item",name="holmium-plate",amount=3}},
    batch=4,bonus=1,count=650,time=45,bonus_icon="holmium-plate"
  },
  {
    name="razi-deep-rubia-rare-earth-logistics",deep_only=true,
    source_mod="rubia",required_mods={"linox"},
    source="rubia-long-stack-inserter",product="rubia-long-stack-inserter",
    category="advanced-crafting",keep_native_category=true,
    working_world="rubia",
    planets={"planet-discovery-rubia",
      "linox-technology_planet-discovery-linox"},
    supplier_recipes={{recipe="linox-recipe_rare-earth-refining",
      product="rare-earth-powder"}},
    science={"vibrant-tech-card","vespera-tech-card"},
    additional={{type="item",name="rare-earth-powder",amount=3}},
    batch=4,bonus=1,count=1400,time=60,bonus_icon="rare-earth-powder"
  },
  {
    name="razi-deep-tenebris-zinc-optics",deep_only=true,
    source_mod="tenebris-prime",required_mods={"Paracelsin","Moshine"},
    source="chitosan",product="chitosan",category="chemistry",
    keep_native_category=true,working_world="tenebris",
    planets={"planet-discovery-tenebris",
      "planet-discovery-paracelsin","planet-discovery-moshine"},
    supplier_recipes={{recipe="zinc-rivets",product="zinc-rivets"},
      {recipe="optical-cable",product="optical-cable"}},
    science={"vibrant-tech-card","vespera-tech-card"},
    additional={{type="item",name="zinc-rivets",amount=3},
      {type="item",name="optical-cable",amount=3}},
    batch=4,bonus=2,count=1300,time=60,bonus_icon="optical-cable"
  },
  {
    name="razi-deep-vesta-precious-supermagnets",deep_only=true,
    source_mod="skewer_planet_vesta",required_mods={"secretas"},
    source="supermagnet",product="supermagnet",
    category="electromagnetics",keep_native_category=true,
    working_world="vesta",
    planets={"planet-discovery-vesta","planet-discovery-secretas",
      "planet-discovery-cubium"},
    supplier_recipes={{recipe="gold-plate",product="gold-plate"}},
    science={"vibrant-tech-card","vespera-tech-card"},
    additional={{type="item",name="gold-plate",amount=3}},
    batch=4,bonus=1,count=1550,time=60,bonus_icon="gold-plate"
  },
  {
    name="razi-deep-linox-craptonite-refining",deep_only=true,
    source_mod="linox",required_mods={"rubia"},
    source="linox-recipe_rare-earth-refining",product="rare-earth-powder",
    category="chemistry",keep_native_category=true,
    working_world="linox-planet_linox",
    planets={"linox-technology_planet-discovery-linox",
      "planet-discovery-rubia"},
    supplier_recipes={{recipe="craptonite-casting",product="craptonite-frame"}},
    science={"vibrant-tech-card","vespera-tech-card"},
    additional={{type="item",name="craptonite-frame",amount=3}},
    batch=3,bonus=1,count=1450,time=60,bonus_icon="craptonite-frame"
  },
  {
    name="razi-deep-ferrum-galvanic-magnets",deep_only=true,
    source_mod="planet-ferrum",required_mods={"Paracelsin"},
    source="ferrum-rare-earth-magnet",product="ferrum-rare-earth-magnet",
    category="metallurgy",keep_native_category=true,
    working_world="ferrum",
    planets={"planet-discovery-ferrum","planet-discovery-paracelsin"},
    supplier_recipes={{recipe="zinc-plate",product="zinc-plate"}},
    science={"vibrant-tech-card","vespera-tech-card"},
    additional={{type="item",name="zinc-plate",amount=4}},
    batch=4,bonus=1,count=1350,time=60,bonus_icon="zinc-plate"
  }
}

function M.data_final_fixes()
  if not mode.deep() then return end
  production.register_k2so(k2so)
  production.register_additional(modded)
end
return M
