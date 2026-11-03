---@diagnostic disable: missing-fields
-- Crucible's space electrolysis gives 250 hydrogen without productivity and the hot hydrogen from ammonia is hidden (prototypes/balance/planet-crucible/hydrogen.lua), on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_balance_hydrogen.lua
package.path = "./?.lua;./?/init.lua;" .. package.path
local support = require("tests.lua.loops_support")
local check = support.check
local loops = require("prototypes.balance.resource_loops")

local fix = require("prototypes.balance.planet-crucible.hydrogen")

local function fixture(amount)
	return {
		["planet-crucible-space-electrolysis"] = {
			allow_productivity = true,
			results = { { type = "fluid", name = "kr-hydrogen", amount = amount }, { type = "fluid", name = "kr-oxygen", amount = 500 } },
		},
		["planet-crucible-hydrogen-from-ammonia"] = { enabled = false },
	}, {
		["crucible-hydrogen"] = { effects = { { type = "unlock-recipe", recipe = "planet-crucible-hydrogen-from-ammonia" },
			{ type = "unlock-recipe", recipe = "planet-crucible-space-electrolysis" } } },
		["ammonia-only"] = { effects = { { type = "unlock-recipe", recipe = "planet-crucible-hydrogen-from-ammonia" } } },
	}
end

local raw = support.install(fixture(500))
fix.data_final_fixes()
local electrolysis = raw.recipe["planet-crucible-space-electrolysis"]
check(electrolysis.results[1].amount == 250 and electrolysis.results[2].amount == 500, "The electrolysis gives 250 hydrogen")
check(electrolysis.allow_productivity == false and electrolysis.maximum_productivity == 0, "The electrolysis takes no productivity")
check(raw.recipe["planet-crucible-hydrogen-from-ammonia"].hidden == true
	and raw.recipe["planet-crucible-hydrogen-from-ammonia"].enabled == false, "The ammonia recipe is hidden")
check(#raw.technology["crucible-hydrogen"].effects == 1 and raw.technology["crucible-hydrogen"].hidden == nil,
	"A technology with another recipe loses the hidden one and stays")
check(raw.technology["ammonia-only"].hidden == true, "A technology with nothing left is hidden")
check(support.logged("planet-crucible-space-electrolysis gives 250 hydrogen, no productivity") == 1
	and support.logged("recipe planet-crucible-hydrogen-from-ammonia hidden") == 1
	and support.logged("technology ammonia-only hidden") == 1 and #support.logs == 3, "A line for each change")

-- An amount the author changed keeps the recipe as it is; the ammonia recipe is still hidden.
raw = support.install(fixture(400))
fix.data_final_fixes()
electrolysis = raw.recipe["planet-crucible-space-electrolysis"]
check(electrolysis.results[1].amount == 400 and electrolysis.allow_productivity == true and electrolysis.maximum_productivity == nil,
	"Another amount stays, with its productivity")
check(raw.recipe["planet-crucible-hydrogen-from-ammonia"].hidden == true, "The ammonia recipe is hidden")

-- No recipes: quiet.
support.install({}, {})
fix.data_final_fixes()
check(#support.logs == 0, "No recipes, no change")

-- Through the level.
support.gate(loops, function() return fixture(500) end, function(data_raw)
	return data_raw.recipe["planet-crucible-space-electrolysis"].results[1].amount == 250
		and data_raw.recipe["planet-crucible-hydrogen-from-ammonia"].hidden == true
end)

print("test_balance_hydrogen: ok")
