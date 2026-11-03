---@diagnostic disable: missing-fields
-- Solid fuel liquefaction takes no productivity and gives 90 heavy oil (prototypes/balance/secretas/fuel_liquefaction.lua), on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_balance_fuel_liquefaction.lua
package.path = "./?.lua;./?/init.lua;" .. package.path
local support = require("tests.lua.loops_support")
local check = support.check
local loops = require("prototypes.balance.resource_loops")

local fix = require("prototypes.balance.secretas.fuel_liquefaction")

local function fixture(amount, allow, maximum)
	return { ["solid-fuel-liquefaction"] = {
		ingredients = {
			{ type = "item", name = "solid-fuel", amount = 5 },
			{ type = "fluid", name = "heavy-oil", amount = 50 },
			{ type = "fluid", name = "steam", amount = 250 } },
		results = { { type = "fluid", name = "heavy-oil", amount = amount, ignored_by_stats = 50, ignored_by_productivity = 50 } },
		allow_productivity = allow,
		maximum_productivity = maximum } }
end

local raw = support.install(fixture(120, true, nil))
fix.data_final_fixes()
local recipe = raw.recipe["solid-fuel-liquefaction"]
check(recipe.results[1].amount == 90, "The recipe gives 90 heavy oil, not 120")
check(recipe.allow_productivity == false and recipe.maximum_productivity == 0, "No productivity modules and no base bonus")
check(recipe.ingredients[1].amount == 5 and recipe.ingredients[2].amount == 50, "The ingredients stay")
check(support.logged("gives 90 heavy oil") == 1 and support.logged("takes no base productivity") == 1
	and support.logged("takes no productivity modules") == 1 and #support.logs == 3
	and support.logs[1]:find("^razi%-protocol: "), "One line for each change")

-- Any amount above 100 goes to 90; an amount the author lowered is left alone, and so is a ranged one.
raw = support.install(fixture(105, true, nil))
fix.data_final_fixes()
check(raw.recipe["solid-fuel-liquefaction"].results[1].amount == 90, "105 goes to 90")
for _, amount in ipairs({ 90, 80 }) do
	raw = support.install(fixture(amount, false, 0))
	fix.data_final_fixes()
	check(raw.recipe["solid-fuel-liquefaction"].results[1].amount == amount and #support.logs == 0,
		amount .. " heavy oil stay, and a closed recipe is silent")
end
raw = support.install({ ["solid-fuel-liquefaction"] = { results = {
	{ type = "fluid", name = "heavy-oil", amount_min = 100, amount_max = 140 } } } })
fix.data_final_fixes()
check(raw.recipe["solid-fuel-liquefaction"].results[1].amount == nil, "A ranged amount is not a number to compare")
-- a recipe that gives 100 gives 90
raw = support.install(fixture(100, false, 0))
fix.data_final_fixes()
check(raw.recipe["solid-fuel-liquefaction"].results[1].amount == 90, "100 goes to 90")
-- the author took the maximum productivity somewhere else
raw = support.install(fixture(90, false, 0.5))
fix.data_final_fixes()
check(raw.recipe["solid-fuel-liquefaction"].maximum_productivity == 0, "A maximum above 0 goes to 0")

-- Another mod removes the recipe: silent.
support.install({})
fix.data_final_fixes()
check(#support.logs == 0, "No recipe, no change")

support.gate(loops, function() return fixture(120, true, nil) end, function(data_raw)
	return data_raw.recipe["solid-fuel-liquefaction"].results[1].amount == 90
end, "strict")

print("test_balance_fuel_liquefaction: ok")
