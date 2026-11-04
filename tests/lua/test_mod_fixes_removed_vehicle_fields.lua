---@diagnostic disable: missing-fields, need-check-nil, inject-field
-- The fields of a vehicle that Factorio 2.1 replaced move to the new ones, on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_mod_fixes_removed_vehicle_fields.lua
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
-- The conversion of the game: power per second to energy per tick.
package.preload["__core__.lualib.util"] = function()
	return {parse_energy = function(text)
		local number, unit = text:match("^([%d%.]+)(%a+)$")
		return tonumber(number) * ({kW = 1000, MW = 1000000})[unit] / 60
	end}
end

local fix = require("prototypes.fixes.common.removed_vehicle_fields")

local cars = {
	tank = {braking_power = "1.75MW", braking_force = 13333, friction_force = 2},
	buggy = {braking_power = "750kW", friction = 0.0025, braking_force = 3333, friction_force = 0.002},
	prop = {friction = 1e-99, friction_force = 2},
	numeric = {braking_power = 500, braking_force = 1},
	current = {braking_force = 7, friction_force = 3},
}
local spider = {friction = 0.005, friction_force = 1}
rawset(_G, "data", {raw = {car = cars, ["spider-vehicle"] = {submarine = spider}}})
fix.data_final_fixes()

check(math.abs(cars.tank.braking_force - 1750000 / 60) < 0.001 and cars.tank.braking_power == nil, "The tank takes 1.75 MW")
check(cars.tank.friction_force == 2, "A field the mod did not write stays")
check(math.abs(cars.buggy.braking_force - 12500) < 0.001 and cars.buggy.friction_force == 0.0025, "The buggy takes both")
check(cars.buggy.braking_power == nil and cars.buggy.friction == nil, "The old fields go")
check(cars.prop.friction_force == 1e-99 and cars.prop.friction == nil, "The stand-in takes its friction")
check(cars.numeric.braking_force == 500, "A number is taken as it is")
check(cars.current.braking_force == 7 and cars.current.friction_force == 3, "A car with the new fields stays")
check(spider.friction == 0.005 and spider.friction_force == 1, "A spider vehicle stays")
check(#logs == 5 and logs[1]:find("^razi%-protocol: "), "One line per change")

fix.data_final_fixes()
check(#logs == 5, "A second run changes nothing")

rawset(_G, "data", {raw = {}})
fix.data_final_fixes()
check(#logs == 5, "No cars, no change")

print("test_mod_fixes_removed_vehicle_fields: ok")
