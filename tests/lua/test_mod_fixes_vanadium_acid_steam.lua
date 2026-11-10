---@diagnostic disable: missing-fields
-- The vanadium acid of Shchierbin takes the steam it is fed, on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_mod_fixes_vanadium_acid_steam.lua
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

local fix = require("prototypes.fixes.shchierbin.vanadium_acid_steam")

local function install(ingredients)
	rawset(_G, "data", {raw = {recipe = {["sulfuric-acid-vanadium"] = {ingredients = ingredients}}}})
	return ingredients
end

local ingredients = install({
	{type = "fluid", name = "steam", amount = 100, temperature = 165},
	{type = "item", name = "vanadium-oxide-catalyst", amount = 1},
})
fix.data_final_fixes()
check(ingredients[1].temperature == nil and ingredients[1].minimum_temperature == 165
	and ingredients[1].maximum_temperature == 500, "The acid takes steam from 165 to 500 degrees")
check(ingredients[2].temperature == nil, "The catalyst is untouched")
check(#logs == 1 and logs[1]:find("^razi%-protocol: "), "One line for the change")

fix.data_final_fixes()
check(#logs == 1, "A second run changes nothing")

ingredients = install({
	{type = "fluid", name = "steam", amount = 100, temperature = 500},
	{type = "fluid", name = "water", amount = 100, temperature = 165},
})
fix.data_final_fixes()
check(ingredients[1].temperature == 500 and ingredients[1].minimum_temperature == nil and ingredients[2].temperature == 165,
	"Other steam and other fluids stay")

rawset(_G, "data", {raw = {}})
fix.data_final_fixes()
check(#logs == 1, "No recipe, no change")

print("test_mod_fixes_vanadium_acid_steam: ok")
