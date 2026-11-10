---@diagnostic disable: missing-fields
-- The lossless pairs of the Hyarion particle manipulator take no quality, carbon nanotubes take productivity (prototypes/balance/planetaris-hyarion/particle_manipulation.lua), on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_balance_particle_manipulation.lua
package.path = "./?.lua;./?/init.lua;" .. package.path
local support = require("tests.lua.loops_support")
local check = support.check
local loops = require("prototypes.balance.resource_loops")

local fix = require("prototypes.balance.planetaris-hyarion.particle_manipulation")

local pairs_of_hyarion = {
	"planetaris-calcite-particle-manipulation", "planetaris-raw-quartz-particle-manipulation",
	"planetaris-coal-to-stone-particle-manipulation", "planetaris-stone-to-coal-particle-manipulation",
	"planetaris-sapphire-to-sulfur-particle-manipulation", "planetaris-sulfur-to-sapphire-particle-manipulation",
}

local function fixture()
	local recipes = { ["planetaris-carbon-nanotube"] = { allow_productivity = false },
		-- the lossy pair of coal and carbon keeps its quality
		["planetaris-coal-to-carbon-particle-manipulation"] = {} }
	for _, name in ipairs(pairs_of_hyarion) do
		recipes[name] = { allow_productivity = false }
	end

	return recipes
end

local raw = support.install(fixture())
fix.data_final_fixes()
for _, name in ipairs(pairs_of_hyarion) do
	check(raw.recipe[name].allow_quality == false, name .. " takes no quality")
end
check(raw.recipe["planetaris-coal-to-carbon-particle-manipulation"].allow_quality == nil, "The lossy pair keeps quality")
check(raw.recipe["planetaris-carbon-nanotube"].allow_productivity == true, "Carbon nanotubes take productivity")
check(support.logged("takes no quality") == 6 and support.logged("planetaris-carbon-nanotube takes productivity") == 1
	and #support.logs == 7 and support.logs[1]:find("^razi%-protocol: "), "One line for each change")

-- Another run, or recipes that already have what the fix wants (container pairs of the closed level do it): silent.
support.logs = {}
fix.data_final_fixes()
check(#support.logs == 0, "A second run changes nothing")

-- An allowed nanotube that the author wrote stays as it is; a missing allow_productivity is the default false.
raw = support.install({ ["planetaris-carbon-nanotube"] = { allow_productivity = true } })
fix.data_final_fixes()
check(#support.logs == 0 and raw.recipe["planetaris-carbon-nanotube"].allow_productivity == true, "An allowed nanotube is silent")
raw = support.install({ ["planetaris-carbon-nanotube"] = {} })
fix.data_final_fixes()
check(raw.recipe["planetaris-carbon-nanotube"].allow_productivity == true, "A nanotube without the field takes productivity")

support.install({})
fix.data_final_fixes()
check(#support.logs == 0, "No recipes, no change")

support.gate(loops, fixture, function(data_raw)
	return data_raw.recipe["planetaris-calcite-particle-manipulation"].allow_quality == false
		and data_raw.recipe["planetaris-carbon-nanotube"].allow_productivity == true
end, "strict")

print("test_balance_particle_manipulation: ok")
