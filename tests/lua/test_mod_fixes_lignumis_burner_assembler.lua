---@diagnostic disable: missing-fields, need-check-nil, inject-field
-- The Lignumis burner assembler can be made on Lignumis with AAI Industry and Krastorio 2.
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

local fix = require("prototypes.fixes.aai-industry.lignumis_burner_assembler")

local function item(name, amount)
	return {type = "item", name = name, amount = amount}
end

-- The recipe as the pack loads it: Lignumis wood parts plus the cores from AAI Industry.
local function lignumis_recipe()
	return {ingredients = {
		item("wooden-gear-wheel", 5),
		item("lumber", 8),
		item("basic-circuit-board", 5),
		item("kr-automation-core", 2),
	}}
end

local function world(recipe, installed)
	logs = {}
	rawset(_G, "mods", installed or {lignumis = "2.12.4", ["aai-industry"] = "0.7.5"})
	rawset(_G, "data", {raw = {recipe = {["burner-assembling-machine"] = recipe}}})
	return recipe
end

local function names(recipe)
	local list = {}
	for _, ingredient in ipairs(recipe.ingredients) do
		list[#list + 1] = ingredient.name
	end
	return table.concat(list, ",")
end

local recipe = world(lignumis_recipe())
fix.data_final_fixes()
check(names(recipe) == "wooden-gear-wheel,lumber,basic-circuit-board",
	"the Lignumis recipe keeps only its wooden parts, got " .. names(recipe))
check(#logs == 1, "the change is logged")

-- Run twice: nothing more to remove.
fix.data_final_fixes()
check(#logs == 1 and #recipe.ingredients == 3, "a second run changes nothing")

-- The AAI Industry recipe (no Lignumis parts) keeps its cores.
recipe = world({ingredients = {item("iron-plate", 10), item("kr-automation-core", 2)}})
fix.data_final_fixes()
check(names(recipe) == "iron-plate,kr-automation-core" and #logs == 0, "the AAI Industry recipe is left alone")

-- A changed core amount is someone else's choice.
recipe = lignumis_recipe()
recipe.ingredients[4].amount = 3
world(recipe)
fix.data_final_fixes()
check(#recipe.ingredients == 4 and #logs == 0, "another amount of cores is left alone")

-- Without AAI Industry or without Lignumis nothing changes.
recipe = world(lignumis_recipe(), {lignumis = "2.12.4"})
fix.data_final_fixes()
check(#recipe.ingredients == 4 and #logs == 0, "without AAI Industry nothing changes")
recipe = world(lignumis_recipe(), {["aai-industry"] = "0.7.5"})
fix.data_final_fixes()
check(#recipe.ingredients == 4 and #logs == 0, "without Lignumis nothing changes")

-- No recipe: no crash.
world(nil)
fix.data_final_fixes()
check(#logs == 0, "a missing recipe is skipped")

print("test_mod_fixes_lignumis_burner_assembler ok")
