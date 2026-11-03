---@diagnostic disable: missing-fields
-- Repairs of mistakes in the data of mods that Razi only reaches through other mods (prototypes/fixes/): the throwers of
-- Renai Transportation, the colored refined concrete of planetaris-dyes, the Big-Monsters spidertrons, the Mini Trains
-- items, the lane balancers, the poles of minimalist-rails and the Factoriopedia simulations of enemy units, on a mocked
-- data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_mod_fixes_transit_mods.lua
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
	local stub = {raw = raw}
	-- data:extend of a mod-data prototype, the only kind a repair adds
	function stub.extend(_, prototypes)
		for _, prototype in ipairs(prototypes) do
			raw[prototype.type] = raw[prototype.type] or {}
			raw[prototype.type][prototype.name] = prototype
		end
	end
	rawset(_G, "data", stub)
	rawset(_G, "mods", {})
	rawset(_G, "defines", {prototypes = {item = {}, entity = {}}})
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
for _, name in ipairs({"recipe", "technology", "item", "tile", "inserter", "unit", "mod-data", "spider-vehicle",
	"item-with-entity-data", "lane-splitter", "electric-pole", "damage-type"}) do
	raw[name] = {}
end
fixes.data_final_fixes()
check(#logs == 0, "A repair logged on empty prototype tables")

-- RenaiTransportation thrower_ranges
local thrower_ranges = require("prototypes.fixes.RenaiTransportation.thrower_ranges")
raw = fresh()
raw["mod-data"] = {
	["RTRealRangeRTThrower-inserter"] = {type = "mod-data", name = "RTRealRangeRTThrower-inserter", data = {x = 1, y = 2, range = 3}},
	["RTRealRangeRTThrower-fast-inserter"] = {type = "mod-data", name = "RTRealRangeRTThrower-fast-inserter", data = {x = 4, y = 5, range = 6}},
}
raw.inserter = {
	["RTThrower-inserter"] = {},
	["RTThrower-inserter_panglia_fast_version"] = {},
	["bioluminescent-RTThrower-inserter"] = {},
	["harene-infused-RTThrower-fast-inserter"] = {},
	["bioluminescent-RTThrower-fast-inserter_panglia_fast_version"] = {},
	["bioluminescent-RTThrower-unknown"] = {},
	["bioluminescent-inserter"] = {},
	["inserter"] = {},
}
thrower_ranges.data_final_fixes()
local mod_data = raw["mod-data"]
check(mod_data["RTRealRangeRTThrower-inserter_panglia_fast_version"].data.range == 3, "The Panglia copy has no range")
check(mod_data["RTRealRangeRTThrower-inserter_panglia_fast_version"].data ~= mod_data["RTRealRangeRTThrower-inserter"].data,
	"The copy shares the table of the thrower")
check(mod_data["RTRealRangebioluminescent-RTThrower-inserter"].data.x == 1, "The Tenebris copy has no range")
check(mod_data["RTRealRangeharene-infused-RTThrower-fast-inserter"].data.y == 5, "The Rabbasca copy has no range")
check(mod_data["RTRealRangebioluminescent-RTThrower-fast-inserter_panglia_fast_version"].data.range == 6, "A copy of a copy has no range")
check(mod_data["RTRealRangebioluminescent-RTThrower-unknown"] == nil, "A copy of an unknown thrower got a range")
check(mod_data["RTRealRangebioluminescent-inserter"] == nil and mod_data["RTRealRangeinserter"] == nil, "A plain inserter got a range")
check(logged("takes the thrower range of") == 4 and logs[1]:find("^razi%-protocol: "), "Expected one line for each of the four copies")
check(logged("has no thrower range to copy") == 1, "Expected one line for the copy of an unknown thrower")
check(logged("thrower ranges copied for 4 thrower copies") == 1, "Expected the total")
thrower_ranges.data_final_fixes()
check(logged("takes the thrower range of") == 4, "The repeated run copied the ranges again")
raw = fresh()
raw.inserter = {["RTThrower-inserter"] = {}, ["inserter"] = {}}
thrower_ranges.data_final_fixes()
check(raw["mod-data"] == nil and logged("has no thrower range to copy") == 1, "A range was made out of nothing")
raw = fresh()
thrower_ranges.data_final_fixes()
check(next(raw) == nil and #logs == 0, "Something changed without inserters")

-- RenaiTransportation recycling_hidden
local recycling_hidden = require("prototypes.fixes.RenaiTransportation.recycling_hidden")
raw = fresh()
raw.recipe = {
	["OpenContainer-recycle"] = {categories = {"recycling"}},
	["iron-plate-recycling"] = {categories = {"recycling"}, hidden = true},
	["mixed"] = {categories = {"recycling", "crafting"}},
	["crafted"] = {categories = {"crafting"}},
	["shown-on-purpose"] = {categories = {"recycling"}, hidden = false, hide_from_player_crafting = true},
	["out-of-menu"] = {categories = {"recycling"}, hide_from_player_crafting = true},
	["no-categories"] = {},
	["empty-categories"] = {categories = {}},
}
recycling_hidden.data_final_fixes()
check(raw.recipe["OpenContainer-recycle"].hidden == true, "The open chest recycling stayed in the crafting menu")
check(raw.recipe["mixed"].hidden == nil and raw.recipe["crafted"].hidden == nil and raw.recipe["no-categories"].hidden == nil
	and raw.recipe["empty-categories"].hidden == nil, "A recipe that something else can make was hidden")
check(raw.recipe["shown-on-purpose"].hidden == false, "A recipe that its mod set to hidden = false was hidden")
check(raw.recipe["out-of-menu"].hidden == true, "A recipe that is only out of the crafting menu stayed visible elsewhere")
check(logged("is hidden, only a recycler makes it") == 2 and logs[1]:find("^razi%-protocol: .* is hidden, only a recycler makes it"),
	"Expected one line for each of the two recipes that were hidden")
recycling_hidden.data_final_fixes()
check(#logs == 2, "The repeated run touched the recipes again")
raw = fresh()
recycling_hidden.data_final_fixes()
check(next(raw) == nil and #logs == 0, "Something changed without recipes")

-- RenaiTransportation hardcoded_localization
local hardcoded_localization = require("prototypes.fixes.RenaiTransportation.hardcoded_localization")
local renai_name = {"?", {"", {"thrower-gen.name", {"entity-name.inserter"}}}, {"", {"thrower-gen.name", "inserter"}}}
raw = fresh()
defines.prototypes.entity = {inserter = 1, ["assembling-machine"] = 2}
defines.prototypes.item = {item = 1, capsule = 2}
raw.inserter = {
	["RTThrower-inserter"] = {localised_name = deepcopy(renai_name)},
	["RTThrower-fast-inserter"] = {localised_name = {"entity-name.somebody-else"}},
	["RTThrower-stack-inserter"] = {},
	["RTThrower-diesel-inserter"] = {localised_name = deepcopy(renai_name)},
}
raw.item = {["RTThrower-inserter-Item"] = {localised_name = deepcopy(renai_name)}}
raw.recipe = {["RTThrower-long-handed-inserter-Recipe"] = {localised_name = deepcopy(renai_name)}}
hardcoded_localization.data_final_fixes()
---@type any
local thrower_name = raw.inserter["RTThrower-inserter"].localised_name
check(thrower_name[1] == "?" and thrower_name[2][1] == "entity-name.RTThrower-inserter",
	"The thrower did not read its locale key first")
check(thrower_name[3][1] == "?" and thrower_name[3][2][2][1] == "thrower-gen.name", "The thrower lost the name Renai built")
check(raw.item["RTThrower-inserter-Item"].localised_name[2][1] == "item-name.RTThrower-inserter-Item", "The item did not point to its locale key")
check(raw.recipe["RTThrower-long-handed-inserter-Recipe"].localised_name[2][1] == "recipe-name.RTThrower-long-handed-inserter-Recipe",
	"The recipe did not point to its locale key")
check(raw.inserter["RTThrower-fast-inserter"].localised_name[1] == "entity-name.somebody-else", "A name another mod set was replaced")
check(raw.inserter["RTThrower-stack-inserter"].localised_name == nil, "A thrower without a name got one")
check(raw.inserter["RTThrower-diesel-inserter"].localised_name[1] == "?", "A thrower of a modded inserter was renamed")
check(logged("before the name Renai built") == 3 and logs[1]:find("^razi%-protocol: "), "Expected one line for each of the three names that were replaced")
hardcoded_localization.data_final_fixes()
check(logged("before the name Renai built") == 3, "The repeated run touched the names again")
raw = fresh()
defines.prototypes.entity = {inserter = 1}
hardcoded_localization.data_final_fixes()
check(next(raw) == nil and #logs == 0, "Something changed without the prototypes")
