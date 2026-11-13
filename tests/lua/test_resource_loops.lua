---@diagnostic disable: missing-fields
-- The level of razi-resource-loops (prototypes/balance/resource_loops.lua): Easy opens the loops, Normal closes the ones
-- that run on the base productivity of a machine, Hard and Nightmare close the strict ones too, and a value picked by
-- hand wins over the level. On a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_resource_loops.lua
package.path = "./?.lua;./?/init.lua;" .. package.path
local support = require("tests.lua.loops_support")
local check = support.check

local loops = require("prototypes.balance.resource_loops")

local levels = {
	{ "easy", "closed", "open" },
	{ "normal", "closed", "closed" },
	{ "hard", "closed", "strict" },
	{ "nightmare", "closed", "strict" },
	-- a value picked by hand on any level
	{ "normal", "open", "open" },
	{ "normal", "strict", "strict" },
	{ "hard", "open", "open" },
	{ "easy", "strict", "strict" },
	{ "custom", "open", "open" },
	{ "custom", "closed", "closed" },
	{ "custom", "strict", "strict" },
	-- a value the setting does not offer counts as the default
	{ "custom", "tight", "closed" },
	{ "normal", "tight", "closed" },
}
for _, row in ipairs(levels) do
	support.level(row[1], row[2])
	check(loops.level() == row[3], row[1] .. " with " .. row[2] .. " must give " .. row[3] .. ", got " .. loops.level())
end

-- Without settings (small fixtures, a later removal of the setting) the loops are closed like the default.
support.no_settings()
check(loops.level() == "closed", "No settings: the default level")
rawset(_G, "settings", { startup = {} })
check(loops.level() == "closed", "The setting is not declared: the default level")

-- The group runs without prototypes at every level; at the open level it logs nothing and does not look at the recipes.
support.level("easy")
support.install({}, {})
rawset(_G, "data", { raw = {} })
loops.data_final_fixes()
check(#support.logs == 0, "Open: nothing logged, data.raw.recipe not even read")
for _, row in ipairs({ { "normal", "closed" }, { "hard", "closed" } }) do
	support.level(row[1], row[2])
	support.install({}, {})
	loops.data_final_fixes()
end

local water_recipes = {
	["water-electrolysis-shchierbin"] = { allow_productivity = true, maximum_productivity = 0.5 },
	ske_h2o = { allow_productivity = true, maximum_productivity = 0.5 },
	ske_water_electrolysis = { allow_productivity = true, maximum_productivity = 0.5 },
}
support.level("custom", "open")
local raw = support.install(water_recipes)
local water_before = support.copy(raw.recipe)
loops.data_final_fixes()
check(support.same(raw.recipe, water_before), "Open: water recipes keep their productivity")
check(#support.logs == 0, "Open: water recipes log no changes")

support.level("custom", "closed")
raw = support.install(support.copy(water_recipes))
loops.data_final_fixes()
for _, name in ipairs({ "water-electrolysis-shchierbin", "ske_h2o", "ske_water_electrolysis" }) do
	local recipe = raw.recipe[name]
	check(recipe.allow_productivity == false and recipe.maximum_productivity == 0,
		"Closed: " .. name .. " takes no productivity")
	check(support.logged(name .. " takes no productivity") == 1,
		"Closed: " .. name .. " logs its change once")
end

local already_closed = support.copy(water_recipes)
for _, recipe in pairs(already_closed) do
	recipe.allow_productivity = false
	recipe.maximum_productivity = 0
end
raw = support.install(already_closed)
loops.data_final_fixes()
check(support.same(raw.recipe, already_closed), "Closed: water recipes already take no productivity")
for _, name in ipairs({ "water-electrolysis-shchierbin", "ske_h2o", "ske_water_electrolysis" }) do
	check(support.logged(name .. " takes no productivity") == 0,
		"Closed: " .. name .. " does not log without a change")
end

print("test_resource_loops: ok")
