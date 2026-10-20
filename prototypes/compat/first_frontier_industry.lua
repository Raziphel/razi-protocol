-- Early cross-star factories. These are optional alternatives to
-- existing production, never new requirements for reaching a planet.
-- Keep the native recipe and its source technology in charge.
local production=require("prototypes.compat.planet_production_exchanges")
local M={}

-- Castra's piercing magazines use castra-crafting in the current pack.
-- Read the REAL source recipe on every data-final-fixes run so another
-- mod's category override does not silently delete our optional factory.
local function native_category(name,fallback)
  local recipes=data and data.raw and data.raw.recipe
  local recipe=recipes and recipes[name]
  if not recipe then return fallback end
  return recipe.category or (recipe.categories and recipe.categories[1])
    or fallback
end

local rules={
  -- Bring Vulcanus metallurgy and Gleba's biology to Moshine's silicon line.
  {
    name="razi-frontier-moshine-biometal-silicon",
    source_mod="Moshine",required_mods={"Moshine"},
    source="silicon-cell",product="silicon-cell",
    category="crafting",keep_native_category=true,working_world="moshine",
    planets={"planet-discovery-moshine","planet-discovery-vulcanus",
      "planet-discovery-gleba"},
    supplier_recipes={{recipe="kr-casting-rare-metals",product="kr-rare-metals"},
      {recipe="bioflux",product="bioflux"}},
    science={"solaris-tech-card","nyxaris-tech-card"},
    additional={{type="item",name="kr-rare-metals",amount=2},
      {type="item",name="bioflux",amount=1}},
    batch=4,bonus=1,target_bonus_fraction=0.20,count=560,time=45,
    bonus_icon="kr-rare-metals",
    require_supplier_provenance=true,max_bonus_fraction=0.25,min_throughput_ratio=1.04,
    time_multiplier=1.12
  },
  -- Gleba can turn imported optics and metals into better carbon-fiber
  -- batches. The source Biochamber recipe, nutrients and inputs remain.
  {
    name="razi-frontier-gleba-photofiber",
    required_mods={"Moshine"},
    source="carbon-fiber",product="carbon-fiber",
    category="organic",keep_native_category=true,working_world="gleba",
    planets={"planet-discovery-gleba","planet-discovery-moshine",
      "planet-discovery-vulcanus"},
    supplier_recipes={{recipe="optical-cable",product="optical-cable"},
      {recipe="kr-casting-rare-metals",product="kr-rare-metals"}},
    science={"solaris-tech-card","nyxaris-tech-card"},
    additional={{type="item",name="optical-cable",amount=2},
      {type="item",name="kr-rare-metals",amount=1}},
    batch=4,bonus=1,target_bonus_fraction=0.20,count=590,time=45,
    bonus_icon="optical-cable",
    require_supplier_provenance=true,max_bonus_fraction=0.25,min_throughput_ratio=1.04,
    time_multiplier=1.12
  },
  -- Castra gets a reason to receive biological composites and Moshine
  -- circuits. Use the native magazine recipe if K2SO has kept it.
  {
    name="razi-frontier-castra-composite-rounds",
    required_mods={"Moshine","castra-prime"},
    source="piercing-rounds-magazine",product="piercing-rounds-magazine",
    category=native_category("piercing-rounds-magazine","castra-crafting"),
    keep_native_category=true,working_world="castra",
    planets={"planet-discovery-castra","planet-discovery-gleba",
      "planet-discovery-moshine"},
    supplier_recipes={{recipe="carbon-fiber",product="carbon-fiber"},
      {recipe="silicon-cell",product="silicon-cell"}},
    science={"solaris-tech-card","nyxaris-tech-card"},
    additional={{type="item",name="carbon-fiber",amount=1},
      {type="item",name="silicon-cell",amount=1}},
    batch=4,bonus=1,target_bonus_fraction=0.20,count=640,time=45,
    bonus_icon="carbon-fiber",
    require_supplier_provenance=true,max_bonus_fraction=0.25,min_throughput_ratio=1.04,
    time_multiplier=1.15
  }
}

function M.data_final_fixes()
  -- Existing exchange engine checks producer recipes, research unlocks,
  -- science labs, legal machines/surfaces, caps and interdependence setting.
  production.register_additional(rules)
end
return M
