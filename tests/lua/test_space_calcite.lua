---@diagnostic disable: missing-fields, need-check-nil
-- The metallurgic science pack research also unlocks the oxide asteroid crushing that yields calcite
-- (prototypes/balance/space-age/space_calcite.lua), on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_space_calcite.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local logged = 0
rawset(_G, "log", function(_) logged = logged + 1 end)

local function setup(results, effects)
	rawset(_G, "data", {raw = {
		technology = {
			["metallurgic-science-pack"] = {name = "metallurgic-science-pack", effects = effects},
			["advanced-asteroid-processing"] = {name = "advanced-asteroid-processing",
				effects = {{type = "unlock-recipe", recipe = "advanced-oxide-asteroid-crushing"}}},
		},
		recipe = {
			["advanced-oxide-asteroid-crushing"] = {name = "advanced-oxide-asteroid-crushing", results = results},
		},
	}})
	logged = 0
	package.loaded["prototypes.balance.space-age.space_calcite"] = nil
	require("prototypes.balance.space-age.space_calcite").data_final_fixes()
	return data.raw.technology
end

local function unlocks(technology, recipe)
	local count = 0
	for _, effect in ipairs(technology.effects or {}) do
		if effect.type == "unlock-recipe" and effect.recipe == recipe then
			count = count + 1
		end
	end
	return count
end

local calcite = {{type = "item", name = "ice", amount = 3}, {type = "item", name = "calcite", amount = 2}}

-- the Vulcanus research gains the unlock, the Gleba-era one keeps it
local technologies = setup(calcite, {{type = "unlock-recipe", recipe = "metallurgic-science-pack"}})
check(unlocks(technologies["metallurgic-science-pack"], "advanced-oxide-asteroid-crushing") == 1, "no calcite unlock after Vulcanus")
check(unlocks(technologies["metallurgic-science-pack"], "metallurgic-science-pack") == 1, "the pack unlock was lost")
check(unlocks(technologies["advanced-asteroid-processing"], "advanced-oxide-asteroid-crushing") == 1,
	"advanced asteroid processing lost its unlock")
check(logged == 1, "the change is not logged")

-- no effects table yet
technologies = setup(calcite, nil)
check(unlocks(technologies["metallurgic-science-pack"], "advanced-oxide-asteroid-crushing") == 1, "no unlock without effects")

-- already unlocked: not added twice, nothing logged
technologies = setup(calcite, {{type = "unlock-recipe", recipe = "advanced-oxide-asteroid-crushing"}})
check(unlocks(technologies["metallurgic-science-pack"], "advanced-oxide-asteroid-crushing") == 1, "unlock added twice")
check(logged == 0, "a change logged that did not happen")

-- the recipe no longer makes calcite: left alone
technologies = setup({{type = "item", name = "ice", amount = 3}}, {})
check(unlocks(technologies["metallurgic-science-pack"], "advanced-oxide-asteroid-crushing") == 0, "unlocked without calcite")

-- a missing technology or recipe does not fail
rawset(_G, "data", {raw = {}})
package.loaded["prototypes.balance.space-age.space_calcite"] = nil
require("prototypes.balance.space-age.space_calcite").data_final_fixes()

print("test_space_calcite: ok")
