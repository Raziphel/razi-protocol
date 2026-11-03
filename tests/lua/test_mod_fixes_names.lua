---@diagnostic disable: missing-fields
-- Repairs of names and tooltips of other mods (prototypes/fixes/): the freshness restoration recipes of Apia, on a
-- mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_mod_fixes_names.lua
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

local function same(left, right)
	if type(left) ~= "table" or type(right) ~= "table" then
		return left == right
	end
	for key, item in pairs(left) do
		if not same(item, right[key]) then
			return false
		end
	end
	for key in pairs(right) do
		if left[key] == nil then
			return false
		end
	end

	return true
end

---@return any
local function fresh()
	logs = {}
	local raw = {}
	rawset(_G, "data", {raw = raw})
	rawset(_G, "mods", {})
	rawset(_G, "defines", {prototypes = {item = {item = 1}, entity = {}}})
	return raw
end

local fixes = require("prototypes.fixes.init")

-- Nothing of the mods is installed: every repair is quiet and does not fail.
---@type any
local raw = fresh()
fixes.data_final_fixes()
check(#logs == 0 and next(raw) == nil, "A repair did something without its prototypes")
raw = fresh()
raw.recipe, raw.item, raw.corpse = {}, {}, {}
fixes.data_final_fixes()
check(#logs == 0, "A repair logged on empty prototype tables")

-- apia refresh_freshness_names
local refresh_freshness_names = require("prototypes.fixes.apia.refresh_freshness_names")
local function apia_name(item_name)
	return {"recipe-name.refresh-freshness", {"item-name." .. item_name}}
end
raw = fresh()
raw.item = {
	["spawner-item"] = {place_result = "spawner"},
	["named-item"] = {localised_name = {"item-name.other"}, place_result = "ignored"},
	["plain-item"] = {},
}
raw.recipe = {
	["spawner-item-refresh-freshness"] = {localised_name = apia_name("spawner-item")},
	["named-item-refresh-freshness"] = {localised_name = apia_name("named-item")},
	["plain-item-refresh-freshness"] = {localised_name = apia_name("plain-item")},
	["missing-item-refresh-freshness"] = {localised_name = apia_name("missing-item")},
	["other-name"] = {localised_name = {"recipe-name.other", {"item-name.spawner-item"}}},
	["extra-argument"] = {localised_name = {"recipe-name.refresh-freshness", {"item-name.spawner-item"}, "more"}},
	["sub-argument"] = {localised_name = {"recipe-name.refresh-freshness", {"item-name.spawner-item", "more"}}},
	["string-name"] = {localised_name = "recipe-name.refresh-freshness"},
	["no-name"] = {},
}
local untouched = deepcopy(raw.recipe)
refresh_freshness_names.data_final_fixes()
---@type any
local spawner = raw.recipe["spawner-item-refresh-freshness"].localised_name
check(spawner[1] == "recipe-name.refresh-freshness" and spawner[2][1] == "?", "The recipe did not get a fallback name")
check(spawner[2][2][1] == "item-name.spawner-item", "The item-name key is not the first choice any more")
check(spawner[2][3][1] == "entity-name.spawner", "The item that places an entity did not fall back to the entity name")
---@type any
local named = raw.recipe["named-item-refresh-freshness"].localised_name
check(named[2][2][1] == "item-name.named-item" and named[2][3][1] == "item-name.other",
	"The item with a localised_name did not fall back to it")
for _, name in ipairs({"plain-item", "missing-item"}) do
	check(raw.recipe[name .. "-refresh-freshness"].localised_name[2][1] == "item-name." .. name,
		"A recipe of an item with nothing to fall back to was changed: " .. name)
end
for _, name in ipairs({"other-name", "extra-argument", "sub-argument", "string-name", "no-name"}) do
	check(same(raw.recipe[name], untouched[name]), "A recipe that Apia did not name that way was changed: " .. name)
end
check(logged("spawner-item-refresh-freshness falls back to the name of spawner-item") == 1
	and logged("named-item-refresh-freshness falls back to the name of named-item") == 1
	and logs[1]:find("^razi%-protocol: "), "Expected one line for each of the two recipes that changed")
check(#logs == 2, "A recipe that was not changed was logged")
refresh_freshness_names.data_final_fixes()
check(#logs == 2 and raw.recipe["spawner-item-refresh-freshness"].localised_name[2][3][1] == "entity-name.spawner",
	"The repeated run changed the names again")
raw = fresh()
refresh_freshness_names.data_final_fixes()
check(next(raw) == nil and #logs == 0, "Something changed without recipes")
raw = fresh()
raw.recipe = {["spawner-item-refresh-freshness"] = {localised_name = apia_name("spawner-item")}}
refresh_freshness_names.data_final_fixes()
check(raw.recipe["spawner-item-refresh-freshness"].localised_name[2][1] == "item-name.spawner-item" and #logs == 0,
	"A recipe was changed without its item")

print("mod fixes (names): ok")
