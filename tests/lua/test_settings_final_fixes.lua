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

-- With the mods the settings are adjusted according to compatibility rules.
---@type table
local raw = {
  ["bool-setting"] = {
    ["s6x-arcanyx-mythril-nuclear"] = { default_value = true },
    ["s6x-location-unlock"] = { default_value = false },
    ["s6x-prismite-on-nauvis"] = { default_value = false },
    ["s6x-colored-concrete"] = { default_value = true },
    ["adjust-maraxsis"] = { default_value = true },
    ["bm-armored-biters-override"] = { default_value = true },
    ["si-disable-inserters-consumption"] = { default_value = false },
    ["si-disable-long-inserters"] = { default_value = false },
    ["si-range-technologies"] = { default_value = false },
    ["si-diagonal-technologies"] = { default_value = false },
    ["si-offset-technologies"] = { default_value = false },
    ["si-inserters-chase-belt-items"] = { default_value = true },
    ["nulla-vanila-science"] = { default_value = true },
    ["nulla-science-promethium"] = { default_value = true },
    ["crushing-industry-k2"] = { default_value = true },
    ["crushing-industry-glass"] = { default_value = true },
    ["crushing-industry-optical-fiber"] = { default_value = true },
    ["crushing-industry-concrete-mix"] = { default_value = true },
    ["crushing-industry-space-crusher-quality"] = { default_value = true },
    ["crushing-industry-ore"] = { default_value = true },
    ["crushing-industry-coal"] = { default_value = true },
    ["rigor-module-compatibility-mode"] = { default_value = false },
    ["rigor-module-compatibility-mode-include-vanilla"] = { default_value = true },
    ["rigor-module-disable-rigor-effect"] = { default_value = false },
    ["s6x-arcanyx-voidcraft"] = { default_value = false },
    ["s6x-no-voidcraft-in-space"] = { default_value = false },
    ["s6x-voidcraft-science"] = { default_value = false },
    ["RTThrowersSetting"] = { default_value = true },
    ["RTBounceSetting"] = { default_value = false },
    ["RTTrainRampSetting"] = { default_value = true },
    ["bzzirconium-early"] = { default_value = true },
    ["vehicle-wagon-use-custom-weights"] = { default_value = true },
    ["RTZiplineSetting"] = { default_value = true },
    ["override_krastorio_endgame"] = { default_value = true },
    ["el_ki_same_surface"] = { default_value = false },
    ["rsc-st-not-removable-site"] = { default_value = false },
    ["real-smoke-events"] = { default_value = true },
  },
  ["double-setting"] = {
    ["rsc-st-power-mp"] = { default_value = 1, minimum_value = 0.25, maximum_value = 3 },
    ["rsc-st-cost-mp"] = { default_value = 1, minimum_value = 0.5, maximum_value = 100 },
  },
  ["string-setting"] = {
    ["s6x-ii-krastorio-overlap-tech"] = { default_value = "ii", allowed_values = { "ii", "kr", "both" } },
    ["si-range-adder"] = {
      default_value = "equal",
      allowed_values = { "inserter", "incremental", "equal", "rebase", "incremental-with-rebase", "inserter-with-rebase" },
    },
    ["bzlead-recipe-bypass"] = { default_value = "" },
    ["bztitanium-recipe-bypass"] = { default_value = "" },
    ["bztin-recipe-bypass"] = { default_value = "" },
    ["bzzirconium-recipe-bypass"] = { default_value = "" },
    ["bzcarbon-recipe-bypass"] = { default_value = "" },
    ["bzsilicon-recipe-bypass"] = { default_value = "" },
    ["bzlead-more-entities"] = { default_value = "yes", allowed_values = { "yes", "no" } },
  },
}
run(raw)
for _, name in ipairs({ "s6x-arcanyx-mythril-nuclear", "s6x-location-unlock", "s6x-prismite-on-nauvis", "s6x-colored-concrete", "adjust-maraxsis", "bm-armored-biters-override",
  "nulla-vanila-science", "crushing-industry-k2", "crushing-industry-glass", "crushing-industry-optical-fiber", "crushing-industry-concrete-mix",
  "crushing-industry-space-crusher-quality" }) do
  ---@type table
  local setting = raw["bool-setting"][name]
  check(setting.forced_value == false and setting.default_value == false and setting.hidden == true, name .. " not pinned to false")
end
---@type table
local bz_early = raw["bool-setting"]["bzzirconium-early"]
check(bz_early.default_value == false and bz_early.forced_value == false and bz_early.hidden == true,
  "bzzirconium-early must be pinned to false")
---@type table
local ki_same_surface = raw["bool-setting"]["el_ki_same_surface"]
check(ki_same_surface.default_value == true and ki_same_surface.forced_value == nil and ki_same_surface.hidden ~= true,
  "el_ki_same_surface must default to true and stay visible to the player")
---@type table
local override_krastorio_endgame = raw["bool-setting"]["override_krastorio_endgame"]
check(override_krastorio_endgame.default_value == true and override_krastorio_endgame.forced_value == nil and override_krastorio_endgame.hidden ~= true,
  "override_krastorio_endgame must keep the 248k Redux default and stay visible to the player")
---@type table
local overlap = raw["string-setting"]["s6x-ii-krastorio-overlap-tech"]
check(overlap.default_value == "kr" and #overlap.allowed_values == 1 and overlap.allowed_values[1] == "kr" and overlap.hidden == true,
  "Krastorio overlap setting not pinned to kr")

-- Smart Inserters starts with vectors available, keeps long inserters and power use, and chases belt items.
for _, name in ipairs({ "si-disable-inserters-consumption", "si-disable-long-inserters", "si-range-technologies",
  "si-diagonal-technologies", "si-offset-technologies" }) do
  ---@type table
  local setting = raw["bool-setting"][name]
  check(setting.default_value == false and setting.forced_value == false and setting.hidden == true,
    name .. " not pinned to false")
end
---@type table
local chase_belt_items = raw["bool-setting"]["si-inserters-chase-belt-items"]
check(chase_belt_items.default_value == true and chase_belt_items.forced_value == true and chase_belt_items.hidden == true,
  "si-inserters-chase-belt-items not pinned to true")
---@type table
local range_adder = raw["string-setting"]["si-range-adder"]
check(range_adder.default_value == "inserter" and #range_adder.allowed_values == 1
  and range_adder.allowed_values[1] == "inserter" and range_adder.hidden == true,
  "si-range-adder not pinned to inserter")

local bz_recipe_bypass = "pipe,pipe-to-ground,electronic-circuit,advanced-circuit,processing-unit,steel-plate,space-platform-foundation,sulfuric-acid,plastic-bar,scrap-recycling"
for _, name in ipairs({ "bzlead-recipe-bypass", "bztitanium-recipe-bypass", "bztin-recipe-bypass", "bzzirconium-recipe-bypass", "bzcarbon-recipe-bypass", "bzsilicon-recipe-bypass" }) do
  ---@type table
  local setting = raw["string-setting"][name]
  check(setting.default_value == bz_recipe_bypass and #setting.allowed_values == 1 and setting.allowed_values[1] == bz_recipe_bypass and setting.hidden == true,
    name .. " not pinned to the shared bypass list")
end
---@type table
local bzlead_entities = raw["string-setting"]["bzlead-more-entities"]
-- Foliax 3.0.13 copies the expansion bolt with its own iron, so the player's choice stays.
check(bzlead_entities.default_value == "yes" and #bzlead_entities.allowed_values == 2 and not bzlead_entities.hidden,
  "bzlead-more-entities must stay the player's choice")

---@type table
local non_removable_site = raw["bool-setting"]["rsc-st-not-removable-site"]
check(non_removable_site.default_value == true and non_removable_site.forced_value == true and non_removable_site.hidden == true,
  "RSC construction sites must stay non-removable")
for name, value in pairs({ ["rsc-st-power-mp"] = 0.5, ["rsc-st-cost-mp"] = 1 }) do
  ---@type table
  local setting = raw["double-setting"][name]
  check(setting.default_value == value and #setting.allowed_values == 1 and setting.allowed_values[1] == value
      and setting.hidden == true and setting.forced_value == nil, name .. " not pinned to its configured value")
end

-- Rigor Module runs in compatibility mode with the vanilla recipes included, to stay under the recipe limit.
for _, name in ipairs({ "rigor-module-compatibility-mode", "rigor-module-compatibility-mode-include-vanilla" }) do
  ---@type table
  local setting = raw["bool-setting"][name]
  check(setting.forced_value == true and setting.default_value == true and setting.hidden == true, name .. " not pinned to true")
end

-- Ribbonia needs the throwers, bounce plates and train ramps of Renai Transportation; its other parts stay optional.
for _, name in ipairs({ "RTThrowersSetting", "RTBounceSetting", "RTTrainRampSetting" }) do
  ---@type table
  local setting = raw["bool-setting"][name]
  check(setting.forced_value == true and setting.default_value == true and setting.hidden == true, name .. " not pinned to true")
end
---@type table
local vehicle_wagon_weights = raw["bool-setting"]["vehicle-wagon-use-custom-weights"]
check(vehicle_wagon_weights.forced_value == true and vehicle_wagon_weights.hidden == true,
  "vehicle-wagon-use-custom-weights must be pinned to true")
---@type table
local zipline = raw["bool-setting"]["RTZiplineSetting"]
check(zipline.forced_value == nil and zipline.hidden == nil, "RTZiplineSetting must stay untouched")

-- Voidcraft runs only on Arcanyx; its other settings stay visible and at their defaults.
---@type table
local arcanyx_voidcraft = raw["bool-setting"]["s6x-arcanyx-voidcraft"]
check(arcanyx_voidcraft.forced_value == true and arcanyx_voidcraft.default_value == true and arcanyx_voidcraft.hidden == true,
  "s6x-arcanyx-voidcraft not pinned to true")
for _, name in ipairs({ "s6x-no-voidcraft-in-space", "s6x-voidcraft-science" }) do
  ---@type table
  local setting = raw["bool-setting"][name]
  check(setting.default_value == false and setting.forced_value == nil and setting.hidden == nil, name .. " must stay untouched")
end

-- The other settings of Nulla and Crushing Industry keep their defaults and stay visible.
for _, name in ipairs({ "nulla-science-promethium", "crushing-industry-ore" }) do
  ---@type table
  local setting = raw["bool-setting"][name]
  check(setting.default_value == true and setting.forced_value == nil and setting.hidden == nil, name .. " must stay untouched")
end
---@type table
local crushing_coal = raw["bool-setting"]["crushing-industry-coal"]
check(crushing_coal.default_value == false and crushing_coal.forced_value == nil and crushing_coal.hidden == nil,
  "crushing-industry-coal must default to off and stay visible to the player")

-- Real Smoke's death smoke is off by default because of asteroids; the player may turn it on.
---@type table
local real_smoke_events = raw["bool-setting"]["real-smoke-events"]
check(real_smoke_events.default_value == false and real_smoke_events.forced_value == nil and real_smoke_events.hidden == nil,
  "real-smoke-events must default to off and stay visible to the player")

-- The other settings of Rigor Module stay as they are.
---@type table
local rigor_effect = raw["bool-setting"]["rigor-module-disable-rigor-effect"]
check(rigor_effect.default_value == false and rigor_effect.forced_value == nil and rigor_effect.hidden == nil,
  "rigor-module-disable-rigor-effect must stay untouched")

-- Nexus shows its limit frame only with the core in hand by default; the player may still change it.
-- The Big-Monsters camera settings, which end the game when changed, are hidden.
local foreign = {
  ["bool-setting"] = {
    ["nexus-limit-frame-in-hand-only"] = { default_value = false },
    ["bm_draggable_camera"] = { default_value = false },
  },
  ["int-setting"] = { ["bm_camera_size"] = { default_value = 300 } },
}
run(foreign)
---@type table
local limit_frame = foreign["bool-setting"]["nexus-limit-frame-in-hand-only"]
check(limit_frame.default_value == true and limit_frame.forced_value == nil and limit_frame.hidden == nil,
  "nexus-limit-frame-in-hand-only must default to on and stay visible")
---@type table
local drag = foreign["bool-setting"]["bm_draggable_camera"]
---@type table
local size = foreign["int-setting"]["bm_camera_size"]
check(drag.hidden == true and drag.default_value == false and size.hidden == true and size.default_value == 300,
  "Big-Monsters camera settings must be hidden with their defaults")

-- Only one of the settings present is enough.
local partial = { ["bool-setting"] = { ["s6x-arcanyx-mythril-nuclear"] = { default_value = true } } }
run(partial)
check(partial["bool-setting"]["s6x-arcanyx-mythril-nuclear"].forced_value == false, "Partial run must still pin the present setting")
check(partial["string-setting"] == nil, "Missing setting type must not be created")
check(partial["double-setting"] == nil, "Missing double-setting type must not be created")
rawset(_G, "data", nil)
print("ok")
