---@diagnostic disable: missing-fields
-- ske_h2o gives 6 water (prototypes/balance/skewer_planet_vesta/h2o_water.lua), on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_balance_h2o_water.lua
package.path = "./?.lua;./?/init.lua;" .. package.path
local support = require("tests.lua.loops_support")
local check = support.check
local loops = require("prototypes.balance.resource_loops")

local fix = require("prototypes.balance.skewer_planet_vesta.h2o_water")

local function fixture(amount, marks)
	local water = { type = "fluid", name = "water", amount = amount }
	for key, value in pairs(marks or {}) do
		water[key] = value
	end

	return { ske_h2o = { results = { water, { type = "fluid", name = "other", amount = amount } } } }
end

local raw = support.install(fixture(30))
fix.data_final_fixes()
check(raw.recipe.ske_h2o.results[1].amount == 6 and raw.recipe.ske_h2o.results[2].amount == 30,
	"The recipe gives 6 water, not 30, and only water")
check(support.logged("ske_h2o gives 6 water, not 30") == 1 and #support.logs == 1 and support.logs[1]:find("^razi%-protocol: "),
	"One line for the change")

-- Marks that equalled the old amount follow it; other marks stay.
raw = support.install(fixture(30, { ignored_by_productivity = 30, ignored_by_stats = 30 }))
fix.data_final_fixes()
check(raw.recipe.ske_h2o.results[1].ignored_by_productivity == 6 and raw.recipe.ske_h2o.results[1].ignored_by_stats == 6,
	"Marks of the whole amount follow the new amount")
raw = support.install(fixture(30, { ignored_by_productivity = 10, ignored_by_stats = 5 }))
fix.data_final_fixes()
check(raw.recipe.ske_h2o.results[1].ignored_by_productivity == 10 and raw.recipe.ske_h2o.results[1].ignored_by_stats == 5,
	"Other marks stay")

-- An amount the author changed is left alone, and so is a missing recipe.
for _, amount in ipairs({ 6, 29, 60 }) do
	raw = support.install(fixture(amount))
	fix.data_final_fixes()
	check(raw.recipe.ske_h2o.results[1].amount == amount and #support.logs == 0, "An amount of " .. amount .. " stays")
end
support.install({})
fix.data_final_fixes()
check(#support.logs == 0, "No recipe, no change")

-- Through the level.
support.gate(loops, function() return fixture(30) end, function(data_raw)
	return data_raw.recipe.ske_h2o.results[1].amount == 6
end)

print("test_balance_h2o_water: ok")
