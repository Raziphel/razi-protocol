-- Run from repo root with Lua 5.2+:
-- lua tests/lua/test_fluxworks_exchanges.lua
local function deepcopy(v)
  if type(v)~="table" then return v end
  local result={}
  for k,x in pairs(v) do result[deepcopy(k)]=deepcopy(x) end
  return result
end
table.deepcopy=deepcopy

local ids={
  "calidus-solaris","nyxaris-vibrant","solaris-vespera",
  "vibrant-beetlejuice","nyxaris-umbra",
}
local regions={
  "calidus","solaris","nyxaris","vibrant",
  "vespera","beetlejuice","umbra",
}
local products={
  "low-density-structure","processing-unit","fw-thermal-buffer",
  "fw-flux-resonance-cell","fw-rift-stabilizer",
  "fw-metal-mesh","fw-annealed-cermet","copper-plate",
  "fw-nutrient-bed","fw-resonance-substrate","superconductor",
  "fw-aquilo-cryogel","fw-cermet","fw-quantum-computer",
  "fw-stabilized-flux-crystal","fw-flux-phase-manifold","chitosan",
}
local science={
  "chemical-science-pack","solaris-tech-card",
  "utility-science-pack","vibrant-tech-card",
  "production-science-pack","vespera-tech-card",
  "beetlejuice-tech-card","umbra-tech-card",
}
local fluids={
  "fw-yellow-flux","fw-red-flux","fw-green-flux","fw-purple-flux",
}
local function setup(missing)
  local raw={technology={},recipe={},item={},tool={},
    fluid={},module={},capsule={},["recipe-category"]={}}
  for _,region in ipairs(regions) do
    raw.technology["razi-fw-"..region.."-industry"]={
      name="razi-fw-"..region.."-industry",
    }
  end
  for _,name in ipairs(products) do
    if name~=missing then raw.item[name]={
      name=name,icon="fake/"..name..".png",icon_size=64,
      subgroup="intermediate-product",
    } end
  end
  for _,name in ipairs(science) do raw.tool[name]={name=name} end
  for _,name in ipairs(fluids) do raw.fluid[name]={name=name} end
  for _,name in ipairs({"fw-flux-synthesis","fw-arc-smelting"}) do
    raw["recipe-category"][name]={name=name}
  end
  _G.data={raw=raw}
  function data:extend(entries)
    for _,entry in ipairs(entries) do
      assert(not raw[entry.type][entry.name],"duplicate "..entry.name)
      raw[entry.type][entry.name]=entry
    end
  end
  _G.mods={FluxWorks="0.2.14"}
  _G.log=function() end
  return raw
end

local bridge=dofile("prototypes/compat/fluxworks_industry_exchanges.lua")
local raw=setup()
assert(bridge.data_final_fixes()==5)
for _,id in ipairs(ids) do
  local tech=assert(raw.technology["razi-fw-"..id.."-exchange"])
  local recipe=assert(raw.recipe["razi-fw-"..id.."-assembly"])
  assert(#tech.prerequisites==2 and #tech.unit.ingredients==2)
  for _,pack in ipairs(tech.unit.ingredients) do
    assert(not pack[1]:find("tech%-card"),
      "FluxWorks exchange research must not demand old system tech cards")
  end
  for _,parent in ipairs(tech.prerequisites) do
    assert(raw.technology[parent],"missing workshop parent "..parent)
  end
  assert(tech.effects[1].type=="unlock-recipe")
  assert(tech.effects[1].recipe==recipe.name)
  assert(recipe.enabled==false and recipe.allow_productivity==false)
  assert(recipe.main_product==recipe.results[1].name)
  assert(#recipe.icons>=3,"missing two spectrum markers")
  assert(#recipe.ingredients<=6)
  local liquids=0
  for _,entry in ipairs(recipe.ingredients) do
    if entry.type=="fluid" then
      liquids=liquids+1
      assert(raw.fluid[entry.name])
    else
      assert(raw.item[entry.name])
    end
  end
  assert(liquids<=2,"machine has too many fluid inputs")
end

-- Repeated stage invocations must not duplicate technologies/unlocks.
assert(bridge.data_final_fixes()==5)
local count=0
for name in pairs(raw.recipe) do
  if name:sub(1,8)=="razi-fw-" then count=count+1 end
end
assert(count==5)

-- A missing regional ingredient affects only its dependent alternatives.
raw=setup("fw-nutrient-bed")
assert(bridge.data_final_fixes()==3)
assert(not raw.recipe["razi-fw-nyxaris-vibrant-assembly"])
assert(not raw.technology["razi-fw-nyxaris-umbra-exchange"])
assert(raw.recipe["razi-fw-calidus-solaris-assembly"])

-- FluxWorks not installed means no optional prototypes.
raw=setup()
_G.mods={}
assert(bridge.data_final_fixes()==0)
assert(not raw.technology["razi-fw-calidus-solaris-exchange"])
print("FluxWorks inter-system exchanges: 5 optional workshops, guards OK")
