---@diagnostic disable: missing-fields
-- The recrystallization recipes of Corrundum go, force reduction takes no productivity (prototypes/balance/corrundum/recrystallization.lua), on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_balance_recrystallization.lua
package.path = "./?.lua;./?/init.lua;" .. package.path
local support = require("tests.lua.loops_support")
local check = support.check
local loops = require("prototypes.balance.resource_loops")

local fix = require("prototypes.balance.corrundum.recrystallization")

local recrystallizations = {
	"iron-recrystalization", "iron-recrystalization-alt", "iron-stick-recrystalization",
	"copper-recrystalization", "copper-recrystalization-alt",
}

local function fixture()
	local recipes = {
		["force-reduction-iron"] = { allow_productivity = true, maximum_productivity = 1 },
		["force-reduction-copper"] = { allow_productivity = true, maximum_productivity = 1 },
		["chalcopyrite-leaching"] = { enabled = false },
	}
	for _, name in ipairs(recrystallizations) do
		recipes[name] = { enabled = false, allow_productivity = false, maximum_productivity = 1 }
	end
	-- one that starts enabled
	recipes["copper-recrystalization-alt"].enabled = true

	local unlock = {}
	for _, name in ipairs(recrystallizations) do
		unlock[#unlock + 1] = { type = "unlock-recipe", recipe = name }
	end

	return recipes, {
		-- nothing left to unlock, and nothing needs it: hidden
		["corrundum-recrystallization"] = { effects = unlock },
		-- the same, but another technology needs it: stays
		["needed-recrystallization"] = { effects = { { type = "unlock-recipe", recipe = "iron-recrystalization" } } },
		["after-needed"] = { prerequisites = { "needed-recrystallization" }, effects = { { type = "unlock-recipe", recipe = "chalcopyrite-leaching" } } },
		-- a technology with other effects keeps them and stays visible
		["mixed"] = { effects = { { type = "unlock-recipe", recipe = "copper-recrystalization" },
			{ type = "unlock-recipe", recipe = "chalcopyrite-leaching" }, { type = "nothing" } } },
		-- a technology that never had effects is not touched
		["empty"] = { effects = {} },
		["without-effects"] = {},
	}
end

local raw = support.install(fixture())
fix.data_final_fixes()
for _, name in ipairs(recrystallizations) do
	check(raw.recipe[name].hidden == true and raw.recipe[name].enabled == false, name .. " is gone")
end
check(raw.recipe["chalcopyrite-leaching"].hidden == nil, "The chalcopyrite way stays")
for _, name in ipairs({ "force-reduction-iron", "force-reduction-copper" }) do
	check(raw.recipe[name].allow_productivity == false and raw.recipe[name].maximum_productivity == 1, name .. " takes no productivity")
end
local technology = raw.technology
check(#technology["corrundum-recrystallization"].effects == 0 and technology["corrundum-recrystallization"].hidden == true,
	"A technology with nothing left is hidden")
check(technology["needed-recrystallization"].hidden == nil and #technology["needed-recrystallization"].effects == 0,
	"A required technology stays")
check(#technology["mixed"].effects == 2 and technology["mixed"].effects[1].recipe == "chalcopyrite-leaching"
	and technology["mixed"].hidden == nil, "The other effects stay")
check(technology["empty"].hidden == nil and technology["without-effects"].hidden == nil, "A technology without effects is left alone")
check(support.logged("technology corrundum-recrystallization hidden") == 1 and support.logged("hidden: nothing left") == 1
	and support.logged("iron-recrystalization removed") == 1 and support.logged("force-reduction-copper takes no productivity") == 1
	and #support.logs == 8 and support.logs[1]:find("^razi%-protocol: "), "One line for each change")

-- A second run, or force reduction that already takes no productivity: the recipes stay gone, the log is short.
support.logs = {}
fix.data_final_fixes()
check(support.logged("takes no productivity") == 0 and support.logged("hidden: nothing left") == 0, "A second run changes nothing more")

-- Corrundum without these recipes (a version that dropped them): nothing happens.
support.install({ ["force-reduction-iron"] = { allow_productivity = false } }, { ["corrundum-recrystallization"] = { effects = {} } })
fix.data_final_fixes()
check(#support.logs == 0, "No recipes, no change")
support.install({})
fix.data_final_fixes()
check(#support.logs == 0, "No recipes and no technologies, no change")

support.gate(loops, fixture, function(data_raw)
	return data_raw.recipe["iron-recrystalization"].hidden == true and data_raw.technology["corrundum-recrystallization"].hidden == true
		and data_raw.recipe["force-reduction-iron"].allow_productivity == false
end, "strict")

print("test_balance_recrystallization: ok")
