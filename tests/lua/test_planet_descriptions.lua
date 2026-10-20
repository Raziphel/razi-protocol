---@diagnostic disable: missing-fields
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, why)
  if not ok then error(why, 2) end
end
local native = {"source-mod.planet-description", "native-parameter"}
local planet = {
  nauvis = {localised_description = native},
  maraxsis = {},
  rabbasca = {localised_description = "A native moon description."},
  carna = {},
  skewer_shattered_planet = {},
  unrelated = {localised_description = "Keep this unchanged"}
}
local locations = {
  vespera = {}, ["sye-calidus"] = {},
  ["apia-carnova-orbit"] = {}, skewer_lost_beyond = {},
}
rawset(_G, "data", {raw = {planet = planet, ["space-location"] = locations}})
package.loaded["prototypes.system.planet_descriptions"] = nil
local descriptions = require("prototypes.system.planet_descriptions")
descriptions.data_final_fixes()

local function check_context(proto, expected_region, key)
  local value = proto.localised_description
  check(type(value) == "table" and value[1] == "", key .. ": description not composed")
  check(value[3][1] == "razi-expedition-heading." .. expected_region,
    key .. ": wrong frontier heading")
  check(value[5][1] == "razi-location-briefing." .. key,
    key .. ": wrong location briefing")
  return value
end
local nauvis = check_context(planet.nauvis, "calidus", "nauvis")
check(nauvis[2][2] == native, "Native localised description was replaced")
local moon = check_context(planet.rabbasca, "nyxaris", "rabbasca")
check(moon[2][2] == "A native moon description.", "Native moon lore was replaced")
for _, pair in ipairs({
  {planet.maraxsis, "vespera", "maraxsis"},
  {planet.carna, "umbra", "carna"},
  {locations.vespera, "vespera", "vespera"},
  {locations["sye-calidus"], "calidus", "sye-calidus"},
  {locations["apia-carnova-orbit"], "nyxaris", "apia-carnova-orbit"},
  {planet.skewer_shattered_planet, "deep-space", "skewer_shattered_planet"},
  {locations.skewer_lost_beyond, "deep-space", "skewer_lost_beyond"},
}) do
  local value = check_context(pair[1], pair[2], pair[3])
  check(value[2][1] == "?" and value[2][2][2][1] == "space-location-description." .. pair[3],
    pair[3] .. ": missing original-locale fallback")
end
check(planet.unrelated.localised_description == "Keep this unchanged",
  "Unrelated source world was modified")
local first = planet.nauvis.localised_description
descriptions.data_final_fixes()
check(planet.nauvis.localised_description == first,
  "Repeated final-fixes pass duplicated Razi context")

-- Turning off the optional description overlay leaves the source author's
-- wording intact on worlds that have not yet received Razi's context.
planet.muluna = {localised_description = "Original lunar expedition text"}
rawset(_G, "settings", {startup={
  ["razi-enable-expedition-briefings"] = {value = false}
}})
descriptions.data_final_fixes()
check(planet.muluna.localised_description == "Original lunar expedition text",
  "Disabled expedition briefings still overwrite planet descriptions")
rawset(settings.startup["razi-enable-expedition-briefings"], "value", true)
descriptions.data_final_fixes()
check_context(planet.muluna, "calidus", "muluna")
rawset(_G, "settings", nil)

-- Require the entrypoint to apply context after the final layout pass.
local f = assert(io.open("data-final-fixes.lua", "r"))
local source = f:read("*a")
f:close()
local layout = assert(source:find('require("prototypes.system.galaxy_layout").data_final_fixes()', 1, true))
local text = assert(source:find('require("prototypes.system.planet_descriptions").data_final_fixes()', 1, true))
check(text > layout, "Planet descriptions run before final layout")

-- All declared locale keys should exist in both supported languages.
local mod = assert(io.open("prototypes/system/planet_descriptions.lua", "r"))
local module_source = mod:read("*a")
mod:close()
for _, lang in ipairs({"en", "ru"}) do
  local file = assert(io.open("locale/" .. lang .. "/names.cfg", "r"))
  local locale = file:read("*a")
  file:close()
  for id in module_source:gmatch('"(.-)"') do
    if id:match("^[%l][%w%-_]+$") and
      (planet[id] or locations[id]) then
      check(locale:find("\n" .. id .. "=", 1, true),
        "No " .. lang .. " locale for " .. id)
    end
  end
end
print("Native descriptions, optional guards, locale and final-stage wiring passed")
