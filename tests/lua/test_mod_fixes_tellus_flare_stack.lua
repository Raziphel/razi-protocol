---@diagnostic disable: missing-fields
-- The magnesium sheet of Tellus takes productivity (prototypes/fixes/planetaris-tellus/magnesium_productivity.lua) and
-- the flaring recipes of Flare Stack pollute as their fluid (prototypes/fixes/flare_stack/flaring_emissions.lua), on a
-- mocked data.raw.
package.path = "./?.lua;./?/init.lua;" .. package.path
local support = require("tests.lua.loops_support")
local check = support.check

local magnesium = require("prototypes.fixes.planetaris-tellus.magnesium_productivity")
local flaring = require("prototypes.fixes.flare_stack.flaring_emissions")

local function install(raw)
	support.logs = {}
	rawset(_G, "data", {raw = raw})
	return raw
end

-- magnesium sheet
local raw = install({recipe = {["planetaris-magnesium-sheet"] = {}}})
magnesium.data_final_fixes()
check(raw.recipe["planetaris-magnesium-sheet"].allow_productivity == true, "The magnesium sheet takes productivity")
check(#support.logs == 1 and support.logs[1]:find("^razi%-protocol: "), "One line for the change")
magnesium.data_final_fixes()
check(#support.logs == 1, "A second run changes nothing")
raw = install({recipe = {["planetaris-magnesium-sheet"] = {allow_productivity = false}}})
magnesium.data_final_fixes()
check(raw.recipe["planetaris-magnesium-sheet"].allow_productivity == false and #support.logs == 0,
	"A value written by a mod stays")
install({recipe = {}})
magnesium.data_final_fixes()
check(#support.logs == 0, "No Tellus, no change")

-- flaring
raw = install({
	fluid = {
		["crude-oil"] = {emissions_multiplier = 3},
		["ethanol"] = {emissions_multiplier = 0.25},
		["water"] = {},
		["oxygen"] = {emissions_multiplier = 2},
		["lubricant"] = {emissions_multiplier = 1},
		["no-flare"] = {emissions_multiplier = 5},
	},
	recipe = {
		["crude-oil-flaring"] = {emissions_multiplier = 1},
		["ethanol-flaring"] = {emissions_multiplier = 1},
		["water-flaring"] = {emissions_multiplier = 0},
		["oxygen-flaring"] = {emissions_multiplier = 0},
		["lubricant-flaring"] = {emissions_multiplier = 1},
	},
})
flaring.data_final_fixes()
check(raw.recipe["crude-oil-flaring"].emissions_multiplier == 3, "Crude oil flares at 3")
check(raw.recipe["ethanol-flaring"].emissions_multiplier == 0.25, "Ethanol flares at 0.25")
check(raw.recipe["oxygen-flaring"].emissions_multiplier == 0, "A zero of Flare Stack stays")
check(raw.recipe["water-flaring"].emissions_multiplier == 0, "Water stays at 0")
check(raw.recipe["lubricant-flaring"].emissions_multiplier == 1, "A fluid at 1 stays")
check(support.logged("2 flaring recipes") == 1 and #support.logs == 1, "One line with the count")
flaring.data_final_fixes()
check(#support.logs == 1, "A second run changes nothing")
install({fluid = {["crude-oil"] = {emissions_multiplier = 3}}})
flaring.data_final_fixes()
check(#support.logs == 0, "No Flare Stack, no change")

print("tellus magnesium and flare stack emissions: ok")
