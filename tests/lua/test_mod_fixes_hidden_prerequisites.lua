---@diagnostic disable: missing-fields, need-check-nil, inject-field
-- A visible technology never needs a hidden one, on a mocked data.raw (Frozeta without Dea Dia hides heat inserter
-- technologies that heat-inserter's neodymium bulk heat inserter needs).
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_mod_fixes_hidden_prerequisites.lua
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

local fix = require("prototypes.fixes.common.hidden_prerequisites")

local function unlock(recipe)
	return {type = "unlock-recipe", recipe = recipe}
end

local technologies = {
	["hyper-inserter"] = {},
	["fast-heat-inserter"] = {hidden = true, prerequisites = {"hyper-inserter"}, effects = {unlock("fast-heat-inserter")}},
	["bulk-heat-inserter"] = {hidden = true, prerequisites = {"fast-heat-inserter"}, effects = {unlock("bulk-heat-inserter")}},
	["heat-inserter"] = {prerequisites = {"hyper-inserter"},
		effects = {unlock("heat-inserter"), unlock("fast-heat-inserter"), unlock("bulk-heat-inserter")}},
	["magnet-inserter"] = {},
	["neodymium-bulk-heat-inserter"] = {prerequisites = {"magnet-inserter", "bulk-heat-inserter"}},
	-- A hidden prerequisite whose recipes nobody unlocks gives way to its own prerequisites, hidden ones resolved too.
	["lost"] = {hidden = true, prerequisites = {"fast-heat-inserter", "magnet-inserter"}, effects = {unlock("lost")}},
	["after-lost"] = {prerequisites = {"lost"}},
	-- A replacement that needs the technology itself would make a cycle.
	["loop-hidden"] = {hidden = true, effects = {unlock("loop")}},
	["loop-unlock"] = {prerequisites = {"loop-user"}, effects = {unlock("loop")}},
	["loop-user"] = {prerequisites = {"loop-hidden", "magnet-inserter"}},
	["hidden-user"] = {hidden = true, prerequisites = {"bulk-heat-inserter"}},
}
rawset(_G, "data", {raw = {technology = technologies}})
fix.data_final_fixes()

local function same(list, expected)
	if #list ~= #expected then return false end
	for i = 1, #list do
		if list[i] ~= expected[i] then return false end
	end
	return true
end

check(same(technologies["neodymium-bulk-heat-inserter"].prerequisites, {"magnet-inserter", "heat-inserter"}),
	"The technology that now unlocks the bulk heat inserter takes the place of the hidden one")
check(same(technologies["after-lost"].prerequisites, {"heat-inserter", "magnet-inserter"}),
	"Without an unlock the prerequisites of the hidden technology take its place")
check(same(technologies["loop-user"].prerequisites, {"magnet-inserter"}), "A replacement that would make a cycle is skipped")
check(same(technologies["hidden-user"].prerequisites, {"bulk-heat-inserter"}), "A hidden technology stays as it is")
check(#logs == 3, "Every change is logged")

-- A second pass finds nothing left to do.
fix.data_final_fixes()
check(#logs == 3, "Nothing hidden is left among the prerequisites")

-- Without technologies nothing happens.
rawset(_G, "data", {raw = {}})
fix.data_final_fixes()

print("test_mod_fixes_hidden_prerequisites: ok")
