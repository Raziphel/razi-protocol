-- Razi Protocol optional early startup-settings host, v1.1.
-- Leave runtime-global and per-user settings owned by the gameplay mod.
if not mods["razi-protocol"] then return end

local key = "__razi_protocol_settings_export"
local previous = rawget(_G, key)
rawset(_G, key, true)
local ok, definitions = pcall(require, "__razi-protocol__/settings")
rawset(_G, key, previous)

if not ok or type(definitions) ~= "table" then
  error("Razi Protocol settings companion could not import settings: "
    .. tostring(definitions))
end

local startup = {}
local seen = {}
for _, entry in ipairs(definitions) do
  if entry.setting_type == "startup" then
    assert(type(entry.name) == "string" and not seen[entry.name],
      "Duplicate or invalid Razi startup setting")
    seen[entry.name] = true
    startup[#startup + 1] = entry
  end
end
assert(#startup > 0, "Razi Protocol did not export startup settings")
data:extend(startup)
