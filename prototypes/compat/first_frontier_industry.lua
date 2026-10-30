-- Early cross-star factory. An optional alternative to existing production,
-- never a new requirement for reaching a planet. Keep the native recipe and
-- its source technology in charge.
local production=require("prototypes.compat.planet_production_exchanges")
local M={}

-- Castra's piercing magazines use castra-crafting in the current pack.
-- Read the REAL source recipe on every data-final-fixes run so another
-- mod's category override does not silently delete our optional factory.
local function native_category(name,fallback)
  local recipes=data and data.raw and data.raw.recipe
  local recipe=recipes and recipes[name]
  if not recipe then return fallback end
  ---@diagnostic disable-next-line: undefined-field
  return recipe.category or (recipe.categories and recipe.categories[1])
    or fallback
end

local rules={
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
