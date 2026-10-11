-- Optional, source-faithful production links for the new community worlds.
-- All three are late alternative recipes. They do not participate in Razi's
-- system cards, and none replaces a source author's original recipe.
local production = require("prototypes.compat.planet_production_exchanges")

local exchanges = {
  {
    -- Ferrum's remote robot industry keeps the original oxide/electrolyte/
    -- molten iron economy. Linox and Moshine give it a later export market.
    name="razi-ferrum-linox-optical-magnets",
    source_mod="planet-ferrum",
    required_mods={"planet-ferrum","linox","Moshine"},
    source="ferrum-rare-earth-magnet", product="ferrum-rare-earth-magnet",
    category="metallurgy", keep_native_category=true,
    working_world="ferrum",
    planets={"planet-discovery-ferrum",
      "linox-technology_planet-discovery-linox",
      "planet-discovery-moshine"},
    supplier_recipes={
      {recipe="linox-recipe_rare-earth-refining",product="rare-earth-powder"},
      {recipe="optical-cable",product="optical-cable"}
    },
    science={"vibrant-tech-card","vespera-tech-card"},
    additional={
      {type="item",name="rare-earth-powder",amount=3},
      {type="item",name="optical-cable",amount=4}
    },
    batch=3,bonus=1,count=1100,time=60,
    bonus_icon="rare-earth-powder"
  },
  {
    -- Wit has a long helium-to-interstellar-science path. A bonus on its
    -- *late* accumulators cannot accelerate the early asteroid collector,
    -- early space science, or Wit robotics facility.
    name="razi-wit-ferrum-grid-storage",
    source_mod="biological-machines-planet-wit",
    required_mods={"biological-machines-planet-wit","planet-ferrum",
      "linox","Moshine"},
    source="bm-advanced-accumulator",product="bm-advanced-accumulator",
    category="electromagnetics",keep_native_category=true,
    working_world="bm-wit",
    planets={"bm-planet-discovery-wit","planet-discovery-ferrum",
      "linox-technology_planet-discovery-linox",
      "planet-discovery-moshine"},
    supplier_recipes={
      {recipe="ferrum-rare-earth-magnet",
        product="ferrum-rare-earth-magnet"},
      {recipe="linox-recipe_rare-earth-refining",product="rare-earth-powder"},
      {recipe="optical-cable",product="optical-cable"}
    },
    science={"vibrant-tech-card","vespera-tech-card"},
    additional={
      {type="item",name="ferrum-rare-earth-magnet",amount=4},
      {type="item",name="rare-earth-powder",amount=4},
      {type="item",name="optical-cable",amount=4}
    },
    batch=4,bonus=1,count=1250,time=60,
    bonus_icon="ferrum-rare-earth-magnet"
  },
  {
    -- Balack requires native promethium, tungsten, carbon fiber and oil.
    -- Imports from Rubia and Tenebris only improve late shielding yield.
    name="razi-balack-rubia-chitosan-shielding",
    source_mod="biological-machines-planet-balack",
    required_mods={"biological-machines-planet-balack",
      "rubia","tenebris-prime"},
    source="bm-radiation-sheilding",product="bm-radiation-sheilding",
    category="bm-bio-cube",keep_native_category=true,
    working_world="bm-balack",
    planets={"bm-planet-discovery-balack",
      "planet-discovery-rubia","planet-discovery-tenebris"},
    supplier_recipes={
      {recipe="craptonite-casting",product="craptonite-frame"},
      {recipe="chitosan",product="chitosan"}
    },
    science={"vibrant-tech-card","vespera-tech-card"},
    additional={
      {type="item",name="craptonite-frame",amount=2},
      {type="item",name="chitosan",amount=2}
    },
    batch=2,bonus=2,count=1250,time=60,
    bonus_icon="craptonite-frame"
  }
}

local M = {}
function M.data_final_fixes()
  production.register_additional(exchanges)
end
return M
