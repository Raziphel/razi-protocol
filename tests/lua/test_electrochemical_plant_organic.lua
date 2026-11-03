---@diagnostic disable: missing-fields
-- The electrochemical plant makes no organic recipes, on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_electrochemical_plant_organic.lua
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

local balance = require("prototypes.balance.xy-k2so-enhancements-nulls-fork.electrochemical_plant_organic")

local categories = {"electromagnetics", "organic", "chemistry"}
rawset(_G, "data", {raw = {["assembling-machine"] = {["electrochemical-plant"] = {crafting_categories = categories}}}})
balance.data_final_fixes()
check(#categories == 2 and categories[1] == "electromagnetics" and categories[2] == "chemistry",
	"The plant must lose organic and keep its other categories")
check(#logs == 1 and logs[1]:find("^razi%-protocol: "), "One line for the change")

balance.data_final_fixes()
check(#logs == 1, "A second run changes nothing")

rawset(_G, "data", {raw = {}})
balance.data_final_fixes()
check(#logs == 1, "No plant, no change")

print("test_electrochemical_plant_organic: ok")
