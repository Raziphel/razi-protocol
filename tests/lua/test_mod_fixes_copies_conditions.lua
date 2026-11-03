---@diagnostic disable: missing-fields
-- Repairs of copies and of surface conditions (prototypes/fixes/): Arig's dust conditions, the bioluminescent copies of
-- Tenebris Prime and the conditions of copies of roboports, recyclers and rails, on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_mod_fixes_copies_conditions.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(value, message)
	if not value then
		error(message, 2)
	end
end

local logs = {}
rawset(_G, "log", function(message) logs[#logs + 1] = message end)

local function logged(text)
	local count = 0
	for _, line in ipairs(logs) do
		if line:find(text, 1, true) then
			count = count + 1
		end
	end

	return count
end

local function deepcopy(value)
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for key, item in pairs(value) do
		copy[key] = deepcopy(item)
	end

	return copy
end
table.deepcopy = deepcopy -- luacheck: ignore 122 (Factorio's helper, not in plain Lua)

---@return any
local function fresh()
	logs = {}
	local raw = {}
	rawset(_G, "data", {raw = raw})
	rawset(_G, "mods", {})
	rawset(_G, "defines", {prototypes = {item = {}}})
	return raw
end

local fixes = require("prototypes.fixes.init")

-- Nothing of the mods is installed: every repair is quiet and does not fail.
---@type any
local raw = fresh()
fixes.data_final_fixes()
check(#logs == 0, "A repair logged without its prototypes")
check(next(raw) == nil, "A repair created a prototype type")
raw = fresh()
raw.recipe = {}
raw.technology = {}
raw.planet = {}
raw.explosion = {}
raw["surface-property"] = {}
fixes.data_final_fixes()
check(#logs == 0, "A repair logged on empty prototype tables")

-- planetaris-arig surface_conditions
local arig = require("prototypes.fixes.planetaris-arig.surface_conditions")
local dust = "planetaris-dust-concentration"
raw = fresh()
raw["surface-property"] = {[dust] = {}}
raw.recipe = {
	["quantum-processor"] = {surface_conditions = {{property = "pressure", min = 10}}},
	["fusion-reactor"] = {},
	["fusion-generator"] = {surface_conditions = {{property = dust, min = 5, max = 20}}},
}
raw.explosion = {["nuke-effects-aquilo"] = {surface_conditions = {{property = "pressure", min = 10}}}}
arig.data_final_fixes()
---@type any
local quantum = raw.recipe["quantum-processor"].surface_conditions
check(#quantum == 2 and quantum[1].property == "pressure" and quantum[2].property == dust, "The condition was not added")
check(quantum[2].min == 1 and quantum[2].max == 50, "The condition does not have the defaults of the library")
check(raw.recipe["fusion-reactor"].surface_conditions[1].property == dust, "A recipe without conditions got none")
check(raw.recipe["fusion-generator"].surface_conditions[1].max == 20 and #raw.recipe["fusion-generator"].surface_conditions == 1,
	"A condition that Arig wrote was changed")
---@type any
local nuke = raw.explosion["nuke-effects-aquilo"].surface_conditions
check(#nuke == 2 and nuke[2].property == dust and nuke[2].max == 50 and nuke[2].min == nil, "The explosion did not get the dust limit")
check(logged("needs " .. dust) == 3, "Expected a line for each of the two recipes and the explosion, got " .. logged("needs " .. dust))
check(logs[1]:find("^razi%-protocol: "), "The line does not start with the mod name")
arig.data_final_fixes()
check(logged("needs " .. dust) == 3, "The repeated run touched the prototypes again")

raw = fresh()
raw["surface-property"] = {}
raw.recipe = {["quantum-processor"] = {}}
raw.explosion = {["nuke-effects-aquilo"] = {surface_conditions = {}}}
arig.data_final_fixes()
check(raw.recipe["quantum-processor"].surface_conditions == nil and #raw.explosion["nuke-effects-aquilo"].surface_conditions == 0
	and #logs == 0, "Something changed without the dust property")

raw = fresh()
raw["surface-property"] = {[dust] = {}}
raw.recipe = {["fusion-reactor"] = {}}
raw.explosion = {["nuke-effects-aquilo"] = {}}
arig.data_final_fixes()
check(raw.explosion["nuke-effects-aquilo"].surface_conditions == nil, "An explosion without conditions got some")
check(raw.recipe["quantum-processor"] == nil and logged("needs " .. dust) == 1, "Expected one line for the one recipe that exists")

-- bioluminescent_copies
local copies = require("prototypes.fixes.tenebris-prime.bioluminescent_copies")
local function tenebris_world()
	local world = fresh()
	world.planet = {tenebris = {surface_properties = {pressure = 3000}}}
	world["surface-property"] = {pressure = {default_value = 101}, gravity = {default_value = 10}}
	world.recipe = {}
	world.technology = {}
	world.item = {}
	return world
end
local function infusion(ingredients)
	return {categories = {"bioinfusion"}, ingredients = ingredients or {{type = "item", name = "iron-plate", amount = 1}}}
end

raw = tenebris_world()
raw["assembling-machine"] = {
	["chemical-plant"] = {crafting_categories = {"chemistry", "vulcanization"}},
	["bioluminescent-chemical-plant"] = {bioluminescent = true, crafting_categories = {"chemistry"}},
	["furnace"] = {crafting_categories = {"smelting"}},
	["bioluminescent-furnace"] = {bioluminescent = true, crafting_categories = {"smelting"}},
	["bioluminescent-orphan"] = {bioluminescent = true, crafting_categories = {"smelting"}},
	["plain"] = {crafting_categories = {"crafting"}},
	["bioluminescent-plain"] = {crafting_categories = {"crafting", "extra"}},
}
copies.data_final_fixes()
---@type any
local plant = raw["assembling-machine"]
check(plant["bioluminescent-chemical-plant"].crafting_categories[2] == "vulcanization"
	and #plant["bioluminescent-chemical-plant"].crafting_categories == 2, "The copy did not take the categories of its base")
check(plant["bioluminescent-chemical-plant"].crafting_categories ~= plant["chemical-plant"].crafting_categories,
	"The copy shares the list of its base")
check(plant["bioluminescent-orphan"].crafting_categories[1] == "smelting", "A copy without a base was changed")
check(#plant["bioluminescent-plain"].crafting_categories == 2, "A prototype that is not a Tenebris copy was changed")
check(logged("bioluminescent-chemical-plant takes the crafting categories of chemical-plant") == 1
	and logged("takes the crafting categories") == 1, "Expected one line, for the one copy that was behind")
check(logs[1]:find("^razi%-protocol: "), "The line does not start with the mod name")
copies.data_final_fixes()
check(logged("takes the crafting categories") == 1, "The repeated run touched the copy again")

-- hidden bioinfusion recipes
raw = tenebris_world()
raw["assembling-machine"] = {
	["bound"] = {surface_conditions = {{property = "pressure", min = 800000}}},
	["bioluminescent-bound"] = {bioluminescent = true},
	["gravity-bound"] = {surface_conditions = {{property = "gravity", min = 8, max = 9}}},
	["bioluminescent-gravity-bound"] = {bioluminescent = true},
	["near"] = {surface_conditions = {{property = "pressure", min = 1000, max = 4000}}},
	["bioluminescent-near"] = {bioluminescent = true},
	["free"] = {},
	["bioluminescent-free"] = {bioluminescent = true},
	["agricultural"] = {surface_conditions = {{property = "gravity", min = 8, max = 9}}},
	["bioluminescent-agricultural"] = {bioluminescent = true},
	["done"] = {surface_conditions = {{property = "pressure", min = 800000}}},
	["bioluminescent-done"] = {bioluminescent = true},
}
raw.recipe = {
	["bioluminescent-bound"] = infusion(),
	["bioluminescent-gravity-bound"] = infusion(),
	["bioluminescent-near"] = infusion(),
	["bioluminescent-free"] = infusion(),
	-- written by hand by Tenebris for the copy, not the bioinfusion of it
	["bio-agricultural"] = {categories = {"crafting"}, ingredients = {}},
	["bioluminescent-agricultural"] = {categories = {"crafting"}, ingredients = {}},
	["bioluminescent-done"] = {categories = {"bioinfusion"}, hidden = true, ingredients = {}},
}
raw.technology = {
	["bio-tech"] = {effects = {
		{type = "unlock-recipe", recipe = "bioluminescent-bound"},
		{type = "unlock-recipe", recipe = "bioluminescent-free"},
		{type = "unlock-recipe", recipe = "bioluminescent-gravity-bound"},
		{type = "unlock-recipe", recipe = "bioluminescent-agricultural"},
		{type = "nothing"},
	}},
	["no-effects"] = {},
}
copies.data_final_fixes()
---@type any
local recipes = raw.recipe
check(recipes["bioluminescent-bound"].hidden == true and recipes["bioluminescent-bound"].enabled == false,
	"The recipe of a copy whose base needs another pressure was not hidden")
check(recipes["bioluminescent-gravity-bound"].hidden == true, "The recipe of a copy whose base needs another gravity stayed")
check(recipes["bioluminescent-near"].hidden == nil, "A copy whose base works on Tenebris was hidden")
check(recipes["bioluminescent-free"].hidden == nil, "A copy whose base has no conditions was hidden")
check(recipes["bioluminescent-agricultural"].hidden == nil, "A recipe written by hand for a copy was hidden")
---@type any
local effects = raw.technology["bio-tech"].effects
check(#effects == 3 and effects[1].recipe == "bioluminescent-free" and effects[2].recipe == "bioluminescent-agricultural"
	and effects[3].type == "nothing", "The unlocks of the hidden recipes were not removed, or others were")
check(logged("can no longer be made: its base cannot work on Tenebris") == 2, "Expected a line for each of the two hidden recipes")
check(logged("bioluminescent-done") == 0, "A recipe that was hidden already was logged")

-- ingredients nothing makes
raw = tenebris_world()
raw["assembling-machine"] = {
	["gone"] = {}, ["bioluminescent-gone"] = {bioluminescent = true},
	["made"] = {}, ["bioluminescent-made"] = {bioluminescent = true},
	["shown"] = {}, ["bioluminescent-shown"] = {bioluminescent = true},
	["wet"] = {}, ["bioluminescent-wet"] = {bioluminescent = true},
}
raw.item = {
	gone = {hidden = true}, made = {hidden = true}, shown = {}, wet = {hidden = true},
}
raw.recipe = {
	["bioluminescent-gone"] = infusion({{type = "item", name = "gone", amount = 1}}),
	["bioluminescent-made"] = infusion({{type = "item", name = "made", amount = 1}}),
	["bioluminescent-shown"] = infusion({{type = "item", name = "shown", amount = 1}}),
	["bioluminescent-wet"] = infusion({{type = "fluid", name = "wet", amount = 1}}),
	["make-made"] = {results = {{type = "item", name = "made", amount = 1}}},
	["hidden-make-gone"] = {hidden = true, results = {{type = "item", name = "gone", amount = 1}}},
	["fluid-gone"] = {results = {{type = "fluid", name = "gone", amount = 1}}},
}
raw.technology = {["t"] = {effects = {{type = "unlock-recipe", recipe = "bioluminescent-gone"}}}}
copies.data_final_fixes()
recipes = raw.recipe
check(recipes["bioluminescent-gone"].hidden == true and recipes["bioluminescent-gone"].enabled == false,
	"The recipe asking for an item nothing makes was not hidden")
check(#raw.technology["t"].effects == 0, "The unlock of the hidden recipe stayed")
check(recipes["bioluminescent-made"].hidden == nil, "An item that a visible recipe makes counted as lost")
check(recipes["bioluminescent-shown"].hidden == nil, "An item that is not hidden counted as lost")
check(recipes["bioluminescent-wet"].hidden == nil, "A fluid ingredient counted as lost")
check(logged("its ingredient gone is hidden and no recipe makes it") == 1, "Expected one line for the lost ingredient")

-- no Tenebris, no copies, no tables
raw = fresh()
raw["assembling-machine"] = {
	["chemical-plant"] = {crafting_categories = {"chemistry", "vulcanization"}},
	["bioluminescent-chemical-plant"] = {bioluminescent = true, crafting_categories = {"chemistry"}},
}
copies.data_final_fixes()
check(#raw["assembling-machine"]["bioluminescent-chemical-plant"].crafting_categories == 1 and #logs == 0,
	"The copies were changed on a map without Tenebris")
raw = fresh()
raw.planet = {tenebris = {}}
copies.data_final_fixes()
check(#logs == 0 and next(raw) == "planet", "A repair logged or created a table on a map without copies")

-- variant_surface_conditions: copies take the conditions of their bases
local variants = require("prototypes.fixes.common.variant_surface_conditions")
raw = fresh()
variants.data_final_fixes()
check(#logs == 0 and next(raw) == nil, "The pass logged or created a table without prototypes")

raw = fresh()
local mad_ai = {{property = "mad-ai", max = 0}}
raw.furnace = {
	recycler = {name = "recycler", surface_conditions = mad_ai},
	["steam-recycler"] = {name = "steam-recycler", surface_conditions = {{property = "mad-ai", max = 0}, {property = "pressure", min = 2}}},
}
raw["assembling-machine"] = {
	["recycler__rigor-module"] = {name = "recycler__rigor-module", surface_conditions = {{property = "pressure", min = 5}}},
	["steam-recycler__rigor-module"] = {name = "steam-recycler__rigor-module",
		surface_conditions = {{property = "mad-ai", max = 0}, {property = "pressure", min = 2}}},
}
raw["straight-rail"] = {
	["straight-rail"] = {name = "straight-rail", surface_conditions = {{property = "gravity", min = 1}}},
	["straight-rail-minimal"] = {name = "straight-rail-minimal", surface_conditions = {{property = "gravity", min = 0.1}}},
	["lonely-rail-minimal"] = {name = "lonely-rail-minimal", surface_conditions = {{property = "gravity", min = 0.1}}},
	-- a base without conditions leaves its copy alone
	["free-rail"] = {name = "free-rail"},
	["free-rail-minimal"] = {name = "free-rail-minimal", surface_conditions = {{property = "gravity", min = 0.1}}},
}
variants.data_final_fixes()
---@type any
local recycler = raw["assembling-machine"]["recycler__rigor-module"].surface_conditions
check(#recycler == 2 and recycler[1].property == "mad-ai" and recycler[1].max == 0 and recycler[2].property == "pressure"
	and recycler[2].min == 5, "The recycler copy did not take the ban, or lost a condition of its own")
check(raw["assembling-machine"]["steam-recycler__rigor-module"].surface_conditions[1].max == 0
	and #raw["assembling-machine"]["steam-recycler__rigor-module"].surface_conditions == 2,
	"A copy that has the conditions of its base was rebuilt")
---@type any
local rail = raw["straight-rail"]["straight-rail-minimal"].surface_conditions
check(#rail == 1 and rail[1].property == "gravity" and rail[1].min == 1, "The minimal rail did not take the gravity of the vanilla rail")
check(raw["straight-rail"]["lonely-rail-minimal"].surface_conditions[1].min == 0.1, "A copy without a base was changed")
check(raw["straight-rail"]["free-rail-minimal"].surface_conditions[1].min == 0.1, "A base without conditions changed its copy")
check(logged("recycler__rigor-module takes the surface conditions of recycler") == 1
	and logged("straight-rail-minimal takes the surface conditions of straight-rail") == 1
	and logged("takes the surface conditions") == 2, "Expected a line for each of the two copies that were behind, got " .. logged("takes the surface conditions"))
check(logs[1]:find("^razi%-protocol: "), "The line does not start with the mod name")
variants.data_final_fixes()
check(logged("takes the surface conditions") == 2, "The repeated run touched the copies again")

raw = fresh()
raw.roboport = {
	["roboport"] = {name = "roboport", surface_conditions = {{property = "dust", max = 50}}},
	["roboport-logistic-mode"] = {name = "roboport-logistic-mode", surface_conditions = {{property = "pressure", min = 3}}},
	["tellus-roboport-2"] = {name = "tellus-roboport-2"},
	["other-roboport"] = {name = "other-roboport", surface_conditions = {{property = "dust", max = 9}}},
	["other-roboport-logistic-mode"] = {name = "other-roboport-logistic-mode"},
}
variants.data_final_fixes()
check(#raw.roboport["roboport-logistic-mode"].surface_conditions == 2, "The roboport mode did not take the conditions of its base")
check(raw.roboport["tellus-roboport-2"].surface_conditions[1].max == 50, "The Tellus roboport did not take the conditions of the roboport")
check(raw.roboport["other-roboport-logistic-mode"].surface_conditions == nil, "A roboport that is not in the list was changed")
check(logged("takes the surface conditions of roboport") == 2, "Expected a line for each of the two roboport copies")

print("test_mod_fixes_copies_conditions: ok")
