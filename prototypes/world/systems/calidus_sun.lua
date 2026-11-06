-- Calidus owns a warm yellow main-sequence star. Keep it visually distinct
-- from Solaris's red-orange giant while retaining the same 1024px quality.
local M={}
local STAR="__razi-protocol__/graphics/icons/CalidusStar.png"
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
    log("[Razi Protocol/Calidus] Dedicated yellow stellar art registered (1024px)")
  end
  return true
end
return M
