-- Second-frontier factories. Every imported item must have an actual
-- native recipe and source research. Do not change native manufacturing.
local engine=require("prototypes.compat.planet_production_exchanges")
local M={}
local rules={
  -- Fulgora supplies rugged capacitors for later relay and power networks.
  -- An Aquilo control unit is shipped back as a finished component.
  {
    name="razi-middle-fulgora-resilient-capacitors",
    source="supercapacitor",product="supercapacitor",
    category="electromagnetics",keep_native_category=true,
    working_world="fulgora",required_mods={"Moshine"},
    planets={"planet-discovery-fulgora","planet-discovery-aquilo",
      "planet-discovery-moshine"},
    supplier_recipes={{recipe="kr-energy-control-unit",
      product="kr-energy-control-unit"},
      {recipe="optical-cable",product="optical-cable"}},
    science={"vibrant-tech-card","vespera-tech-card"},
    additional={{type="item",name="kr-energy-control-unit",amount=1},
      {type="item",name="optical-cable",amount=2}},
    batch=4,bonus=1,target_bonus_fraction=0.20,count=680,time=45,
    bonus_icon="optical-cable",require_supplier_provenance=true,
    max_bonus_fraction=0.25,min_throughput_ratio=1.04,time_multiplier=1.12,
    not_after={"beetlejuice-discovery","umbra-discovery"}
  },
  -- Aquilo control engineering uses Fulgora energy stores and old Nyxaris
  -- optics. It does not replace the native cryogenic production recipe.
  {
    name="razi-middle-aquilo-capacitor-controls",
    source="kr-energy-control-unit",product="kr-energy-control-unit",
    category="cryogenics",working_world="aquilo",
    surface_source="kr-cryogenic-research-data",surface_world="aquilo",
    required_mods={"Moshine"},
    planets={"planet-discovery-aquilo","planet-discovery-fulgora",
      "planet-discovery-moshine"},
    supplier_recipes={{recipe="supercapacitor",product="supercapacitor"},
      {recipe="optical-cable",product="optical-cable"}},
    science={"vibrant-tech-card","vespera-tech-card"},
    additional={{type="item",name="supercapacitor",amount=1},
      {type="item",name="optical-cable",amount=2}},
    batch=4,bonus=1,target_bonus_fraction=0.20,count=740,time=45,
    bonus_icon="supercapacitor",require_supplier_provenance=true,
    max_bonus_fraction=0.25,min_throughput_ratio=1.04,time_multiplier=1.12,
    not_after={"beetlejuice-discovery","umbra-discovery"}
  },
  -- Two mid-frontier anchor workshops exchange COMPLETED native materials.
  -- Neither premium recipe consumes the other, so there is no freight loop.
  {
    name="razi-middle-paracelsin-shielded-coils",
    source_mod="Paracelsin",source="electric-coil",product="electric-coil",
    category="mechanics",keep_native_category=true,
    working_world="paracelsin",required_mods={"Paracelsin","rubia"},
    planets={"planet-discovery-paracelsin","planet-discovery-rubia",
      "planet-discovery-fulgora"},
    supplier_recipes={{recipe="craptonite-casting",
      product="craptonite-frame"},
      {recipe="holmium-plate",product="holmium-plate"}},
    science={"vibrant-tech-card","vespera-tech-card"},
    additional={{type="item",name="craptonite-frame",amount=2},
      {type="item",name="holmium-plate",amount=1}},
    batch=4,bonus=1,target_bonus_fraction=0.20,count=880,time=50,
    bonus_icon="craptonite-frame",require_supplier_provenance=true,
    max_bonus_fraction=0.25,min_throughput_ratio=1.04,time_multiplier=1.15,
    not_after={"beetlejuice-discovery","umbra-discovery"}
  },
  {
    name="razi-middle-rubia-conductive-frames",
    source_mod="rubia",source="craptonite-casting",
    product="craptonite-frame",category="organic",
    keep_native_category=true,working_world="rubia",
    required_mods={"Paracelsin","rubia"},
    planets={"planet-discovery-rubia","planet-discovery-paracelsin",
      "planet-discovery-fulgora"},
    supplier_recipes={{recipe="electric-coil",product="electric-coil"},
      {recipe="supercapacitor",product="supercapacitor"}},
    science={"vibrant-tech-card","vespera-tech-card"},
    additional={{type="item",name="electric-coil",amount=2},
      {type="item",name="supercapacitor",amount=1}},
    batch=4,bonus=1,target_bonus_fraction=0.20,count=920,time=50,
    bonus_icon="electric-coil",require_supplier_provenance=true,
    max_bonus_fraction=0.25,min_throughput_ratio=1.04,time_multiplier=1.15,
    not_after={"beetlejuice-discovery","umbra-discovery"}
  }
}
function M.data_final_fixes()
  -- This existing engine enforces user options, native unlocks, suppliers,
  -- legal factories, surfaces, ingredients and conservation of byproducts.
  engine.register_additional(rules)
end
return M
