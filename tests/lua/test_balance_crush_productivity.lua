---@diagnostic disable: missing-fields
-- Crushing recipes of Krastorio 2 take no productivity (prototypes/balance/Krastorio2/crush_productivity.lua), on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_balance_crush_productivity.lua
package.path = "./?.lua;./?/init.lua;" .. package.path
local support = require("tests.lua.loops_support")
local check = support.check
local loops = require("prototypes.balance.resource_loops")

local fix = require("prototypes.balance.Krastorio2.crush_productivity")

local function fixture()
	return {
		["kr-crush-kr-imersite-crystal"] = { categories = { "kr-crushing" } },
		["kr-crush-rocket"] = { categories = { "kr-void-crushing" }, allow_productivity = false },
		["kr-crush-already"] = { categories = { "kr-crushing" }, maximum_productivity = 0 },
		-- the author's cap is not the one that closes the loop
		["kr-crush-capped"] = { categories = { "kr-crushing" }, maximum_productivity = 0.5 },
		-- other recipes, also near the name
		["kr-crusher"] = {},
		["crush-kr-imersite"] = {},
		["kr-uncrush-all"] = {},
	}
end

local raw = support.install(fixture())
fix.data_final_fixes()
local recipes = raw.recipe
for _, name in ipairs({ "kr-crush-kr-imersite-crystal", "kr-crush-rocket", "kr-crush-already", "kr-crush-capped" }) do
	check(recipes[name].maximum_productivity == 0, name .. " takes no productivity")
end
check(recipes["kr-crusher"].maximum_productivity == nil and recipes["crush-kr-imersite"].maximum_productivity == nil
	and recipes["kr-uncrush-all"].maximum_productivity == nil, "Other recipes are left alone")
check(support.logged("capped at maximum_productivity = 0: 3") == 1 and #support.logs == 1
	and support.logs[1]:find("^razi%-protocol: "), "One line with the number of recipes that changed")

-- A second run finds nothing more to cap.
support.logs = {}
fix.data_final_fixes()
check(support.logged("capped at maximum_productivity = 0: 0") == 1 and #support.logs == 1, "A second run changes nothing")

support.install({})
fix.data_final_fixes()
check(#support.logs == 1 and support.logged("capped at maximum_productivity = 0: 0") == 1, "No recipes, no change")

support.gate(loops, fixture, function(data_raw)
	return data_raw.recipe["kr-crush-rocket"].maximum_productivity == 0
end, "strict")

print("test_balance_crush_productivity: ok")
