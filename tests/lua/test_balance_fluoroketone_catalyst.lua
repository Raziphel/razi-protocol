---@diagnostic disable: missing-fields
-- The hot fluoroketone of plasma-carbon-fiber stays out of productivity (prototypes/balance/plasma_crafter/fluoroketone_catalyst.lua), on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_balance_fluoroketone_catalyst.lua
package.path = "./?.lua;./?/init.lua;" .. package.path
local support = require("tests.lua.loops_support")
local check = support.check
local loops = require("prototypes.balance.resource_loops")

local fix = require("prototypes.balance.plasma_crafter.fluoroketone_catalyst")

local function fixture(mark)
	return {
		["plasma-carbon-fiber"] = {
			results = {
				{ type = "fluid", name = "fluoroketone-hot", amount = 5, ignored_by_stats = 10, ignored_by_productivity = mark },
				{ type = "item", name = "carbon-fiber", amount = 4 },
			},
		},
	}
end

-- The returned fluid is kept out of productivity; the item is not.
local raw = support.install(fixture(nil))
fix.data_final_fixes()
local results = raw.recipe["plasma-carbon-fiber"].results
check(results[1].ignored_by_productivity == 5, "The hot fluoroketone is a catalyst")
check(results[2].ignored_by_productivity == nil, "The carbon fiber still gains from productivity")
check(support.logged("plasma-carbon-fiber fluoroketone-hot ignored_by_productivity = 5") == 1 and #support.logs == 1
	and support.logs[1]:find("^razi%-protocol: "), "One line for the change")

-- A recipe the mod already marked, or marked another way, is left alone.
for _, mark in ipairs({ 5, 2 }) do
	raw = support.install(fixture(mark))
	fix.data_final_fixes()
	check(raw.recipe["plasma-carbon-fiber"].results[1].ignored_by_productivity == mark and #support.logs == 0,
		"A marked product keeps its mark: " .. mark)
end

-- No recipe: quiet.
support.install({})
fix.data_final_fixes()
check(#support.logs == 0, "No recipe, no change")

-- Through the level: open leaves the recipe as it is, closed and strict mark it.
support.gate(loops, function() return fixture(nil) end, function(data_raw)
	return data_raw.recipe["plasma-carbon-fiber"].results[1].ignored_by_productivity == 5
end)

print("test_balance_fluoroketone_catalyst: ok")
