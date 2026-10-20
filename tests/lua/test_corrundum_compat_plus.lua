-- Surface lock of Corrundum Compatibility+'s research data (compat/corrundum_compat_plus.lua) on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_corrundum_compat_plus.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local logged = 0
rawset(_G, "log", function(_) logged = logged + 1 end)

local function run(recipe, planet)
	rawset(_G, "data", {raw = {recipe = recipe and {["electrochemical-research-data"] = recipe} or {},
		planet = planet and {corrundum = planet} or {}}})
	require("prototypes.compat.corrundum_compat_plus").data_final_fixes()
	local result = data.raw.recipe["electrochemical-research-data"]
	return result and (result.surface_conditions or {}) or nil
end

local corrundum = {type = "planet", name = "corrundum", surface_properties = {pressure = 6000, ["magnetic-field"] = 99}}

-- Data recipe built without conditions: the planet's pressure and magnetic field come back.
local conditions = run({type = "recipe", name = "electrochemical-research-data", surface_conditions = {}}, corrundum)
check(#conditions == 2, "the empty conditions are replaced")
local pressure, field = conditions[1], conditions[2]
check(pressure and pressure.property == "pressure" and pressure.min == 6000
	and pressure.max == 6000, "pressure of Corrundum")
check(field and field.property == "magnetic-field" and field.min == 99
	and field.max == 99, "magnetic field of Corrundum")
check(logged == 1, "the change is logged")

-- A recipe without the field gets the conditions too.
conditions = run({type = "recipe", name = "electrochemical-research-data"}, corrundum)
check(#conditions == 2, "missing conditions are filled")

-- Conditions that are already there stay as they are.
local own = {{property = "gravity", min = 1, max = 1}}
conditions = run({type = "recipe", name = "electrochemical-research-data", surface_conditions = own}, corrundum)
check(conditions == own and #own == 1, "existing conditions are untouched")

-- Nothing to do, and no crash, without the recipe, the planet or a property.
logged = 0
check(run(nil, corrundum) == nil, "no recipe, no recipe made")
conditions = run({type = "recipe", name = "electrochemical-research-data", surface_conditions = {}}, nil)
check(next(conditions) == nil, "no planet, no change")
conditions = run({type = "recipe", name = "electrochemical-research-data", surface_conditions = {}},
	{type = "planet", name = "corrundum", surface_properties = {pressure = 6000}})
check(next(conditions) == nil, "no magnetic field, no change")
check(logged == 0, "nothing is logged without a change")

print("corrundum_compat_plus: ok")
