-- The other Razi stellar giants already use detailed 1024px textures.
-- Share the original Solaris-style blazing star for the home system rather
-- than introducing a low-resolution, low-contrast orange disk.
local M={}
local STAR="__razi-protocol__/graphics/icons/SolarisStar.png"
function M.data_updates()
  local source=(data.raw["space-location"] or {}).star
  if not source then
    if type(log)=="function" then
      log("[Razi Protocol/Calidus] Central source star missing; using native art")
    end
    return false
  end
  source.starmap_icon=STAR
  source.starmap_icon_size=1024
  -- Do not write magnitude, distance, orientation, origin or solar-power.
  if type(log)=="function" then
    log("[Razi Protocol/Calidus] High-resolution stellar art registered (Solaris family, 1024px)")
  end
  return true
end
return M
