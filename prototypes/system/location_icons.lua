-- Razi-owned special-location artwork only. No changes to gameplay, travel or orbit data.
local M={}
M.icons={
  ["sye-calidus"]="__razi-protocol__/graphics/icons/navigation/calidus-gate.png",
  ["sye-solaris"]="__razi-protocol__/graphics/icons/navigation/solaris-gate.png",
  ["sye-nyxaris"]="__razi-protocol__/graphics/icons/navigation/nyxaris-gate.png",
  ["sye-vibrant"]="__razi-protocol__/graphics/icons/navigation/vibrant-gate.png",
  ["sye-vespera"]="__razi-protocol__/graphics/icons/navigation/vespera-gate.png",
  ["sye-beetlejuice"]="__razi-protocol__/graphics/icons/navigation/beetlejuice-gate.png",
  ["sye-umbra"]="__razi-protocol__/graphics/icons/navigation/umbra-gate.png",
  ["asteroid-belt-inner-edge"]="__razi-protocol__/graphics/icons/navigation/vibrant-rim-inner.png",
  ["asteroid-belt-outer-edge"]="__razi-protocol__/graphics/icons/navigation/vibrant-rim-outer.png",
  ["razi-umbra-belt-inner"]="__razi-protocol__/graphics/icons/navigation/umbra-rim-inner.png",
  ["razi-umbra-belt-outer"]="__razi-protocol__/graphics/icons/navigation/umbra-rim-outer.png",
}
function M.data_final_fixes()
  for id,asset in pairs(M.icons) do
    local location=(data.raw["space-location"] or {})[id]
    if location then
      location.icon=asset
      location.icon_size=64
      location.starmap_icon=asset
      location.starmap_icon_size=64
    end
  end
end
return M
