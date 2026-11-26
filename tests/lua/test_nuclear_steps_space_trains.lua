package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local function has_condition(conditions, property)
	for _, condition in pairs(conditions or {}) do
		if condition.property == property then
			return condition
		end
	end
end

local function has_log(logs, expected)
	for _, message in ipairs(logs) do
		if message == expected then
			return true
		end
	end
	return false
end

local function count_logs(logs, expected)
	local count = 0
	for _, message in ipairs(logs) do
		if message == expected then
			count = count + 1
		end
	end
	return count
end

local function space_item(result)
	return {
		place_as_tile = {
			result = result,
			invert = true,
			condition = { layers = { empty_space = true } },
		},
	}
end

local nuclear_rule = {
	colliding_tiles = { layers = { forbid_space_train = true } },
}

local function make_world(options)
	options = options or {}
	local raw = {
		["collision-layer"] = options.no_layer and {} or { forbid_space_train = { name = "forbid_space_train" } },
		["surface-property"] = options.no_cerys and {} or {
			["cerys-ambient-radiation"] = { name = "cerys-ambient-radiation" },
		},
		tile = {
			["space-platform-foundation"] = {
				collision_mask = { layers = { ground_tile = true, forbid_space_train = true } },
			},
			["low-density-space-platform-foundation"] = {
				collision_mask = { layers = { ground_tile = true, custom_layer = true } },
			},
			["haronite-plate"] = { collision_mask = { layers = { ground_tile = true } } },
			["heavy-space-platform-foundation"] = { collision_mask = { layers = { ground_tile = true } } },
			landfill = { collision_mask = { layers = { ground_tile = true } } },
			["tile-with-default-mask"] = {},
		},
		item = {
			["space-platform-foundation"] = space_item("space-platform-foundation"),
			["low-density-space-platform-foundation"] = space_item("low-density-space-platform-foundation"),
			["haronite-plate"] = space_item("haronite-plate"),
			["also-low-density-foundation"] = space_item("low-density-space-platform-foundation"),
			["heavy-space-platform-foundation"] = {
				place_as_tile = {
					result = "heavy-space-platform-foundation",
					invert = true,
					condition = { layers = { allow_heavy_space_platform_foundation = true } },
				},
			},
			landfill = { tile_condition = { "water" }, place_as_tile = { result = "landfill" } },
			["tile-with-default-mask"] = space_item("tile-with-default-mask"),
		},
		locomotive = {
			locomotive = { tile_buildability_rules = { nuclear_rule }, surface_conditions = {} },
			yir_loco_fut_red = {
				tile_buildability_rules = { nuclear_rule },
				surface_conditions = { { property = "rubia-wind-speed", max = 100 } },
			},
			with_gravity = {
				tile_buildability_rules = { nuclear_rule },
				surface_conditions = { { property = "gravity", min = 1 } },
			},
			with_radiation = {
				tile_buildability_rules = { nuclear_rule },
				surface_conditions = { { property = "cerys-ambient-radiation", max = 200 } },
			},
		},
		["straight-rail"] = {
			["straight-rail"] = {
				tile_buildability_rules = { nuclear_rule, { is_maraxsis_rule = true } },
				surface_conditions = {},
			},
		},
		["cargo-wagon"] = {
			["space-cargo-wagon"] = {
				tile_buildability_rules = { nuclear_rule },
				surface_conditions = { { property = "gravity", min = 1 } },
			},
		},
		["fluid-wagon"] = { ["fluid-wagon"] = { surface_conditions = {} } },
		["elevated-straight-rail"] = {
			["elevated-straight-rail"] = { tile_buildability_rules = { nuclear_rule }, surface_conditions = {} },
		},
	}

	local item_types = {
		"item",
		"tool",
		"capsule",
		"module",
		"ammo",
		"item-with-entity-data",
		"rail-planner",
		"repair-tool",
	}
	for _, item_type in ipairs(item_types) do
		raw[item_type] = raw[item_type] or {}
		local tile_name = "tile-from-" .. item_type
		raw.tile[tile_name] = { collision_mask = { layers = { ground_tile = true } } }
		raw[item_type]["item-from-" .. item_type] = space_item(tile_name)
	end

	local entity_types = {
		"locomotive",
		"cargo-wagon",
		"fluid-wagon",
		"artillery-wagon",
		"train-stop",
		"rail-signal",
		"rail-chain-signal",
		"straight-rail",
		"half-diagonal-rail",
		"curved-rail-a",
		"curved-rail-b",
		"legacy-straight-rail",
		"legacy-curved-rail",
	}
	for _, entity_type in ipairs(entity_types) do
		if entity_type ~= "locomotive" and entity_type ~= "straight-rail" then
			raw[entity_type] = raw[entity_type] or {}
			raw[entity_type]["test-" .. entity_type] = {
				tile_buildability_rules = { nuclear_rule },
				surface_conditions = {},
			}
		end
	end

	local logs = {}
	rawset(_G, "data", { raw = raw })
	rawset(_G, "mods", options.no_mod and {} or { ["nuclear-steps"] = "0.4.1" })
	rawset(_G, "log", function(message)
		logs[#logs + 1] = message
	end)
	package.loaded["prototypes.compatibility.nuclear-steps.space_trains"] = nil
	return { raw = raw, logs = logs }
end

local function run()
	require("prototypes.compatibility.nuclear-steps.space_trains").data_final_fixes()
end

local world = make_world()
run()

local tiles = world.raw.tile
check(tiles["space-platform-foundation"].collision_mask.layers.forbid_space_train == true,
	"space-platform-foundation keeps its existing train-forbid layer")
check(tiles["low-density-space-platform-foundation"].collision_mask.layers.forbid_space_train == true,
	"low-density foundation gains forbid_space_train")
check(tiles["low-density-space-platform-foundation"].collision_mask.layers.custom_layer == true,
	"existing low-density foundation layers stay")
check(tiles["haronite-plate"].collision_mask.layers.forbid_space_train == true,
	"Rabbasca platform tile gains forbid_space_train")
check(tiles["heavy-space-platform-foundation"].collision_mask.layers.forbid_space_train == nil,
	"heavy foundation placement condition is not treated as empty space")
check(tiles.landfill.collision_mask.layers.forbid_space_train == nil,
	"landfill's legacy tile condition is not treated as empty space")
check(tiles["tile-with-default-mask"].collision_mask == nil, "a tile without collision_mask stays unchanged")
check(has_log(world.logs,
	"razi-protocol: nuclear-steps: tile low-density-space-platform-foundation forbids trains without heavy foundation"),
	"the low-density foundation change is logged")
check(has_log(world.logs,
	"razi-protocol: nuclear-steps: tile tile-with-default-mask has the default collision mask, left as is"),
	"a tile with no collision mask is logged")
check(not has_log(world.logs,
	"razi-protocol: nuclear-steps: tile space-platform-foundation forbids trains without heavy foundation"),
	"an existing layer does not produce a change log")
check(count_logs(world.logs,
	"razi-protocol: nuclear-steps: tile low-density-space-platform-foundation forbids trains without heavy foundation") == 1,
	"a tile referenced by multiple items is changed and logged once")

for _, item_type in ipairs({ "tool", "capsule", "module", "ammo", "item-with-entity-data", "rail-planner", "repair-tool" }) do
	local tile_name = "tile-from-" .. item_type
	local tile = tiles[tile_name]
	check(tile and tile.collision_mask and tile.collision_mask.layers
		and tile.collision_mask.layers.forbid_space_train == true,
		"empty-space item type " .. item_type .. " is scanned")
end

local entities = world.raw
local locomotive = entities.locomotive
local vanilla_radiation = has_condition(locomotive.locomotive.surface_conditions, "cerys-ambient-radiation")
check(vanilla_radiation and vanilla_radiation.max == 300,
	"the vanilla locomotive gets the Cerys condition")
local yir_radiation = has_condition(locomotive.yir_loco_fut_red.surface_conditions, "cerys-ambient-radiation")
check(yir_radiation and yir_radiation.max == 300
	and has_condition(locomotive.yir_loco_fut_red.surface_conditions, "rubia-wind-speed"),
	"YIR locomotives keep their other condition and gain the Cerys condition")
check(has_condition(locomotive.with_gravity.surface_conditions, "cerys-ambient-radiation") == nil,
	"an existing gravity condition prevents adding the Cerys condition")
local existing_radiation = has_condition(locomotive.with_radiation.surface_conditions, "cerys-ambient-radiation")
check(existing_radiation and existing_radiation.max == 200,
	"an existing Cerys condition stays unchanged")
local rail_rules = entities["straight-rail"]["straight-rail"].tile_buildability_rules
check(#rail_rules == 2 and rail_rules[1] == nuclear_rule and rail_rules[2].is_maraxsis_rule == true,
	"Nuclear Steps and Maraxsis tile rules stay intact")
local rail_radiation = has_condition(entities["straight-rail"]["straight-rail"].surface_conditions,
	"cerys-ambient-radiation")
check(rail_radiation and rail_radiation.max == 300, "the straight rail gets the Cerys condition")
check(has_condition(entities["cargo-wagon"]["space-cargo-wagon"].surface_conditions,
	"cerys-ambient-radiation") == nil, "a cargo wagon with gravity stays unchanged")
check(has_condition(entities["elevated-straight-rail"]["elevated-straight-rail"].surface_conditions,
	"cerys-ambient-radiation") == nil, "an elevated rail outside the supported types stays unchanged")
check(has_condition(entities["fluid-wagon"]["fluid-wagon"].surface_conditions,
	"cerys-ambient-radiation") == nil, "a fluid wagon without a Nuclear Steps rule stays unchanged")
check(has_log(world.logs, "razi-protocol: nuclear-steps: locomotive: off Cerys for 2 prototypes"),
	"the locomotive changes are counted in the log")

for _, entity_type in ipairs({
	"cargo-wagon", "fluid-wagon", "artillery-wagon", "train-stop", "rail-signal", "rail-chain-signal",
	"half-diagonal-rail", "curved-rail-a", "curved-rail-b", "legacy-straight-rail", "legacy-curved-rail",
}) do
	local entity = world.raw[entity_type]["test-" .. entity_type]
	if not entity then
		error("missing test prototype for " .. entity_type, 2)
	end
	local condition = has_condition(entity.surface_conditions, "cerys-ambient-radiation")
	check(condition and condition.max == 300,
		"Nuclear Steps prototype type " .. entity_type .. " gets the Cerys condition")
end

-- Without Cerys, foundation tiles are still fixed and train surface conditions stay untouched.
world = make_world({ no_cerys = true })
run()
check(world.raw.tile["low-density-space-platform-foundation"].collision_mask.layers.forbid_space_train == true,
	"foundation tiles are fixed without Cerys")
check(has_condition(world.raw.locomotive.locomotive.surface_conditions, "cerys-ambient-radiation") == nil,
	"train surface conditions stay unchanged without Cerys")
check(not has_log(world.logs, "razi-protocol: nuclear-steps: locomotive: off Cerys for 2 prototypes"),
	"no Cerys surface-property means no Cerys log")

-- Without Nuclear Steps or its collision layer, both passes are inert.
for _, options in ipairs({ { no_mod = true }, { no_layer = true } }) do
	world = make_world(options)
	run()
	check(world.raw.tile["low-density-space-platform-foundation"].collision_mask.layers.forbid_space_train == nil,
		"foundation tiles stay unchanged without Nuclear Steps and its layer")
	check(has_condition(world.raw.locomotive.locomotive.surface_conditions, "cerys-ambient-radiation") == nil,
		"train surface conditions stay unchanged without Nuclear Steps and its layer")
	check(#world.logs == 0, "the pass is silent without Nuclear Steps and its layer")
end

print("test_nuclear_steps_space_trains: ok")
