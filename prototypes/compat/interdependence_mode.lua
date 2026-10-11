-- One authoritative startup-mode reader shared by research and production.
-- Missing settings (including the small Lua fixture environment) use the
-- existing balanced behavior rather than silently disabling progression.
local M = {}
function M.current()
  local setting = settings and settings.startup
    and settings.startup["razi-planetary-interdependence"]
  local value = setting and setting.value or "balanced"
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
