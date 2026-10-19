-- The Seven Witness Accord. RAZI-owned hardware, built out of native items.
-- The real Dyson/transceiver mods continue to own their own machinery.
local M={}
local function recipe(name,results,ingredients,energy)
  return {type="recipe",name=name,enabled=false,
    energy_required=energy or 30,category="crafting",
    ingredients=ingredients,
    results={{type="item",name=name,amount=1}},
    allow_productivity=false,auto_recycle=false,
    allow_decomposition=false}
end
local function item(name,icon,order)
  return {type="item",name=name,
    icon=icon,icon_size=64,
    subgroup="razi-convergence-parts",
    order=order,stack_size=10,weight=200000,
    place_result=name}
end
local function array_radar(name,icon,energy,desc)
  local radar=table.deepcopy(data.raw.radar.radar)
  radar.name=name
  radar.icon=icon
  radar.icon_size=64
  radar.icons=nil
  radar.minable={mining_time=3,result=name}
  radar.max_distance_of_sector_revealed=0
  radar.max_distance_of_nearby_sector_revealed=0
  radar.energy_usage=energy
  radar.localised_name={"entity-name."..name}
  radar.localised_description={"entity-description."..name}
  -- Native radar graphics are retained; no borrowed third-party art.
  return radar
end
function M.data_final_fixes()
  local tech=data.raw.technology or {}
  local sync=tech["razi-convergence-synchronization"]
  local ignition=tech["razi-convergence-ignition"]
  if not (sync and ignition and data.raw.radar
    and data.raw.radar.radar
    and data.raw.recipe["razi-convergence-calidus-frame"]
    and data.raw.recipe["razi-convergence-outer-matrix"]
    and data.raw.recipe["razi-convergence-void-lens"])
    then return false end
  if tech["razi-convergence-witness-network"] then return false end
  local img="__base__/graphics/icons/radar.png"
  local anchor="razi-convergence-witness-anchor"
  local core="razi-convergence-array-core"
  local witness={
    type="technology",name="razi-convergence-witness-network",
    icon="__base__/graphics/technology/radar.png",icon_size=256,
    prerequisites={"razi-convergence-synchronization"},
    unit={count=3200,time=60,
      ingredients=table.deepcopy(sync.unit.ingredients)},
    effects={{type="unlock-recipe",recipe=anchor}},
    order="zz[razi-convergence]-witness",
    essential=true
  }
  ignition.prerequisites=ignition.prerequisites or {}
  local found=false
  for _,name in ipairs(ignition.prerequisites) do
    if name==witness.name then found=true break end
  end
  if not found then ignition.prerequisites[#ignition.prerequisites+1]=witness.name end
  ignition.effects[#ignition.effects+1]={
    type="unlock-recipe",recipe=core}
  local anchor_recipe=recipe(anchor,1,{
    {type="item",name="radar",amount=20},
    {type="item",name="processing-unit",amount=250},
    {type="item",name="low-density-structure",amount=150},
    {type="item",name="electric-engine-unit",amount=80},
    {type="item",name="steel-plate",amount=500}
  },90)
  local core_recipe=recipe(core,1,{
    {type="item",name="razi-convergence-calidus-frame",amount=8},
    {type="item",name="razi-convergence-outer-matrix",amount=8},
    {type="item",name="razi-convergence-void-lens",amount=4},
    {type="item",name="processing-unit",amount=500},
    {type="item",name="low-density-structure",amount=500}
  },180)
  data:extend({
    array_radar(anchor,img,"10MW","witness-anchor"),
    array_radar(core,img,"50MW","array-core"),
    item(anchor,img,"zz[convergence]-a"),
    item(core,img,"zz[convergence]-b"),
    anchor_recipe,core_recipe,witness
  })
  return true
end
return M
