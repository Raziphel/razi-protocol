---@diagnostic disable: missing-fields, assign-type-mismatch, need-check-nil
-- The out-of-nothing recipes of Iridescent Industry and Arcanyx are kept on Arcanyx (compat/arcanyx_from_nothing.lua)
-- on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_arcanyx_from_nothing.lua
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

local function count_property(prototype, property)
	local count = 0
	for _, condition in pairs(prototype.surface_conditions or {}) do
		if condition.property == property then
			count = count + 1
		end
	end
	return count
end

local function count_magic(prototype)
	return count_property(prototype, "magic")
end

local NOTHING_RECIPES = {
	"s6x-prismite-deep-mine", "s6x-prismite-deep-mine-advanced", "s6x-prismite-deep-mining", "s6x-prismite-deeper-mining",
	"s6x-entropic-creation", "s6x-entropic-creation-crushed",
}
local NOTHING_MACHINES = {"s6x-prismite-deep-mine", "s6x-prismite-deep-mine-advanced"}

-- Startup settings by name; mod_list is the mods table; with_nothing false leaves the Iridescent Industry prototypes out.
local function setup(mod_list, startup, with_nothing)
	local data_raw = {
		["assembling-machine"] = {
			-- a voidcrafter: Arcanyx closes it itself, this module does not look at it
			["s6x-voidworks-nuke"] = {type = "assembling-machine", name = "s6x-voidworks-nuke", surface_conditions = {magic()}},
		},
		furnace = {
			-- the cursed furnaces are not touched
			["s6x-cursed-furnace"] = {type = "furnace", name = "s6x-cursed-furnace", surface_conditions = {{property = "pressure", min = 10}}},
		},
		recipe = {
			["s6xvcinv-a"] = {type = "recipe", name = "s6xvcinv-a", categories = {"voidcrafting-inverse"}},
			["s6xvc-other"] = {type = "recipe", name = "s6xvc-other", categories = {"voidcrafting"}},
			["s6x-voidworks-fusion"] = {type = "recipe", name = "s6x-voidworks-fusion", categories = {"crafting"}},
			["iron-plate"] = {type = "recipe", name = "iron-plate", categories = {"smelting"}},
			["broken"] = true,
		},
	}
	if with_nothing ~= false then
		for _, name in ipairs(NOTHING_RECIPES) do
			data_raw.recipe[name] = {type = "recipe", name = name, categories = {"prismite-deep-mining"}}
		end
		data_raw.recipe["s6x-cursed-furnace"] = {type = "recipe", name = "s6x-cursed-furnace", categories = {"crafting"}}
		data_raw.recipe["s6x-cursed-smelting"] = {type = "recipe", name = "s6x-cursed-smelting", categories = {"cursed-smelting"}}
		for _, name in ipairs(NOTHING_MACHINES) do
			data_raw["assembling-machine"][name] = {type = "assembling-machine", name = name, surface_conditions = {{property = "gravity", min = 0.1}}}
		end
		-- the Rabbasca copies were made with the conditions of the machines at that time; a Tenebris copy has its own
		for _, name in ipairs({"harene-infused-s6x-prismite-deep-mine", "harene-infused-s6x-prismite-deep-mine-advanced"}) do
			data_raw["assembling-machine"][name] = {type = "assembling-machine", name = name, surface_conditions = {{property = "gravity", min = 0.1}}}
		end
		data_raw["assembling-machine"]["bioluminescent-s6x-prismite-deep-mine"] = {type = "assembling-machine",
			name = "bioluminescent-s6x-prismite-deep-mine", surface_conditions = {{property = "pressure", min = 3000, max = 3000}}}
		data_raw["assembling-machine"]["harene-infused-s6x-voidworks"] = {type = "assembling-machine", name = "harene-infused-s6x-voidworks"}
	end
	rawset(_G, "mods", mod_list)
	rawset(_G, "settings", {startup = startup})
	rawset(_G, "data", {raw = data_raw})
	logged = {}
	package.loaded["prototypes.compat.arcanyx_from_nothing"] = nil
	return data_raw, require("prototypes.compat.arcanyx_from_nothing")
end

local function on(name)
	return {[name] = {value = true}}
end

-- The setting is on: the deep mines, their recipes, the entropic creation and the Rabbasca copies of the mines are closed;
-- the cursed furnaces, the Tenebris copy, the copies of other machines and everything Arcanyx closes itself are not touched.
local raw, compat = setup({Arcanyx = "1.1.6"}, on("s6x-arcanyx-voidcraft"))
compat.data_final_fixes()
local text = table.concat(logged, "\n")
check(#logged == 11, "ten changes and a summary are logged, got " .. #logged)
check(text:find("razi-protocol: ", 1, true) == 1, "the log lines start with razi-protocol")
for _, name in ipairs(NOTHING_RECIPES) do
	check(count_magic(raw.recipe[name]) == 1 and raw.recipe[name].surface_conditions[1].min == 100
		and raw.recipe[name].surface_conditions[1].max == 100, "the recipe " .. name .. " gets magic = 100")
	check(text:find("recipe " .. name .. " ", 1, true), "the log names " .. name)
end
for _, name in ipairs(NOTHING_MACHINES) do
	local machine = raw["assembling-machine"][name]
	check(count_magic(machine) == 1 and #machine.surface_conditions == 2 and count_property(machine, "gravity") == 1,
		"the machine " .. name .. " keeps its gravity condition and gets magic")
end
for _, name in ipairs({"harene-infused-s6x-prismite-deep-mine", "harene-infused-s6x-prismite-deep-mine-advanced"}) do
	local copy = raw["assembling-machine"][name]
	check(count_magic(copy) == 1 and #copy.surface_conditions == 2 and count_property(copy, "gravity") == 1, "the copy " .. name .. " gets magic")
	check(text:find(name, 1, true), "the log names " .. name)
end
check(count_magic(raw["assembling-machine"]["bioluminescent-s6x-prismite-deep-mine"]) == 0, "the Tenebris copy is not touched")
check(raw["assembling-machine"]["harene-infused-s6x-voidworks"].surface_conditions == nil, "the copy of another machine is not touched")
check(raw.recipe["s6x-cursed-furnace"].surface_conditions == nil and raw.recipe["s6x-cursed-smelting"].surface_conditions == nil,
	"the cursed furnace recipes are not touched")
check(#raw.furnace["s6x-cursed-furnace"].surface_conditions == 1, "the cursed furnace is not touched")
check(#raw["assembling-machine"]["s6x-voidworks-nuke"].surface_conditions == 1, "a voidcrafter is not changed")
check(raw.recipe["s6xvcinv-a"].surface_conditions == nil and raw.recipe["s6xvc-other"].surface_conditions == nil
	and raw.recipe["s6x-voidworks-fusion"].surface_conditions == nil and raw.recipe["iron-plate"].surface_conditions == nil,
	"the voidcrafting and inverse recipes are Arcanyx's, other recipes are not touched")
check(text:find("out-of-nothing production reaches 4 machine(s) and 6 recipe(s)", 1, true), "the summary counts the changes")

-- A second pass changes nothing: no second condition.
logged = {}
compat.data_final_fixes()
check(#logged == 0, "the second pass is idempotent")
check(count_magic(raw.recipe["s6x-prismite-deep-mining"]) == 1 and count_magic(raw["assembling-machine"]["s6x-prismite-deep-mine"]) == 1,
	"the second pass adds no second condition")

-- The setting off: nothing changes.
raw, compat = setup({Arcanyx = "1.1.6"}, {["s6x-arcanyx-voidcraft"] = {value = false}})
compat.data_final_fixes()
check(#logged == 0, "nothing is logged with the setting off")
for _, name in ipairs(NOTHING_RECIPES) do
	check(raw.recipe[name].surface_conditions == nil, "the recipe " .. name .. " stays open with the setting off")
end
for _, name in ipairs(NOTHING_MACHINES) do
	check(#raw["assembling-machine"][name].surface_conditions == 1, "the machine " .. name .. " stays open with the setting off")
end

-- A missing setting counts as off.
raw, compat = setup({Arcanyx = "1.1.6"}, {})
compat.data_final_fixes()
check(#logged == 0, "no change without the setting")
check(raw.recipe["s6x-prismite-deep-mining"].surface_conditions == nil and raw.recipe["s6x-entropic-creation"].surface_conditions == nil,
	"the out-of-nothing recipes stay open without the setting")

-- With ArcanyxContainment the setting is its own: off keeps everything open, on closes it, Arcanyx's own setting does not count.
raw, compat = setup({Arcanyx = "1.1.6", ArcanyxContainment = "1.0.0"}, {["s6x-ac-arcanyx-voidcraft"] = {value = false}})
compat.data_final_fixes()
check(#logged == 0, "nothing is logged with the Containment setting off")
check(raw.recipe["s6x-prismite-deep-mining"].surface_conditions == nil and raw.recipe["s6x-entropic-creation"].surface_conditions == nil
	and count_magic(raw["assembling-machine"]["s6x-prismite-deep-mine"]) == 0, "the out-of-nothing prototypes stay open with the Containment setting off")
raw, compat = setup({Arcanyx = "1.1.6", ArcanyxContainment = "1.0.0"}, on("s6x-ac-arcanyx-voidcraft"))
compat.data_final_fixes()
check(count_magic(raw.recipe["s6x-prismite-deep-mining"]) == 1 and count_magic(raw["assembling-machine"]["s6x-prismite-deep-mine"]) == 1,
	"the Containment setting closes the out-of-nothing prototypes")
raw, compat = setup({Arcanyx = "1.1.6", ArcanyxContainment = "1.0.0"}, on("s6x-arcanyx-voidcraft"))
compat.data_final_fixes()
check(raw.recipe["s6x-prismite-deep-mining"].surface_conditions == nil, "Arcanyx's own setting does not count under Containment")

-- ArcanyxContainment has closed its six prototypes before this module runs: no second condition on them, the rest is closed as before.
local function containment_pass(raw_data)
	for _, name in ipairs({"s6x-cursed-furnace", "s6x-cursed-furnace-steel", "s6x-entropic-creation", "s6x-entropic-creation-crushed",
		"s6x-prismite-deep-mine", "s6x-prismite-deep-mine-advanced"}) do
		local recipe = raw_data.recipe[name]
		if recipe then
			recipe.surface_conditions = recipe.surface_conditions or {}
			table.insert(recipe.surface_conditions, magic())
		end
	end
	for _, name in ipairs(NOTHING_MACHINES) do
		table.insert(raw_data["assembling-machine"][name].surface_conditions, magic())
		-- Rabbasca copies the machine after Containment, with its condition
		table.insert(raw_data["assembling-machine"]["harene-infused-" .. name].surface_conditions, magic())
	end
end
raw, compat = setup({Arcanyx = "1.1.6", ArcanyxContainment = "1.0.0"}, on("s6x-ac-arcanyx-voidcraft"))
containment_pass(raw)
compat.data_final_fixes()
for _, name in ipairs({"s6x-entropic-creation", "s6x-entropic-creation-crushed", "s6x-prismite-deep-mine", "s6x-prismite-deep-mine-advanced"}) do
	check(count_magic(raw.recipe[name]) == 1, "Containment's condition on " .. name .. " is not doubled")
end
for _, name in ipairs(NOTHING_MACHINES) do
	check(count_magic(raw["assembling-machine"][name]) == 1 and #raw["assembling-machine"][name].surface_conditions == 2,
		"Containment's condition on the machine " .. name .. " is not doubled")
end
check(count_magic(raw["assembling-machine"]["harene-infused-s6x-prismite-deep-mine"]) == 1
	and #raw["assembling-machine"]["harene-infused-s6x-prismite-deep-mine"].surface_conditions == 2, "Containment's condition on a copy is not doubled")
check(count_magic(raw.recipe["s6x-prismite-deep-mining"]) == 1 and count_magic(raw.recipe["s6x-prismite-deeper-mining"]) == 1,
	"the mining recipes Containment does not list are closed under Containment")
check(raw.recipe["s6x-cursed-furnace"].surface_conditions ~= nil and count_magic(raw.recipe["s6x-cursed-furnace"]) == 1,
	"Containment's own condition on the cursed furnace stays")
check(not table.concat(logged, "\n"):find("recipe s6x-entropic-creation ", 1, true), "nothing is logged for what Containment closed")

-- With Containment and its setting off, Containment's six stay closed and this module changes none of the out-of-nothing prototypes.
raw, compat = setup({Arcanyx = "1.1.6", ArcanyxContainment = "1.0.0"}, {["s6x-ac-arcanyx-voidcraft"] = {value = false}})
containment_pass(raw)
compat.data_final_fixes()
check(raw.recipe["s6x-prismite-deep-mining"].surface_conditions == nil, "the mining recipes stay open with the Containment setting off")
check(count_magic(raw.recipe["s6x-entropic-creation"]) == 1, "Containment's condition on the entropic creation is still there")

-- Without Arcanyx nothing changes.
raw, compat = setup({}, on("s6x-arcanyx-voidcraft"))
compat.data_final_fixes()
check(raw.recipe["s6x-prismite-deep-mining"].surface_conditions == nil and #logged == 0, "no change without Arcanyx")

-- Without Iridescent Industry and Arcanyx's recipes (older versions, or renamed) nothing fails and nothing is created.
raw, compat = setup({Arcanyx = "1.1.6"}, on("s6x-arcanyx-voidcraft"), false)
compat.data_final_fixes()
check(raw.recipe["s6x-prismite-deep-mining"] == nil and raw["assembling-machine"]["s6x-prismite-deep-mine"] == nil, "nothing is created")
check(#logged == 0, "nothing is logged")

-- Empty data.raw does not fail.
rawset(_G, "data", {raw = {}})
compat.data_final_fixes()

-- It runs after the passes that can add a recipe and before the menu pass.
local file = assert(io.open("data-final-fixes.lua", "r"))
local source = file:read("*a")
file:close()
local asteroids = assert(source:find('require("prototypes.system.asteroid_performance").data_final_fixes()', 1, true))
local own = assert(source:find('require("prototypes.compat.arcanyx_from_nothing").data_final_fixes()', 1, true))
local navigation = assert(source:find('require("prototypes.compat.crafting_navigation").data_final_fixes()', 1, true))
check(asteroids < own and own < navigation, "the pass runs after the asteroid passes and before the menu pass")

print("arcanyx_from_nothing: ok")
