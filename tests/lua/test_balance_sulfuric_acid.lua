---@diagnostic disable: missing-fields
-- The acid of Corrundum takes no productivity at all (prototypes/balance/corrundum/sulfuric_acid.lua), on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_balance_sulfuric_acid.lua
package.path = "./?.lua;./?/init.lua;" .. package.path
local support = require("tests.lua.loops_support")
local check = support.check
local loops = require("prototypes.balance.resource_loops")

local fix = require("prototypes.balance.corrundum.sulfuric_acid")

local function fixture()
	return {
		["sulfuric-acid-dilution"] = { allow_productivity = false, maximum_productivity = 1 },
		["sulfuric-acid-concentration"] = { allow_productivity = false, maximum_productivity = 1 },
		["sulfuric-acid-concentration-alt"] = { allow_productivity = false, maximum_productivity = 1 },
		["sulfuric-acid"] = { allow_productivity = false, maximum_productivity = 1 },
	}
end

local raw = support.install(fixture())
fix.data_final_fixes()
for _, name in ipairs({ "sulfuric-acid-dilution", "sulfuric-acid-concentration", "sulfuric-acid-concentration-alt" }) do
	check(raw.recipe[name].maximum_productivity == 0 and raw.recipe[name].allow_productivity == false, name .. " takes no productivity")
	check(support.logged(name .. " takes no productivity") == 1, "A line for " .. name)
end
check(raw.recipe["sulfuric-acid"].maximum_productivity == 1 and #support.logs == 3, "Another recipe is left alone")
check(support.logs[1]:find("^razi%-protocol: "), "Lines start with the mod name")

-- Recipes that the author changed (productivity allowed, another cap, already capped) are left alone.
for _, changed in ipairs({ { allow_productivity = true, maximum_productivity = 1 }, { allow_productivity = false, maximum_productivity = 3 },
	{ allow_productivity = false, maximum_productivity = 0 }, { allow_productivity = false } }) do
	raw = support.install({ ["sulfuric-acid-dilution"] = support.copy(changed) })
	fix.data_final_fixes()
	check(support.same(raw.recipe["sulfuric-acid-dilution"], changed) and #support.logs == 0, "A changed recipe stays")
end
support.install({})
fix.data_final_fixes()
check(#support.logs == 0, "No recipes, no change")

-- Through the level.
support.gate(loops, fixture, function(data_raw)
	return data_raw.recipe["sulfuric-acid-dilution"].maximum_productivity == 0
end)

print("test_balance_sulfuric_acid: ok")
