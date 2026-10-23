---@diagnostic disable: missing-fields, assign-type-mismatch, need-check-nil, inject-field, undefined-field
-- Razi Rocket Reusability in the pack (compat/rocket_salvage.lua) on a mocked data.raw: the three bulk salvage tiers copy the
-- final rocket-chunk-processing outputs, scale them by the batch and add the handling bonus to the first non-chunk product;
-- every missing prototype skips its tier instead of failing, a second run adds nothing, and every created recipe and
-- technology has its English and Russian locale lines. The fixture's native time (3 s) and research time (45 s) differ from
-- the module's fallbacks (2 s, 60 s), so the test sees both being copied rather than defaulted.
-- Run from the mod root:
--   lua5.2 tests/lua/test_rocket_salvage.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

-- Factorio's table.deepcopy (util) is not available outside the game
local function clone(value)
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for key, entry in pairs(value) do
		copy[clone(key)] = clone(entry)
	end
	return copy
end
rawset(table, "deepcopy", clone)

local PACKS = {{"automation-science-pack", 1}, {"logistic-science-pack", 1}, {"chemical-science-pack", 1},
	{"production-science-pack", 1}, {"utility-science-pack", 1}, {"space-science-pack", 1}}

local function technology(name)
	return {type = "technology", name = name, prerequisites = {}}
end

-- The native recipe as razi-rocket-reusability 1.1.9 leaves it with Krastorio 2 Spaced Out (compatibility/k2so.lua): incomplete
-- rocket parts in a range, a chunk back with a 10% chance, both crushing categories.
local function native_recipe()
	return {type = "recipe", name = "rocket-chunk-processing",
		icon = "__razi-rocket-reusability__/graphics/icons/rocket-chunk-crushing.png",
		categories = {"crushing", "kr-crushing"}, subgroup = "space-crushing", order = "b-a-d", auto_recycle = false, enabled = false,
		ingredients = {{type = "item", name = "rocket-chunk", amount = 1}}, energy_required = 3,
		results = {
			{type = "item", name = "incomplete-rocket-part", amount_min = 3, amount_max = 10},
			{type = "item", name = "rocket-chunk", amount = 1, independent_probability = 0.1},
		},
		allow_productivity = true, allow_decomposition = false}
end

local logged = {}

local function setup(options)
	options = options or {}
	local data_raw = {
		item = {},
		recipe = {["rocket-chunk-processing"] = native_recipe()},
		technology = {
			["remnant-beacon"] = {type = "technology", name = "remnant-beacon", prerequisites = {"rocket-chunk-processing"},
				unit = {count = 1000, ingredients = clone(PACKS), time = 45}},
			["planet-discovery-fulgora"] = technology("planet-discovery-fulgora"),
			["planet-discovery-aquilo"] = technology("planet-discovery-aquilo"),
			["razi-network-precision-matrix"] = technology("razi-network-precision-matrix"),
			["interplanetary-trade-logistics"] = technology("interplanetary-trade-logistics"),
		},
	}
	-- As in the dump: the assembler crusher serves crushing and kr-crushing, Krastorio's kr-crusher is a furnace with one source slot
	-- (kr-crushing and kr-void-crushing), and the rigor-module crusher serves only kr-crushing and its own category
	data_raw["assembling-machine"] = {
		crusher = {type = "assembling-machine", name = "crusher", crafting_categories = {"crushing", "kr-crushing"}},
		["kr-crusher__rigor-module"] = {type = "assembling-machine", name = "kr-crusher__rigor-module",
			crafting_categories = {"kr-crushing", "kr-crushing__rigor_module_mod"}},
	}
	data_raw.furnace = {["kr-crusher"] = {type = "furnace", name = "kr-crusher", crafting_categories = {"kr-crushing", "kr-void-crushing"},
		source_inventory_size = 1}}
	for _, name in ipairs({"rocket-chunk", "holmium-plate", "ice", "processing-unit", "razi-network-precision-matrix"}) do
		data_raw.item[name] = {type = "item", name = name}
	end
	if options.adjust then
		options.adjust(data_raw)
	end
	local extended = {}
	rawset(_G, "data", {raw = data_raw, extend = function(self, prototypes)
		for _, prototype in ipairs(prototypes) do
			self.raw[prototype.type] = self.raw[prototype.type] or {}
			check(not self.raw[prototype.type][prototype.name], "extended twice: " .. prototype.type .. " " .. prototype.name)
			self.raw[prototype.type][prototype.name] = prototype
			extended[#extended + 1] = prototype.type .. ":" .. prototype.name
		end
	end})
	rawset(_G, "log", function(message) logged[#logged + 1] = message end)
	rawset(_G, "mods", options.mods or {["razi-rocket-reusability"] = "1.1.9"})
	package.loaded["prototypes.compat.rocket_salvage"] = nil
	return data_raw, require("prototypes.compat.rocket_salvage"), extended
end

local function near(value, expected)
	return type(value) == "number" and math.abs(value - expected) < 1e-9
end

local function result_list(recipe)
	local out = {}
	for _, result in ipairs(recipe.results) do
		local amount = result.amount and tostring(result.amount) or (result.amount_min .. ".." .. result.amount_max)
		out[#out + 1] = result.name .. "=" .. amount .. (result.independent_probability and ("@" .. result.independent_probability) or "")
	end
	return table.concat(out, ",")
end

local function ingredient_list(recipe)
	local out = {}
	for _, ingredient in ipairs(recipe.ingredients) do
		out[#out + 1] = ingredient.name .. "=" .. ingredient.amount
	end
	return table.concat(out, ",")
end

local function pack_list(unit)
	local out = {}
	for _, pack in ipairs(unit.ingredients) do
		out[#out + 1] = (pack.name or pack[1]) .. "x" .. (pack.amount or pack[2])
	end
	return table.concat(out, ",")
end

local function names(list)
	return table.concat(list, " ")
end

-- the three tiers with the full pack: outputs = native x batch, +bonus on the first non-chunk product, time = native (3 s) x
-- batch x factor
local TIERS = {
	{name = "razi-rocket-salvage-precision", results = "incomplete-rocket-part=10..31,rocket-chunk=3@0.1", time = 7.65, count = 550, batches = 3, bonus = 1,
		ingredients = "rocket-chunk=3,holmium-plate=1", prerequisites = "remnant-beacon,planet-discovery-fulgora", order = "a"},
	{name = "razi-rocket-salvage-cryogenic", results = "incomplete-rocket-part=13..41,rocket-chunk=4@0.1", time = 9, count = 900, batches = 4, bonus = 1,
		ingredients = "rocket-chunk=4,ice=15,processing-unit=2", prerequisites = "razi-rocket-salvage-precision,planet-discovery-aquilo",
		order = "b"},
	{name = "razi-rocket-salvage-network", results = "incomplete-rocket-part=20..62,rocket-chunk=6@0.1", time = 12.6, count = 1500, batches = 6, bonus = 2,
		ingredients = "rocket-chunk=6,razi-network-precision-matrix=1",
		prerequisites = "razi-rocket-salvage-cryogenic,razi-network-precision-matrix,interplanetary-trade-logistics", order = "c"},
}

local data_raw, module, extended = setup()
module.data_final_fixes()
check(#extended == 6, "prototypes added with the full pack: " .. names(extended))
local beacon = data_raw.technology["remnant-beacon"]
local native = data_raw.recipe["rocket-chunk-processing"]
for _, tier in ipairs(TIERS) do
	local recipe = data_raw.recipe[tier.name .. "-processing"]
	local tech = data_raw.technology[tier.name]
	check(recipe and tech, tier.name .. " missing")
	check(result_list(recipe) == tier.results, tier.name .. " results: " .. result_list(recipe))
	check(ingredient_list(recipe) == tier.ingredients, tier.name .. " ingredients: " .. ingredient_list(recipe))
	check(near(recipe.energy_required, tier.time), tier.name .. " time: " .. tostring(recipe.energy_required))
	check(recipe.allow_productivity == false, tier.name .. " allows productivity")
	check(recipe.auto_recycle == false and recipe.enabled == false, tier.name .. " recycles or starts enabled")
	-- kr-crushing is served only by single-slot furnaces, which cannot make a multi-ingredient recipe, so the copies lose it
	check(table.concat(recipe.categories, ",") == "crushing", tier.name .. " categories: " .. table.concat(recipe.categories, ","))
	check(table.concat(native.categories, ",") == "crushing,kr-crushing", "the native categories changed")
	check(recipe.subgroup == "space-crushing" and recipe.order == "z[razi-salvage]-" .. tier.order, tier.name .. " menu placement")
	check(recipe.localised_name[1] == "recipe-name." .. recipe.name
		and recipe.localised_description[1] == "recipe-description." .. recipe.name, tier.name .. " locale keys")
	check(table.concat(tech.prerequisites, ",") == tier.prerequisites, tier.name .. " prerequisites: " .. table.concat(tech.prerequisites, ","))
	check(#tech.effects == 1 and tech.effects[1].type == "unlock-recipe" and tech.effects[1].recipe == recipe.name,
		tier.name .. " does not unlock its recipe")
	check(tech.unit.count == tier.count and tech.unit.time == 45, tier.name .. " price: " .. tech.unit.count .. " x " .. tech.unit.time .. "s")
	check(pack_list(tech.unit) == pack_list(beacon.unit), tier.name .. " packs differ from the beacon: " .. pack_list(tech.unit))
	check(tech.unit.ingredients ~= beacon.unit.ingredients and recipe.results ~= native.results
		and recipe.categories ~= native.categories and recipe.ingredients ~= native.ingredients, tier.name .. " shares tables")
	check(tech.icon == "__razi-rocket-reusability__/graphics/icons/rocket-reusability-research.png" and tech.icon_size == 190,
		tier.name .. " icon")
	check(tech.order == "z[razi-salvage]-" .. tier.order, tier.name .. " order")
end
-- the native recipe and the beacon technology are left alone
check(result_list(native) == "incomplete-rocket-part=3..10,rocket-chunk=1@0.1" and native.allow_productivity == true
	and native.energy_required == 3, "native recipe changed: " .. result_list(native))
check(pack_list(beacon.unit) == "automation-science-packx1,logistic-science-packx1,chemical-science-packx1,production-science-packx1,"
	.. "utility-science-packx1,space-science-packx1" and beacon.unit.count == 1000, "beacon technology changed")

-- a second run adds nothing (the extend mock fails on a duplicate)
module.data_final_fixes()
check(#extended == 6, "second run added prototypes: " .. names(extended))

-- the module's own tier tables are copied, not handed out: editing a created recipe does not leak into the next run of the same
-- module instance on a fresh data.raw
data_raw.recipe["razi-rocket-salvage-precision-processing"].ingredients[1].amount = 99
data_raw.technology["razi-rocket-salvage-precision"].prerequisites[1] = "edited"
setup()
local second_raw = data.raw
module.data_final_fixes()
check(ingredient_list(second_raw.recipe["razi-rocket-salvage-precision-processing"]) == "rocket-chunk=3,holmium-plate=1",
	"tier ingredients leaked between runs")
check(second_raw.technology["razi-rocket-salvage-precision"].prerequisites[1] == "remnant-beacon", "tier prerequisites leaked between runs")

-- the categories follow the machines: a furnace with enough source slots keeps its category, one with too few loses it, and
-- without any machine data the list is left alone
local function categories_of(raw, name)
	return table.concat(raw.recipe["razi-rocket-salvage-" .. name .. "-processing"].categories, ",")
end
data_raw, module = setup({adjust = function(raw) raw.furnace["kr-crusher"].source_inventory_size = 2 end})
module.data_final_fixes()
check(categories_of(data_raw, "precision") == "crushing,kr-crushing" and categories_of(data_raw, "network") == "crushing,kr-crushing",
	"two-slot furnace should keep the two-ingredient tiers: " .. categories_of(data_raw, "precision"))
check(categories_of(data_raw, "cryogenic") == "crushing", "two-slot furnace cannot make the three-ingredient tier")
data_raw, module = setup({adjust = function(raw) raw.furnace["kr-crusher"].source_inventory_size = 3 end})
module.data_final_fixes()
check(categories_of(data_raw, "cryogenic") == "crushing,kr-crushing", "three-slot furnace should keep every category")
data_raw, module = setup({adjust = function(raw) raw.furnace = nil; raw["assembling-machine"] = nil end})
module.data_final_fixes()
check(categories_of(data_raw, "precision") == "crushing,kr-crushing", "no machine data should leave the categories alone")
-- a category is dropped only while another one stays: native kr-crushing alone, or two categories both served by the one-slot furnace
data_raw, module = setup({adjust = function(raw) raw.recipe["rocket-chunk-processing"].categories = {"kr-crushing"} end})
module.data_final_fixes()
check(categories_of(data_raw, "precision") == "kr-crushing", "a single kr-crushing category must stay: " .. categories_of(data_raw, "precision"))
data_raw, module = setup({adjust = function(raw)
	raw.recipe["rocket-chunk-processing"].categories = {"kr-crushing", "kr-void-crushing"}
end})
module.data_final_fixes()
check(categories_of(data_raw, "cryogenic") == "kr-crushing,kr-void-crushing", "no category may be left empty: " .. categories_of(data_raw, "cryogenic"))
-- the filter looks at furnaces only
data_raw, module = setup({adjust = function(raw) raw.furnace = nil end})
module.data_final_fixes()
check(categories_of(data_raw, "precision") == "crushing,kr-crushing", "without furnaces both categories stay: " .. categories_of(data_raw, "precision"))
logged = {}
module = select(2, setup())
module.data_final_fixes()
check(#logged == 3 and logged[1]:find("razi-rocket-salvage-precision-processing", 1, true) and logged[1]:find("keeping crushing", 1, true),
	"each dropped category list is logged once per recipe: " .. table.concat(logged, " | "))

-- without the mod nothing happens
local _
_, module, extended = setup({mods = {}})
module.data_final_fixes()
check(#extended == 0, "added without the mod: " .. names(extended))

-- without Planet Express' trade research: precision and cryogenic only
_, module, extended = setup({adjust = function(raw) raw.technology["interplanetary-trade-logistics"] = nil end})
module.data_final_fixes()
check(names(extended) == "recipe:razi-rocket-salvage-precision-processing technology:razi-rocket-salvage-precision "
	.. "recipe:razi-rocket-salvage-cryogenic-processing technology:razi-rocket-salvage-cryogenic", "without trade research: " .. names(extended))

-- with the interdependence setting off (no matrix research) or without the matrix item: precision and cryogenic only
for label, adjust in pairs({
	["without the matrix research"] = function(raw) raw.technology["razi-network-precision-matrix"] = nil end,
	["without the matrix item"] = function(raw) raw.item["razi-network-precision-matrix"] = nil end,
}) do
	_, module, extended = setup({adjust = adjust})
	module.data_final_fixes()
	check(names(extended) == "recipe:razi-rocket-salvage-precision-processing technology:razi-rocket-salvage-precision "
		.. "recipe:razi-rocket-salvage-cryogenic-processing technology:razi-rocket-salvage-cryogenic", label .. ": " .. names(extended))
end

-- a missing ice item or processing unit skips the cryogenic tier and, with it, the network tier; precision stays
for _, item in ipairs({"ice", "processing-unit"}) do
	_, module, extended = setup({adjust = function(raw) raw.item[item] = nil end})
	module.data_final_fixes()
	check(names(extended) == "recipe:razi-rocket-salvage-precision-processing technology:razi-rocket-salvage-precision",
		"without " .. item .. ": " .. names(extended))
end

-- a tier whose recipe or technology name is already taken is skipped without an error. A taken recipe also leaves the tier's
-- technology missing, so the tiers that need it are skipped; a taken technology name is a usable prerequisite, so they stay.
_, module, extended = setup({adjust = function(raw)
	raw.recipe["razi-rocket-salvage-precision-processing"] = {type = "recipe", name = "razi-rocket-salvage-precision-processing"}
end})
module.data_final_fixes()
check(#extended == 0, "recipe name taken: " .. names(extended))
_, module, extended = setup({adjust = function(raw)
	raw.technology["razi-rocket-salvage-precision"] = technology("razi-rocket-salvage-precision")
end})
module.data_final_fixes()
check(names(extended) == "recipe:razi-rocket-salvage-cryogenic-processing technology:razi-rocket-salvage-cryogenic "
	.. "recipe:razi-rocket-salvage-network-processing technology:razi-rocket-salvage-network", "technology name taken: " .. names(extended))

-- a hidden or disabled gate stops its tier and the tiers after it
for _, flag in ipairs({"hidden", "enabled"}) do
	_, module, extended = setup({adjust = function(raw)
		raw.technology["planet-discovery-aquilo"][flag] = flag == "hidden"
	end})
	module.data_final_fixes()
	check(names(extended) == "recipe:razi-rocket-salvage-precision-processing technology:razi-rocket-salvage-precision",
		"aquilo " .. flag .. ": " .. names(extended))
end

-- every missing piece of the native chain stops everything
local function nothing_when(label, adjust)
	_, module, extended = setup({adjust = adjust})
	module.data_final_fixes()
	check(#extended == 0, label .. ": " .. names(extended))
end
nothing_when("without remnant-beacon", function(raw) raw.technology["remnant-beacon"] = nil end)
nothing_when("without rocket-chunk-processing", function(raw) raw.recipe["rocket-chunk-processing"] = nil end)
nothing_when("native without results", function(raw) raw.recipe["rocket-chunk-processing"].results = nil end)
nothing_when("native with only the chunk back", function(raw)
	raw.recipe["rocket-chunk-processing"].results = {{type = "item", name = "rocket-chunk", amount = 1, independent_probability = 0.1}}
end)
nothing_when("beacon without unit", function(raw) raw.technology["remnant-beacon"].unit = nil end)
nothing_when("beacon unit without ingredients", function(raw) raw.technology["remnant-beacon"].unit.ingredients = nil end)
nothing_when("without the Fulgora gate", function(raw) raw.technology["planet-discovery-fulgora"] = nil end)
nothing_when("without the rocket chunk item", function(raw) raw.item["rocket-chunk"] = nil end)
nothing_when("without holmium (precision skipped, the later tiers need it)", function(raw) raw.item["holmium-plate"] = nil end)

-- without Krastorio: fixed amounts; the bonus goes to the first non-chunk item only, fluids are scaled but never get it
data_raw, module, extended = setup({adjust = function(raw)
	local recipe = raw.recipe["rocket-chunk-processing"]
	recipe.category = "crushing"
	recipe.categories = nil
	recipe.energy_required = nil
	recipe.results = {
		{type = "fluid", name = "steam", amount = 10},
		{type = "item", name = "processing-unit", amount = 5},
		{type = "item", name = "low-density-structure", amount = 5},
		{type = "item", name = "rocket-chunk", amount = 1, independent_probability = 0.1},
	}
	raw.technology["remnant-beacon"].unit.time = nil
end})
module.data_final_fixes()
local precision = data_raw.recipe["razi-rocket-salvage-precision-processing"]
check(precision and result_list(precision) == "steam=30,processing-unit=16,low-density-structure=15,rocket-chunk=3@0.1",
	"fixed amounts: " .. (precision and result_list(precision) or "missing"))
check(precision.category == "crushing" and precision.categories == nil, "single category not kept")
-- the module's own fallback stands in for the missing native time (the game's default would be 0.5 s); only the floor is
-- pinned, so the fallback may change without touching this test
check(type(precision.energy_required) == "number" and precision.energy_required >= 1,
	"no usable time without a native energy_required: " .. tostring(precision.energy_required))
check(data_raw.technology["razi-rocket-salvage-precision"].unit.time == 60, "default research time not 60")

-- a native recipe that starts enabled, recycles and is quick: every copy is disabled, never recycled and never faster than
-- one second (0.2 s x 3 x 0.85 = 0.51 s, floored)
data_raw, module, extended = setup({adjust = function(raw)
	local recipe = raw.recipe["rocket-chunk-processing"]
	recipe.enabled = true
	recipe.auto_recycle = nil
	recipe.energy_required = 0.2
end})
module.data_final_fixes()
check(#extended == 6, "quick native recipe: " .. names(extended))
for _, tier in ipairs(TIERS) do
	local recipe = data_raw.recipe[tier.name .. "-processing"]
	check(recipe.enabled == false and recipe.auto_recycle == false, tier.name .. " keeps enabled or auto_recycle from the native recipe")
	check(recipe.energy_required == 1, tier.name .. " time below the one second floor: " .. tostring(recipe.energy_required))
end

-- a pack without technologies, recipes or items does not fail
rawset(_G, "mods", {["razi-rocket-reusability"] = "1.1.9"})
rawset(_G, "data", {raw = {}, extend = function() error("extended on an empty pack") end})
package.loaded["prototypes.compat.rocket_salvage"] = nil
require("prototypes.compat.rocket_salvage").data_final_fixes()

-- It runs after the last pass that edits recipes and technology prices (Lithium Battery), before the menu pass.
local file = assert(io.open("data-final-fixes.lua", "r"))
local source = file:read("*a")
file:close()
local lithium = assert(source:find('require("prototypes.compat.lithium_battery").data_final_fixes()', 1, true))
local own = assert(source:find('require("prototypes.compat.rocket_salvage").data_final_fixes()', 1, true))
local navigation = assert(source:find('require("prototypes.compat.crafting_navigation").data_final_fixes()', 1, true))
check(lithium < own and own < navigation, "the pass runs late, after Lithium Battery and before the menu pass")

-- Every created recipe and technology has a name and a description in both languages, and the two files list the same keys
-- (the recipes set localised_name/localised_description to these keys, the technologies use the default ones).
local function locale_sections(lang)
	local cfg = assert(io.open("locale/" .. lang .. "/salvage.cfg", "r"))
	local text = cfg:read("*a")
	cfg:close()
	local sections, current = {}, nil
	for line in text:gmatch("[^\n]+") do
		local header = line:match("^%[(.-)%]$")
		if header then
			current = {}
			sections[header] = current
		else
			local key, value = line:match("^([^=]+)=(.+)$")
			check(current and key and value, lang .. " salvage.cfg: unexpected line: " .. line)
			current[key] = value
		end
	end
	return sections
end

local locales = {en = locale_sections("en"), ru = locale_sections("ru")}
for lang, sections in pairs(locales) do
	for _, tier in ipairs(TIERS) do
		for section, key in pairs({["recipe-name"] = tier.name .. "-processing", ["recipe-description"] = tier.name .. "-processing",
			["technology-name"] = tier.name, ["technology-description"] = tier.name}) do
			check(sections[section] and sections[section][key], "no " .. lang .. " " .. section .. " for " .. key)
		end
	end
	local other = locales[lang == "en" and "ru" or "en"]
	for section, keys in pairs(sections) do
		for key in pairs(keys) do
			check(other[section] and other[section][key], lang .. " " .. section .. "." .. key .. " has no counterpart")
		end
	end
end

-- The recipe descriptions spell the numbers out, so they are checked against the tiers: the numbers in the text, in order, must be
-- the ingredient amounts (Russian leaves an amount of one implied), the batches, the bonus and the percent faster.
local NUMBERS = {
	en = {one = 1, two = 2, three = 3, four = 4, six = 6, fifteen = 15},
	ru = {["одна"] = 1, ["одну"] = 1, ["две"] = 2, ["два"] = 2, ["три"] = 3, ["Три"] = 3, ["четыре"] = 4, ["Четыре"] = 4, ["шесть"] = 6,
		["Шесть"] = 6, ["пятнадцать"] = 15},
}
local function numbers_in(lang, text)
	local found = {}
	for word in text:gmatch("[^%s%p]+") do
		local number = tonumber(word) or NUMBERS[lang][lang == "en" and word:lower() or word]
		if number then
			found[#found + 1] = number
		end
	end
	return table.concat(found, ",")
end
for lang, sections in pairs(locales) do
	for _, tier in ipairs(TIERS) do
		local expected = {}
		expected[#expected + 1] = tier.batches
		expected[#expected + 1] = tier.bonus
		expected[#expected + 1] = math.floor((1 - tier.time / (3 * tier.batches)) * 100 + 0.5)
		local description = sections["recipe-description"][tier.name .. "-processing"]
		check(numbers_in(lang, description) == table.concat(expected, ","), lang .. " " .. tier.name .. " description numbers: "
			.. numbers_in(lang, description) .. " instead of " .. table.concat(expected, ","))
	end
end

print("rocket salvage: ok")
