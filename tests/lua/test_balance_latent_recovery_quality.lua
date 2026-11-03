---@diagnostic disable: missing-fields
-- Cubic latent recovery takes no quality (prototypes/balance/cubium/latent_recovery_quality.lua), on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_balance_latent_recovery_quality.lua
package.path = "./?.lua;./?/init.lua;" .. package.path
local support = require("tests.lua.loops_support")
local check = support.check
local loops = require("prototypes.balance.resource_loops")

local fix = require("prototypes.balance.cubium.latent_recovery_quality")

local function fixture(allow_quality)
	return { ["cubic-latent-recovery"] = { allow_productivity = false, allow_quality = allow_quality },
		["cube-jelly"] = { allow_productivity = true } }
end

local raw = support.install(fixture(nil))
fix.data_final_fixes()
check(raw.recipe["cubic-latent-recovery"].allow_quality == false, "The recovery takes no quality")
check(raw.recipe["cube-jelly"].allow_quality == nil, "The jelly recipe is left alone")
check(support.logged("cubic-latent-recovery takes no quality") == 1 and #support.logs == 1
	and support.logs[1]:find("^razi%-protocol: "), "One line for the change")

-- Already without quality: nothing to do. An explicit true is the default the mod wrote, and goes.
support.install(fixture(false))
fix.data_final_fixes()
check(#support.logs == 0, "A recipe without quality is silent")
raw = support.install(fixture(true))
fix.data_final_fixes()
check(raw.recipe["cubic-latent-recovery"].allow_quality == false and #support.logs == 1, "An explicit true goes too")

support.install({})
fix.data_final_fixes()
check(#support.logs == 0, "No recipe, no change")

support.gate(loops, function() return fixture(nil) end, function(data_raw)
	return data_raw.recipe["cubic-latent-recovery"].allow_quality == false
end, "strict")

print("test_balance_latent_recovery_quality: ok")
