-- Multiplex card recipes (compat/system_card_manufacturing.lua) on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_system_card_manufacturing.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local function clone(value)
	if type(value) ~= "table" then return value end
	local copy = {}
	for k, v in pairs(value) do copy[k] = clone(v) end
	return copy
end
table.deepcopy = clone -- luacheck: ignore 122 (the fixture replaces Factorio's helper)
rawset(_G, "log", function(_) end)

local card_names = {
	"solaris-tech-card", "nyxaris-tech-card", "vibrant-tech-card", "vespera-tech-card",
	"beetlejuice-tech-card", "umbra-tech-card", "deep-space-tech-card"
}
-- Science packs and cards are `tool` prototypes in 2.1; plain materials are `item`.
---@type table<string, table>
local tools, raw_recipes, technologies, items = {}, {}, {}, {}
for _, name in ipairs(card_names) do
	tools[name] = {type = "tool", name = name, icon = "__base__/graphics/icons/automation-science-pack.png", icon_size = 64}
	raw_recipes[name] = {type = "recipe", name = name, enabled = false, categories = {"crafting"},
		energy_required = 12,
		ingredients = {{type = "item", name = "calidus-tech-card", amount = 1}},
		results = {{type = "item", name = name, amount = 1}}}
end
tools["calidus-tech-card"] = {type = "tool", name = "calidus-tech-card"}
tools["space-logistic-science-pack"] = {type = "tool", name = "space-logistic-science-pack"}
tools["pulsar-science-pack"] = {type = "tool", name = "pulsar-science-pack"}
for _, part in ipairs({"kr-rare-metals", "tungsten-plate", "bioflux", "optical-cable", "electric-coil",
	"holmium-plate", "craptonite-frame", "carbon-fiber", "gold-plate", "rare-earth-powder", "chitosan",
	"supermagnet"}) do
	items[part] = {type = "item", name = part}
end
items["bioflux"] = nil
---@type table<string, table>
local capsules = {bioflux = {type = "capsule", name = "bioflux"}}
for _, tech in ipairs({"planet-discovery-corrundum", "planet-discovery-apia-carnova",
	"planet-discovery-paracelsin", "planet-discovery-rubia", "planet-discovery-secretas",
	"planet-discovery-vesta", "razi-singularity-theory"}) do
	technologies[tech] = {type = "technology", name = tech, effects = {}, prerequisites = {"base-unlock"}}
end
-- Every ordinary card is unlocked by an earlier technology; Vespera's configured technology
-- (Rubia) does not follow its card's technology, so it must fall back to the card's own.
technologies["base-unlock"] = {type = "technology", name = "base-unlock", effects = {}}
for _, name in ipairs(card_names) do
	technologies["unlock-" .. name] = {type = "technology", name = "unlock-" .. name,
		effects = {{type = "unlock-recipe", recipe = name}}, prerequisites = {"base-unlock"}}
end
technologies["planet-discovery-corrundum"].prerequisites = {"unlock-solaris-tech-card"}
technologies["planet-discovery-apia-carnova"].prerequisites = {"unlock-nyxaris-tech-card"}
technologies["planet-discovery-paracelsin"].prerequisites = {"unlock-vibrant-tech-card"}
technologies["planet-discovery-secretas"].prerequisites = {"unlock-beetlejuice-tech-card"}
technologies["planet-discovery-vesta"].prerequisites = {"unlock-umbra-tech-card"}
technologies["razi-singularity-theory"].prerequisites = {"unlock-deep-space-tech-card"}
-- planet-discovery-rubia keeps only base-unlock: it does not follow unlock-vespera-tech-card.
rawset(_G, "data", {raw = {recipe = raw_recipes, technology = technologies, tool = tools, item = items, capsule = capsules,
	["assembling-machine"] = {large = {crafting_categories = {"crafting"}, ingredient_count = 16}}}})
function data:extend(objects)
	for _, object in ipairs(objects) do
		check(not self.raw[object.type][object.name], "Duplicate recipe")
		self.raw[object.type][object.name] = object
	end
end

local mod = require("prototypes.compat.system_card_manufacturing")
mod.data_final_fixes()
for _, rule in ipairs(mod.rules) do
	local recipe = raw_recipes[rule.name] or error("Missing bulk recipe " .. rule.name)
	local native = raw_recipes[rule.card] or error("Missing native recipe " .. rule.card)
	check(native.ingredients[1].amount == 1, "Original card manufacture has been changed")
	check(recipe.results[1].amount == 5 and recipe.ingredients[1].amount == 4,
		"Bulk route must need four complete source batches for five cards")
	check(math.abs(recipe.energy_required - native.energy_required * 4 * 1.15) < 0.0001,
		"Freight recipe should charge 15 percent extra native-batch time")
	check(#recipe.ingredients == #native.ingredients + #rule.freight, "Missing actual native freight inputs")
	check(recipe.auto_recycle == false and recipe.allow_productivity == false
		and recipe.allow_decomposition == false, "No free productivity amplification")
	check(recipe.enabled == false, "Multiplex recipe is unlocked by research only")
	local expected = rule.unlock
	if rule.card == "vespera-tech-card" then expected = "unlock-vespera-tech-card" end
	local registered = false
	for _, effect in ipairs(technologies[expected].effects) do
		if effect.recipe == rule.name then registered = true end
	end
	check(registered, "Missing source technology unlock in " .. expected)
end
check(#technologies["planet-discovery-rubia"].effects == 0,
	"Vespera multiplex must not be unlocked before the Vespera card recipe")

mod.data_final_fixes()
check(#technologies["planet-discovery-corrundum"].effects == 1,
	"Second registration must not duplicate the source unlock")

raw_recipes["razi-nyxaris-multiplex-cards"] = nil
capsules["bioflux"] = nil
mod.data_final_fixes()
check(raw_recipes["razi-nyxaris-multiplex-cards"] == nil,
	"Missing supplier must disable only its own freight option")

raw_recipes["razi-umbra-multiplex-cards"] = nil
data.raw["assembling-machine"].large.ingredient_count = 3
mod.data_final_fixes()
check(raw_recipes["razi-umbra-multiplex-cards"] == nil,
	"Unavailable ingredient-capable machines must suppress only optional synthesis")
print("Card multiplex: native conservation, freight, science and safety passed")
