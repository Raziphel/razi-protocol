---@diagnostic disable: missing-fields
-- Repairs of mistakes in the data of required mods (prototypes/fixes/): the ice box of Corrundum, the Muluna hard drive
-- and burner roboport, the description of an Arig technology, the connectors of the Dyson sphere, the upgrade chain of the
-- hyper belts, the galvanization pack of Cubium, the nutrients of Apia and the electrochemical plant, on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_mod_fixes_data_errors.lua
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

local mod_list = {}
local item_types = {item = 1, capsule = 2}

---@return any
local function fresh()
	logs = {}
	local raw = {}
	rawset(_G, "data", {raw = raw})
	rawset(_G, "mods", mod_list)
	rawset(_G, "defines", {prototypes = {item = item_types}})
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
for _, name in ipairs({"recipe", "technology", "capsule", "item", "roboport", "assembling-machine", "electric-energy-interface",
	"loader-1x1", "transport-belt", "underground-belt", "splitter"}) do
	raw[name] = {}
end
fixes.data_final_fixes()
check(#logs == 0, "A repair logged on empty prototype tables")

-- apia nutrients_refresh
local nutrients_refresh = require("prototypes.fixes.apia.nutrients_refresh")
raw = fresh()
raw.item = {
	nutrients = {fuel_categories = {"nutrients"}},
	["old-nutrients"] = {fuel_category = "nutrients"},
	["bacteria"] = {fuel_categories = {"chemical"}},
}
raw.capsule = {["nutrient-bar"] = {fuel_categories = {"chemical", "nutrients"}}}
raw.recipe = {
	["nutrients-refresh-freshness"] = {},
	["old-nutrients-refresh-freshness"] = {},
	["bacteria-refresh-freshness"] = {},
	["nutrient-bar-refresh-freshness"] = {},
}
raw.technology = {
	one = {effects = {
		{type = "unlock-recipe", recipe = "nutrients-refresh-freshness"},
		{type = "unlock-recipe", recipe = "bacteria-refresh-freshness"},
		{type = "nothing"},
		{type = "unlock-recipe", recipe = "nutrient-bar-refresh-freshness"},
	}},
	two = {},
}
nutrients_refresh.data_final_fixes()
check(raw.recipe["nutrients-refresh-freshness"] == nil and raw.recipe["old-nutrients-refresh-freshness"] == nil
	and raw.recipe["nutrient-bar-refresh-freshness"] == nil, "A recipe of nutrients stayed")
check(raw.recipe["bacteria-refresh-freshness"] ~= nil, "The recipe of an item that is not nutrients was removed")
check(#raw.technology.one.effects == 2 and raw.technology.one.effects[1].recipe == "bacteria-refresh-freshness"
	and raw.technology.one.effects[2].type == "nothing", "The unlocks were not taken out, or others were")
check(logged("(apia skips nutrients)") == 3 and logs[1]:find("^razi%-protocol: "), "Expected a line for each of the three recipes, got " .. logged("(apia skips nutrients)"))
nutrients_refresh.data_final_fixes()
check(logged("(apia skips nutrients)") == 3, "The repeated run touched the recipes again")
raw = fresh()
nutrients_refresh.data_final_fixes()
check(next(raw) == nil and #logs == 0, "Something changed without recipes")

print("test_mod_fixes_data_errors: ok")
