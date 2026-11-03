---@diagnostic disable: missing-fields
-- Wood, coal, carbon and stone no longer go round through matter (prototypes/balance/common/wood_coal_stone.lua), on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_balance_wood_coal_stone.lua
package.path = "./?.lua;./?/init.lua;" .. package.path
local support = require("tests.lua.loops_support")
local check = support.check
local loops = require("prototypes.balance.resource_loops")

local fix = require("prototypes.balance.common.wood_coal_stone")

local function take(item, amount)
	return { ingredients = { { type = "item", name = item, amount = amount } }, results = {} }
end

local function fixture(changed)
	local recipes = {
		["pyrolysis-advanced"] = take("wood", 8),
		["calciner-wood-carbonization"] = take("wood", 2),
		["planetaris-compression-wood-coal"] = take("wood", 3),
		["pyrolysis-basic"] = { ingredients = {}, results = { { type = "item", name = "coal", amount = 1 } } },
		["wood-spoiling"] = { ingredients = {}, results = { { type = "item", name = "spoilage", amount = 40, ignored_by_stats = 7 } } },
		["planetaris-lig-carbon-wood-chemistry"] = { ingredients = {}, results = { { type = "item", name = "wood", amount = 5 } } },
		["planetaris-coal-to-stone-particle-manipulation"] = { ingredients = {}, results = { { type = "item", name = "stone", amount = 5 } } },
		["burnt-spoilage"] = { ingredients = {}, results = { { type = "item", name = "carbon", amount = 2 }, { type = "item", name = "other", amount = 1 } } },
	}
	if changed then
		-- the authors changed the numbers: nothing of the fixes is left to do but the productivity of the basic pyrolysis
		recipes["pyrolysis-advanced"].ingredients[1].amount = 32
		recipes["calciner-wood-carbonization"].ingredients[1].amount = 4
		recipes["planetaris-compression-wood-coal"].ingredients[1].amount = 8
		recipes["wood-spoiling"].results[1].amount = 10
		recipes["planetaris-lig-carbon-wood-chemistry"].results[1].amount = 2
		recipes["planetaris-coal-to-stone-particle-manipulation"].results[1].amount = 3
		recipes["burnt-spoilage"].results[1].ignored_by_productivity = 1
		recipes["pyrolysis-basic"].maximum_productivity = 0
	end

	return recipes
end

local raw = support.install(fixture())
fix.data_final_fixes()
local recipes = raw.recipe
check(recipes["pyrolysis-advanced"].ingredients[1].amount == 32 and recipes["pyrolysis-advanced"].maximum_productivity == 0,
	"pyrolysis-advanced takes 32 wood and no productivity")
check(recipes["calciner-wood-carbonization"].ingredients[1].amount == 8 and recipes["calciner-wood-carbonization"].maximum_productivity == 0,
	"The calciner takes 8 wood and no productivity")
check(recipes["planetaris-compression-wood-coal"].ingredients[1].amount == 8
	and recipes["planetaris-compression-wood-coal"].maximum_productivity == 0, "The compression takes 8 wood and no productivity")
check(recipes["pyrolysis-basic"].maximum_productivity == 0, "The basic pyrolysis takes no productivity")
check(recipes["wood-spoiling"].results[1].amount == 8 and recipes["wood-spoiling"].results[1].ignored_by_stats == 7
	and recipes["wood-spoiling"].maximum_productivity == 0, "Wood spoiling gives 8 spoilage and takes no productivity")
check(recipes["planetaris-lig-carbon-wood-chemistry"].results[1].amount == 1, "The carbon chemistry gives 1 wood")
check(recipes["planetaris-coal-to-stone-particle-manipulation"].results[1].amount == 3, "The coal particle gives 3 stone")
check(recipes["burnt-spoilage"].results[1].ignored_by_productivity == 2 and recipes["burnt-spoilage"].results[2].ignored_by_productivity == nil,
	"The carbon of burnt spoilage is out of productivity")
check(support.logged("pyrolysis-advanced takes 32 wood, not 8") == 1 and support.logged("wood-spoiling gives 8 spoilage, not 40") == 1
	and support.logged("burnt-spoilage keeps its carbon out of productivity") == 1 and #support.logs == 12,
	"A line for each change")
check(support.logs[1]:find("^razi%-protocol: "), "Lines start with the mod name")

-- The marks that equal the old amount follow it (wood spoiling above kept its own mark of 7).
raw = support.install({ ["wood-spoiling"] = { results = { { type = "item", name = "spoilage", amount = 40,
	ignored_by_productivity = 40, ignored_by_stats = 40 } } } })
fix.data_final_fixes()
recipes = raw.recipe
check(recipes["wood-spoiling"].results[1].ignored_by_productivity == 8 and recipes["wood-spoiling"].results[1].ignored_by_stats == 8,
	"A mark of the whole amount follows the new amount")

-- Numbers the authors changed are left alone: only the basic pyrolysis had no cap to lose, and it keeps its cap.
raw = support.install(fixture(true))
local before = support.copy(raw)
fix.data_final_fixes()
check(support.same(raw, before) and #support.logs == 0, "Changed numbers are left alone and nothing is logged")

-- A burnt spoilage the author marked in part, or recipes that are missing: quiet.
support.install({ ["burnt-spoilage"] = { results = { { type = "item", name = "carbon", amount = 2, ignored_by_productivity = 0 } } } })
fix.data_final_fixes()
check(#support.logs == 0, "A marked carbon stays")
support.install({})
fix.data_final_fixes()
check(#support.logs == 0, "No recipes, no change")

-- Through the level.
support.gate(loops, fixture, function(data_raw)
	return data_raw.recipe["pyrolysis-advanced"].ingredients[1].amount == 32
end)

print("test_balance_wood_coal_stone: ok")
