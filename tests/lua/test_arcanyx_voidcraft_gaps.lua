---@diagnostic disable: missing-fields, assign-type-mismatch, need-check-nil
-- Arcanyx's Voidcraft restriction is extended to the Astral voidforge and the inverse recipes (compat/arcanyx_voidcraft_gaps.lua)
-- on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_arcanyx_voidcraft_gaps.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local logged = {}
rawset(_G, "log", function(text) logged[#logged + 1] = text end)

local function magic()
	return {property = "magic", min = 100, max = 100}
end

local function count_magic(prototype)
	local count = 0
	for _, condition in pairs(prototype.surface_conditions or {}) do
		if condition.property == "magic" then
			count = count + 1
		end
	end
	return count
end

-- Startup settings by name; mod_list is the mods table.
local function setup(mod_list, startup, with_forge)
	local data_raw = {
		["assembling-machine"] = {
			["s6x-voidworks-nuke"] = {type = "assembling-machine", name = "s6x-voidworks-nuke", surface_conditions = {magic()}},
		},
		recipe = {
			-- Factorio 2.1: the list of categories
			["s6xvcinv-a"] = {type = "recipe", name = "s6xvcinv-a", categories = {"voidcrafting-inverse"}},
			["s6xvcinv-b"] = {type = "recipe", name = "s6xvcinv-b", categories = {"crafting", "voidcrafting-inverse"}},
			-- the old single field
			["s6xvcinv-old"] = {type = "recipe", name = "s6xvcinv-old", category = "voidcrafting-inverse"},
			-- Arcanyx's own condition is already there
			["s6xvcinv-done"] = {type = "recipe", name = "s6xvcinv-done", categories = {"voidcrafting-inverse"},
				surface_conditions = {{property = "pressure", min = 10}, magic()}},
			["s6xvc-other"] = {type = "recipe", name = "s6xvc-other", categories = {"voidcrafting"}},
			["iron-plate"] = {type = "recipe", name = "iron-plate", categories = {"smelting"}},
			["broken"] = true,
		},
	}
	if with_forge ~= false then
		data_raw["assembling-machine"]["s6x-voidworks-fusion"] = {type = "assembling-machine", name = "s6x-voidworks-fusion"}
		data_raw.recipe["s6x-voidworks-fusion"] = {type = "recipe", name = "s6x-voidworks-fusion", categories = {"crafting"}}
	end
	rawset(_G, "mods", mod_list)
	rawset(_G, "settings", {startup = startup})
	rawset(_G, "data", {raw = data_raw})
	logged = {}
	package.loaded["prototypes.compat.arcanyx_voidcraft_gaps"] = nil
	return data_raw, require("prototypes.compat.arcanyx_voidcraft_gaps")
end

local function on(name)
	return {[name] = {value = true}}
end

-- The setting is on: the voidforge, its recipe and the inverse recipes are closed.
local raw, compat = setup({Arcanyx = "1.1.5"}, on("s6x-arcanyx-voidcraft"))
compat.data_final_fixes()
local forge = raw["assembling-machine"]["s6x-voidworks-fusion"]
check(count_magic(forge) == 1 and forge.surface_conditions[1].min == 100 and forge.surface_conditions[1].max == 100,
	"the voidforge gets magic = 100")
check(count_magic(raw.recipe["s6x-voidworks-fusion"]) == 1, "the voidforge recipe gets magic")
check(count_magic(raw.recipe["s6xvcinv-a"]) == 1, "an inverse recipe found through categories gets magic")
check(count_magic(raw.recipe["s6xvcinv-b"]) == 1, "an inverse recipe with another category too gets magic")
check(count_magic(raw.recipe["s6xvcinv-old"]) == 1, "an inverse recipe found through category gets magic")
check(#raw.recipe["s6xvcinv-done"].surface_conditions == 2 and count_magic(raw.recipe["s6xvcinv-done"]) == 1,
	"a recipe that has magic already is not changed")
check(raw.recipe["s6xvc-other"].surface_conditions == nil and raw.recipe["iron-plate"].surface_conditions == nil,
	"other recipes are not touched")
check(#raw["assembling-machine"]["s6x-voidworks-nuke"].surface_conditions == 1, "an already closed machine is not changed")
check(#logged == 6, "five changes and a summary are logged, got " .. #logged)
local text = table.concat(logged, "\n")
check(text:find("razi-protocol: ", 1, true) == 1, "the log lines start with razi-protocol")
check(text:find("s6xvcinv-a", 1, true) and text:find("s6xvcinv-old", 1, true) and text:find("s6x-voidworks-fusion", 1, true),
	"the log names the changed prototypes")
check(not text:find("s6xvcinv-done", 1, true) and not text:find("s6xvc-other", 1, true), "the log does not name the unchanged ones")

-- A second pass changes nothing: no second condition.
logged = {}
compat.data_final_fixes()
check(#logged == 0 and count_magic(forge) == 1 and count_magic(raw.recipe["s6xvcinv-a"]) == 1, "the second pass is idempotent")

-- Both settings off: nothing changes.
raw, compat = setup({Arcanyx = "1.1.5"}, {["s6x-arcanyx-voidcraft"] = {value = false}})
compat.data_final_fixes()
check(raw["assembling-machine"]["s6x-voidworks-fusion"].surface_conditions == nil, "no change with the setting off")
check(raw.recipe["s6x-voidworks-fusion"].surface_conditions == nil and raw.recipe["s6xvcinv-a"].surface_conditions == nil,
	"no recipe changes with the setting off")
check(#logged == 0, "nothing is logged with the setting off")

-- A missing setting counts as off.
raw, compat = setup({Arcanyx = "1.1.5"}, {})
compat.data_final_fixes()
check(raw.recipe["s6xvcinv-a"].surface_conditions == nil and #logged == 0, "no change without the setting")

-- With ArcanyxContainment and its voidcraft setting off, only the construction is restricted: the forge recipe.
raw, compat = setup({Arcanyx = "1.1.5", ArcanyxContainment = "1.0.0"}, {["s6x-ac-arcanyx-voidcraft"] = {value = false}})
compat.data_final_fixes()
check(count_magic(raw.recipe["s6x-voidworks-fusion"]) == 1, "the voidforge recipe is closed with Containment")
check(raw["assembling-machine"]["s6x-voidworks-fusion"].surface_conditions == nil, "the voidforge itself stays open with the Containment setting off")
check(raw.recipe["s6xvcinv-a"].surface_conditions == nil and raw.recipe["s6xvcinv-old"].surface_conditions == nil,
	"inverse recipes stay open with the Containment setting off")
check(#logged == 2, "one change and a summary are logged, got " .. #logged)

-- With ArcanyxContainment and its setting on, everything is closed; Arcanyx's own setting is ignored.
raw, compat = setup({Arcanyx = "1.1.5", ArcanyxContainment = "1.0.0"}, on("s6x-ac-arcanyx-voidcraft"))
compat.data_final_fixes()
check(count_magic(raw["assembling-machine"]["s6x-voidworks-fusion"]) == 1 and count_magic(raw.recipe["s6xvcinv-b"]) == 1,
	"the Containment setting closes the voidforge and the inverse recipes")
raw, compat = setup({Arcanyx = "1.1.5", ArcanyxContainment = "1.0.0"}, on("s6x-arcanyx-voidcraft"))
compat.data_final_fixes()
check(raw.recipe["s6xvcinv-a"].surface_conditions == nil, "Arcanyx's own setting does not count under Containment")

-- Without Arcanyx nothing changes.
raw, compat = setup({}, on("s6x-arcanyx-voidcraft"))
compat.data_final_fixes()
check(raw.recipe["s6xvcinv-a"].surface_conditions == nil and #logged == 0, "no change without Arcanyx")

-- Without the voidforge (no Space Age, or Voidcraft before 2.10.0) the rest still works and nothing fails.
raw, compat = setup({Arcanyx = "1.1.5"}, on("s6x-arcanyx-voidcraft"), false)
compat.data_final_fixes()
check(count_magic(raw.recipe["s6xvcinv-a"]) == 1, "inverse recipes are closed without the voidforge")
check(raw["assembling-machine"]["s6x-voidworks-fusion"] == nil and raw.recipe["s6x-voidworks-fusion"] == nil, "nothing is created")

-- Empty data.raw does not fail.
rawset(_G, "data", {raw = {}})
compat.data_final_fixes()

-- It runs after the passes that can add a recipe and before the menu pass.
local file = assert(io.open("data-final-fixes.lua", "r"))
local source = file:read("*a")
file:close()
local compat_2_1_22 = assert(source:find('require("prototypes.compat.factorio_2_1_22").data_final_fixes()', 1, true))
local own = assert(source:find('require("prototypes.compat.arcanyx_voidcraft_gaps").data_final_fixes()', 1, true))
local navigation = assert(source:find('require("prototypes.compat.crafting_navigation").data_final_fixes()', 1, true))
check(compat_2_1_22 < own and own < navigation, "the pass runs after the temporary 2.1.22 pass and before the menu pass")

print("arcanyx_voidcraft_gaps: ok")
