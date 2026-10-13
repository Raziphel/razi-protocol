-- Run from Razi Protocol's repository root:
--   lua tests/lua/test_fluxworks_specializations.lua
-- Prototype mock. A full Factorio 2.1/K2SO startup test is still required.
local function copy(value)
  if type(value)~="table" then return value end
  local result={}
  for k,v in pairs(value) do result[copy(k)]=copy(v) end
  return result
end
table.deepcopy=copy

local identifiers={"calidus","solaris","nyxaris","vibrant","vespera","beetlejuice","umbra"}
local base_techs={
  "fw-flux-stabilization","fw-vulcanus-industrial-symbiosis",
  "fw-gleba-regenerative-symbiosis","fw-fulgora-electromagnetic-symbiosis",
  "fw-aquilo-thermal-symbiosis","fw-cross-planetary-industrial-convergence",
  "fw-flux-phase-engineering","space-science-pack","solaris-discovery",
  "nyxaris-discovery","vibrant-discovery","vespera-discovery",
  "beetlejuice-discovery","umbra-discovery",
  "planet-discovery-secretas","planet-discovery-tenebris",
}
local items={
  "fw-metal-mesh","iron-plate","copper-plate","fw-crystalised-flux",
  "fw-annealed-cermet","fw-cermet","tungsten-carbide","fw-foundry-lining",
  "fw-nutrient-bed","bioflux","spoilage","fw-inline-filter",
  "fw-resonance-substrate","superconductor","holmium-plate",
  "fw-circuit-substrate","fw-aquilo-cryogel","ice","lithium-plate",
  "fw-salt","fw-quantum-computer","gold-plate","fw-logic-matrix",
  "fw-memory-die","fw-sensor-package","fw-flux-phase-manifold",
  "chitosan","fw-condensed-flux-matrix",
}
local fluids={
  "fw-yellow-flux","fw-red-flux","fw-green-flux","fw-purple-flux",
  "fluoroketone-cold"
}
local science={
  "automation-science-pack","logistic-science-pack","chemical-science-pack",
  "production-science-pack","utility-science-pack","metallurgic-science-pack",
  "agricultural-science-pack","electromagnetic-science-pack",
  "cryogenic-science-pack","solaris-tech-card","nyxaris-tech-card",
  "vibrant-tech-card","vespera-tech-card","beetlejuice-tech-card",
  "umbra-tech-card",
}

local function setup(missing)
  local raw={technology={},item={},tool={},module={},capsule={},
    fluid={},recipe={},["recipe-category"]={}}
  for _,name in ipairs(base_techs) do
    raw.technology[name]={name=name}
  end
  for _,name in ipairs(items) do
    if name~=missing then
      raw.item[name]={name=name,icon="demo/"..name..".png",icon_size=64,
        subgroup="intermediate-product"}
    end
  end
  for _,name in ipairs(science) do raw.tool[name]={name=name} end
  for _,name in ipairs(fluids) do raw.fluid[name]={name=name} end
  for _,name in ipairs({"fw-flux-synthesis","fw-arc-smelting"}) do
    raw["recipe-category"][name]={name=name}
  end

  _G.data={raw=raw}
  function data:extend(prototypes)
    for _,proto in ipairs(prototypes) do
      local bucket=assert(raw[proto.type],"Unexpected prototype type "..proto.type)
      assert(not bucket[proto.name],"Duplicate prototype "..proto.name)
      bucket[proto.name]=proto
    end
  end
  _G.log=function() end
  _G.mods={FluxWorks="0.2.14"}
  return raw
end

local bridge=dofile("prototypes/compat/fluxworks_specializations.lua")
local raw=setup()
assert(bridge.data_final_fixes()==7)
for _,system in ipairs(identifiers) do
  local tech_name="razi-fw-"..system.."-industry"
  local recipe_name="razi-fw-"..system.."-specialty"
  local technology=assert(raw.technology[tech_name])
  local recipe=assert(raw.recipe[recipe_name])
  assert(technology.type=="technology" and recipe.type=="recipe")
  assert(recipe.allow_productivity==false and recipe.enabled==false)
  assert(recipe.main_product==recipe.results[1].name)
  assert(#technology.prerequisites>=2 and #technology.unit.ingredients>=2)
  local found=false
  for _,effect in ipairs(technology.effects) do
    if effect.type=="unlock-recipe" and effect.recipe==recipe_name then found=true end
    assert(effect.type~="unlock-space-location")
  end
  assert(found,"No research unlock for "..system)
  local liquids=0
  for _,source in ipairs(recipe.ingredients) do
    if source.type=="fluid" then
      liquids=liquids+1
      assert(raw.fluid[source.name])
    else
      assert(raw.item[source.name])
    end
  end
  assert(liquids<=2,"Machine has too many fluid inputs")
  if system=="beetlejuice" or system=="umbra" then
    assert(#recipe.icons==3,"Two spectra should be visible")
  end
end

-- Source mods or materials that aren't installed skip their process safely.
raw=setup("gold-plate")
assert(bridge.data_final_fixes()==6)
assert(not raw.technology["razi-fw-beetlejuice-industry"])
assert(not raw.recipe["razi-fw-beetlejuice-specialty"])
assert(raw.technology["razi-fw-umbra-industry"])

-- K2SO's alternate lithium item must not silently remove Vespera.
raw=setup("lithium-plate")
raw.item["kr-lithium"]={name="kr-lithium"}
assert(bridge.data_final_fixes()==7)
local lithium_found=false
for _,source in ipairs(raw.recipe["razi-fw-vespera-specialty"].ingredients) do
  if source.name=="kr-lithium" then lithium_found=true end
end
assert(lithium_found,"Vespera did not use K2SO's lithium replacement")

-- An installed non-FluxWorks Razi pack should never gain these prototypes.
raw=setup()
_G.mods={}
assert(bridge.data_final_fixes()==0)
assert(not raw.technology["razi-fw-calidus-industry"])

print("Razi FluxWorks: seven optional industry technologies and recipes OK")
