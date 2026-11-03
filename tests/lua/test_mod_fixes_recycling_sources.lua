---@diagnostic disable: missing-fields
-- Repair of the recycling recipes that the recycler built from a casting recipe instead of the main recipe
-- (prototypes/fixes/common/recycling_sources.lua), on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_mod_fixes_recycling_sources.lua
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
	local stub = {raw = raw}
	function stub.extend(_, prototypes)
		for _, prototype in ipairs(prototypes) do
			raw[prototype.type] = raw[prototype.type] or {}
			raw[prototype.type][prototype.name] = prototype
		end
	end
	rawset(_G, "data", stub)
	rawset(_G, "mods", {})
	rawset(_G, "defines", {prototypes = {item = {item = 1}, entity = {}}})
	return raw
end

-- The recycler of the game, reduced to what the repair relies on: a recycling recipe named after the sole item of the
-- recipe it reverses, written over a recipe of that name, and an unlock appended to the recycling technology.
local recycler_loads = 0
package.preload["__recycler__.recycling"] = function()
	recycler_loads = recycler_loads + 1

	local recycler = {}
	function recycler.generate_recycling_recipe(recipe)
		if recipe.auto_recycle == false then
			return
		end
		local item_name
		for _, product in pairs(recipe.results or {}) do
			if product.type == "item" then
				item_name = product.name
			end
		end
		if not item_name then
			return
		end

		local results = {}
		for _, ingredient in pairs(recipe.ingredients or {}) do
			if ingredient.type == "item" then
				results[#results + 1] = {type = "item", name = ingredient.name, amount = math.floor(ingredient.amount),
					extra_count_fraction = 0}
			end
		end
		local name = item_name .. "-recycling"
		_G.data.raw.recipe[name] = {
			type = "recipe",
			name = name,
			categories = {"recycling"},
			results = results,
			energy_required = (recipe.energy_required or 0.5) / 16,
			subgroup = recipe.subgroup,
			crafting_machine_tint = {primary = {0.5, 0.5, 0.5}},
			hidden = true,
		}
		-- the real library keeps the effects table it found when it was loaded
		local technology = _G.data.raw.technology and _G.data.raw.technology.recycling
		local target = recycler.effects_target or (technology and technology.effects)
		if target then
			table.insert(target, {type = "unlock-recipe", recipe = name, hidden = true})
		end
	end

	return recycler
end

-- Recycling: an engine unit with its recipe and a casting recipe of Pelagos, the way the recycler builds it ---------
local recycling_sources = require("prototypes.fixes.common.recycling_sources")

---@param casting_fields table|nil fields to add to the casting recipe
---@return any raw, any recycler
local function engine_world(casting_fields)
	local raw = fresh()
	raw.recipe = {
		["engine-unit"] = {
			type = "recipe", name = "engine-unit", subgroup = "intermediate-product", energy_required = 10,
			ingredients = {{type = "item", name = "steel-plate", amount = 1}, {type = "item", name = "gear-wheel", amount = 1},
				{type = "item", name = "pipe", amount = 2}},
			results = {{type = "item", name = "engine-unit", amount = 1}},
		},
		["pelagos-casting-engine-unit"] = {
			type = "recipe", name = "pelagos-casting-engine-unit", category = "metallurgy", energy_required = 10,
			subgroup = "vulcanus-processes",
			ingredients = {{type = "fluid", name = "molten-iron", amount = 50},
				{type = "item", name = "activated-carbon", amount = 3}},
			results = {{type = "item", name = "engine-unit", amount = 1}},
		},
		["iron-gear-wheel"] = {
			type = "recipe", name = "iron-gear-wheel",
			ingredients = {{type = "item", name = "iron-plate", amount = 2}},
			results = {{type = "item", name = "gear-wheel", amount = 1}},
		},
	}
	for key, value in pairs(casting_fields or {}) do
		raw.recipe["pelagos-casting-engine-unit"][key] = value
	end
	raw.technology = {recycling = {effects = {{type = "unlock-recipe", recipe = "unrelated-recycling", hidden = true}}}}
	local recycler = require("__recycler__.recycling")
	-- insertion order of the real data stage: the main recipe first, the casting recipe later, which wins
	recycler.generate_recycling_recipe(raw.recipe["engine-unit"])
	recycler.generate_recycling_recipe(raw.recipe["pelagos-casting-engine-unit"])
	raw.recipe["engine-unit-recycling"].enabled = true -- moon-eneas
	raw.recipe["engine-unit-recycling"].allowed_module_categories = {"quality"} -- appended by another mod
	return raw, recycler
end

-- what the recycler builds from the main recipe, taken on a world of its own
local wanted
do
	local probe = engine_world()
	probe.recipe["pelagos-casting-engine-unit"].auto_recycle = false
	require("__recycler__.recycling").generate_recycling_recipe(probe.recipe["engine-unit"])
	wanted = deepcopy(probe.recipe["engine-unit-recycling"])
end
local main_recipe = deepcopy(engine_world().recipe["engine-unit"])

local raw = engine_world()
check(raw.recipe["engine-unit-recycling"].results[1].name == "activated-carbon", "The mock did not make the mistake")
check(#raw.technology.recycling.effects == 3, "The mock did not append the unlocks")
local effects_before = deepcopy(raw.technology.recycling.effects)
recycling_sources.data_final_fixes()
local recycling = raw.recipe["engine-unit-recycling"]
check(same(recycling.results, wanted.results) and recycling.results[1].name == "steel-plate",
	"The engine unit is not recycled by its main recipe")
check(recycling.energy_required == wanted.energy_required and recycling.subgroup == "intermediate-product",
	"The time and the subgroup are not those of the main recipe")
check(recycling.enabled == true and recycling.hidden == true and recycling.allowed_module_categories[1] == "quality",
	"The fields that do not depend on the reversed recipe were changed")
check(same(raw.technology.recycling.effects, effects_before), "The unlocks of the recycling technology changed")
check(logged("razi-protocol: engine-unit-recycling rebuilt from recipe engine-unit (was built from "
	.. "pelagos-casting-engine-unit)") == 1 and #logs == 1, "Expected one line for the engine unit")
check(same(raw.recipe["engine-unit"], main_recipe), "The main recipe was changed")
local after = deepcopy(raw.recipe)
recycling_sources.data_final_fixes()
check(same(raw.recipe, after) and #logs == 1, "The repeated run changed or logged again")

-- the same with the categories list of a mod that is updated for 2.1
raw = engine_world()
raw.recipe["pelagos-casting-engine-unit"].category = nil
raw.recipe["pelagos-casting-engine-unit"].categories = {"metallurgy"}
recycling_sources.data_final_fixes()
check(raw.recipe["engine-unit-recycling"].results[1].name == "steel-plate" and #logs == 1,
	"A casting recipe with the categories list was not found")

-- a casting recipe that keeps out of the recycler is no source
raw = engine_world({auto_recycle = false})
raw.recipe["engine-unit-recycling"].results = {{type = "item", name = "steel-plate", amount = 1, extra_count_fraction = 0}}
local before = deepcopy(raw.recipe)
recycling_sources.data_final_fixes()
check(same(raw.recipe, before) and #logs == 0, "A casting recipe with auto_recycle = false was treated as a source")

-- a recycling recipe written by hand fits no casting recipe and stays
raw = engine_world()
raw.recipe["engine-unit-recycling"].results = {{type = "item", name = "iron-plate", amount = 5, extra_count_fraction = 0}}
before = deepcopy(raw.recipe)
local effects_hand = deepcopy(raw.technology.recycling.effects)
recycling_sources.data_final_fixes()
check(same(raw.recipe, before) and #logs == 0, "A hand-written recycling recipe was rebuilt")
check(same(raw.technology.recycling.effects, effects_hand), "The unlocks changed with a hand-written recycling recipe")

-- a casting recipe that reverses to the same results as the main recipe is no source: nothing to rebuild
raw = engine_world()
raw.recipe["pelagos-casting-engine-unit"].ingredients = deepcopy(raw.recipe["engine-unit"].ingredients)
require("__recycler__.recycling").generate_recycling_recipe(raw.recipe["pelagos-casting-engine-unit"])
before = deepcopy(raw.recipe)
recycling_sources.data_final_fixes()
check(same(raw.recipe, before) and #logs == 0, "A recipe with the right results was rebuilt")

-- the technology got another list of effects than the library keeps: the new recycling recipe keeps its unlock
local recycler
raw, recycler = engine_world()
recycler.effects_target = raw.technology.recycling.effects
raw.technology.recycling.effects = {{type = "unlock-recipe", recipe = "unrelated-recycling", hidden = true}}
recycling_sources.data_final_fixes()
check(raw.recipe["engine-unit-recycling"].results[1].name == "steel-plate" and #logs == 1, "The recipe was not rebuilt")
local list = raw.technology.recycling.effects
local put_back = list[#list]
check(#list == 2 and put_back.recipe == "engine-unit-recycling" and put_back.hidden == true,
	"The unlock of the rebuilt recipe was not put back")
raw, recycler = engine_world()
recycler.effects_target = raw.technology.recycling.effects
raw.technology.recycling.effects = {{type = "unlock-recipe", recipe = "engine-unit-recycling", hidden = true}}
recycling_sources.data_final_fixes()
check(#raw.technology.recycling.effects == 1, "An unlock that is there was added again")

-- a recycling recipe that is built from the main recipe already stays
raw = engine_world()
raw.recipe["pelagos-casting-engine-unit"].auto_recycle = false
require("__recycler__.recycling").generate_recycling_recipe(raw.recipe["engine-unit"])
raw.technology.recycling.effects = {}
before = deepcopy(raw.recipe)
recycling_sources.data_final_fixes()
check(same(raw.recipe, before) and #logs == 0 and #raw.technology.recycling.effects == 0,
	"A recycling recipe built from the main recipe was changed")

-- no recycling technology: nothing to keep in order, the recipe is rebuilt all the same
raw = engine_world()
raw.technology = nil
recycling_sources.data_final_fixes()
check(raw.recipe["engine-unit-recycling"].results[1].name == "steel-plate" and #logs == 1,
	"Without the recycling technology the recipe was not rebuilt")

-- an item that is itself a metallurgy recipe, or has no main recipe, or no recycling recipe, is left alone
raw = engine_world()
raw.recipe["engine-unit"] = nil
before = deepcopy(raw.recipe)
recycling_sources.data_final_fixes()
check(same(raw.recipe, before) and #logs == 0, "An item without a main recipe was changed")
raw = engine_world()
raw.recipe["engine-unit-recycling"] = nil
recycling_sources.data_final_fixes()
check(raw.recipe["engine-unit-recycling"] == nil and #logs == 0, "A missing recycling recipe was created")

-- the library of the recycler is loaded only when a recipe may need it
raw = fresh()
raw.recipe = {["plain"] = {type = "recipe", name = "plain", results = {{type = "item", name = "plain", amount = 1}}}}
raw.recipe["x-casting"] = {type = "recipe", name = "x-casting", categories = {"metallurgy"},
	results = {{type = "item", name = "plain", amount = 1}}}
package.loaded["__recycler__.recycling"] = nil
recycler_loads = 0
recycling_sources.data_final_fixes()
check(recycler_loads == 0 and #logs == 0, "The recycler library was loaded without a recycling recipe in question")
raw = fresh()
recycling_sources.data_final_fixes()
check(next(raw) == nil and #logs == 0 and recycler_loads == 0, "Something changed without recipes")

print("mod fixes (recycling sources): ok")
