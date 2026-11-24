---@diagnostic disable: missing-fields, need-check-nil, inject-field
-- Castra Prime gives its "castra-<category>" copies to assembling machines only; furnaces get them too, so the Arcane
-- Infuser of Foliax processes Nature's Bounty again.
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

local fix = require("prototypes.fixes.castra-prime.furnace_categories")

local function category_set(names)
	local set = {}
	for _, name in ipairs(names) do
		set[name] = {type = "recipe-category", name = name}
	end
	return set
end

-- The pack after Castra's data-updates: scrap-recycling-basic moved to castra-foliax-recycling, which only the forge has.
local function world(installed)
	logs = {}
	rawset(_G, "mods", installed or {["castra-prime"] = "0.9.5", foliax = "3.0.10"})
	local raw = {
		["recipe-category"] = category_set({"smelting", "foliax-recycling", "castra-foliax-recycling", "forge", "castra-forge",
			"hand-crafting", "castra-hand-crafting"}),
		furnace = {
			["foliax-recycler"] = {name = "foliax-recycler", crafting_categories = {"foliax-recycling"}},
			["stone-furnace"] = {name = "stone-furnace", crafting_categories = {"smelting"}},
			["steam-recycler"] = {name = "steam-recycler", crafting_categories = {"recycling", "hand-crafting"}},
		},
		["assembling-machine"] = {
			forge = {name = "forge", crafting_categories = {"forge", "castra-forge", "castra-foliax-recycling"}},
		},
		recipe = {
			["scrap-recycling-basic"] = {name = "scrap-recycling-basic", categories = {"castra-foliax-recycling"}},
		},
	}
	rawset(_G, "data", {raw = raw})
	return raw
end

-- The machines that can craft a recipe, the way the game matches categories.
local function crafters(raw, recipe_name)
	local category = raw.recipe[recipe_name].categories[1]
	local names = {}
	for _, kind in ipairs({"furnace", "assembling-machine"}) do
		for name, machine in pairs(raw[kind]) do
			for _, own in ipairs(machine.crafting_categories) do
				if own == category then
					names[#names + 1] = name
				end
			end
		end
	end
	table.sort(names)
	return table.concat(names, ",")
end

local raw = world()
check(crafters(raw, "scrap-recycling-basic") == "forge", "before the fix only the forge processes the bounty")
fix.data_final_fixes()
check(crafters(raw, "scrap-recycling-basic") == "foliax-recycler,forge",
	"the Arcane Infuser processes the bounty, got " .. crafters(raw, "scrap-recycling-basic"))
check(table.concat(raw.furnace["foliax-recycler"].crafting_categories, ",") == "foliax-recycling,castra-foliax-recycling",
	"the infuser keeps its own category first")
check(table.concat(raw.furnace["stone-furnace"].crafting_categories, ",") == "smelting",
	"a furnace whose category Castra did not copy stays as it is")
check(table.concat(raw.furnace["steam-recycler"].crafting_categories, ",") == "recycling,hand-crafting",
	"the steam recycler does not take Castra's hand-crafting recipes")
check(#logs == 1, "the change is logged, got " .. #logs)

-- A second run adds nothing twice.
fix.data_final_fixes()
check(#raw.furnace["foliax-recycler"].crafting_categories == 2 and #logs == 1, "no duplicate category")

-- Without Castra Prime nothing changes.
raw = world({foliax = "3.0.10"})
fix.data_final_fixes()
check(#raw.furnace["foliax-recycler"].crafting_categories == 1 and #logs == 0, "without Castra Prime nothing changes")

print("test_mod_fixes_castra_furnace_categories ok")
