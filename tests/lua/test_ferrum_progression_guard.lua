---@diagnostic disable: missing-fields, assign-type-mismatch, need-check-nil
-- Ferrum's robotics science and magnets stay out of the research that planet-discovery-ferrum needs (compat/ferrum_progression_guard.lua)
-- on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_ferrum_progression_guard.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local logged = 0
rawset(_G, "log", function(_) logged = logged + 1 end)

local pack = "ferrum-robotics-science-pack"

local function setup(mod_list)
	local technologies = {
		["planet-discovery-ribbonia"] = {effects = {{type = "unlock-recipe", recipe = "vibrant-tech-card"}},
			unit = {ingredients = {{"space-science-pack", 1}}}},
		-- needs the Vibrant card, whose recipe holds the refraction pack
		["cryogenic-plant"] = {effects = {{type = "unlock-recipe", recipe = "cryogenic-plant"}},
			unit = {ingredients = {{"space-science-pack", 1}}}},
		["fusion-reactor"] = {effects = {{type = "unlock-recipe", recipe = "fusion-reactor"}},
			prerequisites = {"ferrum-robotics-science-pack"}, unit = {ingredients = {{"space-science-pack", 1}}}},
		["beetlejuice-discovery"] = {prerequisites = {"planet-discovery-ribbonia", "cryogenic-plant"},
			unit = {ingredients = {{"vibrant-tech-card", 1}}}},
		["planetaris-refraction-science-pack"] = {
			effects = {{type = "unlock-recipe", recipe = "planetaris-refraction-science-pack"}},
			prerequisites = {"ferrum-robotics-science-pack", "planetaris-ruby-laser"},
			unit = {ingredients = {{"space-science-pack", 1}, {pack, 1}}}},
		["planetaris-ruby-laser"] = {unit = {ingredients = {{"space-science-pack", 1}, {pack, 1}}}},
		["planet-discovery-ferrum"] = {prerequisites = {"beetlejuice-discovery"},
			unit = {ingredients = {{"space-science-pack", 1}}}},
		["ferrum-robotics-science-pack"] = {effects = {{type = "unlock-recipe", recipe = pack}},
			prerequisites = {"planet-discovery-ferrum"}, unit = {ingredients = {{"space-science-pack", 1}}}},
		-- after Ferrum: keeps the pack
		["legendary-quality"] = {prerequisites = {"ferrum-robotics-science-pack"},
			unit = {ingredients = {{"space-science-pack", 1}, {pack, 1}, {"planetaris-refraction-science-pack", 1}}}},
	}
	rawset(_G, "mods", mod_list)
	rawset(_G, "data", {raw = {
		technology = technologies,
		recipe = {
			["vibrant-tech-card"] = {ingredients = {{type = "item", name = "planetaris-refraction-science-pack", amount = 1},
				{type = "item", name = "space-science-pack", amount = 1}}},
			["cryogenic-plant"] = {ingredients = {{type = "item", name = "superconductor", amount = 20},
				{type = "item", name = "ferrum-rare-earth-magnet", amount = 10}}},
			["cryogenic-plant-recycling"] = {results = {{type = "item", name = "superconductor", amount = 5},
				{type = "item", name = "ferrum-rare-earth-magnet", amount = 2}}},
			["fusion-reactor"] = {ingredients = {{type = "item", name = "tungsten-plate", amount = 200},
				{type = "item", name = "ferrum-rare-earth-magnet", amount = 200}}},
		},
	}})
	package.loaded["prototypes.compat.ferrum_progression_guard"] = nil
	return technologies, require("prototypes.compat.ferrum_progression_guard")
end

local function prices(technology, name)
	for _, ingredient in ipairs(technology.unit.ingredients) do
		if ingredient[1] == name then
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

local technologies, compat = setup({["planet-ferrum"] = "0.1.4"})
compat.data_final_fixes()
local refraction = technologies["planetaris-refraction-science-pack"]
check(not prices(refraction, pack), "the refraction research no longer costs Ferrum's pack")
check(not requires(refraction, pack), "the refraction research no longer requires the pack technology")
check(requires(refraction, "planetaris-ruby-laser"), "its other prerequisites stay")
check(#refraction.unit.ingredients == 1, "its other packs stay")
check(not prices(technologies["planetaris-ruby-laser"], pack), "the laser research is a prerequisite of the refraction research, which Ferrum needs")
check(prices(technologies["legendary-quality"], pack) and requires(technologies["legendary-quality"], pack),
	"research after Ferrum keeps its pack and its prerequisite")
check(prices(technologies["ferrum-robotics-science-pack"], "space-science-pack"), "the technology of the pack is untouched")
check(logged > 0, "the changes are logged")

-- The cryogenic plant, which the Vespera card needs, loses the magnets and its recycling recipe the return of them;
-- the fusion reactor, researched after Ferrum, keeps them.
local recipes = data.raw.recipe
check(#recipes["cryogenic-plant"].ingredients == 1 and recipes["cryogenic-plant"].ingredients[1].name == "superconductor",
	"the cryogenic plant takes no magnets")
check(#recipes["cryogenic-plant-recycling"].results == 1, "the cryogenic plant recycling returns no magnets")
check(#recipes["fusion-reactor"].ingredients == 2, "the fusion reactor keeps its magnets")

-- A second pass changes nothing.
logged = 0
compat.data_final_fixes()
check(#refraction.unit.ingredients == 1 and #technologies["legendary-quality"].unit.ingredients == 3
	and #data.raw.recipe["cryogenic-plant"].ingredients == 1, "the second pass is idempotent")

-- A technology whose only pack is Ferrum's is not left with an empty price.
technologies, compat = setup({["planet-ferrum"] = "0.1.4"})
technologies["planetaris-ruby-laser"].unit.ingredients = {{pack, 1}}
compat.data_final_fixes()
check(#technologies["planetaris-ruby-laser"].unit.ingredients == 1, "no empty price")

-- Without Ferrum, or without the gate, nothing happens.
technologies, compat = setup({})
compat.data_final_fixes()
check(prices(technologies["planetaris-refraction-science-pack"], pack), "no change without the mod")
check(#data.raw.recipe["cryogenic-plant"].ingredients == 2, "no change to recipes without the mod")
technologies, compat = setup({["planet-ferrum"] = "0.1.4"})
technologies["planet-discovery-ferrum"] = nil
compat.data_final_fixes()
check(prices(technologies["planetaris-refraction-science-pack"], pack), "no change without the gate")

-- It runs after the gates and before the cycle breaker.
local file = assert(io.open("data-final-fixes.lua", "r"))
local source = file:read("*a")
file:close()
local gates = assert(source:find('require("prototypes.technology.seven_system_gates").data_final_fixes()', 1, true))
local guard = assert(source:find('require("prototypes.compat.ferrum_progression_guard").data_final_fixes()', 1, true))
local breaker = assert(source:find('require("prototypes.technology.system_gate_links").data_final_fixes()', 1, true))
check(gates < guard and guard < breaker, "the guard runs between the gates and the cycle breaker")

print("ferrum_progression_guard: ok")
