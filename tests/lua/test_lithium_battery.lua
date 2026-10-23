---@diagnostic disable: missing-fields, assign-type-mismatch, need-check-nil
-- Lithium Battery in the pack (compat/lithium_battery.lua) on a mocked data.raw: the productivity effects of the recipe copies it
-- deletes (7.5.0 and older) are taken out of Planet Crucible's technologies, and equal ingredients of the research data recipes and
-- of the copies it keeps (7.5.1), which share one list with them, are added up.
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

local function productivity(recipe)
	return {type = "change-recipe-productivity", recipe = recipe, change = 0.1}
end

local function setup(mod_list)
	local data_raw = {
		recipe = {
			["cryogenic-science-pack"] = {type = "recipe", name = "cryogenic-science-pack"},
			["promethium-science-pack"] = {type = "recipe", name = "promethium-science-pack"},
		},
		technology = {
			-- Planet Crucible: the real recipe and the deleted clone
			["planet-crucible-cryogenic-science-pack-productivity"] = {type = "technology",
				effects = {productivity("cryogenic-science-pack"), productivity("cryogenic-science-pack-clone")}},
			["planet-crucible-promethium-science-pack-productivity"] = {type = "technology",
				effects = {productivity("promethium-science-pack-clone"), productivity("promethium-science-pack")}},
			-- other effects of a missing recipe are not productivity and stay
			["unlock-of-missing"] = {type = "technology",
				effects = {{type = "unlock-recipe", recipe = "cryogenic-science-pack-clone"}, {type = "nothing"}}},
			["no-effects"] = {type = "technology"},
			["healthy"] = {type = "technology", effects = {productivity("cryogenic-science-pack")}},
		},
	}
	rawset(_G, "mods", mod_list)
	rawset(_G, "data", {raw = data_raw})
	logged = {}
	package.loaded["prototypes.compat.lithium_battery"] = nil
	return data_raw, require("prototypes.compat.lithium_battery")
end

local function recipes_of(technology)
	local out = {}
	for _, effect in ipairs(technology.effects) do
		out[#out + 1] = effect.recipe or effect.type
	end
	return table.concat(out, ",")
end

-- without Lithium Battery nothing changes
local data_raw, module = setup({})
module.data_final_fixes()
check(#data_raw.technology["planet-crucible-cryogenic-science-pack-productivity"].effects == 2, "changed without Lithium Battery")
check(#logged == 0, "logged without Lithium Battery")

-- with it, the effects of deleted recipes go
data_raw, module = setup({LithiumBattery = true})
module.data_final_fixes()
check(recipes_of(data_raw.technology["planet-crucible-cryogenic-science-pack-productivity"]) == "cryogenic-science-pack",
	"cryogenic: " .. recipes_of(data_raw.technology["planet-crucible-cryogenic-science-pack-productivity"]))
check(recipes_of(data_raw.technology["planet-crucible-promethium-science-pack-productivity"]) == "promethium-science-pack",
	"promethium: " .. recipes_of(data_raw.technology["planet-crucible-promethium-science-pack-productivity"]))
check(recipes_of(data_raw.technology["unlock-of-missing"]) == "cryogenic-science-pack-clone,nothing", "other effects kept")
check(recipes_of(data_raw.technology["healthy"]) == "cryogenic-science-pack", "healthy technology kept")
check(data_raw.technology["no-effects"].effects == nil, "technology without effects untouched")
check(#logged == 2, "one log line per removed effect: " .. #logged)

-- a second run changes nothing
module.data_final_fixes()
check(#logged == 2, "second run logged")

-- equal ingredients of the research data recipes are added up, in the first place and without touching the rest
local function ingredient_list(recipe)
	local out = {}
	for _, ingredient in ipairs(recipe.ingredients) do
		out[#out + 1] = (ingredient.type or "item") .. ":" .. ingredient.name .. "=" .. ingredient.amount
	end
	return table.concat(out, ",")
end

data_raw, module = setup({LithiumBattery = true})
data_raw.recipe["kr-promethium-research-data"] = {type = "recipe", name = "kr-promethium-research-data", ingredients = {
	{type = "item", name = "hea-engine", amount = 1},
	{type = "item", name = "biter-egg", amount = 7},
	{type = "fluid", name = "biter-egg", amount = 5},
	{type = "item", name = "promethium-asteroid-chunk", amount = 18},
	{type = "item", name = "biter-egg", amount = 4},
	{name = "carbon-fiber", amount = 2},
	{"shorthand", 1},
}}
data_raw.recipe["kr-cryogenic-research-data"] = {type = "recipe", name = "kr-cryogenic-research-data", ingredients = {
	{type = "item", name = "ice", amount = 3}, {type = "item", name = "lithium-plate", amount = 1}}}
module.data_final_fixes()
check(ingredient_list({ingredients = {table.unpack(data_raw.recipe["kr-promethium-research-data"].ingredients, 1, 5)}})
	== "item:hea-engine=1,item:biter-egg=11,fluid:biter-egg=5,item:promethium-asteroid-chunk=18,item:carbon-fiber=2",
	"merged: " .. ingredient_list({ingredients = {table.unpack(data_raw.recipe["kr-promethium-research-data"].ingredients, 1, 5)}}))
check(#data_raw.recipe["kr-promethium-research-data"].ingredients == 6, "the shorthand ingredient stays")
check(ingredient_list(data_raw.recipe["kr-cryogenic-research-data"]) == "item:ice=3,item:lithium-plate=1", "recipe without doubles untouched")

-- 7.5.1 keeps the copies, and a copy and its research data recipe hold the same ingredient list: Maraxsis appends the biter eggs to
-- the shared list, the sum of one recipe must not reach the other, and both end without doubles
local shared_promethium = {
	{type = "item", name = "hea-engine", amount = 1},
	{type = "item", name = "biter-egg", amount = 7},
	{type = "item", name = "promethium-asteroid-chunk", amount = 18},
	{type = "item", name = "biter-egg", amount = 10},
}
local shared_cryogenic = {{type = "item", name = "ice", amount = 3}, {type = "item", name = "lithium-plate", amount = 1}}
data_raw, module = setup({LithiumBattery = true})
data_raw.recipe["cryogenic-science-pack-clone"] = {type = "recipe", name = "cryogenic-science-pack-clone", hidden = true,
	enabled = false, ingredients = shared_cryogenic}
data_raw.recipe["kr-cryogenic-research-data"] = {type = "recipe", name = "kr-cryogenic-research-data", ingredients = shared_cryogenic}
data_raw.recipe["promethium-science-pack-clone"] = {type = "recipe", name = "promethium-science-pack-clone", hidden = true,
	enabled = false, ingredients = shared_promethium}
data_raw.recipe["kr-promethium-research-data"] = {type = "recipe", name = "kr-promethium-research-data", ingredients = shared_promethium}
module.data_final_fixes()
local merged_promethium = "item:hea-engine=1,item:biter-egg=17,item:promethium-asteroid-chunk=18"
check(ingredient_list(data_raw.recipe["kr-promethium-research-data"]) == merged_promethium,
	"research data: " .. ingredient_list(data_raw.recipe["kr-promethium-research-data"]))
check(ingredient_list(data_raw.recipe["promethium-science-pack-clone"]) == merged_promethium,
	"copy: " .. ingredient_list(data_raw.recipe["promethium-science-pack-clone"]))
check(data_raw.recipe["kr-promethium-research-data"].ingredients ~= data_raw.recipe["promethium-science-pack-clone"].ingredients,
	"the copy and the research data recipe still share the list")
check(data_raw.recipe["kr-promethium-research-data"].ingredients[2] ~= data_raw.recipe["promethium-science-pack-clone"].ingredients[2],
	"the copy and the research data recipe still share an ingredient")
check(data_raw.recipe["promethium-science-pack-clone"].hidden == true and data_raw.recipe["promethium-science-pack-clone"].enabled == false,
	"the copy stays hidden and disabled")
check(ingredient_list(data_raw.recipe["kr-cryogenic-research-data"]) == "item:ice=3,item:lithium-plate=1"
	and data_raw.recipe["cryogenic-science-pack-clone"].ingredients == shared_cryogenic, "recipes without doubles untouched")
check(#logged == 2, "one log line per sum, per recipe: " .. #logged)
module.data_final_fixes()
check(#logged == 2, "second run logged")

-- without Lithium Battery the ingredients stay as they are
data_raw, module = setup({})
data_raw.recipe["kr-promethium-research-data"] = {type = "recipe", name = "kr-promethium-research-data", ingredients = {
	{type = "item", name = "biter-egg", amount = 7}, {type = "item", name = "biter-egg", amount = 4}}}
module.data_final_fixes()
check(#data_raw.recipe["kr-promethium-research-data"].ingredients == 2, "merged without Lithium Battery")

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

-- a pack without technologies or recipes does not fail
rawset(_G, "mods", {LithiumBattery = true})
rawset(_G, "data", {raw = {}})
package.loaded["prototypes.compat.lithium_battery"] = nil
require("prototypes.compat.lithium_battery").data_final_fixes()

print("lithium battery: ok")
