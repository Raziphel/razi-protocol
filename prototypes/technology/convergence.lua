-- Convergence's five real shipments use items and recipes already
-- supplied by the galaxy's mods. No RP3 mandate, frame, lens or core items.
local M = {}
M.commission = "razi-convergence-commission"
M.authorization = "razi-convergence-synchronization"
M.ignition = "razi-convergence-ignition"
-- All cargo is produced by source mods. Each stage requires several
-- independent native industries rather than a Razi-only assembly recipe.
-- Supplied amounts are expedition-wide totals, not per-craft ingredients.
M.shipments = {
  {id="stellar",item="slp-ds-satellite",count=24,supplies={
    {"holmium-plate",240},{"tungsten-plate",300},
    {"processing-unit",400},{"low-density-structure",400},
    {"superconductor",120},{"lithium-plate",180}}},
  {id="industry",item="kr-rare-metals",count=600,supplies={
    {"optical-cable",180},{"craptonite-frame",100},
    {"chitosan",160},{"zinc-plate",180},
    {"electric-coil",200},{"rare-earth-powder",180}}},
  {id="deep-space",item="promethium-science-pack",count=180,supplies={
    {"kr-cryogenic-research-data",120},
    {"kr-electromagnetic-research-data",120},
    {"kr-agricultural-research-data",120},
    {"planet-crucible-science-pack",100},
    {"pulsar-science-pack",100}}},
  {id="resonance",item="superconductor",count=400,supplies={
    {"supermagnet",160},{"gold-plate",220},
    {"kr-energy-control-unit",160},
    {"holmium-plate",240},{"lithium-plate",240}}},
  {id="ignition",item="kr-singularity-tech-card",count=120,supplies={
    {"deep-space-tech-card",100},
    {"calidus-tech-card",80},{"solaris-tech-card",80},
    {"nyxaris-tech-card",80},{"vibrant-tech-card",80},
    {"vespera-tech-card",80},{"beetlejuice-tech-card",80},
    {"umbra-tech-card",80},{"antimatter-science-pack",80}}}
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
local function tech(prototype,source,count)
  local unit=science_unit(source,count)
    or science_unit("slp-dyson-sphere",count)
    or science_unit("planet-discovery-aquilo",count)
  local art=icon_from("promethium-science-pack")
  if not (unit and art) then return end
  local result=table.deepcopy(prototype)
  result.unit=unit
  for key,value in pairs(art) do result[key]=value end
  return result
end
function M.data_final_fixes()
  local technology=data.raw.technology or {}
  if not active("razi-intergalactic-transceiver-signal")
    or not active("stellar-discovery-solar-system-edge")
    or technology[M.commission] or technology[M.authorization]
    or technology[M.ignition] then return end
  -- Only install stages whose complete native supply set exists.
  -- Missing items are reported rather than silently replaced by new crafts.
  for _,shipment in ipairs(M.shipments) do
    local cargo={shipment.item}
    for _,part in ipairs(shipment.supplies or {}) do
      cargo[#cargo+1]=part[1]
    end
    for _,name in ipairs(cargo) do
      if not icon_from(name) then
        if log then log("[RAZI Convergence] Missing native supply: "..name) end
        return
      end
    end
  end
  local begin=tech({
    type="technology",name="razi-convergence-commission",
    localised_name={"technology-name.razi-convergence-commission"},
    localised_description={"technology-description.razi-convergence-commission"},
    prerequisites={"stellar-discovery-solar-system-edge"},
    effects={},essential=true,order="zz[razi-convergence]-commission"
  },"stellar-discovery-solar-system-edge",2400)
  local sync=tech({
    type="technology",name="razi-convergence-synchronization",
    localised_name={"technology-name.razi-convergence-synchronization"},
    localised_description={"technology-description.razi-convergence-synchronization"},
    prerequisites={"razi-convergence-commission"},
    effects={},essential=true,order="zz[razi-convergence]-synchronization"
  },"stellar-discovery-solar-system-edge",4200)
  local ignition=tech({
    type="technology",name="razi-convergence-ignition",
    localised_name={"technology-name.razi-convergence-ignition"},
    localised_description={"technology-description.razi-convergence-ignition"},
    prerequisites={"razi-convergence-synchronization"},
    effects={},essential=true,order="zz[razi-convergence]-ignition"
  },"stellar-discovery-solar-system-edge",5000)
  if not (begin and sync and ignition) then return end
  data:extend({begin,sync,ignition})
  for _,prereq in ipairs({"slp-dyson-sphere","discovery-aegis-outer"}) do
    link(M.commission,prereq)
  end
  link(M.authorization,"promethium-science-pack")
  for _,prereq in ipairs({"slp-dyson-sphere-grounded","ds-energy-loader-mk2"}) do
    link(M.ignition,prereq)
  end
end
return M
