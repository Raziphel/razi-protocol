---@diagnostic disable: missing-fields
-- The empty container of Voidcraft's safe disposal stays out of productivity (prototypes/balance/Voidcraft/void_container.lua),
-- on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_balance_void_container.lua
package.path = "./?.lua;./?/init.lua;" .. package.path
local support = require("tests.lua.loops_support")
local check = support.check
local loops = require("prototypes.balance.resource_loops")

local fix = require("prototypes.balance.Voidcraft.void_container")

local function fixture(amount, mark)
	return { ["s6x-void-safe-disposal"] = {
		ingredients = { { type = "item", name = "void-pure-container-full", amount = 1 } },
		results = { { type = "item", name = "void-pure-container", amount = amount, ignored_by_productivity = mark } } } }
end

local raw = support.install(fixture(1, nil))
fix.data_final_fixes()
check(raw.recipe["s6x-void-safe-disposal"].results[1].ignored_by_productivity == 1, "The empty container is out of productivity")
check(support.logged("s6x-void-safe-disposal keeps its empty container out of productivity") == 1 and #support.logs == 1
	and support.logs[1]:find("^razi%-protocol: "), "One line for the change")

-- Another amount or a mark of the author stays.
for _, row in ipairs({ { 2, nil }, { 1, 0 }, { 1, 1 } }) do
	raw = support.install(fixture(row[1], row[2]))
	fix.data_final_fixes()
	check(raw.recipe["s6x-void-safe-disposal"].results[1].ignored_by_productivity == row[2] and #support.logs == 0,
		"Amount " .. row[1] .. " with mark " .. tostring(row[2]) .. " stays")
end
support.install({})
fix.data_final_fixes()
check(#support.logs == 0, "No recipe, no change")

-- Through the level.
support.gate(loops, function() return fixture(1, nil) end, function(data_raw)
	return data_raw.recipe["s6x-void-safe-disposal"].results[1].ignored_by_productivity == 1
end)

print("test_balance_void_container: ok")
