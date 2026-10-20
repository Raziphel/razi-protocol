-- Unlocks of Skewer Shattered Planet's recipes under Vesta (compat/skewer_shattered_unlocks.lua) on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_skewer_shattered_unlocks.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local logged = 0
rawset(_G, "log", function(_) logged = logged + 1 end)

local function setup(mod_list, slurry_ingredient)
	local raw = {
		recipe = {
			nitrogen = {type = "recipe", name = "nitrogen", hidden = true,
				ingredients = {{type = "fluid", name = slurry_ingredient, amount = 10}}},
			ske_ammonia = {type = "recipe", name = "ske_ammonia"},
			ske_water_vaporization = {type = "recipe", name = "ske_water_vaporization"},
		},
		technology = {
			alternate_methods_of_production = {type = "technology", name = "alternate_methods_of_production",
				effects = {{type = "unlock-recipe", recipe = "ske_foundry"}}},
			chunk_slurry_creation = {type = "technology", name = "chunk_slurry_creation",
				effects = {{type = "unlock-recipe", recipe = "ske_metallic_slurry"}}},
		},
	}
	rawset(_G, "mods", mod_list)
	rawset(_G, "data", {raw = raw})
	package.loaded["prototypes.compat.skewer_shattered_unlocks"] = nil
	return raw, require("prototypes.compat.skewer_shattered_unlocks")
end

local function unlocks(technology, recipe_name)
	for _, effect in pairs(technology.effects) do
		if effect.type == "unlock-recipe" and effect.recipe == recipe_name then
			return true
		end
	end
	return false
end

local both = {skewer_shattered_planet = "1.0.42", skewer_planet_vesta = "2.1.29"}

-- Under Vesta the three recipes come back on the technologies of the branch without Vesta.
local raw, compat = setup(both, "ske_slurry_oxide")
compat.data_final_fixes()
local alternate, slurry = raw.technology.alternate_methods_of_production, raw.technology.chunk_slurry_creation
check(unlocks(alternate, "nitrogen"), "nitrogen is unlocked again")
check(unlocks(alternate, "ske_ammonia"), "ske_ammonia is unlocked")
check(unlocks(slurry, "ske_water_vaporization"), "ske_water_vaporization is unlocked")
check(unlocks(alternate, "ske_foundry") and #alternate.effects == 3, "the other effects stay")
check(raw.recipe.nitrogen.hidden == false, "the slurry recipe is shown again")
check(logged == 4, "every change is logged")

-- A second pass changes nothing.
logged = 0
compat.data_final_fixes()
check(#alternate.effects == 3 and #slurry.effects == 2 and logged == 0, "the second pass is idempotent")

-- A recipe that a technology opens already stays as it is.
raw, compat = setup(both, "ske_slurry_oxide")
raw.technology.chunk_slurry_creation.effects[#raw.technology.chunk_slurry_creation.effects + 1] =
	{type = "unlock-recipe", recipe = "ske_water_vaporization"}
compat.data_final_fixes()
check(#raw.technology.chunk_slurry_creation.effects == 2, "an existing unlock is not doubled")

-- Another recipe named nitrogen is not Skewer's slurry recipe.
raw, compat = setup(both, "air")
compat.data_final_fixes()
check(not unlocks(raw.technology.alternate_methods_of_production, "nitrogen") and raw.recipe.nitrogen.hidden == true,
	"a nitrogen recipe of another mod is left alone")

-- Without Vesta, or without Skewer Shattered Planet, nothing happens.
for _, mod_list in ipairs({{skewer_shattered_planet = "1.0.42"}, {skewer_planet_vesta = "2.1.29"}, {}}) do
	raw, compat = setup(mod_list, "ske_slurry_oxide")
	compat.data_final_fixes()
	check(#raw.technology.chunk_slurry_creation.effects == 1 and raw.recipe.nitrogen.hidden == true, "no change without both mods")
end

-- Missing prototypes do not crash.
rawset(_G, "mods", both)
rawset(_G, "data", {raw = {}})
package.loaded["prototypes.compat.skewer_shattered_unlocks"] = nil
require("prototypes.compat.skewer_shattered_unlocks").data_final_fixes()

-- The entrypoint runs it.
local file = assert(io.open("data-final-fixes.lua", "r"))
local source = file:read("*a")
file:close()
check(source:find('require("prototypes.compat.skewer_shattered_unlocks").data_final_fixes()', 1, true), "data-final-fixes.lua calls the unlocks")

print("skewer_shattered_unlocks: ok")
