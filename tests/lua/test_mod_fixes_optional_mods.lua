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

-- The prototype `name` of the type `kind` in the current mock, without the type inference of the editor.
---@return any
local function proto(kind, name)
	---@type any
	local list = _G.data.raw[kind]
	return list and list[name]
end

---@param kind string
---@param name string
---@param value any
local function set_proto(kind, name, value)
	---@type any
	local list = _G.data.raw[kind]
	list[name] = value
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
local pristine = proto("recipe", "filter-heavy-oil-pristine").results[2]
check(pristine.amount_min == 1 and pristine.amount_max == 5, "The coal range of the pristine filter was not turned")
pristine = proto("recipe", "filter-heavy-oil-pristine__rigor_module_mod__2").results[2]
check(pristine.amount_min == 1 and pristine.amount_max == 5, "The coal range of the rigor copy was not turned")
check(same(raw.recipe["filter-heavy-oil-pristine__rigor_module_mod__3"], filter_before["filter-heavy-oil-pristine__rigor_module_mod__3"])
	and same(raw.recipe["filter-heavy-oil"], filter_before["filter-heavy-oil"])
	and same(raw.recipe["filter-heavy-oil-pristine-other"], filter_before["filter-heavy-oil-pristine-other"]),
	"A recipe that was right or that is not the pristine filter was changed")
---@type any
local servofish_effects = proto("technology", "pristine-servofish").effects
check(#servofish_effects == 4 and servofish_effects[2].recipe == "filter-heavy-oil-pristine"
	and not servofish_effects[2].hidden and servofish_effects[3].recipe == "filter-heavy-oil-pristine__rigor_module_mod__2"
	and servofish_effects[3].hidden and servofish_effects[4].recipe == "filter-heavy-oil-pristine__rigor_module_mod__3"
	and servofish_effects[4].hidden, "The pristine filter and its rigor copies are not unlocked by pristine-servofish")
check(#proto("technology", "water-advanced").effects == 1, "Another technology was changed")
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
check(#logs == 0 and #proto("technology", "water-advanced").effects == 1, "An unlocked recipe was unlocked again")
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
local circuit_effects = proto("technology", "advanced-circuit").effects
check(#circuit_effects == 1 and circuit_effects[1].recipe == "other-recipe", "The unlock stayed with advanced-circuit")
---@type any
local coconut_effects = proto("technology", "coconut-processing-technology").effects
check(#coconut_effects == 2 and coconut_effects[2].recipe == "pelagos-electronic-components",
	"The recipe is not unlocked by the technology of the coconuts")
check(raw.recipe["other-recipe"].enabled == true, "Another recipe was disabled")
check(logged("razi-protocol: pelagos-electronic-components is unlocked by coconut-processing-technology, not by "
	.. "advanced-circuit") == 1 and #logs == 1, "Expected one line")
pelagos_recipe_gates.data_final_fixes()
check(#logs == 1 and #coconut_effects == 2 and #circuit_effects == 1, "The repeated run changed things again")
raw = gates_data()
set_proto("technology", "coconut-processing-technology", nil)
pelagos_recipe_gates.data_final_fixes()
check(raw.recipe["pelagos-electronic-components"].enabled == true and #proto("technology", "advanced-circuit").effects == 2
	and #logs == 0, "The recipe lost its only unlock without the technology of the coconuts")
raw = gates_data()
raw.recipe["pelagos-electronic-components"] = nil
pelagos_recipe_gates.data_final_fixes()
check(#proto("technology", "advanced-circuit").effects == 2 and #proto("technology", "coconut-processing-technology").effects == 1
	and #logs == 0, "A technology was changed without the recipe")
raw = fresh()
pelagos_recipe_gates.data_final_fixes()
check(next(raw) == nil and #logs == 0, "Something changed without Pelagos")

-- Cerys-Moon-of-Fulgora roboport_pressure
local roboport_pressure = require("prototypes.fixes.Cerys-Moon-of-Fulgora.roboport_pressure")
local function roboport(min, max, extra)
	local conditions = {{property = "pressure", min = min, max = max}}
	for _, condition in ipairs(extra or {}) do
		conditions[#conditions + 1] = condition
	end

	return {surface_conditions = conditions}
end
local function pressure_data()
	local result = fresh()
	result["mod-data"] = {["maraxsis-constants"] = {data = {PRESSURE_DOMES = {
		["maraxsis-pressure-dome"] = {lamp = "maraxsis-lamp", pressure_dome = "maraxsis-pressure-dome",
			regulator = "maraxsis-regulator"},
		["no-lamp-dome"] = {lamp = "missing-lamp", pressure_dome = "no-lamp-dome", regulator = "no-lamp-regulator"},
	}}}}
	result.lamp = {["maraxsis-lamp"] = roboport(200000, 800000)}
	result.roboport = {
		["maraxsis-pressure-dome"] = roboport(5, nil),
		["maraxsis-pressure-dome-logistic-mode"] = roboport(5, nil),
		["maraxsis-pressure-dome-construction-mode"] = roboport(5, nil),
		["maraxsis-regulator"] = roboport(5, nil, {{property = "dust", max = 0}}),
		["maraxsis-regulator-logistic-mode"] = roboport(5, nil),
		["maraxsis-regulator-construction-mode"] = roboport(200000, 800000),
		["no-lamp-dome"] = roboport(5, nil),
		["no-lamp-regulator"] = roboport(5, nil),
		["roboport"] = roboport(5, nil),
		["bioluminescent-roboport"] = roboport(5, 3000),
		["bioluminescent-kr-big-roboport"] = roboport(3000, 3000),
		["bioluminescent-no-pressure"] = {surface_conditions = {{property = "gravity", min = 1}}},
	}
	result.roboport["bioluminescent-roboport"].bioluminescent = true
	result.roboport["bioluminescent-kr-big-roboport"].bioluminescent = true
	result.roboport["bioluminescent-no-pressure"].bioluminescent = true
	result.roboport["bioluminescent-no-max"] = roboport(5, nil)
	result.roboport["bioluminescent-no-max"].bioluminescent = true

	return result
end
raw = pressure_data()
local pressure_before = deepcopy(raw.roboport)
roboport_pressure.data_final_fixes()
for _, name in ipairs({"maraxsis-pressure-dome", "maraxsis-pressure-dome-logistic-mode",
	"maraxsis-pressure-dome-construction-mode", "maraxsis-regulator", "maraxsis-regulator-logistic-mode"}) do
	check(raw.roboport[name].surface_conditions[1].min == 200000, "The dome roboport did not get the pressure of the lamp: " .. name)
	check(logged("razi-protocol: " .. name .. " pressure min 5 -> 200000") == 1, "Expected one line for " .. name)
end
check(raw.roboport["maraxsis-regulator"].surface_conditions[2].property == "dust", "The other condition was changed")
check(raw.roboport["bioluminescent-roboport"].surface_conditions[1].min == 3000
	and logged("razi-protocol: bioluminescent-roboport pressure min 5 -> 3000") == 1, "The bioluminescent roboport is relaxed")
check(same(raw.roboport["maraxsis-regulator-construction-mode"], pressure_before["maraxsis-regulator-construction-mode"])
	and same(raw.roboport["no-lamp-dome"], pressure_before["no-lamp-dome"])
	and same(raw.roboport["no-lamp-regulator"], pressure_before["no-lamp-regulator"])
	and same(raw.roboport.roboport, pressure_before.roboport)
	and same(raw.roboport["bioluminescent-kr-big-roboport"], pressure_before["bioluminescent-kr-big-roboport"])
	and same(raw.roboport["bioluminescent-no-pressure"], pressure_before["bioluminescent-no-pressure"])
	and same(raw.roboport["bioluminescent-no-max"], pressure_before["bioluminescent-no-max"]),
	"A roboport that has to stay as it is was changed")
check(#logs == 6, "A roboport that was not changed was logged")
roboport_pressure.data_final_fixes()
check(#logs == 6, "The repeated run logged again")
raw = pressure_data()
raw["mod-data"] = nil
roboport_pressure.data_final_fixes()
check(raw.roboport["maraxsis-pressure-dome"].surface_conditions[1].min == 5
	and raw.roboport["bioluminescent-roboport"].surface_conditions[1].min == 3000 and #logs == 1,
	"Without Maraxsis only the bioluminescent roboports are expected to change")
raw = pressure_data()
raw.roboport = nil
roboport_pressure.data_final_fixes()
check(#logs == 0, "Something was logged without roboports")
raw = fresh()
roboport_pressure.data_final_fixes()
check(next(raw) == nil and #logs == 0, "Something changed without roboports")

-- moon-eneas construction_drone
local construction_drone = require("prototypes.fixes.moon-eneas.construction_drone")
local function drone_data()
	local drone_raw = fresh()
	_G.mods["moon-eneas"] = "1.0.10"
	drone_raw.technology = {["friend-tech"] = {effects = {}}}
	_G.data.extend = function(_, prototypes)
		for _, prototype in ipairs(prototypes) do
			drone_raw[prototype.type] = drone_raw[prototype.type] or {}
			drone_raw[prototype.type][prototype.name] = prototype
		end
	end
	return drone_raw
end
drone_data()
construction_drone.data_final_fixes()
local drone = proto("item", "Construction_Drone")
check(drone and drone.hidden and drone.hidden_in_factoriopedia and drone.stack_size == 1
	and drone.localised_name[1] == "item-name.razi-eneas-construction-drone",
	"Without Construction_Drones_Forked the hidden Construction_Drone item is missing")
check(logged("razi-protocol: Construction_Drone is added") == 1 and #logs == 1, "Expected one line for the item")
construction_drone.data_final_fixes()
check(#logs == 1, "The repeated run logged again")
raw = drone_data()
raw.item = {Construction_Drone = {type = "item", name = "Construction_Drone", stack_size = 50}}
local drone_before = deepcopy(raw.item)
construction_drone.data_final_fixes()
check(same(raw.item, drone_before) and #logs == 0, "The item of Construction_Drones_Forked was changed")
raw = drone_data()
_G.defines.prototypes.item["item-with-entity-data"] = 1
raw["item-with-entity-data"] = {Construction_Drone = {type = "item-with-entity-data", name = "Construction_Drone"}}
construction_drone.data_final_fixes()
check(raw.item == nil and #logs == 0, "A second Construction_Drone was made beside one of another item type")
raw = drone_data()
raw.technology = nil
construction_drone.data_final_fixes()
check(raw.item == nil and #logs == 0, "The item was made without friend-tech")
raw = drone_data()
_G.mods["moon-eneas"] = nil
construction_drone.data_final_fixes()
check(raw.item == nil and #logs == 0, "The item was made without Eneas")

print("mod fixes (optional mods): ok")
