-- One authoritative startup-mode reader for the planetary research links
-- and the interplanetary exchanges. Missing settings (including the small
-- Lua fixture environment) use the balanced behavior rather than silently
-- disabling progression.
local difficulty = require("scripts.razi_difficulty_presets")
local M = {}
function M.current()
  local value = difficulty.effective("razi-planetary-interdependence",
    "balanced")
  if value == "off" or value == "deep" then return value end
  return "balanced"
end
function M.enabled()
  return M.current() ~= "off"
end
-- Deep changes only the exchanges: larger physical imports and one more
-- component sink. Research links of the planets are the same as in Balanced.
function M.deep()
  return M.current() == "deep"
end
return M
