---@diagnostic disable: missing-fields
-- The hot fluoroketone of dry ice stays out of productivity (prototypes/balance/corrundum/dry_ice.lua), on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_balance_dry_ice.lua
package.path = "./?.lua;./?/init.lua;" .. package.path
local support = require("tests.lua.loops_support")
local check = support.check
local loops = require("prototypes.balance.resource_loops")

local fix = require("prototypes.balance.corrundum.dry_ice")

local function fixture(amount, mark)
	return { ["dry-ice"] = { results = {
		{ type = "item", name = "dry-ice", amount = 1 },
		{ type = "fluid", name = "fluoroketone-hot", amount = amount, ignored_by_productivity = mark } } } }
end

local raw = support.install(fixture(25, nil))
fix.data_final_fixes()
check(raw.recipe["dry-ice"].results[2].ignored_by_productivity == 25 and raw.recipe["dry-ice"].results[1].ignored_by_productivity == nil,
	"The hot fluoroketone is out of productivity, the ice is not")
check(support.logged("dry-ice keeps its hot fluoroketone out of productivity") == 1 and #support.logs == 1
	and support.logs[1]:find("^razi%-protocol: "), "One line for the change")

-- Another amount or a mark of the author stays.
for _, row in ipairs({ { 20, nil }, { 25, 10 }, { 25, 25 } }) do
	raw = support.install(fixture(row[1], row[2]))
	fix.data_final_fixes()
	check(raw.recipe["dry-ice"].results[2].ignored_by_productivity == row[2] and #support.logs == 0,
		"Amount " .. row[1] .. " with mark " .. tostring(row[2]) .. " stays")
end
support.install({})
fix.data_final_fixes()
check(#support.logs == 0, "No recipe, no change")

-- Through the level.
support.gate(loops, function() return fixture(25, nil) end, function(data_raw)
	return data_raw.recipe["dry-ice"].results[2].ignored_by_productivity == 25
end)

print("test_balance_dry_ice: ok")
