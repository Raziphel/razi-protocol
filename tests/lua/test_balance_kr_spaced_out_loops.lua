---@diagnostic disable: missing-fields
-- The loops of Krastorio2-spaced-out (prototypes/balance/Krastorio2-spaced-out/loops.lua): the bio processing circuit, matter
-- from quartz, and the price of the greenhouse recipes of the decorations, on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_balance_kr_spaced_out_loops.lua
package.path = "./?.lua;./?/init.lua;" .. package.path
local support = require("tests.lua.loops_support")
local check = support.check
local loops = require("prototypes.balance.resource_loops")

local fix = require("prototypes.balance.Krastorio2-spaced-out.loops")

-- Both parts of the file: the loops that close at strict and the price of the decorations, which closes at closed.
local function run()
	fix.data_final_fixes()
	fix.decorations_data_final_fixes()
end

local function ingredient(name, amount, kind)
	return { type = kind or "item", name = name, amount = amount }
end

local function growing(result, ingredients, categories)
	return { name = result, categories = categories or { "kr-growing" }, ingredients = ingredients,
		results = { { type = "item", name = result, amount = 1 } } }
end

local function unlock(name)
	return { type = "unlock-recipe", recipe = name }
end

local function rock(drops)
	return { minable = { results = drops } }
end

-- The prototypes that are not recipes or technologies are put next to them.
local function fixture()
	local recipes = {
		["kr-bio-processing-circuit"] = { allow_productivity = true },
		["kr-kr-quartz-to-matter"] = { results = { { type = "fluid", name = "kr-matter", amount = 0.64 } } },
		-- prices: a plate costs 2 ore, steel 5 plates, a circuit a plate and 3 cables; a recipe of another name gives nothing
		["gold-plate"] = { ingredients = { ingredient("gold-ore", 2) }, results = { { type = "item", name = "gold-plate", amount = 1 } } },
		["steel-plate"] = { ingredients = { ingredient("iron-plate", 5) }, results = { { type = "item", name = "steel-plate", amount = 1 } } },
		["electronic-circuit"] = { ingredients = { ingredient("iron-plate", 1), ingredient("copper-cable", 3) },
			results = { { type = "item", name = "electronic-circuit", amount = 1 } } },
		-- half of the result of a recipe of the same name is not given: a plate costs two ore for one on average
		["silver-plate"] = { ingredients = { ingredient("silver-ore", 2) },
			results = { { type = "item", name = "silver-plate", amount = 2, independent_probability = 0.5 } } },
		-- one slot is free: the drop of tungsten comes in as it is
		["rock-a"] = growing("rock-a", { ingredient("coal", 50), ingredient("stone", 75) }),
		-- two slots are free, four valuable drops: the two dearest, and the amounts carry the price of the other two
		["rock-b"] = growing("rock-b", { ingredient("coal", 50), ingredient("stone", 75) }),
		-- a probability counts, a fluid in the recipe takes no slot
		["tree-c"] = growing("tree-c", { ingredient("wood", 40), ingredient("water", 100, "fluid") }),
		-- one slot is free, and the dearer drop wins it only if the probability of the recipe counts
		["rock-i"] = growing("rock-i", { ingredient("coal", 50), ingredient("stone", 75), ingredient("copper-plate", 5) }),
		-- the ingredient is there already: it takes more
		["rock-d"] = growing("rock-d", { ingredient("coal", 50), ingredient("stone", 75), ingredient("tungsten-ore", 20) }),
		-- no slot at all: the dearest ingredient covers the drops
		["rock-e"] = growing("rock-e", { ingredient("coal", 50), ingredient("stone", 75), ingredient("electronic-circuit", 5),
			ingredient("iron-plate", 2) }),
		-- no machine takes the category: no limit
		["rock-f"] = growing("rock-f", { ingredient("coal", 50) }, { "kr-nowhere" }),
		-- the entity has nothing to mine
		["rock-g"] = growing("rock-g", { ingredient("coal", 50) }),
		-- not a placed entity
		["not-placed"] = growing("not-placed", { ingredient("coal", 50) }),
		-- not unlocked by the decorations
		["rock-h"] = growing("rock-h", { ingredient("coal", 50) }),
	}
	local technologies = { ["kr-decorations"] = { effects = {
		unlock("rock-a"), unlock("rock-b"), unlock("tree-c"), unlock("rock-d"), unlock("rock-e"), unlock("rock-f"), unlock("rock-i"),
		unlock("rock-g"), unlock("not-placed"), { type = "nothing" }, unlock("missing") } } }

	return recipes, technologies
end

local function entities(raw)
	raw.item = { ["rock-a"] = { place_result = "rock-a-entity" } }
	raw["simple-entity"] = {
		["rock-a-entity"] = rock({ { type = "item", name = "tungsten-ore", amount_min = 10, amount_max = 20 },
			{ type = "item", name = "coal", amount = 30 }, { type = "item", name = "stone", amount = 10 } }),
		["rock-b"] = rock({ { type = "item", name = "gold-plate", amount = 5 }, { type = "item", name = "steel-plate", amount = 3 },
			{ type = "item", name = "tungsten-ore", amount = 4 }, { type = "item", name = "uranium-ore", amount = 2 } }),
		["rock-d"] = rock({ { type = "item", name = "tungsten-ore", amount = 20 } }),
		["rock-i"] = rock({ { type = "item", name = "silver-plate", amount = 3 }, { type = "item", name = "tungsten-ore", amount = 5 } }),
		["rock-e"] = rock({ { type = "item", name = "steel-plate", amount = 3 }, { type = "item", name = "gold-plate", amount = 5 } }),
		["rock-f"] = rock({ { type = "item", name = "steel-plate", amount = 2 }, { type = "item", name = "gold-plate", amount = 1 } }),
		["rock-g"] = { minable = nil },
		["rock-h"] = rock({ { type = "item", name = "steel-plate", amount = 3 } }),
	}
	-- the artificial tree: a result given as a single item, an independent probability, a fluid
	raw.tree = { ["tree-c"] = rock({ { type = "item", name = "steel-plate", amount = 1, independent_probability = 0.5 },
		{ type = "item", name = "wood", amount = 4 }, { type = "fluid", name = "crude-oil", amount = 100 } }) }
	raw["assembling-machine"] = {
		["kr-greenhouse"] = { crafting_categories = { "kr-growing" }, ingredient_count = 4 },
		["assembling-machine-3"] = { crafting_categories = { "crafting" } },
	}
end

local function names(recipe)
	local parts = {}
	for _, item in ipairs(recipe.ingredients) do
		parts[#parts + 1] = item.amount .. " " .. item.name
	end

	return table.concat(parts, ", ")
end

local raw = support.install(fixture())
entities(raw)
run()
local recipes = raw.recipe

-- 1. The circuit and the matter.
check(recipes["kr-bio-processing-circuit"].maximum_productivity == 0.5, "The bio circuit takes at most +50 %")
check(recipes["kr-kr-quartz-to-matter"].results[1].amount == 0.48, "Quartz gives 0.48 matter")
check(support.logged("kr-bio-processing-circuit takes at most +50 % productivity") == 1
	and support.logged("kr-kr-quartz-to-matter gives 0.48 matter") == 1, "A line for each")

-- 2. The decorations.
check(names(recipes["rock-a"]) == "50 coal, 75 stone, 40 tungsten-ore", "A free slot takes twice the most of the drop: " .. names(recipes["rock-a"]))
check(names(recipes["rock-b"]) == "50 coal, 75 stone, 8 steel-plate, 13 gold-plate",
	"Two slots go to the dearest drops, the amounts carry the rest: " .. names(recipes["rock-b"]))
check(names(recipes["tree-c"]) == "40 wood, 100 water, 1 steel-plate", "A probability counts and a fluid takes no slot: " .. names(recipes["tree-c"]))
check(names(recipes["rock-d"]) == "50 coal, 75 stone, 60 tungsten-ore", "An ingredient that is there takes more: " .. names(recipes["rock-d"]))
check(names(recipes["rock-e"]) == "50 coal, 75 stone, 18 electronic-circuit, 2 iron-plate",
	"Without a slot the dearest ingredient covers the drops: " .. names(recipes["rock-e"]))
check(names(recipes["rock-f"]) == "50 coal, 4 steel-plate, 2 gold-plate", "No limit, no left out drops: " .. names(recipes["rock-f"]))
check(names(recipes["rock-i"]) == "50 coal, 75 stone, 5 copper-plate, 11 silver-plate",
	"The probability of the recipe that sets the price counts: " .. names(recipes["rock-i"]))
check(names(recipes["rock-g"]) == "50 coal" and names(recipes["not-placed"]) == "50 coal" and names(recipes["rock-h"]) == "50 coal",
	"Recipes without a drop, without an entity, or outside the decorations are left alone")
check(recipes["tree-c"].ingredients[2].type == "fluid", "The fluid stays")

-- Every recipe a greenhouse crafts takes at most what it has slots for.
for _, name in ipairs({ "rock-a", "rock-b", "tree-c", "rock-d", "rock-e", "rock-i" }) do
	local items = 0
	for _, item in ipairs(recipes[name].ingredients) do
		if item.type == "item" then
			items = items + 1
		end
	end
	check(items <= 4, name .. " must stay craftable in a greenhouse, it takes " .. items .. " items")
end

check(support.logged("rock-b has no slot for the drops tungsten-ore, uranium-ore; it costs 50 coal, 75 stone, 8 steel-plate, 13 gold-plate") == 1
	and support.logged("rock-e has no slot for the drops steel-plate, gold-plate;") == 1, "The drops that lost the slots are logged")
check(support.logged("rock-i has no slot for the drops tungsten-ore; it costs 50 coal, 75 stone, 5 copper-plate, 11 silver-plate") == 1,
	"The drop that lost the slot of rock-i is logged")
check(support.logged("kr-decorations recipes that also cost twice their valuable drop: 7, of them with drops left out for lack of ingredient slots: 3") == 1,
	"The summary counts the recipes")
check(#support.logs == 6, "Six lines in all")
for _, line in ipairs(support.logs) do
	check(line:find("^razi%-protocol: "), "Every line has the prefix")
end

-- A probability that is not a field of 2.1 does not count.
raw = support.install({ ["rock-a"] = growing("rock-a", { ingredient("coal", 50) }) },
	{ ["kr-decorations"] = { effects = { unlock("rock-a") } } })
raw["simple-entity"] = { ["rock-a"] = rock({ { type = "item", name = "tungsten-ore", amount = 10, probability = 0.1 } }) }
run()
check(names(raw.recipe["rock-a"]) == "50 coal, 20 tungsten-ore", "The old probability is not read")

-- 3. What the authors changed stays: a lower cap, a matter that is no more than 0.48, a circuit without productivity.
recipes = fixture()
recipes["kr-bio-processing-circuit"].maximum_productivity = 0.25
recipes["kr-kr-quartz-to-matter"].results[1].amount = 0.4
raw = support.install(recipes, {})
run()
check(raw.recipe["kr-bio-processing-circuit"].maximum_productivity == 0.25 and raw.recipe["kr-kr-quartz-to-matter"].results[1].amount == 0.4
	and #support.logs == 1, "A lower cap and a lower amount stay; only the empty summary is logged")
recipes = fixture()
recipes["kr-bio-processing-circuit"].allow_productivity = false
raw = support.install(recipes, {})
run()
check(raw.recipe["kr-bio-processing-circuit"].maximum_productivity == nil, "A circuit without productivity needs no cap")
recipes = fixture()
recipes["kr-bio-processing-circuit"].maximum_productivity = 3
raw = support.install(recipes, {})
run()
check(raw.recipe["kr-bio-processing-circuit"].maximum_productivity == 0.5, "A higher cap goes down")

-- 4. Without the recipes, the technology or the machines nothing fails.
support.install({})
run()
raw = support.install({ ["rock-a"] = growing("rock-a", { ingredient("coal", 50) }) }, { ["kr-decorations"] = { effects = { unlock("rock-a") } } })
raw["simple-entity"] = { ["rock-a"] = rock({ { type = "item", name = "tungsten-ore", amount = 10 } }) }
run()
check(names(raw.recipe["rock-a"]) == "50 coal, 20 tungsten-ore", "Without machines there is no limit")
support.install({ ["rock-a"] = { results = {} } }, { ["kr-decorations"] = { effects = { unlock("rock-a") } } })
run()

-- Through the level: open and closed leave the circuit and the matter, strict closes them.
support.gate(loops, function()
	local recipes = fixture()
	return { ["kr-bio-processing-circuit"] = recipes["kr-bio-processing-circuit"],
		["kr-kr-quartz-to-matter"] = recipes["kr-kr-quartz-to-matter"] }
end, function(data_raw)
	return data_raw.recipe["kr-kr-quartz-to-matter"].results[1].amount == 0.48
		and data_raw.recipe["kr-bio-processing-circuit"].maximum_productivity == 0.5
end, "strict")

-- Planting and mining a decoration needs no productivity: open leaves the recipes, closed and strict price them.
support.gate(loops, function()
	local recipes = { ["rock-d"] = growing("rock-d", { ingredient("coal", 50), ingredient("stone", 75), ingredient("tungsten-ore", 20) }) }
	local technologies = { ["kr-decorations"] = { effects = { unlock("rock-d") } } }
	return recipes, technologies, { ["simple-entity"] = { ["rock-d"] = rock({ { type = "item", name = "tungsten-ore", amount = 20 } }) } }
end, function(data_raw)
	return names(data_raw.recipe["rock-d"]) == "50 coal, 75 stone, 60 tungsten-ore"
end)

print("test_balance_kr_spaced_out_loops: ok")
