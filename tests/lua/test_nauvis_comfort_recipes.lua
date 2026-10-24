---@diagnostic disable: missing-fields, assign-type-mismatch, need-check-nil
-- The stack inserter and the toolbelt equipment are made of low density structure and plastic instead of carbon fiber and jelly, and
-- their recycling and crushing return the same (compat/nauvis_comfort_recipes.lua), on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_nauvis_comfort_recipes.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local logged = 0
rawset(_G, "log", function(_) logged = logged + 1 end)

local function item(name, amount, extra)
	local entry = {type = "item", name = name, amount = amount}
	for key, value in pairs(extra or {}) do
		entry[key] = value
	end
	return entry
end

local function setup()
	local recipes = {
		["stack-inserter"] = {name = "stack-inserter", ingredients = {item("bulk-inserter", 1), item("processing-unit", 1),
			item("carbon-fiber", 2), item("jelly", 10)}, results = {item("stack-inserter", 1)}},
		["stack-inserter-recycling"] = {name = "stack-inserter-recycling", ingredients = {item("stack-inserter", 1)},
			results = {item("bulk-inserter", 0, {extra_count_fraction = 0.25}), item("processing-unit", 0, {extra_count_fraction = 0.25}),
				item("carbon-fiber", 0, {extra_count_fraction = 0.5}), item("jelly", 2, {extra_count_fraction = 0.5})}},
		["kr-crush-stack-inserter"] = {name = "kr-crush-stack-inserter", ingredients = {item("stack-inserter", 1)},
			results = {item("kr-inserter-parts", 1), item("kr-electronic-components", 4), item("carbon-fiber", 1)}},
		["toolbelt-equipment"] = {name = "toolbelt-equipment", ingredients = {item("advanced-circuit", 3), item("carbon-fiber", 10)},
			results = {item("toolbelt-equipment", 1)}},
		["toolbelt-equipment-recycling"] = {name = "toolbelt-equipment-recycling", ingredients = {item("toolbelt-equipment", 1)},
			results = {item("advanced-circuit", 0, {extra_count_fraction = 0.75}), item("carbon-fiber", 2, {extra_count_fraction = 0.5})}},
		["kr-crush-toolbelt-equipment"] = {name = "kr-crush-toolbelt-equipment", ingredients = {item("toolbelt-equipment", 1)}},
		-- the same ingredients, a different item: left alone
		["stack-heat-inserter"] = {name = "stack-heat-inserter", ingredients = {item("bulk-heat-inserter", 1), item("carbon-fiber", 2),
			item("jelly", 10)}, results = {item("stack-heat-inserter", 1)}},
		["stack-inserter-from-gel"] = {name = "stack-inserter-from-gel", ingredients = {item("bulk-inserter", 1), item("carbon-fiber", 2),
			item("slimy-gel", 200)}, results = {item("stack-inserter", 1)}},
	}
	local items = {}
	for _, name in ipairs({"low-density-structure", "plastic-bar", "carbon-fiber", "jelly"}) do
		items[name] = {name = name}
	end
	rawset(_G, "data", {raw = {recipe = recipes, item = items}})
	package.loaded["prototypes.compat.nauvis_comfort_recipes"] = nil
	return recipes, require("prototypes.compat.nauvis_comfort_recipes")
end

local function find(list, name)
	for _, entry in ipairs(list) do
		if (entry.name or entry[1]) == name then
			return entry
		end
	end
end

local recipes, module = setup()
module.data_final_fixes()

-- the recipes
local stack = recipes["stack-inserter"]
check(not find(stack.ingredients, "carbon-fiber") and not find(stack.ingredients, "jelly"), "the stack inserter takes no carbon fiber and no jelly")
check(find(stack.ingredients, "low-density-structure").amount == 1, "the stack inserter takes one low density structure")
check(find(stack.ingredients, "plastic-bar").amount == 10, "the stack inserter takes ten plastic bars")
check(#stack.ingredients == 4 and find(stack.ingredients, "bulk-inserter").amount == 1
	and find(stack.ingredients, "processing-unit").amount == 1, "the rest of the stack inserter stays")
local toolbelt = recipes["toolbelt-equipment"]
check(not find(toolbelt.ingredients, "carbon-fiber"), "the toolbelt equipment takes no carbon fiber")
check(find(toolbelt.ingredients, "low-density-structure").amount == 3 and find(toolbelt.ingredients, "advanced-circuit").amount == 3,
	"the toolbelt equipment takes three low density structures and its circuits")
check(logged > 0, "the changes are logged")

-- the recycling returns a quarter of the new ingredients
local back = recipes["stack-inserter-recycling"].results
check(not find(back, "carbon-fiber") and not find(back, "jelly"), "the stack inserter recycling returns no carbon fiber and no jelly")
local structure = find(back, "low-density-structure")
check(structure.amount == 0 and structure.extra_count_fraction == 0.25, "a quarter of a low density structure")
local plastic = find(back, "plastic-bar")
check(plastic.amount == 2 and plastic.extra_count_fraction == 0.5, "two and a half plastic bars")
check(#back == 4 and find(back, "bulk-inserter").extra_count_fraction == 0.25, "the rest of the recycling stays")
back = recipes["toolbelt-equipment-recycling"].results
check(not find(back, "carbon-fiber"), "the toolbelt equipment recycling returns no carbon fiber")
structure = find(back, "low-density-structure")
check(structure.amount == 0 and structure.extra_count_fraction == 0.75, "three quarters of a low density structure")

-- the crushing gives back half of the structure by chance, and no carbon fiber
back = recipes["kr-crush-stack-inserter"].results
check(not find(back, "carbon-fiber"), "the crushing gives no carbon fiber")
structure = find(back, "low-density-structure")
check(structure.amount == 1 and structure.probability == 0.5, "the crushing gives a low density structure by chance")
check(#back == 3 and find(back, "kr-electronic-components").amount == 4, "the rest of the crushing stays")
check(recipes["kr-crush-toolbelt-equipment"].results == nil, "the void crushing of the toolbelt equipment is untouched")

-- other recipes keep their ingredients
check(find(recipes["stack-heat-inserter"].ingredients, "carbon-fiber").amount == 2
	and find(recipes["stack-heat-inserter"].ingredients, "jelly").amount == 10, "the heat stack inserter is untouched")
check(find(recipes["stack-inserter-from-gel"].ingredients, "carbon-fiber").amount == 2, "the slimy gel recipe keeps its carbon fiber")

-- a second pass changes nothing
logged = 0
module.data_final_fixes()
check(logged == 0 and #stack.ingredients == 4 and find(stack.ingredients, "plastic-bar").amount == 10, "the second pass is idempotent")

-- a recipe that is not the original is left alone, with its recycling and crushing
recipes, module = setup()
find(recipes["stack-inserter"].ingredients, "jelly").amount = 20
module.data_final_fixes()
check(find(recipes["stack-inserter"].ingredients, "carbon-fiber") and find(recipes["stack-inserter"].ingredients, "jelly").amount == 20,
	"a changed recipe stays")
check(find(recipes["stack-inserter-recycling"].results, "carbon-fiber") and find(recipes["kr-crush-stack-inserter"].results, "carbon-fiber"),
	"its recycling and crushing stay")
check(find(recipes["toolbelt-equipment"].ingredients, "low-density-structure"), "the toolbelt equipment is still changed")

-- a recycling that is not a quarter stays; the recipe changes
recipes, module = setup()
find(recipes["toolbelt-equipment-recycling"].results, "carbon-fiber").amount = 3
module.data_final_fixes()
check(find(recipes["toolbelt-equipment"].ingredients, "low-density-structure"), "the recipe changes")
check(find(recipes["toolbelt-equipment-recycling"].results, "carbon-fiber"), "an altered recycling is left as it is")

recipes, module = setup()
find(recipes["toolbelt-equipment-recycling"].results, "carbon-fiber").extra_count_fraction = 0.25
module.data_final_fixes()
check(find(recipes["toolbelt-equipment-recycling"].results, "carbon-fiber"), "a recycling with another chance is left as it is")

-- a crushing that is not the original stays
recipes, module = setup()
find(recipes["kr-crush-stack-inserter"].results, "carbon-fiber").amount = 2
module.data_final_fixes()
check(find(recipes["kr-crush-stack-inserter"].results, "carbon-fiber").amount == 2, "an altered crushing is left as it is")

-- the new ingredient is already there: the amounts add up
recipes, module = setup()
table.insert(recipes["stack-inserter"].ingredients, item("plastic-bar", 5))
table.insert(recipes["stack-inserter-recycling"].results, item("plastic-bar", 1, {extra_count_fraction = 0.75}))
module.data_final_fixes()
check(find(recipes["stack-inserter"].ingredients, "plastic-bar").amount == 15 and #recipes["stack-inserter"].ingredients == 4,
	"the plastic bars add up in the recipe")
local count = 0
for _, entry in ipairs(recipes["stack-inserter-recycling"].results) do
	if entry.name == "plastic-bar" then
		count = count + 1
	end
end
local carried = find(recipes["stack-inserter-recycling"].results, "plastic-bar")
check(carried.amount == 4 and carried.extra_count_fraction == 0.25, "and in the recycling, with the fraction carried")
check(count == 1, "one plastic bar entry in the recycling")

-- no new item, no recipe, no data: nothing happens
recipes, module = setup()
data.raw.item["low-density-structure"] = nil
module.data_final_fixes()
check(find(recipes["stack-inserter"].ingredients, "carbon-fiber") and find(recipes["toolbelt-equipment"].ingredients, "carbon-fiber"),
	"without the new ingredient nothing changes")
recipes, module = setup()
recipes["stack-inserter"] = nil
recipes["toolbelt-equipment-recycling"] = nil
module.data_final_fixes()
check(find(recipes["toolbelt-equipment"].ingredients, "low-density-structure"), "without the stack inserter the toolbelt equipment is changed")
rawset(_G, "data", {raw = {}})
package.loaded["prototypes.compat.nauvis_comfort_recipes"] = nil
require("prototypes.compat.nauvis_comfort_recipes").data_final_fixes()

-- It is wired in, after the last pass that adds recipes and before the menu pass.
local file = assert(io.open("data-final-fixes.lua", "r"))
local source = file:read("*a")
file:close()
local battery = assert(source:find('require("prototypes.compat.lithium_battery").data_final_fixes()', 1, true))
local pass = assert(source:find('require("prototypes.compat.nauvis_comfort_recipes").data_final_fixes()', 1, true))
local menu = assert(source:find('require("prototypes.compat.crafting_navigation").data_final_fixes()', 1, true))
check(battery < pass and pass < menu, "the pass runs after the late recipe passes and before the menu pass")

print("nauvis_comfort_recipes: ok")
