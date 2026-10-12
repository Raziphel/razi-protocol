-- Bonus recipes for trading materials between the planet mods.
-- Keep these separate from their normal production chains.
local production = require("prototypes.compat.planet_production_exchanges")

local rules = {
  {
    name="razi-modded-rubia-craptonite-composites",
    source_mod="rubia", source="craptonite-casting", required_mods={"rubia","Paracelsin","Moshine"},
    product="craptonite-frame", category="organic", working_world="rubia",
    planets={"planet-discovery-rubia", "planet-discovery-paracelsin",
      "planet-discovery-moshine"},
    keep_native_category=true,
    supplier_recipes={
      {recipe="zinc-plate", product="zinc-plate"},
      {recipe="optical-cable", product="optical-cable"}},
    science={"vibrant-tech-card", "vespera-tech-card"},
    additional={{type="item",name="zinc-plate",amount=2},
      {type="item",name="optical-cable",amount=2}},
    batch=3, bonus=1, count=800, time=45,
    bonus_icon="optical-cable"
  },
  {
    name="razi-modded-paracelsin-optical-coils",
    source_mod="Paracelsin", source="electric-coil", required_mods={"Paracelsin","Moshine"},
    product="electric-coil", category="mechanics",
    working_world="paracelsin",
    planets={"planet-discovery-paracelsin", "planet-discovery-moshine"},
    keep_native_category=true,
    supplier_recipes={{recipe="optical-cable",product="optical-cable"}},
    science={"solaris-tech-card", "nyxaris-tech-card"},
    additional={{type="item",name="optical-cable",amount=2}},
    batch=4, bonus=1, count=650, time=45,
    bonus_icon="optical-cable"
  },
  {
    name="razi-modded-moshine-zinc-silicon",
    source_mod="Moshine", source="silicon-cell", required_mods={"Moshine","Paracelsin"},
    product="silicon-cell", category="crafting", working_world="moshine",
    planets={"planet-discovery-moshine", "planet-discovery-paracelsin"},
    keep_native_category=true,
    supplier_recipes={{recipe="zinc-solder",product="zinc-solder"}},
    science={"solaris-tech-card", "nyxaris-tech-card"},
    additional={{type="item",name="zinc-solder",amount=2}},
    batch=4, bonus=1, count=600, time=45,
    bonus_icon="zinc-solder"
  },
  {
    name="razi-modded-linox-precision-refining",
    source_mod="linox", source="linox-recipe_rare-earth-refining", required_mods={"linox","Moshine","Paracelsin"},
    product="rare-earth-powder", category="chemistry",
    working_world="linox-planet_linox",
    planets={"linox-technology_planet-discovery-linox",
      "planet-discovery-moshine","planet-discovery-paracelsin"},
    keep_native_category=true,
    supplier_recipes={{recipe="optical-cable",product="optical-cable"},
      {recipe="zinc-plate",product="zinc-plate"}},
    science={"vibrant-tech-card","vespera-tech-card"},
    additional={{type="item",name="optical-cable",amount=2},
      {type="item",name="zinc-plate",amount=2}},
    batch=2, bonus=1, count=1100, time=60,
    bonus_icon="optical-cable"
  },
  {
    name="razi-modded-vesta-rare-earth-supermagnets",
    source_mod="skewer_planet_vesta", source="supermagnet", required_mods={"skewer_planet_vesta","linox","Moshine"},
    product="supermagnet", category="electromagnetics", working_world="vesta",
    planets={"planet-discovery-vesta",
      "linox-technology_planet-discovery-linox",
      "planet-discovery-moshine"},
    keep_native_category=true,
    supplier_recipes={
      {recipe="linox-recipe_rare-earth-refining", product="rare-earth-powder"},
      {recipe="optical-cable",product="optical-cable"}},
    science={"vibrant-tech-card","vespera-tech-card"},
    additional={{type="item",name="rare-earth-powder",amount=3},
      {type="item",name="optical-cable",amount=3}},
    batch=3, bonus=1, count=1450, time=60,
    bonus_icon="rare-earth-powder"
  },
  {
    name="razi-modded-tenebris-galvanized-chitosan",
    source_mod="tenebris-prime", source="chitosan", required_mods={"tenebris-prime","Paracelsin"},
    product="chitosan", category="chemistry", working_world="tenebris",
    planets={"planet-discovery-tenebris","planet-discovery-paracelsin"},
    keep_native_category=true,
    supplier_recipes={{recipe="zinc-rivets",product="zinc-rivets"}},
    science={"vibrant-tech-card","vespera-tech-card"},
    additional={{type="item",name="zinc-rivets",amount=2}},
    batch=2, bonus=2, count=850, time=45,
    bonus_icon="zinc-rivets"
  },
  {
    name="razi-modded-rubia-precision-inserters",
    source_mod="rubia", source="rubia-long-stack-inserter", required_mods={"rubia","Paracelsin","Moshine"},
    product="rubia-long-stack-inserter", category="advanced-crafting",
    working_world="rubia",
    planets={"planet-discovery-rubia",
      "planet-discovery-paracelsin","planet-discovery-moshine"},
    keep_native_category=true,
    supplier_recipes={{recipe="electric-coil",product="electric-coil"},
      {recipe="optical-cable",product="optical-cable"}},
    science={"vibrant-tech-card","vespera-tech-card"},
    additional={{type="item",name="electric-coil",amount=2},
      {type="item",name="optical-cable",amount=2}},
    batch=3, bonus=1, count=1200, time=60,
    bonus_icon="electric-coil"
  }
}

local M = {}
function M.data_final_fixes()
  production.register_additional(rules)
end
return M
