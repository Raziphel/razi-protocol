---@diagnostic disable: missing-fields, assign-type-mismatch, need-check-nil
-- Ordinary module categories for Module Category Defaults (compat/module_category_defaults.lua) on a mocked data.raw and a stand-in
-- for the mod's global table.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_module_category_defaults.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local logged = {}
rawset(_G, "log", function(text) logged[#logged + 1] = text end)

local function category(name)
	return {type = "module-category", name = name}
end

local function machine(prototype_type, name, categories)
	return {type = prototype_type, name = name, module_slots = 2, allowed_module_categories = categories}
end

-- The stand-in has what the real mod's data.lua makes: ordinary categories, the moduled types and the processed prototypes.
local function setup(mod_list, with_defaults, with_categories)
	local categories = {}
	for _, name in ipairs(with_categories or {"speed", "azure-speed", "arcanyx-curse"}) do
		categories[name] = category(name)
	end
	local data_raw = {
		["module-category"] = categories,
		["assembling-machine"] = {
			-- the author's list with the two categories Voidcraft appends
			["nano-factory"] = machine("assembling-machine", "nano-factory", {"speed", "quality", "omega", "azure-speed", "arcanyx-curse"}),
			-- the voidforges and a machine with an empty list: nothing but the two categories
			["forge"] = machine("assembling-machine", "forge", {"arcanyx-curse"}),
			["apo-chamber"] = machine("assembling-machine", "apo-chamber", {"azure-speed"}),
			["both"] = machine("assembling-machine", "both", {"azure-speed", "arcanyx-curse"}),
			-- a list that is empty, or that Voidcraft did not touch
			["sealed"] = machine("assembling-machine", "sealed", {}),
			["nolist"] = {type = "assembling-machine", name = "nolist", module_slots = 2},
		},
		lab = {
			["curse-lab"] = machine("lab", "curse-lab", {"arcanyx-curse"}),
		},
		furnace = {},
	}
	rawset(_G, "mods", mod_list)
	rawset(_G, "data", {raw = data_raw})
	local defaults
	if with_defaults then
		defaults = {
			moduled_types = {"beacon", "assembling-machine", "rocket-silo", "furnace", "lab", "mining-drill"},
			default_categories = {"efficiency", "speed", "productivity"},
			restricted_categories = {},
			processed_prototypes = {},
		}
	end
	rawset(_G, "ModuleCategoryDefaults", defaults)
	logged = {}
	package.loaded["prototypes.compat.module_category_defaults"] = nil
	return data_raw, defaults, require("prototypes.compat.module_category_defaults")
end

local function has(list, value)
	for _, item in ipairs(list) do
		if item == value then
			return true
		end
	end
	return false
end

local function count(list, value)
	local total = 0
	for _, item in ipairs(list) do
		if item == value then
			total = total + 1
		end
	end
	return total
end

-- both categories are registered, once each, with a log line each
local data_raw, defaults, module = setup({["module-category-defaults"] = "2.2.0"}, true)
module.data_updates()
check(has(defaults.default_categories, "azure-speed"), "azure-speed not registered")
check(has(defaults.default_categories, "arcanyx-curse"), "arcanyx-curse not registered")
check(#defaults.default_categories == 5, "registered list: " .. table.concat(defaults.default_categories, ","))
check(has(defaults.default_categories, "speed") and has(defaults.default_categories, "productivity"), "the ordinary categories went")
check(#logged >= 2, "no log line for the registered categories")

-- lists that hold only the two categories are kept as they are; the others are left to the mod
local processed = defaults.processed_prototypes
check(processed["assembling-machine"] and processed["assembling-machine"]["forge"], "curse-only list not kept")
check(processed["assembling-machine"]["apo-chamber"], "azure-only list not kept")
check(processed["assembling-machine"]["both"], "azure+curse list not kept")
check(processed.lab and processed.lab["curse-lab"], "curse-only lab not kept")
check(not processed["assembling-machine"]["nano-factory"], "the author's list was kept instead of widened")
check(not processed["assembling-machine"]["sealed"], "empty list marked")
check(not processed["assembling-machine"]["nolist"], "machine without a list marked")
check(#data_raw["assembling-machine"]["forge"].allowed_module_categories == 1, "list of the forge changed")
check(#data_raw["assembling-machine"]["nano-factory"].allowed_module_categories == 5, "list of the nano factory changed")

-- a second run adds nothing and logs nothing
local before = #logged
module.data_updates()
check(#defaults.default_categories == 5, "registered twice: " .. table.concat(defaults.default_categories, ","))
check(count(defaults.default_categories, "azure-speed") == 1, "azure-speed twice")
check(#logged == before, "second run logged")

-- a category that already is ordinary is not added again
do
	local _, defaults_here, module_here = setup({["module-category-defaults"] = "2.2.0"}, true)
	table.insert(defaults_here.default_categories, "azure-speed")
	module_here.data_updates()
	check(count(defaults_here.default_categories, "azure-speed") == 1, "azure-speed doubled")
	check(has(defaults_here.default_categories, "arcanyx-curse"), "arcanyx-curse missing next to a registered azure-speed")
end

-- a category that does not exist is not registered, and without any registration the lists stay unmarked
do
	local _, defaults_here, module_here = setup({["module-category-defaults"] = "2.2.0"}, true, {"speed"})
	module_here.data_updates()
	check(#defaults_here.default_categories == 3, "registered a category that does not exist")
	check(next(defaults_here.processed_prototypes) == nil, "lists marked without a registration")
	check(#logged == 0, "logged without a registration")
end
do
	local _, defaults_here, module_here = setup({["module-category-defaults"] = "2.2.0"}, true, {"speed", "arcanyx-curse"})
	module_here.data_updates()
	check(not has(defaults_here.default_categories, "azure-speed") and has(defaults_here.default_categories, "arcanyx-curse"),
		"only the existing category is registered")
end

-- without the mod nothing changes and nothing fails
do
	local data_here, _, module_here = setup({}, false)
	module_here.data_updates()
	check(#logged == 0, "logged without the mod")
	check(#data_here["assembling-machine"]["forge"].allowed_module_categories == 1, "changed without the mod")
end

-- the mod is there, its table is not (another version): nothing fails
do
	local _, _, module_here = setup({["module-category-defaults"] = "9.9.9"}, false)
	module_here.data_updates()
	check(#logged == 0, "logged without the table")
end

-- a table without the lists of processed prototypes: the categories are registered, nothing fails
do
	local _, defaults_here, module_here = setup({["module-category-defaults"] = "2.2.0"}, true)
	defaults_here.processed_prototypes = nil
	module_here.data_updates()
	check(has(defaults_here.default_categories, "azure-speed"), "not registered without processed_prototypes")
end

-- a pack without module categories or machines
do
	local empty_defaults = {moduled_types = {"lab"}, default_categories = {"speed"}, processed_prototypes = {}}
	rawset(_G, "mods", {["module-category-defaults"] = "2.2.0"})
	rawset(_G, "data", {raw = {}})
	rawset(_G, "ModuleCategoryDefaults", empty_defaults)
	package.loaded["prototypes.compat.module_category_defaults"] = nil
	require("prototypes.compat.module_category_defaults").data_updates()
	check(#empty_defaults.default_categories == 1, "registered in an empty pack")
end

print("module category defaults: ok")
