---@diagnostic disable: missing-fields, inject-field
-- Hyarion and Foliax recipes use the same research-data route as Krastorio 2.
-- Run from the mod root with the library bootstrap: tests/run.sh
package.path = "./?.lua;./?/init.lua;" .. package.path

local support = require("tests.lua.loops_support")
local check = support.check

local fix = require("prototypes.balance.common.promethium_research_data")

local DATA_NAME = "kr-promethium-research-data"
local HYARION_RECIPE = "planetaris-promethium-science-pack"
local FOLIAX_RECIPE = "foliax-promethium-science-pack"
local HYARION_COPY = "igrys-planetaris-promethium-science-pack-enhanced"
local FOLIAX_COPY = "igrys-foliax-promethium-science-pack-enhanced"
local OMNI_RECIPE = "advanced-promethium-science"
local OMNI_COPY = "igrys-advanced-promethium-science-enhanced"

local function item(name, amount)
	return {type = "item", name = name, amount = amount}
end

local function source_recipe(amount, extra)
	local result = item("promethium-science-pack", amount)
	result.ignored_by_productivity = 2
	local recipe = {
		results = {result},
		ingredients = {item("promethium-asteroid-chunk", 20)},
	}
	for key, value in pairs(extra or {}) do
		recipe[key] = support.copy(value)
	end

	return recipe
end

local function install(recipes, technologies, items)
	local other_prototypes = {item = items or {}}
	return support.install(recipes, technologies or {}, other_prototypes)
end

local function unlock(recipe)
	return {type = "unlock-recipe", recipe = recipe}
end

local recipes = {
	[HYARION_RECIPE] = source_recipe(15, {
		main_product = "promethium-science-pack",
		localised_name = {"item-name.promethium-science-pack"},
		localised_description = {"item-description.promethium-science-pack"},
	}),
	[FOLIAX_RECIPE] = source_recipe(10, {
		icon = "old-foliax-icon.png",
		icon_size = 64,
		icons = {{icon = "unused-extra-icon.png", icon_size = 32}},
		localised_description = {"item-description.foliax-promethium-science-pack"},
	}),
	[OMNI_RECIPE] = source_recipe(5),
	[HYARION_COPY] = source_recipe(15, {enabled = true, hidden = false}),
	[FOLIAX_COPY] = source_recipe(10, {enabled = true, hidden = false}),
	[OMNI_COPY] = source_recipe(5, {enabled = true, hidden = false}),
}
local original_ingredients = {
	[HYARION_RECIPE] = support.copy(recipes[HYARION_RECIPE].ingredients),
	[FOLIAX_RECIPE] = support.copy(recipes[FOLIAX_RECIPE].ingredients),
	[OMNI_RECIPE] = support.copy(recipes[OMNI_RECIPE].ingredients),
}
local raw = install(recipes, {
	promethium = {effects = {unlock(HYARION_COPY), unlock(FOLIAX_COPY), unlock(OMNI_COPY), unlock("other-recipe")}},
}, {
	[DATA_NAME] = {icon = "promethium-research-data.png"},
})

fix.data_final_fixes()

check(recipes[HYARION_RECIPE].results[1].name == DATA_NAME and recipes[HYARION_RECIPE].results[1].amount == 8,
	"Hyarion makes eight research data")
check(recipes[FOLIAX_RECIPE].results[1].name == DATA_NAME and recipes[FOLIAX_RECIPE].results[1].amount == 10,
	"Foliax makes ten research data")
check(recipes[OMNI_RECIPE].results[1].name == DATA_NAME and recipes[OMNI_RECIPE].results[1].amount == 5,
	"omni makes five research data")
check(recipes[HYARION_RECIPE].results[1].ignored_by_productivity == 2,
	"Other result fields stay untouched")
check(recipes[HYARION_RECIPE].main_product == DATA_NAME, "Hyarion main product follows the research data")
check(support.same(recipes[HYARION_RECIPE].localised_name, {"item-name." .. DATA_NAME}),
	"Hyarion recipe name follows the research data")
check(recipes[HYARION_RECIPE].localised_description == nil,
	"Hyarion recipe drops the science-pack description")
check(support.same(recipes[FOLIAX_RECIPE].localised_description,
	{"item-description.foliax-promethium-science-pack"}),
	"A different recipe description stays untouched")
check(recipes[FOLIAX_RECIPE].icon == "promethium-research-data.png"
	and recipes[FOLIAX_RECIPE].icon_size == nil and recipes[FOLIAX_RECIPE].icons == nil,
	"Foliax uses the data item icon and drops the old icon fields")
check(support.same(recipes[HYARION_RECIPE].ingredients, original_ingredients[HYARION_RECIPE])
	and support.same(recipes[FOLIAX_RECIPE].ingredients, original_ingredients[FOLIAX_RECIPE])
	and support.same(recipes[OMNI_RECIPE].ingredients, original_ingredients[OMNI_RECIPE]),
	"The recipes' ingredients stay unchanged")
check(support.logged(HYARION_RECIPE .. " makes 8 " .. DATA_NAME) == 1
	and support.logged(FOLIAX_RECIPE .. " makes 10 " .. DATA_NAME) == 1
	and support.logged(OMNI_RECIPE .. " makes 5 " .. DATA_NAME) == 1,
	"Each changed recipe has one change log")
check(recipes[HYARION_COPY].hidden == true and recipes[HYARION_COPY].enabled == false
	and recipes[FOLIAX_COPY].hidden == true and recipes[FOLIAX_COPY].enabled == false
	and recipes[OMNI_COPY].hidden == true and recipes[OMNI_COPY].enabled == false,
	"Igrys copies of changed recipes are hidden and disabled")
check(#raw.technology.promethium.effects == 1 and raw.technology.promethium.effects[1].recipe == "other-recipe",
	"Only unlocks for the hidden Igrys copies are removed")
check(#support.logs == 6, "Three recipe changes and three hidden Igrys copies are logged")

local after_first_call = support.copy(raw)
local log_count = #support.logs
fix.data_final_fixes()
check(support.same(raw, after_first_call) and #support.logs == log_count,
	"A repeated call makes no further changes or logs")

-- The prototype icon style may use layered icons. The recipe must get a deep copy.
recipes = {
	[HYARION_RECIPE] = source_recipe(15, {icons = {{icon = "old.png", icon_size = 64}}}),
}
local data_icons = {{icon = "base.png", icon_size = 64, tint = {r = 0.2, g = 0.3, b = 0.4}}}
install(recipes, {}, {[DATA_NAME] = {icons = data_icons}})
fix.data_final_fixes()
check(support.same(recipes[HYARION_RECIPE].icons, data_icons)
	and recipes[HYARION_RECIPE].icon == nil and recipes[HYARION_RECIPE].icon_size == nil,
	"Layered data icons replace recipe icon fields")
recipes[HYARION_RECIPE].icons[1].tint.r = 1
check(data_icons[1].tint.r == 0.2, "Layered recipe icons do not share nested tables with the item")

-- Without the research-data item, every recipe and Igrys copy stays unchanged.
recipes = {
	[HYARION_RECIPE] = source_recipe(15),
	[FOLIAX_RECIPE] = source_recipe(10),
	[HYARION_COPY] = source_recipe(15, {enabled = true, hidden = false}),
	[FOLIAX_COPY] = source_recipe(10, {enabled = true, hidden = false}),
}
raw = install(recipes, {promethium = {effects = {unlock(HYARION_COPY), unlock(FOLIAX_COPY)}}}, {})
local before = support.copy(raw)
fix.data_final_fixes()
check(support.same(raw, before) and #support.logs == 0, "A missing research-data item changes nothing")

-- Changed result amounts and multiple results do not qualify for the fix or copy hiding.
recipes = {
	[HYARION_RECIPE] = source_recipe(16),
	[FOLIAX_RECIPE] = source_recipe(10),
	[HYARION_COPY] = source_recipe(16, {enabled = true, hidden = false}),
	[FOLIAX_COPY] = source_recipe(10, {enabled = true, hidden = false}),
}
recipes[FOLIAX_RECIPE].results[2] = item("other-item", 1)
raw = install(recipes, {promethium = {effects = {unlock(HYARION_COPY), unlock(FOLIAX_COPY)}}}, {
	[DATA_NAME] = {icon = "promethium-research-data.png"},
})
before = support.copy(raw)
fix.data_final_fixes()
check(support.same(raw, before) and #support.logs == 0,
	"A changed amount or multiple results leave the recipe and Igrys copy alone")

-- Missing source recipes are harmless.
raw = install({}, {}, {[DATA_NAME] = {icon = "promethium-research-data.png"}})
fix.data_final_fixes()
check(#support.logs == 0 and next(raw.recipe) == nil, "Missing recipes are skipped")

print("test_balance_promethium_research_data: ok")
