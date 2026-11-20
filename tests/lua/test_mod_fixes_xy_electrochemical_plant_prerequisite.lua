---@diagnostic disable: missing-fields, need-check-nil, inject-field
-- The electrochemical plant is researched after the advanced chemical plant that its recipe needs.
-- Run from the mod root with the library bootstrap: tests/run.sh
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local logs = {}
rawset(_G, "log", function(line)
	logs[#logs + 1] = line
end)

local fix = require("prototypes.fixes.xy-k2so-enhancements-nulls-fork.electrochemical_plant_prerequisite")

local function count(list, value)
	local found = 0
	for _, entry in ipairs(list or {}) do
		if entry == value then
			found = found + 1
		end
	end
	return found
end

-- The tree after the progression of razi: Paracelsin discovery no longer requires the advanced chemical plant.
local function world(discovery_prerequisites, ingredients)
	logs = {}
	local technologies = {
		["vibrant-discovery"] = {prerequisites = {}},
		["kr-advanced-chemical-plant"] = {prerequisites = {}},
		["planet-discovery-paracelsin"] = {prerequisites = discovery_prerequisites or {"vibrant-discovery"}},
		["zinc-extraction"] = {prerequisites = {"planet-discovery-paracelsin"}},
		["electrochemical-plant"] = {prerequisites = {"zinc-extraction"}},
	}
	rawset(_G, "data", {raw = {
		technology = technologies,
		recipe = {["electrochemical-plant"] = {ingredients = ingredients or {
			{type = "item", name = "processing-unit", amount = 40},
			{type = "item", name = "kr-advanced-chemical-plant", amount = 1},
		}}},
	}})
	return technologies
end

-- The recipe needs the machine and nothing before the plant requires it.
local technologies = world()
fix.data_final_fixes()
local prerequisites = technologies["electrochemical-plant"].prerequisites
check(count(prerequisites, "kr-advanced-chemical-plant") == 1, "the plant requires the advanced chemical plant")
check(count(prerequisites, "zinc-extraction") == 1, "the old prerequisite stays")
check(#logs == 1, "the change is logged")

-- Running twice adds nothing.
fix.data_final_fixes()
check(count(technologies["electrochemical-plant"].prerequisites, "kr-advanced-chemical-plant") == 1, "added once")

-- When the discovery already requires it, as xy-k2so-enhancements-nulls-fork wants, nothing changes.
technologies = world({"vibrant-discovery", "kr-advanced-chemical-plant"})
fix.data_final_fixes()
check(count(technologies["electrochemical-plant"].prerequisites, "kr-advanced-chemical-plant") == 0, "already required")
check(#logs == 0, "nothing is logged")

-- A recipe without the machine needs no new prerequisite.
technologies = world(nil, {{type = "item", name = "processing-unit", amount = 40}})
fix.data_final_fixes()
check(count(technologies["electrochemical-plant"].prerequisites, "kr-advanced-chemical-plant") == 0, "recipe without it")

-- Without the technologies nothing fails.
rawset(_G, "data", {raw = {technology = {}, recipe = {}}})
fix.data_final_fixes()

print("ok")
