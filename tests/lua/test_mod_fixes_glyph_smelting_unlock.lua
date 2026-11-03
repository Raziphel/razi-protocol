---@diagnostic disable: missing-fields, need-check-nil, inject-field
-- The recipes that smelt a Khemia glyph open with the glyphs, on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_mod_fixes_glyph_smelting_unlock.lua
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

local fix = require("prototypes.fixes.alchemy-khemia.glyph_smelting_unlock")

local recipes = {
	["glyph-smelt-glyph-1x3-pipe"] = {enabled = true},
	["glyph-smelt-glyph-1x1-pipe"] = {enabled = true},
	["glyph-smelt-glyph-closed"] = {enabled = false},
	["iron-plate"] = {enabled = true},
}
local technology = {effects = {{type = "unlock-recipe", recipe = "basic-glyph-production"}}}
rawset(_G, "data", {raw = {recipe = recipes, technology = {["glyph-discovery"] = technology}}})
fix.data_final_fixes()

check(recipes["glyph-smelt-glyph-1x1-pipe"].enabled == false and recipes["glyph-smelt-glyph-1x3-pipe"].enabled == false,
	"The recipes must not be open from the start")
check(recipes["iron-plate"].enabled == true, "A recipe of another kind stays open")
check(#technology.effects == 3 and technology.effects[1].recipe == "basic-glyph-production", "The research keeps its effects")
check(technology.effects[2].recipe == "glyph-smelt-glyph-1x1-pipe" and technology.effects[3].recipe == "glyph-smelt-glyph-1x3-pipe",
	"The research opens them, in a stable order")
check(#logs == 2, "Every change is logged")

-- A second pass finds nothing left to do.
fix.data_final_fixes()
check(#technology.effects == 3 and #logs == 2, "A closed recipe stays as it is")

-- Without the research the recipes stay as Khemia wrote them, or nothing could open them.
recipes["glyph-smelt-glyph-1x1-pipe"].enabled = true
data.raw.technology["glyph-discovery"] = nil
fix.data_final_fixes()
check(recipes["glyph-smelt-glyph-1x1-pipe"].enabled == true, "Without the research nothing changes")

-- Without the mod nothing happens.
rawset(_G, "data", {raw = {}})
fix.data_final_fixes()

print("test_mod_fixes_glyph_smelting_unlock: ok")
