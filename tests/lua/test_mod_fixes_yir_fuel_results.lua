---@diagnostic disable: lowercase-global
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local module_name = "prototypes.fixes.yi_railway.fuel_fluid_results"

local function run(raw, no_mod)
	local logs = {}
	rawset(_G, "data", {raw = raw})
	rawset(_G, "mods", no_mod and {} or {yi_railway = "1.4.0"})
	rawset(_G, "log", function(message) logs[#logs + 1] = message end)
	package.loaded[module_name] = nil
	require(module_name).data_final_fixes()
	return logs
end

local raw = {
	item = {yir_fuel_fluid_u1 = {}, yir_fuel_fluid_u3 = {}},
	recipe = {
		yir_fuel_fluid_u1 = {results = {
			{type = "item", name = "yir_fuel_fluid_u2", amount = 100},
			{type = "item", name = "yir_fuel_fluid_u2", amount = 1},
		}},
		yir_fuel_fluid_u3 = {results = {{type = "item", name = "yir_fuel_fluid_u2", amount = 100}}},
		yir_fuel_fluid_u2 = {results = {{type = "item", name = "yir_fuel_fluid_u2", amount = 100}}},
	},
}
local logs = run(raw)
check(raw.recipe.yir_fuel_fluid_u1.results[1].name == "yir_fuel_fluid_u1"
	and raw.recipe.yir_fuel_fluid_u1.results[2].name == "yir_fuel_fluid_u1",
	"every u1 recipe result produces u1")
check(raw.recipe.yir_fuel_fluid_u3.results[1].name == "yir_fuel_fluid_u3", "the u3 recipe produces u3")
check(raw.recipe.yir_fuel_fluid_u2.results[1].name == "yir_fuel_fluid_u2", "the u2 recipe stays unchanged")
check(#logs == 2
	and logs[1] == "razi-protocol: yi_railway: recipe yir_fuel_fluid_u1 makes yir_fuel_fluid_u1, not yir_fuel_fluid_u2"
	and logs[2] == "razi-protocol: yi_railway: recipe yir_fuel_fluid_u3 makes yir_fuel_fluid_u3, not yir_fuel_fluid_u2",
	"each changed recipe is logged once")

raw = {
	item = {yir_fuel_fluid_u1 = {}},
	recipe = {
		yir_fuel_fluid_u1 = {results = {{type = "item", name = "yir_fuel_fluid_u1", amount = 100}}},
		yir_fuel_fluid_u3 = {results = {{type = "item", name = "yir_fuel_fluid_u2", amount = 100}}},
	},
}
logs = run(raw)
check(raw.recipe.yir_fuel_fluid_u1.results[1].name == "yir_fuel_fluid_u1", "an already correct u1 result stays")
check(raw.recipe.yir_fuel_fluid_u3.results[1].name == "yir_fuel_fluid_u2", "a recipe without its item is skipped")
check(#logs == 0, "unchanged or incomplete recipes are not logged")

raw = {
	item = {yir_fuel_fluid_u1 = {}},
	recipe = {yir_fuel_fluid_u1 = {results = {{type = "item", name = "yir_fuel_fluid_u2", amount = 100}}}},
}
logs = run(raw, true)
check(raw.recipe.yir_fuel_fluid_u1.results[1].name == "yir_fuel_fluid_u2" and #logs == 0,
	"the pass is inert without YIR")

print("test_mod_fixes_yir_fuel_results: ok")
