---@diagnostic disable: missing-fields, inject-field
-- The research data of Paracelsin and Rubia from the Krastorio compatibility mods get their planet back.
-- Run from the mod root with the library bootstrap: tests/run.sh
package.path = "./?.lua;./?/init.lua;" .. package.path

local support = require("tests.lua.loops_support")
local check = support.check

local fix = require("prototypes.fixes.common.research_data_surfaces")

local PARACELSIN_PRESSURE = 5300

local function install(galvanization, with_electrochemistry)
	local categories = {["kr-tech-cards"] = {}}
	if with_electrochemistry ~= false then
		categories["electrochemistry"] = {}
	end

	return support.install({["galvanization-research-data"] = galvanization}, {}, {
		["recipe-category"] = categories,
		planet = {paracelsin = {surface_properties = {pressure = PARACELSIN_PRESSURE}}},
	})
end

-- The copy from the tech card recipe: research server on any planet.
local raw = install({categories = {"kr-tech-cards"}})
fix.data_final_fixes()
local recipe = raw.recipe["galvanization-research-data"]
check(support.same(recipe.categories, {"electrochemistry"}), "galvanization research data is made in the electrochemical plant")
check(recipe.surface_conditions[1].min == PARACELSIN_PRESSURE, "galvanization research data keeps the pressure of Paracelsin")
check(support.logged("electrochemical plant") == 1, "the change is logged")

-- A machine chosen by another mod stays.
raw = install({categories = {"organic"}})
fix.data_final_fixes()
check(support.same(raw.recipe["galvanization-research-data"].categories, {"organic"}), "another category stays")
check(support.logged("electrochemical plant") == 0, "nothing is logged when nothing changes")

-- Without Paracelsin's category the recipe keeps the research server.
raw = install({categories = {"kr-tech-cards"}}, false)
fix.data_final_fixes()
check(support.same(raw.recipe["galvanization-research-data"].categories, {"kr-tech-cards"}), "no electrochemistry, no change")

-- Without the recipe nothing fails.
install(nil)
fix.data_final_fixes()

print("ok")
