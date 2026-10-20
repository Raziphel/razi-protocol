---@diagnostic disable: missing-fields
-- The grouped startup headings are localized, not extra dummy settings.
-- Guard the actual names/defaults/order used by existing saves and startup.
local function check(value, why)
  if not value then error(why, 2) end
end

local definitions = {}
rawset(_G, "data", {
  extend = function(_, entries)
    for _, entry in ipairs(entries) do
      check(not definitions[entry.name], "Duplicate mod setting: " .. entry.name)
      definitions[entry.name] = entry
    end
  end
})
dofile("settings.lua")

local expected = {
  {"razi-enable-enemy-routing", "aa[worlds]-a[enemy-routing]", "yellow"},
  {"razi-planetary-interdependence",
    "ba[integration]-0[interdependence]", "cyan"},
  {"razi-enable-k2so-production-exchanges",
    "ba[integration]-a[k2so-exchanges]", "cyan"},
  {"razi-enable-modded-planet-exchanges",
    "ba[integration]-b[modded-planets]", "cyan"},
  {"razi-hide-redundant-assembler-tiers",
    "ca[quality-of-life]-a[redundant-assemblers]", "green"},
  {"razi-enable-expedition-briefings",
    "ca[quality-of-life]-b[expedition-briefings]", "green"}
}
local number = 0
for _ in pairs(definitions) do number = number + 1 end
check(number >= #expected, "Settings should retain real legacy controls")

local previous_order = ""
for _, spec in ipairs(expected) do
  local name, order, color = spec[1], spec[2], spec[3]
  local setting = assert(definitions[name], "Missing setting: " .. name)
  if name == "razi-planetary-interdependence" then
    check(rawget(setting, "type") == "string-setting"
      and rawget(setting, "default_value") == "balanced",
      "Interdependence must default to the original balanced behavior")
    local allowed = table.concat(setting.allowed_values or {}, ",")
    check(allowed == "off,balanced,deep", "Invalid interdependence modes")
  else
    check(rawget(setting, "type") == "bool-setting", "Not a boolean: " .. name)
    check(rawget(setting, "default_value") == true,
      "Existing behavior no longer default: " .. name)
  end
  check(rawget(setting, "setting_type") == "startup", "Startup mode changed: " .. name)
  check(rawget(setting, "order") == order and order > previous_order,
    "Color-coded settings section order is unstable: " .. name)
  check(not rawget(setting, "hidden") and not rawget(setting, "forced_value"),
    "A displayed setting was accidentally hidden or forced")
  previous_order = order

  for _, language in ipairs({"en", "ru"}) do
    local file = assert(io.open("locale/" .. language .. "/settings.cfg", "r"))
    local raw = file:read("*a")
    file:close()
    local section = raw:match("%[mod%-setting%-name%]%s*(.-)%[mod%-setting%-description%]")
    check(section, "Missing localized setting names: " .. language)
    local matching_name
    section = section:match("^(.-)%[string%-mod%-setting%]") or section
  for line in section:gmatch("[^\n]+") do
      if line:sub(1, #name + 1) == name .. "=" then
        check(not matching_name, "Duplicate locale entry: " .. name)
        matching_name = line:sub(#name + 2)
      end
    end
    check(matching_name, "Missing translated setting label: " .. name)
    local label = tostring(matching_name)
    check(label:find("[color=" .. color .. "][font=heading-2]", 1, true),
      "Missing matching color and large heading: " .. language .. " " .. name)
    check(label:find("[/font][/color] ", 1, true),
      "Heading not closed before setting label: " .. name)
    local description = raw:match("%[mod%-setting%-description%]%s*(.*)")
    check(description and ("\n" .. description):find("\n" .. name .. "=", 1, true),
      "Missing setting explanation: " .. language .. " " .. name)
    check(description:find(
      language == "en" and "[color=red]RECOMMENDED[/color]"
        or "[color=red]РЕКОМЕНДУЕТСЯ[/color]", 1, true),
      "Missing recommendation marker: " .. language)
  end
end

-- Keep all colors coherent per semantic group in every translation.
for _, language in ipairs({"en", "ru"}) do
  local file = assert(io.open("locale/" .. language .. "/settings.cfg", "r"))
  local raw = file:read("*a")
  file:close()
  local names = {}
  local section = raw:match("%[mod%-setting%-name%]%s*(.-)%[mod%-setting%-description%]")
  section = section:match("^(.-)%[string%-mod%-setting%]") or section
  for line in section:gmatch("[^\n]+") do
    local name = line:match("^([^=]+)=")
    if name then
      check(definitions[name], "Orphaned setting locale: " .. name)
      check(not names[name], "Duplicated localized label: " .. name)
      names[name] = true
    end
  end
  if language == "en" then
    for key in pairs(definitions) do
      check(names[key], "A setting is missing its English label: " .. key)
    end
  end
end
print("Localized grouped Razi settings and unchanged defaults passed")
