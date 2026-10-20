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
  },
  ["string-setting"] = {
    ["s6x-ii-krastorio-overlap-tech"] = { default_value = "ii", allowed_values = { "ii", "kr", "both" } },
  },
}
run(raw)
for _, name in ipairs({ "s6x-arcanyx-mythril-nuclear", "s6x-location-unlock", "s6x-prismite-on-nauvis", "s6x-colored-concrete", "adjust-maraxsis" }) do
  ---@type table
  local setting = raw["bool-setting"][name]
  check(setting.forced_value == false and setting.default_value == false and setting.hidden == true, name .. " not pinned to false")
end
---@type table
local overlap = raw["string-setting"]["s6x-ii-krastorio-overlap-tech"]
check(overlap.default_value == "kr" and #overlap.allowed_values == 1 and overlap.allowed_values[1] == "kr" and overlap.hidden == true,
  "Krastorio overlap setting not pinned to kr")

-- Only one of the settings present is enough.
local partial = { ["bool-setting"] = { ["s6x-arcanyx-mythril-nuclear"] = { default_value = true } } }
run(partial)
check(partial["bool-setting"]["s6x-arcanyx-mythril-nuclear"].forced_value == false, "Partial run must still pin the present setting")
check(partial["string-setting"] == nil, "Missing setting type must not be created")
rawset(_G, "data", nil)
print("ok")
