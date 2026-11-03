---@diagnostic disable: missing-fields
-- The helper that takes a working recipe out of the game for the balance files
-- (prototypes/balance/common/hide_recipes.lua), on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_balance_hide_recipes.lua
package.path = "./?.lua;./?/init.lua;" .. package.path
local support = require("tests.lua.loops_support")
local check = support.check

local hide_recipes = require("prototypes.balance.common.hide_recipes")

local function unlock(name)
	return { type = "unlock-recipe", recipe = name }
end

local raw = support.install({
	gone = { enabled = true },
	other = { enabled = true },
}, {
	-- left with nothing: hidden
	only_gone = { effects = { unlock("gone") } },
	-- left with another recipe: stays
	both = { effects = { unlock("gone"), unlock("other") } },
	-- left with another kind of effect: stays
	mixed = { effects = { unlock("gone"), { type = "nothing" } } },
	-- left with nothing, but another technology needs it: stays
	needed = { effects = { unlock("gone") } },
	user = { prerequisites = { "needed" }, effects = { unlock("other") } },
	-- never had effects: stays
	empty = {},
	-- another recipe: stays
	unrelated = { effects = { unlock("other") } },
})

hide_recipes.hide({ "gone", "missing" })

check(raw.recipe.gone.enabled == false and raw.recipe.gone.hidden == true, "The recipe is disabled and hidden")
check(raw.recipe.other.enabled == true and raw.recipe.other.hidden == nil, "Another recipe is left alone")
check(raw.technology.only_gone.hidden == true and #raw.technology.only_gone.effects == 0,
	"A technology left with nothing is hidden")
check(raw.technology.both.hidden == nil and #raw.technology.both.effects == 1 and raw.technology.both.effects[1].recipe == "other",
	"A technology with another recipe keeps it and stays")
check(raw.technology.mixed.hidden == nil and #raw.technology.mixed.effects == 1 and raw.technology.mixed.effects[1].type == "nothing",
	"A technology with another effect stays")
check(raw.technology.needed.hidden == nil and #raw.technology.needed.effects == 0,
	"A technology that another one requires stays")
check(raw.technology.empty.hidden == nil and raw.technology.unrelated.hidden == nil, "Other technologies are left alone")
check(support.logged("recipe gone hidden") == 1 and support.logged("technology only_gone hidden") == 1
	and #support.logs == 2, "Two lines: the recipe and the technology")
check(support.logs[1]:find("^razi%-protocol: ") ~= nil, "Lines start with the mod name")

-- Nothing to hide: no change, no line, no failure.
raw = support.install({ other = { enabled = true } }, { t = { effects = { unlock("other") } } })
hide_recipes.hide({ "gone" })
check(#support.logs == 0 and raw.recipe.other.hidden == nil and raw.technology.t.hidden == nil, "A missing recipe is skipped")

print("test_balance_hide_recipes: ok")
