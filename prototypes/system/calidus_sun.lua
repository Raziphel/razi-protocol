-- Calidus source sun uses PlanetsLib's star sprite-only registration.
-- Replace its file before PlanetsLib bakes its native starmap layers.
local M={}
local STAR="__razi-protocol__/graphics/starmap/razi/calidus-star.png"
function M.data_updates()
  local source=(data.raw["space-location"] or {}).star
  if not source then
    if type(log)=="function" then
      log("[Razi Protocol/Calidus] WARNING: source star is missing; new artwork not applied")
    end
    return false
  end
  source.starmap_icon=STAR
  source.starmap_icon_size=256
  -- Magnitude controls the sprite's rendered size in PlanetsLib. Preserve
  -- the original angular prominence, route coordinates and all gameplay.
  source.magnitude=source.magnitude or 8
  if type(log)=="function" then
    log("[Razi Protocol/Calidus] Registered golden Calidus sun before PlanetsLib rendering")
  end
  return true
end
return M
