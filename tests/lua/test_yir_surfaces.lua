---@diagnostic disable: lowercase-global
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
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

local module_name = "prototypes.compatibility.yi_railway.surface_conditions"

local function make_world(raw, no_mod)
	local logs = {}
	rawset(_G, "data", {raw = raw})
	rawset(_G, "mods", no_mod and {} or {yi_railway = "1.4.0"})
	rawset(_G, "log", function(message) logs[#logs + 1] = message end)
	package.loaded[module_name] = nil
	require(module_name).data_final_fixes()
	return logs
end

local function find_condition(conditions, property)
	for _, condition in pairs(conditions or {}) do
		if condition.property == property then
			return condition
		end
	end
end

local function contains(logs, message)
	for _, line in ipairs(logs) do
		if line == message then
			return true
		end
	end
	return false
end

local function equal(left, right)
	if type(left) ~= type(right) then
		return false
	end
	if type(left) ~= "table" then
		return left == right
	end
	for key, value in pairs(left) do
		if not equal(value, right[key]) then
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

-- Gravity mode adds the vanilla limit without removing other conditions or touching vanilla and unrelated trains.
local raw = {
	["surface-property"] = {gravity = {}},
	locomotive = {
		locomotive = {surface_conditions = {{property = "gravity", min = 1}}},
		yir_loco_fut_red = {surface_conditions = {{property = "rubia-wind-speed", max = 100}}},
		yir_loco_del_KR = {surface_conditions = {{property = "gravity", min = 0.5}}},
		["yellow-express"] = {},
	},
	["cargo-wagon"] = {
		["cargo-wagon"] = {surface_conditions = {{property = "gravity", min = 1}}},
		["bioluminescent-y_wagon_hopper_yellow"] = {surface_conditions = {{property = "pressure", min = 3000, max = 3000}}},
	},
	["fluid-wagon"] = {
		["fluid-wagon"] = {surface_conditions = {{property = "gravity", min = 1}}},
		y_wagon_tank_fm1 = {},
	},
}
local logs = make_world(raw)

local locomotive_gravity = find_condition(raw.locomotive.yir_loco_fut_red.surface_conditions, "gravity")
check(locomotive_gravity and locomotive_gravity.min == 1, "YIR locomotive gets the gravity minimum")
check(raw.locomotive.yir_loco_fut_red.surface_conditions[1].property == "rubia-wind-speed",
	"the locomotive keeps its existing surface condition")
local cargo_pressure = find_condition(raw["cargo-wagon"]["bioluminescent-y_wagon_hopper_yellow"].surface_conditions, "pressure")
local cargo_gravity = find_condition(raw["cargo-wagon"]["bioluminescent-y_wagon_hopper_yellow"].surface_conditions, "gravity")
check(cargo_pressure and cargo_pressure.min == 3000 and cargo_pressure.max == 3000 and cargo_gravity and cargo_gravity.min == 1,
	"the Tenebris cargo copy keeps pressure and gains gravity")
check(#raw["fluid-wagon"].y_wagon_tank_fm1.surface_conditions == 1
	and raw["fluid-wagon"].y_wagon_tank_fm1.surface_conditions[1].property == "gravity"
	and raw["fluid-wagon"].y_wagon_tank_fm1.surface_conditions[1].min == 1,
	"a fluid wagon without conditions gets only gravity")
check(raw.locomotive["yellow-express"].surface_conditions == nil, "an unrelated train is unchanged")
check(#raw.locomotive.locomotive.surface_conditions == 1, "the vanilla locomotive is unchanged")
check(raw.locomotive.yir_loco_del_KR.surface_conditions[1].min == 0.5,
	"an existing gravity condition is unchanged")
check(contains(logs, "razi-protocol: yi_railway: yir_loco_del_KR already has a gravity condition, left as is"),
	"an existing gravity condition is logged")
for _, train_type in ipairs({"locomotive", "cargo-wagon", "fluid-wagon"}) do
	check(contains(logs, "razi-protocol: yi_railway: " .. train_type .. ": gravity >= 1 for 1 prototypes"),
		train_type .. " change count is logged")
end

-- Nuclear-steps mode copies the vanilla tile rule and leaves the prototype's surface conditions alone.
local nuclear_rule = {{
	area = {{-0.4, -0.4}, {0.4, 0.4}},
	colliding_tiles = {layers = {forbid_space_train = true}},
}}
raw = {
	locomotive = {
		locomotive = {surface_conditions = {}, tile_buildability_rules = deepcopy(nuclear_rule)},
		yir_loco_fut_red = {surface_conditions = {{property = "rubia-wind-speed", max = 100}}},
	},
	["cargo-wagon"] = {
		["cargo-wagon"] = {surface_conditions = {}, tile_buildability_rules = deepcopy(nuclear_rule)},
		y_wagon_zement_gray = {tile_buildability_rules = {{colliding_tiles = {layers = {}}}}},
	},
}
logs = make_world(raw)
local loco_rules = raw.locomotive.yir_loco_fut_red.tile_buildability_rules
check(equal(loco_rules, nuclear_rule) and loco_rules ~= raw.locomotive.locomotive.tile_buildability_rules,
	"the YIR locomotive receives an independent copy of the vanilla rules")
check(#raw.locomotive.yir_loco_fut_red.surface_conditions == 1
	and raw.locomotive.yir_loco_fut_red.surface_conditions[1].property == "rubia-wind-speed",
	"nuclear-steps mode does not change surface conditions")
check(raw["cargo-wagon"].y_wagon_zement_gray.tile_buildability_rules[1].colliding_tiles.layers.forbid_space_train == nil,
	"a wagon with its own buildability rules is unchanged")
check(contains(logs, "razi-protocol: yi_railway: locomotive: the nuclear-steps space train rule for 1 prototypes"),
	"the nuclear-steps change count is logged")
check(contains(logs, "razi-protocol: yi_railway: y_wagon_zement_gray already has tile buildability rules, left as is"),
	"an existing buildability rule is logged")

-- The mode follows each vanilla prototype independently.
raw = {
	["surface-property"] = {gravity = {}},
	locomotive = {
		locomotive = {surface_conditions = {}, tile_buildability_rules = deepcopy(nuclear_rule)},
		yir_loco_fut_red = {},
	},
	["fluid-wagon"] = {
		["fluid-wagon"] = {surface_conditions = {{property = "gravity", min = 1}}},
		y_wagon_tank_fm1 = {},
	},
}
make_world(raw)
check(raw.locomotive.yir_loco_fut_red.tile_buildability_rules ~= nil
	and raw.locomotive.yir_loco_fut_red.surface_conditions == nil,
	"a locomotive follows its nuclear-steps vanilla prototype")
check(find_condition(raw["fluid-wagon"].y_wagon_tank_fm1.surface_conditions, "gravity").min == 1,
	"a fluid wagon follows its gravity vanilla prototype")

-- Without YIR or without the gravity property, the gravity-mode pass is silent and leaves prototypes alone.
raw = {
	["surface-property"] = {gravity = {}},
	locomotive = {locomotive = {}, yir_loco_fut_red = {}},
}
logs = make_world(raw, true)
check(raw.locomotive.yir_loco_fut_red.surface_conditions == nil and #logs == 0,
	"the pass is inert without YIR")
raw = {
	["surface-property"] = {},
	locomotive = {locomotive = {}, yir_loco_fut_red = {}},
}
logs = make_world(raw)
check(raw.locomotive.yir_loco_fut_red.surface_conditions == nil and #logs == 0,
	"gravity mode is inert when the gravity property is absent")

print("test_yir_surfaces: ok")
