---@diagnostic disable: missing-fields, need-check-nil, undefined-field, inject-field
-- Rocket-Silo Construction data-final-fixes compatibility on mocked prototypes.
-- Run from the mod root: lua5.2 tests/lua/test_rocket_silo_construction.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local function same_value(left, right)
	if left == right then
		return true
	end
	if type(left) ~= "table" or type(right) ~= "table" then
		return false
	end
	for key, value in pairs(left) do
		if not same_value(value, right[key]) then
			return false
		end
	end
	for key in pairs(right) do
		if left[key] == nil then
			return false
		end
	end
	return true
end

local function copy(value)
	if type(value) ~= "table" then
		return value
	end
	local result = {}
	for key, child in pairs(value) do
		result[key] = copy(child)
	end
	return result
end

local module_names = {
	"prototypes.compatibility.Rocket-Silo-Construction.stage_ingredients",
	"prototypes.compatibility.Rocket-Silo-Construction.surface_conditions",
	"prototypes.compatibility.Rocket-Silo-Construction.first_silo",
}

local function load_modules(raw, installed, multiplier)
	local messages = {}
	rawset(_G, "data", { raw = raw })
	rawset(_G, "mods", installed and { ["Rocket-Silo-Construction"] = "2.1.3" } or {})
	rawset(_G, "settings", { startup = multiplier and { ["rsc-st-cost-mp"] = { value = multiplier } } or {} })
	rawset(_G, "log", function(message)
		messages[#messages + 1] = message
	end)
	for _, name in ipairs(module_names) do
		package.loaded[name] = nil
	end
	return {
		stage_ingredients = require(module_names[1]),
		surface_conditions = require(module_names[2]),
		first_silo = require(module_names[3]),
	}, messages
end

local function foreign_ingredients()
	return {
		{ type = "item", name = "titanium-plate", amount = 5 },
		{ type = "item", name = "steel-beam", amount = 5 },
	}
end

local function prototype_data()
	local items = {}
	for _, name in ipairs({
		"concrete", "stone-brick", "steel-plate", "iron-stick", "titanium-plate", "steel-beam", "pipe",
		"pipe-to-ground", "copper-cable", "electronic-circuit", "copper-plate", "refined-concrete",
		"electric-engine-unit", "processing-unit", "advanced-circuit", "radar",
	}) do
		items[name] = {}
	end

	local recipes = {
		["rsc-construction-stage2"] = { ingredients = foreign_ingredients() },
		["rsc-construction-stage4"] = { ingredients = foreign_ingredients() },
		["rsc-construction-stage5"] = { ingredients = foreign_ingredients() },
		["rsc-construction-stage6"] = { ingredients = foreign_ingredients() },
		["rsc-excavation-site"] = {},
		["rocket-silo"] = { hidden = true, enabled = true, ingredients = {} },
	}
	local stage_conditions = { { property = "gravity", min = 0.1 } }
	local machines = {}
	for index = 1, 6 do
		machines["rsc-silo-stage" .. index] = { surface_conditions = copy(stage_conditions) }
	end

	return {
		item = items,
		fluid = { water = {} },
		recipe = recipes,
		technology = { ["space-platform"] = { effects = {} } },
		["rocket-silo"] = {
			["rocket-silo"] = {
				surface_conditions = {
					{ property = "pressure", min = 1, max = 300000 },
					{ property = "rabbasca-underground", min = 0, max = 0 },
				},
			},
		},
		["assembling-machine"] = machines,
		["surface-property"] = { gravity = {} },
	}
end

local function expect_ingredients(raw, recipe_name, expected)
	local actual = raw.recipe[recipe_name].ingredients
	check(same_value(actual, expected), recipe_name .. " has the wrong ingredients or order")
end

-- Without the optional mod, none of the three modules changes prototypes or logs.
local raw = prototype_data()
local original_stage2 = copy(raw.recipe["rsc-construction-stage2"].ingredients)
local original_hidden = raw.recipe["rocket-silo"].hidden
local original_conditions = copy(raw["assembling-machine"]["rsc-silo-stage1"].surface_conditions)
local modules, messages = load_modules(raw, false, 1)
modules.stage_ingredients.data_final_fixes()
modules.surface_conditions.data_final_fixes()
modules.first_silo.data_final_fixes()
check(same_value(raw.recipe["rsc-construction-stage2"].ingredients, original_stage2), "stage ingredients changed without RSC")
check(raw.recipe["rocket-silo"].hidden == original_hidden, "rocket-silo visibility changed without RSC")
check(same_value(raw["assembling-machine"]["rsc-silo-stage1"].surface_conditions, original_conditions),
	"stage conditions changed without RSC")
check(#messages == 0, "compatibility modules logged without RSC")

-- The four vanilla recipes replace foreign CheckItem results with the complete stable lists.
raw = prototype_data()
modules, messages = load_modules(raw, true, 1)
modules.stage_ingredients.data_final_fixes()
local stage2 = {
	{ type = "item", name = "concrete", amount = 50 },
	{ type = "item", name = "stone-brick", amount = 10 },
	{ type = "item", name = "steel-plate", amount = 20 },
	{ type = "item", name = "iron-stick", amount = 30 },
	{ type = "fluid", name = "water", amount = 500 },
}
local stage4 = {
	{ type = "item", name = "concrete", amount = 50 },
	{ type = "item", name = "stone-brick", amount = 10 },
	{ type = "item", name = "steel-plate", amount = 20 },
	{ type = "item", name = "iron-stick", amount = 30 },
	{ type = "item", name = "pipe", amount = 20 },
	{ type = "item", name = "pipe-to-ground", amount = 10 },
}
local stage5 = {
	{ type = "item", name = "stone-brick", amount = 10 },
	{ type = "item", name = "copper-cable", amount = 100 },
	{ type = "item", name = "electronic-circuit", amount = 20 },
	{ type = "item", name = "copper-plate", amount = 40 },
	{ type = "item", name = "steel-plate", amount = 10 },
}
local stage6 = {
	{ type = "item", name = "refined-concrete", amount = 10 },
	{ type = "item", name = "electric-engine-unit", amount = 5 },
	{ type = "item", name = "processing-unit", amount = 5 },
	{ type = "item", name = "advanced-circuit", amount = 10 },
	{ type = "item", name = "electronic-circuit", amount = 30 },
	{ type = "item", name = "radar", amount = 2 },
}
expect_ingredients(raw, "rsc-construction-stage2", stage2)
expect_ingredients(raw, "rsc-construction-stage4", stage4)
expect_ingredients(raw, "rsc-construction-stage5", stage5)
expect_ingredients(raw, "rsc-construction-stage6", stage6)
local ingredient_log_count = #messages
modules.stage_ingredients.data_final_fixes()
check(#messages == ingredient_log_count, "a repeated ingredient pass logged again")

-- RSC's cost multiplier rounds each ingredient amount up independently.
raw = prototype_data()
modules = load_modules(raw, true, 2.5)
modules.stage_ingredients.data_final_fixes()
check(raw.recipe["rsc-construction-stage2"].ingredients[1].amount == 125, "concrete was not scaled with ceil")
check(raw.recipe["rsc-construction-stage2"].ingredients[5].amount == 1250, "water was not scaled with ceil")
check(raw.recipe["rsc-construction-stage6"].ingredients[2].amount == 13, "electric-engine-unit was not scaled with ceil")

-- Missing recipes are ignored; a missing required prototype leaves that recipe unchanged and logs its name once.
raw = prototype_data()
raw.recipe = {}
modules, messages = load_modules(raw, true, 1)
modules.stage_ingredients.data_final_fixes()
check(#messages == 0, "an absent stage recipe logged an error")

raw = prototype_data()
raw.recipe = { ["rsc-construction-stage4"] = { ingredients = foreign_ingredients() } }
raw.item.pipe = nil
local original_stage4 = copy(raw.recipe["rsc-construction-stage4"].ingredients)
modules, messages = load_modules(raw, true, 1)
modules.stage_ingredients.data_final_fixes()
check(same_value(raw.recipe["rsc-construction-stage4"].ingredients, original_stage4),
	"stage recipe changed with a missing ingredient prototype")
check(#messages == 1 and string.find(messages[1], "rsc-construction-stage4", 1, true)
	and string.find(messages[1], "pipe", 1, true), "missing ingredient log did not name the recipe and prototype")
local missing_log_count = #messages
modules.stage_ingredients.data_final_fixes()
check(#messages == missing_log_count, "a repeated missing-prototype pass logged again")

-- Each stage receives its own deep copy of the silo's conditions plus RSC's gravity condition.
raw = prototype_data()
modules, messages = load_modules(raw, true, 1)
modules.surface_conditions.data_final_fixes()
local expected_conditions = {
	{ property = "pressure", min = 1, max = 300000 },
	{ property = "rabbasca-underground", min = 0, max = 0 },
	{ property = "gravity", min = 0.1 },
}
for index = 1, 6 do
	local stage_entity = raw["assembling-machine"]["rsc-silo-stage" .. index]
	check(same_value(stage_entity.surface_conditions, expected_conditions), "stage " .. index .. " has wrong surface conditions")
	check(stage_entity.surface_conditions ~= raw["rocket-silo"]["rocket-silo"].surface_conditions,
		"stage " .. index .. " shares the silo condition table")
	check(stage_entity.surface_conditions[1] ~= raw["rocket-silo"]["rocket-silo"].surface_conditions[1],
		"stage " .. index .. " shares a silo condition entry")
end
check(raw["assembling-machine"]["rsc-silo-stage1"].surface_conditions
	~= raw["assembling-machine"]["rsc-silo-stage2"].surface_conditions, "stages share their condition list")
local surface_log_count = #messages
modules.surface_conditions.data_final_fixes()
check(#messages == surface_log_count, "a repeated surface-condition pass logged again")
raw["assembling-machine"]["rsc-silo-stage1"].surface_conditions[1].min = 99
check(raw["rocket-silo"]["rocket-silo"].surface_conditions[1].min == 1
	and raw["assembling-machine"]["rsc-silo-stage2"].surface_conditions[1].min == 1,
	"changing one stage changed the silo or another stage")

-- An existing gravity condition is kept once; without the rocket-silo entity no stage is changed.
raw = prototype_data()
raw["rocket-silo"]["rocket-silo"].surface_conditions = {
	{ property = "pressure", min = 1, max = 300000 },
	{ property = "gravity", min = 1 },
}
modules = load_modules(raw, true, 1)
modules.surface_conditions.data_final_fixes()
local gravity_count = 0
for _, condition in ipairs(raw["assembling-machine"]["rsc-silo-stage1"].surface_conditions) do
	if condition.property == "gravity" then
		gravity_count = gravity_count + 1
		check(condition.min == 1, "existing gravity condition was replaced")
	end
end
check(gravity_count == 1, "a duplicate gravity condition was added")

raw = prototype_data()
raw["rocket-silo"] = nil
local prior_conditions = copy(raw["assembling-machine"]["rsc-silo-stage1"].surface_conditions)
modules, messages = load_modules(raw, true, 1)
modules.surface_conditions.data_final_fixes()
check(same_value(raw["assembling-machine"]["rsc-silo-stage1"].surface_conditions, prior_conditions)
	and #messages == 0, "stages changed without a rocket-silo entity")

-- The first staged silo restores visibility; Space platform unlocks the ordinary recipe exactly once.
raw = prototype_data()
modules, messages = load_modules(raw, true, 1)
modules.first_silo.data_final_fixes()
check(raw.recipe["rocket-silo"].hidden == false, "the regular rocket-silo recipe stayed hidden")
check(raw.recipe["rocket-silo"].enabled == true, "the regular rocket-silo recipe enabled state changed")
local effects = raw.technology["space-platform"].effects
check(#effects == 1 and effects[1].type == "unlock-recipe" and effects[1].recipe == "rocket-silo",
	"Space platform did not receive exactly one rocket-silo unlock")
local first_silo_log_count = #messages
modules.first_silo.data_final_fixes()
check(#messages == first_silo_log_count and #effects == 1, "a repeated first-silo pass changed or logged again")

-- The first-silo adjustment needs both recipes and the target technology.
raw = prototype_data()
raw.technology["space-platform"] = nil
modules, messages = load_modules(raw, true, 1)
modules.first_silo.data_final_fixes()
check(raw.recipe["rocket-silo"].hidden == true and #messages == 0, "first-silo changed without Space platform")

raw = prototype_data()
raw.recipe["rsc-excavation-site"] = nil
modules, messages = load_modules(raw, true, 1)
modules.first_silo.data_final_fixes()
check(raw.recipe["rocket-silo"].hidden == true and #raw.technology["space-platform"].effects == 0
	and #messages == 0, "first-silo changed without the excavation-site recipe")

rawset(_G, "data", nil)
rawset(_G, "mods", nil)
rawset(_G, "settings", nil)
rawset(_G, "log", nil)
print("test_rocket_silo_construction: ok")
