---@diagnostic disable: missing-fields
-- Recycling returns a quarter of the cheapest recipe at most (prototypes/balance/Krastorio2/recycling_returns.lua), on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_balance_recycling_returns.lua
package.path = "./?.lua;./?/init.lua;" .. package.path
local support = require("tests.lua.loops_support")
local check = support.check
local loops = require("prototypes.balance.resource_loops")

local fix = require("prototypes.balance.Krastorio2.recycling_returns")

local function fixture()
	return {
		["glass-recycling"] = { results = { { type = "item", name = "kr-sand", amount = 1 } } },
		["gold-plate-recycling"] = { results = { { type = "item", name = "gold-ore", amount = 1, extra_count_fraction = 0 } } },
		["kr-crush-burner-inserter"] = { results = {
			{ type = "item", name = "kr-inserter-parts", amount = 1 }, { type = "item", name = "iron-plate", amount = 1 } } },
	}
end

local raw = support.install(fixture())
fix.data_final_fixes()
local recipes = raw.recipe
check(recipes["glass-recycling"].results[1].amount == 0 and recipes["glass-recycling"].results[1].extra_count_fraction == 0.5,
	"Glass returns half a sand")
check(recipes["gold-plate-recycling"].results[1].amount == 0 and recipes["gold-plate-recycling"].results[1].extra_count_fraction == 0.25,
	"A gold plate returns a quarter of an ore")
check(recipes["kr-crush-burner-inserter"].results[1].amount == 0 and recipes["kr-crush-burner-inserter"].results[1].extra_count_fraction == 0.5
	and recipes["kr-crush-burner-inserter"].results[2].amount == 1, "The burner inserter crusher returns half a part and keeps the plate")
check(support.logged("glass-recycling returns 0.5 kr-sand") == 1 and support.logged("gold-plate-recycling returns 0.25 gold-ore") == 1
	and support.logged("kr-crush-burner-inserter returns half a part") == 1 and #support.logs == 3, "A line for each change")
check(support.logs[1]:find("^razi%-protocol: "), "Lines start with the mod name")

-- A second run finds the new numbers and changes nothing.
support.logs = {}
fix.data_final_fixes()
check(#support.logs == 0, "A second run changes nothing")

-- Numbers the authors changed are left alone: glass at a quarter already, gold at half, a part with a fraction.
raw = support.install({
	["glass-recycling"] = { results = { { type = "item", name = "kr-sand", amount = 0, extra_count_fraction = 0.5 } } },
	["gold-plate-recycling"] = { results = { { type = "item", name = "gold-ore", amount = 0, extra_count_fraction = 0.5 } } },
	["kr-crush-burner-inserter"] = { results = { { type = "item", name = "kr-inserter-parts", amount = 1, extra_count_fraction = 0.25 } } },
})
local before = support.copy(raw)
fix.data_final_fixes()
check(support.same(raw, before) and #support.logs == 0, "Changed numbers stay and nothing is logged")
support.install({})
fix.data_final_fixes()
check(#support.logs == 0, "No recipes, no change")

-- Through the level.
support.gate(loops, fixture, function(data_raw)
	return data_raw.recipe["glass-recycling"].results[1].extra_count_fraction == 0.5
end)

print("test_balance_recycling_returns: ok")
