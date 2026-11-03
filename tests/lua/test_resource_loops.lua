---@diagnostic disable: missing-fields
-- The level of razi-resource-loops (prototypes/balance/resource_loops.lua): Easy opens the loops, Normal closes the ones
-- that run on the base productivity of a machine, Hard and Nightmare close the strict ones too, and a value picked by
-- hand wins over the level. On a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_resource_loops.lua
package.path = "./?.lua;./?/init.lua;" .. package.path
local support = require("tests.lua.loops_support")
local check = support.check

local loops = require("prototypes.balance.resource_loops")

local levels = {
	{ "easy", "closed", "open" },
	{ "normal", "closed", "closed" },
	{ "hard", "closed", "strict" },
	{ "nightmare", "closed", "strict" },
	-- a value picked by hand on any level
	{ "normal", "open", "open" },
	{ "normal", "strict", "strict" },
	{ "hard", "open", "open" },
	{ "easy", "strict", "strict" },
	{ "custom", "open", "open" },
	{ "custom", "closed", "closed" },
	{ "custom", "strict", "strict" },
	-- a value the setting does not offer counts as the default
	{ "custom", "tight", "closed" },
	{ "normal", "tight", "closed" },
}
for _, row in ipairs(levels) do
	support.level(row[1], row[2])
	check(loops.level() == row[3], row[1] .. " with " .. row[2] .. " must give " .. row[3] .. ", got " .. loops.level())
end

-- Without settings (small fixtures, a later removal of the setting) the loops are closed like the default.
support.no_settings()
check(loops.level() == "closed", "No settings: the default level")
rawset(_G, "settings", { startup = {} })
check(loops.level() == "closed", "The setting is not declared: the default level")

-- The group runs without prototypes at every level; at the open level it logs nothing and does not look at the recipes.
support.level("easy")
support.install({}, {})
rawset(_G, "data", { raw = {} })
loops.data_final_fixes()
check(#support.logs == 0, "Open: nothing logged, data.raw.recipe not even read")
for _, row in ipairs({ { "normal", "closed" }, { "hard", "closed" } }) do
	support.level(row[1], row[2])
	support.install({}, {})
	loops.data_final_fixes()
end

print("test_resource_loops: ok")
