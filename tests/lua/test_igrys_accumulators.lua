-- The Igrys accumulator ban spreads to the accumulators of other mods (prototypes/compatibility/Igrys/), on a mocked
-- data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_igrys_accumulators.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(value, message)
	if not value then
		error(message, 2)
	end
end

local logs = {}
rawset(_G, "log", function(message) logs[#logs + 1] = message end)

local function magic(entity)
	for _, condition in pairs(entity.surface_conditions or {}) do
		if condition.property == "igrys-magic" then
			return condition
		end
	end
end

local function fresh(installed)
	logs = {}
	local raw = {
		["surface-property"] = {["igrys-magic"] = {name = "igrys-magic"}},
		accumulator = {
			["accumulator"] = {name = "accumulator", surface_conditions = {{property = "igrys-magic", max = 0}}},
			["kr-energy-storage"] = {name = "kr-energy-storage", surface_conditions = {{property = "pressure", min = 1}}},
			["omega-accumulator"] = {name = "omega-accumulator"},
			["kr-planetary-teleporter"] = {name = "kr-planetary-teleporter"},
			["hidden-helper"] = {name = "hidden-helper", hidden = true}
		}
	}
	rawset(_G, "data", {raw = raw})
	rawset(_G, "mods", installed and {Igrys = "1.5.41"} or {})
	return raw
end

local igrys_accumulators = require("prototypes.compatibility.Igrys.igrys_accumulators")

local raw = fresh(true)
igrys_accumulators.data_final_fixes()
local storage = raw.accumulator["kr-energy-storage"]
check(magic(storage) and magic(storage).max == 0, "kr-energy-storage is not banned on Igrys")
check(#storage.surface_conditions == 2, "kr-energy-storage lost its own condition")
check(magic(raw.accumulator["omega-accumulator"]), "omega-accumulator is not banned on Igrys")
check(not magic(raw.accumulator["kr-planetary-teleporter"]), "the teleporter was banned")
check(not magic(raw.accumulator["hidden-helper"]), "a hidden accumulator was changed")
check(#raw.accumulator["accumulator"].surface_conditions == 1, "the vanilla accumulator got a second ban")
check(#logs == 2, "expected two log lines, got " .. #logs)

igrys_accumulators.data_final_fixes()
check(#logs == 2, "the second run changed something")

raw = fresh(false)
igrys_accumulators.data_final_fixes()
check(not magic(raw.accumulator["omega-accumulator"]) and #logs == 0, "changed accumulators without Igrys")

print("ok")
