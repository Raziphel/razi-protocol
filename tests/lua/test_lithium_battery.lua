---@diagnostic disable: missing-fields, assign-type-mismatch, need-check-nil
-- Lithium Battery in the pack (prototypes/fixes/LithiumBattery/lithium_battery.lua) on a mocked data.raw: the belt category stays
-- craftable after Razi hides the assembling machine, and missing Vesta items are removed from its recipes and recycling.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_lithium_battery.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local logged = {}
rawset(_G, "log", function(text) logged[#logged + 1] = text end)

---@return any, any
local function setup(mod_list)
	local data_raw = {recipe = {}}
	rawset(_G, "mods", mod_list)
	rawset(_G, "data", {raw = data_raw})
	logged = {}
	package.loaded["prototypes.fixes.LithiumBattery.lithium_battery"] = nil
	return data_raw, require("prototypes.fixes.LithiumBattery.lithium_battery")
end

local function ingredient_list(recipe)
	local out = {}
	for _, ingredient in ipairs(recipe.ingredients) do
		out[#out + 1] = (ingredient.type or "item") .. ":" .. ingredient.name .. "=" .. ingredient.amount
	end
	return table.concat(out, ",")
end

---@type any
local data_raw
---@type any
local module

-- the belt category: only while the assembling machine 4 is hidden, and only for the Krastorio advanced assembler and its copies
local function belt_pack(hidden)
	local function machine(name, hidden_machine)
		return {type = "assembling-machine", name = name, hidden = hidden_machine,
			crafting_categories = {"crafting", "hea-fabrication"}}
	end
	data_raw, module = setup({LithiumBattery = true})
	data_raw.recipe["assembling-machine-4"] = {type = "recipe", name = "assembling-machine-4", hidden = hidden}
	data_raw["recipe-category"] = {["hea-am4-only"] = {type = "recipe-category", name = "hea-am4-only"}}
	data_raw["assembling-machine"] = {
		["assembling-machine-4"] = {type = "assembling-machine", name = "assembling-machine-4", hidden = hidden,
			crafting_categories = {"crafting", "hea-am4-only"}},
		["kr-advanced-assembling-machine"] = machine("kr-advanced-assembling-machine"),
		["bioluminescent-kr-advanced-assembling-machine"] = machine("bioluminescent-kr-advanced-assembling-machine"),
		["assembling-machine-3"] = machine("assembling-machine-3"),
		["hidden-kr-advanced-assembling-machine"] = machine("hidden-kr-advanced-assembling-machine", true),
	}
	module.data_final_fixes()
	return data_raw["assembling-machine"]
end

local function has_category(machine)
	for _, category in ipairs(machine.crafting_categories) do
		if category == "hea-am4-only" then
			return true
		end
	end
	return false
end

local machines = belt_pack(true)
check(has_category(machines["kr-advanced-assembling-machine"]), "advanced assembler lacks the belt category")
check(has_category(machines["bioluminescent-kr-advanced-assembling-machine"]), "its copy lacks the belt category")
check(not has_category(machines["assembling-machine-3"]), "assembling machine 3 got the belt category")
check(not has_category(machines["hidden-kr-advanced-assembling-machine"]), "a hidden machine got the belt category")
check(#machines["kr-advanced-assembling-machine"].crafting_categories == 3, "category added twice")
machines = belt_pack(false)
check(not has_category(machines["kr-advanced-assembling-machine"]), "belt category added while the assembling machine 4 is usable")

-- Vesta without its legacy recipes: the items Lithium Battery adds to its recipes are not there
rawset(_G, "defines", {prototypes = {item = {item = 0, tool = 0}}})
local function vesta_pack(mod_list, with_legacy_items)
	data_raw, module = setup(mod_list)
	data_raw.item = {["quantum-processor"] = {}, ["hea-engine"] = {}, ["accumulator"] = {}}
	data_raw.fluid = {ske_dt_fuel = {}}
	if with_legacy_items then
		data_raw.item.ske_empty_dt_canister = {}
		data_raw.tool = {["vesta-heater"] = {}}
	end
	data_raw.recipe.ske_fusion_framework = {type = "recipe", name = "ske_fusion_framework", ingredients = {
		{type = "item", name = "quantum-processor", amount = 5},
		{type = "item", name = "hea-engine", amount = 1},
		{type = "item", name = "ske_empty_dt_canister", amount = 2},
		{type = "item", name = "accumulator", amount = 1},
		{type = "fluid", name = "ske_dt_fuel", amount = 200},
	}}
	data_raw.recipe.ske_fusion_thruster = {type = "recipe", name = "ske_fusion_thruster", ingredients = {
		{type = "item", name = "vesta-heater", amount = 1},
		{type = "item", name = "hea-engine", amount = 5},
	}}
	data_raw.recipe["ske_fusion_framework-recycling"] = {type = "recipe", name = "ske_fusion_framework-recycling", results = {
		{type = "item", name = "quantum-processor", amount = 1},
		{type = "item", name = "ske_empty_dt_canister", amount = 0.5},
	}}
	module.data_final_fixes()
	return data_raw.recipe
end

local function vesta_lines()
	local count = 0
	for _, line in ipairs(logged) do
		count = count + (line:find("legacy recipes", 1, true) and 1 or 0)
	end
	return count
end

local recipes = vesta_pack({LithiumBattery = true, skewer_planet_vesta = true}, false)
check(ingredient_list(recipes.ske_fusion_framework)
	== "item:quantum-processor=5,item:hea-engine=1,item:accumulator=1,fluid:ske_dt_fuel=200",
	"framework: " .. ingredient_list(recipes.ske_fusion_framework))
check(ingredient_list(recipes.ske_fusion_thruster) == "item:hea-engine=5", "thruster: " .. ingredient_list(recipes.ske_fusion_thruster))
check(#recipes["ske_fusion_framework-recycling"].results == 1 and recipes["ske_fusion_framework-recycling"].results[1].name
	== "quantum-processor", "recycling still returns the canister")
check(vesta_lines() == 3, "one log line per removed ingredient and result: " .. vesta_lines())
recipes = vesta_pack({LithiumBattery = true, skewer_planet_vesta = true}, true)
check(#recipes.ske_fusion_framework.ingredients == 5 and #recipes.ske_fusion_thruster.ingredients == 2
	and #recipes["ske_fusion_framework-recycling"].results == 2,
	"ingredients removed while Vesta makes the items")
check(vesta_lines() == 0, "logged while Vesta makes the items")
recipes = vesta_pack({LithiumBattery = true}, false)
check(#recipes.ske_fusion_framework.ingredients == 5, "changed without Vesta")
recipes = vesta_pack({skewer_planet_vesta = true}, false)
check(#recipes.ske_fusion_framework.ingredients == 5, "changed without Lithium Battery")

-- a pack without technologies or recipes does not fail
rawset(_G, "mods", {LithiumBattery = true})
rawset(_G, "data", {raw = {}})
package.loaded["prototypes.fixes.LithiumBattery.lithium_battery"] = nil
require("prototypes.fixes.LithiumBattery.lithium_battery").data_final_fixes()

print("lithium battery: ok")
