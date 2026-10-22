-- Bonus recipes for trading materials between the planet mods.
-- Keep these separate from their normal production chains.
local production = require("prototypes.compat.planet_production_exchanges")

local rules = {
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
    -- One extra magnet per four native ones: 25%, the ceiling of every
    -- exchange (one per three would be 33%).
    batch=4, bonus=1, max_bonus_fraction=0.25, count=1450, time=60,
    bonus_icon="rare-earth-powder"
  }
}

local M = {}
function M.data_final_fixes()
  production.register_additional(rules)
end
return M
