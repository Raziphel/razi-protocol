---@diagnostic disable: missing-fields
-- Products that a recipe only gives back stay out of productivity (prototypes/balance/common/catalysts.lua), on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_balance_catalysts.lua
package.path = "./?.lua;./?/init.lua;" .. package.path
local support = require("tests.lua.loops_support")
local check = support.check
local loops = require("prototypes.balance.resource_loops")

local fix = require("prototypes.balance.common.catalysts")

local function fixture()
	return {
		-- gives back what it took, and one product more: the returned amount is a catalyst
		pulsar = {
			ingredients = { { type = "item", name = "engine", amount = 2 }, { type = "item", name = "ore", amount = 5 } },
			results = { { type = "item", name = "engine", amount = 2 }, { type = "item", name = "science", amount = 1 } },
		},
		-- gives back less than it took: the whole returned amount is a catalyst
		leaky = {
			ingredients = { { type = "fluid", name = "gas", amount = 5000 } },
			results = { { type = "fluid", name = "gas", amount = 4995 }, { type = "fluid", name = "tritium", amount = 1 } },
		},
		-- part of the amount is already out of productivity: only the rest is added
		partly = {
			ingredients = { { type = "item", name = "egg", amount = 4 } },
			results = { { type = "item", name = "egg", amount = 4, ignored_by_productivity = 1 }, { type = "item", name = "meat", amount = 1 } },
		},
		-- the item twice, the second time with a chance: the amounts add up and the entries share the mark in turn
		twice = {
			ingredients = { { type = "item", name = "frame", amount = 2 } },
			results = { { type = "item", name = "frame", amount = 1 }, { type = "item", name = "frame", amount = 1, probability = 0.5 } },
		},
		-- already out of productivity: nothing to add
		marked = {
			ingredients = { { type = "item", name = "bacteria", amount = 1 } },
			results = { { type = "item", name = "bacteria", amount = 1, ignored_by_productivity = 1 } },
		},
		-- gives more than it took: growth, left to productivity
		growth = {
			ingredients = { { type = "item", name = "bacteria", amount = 1 } },
			results = { { type = "item", name = "bacteria", amount = 4 } },
		},
		-- an item that recycles into itself has nothing to lose
		["engine-recycling"] = {
			category = "recycling",
			ingredients = { { type = "item", name = "engine", amount = 1 } },
			results = { { type = "item", name = "engine", amount = 1 } },
		},
		-- a recipe with categories (2.1) that includes recycling
		["other-recycling"] = {
			categories = { "crafting", "recycling-or-hand-crafting" },
			ingredients = { { type = "item", name = "engine", amount = 1 } },
			results = { { type = "item", name = "engine", amount = 1 } },
		},
		-- no ingredients and no results to speak of
		bare = {},
	}
end

local raw = support.install(fixture())
fix.data_final_fixes()
local recipes = raw.recipe
check(recipes.pulsar.results[1].ignored_by_productivity == 2 and recipes.pulsar.results[2].ignored_by_productivity == nil,
	"The returned engines are out of productivity, the science is not")
check(recipes.leaky.results[1].ignored_by_productivity == 4995 and recipes.leaky.results[2].ignored_by_productivity == nil,
	"What comes back is out of productivity, the rest is not")
check(recipes.partly.results[1].ignored_by_productivity == 4, "A part already ignored is completed to the amount")
check(recipes.twice.results[1].ignored_by_productivity == 1 and recipes.twice.results[2].ignored_by_productivity == 1,
	"A product listed twice gets the mark on both entries")
check(recipes.marked.results[1].ignored_by_productivity == 1, "A marked product stays as it is")
check(recipes.growth.results[1].ignored_by_productivity == nil, "A growth recipe keeps its productivity")
check(recipes["engine-recycling"].results[1].ignored_by_productivity == nil
	and recipes["other-recycling"].results[1].ignored_by_productivity == nil, "Recycling is skipped")
check(support.logged("catalysts kept out of productivity: 4 products") == 1 and #support.logs == 1
	and support.logs[1]:find("^razi%-protocol: "), "One line with the number of products")

-- A second run finds nothing more.
support.logs = {}
fix.data_final_fixes()
check(support.logged("catalysts kept out of productivity: 0 products") == 1, "A second run changes nothing")

-- Through the level: open leaves the recipes as they are, closed and strict mark the catalysts.
support.gate(loops, fixture, function(data_raw)
	return data_raw.recipe.pulsar.results[1].ignored_by_productivity == 2 and support.logged("catalysts kept out of productivity: 4 products") == 1
end)

print("test_balance_catalysts: ok")
