-- Native-only witness milestone: no manufactured anchors or array core.
local M = {}
function M.data_final_fixes()
  local techs=data.raw.technology or {}
  local sync=techs["razi-convergence-synchronization"]
  local ignition=techs["razi-convergence-ignition"]
  if not (sync and ignition and sync.unit and sync.unit.ingredients)
    or techs["razi-convergence-witness-network"] then return false end
  local source=(data.raw.technology or {})["radar"] or sync
  local node={
    type="technology",name="razi-convergence-witness-network",
    localised_name={"technology-name.razi-convergence-witness-network"},
    localised_description={"technology-description.razi-convergence-witness-network"},
    icon=source.icon or "__base__/graphics/technology/radar.png",
    icons=source.icons and table.deepcopy(source.icons) or nil,
    icon_size=source.icon_size or 256,
    prerequisites={"razi-convergence-synchronization"},
    unit=table.deepcopy(sync.unit),effects={},essential=true,
    order="zz[razi-convergence]-witness"
  }
  node.unit.count=3200
  node.unit.count_formula=nil
  data:extend({node})
  local dyson=require("prototypes.compat.calidus_dyson")
  dyson.safe_link("razi-convergence-ignition",node.name)
  return true
end
return M
