-- Run from the repository root with: lua tests/natural_decorations_test.lua
-- Small prototype-stage regression test; Factorio itself is not required.
local function recipe(name, category, output, subgroup)
	return {
		name = name,
		categories = {category},
		results = {{type = "item", name = output}},
		subgroup = subgroup
	}
end

local log_messages = {}
_G.log = function(message) log_messages[#log_messages + 1] = message end

_G.data = {
	raw = {
		["recipe-category"] = {},
		tree = {["ribbonia-tree"] = {}, ["tree-01"] = {}},
		["simple-entity"] = {
			["hyarion-crystal"] = {minable = {results = {{type = "item", name = "quartz", amount = 2}}}},
			["safe-sign"] = {minable = {result = "safe-sign"}}
		},
		item = {
			["ribbonia-tree-item"] = {place_result = "ribbonia-tree", subgroup = "trees"},
			["tree-01"] = {place_result = "tree-01", subgroup = "trees"},
			["hyarion-crystal-item"] = {place_result = "hyarion-crystal"},
			["safe-sign"] = {place_result = "safe-sign"},
			["rock-item"] = {place_result = "big-rock", subgroup = "grass"}
		},
		recipe = {
			["wood"] = recipe("wood", "kr-growing", "wood"),
			["kr-wood-with-fertilizer"] = recipe("kr-wood-with-fertilizer", "kr-growing", "wood"),
			["tree-seed"] = recipe("tree-seed", "crafting", "tree-seed"),
			["ribbonia-tree"] = recipe("ribbonia-tree", "crafting", "ribbonia-tree-item"),
			["tree-01"] = recipe("tree-01", "crafting", "tree-01"),
			["hyarion-crystal"] = recipe("hyarion-crystal", "crafting", "hyarion-crystal-item"),
			["big-rock"] = recipe("big-rock", "crafting", "rock-item"),
			["kr-jellynut"] = recipe("kr-jellynut", "kr-growing", "jellynut"),
			["kr-yumako"] = recipe("kr-yumako", "kr-growing", "yumako"),
			["yumako"] = recipe("yumako", "agriculture", "yumako"),
			["safe-sign"] = recipe("safe-sign", "crafting", "safe-sign")
		},
		technology = {
			["kr-decorations"] = {effects = {
				{type = "unlock-recipe", recipe = "ribbonia-tree"},
				{type = "unlock-recipe", recipe = "big-rock"}
			}},
			["some-mod-tech"] = {effects = {
				{type = "unlock-recipe", recipe = "hyarion-crystal"},
				{type = "unlock-recipe", recipe = "safe-sign"},
				{type = "unlock-recipe", recipe = "wood"}
			}}
		}
	}
}

function data:extend(prototypes)
	for _, prototype in ipairs(prototypes) do
		self.raw[prototype.type] = self.raw[prototype.type] or {}
		self.raw[prototype.type][prototype.name] = prototype
	end
end

local fix = dofile("prototypes/balance/Krastorio2-spaced-out/natural_decorations.lua")
fix.data_final_fixes()

local disabled_category = "razi-disabled-natural-decorations"
local function banned(name)
	local r = data.raw.recipe[name]
	assert(r.enabled == false and r.hidden == true, name .. " still enabled")
	assert(#r.categories == 1 and r.categories[1] == disabled_category, name .. " still craftable")
end
for _, name in ipairs({
	"ribbonia-tree", "tree-01", "hyarion-crystal", "big-rock",
	"kr-jellynut", "kr-yumako"
}) do banned(name) end

for _, name in ipairs({"wood", "kr-wood-with-fertilizer", "tree-seed", "yumako", "safe-sign"}) do
	local r = data.raw.recipe[name]
	assert(not r.hidden, name .. " incorrectly hidden")
	assert(r.categories[1] ~= disabled_category, name .. " incorrectly isolated")
end

assert(data.raw.technology["kr-decorations"].hidden == true)
local effects = data.raw.technology["some-mod-tech"].effects
assert(#effects == 2 and effects[1].recipe == "safe-sign" and effects[2].recipe == "wood")
assert(data.raw["recipe-category"][disabled_category])
assert(#log_messages == 1)

-- Idempotent when the final pass is re-run: no duplicate tech unlocks or logs.
fix.data_final_fixes()
assert(#log_messages == 2)
print("natural_decorations_test: OK")
