---@diagnostic disable: missing-fields, need-check-nil, inject-field
-- With Crushing Industry's "Crushed ore" off, Arcanyx, Plasma Crafter and Voidcraft no longer point at crushed ore that
-- does not exist, on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_mod_fixes_crushed_ore_off.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(condition, message)
	if not condition then
		error(message, 2)
	end
end

local logs = {}
rawset(_G, "log", function(line)
	logs[#logs + 1] = line
end)

local arcanyx = require("prototypes.fixes.Arcanyx.crushed_creation_unlock")
local plasma = require("prototypes.fixes.plasma_crafter.crushed_ore_melting")
local voidcraft = require("prototypes.fixes.Voidcraft.crushed_prismite_sand")

local function plasma_recipe(crushed)
	return {ingredients = {
		{type = "fluid", name = "fusion-plasma", amount = 10},
		{type = "item", name = crushed, amount = 75},
	}}
end

local function sand_recipe()
	return {ingredients = {
		{type = "item", name = "crushed-prismite-ore", amount = 10},
		{type = "fluid", name = "void-flux", amount = 5},
	}}
end

local function world(crushed_ore)
	local items = {["iron-ore"] = {}, ["copper-ore"] = {}, ["prismite-ore"] = {}}
	local recipes = {
		["plasma-molten-iron"] = plasma_recipe("crushed-iron-ore"),
		["plasma-molten-copper"] = plasma_recipe("crushed-copper-ore"),
		["s6x-prismiteconv-sand"] = sand_recipe(),
		["s6x-prismiteconv-coh-sand"] = sand_recipe(),
		["s6x-entropic-creation"] = {},
	}
	if crushed_ore then
		items["crushed-iron-ore"], items["crushed-copper-ore"], items["crushed-prismite-ore"] = {}, {}, {}
		recipes["s6x-entropic-creation-crushed"] = {}
	end
	local technology = {effects = {
		{type = "unlock-recipe", recipe = "s6x-entropic-creation"},
		{type = "unlock-recipe", recipe = "s6x-entropic-creation-crushed"},
	}}
	rawset(_G, "data", {raw = {item = items, recipe = recipes, technology = {["s6x-entropic-creation"] = technology}}})
	return recipes, technology
end

local function run()
	arcanyx.data_final_fixes()
	plasma.data_final_fixes()
	voidcraft.data_final_fixes()
end

-- Crushed ore off: every reference to it goes.
local recipes, technology = world(false)
run()
check(#technology.effects == 1 and technology.effects[1].recipe == "s6x-entropic-creation",
	"The research no longer unlocks the missing crushed recipe and keeps the other")
local iron = recipes["plasma-molten-iron"].ingredients[2]
check(iron.name == "iron-ore" and iron.amount == 50, "Plasma melting takes 50 iron ore, as without Crushing Industry")
local copper = recipes["plasma-molten-copper"].ingredients[2]
check(copper.name == "copper-ore" and copper.amount == 50, "Plasma melting takes 50 copper ore")
check(recipes["plasma-molten-iron"].ingredients[1].name == "fusion-plasma", "The plasma stays")
check(recipes["s6x-prismiteconv-sand"].ingredients[1].name == "prismite-ore"
	and recipes["s6x-prismiteconv-coh-sand"].ingredients[1].name == "prismite-ore",
	"Both prismite sand recipes take prismite ore")
check(recipes["s6x-prismiteconv-sand"].ingredients[1].amount == 10, "The amount stays")
check(#logs == 5, "Every change is logged")

-- A second pass finds nothing left to do.
run()
check(#logs == 5, "A repaired recipe stays as it is")

-- Crushed ore on: nothing changes.
logs = {}
recipes, technology = world(true)
run()
check(#technology.effects == 2, "The crushed recipe stays unlocked")
check(recipes["plasma-molten-iron"].ingredients[2].name == "crushed-iron-ore", "Plasma melting keeps crushed ore")
check(recipes["s6x-prismiteconv-sand"].ingredients[1].name == "crushed-prismite-ore", "Sand keeps crushed prismite")
check(#logs == 0, "Nothing is logged")

-- Without the mods nothing happens.
rawset(_G, "data", {raw = {}})
run()

print("test_mod_fixes_crushed_ore_off: ok")
