---@diagnostic disable: missing-fields
-- Crushing recipes that do not allow productivity take none (prototypes/balance/shchierbin/crusher_productivity.lua), on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_balance_crusher_productivity.lua
package.path = "./?.lua;./?/init.lua;" .. package.path
local support = require("tests.lua.loops_support")
local check = support.check
local loops = require("prototypes.balance.resource_loops")

local fix = require("prototypes.balance.shchierbin.crusher_productivity")

local function fixture()
	return {
		-- crushing without productivity (written false or left unset): the base bonus of a crusher must not apply
		reprocessing = { categories = { "crushing" }, allow_productivity = false },
		unset = { categories = { "crushing", "basic-crushing" } },
		-- crushing with productivity: the author's choice
		crushing = { categories = { "crushing" }, allow_productivity = true },
		-- already capped
		capped = { categories = { "crushing" }, allow_productivity = false, maximum_productivity = 0 },
		-- another category
		smelting = { categories = { "smelting" }, allow_productivity = false },
		-- an old recipe with a single category, not converted yet: nothing to read
		old = { category = "crushing" },
	}
end

local raw = support.install(fixture())
fix.data_final_fixes()
local recipes = raw.recipe
check(recipes.reprocessing.maximum_productivity == 0 and recipes.unset.maximum_productivity == 0,
	"Crushing without productivity takes none")
check(recipes.crushing.maximum_productivity == nil, "Crushing with productivity keeps it")
check(recipes.capped.maximum_productivity == 0, "A capped recipe stays capped")
check(recipes.smelting.maximum_productivity == nil and recipes.old.maximum_productivity == nil, "Other recipes are left alone")
check(support.logged("capped at maximum_productivity = 0: 2") == 1, "The line counts the recipes")
check(#support.logs == 1 and support.logs[1]:find("^razi%-protocol: "), "One line, with the prefix")

-- A second run finds nothing more to cap.
support.logs = {}
fix.data_final_fixes()
check(support.logged("capped at maximum_productivity = 0: 0") == 1 and #support.logs == 1, "A second run changes nothing")

-- No recipes at all: quiet except for the count.
support.install({})
fix.data_final_fixes()
check(#support.logs == 1 and support.logged("capped at maximum_productivity = 0: 0") == 1, "No recipes, no change")

-- Through the level: open leaves the recipes as they are, closed and strict apply the cap.
support.gate(loops, fixture, function(data_raw)
	return data_raw.recipe.reprocessing.maximum_productivity == 0
end)

print("test_balance_crusher_productivity: ok")
