-- Convergence's five real shipments use items and recipes already
-- supplied by the galaxy's mods. No RP3 mandate, frame, lens or core items.
local M = {}
M.commission = "razi-convergence-commission"
M.authorization = "razi-convergence-synchronization"
M.ignition = "razi-convergence-ignition"
M.shipments = {
  {id="stellar", item="slp-ds-satellite", count=24},
  {id="industry", item="kr-rare-metals", count=600},
  {id="deep-space", item="promethium-science-pack", count=180},
  {id="resonance", item="superconductor", count=400},
  {id="ignition", item="kr-singularity-tech-card", count=120}
}
M.assemblies = {}

local function active(name)
  local tech = (data.raw.technology or {})[name]
  return tech and tech.enabled~=false and tech.hidden~=true
end
local function link(target, parent)
  local dyson=require("prototypes.compat.calidus_dyson")
  dyson.safe_link(target,parent)
end
local function icon_from(name)
  local source=(data.raw.tool or {})[name] or (data.raw.item or {})[name]
  if not source then return end
  if source.icons then
    return {icons=table.deepcopy(source.icons),icon_size=source.icon_size}
  end
  return {icon=source.icon,icon_size=source.icon_size or 64}
end
local function science_unit(source, count)
  local tech=(data.raw.technology or {})[source]
  if not (tech and tech.unit and tech.unit.ingredients
    and #tech.unit.ingredients>0) then return nil end
  local unit=table.deepcopy(tech.unit)
  unit.count=count
  unit.count_formula=nil
  return unit
end
local function tech(name,source,prereqs,count)
  local unit=science_unit(source,count)
  local art=icon_from("promethium-science-pack")
  if not (unit and art) then return end
  local result={
    type="technology",name=name,
    localised_name={"technology-name."..name},
    localised_description={"technology-description."..name},
    prerequisites=prereqs,unit=unit,effects={},essential=true,
    order="zz[razi-convergence]-"..name
  }
  for key,value in pairs(art) do result[key]=value end
  return result
end
function M.data_final_fixes()
  local technology=data.raw.technology or {}
  if not active("razi-intergalactic-transceiver-signal")
    or not active("stellar-discovery-solar-system-edge")
    or technology[M.commission] or technology[M.authorization]
    or technology[M.ignition] then return end
  -- No substitute items: every cargo must be an existing source product.
  for _,shipment in ipairs(M.shipments) do
    if not icon_from(shipment.item) then
      if log then log("[RAZI Convergence] Missing native cargo: "..shipment.item) end
      return
    end
  end
  local begin=tech(M.commission,"stellar-discovery-solar-system-edge",
    {"stellar-discovery-solar-system-edge"},2400)
  local sync=tech(M.authorization,"stellar-discovery-solar-system-edge",
    {M.commission},4200)
  local ignition=tech(M.ignition,"stellar-discovery-solar-system-edge",
    {M.authorization},5000)
  if not (begin and sync and ignition) then return end
  data:extend({begin,sync,ignition})
  for _,prereq in ipairs({"slp-dyson-sphere","discovery-aegis-outer"}) do
    link(M.commission,prereq)
  end
  for _,prereq in ipairs({"promethium-science-pack","razi-network-extreme-lattice"}) do
    link(M.authorization,prereq)
  end
  for _,prereq in ipairs({"slp-dyson-sphere-grounded","ds-energy-loader-mk2"}) do
    link(M.ignition,prereq)
  end
end
return M
