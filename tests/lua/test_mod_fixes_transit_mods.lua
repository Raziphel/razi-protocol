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

-- planetaris-dyes refined_concrete
local refined_concrete = require("prototypes.fixes.planetaris-dyes.refined_concrete")
raw = fresh()
raw.item = {
	["planetaris-red-refined-concrete"] = {place_as_tile = {result = "red-refined-concrete"}},
	["planetaris-magenta-refined-concrete"] = {place_as_tile = {result = "purple-refined-concrete"}},
	["planetaris-blue-refined-concrete"] = {place_as_tile = {result = "blue-refined-concrete"}},
	["planetaris-green-refined-concrete"] = {place_as_tile = {result = "green-refined-concrete"}},
	["planetaris-gone-refined-concrete"] = {place_as_tile = {result = "gone-refined-concrete"}},
	["planetaris-no-tile-refined-concrete"] = {},
	["refined-concrete"] = {place_as_tile = {result = "yellow-refined-concrete"}},
}
raw.tile = {
	["red-refined-concrete"] = {},
	["purple-refined-concrete"] = {},
	["blue-refined-concrete"] = {minable = {mining_time = 0.5, result = "refined-concrete"}},
	["green-refined-concrete"] = {},
	["yellow-refined-concrete"] = {},
}
refined_concrete.data_final_fixes()
check(raw.tile["red-refined-concrete"].minable.result == "planetaris-red-refined-concrete"
	and raw.tile["red-refined-concrete"].minable.mining_time == 0.1, "The red tile was not made minable")
check(raw.tile["purple-refined-concrete"].minable.result == "planetaris-magenta-refined-concrete", "The magenta item was taken by name")
check(raw.tile["blue-refined-concrete"].minable.result == "refined-concrete" and raw.tile["blue-refined-concrete"].minable.mining_time == 0.5,
	"A minable tile was changed")
check(raw.tile["yellow-refined-concrete"].minable == nil, "A tile of another item was made minable")
check(logged("is mined into") == 3 and logs[1]:find("^razi%-protocol: tile "), "Expected one line for each of the three tiles that were changed")
refined_concrete.data_final_fixes()
check(logged("is mined into") == 3, "The repeated run touched the tiles again")
raw = fresh()
raw.item = {["planetaris-red-refined-concrete"] = {place_as_tile = {result = "red-refined-concrete"}}}
refined_concrete.data_final_fixes()
check(next(raw) == "item" and next(raw, "item") == nil and #logs == 0, "Something changed without the tile table")

-- Big-Monsters boss_spidertrons
local boss_spidertrons = require("prototypes.fixes.Big-Monsters.boss_spidertrons")
raw = fresh()
raw["spider-vehicle"] = {
	["bm-spidertron_1"] = {allow_passengers = true, minable = {mining_time = 1, result = "spidertron"}},
	["bm-spidertron_5"] = {minable = {mining_time = 1, result = "spidertron"}},
	["bm-spidertron_2"] = {allow_passengers = false},
	["spidertron"] = {minable = {mining_time = 1, result = "spidertron"}},
	["bm-spidertron_x"] = {minable = {mining_time = 1, result = "spidertron"}},
}
boss_spidertrons.data_final_fixes()
check(raw["spider-vehicle"]["bm-spidertron_1"].allow_passengers == false and raw["spider-vehicle"]["bm-spidertron_1"].minable == nil,
	"The first boss still takes passengers or can be mined")
check(raw["spider-vehicle"]["bm-spidertron_5"].allow_passengers == false and raw["spider-vehicle"]["bm-spidertron_5"].minable == nil,
	"The fifth boss still takes passengers or can be mined")
check(raw["spider-vehicle"]["spidertron"].minable ~= nil and raw["spider-vehicle"]["spidertron"].allow_passengers == nil, "The spidertron of the player was changed")
check(raw["spider-vehicle"]["bm-spidertron_x"].minable ~= nil, "A name that is not a numbered boss was changed")
check(logged("takes no passengers and cannot be mined") == 2 and logs[1]:find("^razi%-protocol: "), "Expected one line for each of the two bosses that were open")
boss_spidertrons.data_final_fixes()
check(logged("takes no passengers") == 2, "The repeated run touched the bosses again")
raw = fresh()
boss_spidertrons.data_final_fixes()
check(next(raw) == nil and #logs == 0, "Something changed without spider vehicles")

-- Mini_Trains entity_data_items
local entity_data_items = require("prototypes.fixes.Mini_Trains.entity_data_items")
raw = fresh()
raw.item = {
	["mini-locomotive"] = {type = "item", name = "mini-locomotive", stack_size = 5},
	["mini-cargo-wagon"] = {type = "item", name = "mini-cargo-wagon", stack_size = 5},
	["mini-fluid-wagon"] = {type = "item", name = "mini-fluid-wagon", stack_size = 5},
	["locomotive"] = {type = "item", name = "locomotive", stack_size = 5},
}
raw["item-with-entity-data"] = {["mini-fluid-wagon"] = {type = "item-with-entity-data", name = "mini-fluid-wagon", stack_size = 1}}
entity_data_items.data_final_fixes()
check(raw.item["mini-locomotive"] == nil and raw.item["mini-cargo-wagon"] == nil, "The items stayed plain")
check(raw["item-with-entity-data"]["mini-locomotive"].type == "item-with-entity-data"
	and raw["item-with-entity-data"]["mini-locomotive"].stack_size == 5, "The locomotive did not move with its fields")
check(raw["item-with-entity-data"]["mini-cargo-wagon"].type == "item-with-entity-data", "The cargo wagon did not move")
check(raw.item["mini-fluid-wagon"] ~= nil and raw["item-with-entity-data"]["mini-fluid-wagon"].stack_size == 1,
	"An item that already exists as item-with-entity-data was replaced")
check(raw.item["locomotive"] ~= nil, "Another item was moved")
check(logged("is an item-with-entity-data") == 2 and logs[1]:find("^razi%-protocol: "), "Expected one line for each of the two items that moved")
entity_data_items.data_final_fixes()
check(logged("is an item-with-entity-data") == 2, "The repeated run moved the items again")
raw = fresh()
raw.item = {["mini-locomotive"] = {type = "item", name = "mini-locomotive"}}
entity_data_items.data_final_fixes()
check(raw.item["mini-locomotive"] ~= nil and #logs == 0, "An item moved without the table of item-with-entity-data")
raw = fresh()
entity_data_items.data_final_fixes()
check(next(raw) == nil and #logs == 0, "Something changed without items")

-- lane-balancers hidden_splitters
local hidden_splitters = require("prototypes.fixes.lane-balancers.hidden_splitters")
raw = fresh()
raw["lane-splitter"] = {
	["lane-splitter"] = {next_upgrade = "fast-lane-splitter"},
	["fast-lane-splitter"] = {next_upgrade = "kr-advanced-lane-splitter"},
	["kr-advanced-lane-splitter"] = {next_upgrade = "kr-superior-lane-splitter"},
	["kr-superior-lane-splitter"] = {},
	["plain-lane-splitter"] = {},
}
raw.item = {
	["fast-splitter"] = {},
	["kr-advanced-splitter"] = {hidden = true},
	["kr-superior-splitter"] = {},
	["splitter"] = {hidden = false},
}
raw.recipe = {
	["lane-splitter"] = {ingredients = {{type = "item", name = "splitter", amount = 1}}, enabled = true},
	["fast-lane-splitter"] = {ingredients = {{type = "item", name = "fast-splitter", amount = 1}}},
	["kr-advanced-lane-splitter"] = {ingredients = {{type = "item", name = "kr-advanced-splitter", amount = 1}}},
	["kr-superior-lane-splitter"] = {ingredients = {{type = "item", name = "kr-superior-splitter", amount = 1}, {type = "item", name = "iron-plate", amount = 1}}},
}
raw.technology = {
	["logistics-4"] = {effects = {
		{type = "unlock-recipe", recipe = "kr-advanced-lane-splitter"},
		{type = "unlock-recipe", recipe = "kr-superior-lane-splitter"},
		{type = "give-item", item = "kr-advanced-lane-splitter"},
	}},
	["logistics-5"] = {effects = {{type = "unlock-recipe", recipe = "kr-advanced-lane-splitter"}}},
	["no-effects"] = {},
}
hidden_splitters.data_final_fixes()
check(raw.recipe["kr-advanced-lane-splitter"].hidden == true and raw.recipe["kr-advanced-lane-splitter"].enabled == false,
	"The lane splitter of the hidden splitter stayed visible")
check(raw.recipe["lane-splitter"].hidden == nil and raw.recipe["fast-lane-splitter"].hidden == nil
	and raw.recipe["kr-superior-lane-splitter"].hidden == nil, "A lane splitter of a visible splitter was hidden")
check(raw["lane-splitter"]["fast-lane-splitter"].next_upgrade == "kr-superior-lane-splitter", "The upgrade planner still stops at the hidden lane splitter")
check(raw["lane-splitter"]["kr-advanced-lane-splitter"] ~= nil and raw.item["kr-advanced-splitter"].hidden == true, "The entity or the item was removed")
check(#raw.technology["logistics-4"].effects == 2 and raw.technology["logistics-4"].effects[1].recipe == "kr-superior-lane-splitter"
	and raw.technology["logistics-4"].effects[2].type == "give-item", "The unlock stayed in the technology or another effect went too")
check(#raw.technology["logistics-5"].effects == 0, "The unlock stayed in the second technology")
check(#logs == 1 and logs[1]:find("^razi%-protocol: kr%-advanced%-lane%-splitter hidden: its splitter kr%-advanced%-splitter is hidden, 2 unlocks removed"),
	"Expected one line for the lane splitter that was hidden, with the number of unlocks removed")
hidden_splitters.data_final_fixes()
check(#logs == 1, "The repeated run touched the lane splitters again")
raw = fresh()
hidden_splitters.data_final_fixes()
check(next(raw) == nil and #logs == 0, "Something changed without lane splitters")
