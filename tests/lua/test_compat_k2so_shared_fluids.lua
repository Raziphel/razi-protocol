---@diagnostic disable: missing-fields, need-check-nil, inject-field, undefined-field
-- Muria's hydrogen chloride becomes K2's in every recipe, the acid thrower and fluid boxes; the retired fluid and
-- K2SO's hidden chlorine lose their barrels, flare, outlet, void and burn recipes and those unlocks.
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

local compat = require("prototypes.compatibility.Krastorio2-spaced-out.shared_fluids")

local function fluid(name, amount)
	return {type = "fluid", name = name, amount = amount or 10}
end

local function item(name, amount)
	return {type = "item", name = name, amount = amount or 1}
end

local function recipe(name, ingredients, results, extra)
	local prototype = {type = "recipe", name = name, ingredients = ingredients, results = results}
	for key, value in pairs(extra or {}) do
		prototype[key] = value
	end
	return prototype
end

-- The pack after K2SO's final fixes: chlorine is already kr-chlorine and hidden, hydrogen chloride exists twice.
local function world(installed)
	logs = {}
	rawset(_G, "mods", installed or {Muria = "1.11.5", Krastorio2 = "2.1.4", ["Krastorio2-spaced-out"] = "2.0.19"})
	local raw = {
		fluid = {
			["hydrogen-chloride"] = {name = "hydrogen-chloride"},
			["kr-hydrogen-chloride"] = {name = "kr-hydrogen-chloride"},
			chlorine = {name = "chlorine", hidden = true, hidden_in_factoriopedia = true},
			["kr-chlorine"] = {name = "kr-chlorine"},
			water = {name = "water"},
		},
		item = {
			["hydrogen-chloride-barrel"] = {name = "hydrogen-chloride-barrel"},
			["hydrogen-chloride-titanium-barrel"] = {name = "hydrogen-chloride-titanium-barrel"},
			["kr-hydrogen-chloride-barrel"] = {name = "kr-hydrogen-chloride-barrel"},
			barrel = {name = "barrel"},
			lead = {name = "lead"},
		},
		recipe = {
			["hydrogen-chloride"] = recipe("hydrogen-chloride", {fluid("kr-chlorine"), fluid("water")},
				{fluid("hydrogen-chloride", 20)}, {main_product = "hydrogen-chloride"}),
			["casting-lead"] = recipe("casting-lead", {fluid("hydrogen-chloride"), item("lead")}, {item("lead", 2)}),
			["kr-lithium-chloride"] = recipe("kr-lithium-chloride", {fluid("kr-hydrogen-chloride")}, {item("lead")}),
			["hydrogen-chloride-barrel"] = recipe("hydrogen-chloride-barrel", {fluid("hydrogen-chloride", 50), item("barrel")},
				{item("hydrogen-chloride-barrel")}),
			["empty-hydrogen-chloride-barrel"] = recipe("empty-hydrogen-chloride-barrel", {item("hydrogen-chloride-barrel")},
				{fluid("hydrogen-chloride", 50), item("barrel")}),
			["hydrogen-chloride-titanium-barrel-recycling"] = recipe("hydrogen-chloride-titanium-barrel-recycling",
				{item("hydrogen-chloride-titanium-barrel")}, {item("barrel")}),
			["kr-hydrogen-chloride-barrel"] = recipe("kr-hydrogen-chloride-barrel",
				{fluid("kr-hydrogen-chloride", 50), item("barrel")}, {item("kr-hydrogen-chloride-barrel")}),
			["hydrogen-chloride-flaring"] = recipe("hydrogen-chloride-flaring", {fluid("hydrogen-chloride")}, {}),
			["kr-burn-hydrogen-chloride"] = recipe("kr-burn-hydrogen-chloride", {fluid("hydrogen-chloride")}, {}),
			["maraxsis-fluid-void-hydrogen-chloride"] = recipe("maraxsis-fluid-void-hydrogen-chloride",
				{fluid("hydrogen-chloride")}, {}),
			["kr-hydrogen-chloride-flaring"] = recipe("kr-hydrogen-chloride-flaring", {fluid("kr-hydrogen-chloride")}, {}),
			["chlorine-flaring"] = recipe("chlorine-flaring", {fluid("chlorine")}, {}, {hidden_in_factoriopedia = true}),
			["chlorine-outlet"] = recipe("chlorine-outlet", {fluid("chlorine")}, {}),
		},
		technology = {
			acidworking = {name = "acidworking", effects = {
				{type = "unlock-recipe", recipe = "hydrogen-chloride"},
				{type = "unlock-recipe", recipe = "hydrogen-chloride-barrel"},
				{type = "unlock-recipe", recipe = "empty-hydrogen-chloride-barrel"},
			}},
			["acid-trigger"] = {name = "acid-trigger", research_trigger = {type = "craft-fluid", fluid = "hydrogen-chloride"}},
		},
		["fluid-turret"] = {
			["acidthrower-turret"] = {name = "acidthrower-turret", attack_parameters = {fluids = {
				{type = "hydrogen-chloride"}, {type = "sulfuric-acid"},
			}}},
		},
		["storage-tank"] = {
			["acid-tank"] = {name = "acid-tank", fluid_box = {filter = "hydrogen-chloride"}},
		},
		["assembling-machine"] = {
			["acid-plant"] = {name = "acid-plant", fluid_boxes = {{filter = "hydrogen-chloride"}, {filter = "water"}}},
		},
	}
	rawset(_G, "data", {raw = raw})
	return raw
end

local function names(entries)
	local list = {}
	for _, entry in ipairs(entries) do
		list[#list + 1] = entry.name
	end
	return table.concat(list, ",")
end

local function unlocks(technology)
	local list = {}
	for _, effect in ipairs(technology.effects) do
		list[#list + 1] = effect.recipe
	end
	return table.concat(list, ",")
end

local raw = world()
compat.data_final_fixes()

-- Every chain takes K2's fluid.
check(names(raw.recipe["hydrogen-chloride"].results) == "kr-hydrogen-chloride", "Muria's recipe makes K2's fluid")
check(raw.recipe["hydrogen-chloride"].main_product == "kr-hydrogen-chloride", "and names it as the main product")
check(names(raw.recipe["casting-lead"].ingredients) == "kr-hydrogen-chloride,lead", "Muria's consumers take K2's fluid")
check(names(raw.recipe["kr-lithium-chloride"].ingredients) == "kr-hydrogen-chloride", "K2's consumers stay as they are")
check(raw["fluid-turret"]["acidthrower-turret"].attack_parameters.fluids[1].type == "kr-hydrogen-chloride",
	"the acid thrower fires K2's fluid")
check(raw["fluid-turret"]["acidthrower-turret"].attack_parameters.fluids[2].type == "sulfuric-acid",
	"the other ammo of the acid thrower stays")
check(raw["storage-tank"]["acid-tank"].fluid_box.filter == "kr-hydrogen-chloride", "a fluid box filter follows")
check(raw["assembling-machine"]["acid-plant"].fluid_boxes[1].filter == "kr-hydrogen-chloride", "fluid_boxes follow")
check(raw["assembling-machine"]["acid-plant"].fluid_boxes[2].filter == "water", "other filters stay")
check(raw.technology["acid-trigger"].research_trigger.fluid == "kr-hydrogen-chloride", "the research trigger follows")

-- Muria's fluid and what exists only for it are hidden, not renamed into second K2 barrels.
check(raw.fluid["hydrogen-chloride"].hidden and raw.fluid["hydrogen-chloride"].hidden_in_factoriopedia,
	"Muria's fluid is hidden")
check(not raw.fluid["kr-hydrogen-chloride"].hidden, "K2's fluid stays visible")
for _, name in ipairs({"hydrogen-chloride-barrel", "empty-hydrogen-chloride-barrel",
	"hydrogen-chloride-titanium-barrel-recycling", "hydrogen-chloride-flaring", "kr-burn-hydrogen-chloride",
	"maraxsis-fluid-void-hydrogen-chloride"}) do
	check(raw.recipe[name].hidden and raw.recipe[name].hidden_in_factoriopedia, name .. " is hidden")
end
check(names(raw.recipe["hydrogen-chloride-barrel"].ingredients) == "hydrogen-chloride,barrel",
	"the retired barrel is not turned into a second K2 barrel")
check(raw.item["hydrogen-chloride-barrel"].hidden and raw.item["hydrogen-chloride-titanium-barrel"].hidden,
	"the retired barrels are hidden")
check(not raw.item["kr-hydrogen-chloride-barrel"].hidden, "K2's barrel stays")
check(not raw.recipe["kr-hydrogen-chloride-barrel"].hidden and not raw.recipe["kr-hydrogen-chloride-flaring"].hidden,
	"K2's barrel and flare recipes stay")
check(unlocks(raw.technology.acidworking) == "hydrogen-chloride", "acidworking no longer unlocks the retired barrels")

-- K2SO's hidden chlorine loses its leftover recipes too.
check(raw.recipe["chlorine-flaring"].hidden and raw.recipe["chlorine-outlet"].hidden, "chlorine's leftovers are hidden")

check(#logs == 3, "every change is logged, got " .. #logs)

-- Without Muria's fluid nothing is renamed, and without K2SO no leftovers are touched.
raw = world({Krastorio2 = "2.1.4"})
raw.fluid["hydrogen-chloride"] = nil
compat.data_final_fixes()
check(names(raw.recipe["casting-lead"].ingredients) == "hydrogen-chloride,lead", "nothing is renamed without both fluids")
check(not raw.recipe["chlorine-flaring"].hidden, "without K2SO the chlorine recipes stay")
check(#logs == 0, "nothing is logged when nothing changes, got " .. #logs)

-- A retired fluid that some visible recipe still makes keeps its barrels and flare recipes.
raw = world()
raw.recipe["chlorine-from-salt"] = recipe("chlorine-from-salt", {item("lead")}, {fluid("chlorine")})
compat.data_final_fixes()
check(not raw.recipe["chlorine-flaring"].hidden, "chlorine still made by a recipe keeps its flare recipe")

print("shared fluids: ok")
