---@diagnostic disable: missing-fields, need-check-nil, inject-field
-- Eneas with integrate-lignumis replaces the unlocks of iron-processing; the ones it drops come back.
-- Run from the mod root with the library bootstrap: tests/run.sh
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local logs = {}
rawset(_G, "log", function(line)
	logs[#logs + 1] = line
end)

local INSTALLED = {["moon-eneas"] = "1.0.10", lignumis = "2.13.2"}

-- iron-processing as Lignumis leaves it for K2SO in data-updates (the recipes of the pack, shortened).
local LIGNUMIS_UNLOCKS = {"iron-plate", "iron-chest", "iron-gear-wheel", "steam-inserter-iron", "iron-stick", "kr-iron-beam"}

-- What moon-eneas prototypes/patches/lignumis-recipe.lua:5-11 writes instead.
local ENEAS_UNLOCKS = {"iron-plate", "iron-chest", "iron-gear-wheel", "transport-belt"}

local function effects(recipes)
	local list = {}
	for _, recipe in ipairs(recipes) do
		list[#list + 1] = {type = "unlock-recipe", recipe = recipe}
	end
	return list
end

local function recipes_of(technology)
	local list = {}
	for _, effect in ipairs(technology.effects) do
		list[#list + 1] = effect.recipe
	end
	return table.concat(list, ",")
end

-- Loads the fix anew, runs its data-updates on the Lignumis list, lets Eneas replace it, runs data-final-fixes.
local function run(installed, integrate, existing_recipes)
	logs = {}
	package.loaded["prototypes.fixes.moon-eneas.lignumis_iron_processing"] = nil
	local fix = require("prototypes.fixes.moon-eneas.lignumis_iron_processing")
	local recipe = {}
	for _, name in ipairs(existing_recipes or LIGNUMIS_UNLOCKS) do
		recipe[name] = {name = name}
	end
	recipe["transport-belt"] = {name = "transport-belt"}
	local technology = {name = "iron-processing", effects = effects(LIGNUMIS_UNLOCKS)}
	rawset(_G, "mods", installed)
	rawset(_G, "settings", {startup = integrate == nil and {} or {["integrate-lignumis"] = {value = integrate}}})
	rawset(_G, "data", {raw = {technology = {["iron-processing"] = technology}, recipe = recipe}})
	fix.data_updates()
	technology.effects = effects(ENEAS_UNLOCKS)
	fix.data_final_fixes()
	return technology
end

local technology = run(INSTALLED, true)
check(recipes_of(technology) == "iron-plate,iron-chest,iron-gear-wheel,transport-belt,steam-inserter-iron,iron-stick,kr-iron-beam",
	"the dropped unlocks come back after Eneas' own, got " .. recipes_of(technology))
check(#logs == 3, "every unlock added back is logged, got " .. #logs)

-- A recipe that no longer exists is not unlocked.
technology = run(INSTALLED, true, {"iron-plate", "iron-chest", "iron-gear-wheel", "iron-stick"})
check(recipes_of(technology) == "iron-plate,iron-chest,iron-gear-wheel,transport-belt,iron-stick",
	"only existing recipes come back, got " .. recipes_of(technology))

-- With integrate-lignumis off Eneas leaves iron-processing alone; so does the fix.
technology = run(INSTALLED, false)
check(recipes_of(technology) == table.concat(ENEAS_UNLOCKS, ",") and #logs == 0, "nothing changes without the setting")

-- Without Eneas the setting does not exist.
technology = run({lignumis = "2.13.2"}, nil)
check(recipes_of(technology) == table.concat(ENEAS_UNLOCKS, ",") and #logs == 0, "nothing changes without Eneas")

print("test_mod_fixes_eneas_lignumis_iron_processing ok")
