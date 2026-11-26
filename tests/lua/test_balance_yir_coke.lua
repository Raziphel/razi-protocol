---@diagnostic disable: lowercase-global
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local module_name = "prototypes.balance.yi_railway.coke_fuel"

local function run(fuel_value, options)
	options = options or {}
	local fuel
	if fuel_value ~= false then
		fuel = {fuel_value = fuel_value}
	end
	local raw = {item = fuel and {yir_fuel_coks = fuel} or {}}
	local logs = {}
	rawset(_G, "data", {raw = raw})
	rawset(_G, "mods", options.no_mod and {} or {yi_railway = "1.4.0"})
	rawset(_G, "log", function(message) logs[#logs + 1] = message end)
	package.loaded[module_name] = nil
	require(module_name).data_final_fixes()
	return fuel, logs
end

local fuel, logs = run("35MJ")
check(fuel ~= nil and fuel.fuel_value == "20MJ", "35 MJ YIR coke is capped at 20 MJ")
check(logs[1] == "razi-protocol: yi_railway: yir_fuel_coks fuel_value 35MJ -> 20MJ", "the coke balance is logged")

fuel, logs = run("30MJ")
check(fuel ~= nil and fuel.fuel_value == "30MJ", "a changed upstream value is left alone")
check(logs[1] == "razi-protocol: yi_railway: yir_fuel_coks fuel_value is 30MJ, expected 35MJ, left as is",
	"a changed upstream value is logged")

fuel, logs = run(false)
check(fuel == nil and #logs == 0, "a missing coke item is skipped quietly")

fuel, logs = run("35MJ", {no_mod = true})
check(fuel ~= nil and fuel.fuel_value == "35MJ" and #logs == 0, "the pass is inert without YIR")

print("test_balance_yir_coke: ok")
