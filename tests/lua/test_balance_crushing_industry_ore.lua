---@diagnostic disable: missing-fields, need-check-nil, inject-field
-- Crushing Industry can keep its crushing route without replacing ore in these recipes.
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

local fix = require("prototypes.balance.crushing-industry.ore_recipes")

local function ingredient(name, amount)
	return {type = "item", name = name, amount = amount}
end

local function world(recipes, enabled, installed)
	logs = {}
	rawset(_G, "mods", installed == false and {} or {["crushing-industry"] = "0.6.9"})
	local startup = {}
	if enabled ~= nil then
		startup["crushing-industry-ore"] = {value = enabled}
	end
	rawset(_G, "settings", {startup = startup})
	local items = {
		["iron-ore"] = {}, ["copper-ore"] = {}, ["tungsten-ore"] = {}, ["holmium-ore"] = {},
		["crushed-iron-ore"] = {}, ["crushed-copper-ore"] = {}, ["crushed-tungsten-ore"] = {}, ["holmium-powder"] = {},
	}
	local recipe_table = recipes or {
		concrete = {ingredients = {ingredient("crushed-iron-ore", 1)}},
		["iron-ore-melting"] = {ingredients = {ingredient("crushed-iron-ore", 75)}},
		["copper-ore-melting"] = {ingredients = {ingredient("crushed-copper-ore", 75)}},
		["advanced-thruster-oxidizer"] = {ingredients = {ingredient("crushed-iron-ore", 4)}},
		["tungsten-plate"] = {ingredients = {ingredient("crushed-tungsten-ore", 8)}},
		["holmium-solution"] = {ingredients = {ingredient("holmium-powder", 3)}},
		["holmium-powder"] = {enabled = true, hidden = false},
	}
	rawset(_G, "data", {raw = {item = items, recipe = recipe_table, technology = {}}})
	return recipe_table
end

local recipes = world(nil, true)
fix.data_final_fixes()
local expected = {
	{"concrete", "iron-ore", 1, "crushed-iron-ore", 1},
	{"iron-ore-melting", "iron-ore", 50, "crushed-iron-ore", 75},
	{"copper-ore-melting", "copper-ore", 50, "crushed-copper-ore", 75},
	{"advanced-thruster-oxidizer", "iron-ore", 2, "crushed-iron-ore", 4},
	{"tungsten-plate", "tungsten-ore", 4, "crushed-tungsten-ore", 8},
	{"holmium-solution", "holmium-ore", 2, "holmium-powder", 3},
}
for index, row in ipairs(expected) do
	local actual = recipes[row[1]].ingredients[1]
	check(actual.name == row[2] and actual.amount == row[3], row[1] .. " did not return to ore")
	check(logs[index] == "razi-protocol: " .. row[1] .. " takes " .. row[3] .. " " .. row[2]
		.. " instead of " .. row[5] .. " " .. row[4] .. ", crushing the ore stays optional",
		row[1] .. " change must have one exact log")
end
check(recipes["holmium-powder"].hidden and recipes["holmium-powder"].enabled == false,
	"holmium-powder must be hidden after holmium-solution returns to ore")
check(#logs == 7 and logs[7] == "razi-protocol: recipe holmium-powder hidden",
	"all recipe changes and the hide must be logged")

-- A recipe already using ore is left alone and does not hide the powder.
recipes = world({
	["holmium-solution"] = {ingredients = {ingredient("holmium-ore", 2)}},
	["holmium-powder"] = {enabled = true, hidden = false},
}, true)
fix.data_final_fixes()
check(recipes["holmium-solution"].ingredients[1].name == "holmium-ore" and #logs == 0,
	"an ore recipe is unchanged")
check(recipes["holmium-powder"].hidden == false, "holmium-powder stays visible when no recipe changed")

-- An amount that does not divide by the Crushing Industry ratio is untouched.
recipes = world({["tungsten-plate"] = {ingredients = {ingredient("crushed-tungsten-ore", 5)}}}, true)
fix.data_final_fixes()
check(recipes["tungsten-plate"].ingredients[1].name == "crushed-tungsten-ore"
	and recipes["tungsten-plate"].ingredients[1].amount == 5 and #logs == 0,
	"a non-integral replacement is left alone")

-- The setting and mod are both optional, and missing recipes are harmless.
recipes = world(nil, false)
fix.data_final_fixes()
check(recipes.concrete.ingredients[1].name == "crushed-iron-ore" and #logs == 0, "ore crushing off changes nothing")
recipes = world(nil, true, false)
fix.data_final_fixes()
check(recipes.concrete.ingredients[1].name == "crushed-iron-ore" and #logs == 0, "missing Crushing Industry changes nothing")
world({}, true)
fix.data_final_fixes()
check(#logs == 0, "missing recipes are skipped")

print("test_balance_crushing_industry_ore ok")
