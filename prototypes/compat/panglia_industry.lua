-- Panglia's glass and Moshine's optics can feed each other's factories.
-- Both recipes go through the usual exchange checks.
local engine = require("prototypes.compat.planet_production_exchanges")
local M = {}

local recipes = {
  {
    -- Export Moshine optics and Gleba bioflux to Panglia's own foundries.
    -- Its native glass recipe remains available with its real 1401 hPa gate.
    name="razi-panglia-biooptic-glass",
    source_mod="panglia_planet",
    required_mods={"panglia_planet","Moshine","apia"},
    source="panglia_panglite_glass",product="panglia_panglite_glass",
    category="metallurgy",keep_native_category=true,
    working_world="panglia",
    planets={"panglia_planet_discovery_panglia",
      "planet-discovery-moshine","planet-discovery-apia-carnova",
      "planet-discovery-gleba"},
    supplier_recipes={
      {recipe="optical-cable",product="optical-cable"},
      {recipe="bioflux",product="bioflux"}
    },
    science={"solaris-tech-card","nyxaris-tech-card"},
    additional={{type="item",name="optical-cable",amount=4},
      {type="item",name="bioflux",amount=2}},
    batch=4,bonus=1,count=900,time=60,
    bonus_icon="optical-cable",
    require_supplier_provenance=true,
    max_bonus_fraction=0.25,
    time_multiplier=1.2
  },
  {
    -- Panglite glass travels back to Moshine for precision manufacturing.
    -- No requirement is put onto Moshine's original cable recipe.
    name="razi-moshine-panglia-optical-cables",
    source_mod="panglia_planet",
    required_mods={"panglia_planet","Moshine","apia"},
    source="optical-cable",product="optical-cable",
    category="crafting",keep_native_category=true,
    working_world="moshine",
    planets={"panglia_planet_discovery_panglia",
      "planet-discovery-moshine","planet-discovery-apia-carnova",
      "planet-discovery-gleba"},
    supplier_recipes={
      {recipe="panglia_panglite_glass",product="panglia_panglite_glass"},
      {recipe="bioflux",product="bioflux"}
    },
    science={"solaris-tech-card","nyxaris-tech-card"},
    additional={{type="item",name="panglia_panglite_glass",amount=2},
      {type="item",name="bioflux",amount=2}},
    batch=4,bonus=1,count=950,time=60,
    bonus_icon="panglia_panglite_glass",
    require_supplier_provenance=true,
    max_bonus_fraction=0.25,
    time_multiplier=1.2
  }
}

function M.data_final_fixes()
  if not (mods and mods["panglia_planet"]) then return end
  engine.register_additional(recipes)
end

return M
