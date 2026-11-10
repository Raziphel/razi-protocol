---@diagnostic disable: missing-fields
-- Panglite leaves two recycling recipes (prototypes/balance/panglia_planet/panglite_recycling.lua), on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_balance_panglite_recycling.lua
package.path = "./?.lua;./?/init.lua;" .. package.path
local support = require("tests.lua.loops_support")
local check = support.check
local loops = require("prototypes.balance.resource_loops")

local fix = require("prototypes.balance.panglia_planet.panglite_recycling")

local function fixture()
	return {
		["panglia_universe_precursor_volcanic-recycling"] = { results = {
			{ type = "item", name = "panglia_panglite", amount = 1, extra_count_fraction = 0.25 } } },
		["panglia_sentient_processor-recycling"] = { results = {
			{ type = "item", name = "processing-unit", amount = 0, extra_count_fraction = 0.25 },
			{ type = "item", name = "panglia_panglite", amount = 1, extra_count_fraction = 0.25 },
			{ type = "item", name = "quantum-processor", amount = 0, extra_count_fraction = 0.25 } } },
		-- another recipe that returns panglite is not one of the two
		["panglia_other-recycling"] = { results = { { type = "item", name = "panglia_panglite", amount = 1 } } },
	}
end

local raw = support.install(fixture())
fix.data_final_fixes()
local volcanic = raw.recipe["panglia_universe_precursor_volcanic-recycling"].results
local sentient = raw.recipe["panglia_sentient_processor-recycling"].results
check(#volcanic == 0, "The volcanic precursor returns no panglite")
check(#sentient == 2 and sentient[1].name == "processing-unit" and sentient[2].name == "quantum-processor",
	"The sentient processor keeps its other returns, in order")
check(#raw.recipe["panglia_other-recycling"].results == 1, "Another recipe is left alone")
check(support.logged("panglia_universe_precursor_volcanic-recycling no longer returns panglia_panglite") == 1
	and support.logged("panglia_sentient_processor-recycling no longer returns panglia_panglite") == 1
	and #support.logs == 2 and support.logs[1]:find("^razi%-protocol: "), "One line for each change")

-- A second run, or an author who already took panglite out: nothing to do.
support.logs = {}
fix.data_final_fixes()
check(#support.logs == 0 and #raw.recipe["panglia_sentient_processor-recycling"].results == 2, "A second run changes nothing")

-- No recipes, or a recipe without results.
support.install({})
fix.data_final_fixes()
support.install({ ["panglia_sentient_processor-recycling"] = {} })
fix.data_final_fixes()
check(#support.logs == 0, "No recipe, no change")

-- Through the level: open and closed leave panglite, strict takes it out.
support.gate(loops, fixture, function(data_raw)
	return #data_raw.recipe["panglia_universe_precursor_volcanic-recycling"].results == 0
end, "strict")

print("test_balance_panglite_recycling: ok")
