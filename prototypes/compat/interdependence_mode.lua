-- One authoritative startup-mode reader shared by research and production.
-- Missing settings (including the small Lua fixture environment) use the
-- existing balanced behavior rather than silently disabling progression.
local M = {}
function M.current()
  local value=require("scripts.razi_difficulty_presets")
    .effective("razi-planetary-interdependence","balanced")
  if value == "off" or value == "deep" then return value end
  return "balanced"
end
function M.enabled()
  return M.current() ~= "off"
end
function M.deep()
  return M.current() == "deep"
end
return M
