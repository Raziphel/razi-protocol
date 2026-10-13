-- Small engine-free fixtures for the compatibility guards in this repository.
package.path = "./?.lua;./?/init.lua;" .. package.path

local function ok(condition, message)
	if not condition then
		error(message, 2)
	end
end

local function fresh(module_name)
	package.loaded[module_name] = nil
	return require(module_name)
end

local function mock_data(raw)
	return {
		raw = raw,
		extend = function(self, definitions)
			for _, definition in ipairs(definitions) do
				self.raw[definition.type] = self.raw[definition.type] or {}
				self.raw[definition.type][definition.name] = definition
			end
		end
	}
end

local function test_unrelated_technologies_stay_visible()
	rawset(_G, "mods", {LithiumBattery = "1.0"})
	rawset(_G, "settings", {startup = {["razi-hide-redundant-assembler-tiers"] = {value = true}}})
	data = mock_data({
		["assembling-machine"] = {
			["assembling-machine-3"] = {name = "assembling-machine-3", next_upgrade = "assembling-machine-4"},
			["assembling-machine-4"] = {name = "assembling-machine-4"}
		},
		item = {["assembling-machine-4"] = {place_result = "assembling-machine-4"}},
		recipe = {["assembling-machine-4"] = {enabled = true}},
		technology = {
			["unrelated-empty"] = {name = "unrelated-empty", effects = {}},
			["only-machine-unlock"] = {name = "only-machine-unlock", effects = {
				{type = "unlock-recipe", recipe = "assembling-machine-4"}
			}},
			["used-machine-unlock"] = {name = "used-machine-unlock", effects = {
				{type = "unlock-recipe", recipe = "assembling-machine-4"}
			}},
			["dependent"] = {name = "dependent", prerequisites = {"used-machine-unlock"}, effects = {}}
		}
	})

	fresh("prototypes.compat.redundant_progression").data_final_fixes()
	ok(not data.raw.technology["unrelated-empty"].hidden, "Unrelated empty tech was hidden")
	ok(data.raw.technology["only-machine-unlock"].hidden, "Orphaned unlock tech remained visible")
	ok(not data.raw.technology["used-machine-unlock"].hidden, "Prerequisite tech was hidden")
	ok(data.raw["assembling-machine"]["assembling-machine-3"].next_upgrade == nil,
		"Invalid next_upgrade was retained")
end

local function test_infrastructure_name_matching()
	rawset(_G, "mods", {})
	rawset(_G, "settings", {})
	data = mock_data({
		item = {
			projectile = {},
			["demo-projectile"] = {},
			["straight-rail"] = {},
			["elevated-rail-ramp"] = {},
			["stone-brick"] = {place_as_tile = {result = "stone-path"}},
			["refined-concrete"] = {},
			railgun = {}
		},
		recipe = {
			projectile = {results = {{name = "projectile"}}},
			["straight-rail"] = {results = {{name = "straight-rail"}}},
			["elevated-rail-ramp"] = {results = {{name = "elevated-rail-ramp"}}},
			["refined-concrete"] = {results = {{name = "refined-concrete"}}},
			railgun = {results = {{name = "railgun"}}}
		},
		["item-group"] = {},
		["item-subgroup"] = {}
	})

	fresh("prototypes.compat.logistics_cleanup").data_final_fixes()
	local items, recipes = data.raw.item, data.raw.recipe
	ok(items.projectile.subgroup == nil, "A projectile was moved to the floor tab")
	ok(items["demo-projectile"].subgroup == nil, "Projectile suffix mistaken for tile")
	ok(recipes.projectile.subgroup == nil, "Projectile recipe was moved to the floor tab")
	ok(items["straight-rail"].subgroup == "razi-infrastructure-rail", "Rails not grouped")
	ok(items["elevated-rail-ramp"].subgroup == "razi-infrastructure-rail", "Ramp not grouped")
	ok(items["stone-brick"].subgroup == "razi-infrastructure-surfaces", "Tiles not grouped")
	ok(items["refined-concrete"].subgroup == "razi-infrastructure-surfaces", "Concrete not grouped")
	ok(items.railgun.subgroup == "gun", "Railgun incorrectly classified as infrastructure")
	ok(recipes.railgun.subgroup == "gun", "Railgun recipe incorrectly classified")
end

local function test_nexus_migration_scope()
	---@type fun(event: table)|nil
	local callback = nil
	rawset(_G, "script", {
		active_mods = {["Nexus-Updated"] = "1.0.0"},
		on_init = function() end,
		on_configuration_changed = function(fn) callback = fn end,
		on_nth_tick = function() end,
		on_event = function() end
	})
	rawset(_G, "commands", {add_command = function() end})
	rawset(_G, "defines", {events = {
		on_built_entity = 1,
		on_robot_built_entity = 2,
		on_entity_cloned = 3,
		script_raised_built = 4,
		script_raised_revive = 5
	}})
	local technologies = {
		element882 = {enabled = false, researched = false, prototype = {enabled = true}},
		atomacer = {enabled = false, researched = false, prototype = {enabled = false}},
		["rare-metal-refining"] = {enabled = false, researched = false, prototype = {enabled = true, hidden = true}},
		["nexus-storm-prediction"] = {enabled = false, researched = true, prototype = {enabled = true}}
	}
	local force = {valid = true, technologies = technologies,
		get_entity_count = function() return 0 end}
	rawset(_G, "game", {forces = {player = force}, connected_players = {}})
	fresh("control")
	local run_callback = callback
	if not run_callback then
		error("Configuration callback missing")
	end

	run_callback({mod_changes = {["unrelated-mod"] = {old_version = "1", new_version = "2"}}})
	ok(not technologies.element882.enabled, "Unrelated mod update enabled Nexus tech")

	run_callback({mod_changes = {["Nexus-Updated"] = {old_version = "1", new_version = "2"}}})
	ok(technologies.element882.enabled, "Legitimate Nexus migration was ignored")
	ok(not technologies.atomacer.enabled, "Prototype-disabled Nexus tech was enabled")
	ok(not technologies["rare-metal-refining"].enabled, "Hidden Nexus tech was enabled")
	ok(not technologies["nexus-storm-prediction"].enabled, "Researched technology was changed")
end

test_unrelated_technologies_stay_visible()
test_infrastructure_name_matching()
test_nexus_migration_scope()
print("Lua compatibility fixture tests passed")
