---@diagnostic disable: missing-fields, lowercase-global
package.path = "./?.lua;./?/init.lua;" .. package.path
local function check(ok, why) if not ok then error(why, 2) end end

local function run(raw)
  rawset(_G, "data", { raw = raw })
  dofile("settings-final-fixes.lua")
end

-- Without the mods nothing is created and nothing fails.
run({})
run({ ["bool-setting"] = {}, ["string-setting"] = {} })

-- With the mods the settings are pinned and hidden.
---@type table
local raw = {
  ["bool-setting"] = {
    ["s6x-arcanyx-mythril-nuclear"] = { default_value = true },
    ["s6x-location-unlock"] = { default_value = false },
    ["s6x-prismite-on-nauvis"] = { default_value = false },
    ["s6x-colored-concrete"] = { default_value = true },
    ["adjust-maraxsis"] = { default_value = true },
    ["bm-armored-biters-override"] = { default_value = true },
    ["nulla-vanila-science"] = { default_value = true },
    ["nulla-science-promethium"] = { default_value = true },
    ["crushing-industry-k2"] = { default_value = true },
    ["crushing-industry-glass"] = { default_value = true },
    ["crushing-industry-optical-fiber"] = { default_value = true },
    ["crushing-industry-concrete-mix"] = { default_value = true },
    ["crushing-industry-ore"] = { default_value = true },
    ["rigor-module-compatibility-mode"] = { default_value = false },
    ["rigor-module-compatibility-mode-include-vanilla"] = { default_value = true },
    ["rigor-module-disable-rigor-effect"] = { default_value = false },
  },
  ["string-setting"] = {
    ["s6x-ii-krastorio-overlap-tech"] = { default_value = "ii", allowed_values = { "ii", "kr", "both" } },
  },
}
run(raw)
for _, name in ipairs({ "s6x-arcanyx-mythril-nuclear", "s6x-location-unlock", "s6x-prismite-on-nauvis", "s6x-colored-concrete", "adjust-maraxsis", "bm-armored-biters-override",
  "nulla-vanila-science", "crushing-industry-k2", "crushing-industry-glass", "crushing-industry-optical-fiber", "crushing-industry-concrete-mix" }) do
  ---@type table
  local setting = raw["bool-setting"][name]
  check(setting.forced_value == false and setting.default_value == false and setting.hidden == true, name .. " not pinned to false")
end
---@type table
local overlap = raw["string-setting"]["s6x-ii-krastorio-overlap-tech"]
check(overlap.default_value == "kr" and #overlap.allowed_values == 1 and overlap.allowed_values[1] == "kr" and overlap.hidden == true,
  "Krastorio overlap setting not pinned to kr")

-- Rigor Module runs in compatibility mode with the vanilla recipes included, to stay under the recipe limit.
for _, name in ipairs({ "rigor-module-compatibility-mode", "rigor-module-compatibility-mode-include-vanilla" }) do
  ---@type table
  local setting = raw["bool-setting"][name]
  check(setting.forced_value == true and setting.default_value == true and setting.hidden == true, name .. " not pinned to true")
end

-- The other settings of Nulla and Crushing Industry keep their defaults and stay visible.
for _, name in ipairs({ "nulla-science-promethium", "crushing-industry-ore" }) do
  ---@type table
  local setting = raw["bool-setting"][name]
  check(setting.default_value == true and setting.forced_value == nil and setting.hidden == nil, name .. " must stay untouched")
end

-- The other settings of Rigor Module stay as they are.
---@type table
local rigor_effect = raw["bool-setting"]["rigor-module-disable-rigor-effect"]
check(rigor_effect.default_value == false and rigor_effect.forced_value == nil and rigor_effect.hidden == nil,
  "rigor-module-disable-rigor-effect must stay untouched")

-- Only one of the settings present is enough.
local partial = { ["bool-setting"] = { ["s6x-arcanyx-mythril-nuclear"] = { default_value = true } } }
run(partial)
check(partial["bool-setting"]["s6x-arcanyx-mythril-nuclear"].forced_value == false, "Partial run must still pin the present setting")
check(partial["string-setting"] == nil, "Missing setting type must not be created")
rawset(_G, "data", nil)
print("ok")
