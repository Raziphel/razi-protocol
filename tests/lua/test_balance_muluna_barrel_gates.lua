---@diagnostic disable: missing-fields
-- Barrels of Muluna open with the technology of their fluid (prototypes/balance/planet-muluna/barrel_gates.lua), on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_balance_muluna_barrel_gates.lua
package.path = "./?.lua;./?/init.lua;" .. package.path
local support = require("tests.lua.loops_support")
local check = support.check

rawset(_G, "defines", { prototypes = { item = { item = 1 } } })

local fix = require("prototypes.balance.planet-muluna.barrel_gates")

local function barrel(name, fluid, ingredient, result)
	local entry = { type = "fluid", name = fluid, amount = 50 }
	return { name = name, ingredients = { ingredient and entry or { type = "item", name = "barrel", amount = 1 } },
		results = { result and entry or { type = "item", name = "barrel", amount = 1 } } }
end

local function unlock(recipe)
	return { type = "unlock-recipe", recipe = recipe }
end

local function names(technology)
	local result = {}
	for _, effect in ipairs(technology.effects) do
		result[effect.recipe] = true
	end

	return result
end

-- hidden: the technology of the acid is hidden.
local function install(hidden)
	return support.install({
		["water-barrel"] = barrel("water-barrel", "water", true, false),
		["empty-water-barrel"] = barrel("empty-water-barrel", "water", false, true),
		["sulfuric-acid-barrel"] = barrel("sulfuric-acid-barrel", "sulfuric-acid", true, false),
		["empty-sulfuric-acid-barrel"] = barrel("empty-sulfuric-acid-barrel", "sulfuric-acid", false, true),
		["sulfuric-acid"] = { name = "sulfuric-acid", results = { { type = "fluid", name = "sulfuric-acid", amount = 50 } } },
	}, {
		["fluid-handling"] = { effects = {} },
		["fluid-barreling"] = { effects = {
			unlock("water-barrel"), unlock("empty-water-barrel"), unlock("sulfuric-acid-barrel"), unlock("empty-sulfuric-acid-barrel") } },
		["sulfur-processing"] = { hidden = hidden, effects = { unlock("sulfuric-acid") } },
	}, {
		tile = { water = { fluid = "water" } },
		planet = { nauvis = { map_gen_settings = { autoplace_settings = { tile = { settings = { water = {} } } } } } },
	})
end

local function run(mod_list, enabled)
	rawset(_G, "mods", mod_list)
	rawset(_G, "settings", { startup = { ["razi-muluna-barrel-gates"] = { value = enabled } } })
	fix.data_final_fixes()
end

-- The barrels of the acid move to the technology that makes it; the water, which is pumped with no research, stays.
local raw = install()
run({ ["planet-muluna"] = "2.9.14" }, true)
local gated = names(raw.technology["sulfur-processing"])
local barreling = names(raw.technology["fluid-barreling"])
check(gated["sulfuric-acid-barrel"] and gated["empty-sulfuric-acid-barrel"], "The acid barrels open with sulfur processing")
check(not barreling["sulfuric-acid-barrel"] and not barreling["empty-sulfuric-acid-barrel"], "The acid barrels leave fluid barreling")
check(barreling["water-barrel"] and barreling["empty-water-barrel"] and not gated["water-barrel"], "The water barrels stay")
check(support.logged("barrels of sulfuric-acid unlocked by: sulfur-processing") == 1
	and support.logged("moved the barrels of 1 fluids, kept 1 (water)") == 1
	and support.logs[1]:find("^razi%-protocol: "), "The log names the move")

-- A hidden technology gets nothing: the acid keeps its place.
raw = install(true)
run({ ["planet-muluna"] = "2.9.14" }, true)
check(#raw.technology["sulfur-processing"].effects == 1, "A hidden technology gets no barrels")
check(names(raw.technology["fluid-barreling"])["sulfuric-acid-barrel"], "The acid barrels stay where they were")

-- Off, or without Muluna: nothing changes and nothing is logged.
raw = install()
run({ ["planet-muluna"] = "2.9.14" }, false)
check(names(raw.technology["fluid-barreling"])["sulfuric-acid-barrel"] and #raw.technology["sulfur-processing"].effects == 1
	and #support.logs == 0, "Off changes nothing")
raw = install()
run({}, true)
check(names(raw.technology["fluid-barreling"])["sulfuric-acid-barrel"] and #raw.technology["sulfur-processing"].effects == 1
	and #support.logs == 0, "Without Muluna nothing changes")
