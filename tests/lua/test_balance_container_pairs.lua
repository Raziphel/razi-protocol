---@diagnostic disable: missing-fields
-- Pairs of recipes that undo each other stay out of productivity and quality (prototypes/balance/common/container_pairs.lua), on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_balance_container_pairs.lua
package.path = "./?.lua;./?/init.lua;" .. package.path
local support = require("tests.lua.loops_support")
local check = support.check
local loops = require("prototypes.balance.resource_loops")

local fix = require("prototypes.balance.common.container_pairs")

local function fixture()
	return {
		-- a container: fill and drain, the same amounts both ways
		["fill-can"] = {
			ingredients = { { type = "item", name = "can", amount = 1 }, { type = "fluid", name = "gas", amount = 50 } },
			results = { { type = "item", name = "full-can", amount = 1 } },
		},
		["drain-can"] = {
			ingredients = { { type = "item", name = "full-can", amount = 1 } },
			results = { { type = "item", name = "can", amount = 1 }, { type = "fluid", name = "gas", amount = 50 } },
		},
		-- the pair of a vanilla barrel: the products are marked, the quality is not
		["fill-barrel"] = {
			ingredients = { { type = "item", name = "barrel", amount = 1 }, { type = "fluid", name = "oil", amount = 50 } },
			results = { { type = "item", name = "full-barrel", amount = 1, ignored_by_stats = 1, ignored_by_productivity = 1 } },
		},
		["empty-barrel"] = {
			ingredients = { { type = "item", name = "full-barrel", amount = 1 } },
			results = { { type = "item", name = "barrel", amount = 1, ignored_by_stats = 1, ignored_by_productivity = 1 },
				{ type = "fluid", name = "oil", amount = 50, ignored_by_stats = 50, ignored_by_productivity = 50 } },
			allow_quality = false,
		},
		-- not a pair: the way back gives another amount (the name that sorts first is the one that looks for a partner)
		["a-press-ore"] = {
			ingredients = { { type = "item", name = "ore", amount = 2 } },
			results = { { type = "item", name = "plate", amount = 1 } },
		},
		["z-melt-plate"] = {
			ingredients = { { type = "item", name = "plate", amount = 1 } },
			results = { { type = "item", name = "ore", amount = 1 } },
		},
		-- a chance in the amounts: no pair, however the names fit
		["roll-a"] = {
			ingredients = { { type = "item", name = "a", amount = 1 } },
			results = { { type = "item", name = "b", amount = 1, independent_probability = 0.5 } },
		},
		["roll-b"] = {
			ingredients = { { type = "item", name = "b", amount = 1 } },
			results = { { type = "item", name = "a", amount = 1 } },
		},
		-- recycling is no pair
		["x-recycling"] = {
			category = "recycling",
			ingredients = { { type = "item", name = "plate", amount = 1 } },
			results = { { type = "item", name = "ore", amount = 2 } },
		},
	}
end

local raw = support.install(fixture())
fix.data_final_fixes()
local recipes = raw.recipe
check(recipes["fill-can"].allow_quality == false and recipes["drain-can"].allow_quality == false, "The pair takes no quality")
check(recipes["fill-can"].results[1].ignored_by_productivity == 1 and recipes["fill-can"].results[1].ignored_by_stats == 1,
	"The filled can is out of productivity")
check(recipes["drain-can"].results[1].ignored_by_productivity == 1 and recipes["drain-can"].results[2].ignored_by_productivity == 50
	and recipes["drain-can"].results[2].ignored_by_stats == 50, "Both products of the drain are out of productivity")
check(recipes["fill-barrel"].allow_quality == false, "A barrel that took productivity already takes no quality now")
check(recipes["fill-barrel"].results[1].ignored_by_productivity == 1 and recipes["empty-barrel"].results[2].ignored_by_productivity == 50,
	"A marked product keeps its mark")
check(support.logged("drain-can + fill-can undo each other, 5 products kept out of productivity") == 1
	and support.logged("empty-barrel + fill-barrel undo each other, 1 products kept out of productivity") == 1,
	"One line for each pair, with the number of changes")
check(recipes["a-press-ore"].allow_quality == nil and recipes["a-press-ore"].results[1].ignored_by_productivity == nil
	and recipes["z-melt-plate"].results[1].ignored_by_productivity == nil, "Recipes with different amounts are no pair")
check(recipes["roll-a"].allow_quality == nil and recipes["roll-b"].allow_quality == nil, "A chance in the amounts is no pair")
check(recipes["x-recycling"].allow_quality == nil, "Recycling is skipped")
check(support.logged("reversible recipe pairs kept out of productivity: 2 pairs, 6 products") == 1 and #support.logs == 3,
	"The summary line counts pairs and products")
check(support.logs[1]:find("^razi%-protocol: "), "Lines start with the mod name")

-- A second run finds nothing more.
support.logs = {}
fix.data_final_fixes()
check(support.logged("2 pairs") == 0 and support.logged("0 pairs, 0 products") == 1 and #support.logs == 1, "A second run changes nothing")

-- Through the level: open leaves the pairs as they are, closed and strict mark them.
support.gate(loops, fixture, function(data_raw)
	return data_raw.recipe["fill-can"].allow_quality == false and support.logged("2 pairs, 6 products") == 1
end)

print("test_balance_container_pairs: ok")
