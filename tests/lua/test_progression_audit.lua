-- K2 sand progression uses the prototype IDs from the pack sources:
-- Krastorio2 defines kr-sand as disabled, K2SO unlocks it with kr-stone-processing,
-- and Muluna owns the separate technology named crusher.
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(value, message)
	if not value then
		error(message, 2)
	end
end

local function contains(list, value)
	for _, entry in ipairs(list or {}) do
		if entry == value then
			return true
		end
	end
	return false
end

local function has_unlock(technology, recipe)
	for _, effect in ipairs(technology.effects or {}) do
		if effect.type == "unlock-recipe" and effect.recipe == recipe then
			return true
		end
	end
	return false
end

local function deepcopy(value, seen)
	if type(value) ~= "table" then
		return value
	end
	seen = seen or {}
	if seen[value] then
		return seen[value]
	end
	local copy = {}
	seen[value] = copy
	for key, entry in pairs(value) do
		copy[deepcopy(key, seen)] = deepcopy(entry, seen)
	end
	return copy
end

if not table.deepcopy then
	table.deepcopy = deepcopy -- luacheck: ignore 122
end

local crusher = {effects = {{type = "unlock-recipe", recipe = "muluna-crusher"}}}
local kr_crusher = {effects = {{type = "unlock-recipe", recipe = "kr-crusher"}}}
local kr_stone_processing = {
	effects = {
		{type = "unlock-recipe", recipe = "kr-sand"},
		{type = "unlock-recipe", recipe = "kr-glass"}
	}
}
local sand_processing = {
	effects = {
		{type = "unlock-recipe", recipe = "kr-sand"},
		{type = "unlock-recipe", recipe = "sand"}
	}
}
local glass_processing = {prerequisites = {}}
local kr_sand_recipe = {
	enabled = false,
	ingredients = {{type = "item", name = "stone", amount = 3}},
	results = {{type = "item", name = "kr-sand", amount_min = 7, amount_max = 8}}
}
local sand_recipe = {enabled = false, ingredients = {}, results = {}}

rawset(_G, "data", {raw = {
	technology = {
		crusher = crusher,
		["kr-crusher"] = kr_crusher,
		["kr-stone-processing"] = kr_stone_processing,
		["sand-processing"] = sand_processing,
		["glass-processing"] = glass_processing
	},
	recipe = { ["kr-sand"] = kr_sand_recipe, sand = sand_recipe },
	item = { ["kr-sand"] = {} },
	furnace = { ["kr-crusher"] = {crafting_categories = {"crafting"}} }
}})

require("prototypes.fixes.common.unlock_order").data_final_fixes()
check(not has_unlock(crusher, "kr-sand"), "Muluna crusher must not unlock K2 sand")
check(not has_unlock(crusher, "sand"), "Muluna crusher must not unlock sand")
check(has_unlock(kr_stone_processing, "kr-sand"), "K2 stone processing must unlock kr-sand")
check(has_unlock(kr_stone_processing, "sand"), "K2 stone processing must own the sand unlock")
check(not has_unlock(sand_processing, "kr-sand") and not has_unlock(sand_processing, "sand"),
	"The old sand-processing unlocks must be removed")
check(kr_sand_recipe.enabled == false and sand_recipe.enabled == false,
	"The recipes must stay disabled until research")

require("prototypes.compatibility.Krastorio2-spaced-out.sand_progression").data_final_fixes()
check(contains(sand_processing.prerequisites, "kr-crusher"), "Sand processing must follow the K2 crusher")
check(not contains(sand_processing.prerequisites, "crusher"), "Sand processing must not follow Muluna crusher")

require("prototypes.fixes.Krastorio2-spaced-out.sand_recipe").data_final_fixes()
check(kr_sand_recipe.enabled == false, "The K2 recipe fix must preserve the disabled state")

crusher.order = "muluna-native-order"
require("prototypes.fixes.common.technology_order").data_final_fixes()
check(crusher.order == "muluna-native-order", "The Razi technology order must leave Muluna crusher alone")

print("K2 sand research and Muluna crusher progression stay separate")
