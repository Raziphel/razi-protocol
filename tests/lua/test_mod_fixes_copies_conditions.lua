---@diagnostic disable: missing-fields
-- Repairs of copies and of surface conditions (prototypes/fixes/): Arig's dust conditions, the bioluminescent copies of
-- Tenebris Prime and the conditions of copies of roboports, recyclers and rails, on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_mod_fixes_copies_conditions.lua
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
table.deepcopy = deepcopy -- luacheck: ignore 122 (Factorio's helper, not in plain Lua)

---@return any
local function fresh()
	logs = {}
	local raw = {}
	rawset(_G, "data", {raw = raw})
	return raw
end

local fixes = require("prototypes.fixes.init")

-- Nothing of the mods is installed: every repair is quiet and does not fail.
---@type any
local raw = fresh()
fixes.data_final_fixes()
check(#logs == 0, "A repair logged without its prototypes")
check(next(raw) == nil, "A repair created a prototype type")
raw = fresh()
raw.recipe = {}
raw.technology = {}
raw.planet = {}
raw.explosion = {}
raw["surface-property"] = {}
fixes.data_final_fixes()
check(#logs == 0, "A repair logged on empty prototype tables")

-- planetaris-arig surface_conditions
local arig = require("prototypes.fixes.planetaris-arig.surface_conditions")
local dust = "planetaris-dust-concentration"
raw = fresh()
raw["surface-property"] = {[dust] = {}}
raw.recipe = {
	["quantum-processor"] = {surface_conditions = {{property = "pressure", min = 10}}},
	["fusion-reactor"] = {},
	["fusion-generator"] = {surface_conditions = {{property = dust, min = 5, max = 20}}},
}
raw.explosion = {["nuke-effects-aquilo"] = {surface_conditions = {{property = "pressure", min = 10}}}}
arig.data_final_fixes()
---@type any
local quantum = raw.recipe["quantum-processor"].surface_conditions
check(#quantum == 2 and quantum[1].property == "pressure" and quantum[2].property == dust, "The condition was not added")
check(quantum[2].min == 1 and quantum[2].max == 50, "The condition does not have the defaults of the library")
check(raw.recipe["fusion-reactor"].surface_conditions[1].property == dust, "A recipe without conditions got none")
check(raw.recipe["fusion-generator"].surface_conditions[1].max == 20 and #raw.recipe["fusion-generator"].surface_conditions == 1,
	"A condition that Arig wrote was changed")
---@type any
local nuke = raw.explosion["nuke-effects-aquilo"].surface_conditions
check(#nuke == 2 and nuke[2].property == dust and nuke[2].max == 50 and nuke[2].min == nil, "The explosion did not get the dust limit")
check(logged("needs " .. dust) == 3, "Expected a line for each of the two recipes and the explosion, got " .. logged("needs " .. dust))
check(logs[1]:find("^razi%-protocol: "), "The line does not start with the mod name")
arig.data_final_fixes()
check(logged("needs " .. dust) == 3, "The repeated run touched the prototypes again")

raw = fresh()
raw["surface-property"] = {}
raw.recipe = {["quantum-processor"] = {}}
raw.explosion = {["nuke-effects-aquilo"] = {surface_conditions = {}}}
arig.data_final_fixes()
check(raw.recipe["quantum-processor"].surface_conditions == nil and #raw.explosion["nuke-effects-aquilo"].surface_conditions == 0
	and #logs == 0, "Something changed without the dust property")

raw = fresh()
raw["surface-property"] = {[dust] = {}}
raw.recipe = {["fusion-reactor"] = {}}
raw.explosion = {["nuke-effects-aquilo"] = {}}
arig.data_final_fixes()
check(raw.explosion["nuke-effects-aquilo"].surface_conditions == nil, "An explosion without conditions got some")
check(raw.recipe["quantum-processor"] == nil and logged("needs " .. dust) == 1, "Expected one line for the one recipe that exists")

print("test_mod_fixes_copies_conditions: ok")
