-- One authoritative startup-mode reader for the planetary research links.
-- Missing settings (including the small Lua fixture environment) use the
-- balanced behavior rather than silently disabling progression.
local M = {}
function M.current()
  local setting = settings and settings.startup
    and settings.startup["razi-planetary-interdependence"]
  local value = setting and setting.value or "balanced"
  if value == "off" then return value end
  return "balanced"
end
function M.enabled()
  return M.current() ~= "off"
end
return M
