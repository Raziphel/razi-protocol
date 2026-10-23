-- HELIOS integrates the original Dyson Sphere research and hardware.
-- Do not invent duplicate components, recipe chains, or satellite costs.
local M = {}
local dyson = require("prototypes.compat.calidus_dyson")
local difficulty = require("scripts.razi_difficulty_presets")

function M.data_final_fixes()
  if not (mods and mods["slp-dyson-sphere-reworked-fork"])
    or difficulty.effective("razi-helios-progression", "late") == "legacy"
    or difficulty.effective("razi-helios-construction", "satellites") == "off"
  then return false end

  -- All targets are source-owned technologies, with their source recipes
  -- and original manufacturing chains left completely intact.
  dyson.safe_link("slp-dyson-sphere", "planet-discovery-sunorbit")
  dyson.safe_link("slp-dyson-sphere", "moon-discovery-cerys")
  dyson.safe_link("slp-dyson-sphere-grounded", "slp-dyson-sphere")
  dyson.safe_link("ds-energy-loader-mk3", "slp-dyson-sphere-grounded")
  return true
end

-- Retained API for compatibility with data-final-fixes.lua.
-- Native satellites should never require fabricated Razi intermediates.
function M.reinforce_satellites() return 0 end

return M
