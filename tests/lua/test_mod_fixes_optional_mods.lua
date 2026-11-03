---@diagnostic disable: missing-fields
-- Repairs of the data of mods that Razi lists as optional (prototypes/fixes/): Aircraft Space Age, Eneas, Pelagos and
-- Cerys, on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_mod_fixes_optional_mods.lua
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

local function same(left, right)
	if type(left) ~= "table" or type(right) ~= "table" then
		return left == right
	end
	for key, item in pairs(left) do
		if not same(item, right[key]) then
			return false
		end
	end
	for key in pairs(right) do
		if left[key] == nil then
			return false
		end
	end

	return true
end

---@return any
local function fresh()
	logs = {}
	local raw = {}
	rawset(_G, "data", {raw = raw})
	rawset(_G, "mods", {})
	rawset(_G, "defines", {prototypes = {item = {item = 1}, entity = {}}})
	return raw
end

local fixes = require("prototypes.fixes.init")

-- Nothing of the mods is installed: every repair is quiet and does not fail.
---@type any
local raw = fresh()
fixes.data_final_fixes()
check(#logs == 0 and next(raw) == nil, "A repair did something without its prototypes")
raw = fresh()
for _, name in ipairs({"recipe", "technology", "item", "car", "roboport", "lamp", "mod-data", "fuel-category"}) do
	raw[name] = {}
end
fixes.data_final_fixes()
check(#logs == 0, "A repair logged on empty prototype tables")

-- Aircraft-space-age vehicle_fuel
local vehicle_fuel = require("prototypes.fixes.Aircraft-space-age.vehicle_fuel")
local function plane(categories)
	return {type = "car", energy_source = {type = "burner", fuel_categories = categories}}
end
raw = fresh()
raw["fuel-category"] = {["kr-vehicle-fuel"] = {}}
raw.car = {
	gunship = plane({"chemical"}),
	["cargo-plane-carbon-fiber"] = plane({"chemical"}),
	["rubia-auto-variant-jet"] = plane({"chemical"}),
	["rubia-auto-variant-flying-fortress-carbon-fiber"] = plane({"chemical"}),
	["not-a-plane"] = plane({"chemical"}),
	jet = plane({"chemical", "kr-vehicle-fuel"}),
	tank = plane({"kr-vehicle-fuel"}),
	car = plane({"chemical"}),
	["not-a-burner"] = {type = "car", energy_source = {type = "electric"}},
	["no-energy"] = {type = "car"},
}
raw.car["flying-fortress"] = {type = "car", energy_source = {type = "burner"}}
raw.car["cargo-plane"] = plane({"nuclear"})
local others = deepcopy({raw.car.tank, raw.car.car, raw.car["not-a-plane"], raw.car["not-a-burner"],
	raw.car["no-energy"], raw.car["flying-fortress"], raw.car["cargo-plane"], raw.car.jet})
vehicle_fuel.data_final_fixes()
for _, name in ipairs({"gunship", "cargo-plane-carbon-fiber", "rubia-auto-variant-jet",
	"rubia-auto-variant-flying-fortress-carbon-fiber"}) do
	local categories = raw.car[name].energy_source.fuel_categories
	check(#categories == 2 and categories[1] == "chemical" and categories[2] == "kr-vehicle-fuel",
		"A plane does not take the vehicle fuel too: " .. name)
	check(logged("razi-protocol: " .. name .. " also takes kr-vehicle-fuel") == 1, "Expected one line for " .. name)
end
check(same(others, {raw.car.tank, raw.car.car, raw.car["not-a-plane"], raw.car["not-a-burner"],
	raw.car["no-energy"], raw.car["flying-fortress"], raw.car["cargo-plane"], raw.car.jet}),
	"A vehicle that is no plane, takes the fuel already or burns no chemical fuel was changed")
check(#logs == 4, "A vehicle that was not changed was logged")
vehicle_fuel.data_final_fixes()
check(#logs == 4 and #raw.car.gunship.energy_source.fuel_categories == 2, "The repeated run changed the planes again")
raw = fresh()
raw.car = {gunship = plane({"chemical"})}
vehicle_fuel.data_final_fixes()
check(#raw.car.gunship.energy_source.fuel_categories == 1 and #logs == 0, "A plane was changed without the K2 fuel")
raw = fresh()
raw["fuel-category"] = {["kr-vehicle-fuel"] = {}}
vehicle_fuel.data_final_fixes()
check(next(raw.car or {}) == nil and #logs == 0, "Something changed without cars")

-- moon-eneas recycling_enabled
local recycling_enabled = require("prototypes.fixes.moon-eneas.recycling_enabled")
raw = fresh()
raw.technology = {
	{effects = {{type = "unlock-recipe", recipe = "nuclear-scrap-recycling"},
		{type = "unlock-recipe", recipe = "cube-recycling"}, {type = "nothing"}}},
	{effects = {{type = "unlock-recipe", recipe = "plain-recycling"}, {type = "unlock-recipe", recipe = "hand-only"}}},
	{},
}
raw.recipe = {
	["nuclear-scrap-recycling"] = {categories = {"recycling", "hand-crafting"}, enabled = true},
	["cube-recycling"] = {categories = {"recycling", "hand-crafting"}},
	["plain-recycling"] = {categories = {"recycling"}, enabled = true},
	["hand-only"] = {categories = {"hand-crafting"}, enabled = true},
	["no-technology-recycling"] = {categories = {"recycling", "hand-crafting"}, enabled = true},
	["already-closed-recycling"] = {categories = {"recycling", "hand-crafting"}, enabled = false},
	["no-categories"] = {enabled = true},
}
local recycling_before = deepcopy(raw.recipe)
recycling_enabled.data_final_fixes()
check(raw.recipe["nuclear-scrap-recycling"].enabled == false and raw.recipe["cube-recycling"].enabled == false,
	"A recycling recipe that can be hand-crafted and that a technology unlocks stays enabled")
for _, name in ipairs({"plain-recycling", "hand-only", "no-technology-recycling", "already-closed-recycling",
	"no-categories"}) do
	check(same(raw.recipe[name], recycling_before[name]), "A recipe that has to stay as it is was changed: " .. name)
end
check(logged("razi-protocol: nuclear-scrap-recycling is disabled") == 1
	and logged("razi-protocol: cube-recycling is disabled") == 1 and #logs == 2, "Expected one line for each recipe")
recycling_enabled.data_final_fixes()
check(#logs == 2, "The repeated run logged again")
raw = fresh()
recycling_enabled.data_final_fixes()
check(next(raw) == nil and #logs == 0, "Something changed without recipes")

-- moon-eneas pristine_filter
local pristine_filter = require("prototypes.fixes.moon-eneas.pristine_filter")
local function filter_recipe(coal)
	return {results = {{name = "servofish"}, coal, {name = "stone", amount_min = 20, amount_max = 25}}}
end
raw = fresh()
raw.recipe = {
	["filter-heavy-oil-pristine"] = filter_recipe({name = "coal", amount_min = 5, amount_max = 1}),
	["filter-heavy-oil-pristine__rigor_module_mod__2"] = filter_recipe({name = "coal", amount_min = 5, amount_max = 1}),
	["filter-heavy-oil-pristine__rigor_module_mod__3"] = filter_recipe({name = "coal", amount_min = 1, amount_max = 5}),
	["filter-heavy-oil"] = filter_recipe({name = "coal", amount_min = 9, amount_max = 2}),
	["filter-heavy-oil-pristine-other"] = filter_recipe({name = "coal", amount_min = 9, amount_max = 2}),
}
raw.technology = {
	["pristine-servofish"] = {effects = {{type = "unlock-recipe", recipe = "pristine-servofish"}}},
	["water-advanced"] = {effects = {{type = "unlock-recipe", recipe = "filter-heavy-oil"}}},
}
raw["mod-data"] = {rigor_module_mod_recipe_table = {data = {["filter-heavy-oil-pristine"] = {
	"filter-heavy-oil-pristine", "filter-heavy-oil-pristine__rigor_module_mod__2",
	"filter-heavy-oil-pristine__rigor_module_mod__3", "missing-copy"}}}}
local filter_before = deepcopy(raw.recipe)
pristine_filter.data_final_fixes()
local pristine = raw.recipe["filter-heavy-oil-pristine"].results[2]
check(pristine.amount_min == 1 and pristine.amount_max == 5, "The coal range of the pristine filter was not turned")
pristine = raw.recipe["filter-heavy-oil-pristine__rigor_module_mod__2"].results[2]
check(pristine.amount_min == 1 and pristine.amount_max == 5, "The coal range of the rigor copy was not turned")
check(same(raw.recipe["filter-heavy-oil-pristine__rigor_module_mod__3"], filter_before["filter-heavy-oil-pristine__rigor_module_mod__3"])
	and same(raw.recipe["filter-heavy-oil"], filter_before["filter-heavy-oil"])
	and same(raw.recipe["filter-heavy-oil-pristine-other"], filter_before["filter-heavy-oil-pristine-other"]),
	"A recipe that was right or that is not the pristine filter was changed")
---@type any
local servofish_effects = raw.technology["pristine-servofish"].effects
check(#servofish_effects == 4 and servofish_effects[2].recipe == "filter-heavy-oil-pristine"
	and not servofish_effects[2].hidden and servofish_effects[3].recipe == "filter-heavy-oil-pristine__rigor_module_mod__2"
	and servofish_effects[3].hidden and servofish_effects[4].recipe == "filter-heavy-oil-pristine__rigor_module_mod__3"
	and servofish_effects[4].hidden, "The pristine filter and its rigor copies are not unlocked by pristine-servofish")
check(#raw.technology["water-advanced"].effects == 1, "Another technology was changed")
check(logged("razi-protocol: filter-heavy-oil-pristine makes 1 to 5 coal") == 1
	and logged("razi-protocol: filter-heavy-oil-pristine__rigor_module_mod__2 makes 1 to 5 coal") == 1
	and logged("razi-protocol: filter-heavy-oil-pristine is unlocked by pristine-servofish (+2 rigor copies)") == 1
	and #logs == 3, "Expected three lines")
pristine_filter.data_final_fixes()
check(#logs == 3 and #servofish_effects == 4, "The repeated run changed things again")
raw = fresh()
raw.recipe = {["filter-heavy-oil-pristine"] = filter_recipe({name = "coal", amount_min = 5, amount_max = 1})}
pristine_filter.data_final_fixes()
check(raw.recipe["filter-heavy-oil-pristine"].results[2].amount_min == 1 and #logs == 2
	and logged("technology pristine-servofish does not exist") == 1, "A missing technology was not reported")
raw = fresh()
raw.recipe = {["filter-heavy-oil-pristine"] = filter_recipe({name = "coal", amount_min = 1, amount_max = 5})}
raw.technology = {["water-advanced"] = {effects = {{type = "unlock-recipe", recipe = "filter-heavy-oil-pristine"}}}}
pristine_filter.data_final_fixes()
check(#logs == 0 and #raw.technology["water-advanced"].effects == 1, "An unlocked recipe was unlocked again")
raw = fresh()
pristine_filter.data_final_fixes()
check(next(raw) == nil and #logs == 0, "Something changed without recipes")

-- moon-eneas aquilo_data_card
local aquilo_data_card = require("prototypes.fixes.moon-eneas.aquilo_data_card")
raw = fresh()
raw.item = {
	["aquilo-data-card"] = {},
	["cargo-crate-aquilo-data-card"] = {},
	["gleba-data-card"] = {},
	["cargo-crate-gleba-data-card"] = {},
}
raw.recipe = {
	["cargo-crate-aquilo-data-card"] = {},
	["unpack-cargo-crate-aquilo-data-card"] = {hidden = false},
	["cargo-crate-gleba-data-card"] = {},
}
aquilo_data_card.data_final_fixes()
check(raw.item["aquilo-data-card"].hidden and raw.item["cargo-crate-aquilo-data-card"].hidden
	and raw.recipe["cargo-crate-aquilo-data-card"].hidden and raw.recipe["unpack-cargo-crate-aquilo-data-card"].hidden,
	"The Aquilo card, its crate or their recipes are not hidden")
check(raw.item["gleba-data-card"].hidden == nil and raw.item["cargo-crate-gleba-data-card"].hidden == nil
	and raw.recipe["cargo-crate-gleba-data-card"].hidden == nil, "The card of another planet was hidden")
check(logged("razi-protocol: aquilo-data-card is hidden") == 1
	and logged("razi-protocol: cargo-crate-aquilo-data-card is hidden") == 2
	and logged("razi-protocol: unpack-cargo-crate-aquilo-data-card is hidden") == 1 and #logs == 4,
	"Expected one line for each of the four hidden prototypes")
aquilo_data_card.data_final_fixes()
check(#logs == 4, "The repeated run logged again")
raw = fresh()
raw.item = {["aquilo-data-card"] = {}}
aquilo_data_card.data_final_fixes()
check(raw.item["aquilo-data-card"].hidden and #logs == 1, "The card was not hidden without Cargo Crates")
raw = fresh()
raw.item = {["gleba-data-card"] = {}}
raw.recipe = {["cargo-crate-aquilo-data-card"] = {}}
aquilo_data_card.data_final_fixes()
check(raw.recipe["cargo-crate-aquilo-data-card"].hidden == nil and #logs == 0, "Something was hidden without the card")
raw = fresh()
aquilo_data_card.data_final_fixes()
check(next(raw) == nil and #logs == 0, "Something changed without items")

-- pelagos recipe_gates
local pelagos_recipe_gates = require("prototypes.fixes.pelagos.recipe_gates")
local function gates_data()
	local result = fresh()
	result.recipe = {["pelagos-electronic-components"] = {enabled = true}, ["other-recipe"] = {enabled = true}}
	result.technology = {
		["advanced-circuit"] = {effects = {{type = "unlock-recipe", recipe = "pelagos-electronic-components"},
			{type = "unlock-recipe", recipe = "other-recipe"}}},
		["coconut-processing-technology"] = {effects = {{type = "unlock-recipe", recipe = "coconut-sealant"}}},
	}
	return result
end
raw = gates_data()
pelagos_recipe_gates.data_final_fixes()
check(raw.recipe["pelagos-electronic-components"].enabled == false, "The recipe is still enabled from the start")
---@type any
local circuit_effects = raw.technology["advanced-circuit"].effects
check(#circuit_effects == 1 and circuit_effects[1].recipe == "other-recipe", "The unlock stayed with advanced-circuit")
---@type any
local coconut_effects = raw.technology["coconut-processing-technology"].effects
check(#coconut_effects == 2 and coconut_effects[2].recipe == "pelagos-electronic-components",
	"The recipe is not unlocked by the technology of the coconuts")
check(raw.recipe["other-recipe"].enabled == true, "Another recipe was disabled")
check(logged("razi-protocol: pelagos-electronic-components is unlocked by coconut-processing-technology, not by "
	.. "advanced-circuit") == 1 and #logs == 1, "Expected one line")
pelagos_recipe_gates.data_final_fixes()
check(#logs == 1 and #coconut_effects == 2 and #circuit_effects == 1, "The repeated run changed things again")
raw = gates_data()
raw.technology["coconut-processing-technology"] = nil
pelagos_recipe_gates.data_final_fixes()
check(raw.recipe["pelagos-electronic-components"].enabled == true and #raw.technology["advanced-circuit"].effects == 2
	and #logs == 0, "The recipe lost its only unlock without the technology of the coconuts")
raw = gates_data()
raw.recipe["pelagos-electronic-components"] = nil
pelagos_recipe_gates.data_final_fixes()
check(#raw.technology["advanced-circuit"].effects == 2 and #raw.technology["coconut-processing-technology"].effects == 1
	and #logs == 0, "A technology was changed without the recipe")
raw = fresh()
pelagos_recipe_gates.data_final_fixes()
check(next(raw) == nil and #logs == 0, "Something changed without Pelagos")

print("mod fixes (optional mods): ok")
