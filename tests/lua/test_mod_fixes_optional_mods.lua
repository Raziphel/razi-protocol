---@diagnostic disable: missing-fields
-- Repairs of the data of mods that Razi lists as optional (prototypes/fixes/): Aircraft Space Age, Eneas, Pelagos and
-- Cerys, on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_mod_fixes_optional_mods.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(value, message)
	if not value then
		error(message, 2)
	end
end

local logs = {}
rawset(_G, "log", function(message) logs[#logs + 1] = message end)

local function logged(text)
	local count = 0
	for _, line in ipairs(logs) do
		if line:find(text, 1, true) then
			count = count + 1
		end
	end

	return count
end

local function deepcopy(value)
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for key, item in pairs(value) do
		copy[key] = deepcopy(item)
	end

	return copy
end

local function same(left, right)
	if type(left) ~= "table" or type(right) ~= "table" then
		return left == right
	end
	for key, item in pairs(left) do
		if not same(item, right[key]) then
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

---@return any
local function fresh()
	logs = {}
	local raw = {}
	rawset(_G, "data", {raw = raw})
	rawset(_G, "mods", {})
	rawset(_G, "defines", {prototypes = {item = {item = 1}, entity = {}}})
	return raw
end

local fixes = require("prototypes.fixes.init")

-- Nothing of the mods is installed: every repair is quiet and does not fail.
---@type any
local raw = fresh()
fixes.data_final_fixes()
check(#logs == 0 and next(raw) == nil, "A repair did something without its prototypes")
raw = fresh()
for _, name in ipairs({"recipe", "technology", "item", "car", "roboport", "lamp", "mod-data", "fuel-category"}) do
	raw[name] = {}
end
fixes.data_final_fixes()
check(#logs == 0, "A repair logged on empty prototype tables")

-- Aircraft-space-age vehicle_fuel
local vehicle_fuel = require("prototypes.fixes.Aircraft-space-age.vehicle_fuel")
local function plane(categories)
	return {type = "car", energy_source = {type = "burner", fuel_categories = categories}}
end
raw = fresh()
raw["fuel-category"] = {["kr-vehicle-fuel"] = {}}
raw.car = {
	gunship = plane({"chemical"}),
	["cargo-plane-carbon-fiber"] = plane({"chemical"}),
	["rubia-auto-variant-jet"] = plane({"chemical"}),
	["rubia-auto-variant-flying-fortress-carbon-fiber"] = plane({"chemical"}),
	["not-a-plane"] = plane({"chemical"}),
	jet = plane({"chemical", "kr-vehicle-fuel"}),
	tank = plane({"kr-vehicle-fuel"}),
	car = plane({"chemical"}),
	["not-a-burner"] = {type = "car", energy_source = {type = "electric"}},
	["no-energy"] = {type = "car"},
}
raw.car["flying-fortress"] = {type = "car", energy_source = {type = "burner"}}
raw.car["cargo-plane"] = plane({"nuclear"})
local others = deepcopy({raw.car.tank, raw.car.car, raw.car["not-a-plane"], raw.car["not-a-burner"],
	raw.car["no-energy"], raw.car["flying-fortress"], raw.car["cargo-plane"], raw.car.jet})
vehicle_fuel.data_final_fixes()
for _, name in ipairs({"gunship", "cargo-plane-carbon-fiber", "rubia-auto-variant-jet",
	"rubia-auto-variant-flying-fortress-carbon-fiber"}) do
	local categories = raw.car[name].energy_source.fuel_categories
	check(#categories == 2 and categories[1] == "chemical" and categories[2] == "kr-vehicle-fuel",
		"A plane does not take the vehicle fuel too: " .. name)
	check(logged("razi-protocol: " .. name .. " also takes kr-vehicle-fuel") == 1, "Expected one line for " .. name)
end
check(same(others, {raw.car.tank, raw.car.car, raw.car["not-a-plane"], raw.car["not-a-burner"],
	raw.car["no-energy"], raw.car["flying-fortress"], raw.car["cargo-plane"], raw.car.jet}),
	"A vehicle that is no plane, takes the fuel already or burns no chemical fuel was changed")
check(#logs == 4, "A vehicle that was not changed was logged")
vehicle_fuel.data_final_fixes()
check(#logs == 4 and #raw.car.gunship.energy_source.fuel_categories == 2, "The repeated run changed the planes again")
raw = fresh()
raw.car = {gunship = plane({"chemical"})}
vehicle_fuel.data_final_fixes()
check(#raw.car.gunship.energy_source.fuel_categories == 1 and #logs == 0, "A plane was changed without the K2 fuel")
raw = fresh()
raw["fuel-category"] = {["kr-vehicle-fuel"] = {}}
vehicle_fuel.data_final_fixes()
check(next(raw.car or {}) == nil and #logs == 0, "Something changed without cars")

print("mod fixes (optional mods): ok")
