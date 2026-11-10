---@diagnostic disable: missing-fields
-- Productivity caps on five recipes and the matter of uranium 238 (prototypes/balance/common/productivity_caps.lua), on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_balance_productivity_caps.lua
package.path = "./?.lua;./?/init.lua;" .. package.path
local support = require("tests.lua.loops_support")
local check = support.check
local loops = require("prototypes.balance.resource_loops")

local fix = require("prototypes.balance.common.productivity_caps")

local function fixture(cap)
	return {
		["nutrients-spoiling"] = { maximum_productivity = cap },
		["linox-recipe_rapid-distillation"] = { maximum_productivity = cap },
		["gel-polymerization"] = { maximum_productivity = cap },
		["slime-weed-processing"] = { maximum_productivity = cap },
		["advanced-circuit-from-silicon"] = { maximum_productivity = cap },
		["kr-uranium-238-to-matter"] = { results = {
			{ type = "fluid", name = "kr-matter", amount = 47.1, ignored_by_productivity = 47.1, ignored_by_stats = 47.1 } } },
	}
end

local raw = support.install(fixture())
fix.data_final_fixes()
local recipes = raw.recipe
check(recipes["nutrients-spoiling"].maximum_productivity == 0 and recipes["gel-polymerization"].maximum_productivity == 0,
	"Spoiling and gel take no productivity")
check(recipes["linox-recipe_rapid-distillation"].maximum_productivity == 0.5, "Rapid distillation takes at most +50 %")
check(recipes["slime-weed-processing"].maximum_productivity == 2, "Slime weed takes at most +200 %")
check(recipes["advanced-circuit-from-silicon"].maximum_productivity == 1, "Advanced circuits from silicon take at most +100 %")
local matter = recipes["kr-uranium-238-to-matter"].results[1]
check(matter.amount == 20 and matter.ignored_by_productivity == 20 and matter.ignored_by_stats == 20,
	"Uranium 238 sells for 20 matter, the marks follow")
check(support.logged("nutrients-spoiling takes at most +0 % productivity") == 1
	and support.logged("linox-recipe_rapid-distillation takes at most +50 % productivity") == 1
	and support.logged("slime-weed-processing takes at most +200 % productivity") == 1
	and support.logged("advanced-circuit-from-silicon takes at most +100 % productivity") == 1
	and support.logged("kr-uranium-238-to-matter gives 20 matter, not 47.1") == 1 and #support.logs == 6
	and support.logs[1]:find("^razi%-protocol: "), "One line for each change")

-- A cap the author set stays, whatever it is.
raw = support.install(fixture(1))
fix.data_final_fixes()
recipes = raw.recipe
for name, recipe in pairs(recipes) do
	check(name == "kr-uranium-238-to-matter" or recipe.maximum_productivity == 1, name .. " keeps the cap of the author")
end
check(support.logged("takes at most") == 0, "An author's cap is silent")

-- Matter that is not 47.1 stays; marks that differ stay.
raw = support.install({ ["kr-uranium-238-to-matter"] = { results = {
	{ type = "fluid", name = "kr-matter", amount = 30 }, { type = "fluid", name = "other", amount = 47.1 } } } })
fix.data_final_fixes()
recipes = raw.recipe
check(recipes["kr-uranium-238-to-matter"].results[1].amount == 30 and recipes["kr-uranium-238-to-matter"].results[2].amount == 47.1
	and #support.logs == 0, "Another amount, or another product, is left alone")
raw = support.install({ ["kr-uranium-238-to-matter"] = { results = {
	{ type = "fluid", name = "kr-matter", amount = 47.1, ignored_by_productivity = 10 } } } })
fix.data_final_fixes()
recipes = raw.recipe
check(recipes["kr-uranium-238-to-matter"].results[1].amount == 20 and recipes["kr-uranium-238-to-matter"].results[1].ignored_by_productivity == 10,
	"A mark of another value stays")

support.install({})
fix.data_final_fixes()
check(#support.logs == 0, "No recipes, no change")

support.gate(loops, function() return fixture() end, function(data_raw)
	return data_raw.recipe["nutrients-spoiling"].maximum_productivity == 0
		and data_raw.recipe["kr-uranium-238-to-matter"].results[1].amount == 20
end, "strict")

print("test_balance_productivity_caps: ok")
