---@diagnostic disable: missing-fields
-- Calcite costs 24 quartz and matter no longer prints quartz (prototypes/balance/planetaris-hyarion/quartz_and_calcite.lua), on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_balance_quartz_and_calcite.lua
package.path = "./?.lua;./?/init.lua;" .. package.path
local support = require("tests.lua.loops_support")
local check = support.check
local loops = require("prototypes.balance.resource_loops")

local fix = require("prototypes.balance.planetaris-hyarion.quartz_and_calcite")

local function fixture(amount)
	return {
		["planetaris-calcite-particle-manipulation"] = { ingredients = {
			{ type = "item", name = "kr-quartz", amount = amount }, { type = "item", name = "other", amount = 2 } } },
		["kr-matter-to-kr-quartz"] = { enabled = true },
	}, {
		["matter-quartz"] = { effects = { { type = "unlock-recipe", recipe = "kr-matter-to-kr-quartz" } } },
		["kept"] = { effects = { { type = "unlock-recipe", recipe = "kr-matter-to-kr-quartz" }, { type = "unlock-recipe", recipe = "other" } } },
	}
end

local raw = support.install(fixture(2))
fix.data_final_fixes()
local ingredients = raw.recipe["planetaris-calcite-particle-manipulation"].ingredients
check(ingredients[1].amount == 24 and ingredients[2].amount == 2, "Calcite takes 24 quartz and nothing else changes")
check(raw.recipe["kr-matter-to-kr-quartz"].hidden == true and raw.recipe["kr-matter-to-kr-quartz"].enabled == false,
	"Matter to quartz is hidden")
check(raw.technology["matter-quartz"].hidden == true and #raw.technology.kept.effects == 1 and raw.technology.kept.hidden == nil,
	"The technology with nothing left is hidden, the other keeps its recipe")
check(support.logged("planetaris-calcite-particle-manipulation takes 24 quartz") == 1
	and support.logged("recipe kr-matter-to-kr-quartz hidden") == 1 and support.logged("technology matter-quartz hidden") == 1
	and #support.logs == 3 and support.logs[1]:find("^razi%-protocol: "), "A line for each change")

-- An amount the author changed stays; the matter recipe is hidden all the same.
for _, amount in ipairs({ 24, 16, 1 }) do
	raw = support.install(fixture(amount))
	fix.data_final_fixes()
	check(raw.recipe["planetaris-calcite-particle-manipulation"].ingredients[1].amount == amount
		and support.logged("takes 24 quartz") == 0, "An amount of " .. amount .. " stays")
end

-- Nothing installed: quiet.
support.install({}, {})
fix.data_final_fixes()
check(#support.logs == 0, "No recipes, no change")

-- Through the level.
support.gate(loops, function() return fixture(2) end, function(data_raw)
	return data_raw.recipe["planetaris-calcite-particle-manipulation"].ingredients[1].amount == 24
		and data_raw.recipe["kr-matter-to-kr-quartz"].hidden == true
end)

print("test_balance_quartz_and_calcite: ok")
