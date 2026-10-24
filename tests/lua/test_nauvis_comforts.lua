---@diagnostic disable: missing-fields, assign-type-mismatch, need-check-nil
-- The stack inserter, the toolbelt equipment and the two belt capacity technologies leave Gleba's science and carbon fiber research
-- (technology/nauvis_comforts.lua) on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_nauvis_comforts.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local logged = 0
rawset(_G, "log", function(_) logged = logged + 1 end)

local function setup()
	local technologies = {
		["bulk-inserter"] = {unit = {ingredients = {{"automation-science-pack", 1}}}},
		["production-science-pack"] = {unit = {ingredients = {{"automation-science-pack", 1}}}},
		["utility-science-pack"] = {unit = {ingredients = {{"automation-science-pack", 1}}}},
		["space-science-pack"] = {prerequisites = {"production-science-pack"}, research_trigger = {type = "build-entity"}},
		["power-armor"] = {unit = {ingredients = {{"automation-science-pack", 1}}}},
		["toolbelt"] = {unit = {ingredients = {{"automation-science-pack", 1}}}},
		["inserter-capacity-bonus-7"] = {unit = {ingredients = {{"automation-science-pack", 1}}}},
		["planet-discovery-gleba"] = {unit = {ingredients = {{"space-science-pack", 1}}}},
		["agricultural-science-pack"] = {prerequisites = {"planet-discovery-gleba"},
			effects = {{type = "unlock-recipe", recipe = "agricultural-science-pack"}},
			unit = {ingredients = {{"space-science-pack", 1}}}},
		["carbon-fiber"] = {prerequisites = {"agricultural-science-pack"},
			effects = {{type = "unlock-recipe", recipe = "carbon-fiber"}},
			unit = {ingredients = {{"space-science-pack", 1}, {"agricultural-science-pack", 1}}}},
		["stack-inserter"] = {
			prerequisites = {"carbon-fiber", "production-science-pack", "utility-science-pack", "bulk-inserter"},
			effects = {{type = "unlock-recipe", recipe = "stack-inserter"}, {type = "belt-stack-size-bonus", modifier = 1}},
			unit = {count = 1000, time = 60, ingredients = {{"production-science-pack", 1}, {"utility-science-pack", 1},
				{"space-science-pack", 1}, {"agricultural-science-pack", 1}}}},
		["toolbelt-equipment"] = {
			prerequisites = {"power-armor", "toolbelt", "carbon-fiber"},
			unit = {count = 300, time = 30, ingredients = {{"space-science-pack", 1}, {"agricultural-science-pack", 1}}}},
		["transport-belt-capacity-1"] = {
			prerequisites = {"stack-inserter"},
			unit = {count = 2000, time = 60, ingredients = {{"production-science-pack", 1}, {"utility-science-pack", 1},
				{"space-science-pack", 1}, {"agricultural-science-pack", 1}}}},
		["transport-belt-capacity-2"] = {
			prerequisites = {"transport-belt-capacity-1", "inserter-capacity-bonus-7"},
			unit = {count = 3000, time = 60, ingredients = {{"production-science-pack", 1}, {"utility-science-pack", 1},
				{"space-science-pack", 1}, {"agricultural-science-pack", 1}}}},
		-- after the comforts: keeps its own price
		["epic-quality"] = {prerequisites = {"agricultural-science-pack"},
			unit = {ingredients = {{"utility-science-pack", 1}, {"space-science-pack", 1}, {"agricultural-science-pack", 1}}}},
	}
	-- after the stack inserter, with and without a recipe that needs carbon fiber; and a technology outside, with one
	technologies["rubia-long-stack-inserter"] = {prerequisites = {"stack-inserter", "agricultural-science-pack"},
		effects = {{type = "unlock-recipe", recipe = "rubia-long-stack-inserter"}},
		unit = {ingredients = {{"utility-science-pack", 1}, {"agricultural-science-pack", 1}}}}
	technologies["long-stack-inserter"] = {prerequisites = {"stack-inserter"},
		effects = {{type = "unlock-recipe", recipe = "long-stack-inserter"}},
		unit = {ingredients = {{"utility-science-pack", 1}}}}
	technologies["rocket-turret"] = {prerequisites = {"bulk-inserter"},
		effects = {{type = "unlock-recipe", recipe = "rocket-turret"}},
		unit = {ingredients = {{"utility-science-pack", 1}}}}
	rawset(_G, "data", {raw = {
		technology = technologies,
		recipe = {
			["stack-inserter"] = {ingredients = {{type = "item", name = "carbon-fiber", amount = 2}, {type = "item", name = "jelly", amount = 10}}},
			["rubia-long-stack-inserter"] = {ingredients = {{type = "item", name = "carbon-fiber", amount = 2}}},
			["long-stack-inserter"] = {ingredients = {{type = "item", name = "stack-inserter", amount = 1}}},
			["rocket-turret"] = {ingredients = {{"carbon-fiber", 20}}},
		},
	}})
	package.loaded["prototypes.technology.nauvis_comforts"] = nil
	return technologies, require("prototypes.technology.nauvis_comforts")
end

local function prices(technology, name)
	for _, ingredient in ipairs(technology.unit.ingredients) do
		if (ingredient.name or ingredient[1]) == name then
			return true
		end
	end
	return false
end

local function requires(technology, name)
	for _, prerequisite in ipairs(technology.prerequisites or {}) do
		if prerequisite == name then
			return true
		end
	end
	return false
end

local comforts = {"stack-inserter", "toolbelt-equipment", "transport-belt-capacity-1", "transport-belt-capacity-2"}

local technologies, module = setup()
module.data_final_fixes()
for _, name in ipairs(comforts) do
	check(not prices(technologies[name], "agricultural-science-pack"), name .. " no longer costs agricultural science")
	check(not requires(technologies[name], "carbon-fiber"), name .. " no longer requires carbon fiber")
	check(not requires(technologies[name], "agricultural-science-pack"), name .. " no longer requires the pack technology")
end
check(logged > 0, "the changes are logged")

-- the rest of the price and of the prerequisites stays
local stack = technologies["stack-inserter"]
check(#stack.unit.ingredients == 3 and prices(stack, "production-science-pack") and prices(stack, "utility-science-pack")
	and prices(stack, "space-science-pack"), "the stack inserter keeps production, utility and space science")
check(stack.unit.count == 1000 and stack.unit.time == 60, "the count and the time of the stack inserter stay")
check(requires(stack, "bulk-inserter") and requires(stack, "production-science-pack") and requires(stack, "utility-science-pack"),
	"the other prerequisites of the stack inserter stay")
check(#stack.effects == 2, "the effects stay")
check(requires(technologies["transport-belt-capacity-1"], "stack-inserter"), "belt capacity 1 follows the stack inserter")
check(requires(technologies["transport-belt-capacity-2"], "transport-belt-capacity-1")
	and requires(technologies["transport-belt-capacity-2"], "inserter-capacity-bonus-7"), "belt capacity 2 keeps its prerequisites")
check(technologies["toolbelt-equipment"].unit.count == 300 and #technologies["toolbelt-equipment"].unit.ingredients == 1,
	"the toolbelt equipment is priced in space science only")

-- Space science was reached through carbon fiber: it is now a prerequisite of the technologies priced in it.
check(requires(technologies["toolbelt-equipment"], "space-science-pack"), "the toolbelt equipment requires the space science pack technology")
check(requires(technologies["stack-inserter"], "space-science-pack"), "the stack inserter requires the space science pack technology")
check(not requires(technologies["transport-belt-capacity-1"], "space-science-pack"), "belt capacity 1 reaches it through the stack inserter")
check(not requires(technologies["transport-belt-capacity-2"], "space-science-pack"), "belt capacity 2 reaches it through belt capacity 1")
check(#stack.prerequisites == 4, "the pack technologies that were already ancestors are not added twice")

-- Gleba's own research and the research after the comforts are untouched.
check(prices(technologies["epic-quality"], "agricultural-science-pack") and requires(technologies["epic-quality"], "agricultural-science-pack"),
	"other technologies keep agricultural science")
check(prices(technologies["carbon-fiber"], "agricultural-science-pack"), "carbon fiber keeps its price")
check(requires(technologies["carbon-fiber"], "agricultural-science-pack"), "carbon fiber keeps its prerequisite")

-- What came after the stack inserter keeps the carbon fiber research if its recipe needs the item; the rest is left alone.
check(requires(technologies["rubia-long-stack-inserter"], "carbon-fiber"), "a technology after the stack inserter with a carbon fiber recipe requires carbon fiber")
check(not requires(technologies["long-stack-inserter"], "carbon-fiber"), "a technology after the stack inserter without one does not")
check(not requires(technologies["rocket-turret"], "carbon-fiber"), "a technology outside the comforts is not touched")
check(not requires(technologies["stack-inserter"], "carbon-fiber"), "the stack inserter itself does not")

-- A second pass changes nothing.
logged = 0
module.data_final_fixes()
check(#stack.unit.ingredients == 3 and #stack.prerequisites == 4, "the second pass is idempotent")
check(logged == 0, "the second pass logs nothing")

-- Other planet packs go too; a technology whose only pack or prerequisite is Gleba's keeps it.
technologies, module = setup()
table.insert(technologies["stack-inserter"].unit.ingredients, {"metallurgic-science-pack", 1})
table.insert(technologies["stack-inserter"].unit.ingredients, {type = "item", name = "electromagnetic-science-pack", amount = 1})
technologies["toolbelt-equipment"].unit.ingredients = {{"agricultural-science-pack", 1}}
technologies["toolbelt-equipment"].prerequisites = {"carbon-fiber"}
module.data_final_fixes()
check(not prices(technologies["stack-inserter"], "metallurgic-science-pack")
	and not prices(technologies["stack-inserter"], "electromagnetic-science-pack"), "the other planet packs are taken out too")
check(#technologies["toolbelt-equipment"].unit.ingredients == 1 and prices(technologies["toolbelt-equipment"], "agricultural-science-pack"),
	"no empty price")
check(requires(technologies["toolbelt-equipment"], "carbon-fiber"), "no technology is left without prerequisites")

-- A technology that is missing, or that has no price, is skipped.
technologies, module = setup()
technologies["toolbelt-equipment"] = nil
technologies["transport-belt-capacity-2"].unit = nil
module.data_final_fixes()
check(not prices(technologies["stack-inserter"], "agricultural-science-pack"), "the others are still changed")
rawset(_G, "data", {raw = {}})
package.loaded["prototypes.technology.nauvis_comforts"] = nil
require("prototypes.technology.nauvis_comforts").data_final_fixes()

-- It runs after the gates and before the gate links.
local file = assert(io.open("data-final-fixes.lua", "r"))
local source = file:read("*a")
file:close()
local gates = assert(source:find('require("prototypes.technology.seven_system_gates").data_final_fixes()', 1, true))
local pass = assert(source:find('require("prototypes.technology.nauvis_comforts").data_final_fixes()', 1, true))
local links = assert(source:find('require("prototypes.technology.system_gate_links").data_final_fixes()', 1, true))
check(gates < pass and pass < links, "the pass runs between the gates and the gate links")

print("nauvis_comforts: ok")
