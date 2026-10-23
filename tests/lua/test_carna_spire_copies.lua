---@diagnostic disable: missing-fields, assign-type-mismatch, need-check-nil
-- Carna's spire marker is taken off the copies of the spire (compat/carna_spire_copies.lua) on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_carna_spire_copies.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local logged = {}
rawset(_G, "log", function(text) logged[#logged + 1] = text end)

local function mark()
	return {type = "script", effect_id = "spire-mark"}
end

local function other()
	return {type = "script", effect_id = "snow-module"}
end

-- Carna's own form: one trigger, one delivery, one effect.
local function single_trigger(effect)
	return {type = "direct", action_delivery = {type = "instant", source_effects = effect}}
end

local function setup(mod_list)
	local data_raw = {
		["assembling-machine"] = {
			["carnan-spire"] = {type = "assembling-machine", name = "carnan-spire", created_effect = single_trigger(mark())},
			-- Tenebris Prime: a deep copy of the spire
			["bioluminescent-carnan-spire"] = {type = "assembling-machine", name = "bioluminescent-carnan-spire",
				created_effect = single_trigger(mark())},
			-- Rabbasca: the same, with the trigger in a list
			["harene-infused-carnan-spire"] = {type = "assembling-machine", name = "harene-infused-carnan-spire",
				created_effect = {single_trigger(mark())}},
			-- the mark next to another effect, in lists of effects, deliveries and triggers
			["mixed-copy"] = {type = "assembling-machine", name = "mixed-copy", created_effect = {
				{type = "direct", action_delivery = {
					{type = "instant", source_effects = {other(), mark()}},
					{type = "instant", target_effects = mark(), source_effects = other()},
				}},
				single_trigger(other()),
				single_trigger({mark(), mark()}),
			}},
			["plain-machine"] = {type = "assembling-machine", name = "plain-machine"},
			["other-effect-machine"] = {type = "assembling-machine", name = "other-effect-machine",
				created_effect = single_trigger(other())},
		},
		-- not only assembling machines
		["furnace"] = {
			["furnace-copy"] = {type = "furnace", name = "furnace-copy", created_effect = single_trigger(mark())},
		},
		["lab"] = {},
		["broken"] = {["not-a-table"] = true},
	}
	rawset(_G, "mods", mod_list)
	rawset(_G, "data", {raw = data_raw})
	package.loaded["prototypes.compat.carna_spire_copies"] = nil
	return data_raw, require("prototypes.compat.carna_spire_copies")
end

local function has_mark(value)
	if type(value) ~= "table" then
		return false
	end
	if value.type == "script" and value.effect_id == "spire-mark" then
		return true
	end
	for _, child in pairs(value) do
		if has_mark(child) then
			return true
		end
	end
	return false
end

local raw, compat = setup({carna = "0.3.24"})
local machines = raw["assembling-machine"]
compat.data_final_fixes()

-- The real spire keeps its mark, exactly as it was.
check(has_mark(machines["carnan-spire"].created_effect), "the spire keeps its mark")
check(machines["carnan-spire"].created_effect.action_delivery.source_effects.effect_id == "spire-mark",
	"the spire's trigger is untouched")

-- The copies lose it, and nothing is left behind of a trigger that only held the mark.
check(machines["bioluminescent-carnan-spire"].created_effect == nil, "the Tenebris copy has no created_effect left")
check(machines["harene-infused-carnan-spire"].created_effect == nil, "the Rabbasca copy (a list of triggers) has no created_effect left")
check(raw.furnace["furnace-copy"].created_effect == nil, "other prototype types are covered too")

-- Only the mark goes: the other effects, deliveries and triggers stay.
local mixed = machines["mixed-copy"].created_effect
check(not has_mark(mixed), "the mixed copy has no mark left")
check(#mixed == 2, "the trigger that held only marks is gone, the other two stay, got " .. #mixed)
check(#mixed[1].action_delivery == 2, "both deliveries stay: one keeps another effect")
check(#mixed[1].action_delivery[1].source_effects == 1 and mixed[1].action_delivery[1].source_effects[1].effect_id == "snow-module",
	"the other effect in the list stays")
check(mixed[1].action_delivery[2].target_effects == nil and mixed[1].action_delivery[2].source_effects.effect_id == "snow-module",
	"the mark is taken off target_effects, the other effect in source_effects stays")
check(mixed[2].action_delivery.source_effects.effect_id == "snow-module", "a trigger without a mark is untouched")

-- Prototypes without a mark are not touched.
check(machines["plain-machine"].created_effect == nil, "a machine without created_effect stays without")
check(machines["other-effect-machine"].created_effect.action_delivery.source_effects.effect_id == "snow-module",
	"another mod's effect stays")

-- Every change is logged, the untouched ones are not.
check(#logged == 4, "one log line for each of the four changed prototypes, got " .. #logged)
local text = table.concat(logged, "\n")
check(text:find("razi-protocol: ", 1, true) == 1, "the log lines start with razi-protocol")
check(text:find("bioluminescent-carnan-spire", 1, true) and text:find("harene-infused-carnan-spire", 1, true)
	and text:find("mixed-copy", 1, true) and text:find("furnace-copy", 1, true), "the log names the prototypes")
check(not text:find("plain-machine", 1, true) and not text:find("other-effect-machine", 1, true)
	and not text:find(" carnan-spire ", 1, true), "the log does not name the unchanged ones")

-- A second pass changes nothing.
logged = {}
compat.data_final_fixes()
check(#logged == 0 and #mixed == 2 and has_mark(machines["carnan-spire"].created_effect), "the second pass is idempotent")

-- Without Carna nothing changes.
logged = {}
raw, compat = setup({})
compat.data_final_fixes()
check(has_mark(raw["assembling-machine"]["bioluminescent-carnan-spire"].created_effect), "no change without Carna")
check(has_mark(raw.furnace["furnace-copy"].created_effect), "no change to other types without Carna")
check(#logged == 0, "nothing is logged without Carna")

-- Carna without any copy, and an empty data.raw, do not fail.
raw, compat = setup({carna = "0.3.24"})
raw["assembling-machine"]["bioluminescent-carnan-spire"] = nil
raw["assembling-machine"]["harene-infused-carnan-spire"] = nil
raw["assembling-machine"]["mixed-copy"] = nil
raw.furnace["furnace-copy"] = nil
compat.data_final_fixes()
check(has_mark(raw["assembling-machine"]["carnan-spire"].created_effect), "the spire stays when there are no copies")
rawset(_G, "data", {raw = {}})
compat.data_final_fixes()

-- It runs after the passes that can copy a prototype (the last data-final-fixes edit before the menu pass).
local file = assert(io.open("data-final-fixes.lua", "r"))
local source = file:read("*a")
file:close()
local asteroids = assert(source:find('require("prototypes.system.asteroid_performance").data_final_fixes()', 1, true))
local own = assert(source:find('require("prototypes.compat.carna_spire_copies").data_final_fixes()', 1, true))
local navigation = assert(source:find('require("prototypes.compat.crafting_navigation").data_final_fixes()', 1, true))
check(asteroids < own and own < navigation, "the pass runs late, after the asteroid passes")

print("carna_spire_copies: ok")
