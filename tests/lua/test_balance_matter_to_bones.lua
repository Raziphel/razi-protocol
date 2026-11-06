---@diagnostic disable: missing-fields
-- Matter no longer prints bones (prototypes/balance/nulls-k2so-tweaks/matter_to_bones.lua), on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_balance_matter_to_bones.lua
package.path = "./?.lua;./?/init.lua;" .. package.path
local support = require("tests.lua.loops_support")
local check = support.check
local loops = require("prototypes.balance.resource_loops")

local fix = require("prototypes.balance.nulls-k2so-tweaks.matter_to_bones")

local function fixture()
	return {
		["kr-matter-to-bones"] = { enabled = true },
		["kr-bones-to-matter"] = { enabled = true },
	}, {
		-- the technology of the mod unlocks both ways: it keeps the way back
		["k2sotweak-matter-bones-processing"] = { effects = {
			{ type = "unlock-recipe", recipe = "kr-matter-to-bones" }, { type = "unlock-recipe", recipe = "kr-bones-to-matter" } } },
		-- a technology with nothing else to unlock goes
		["bones-only"] = { effects = { { type = "unlock-recipe", recipe = "kr-matter-to-bones" } } },
		-- the same, but another technology needs it
		["bones-needed"] = { effects = { { type = "unlock-recipe", recipe = "kr-matter-to-bones" } } },
		["after-bones"] = { prerequisites = { "bones-needed" }, effects = { { type = "unlock-recipe", recipe = "kr-bones-to-matter" } } },
	}
end

local raw = support.install(fixture())
fix.data_final_fixes()
check(raw.recipe["kr-matter-to-bones"].hidden == true and raw.recipe["kr-matter-to-bones"].enabled == false,
	"Matter to bones is hidden")
check(raw.recipe["kr-bones-to-matter"].hidden == nil and raw.recipe["kr-bones-to-matter"].enabled == true,
	"Bones still sell for matter")
local technology = raw.technology
check(#technology["k2sotweak-matter-bones-processing"].effects == 1
	and technology["k2sotweak-matter-bones-processing"].effects[1].recipe == "kr-bones-to-matter"
	and technology["k2sotweak-matter-bones-processing"].hidden == nil, "The technology keeps the way back")
check(technology["bones-only"].hidden == true, "A technology with nothing left is hidden")
check(technology["bones-needed"].hidden == nil and #technology["bones-needed"].effects == 0, "A required technology stays")
check(support.logged("recipe kr-matter-to-bones hidden") == 1 and support.logged("technology bones-only hidden") == 1
	and #support.logs == 2 and support.logs[1]:find("^razi%-protocol: "), "A line for the recipe and one for the technology")

-- No recipe (the mod without its matter recipes): quiet.
support.install({ ["kr-bones-to-matter"] = { enabled = true } }, {})
fix.data_final_fixes()
check(#support.logs == 0, "No recipe, no change")

-- Through the level.
support.gate(loops, fixture, function(data_raw)
	return data_raw.recipe["kr-matter-to-bones"].hidden == true
end)

print("test_balance_matter_to_bones: ok")
