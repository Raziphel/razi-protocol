package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local function make_world(options)
	options = options or {}
	local technology = {
		["advanced-material-processing-2"] = {},
		["low-density-structure"] = {
			prerequisites = { "plastics", "diamond-processing", "titanium-processing" },
		},
		laser = { prerequisites = { "military-2", "diamond-processing" } },
		["diamond-processing"] = {
			effects = { { type = "unlock-recipe", recipe = "nexus-diamond-recipe" } },
		},
		["diamond-processing-2"] = {
			research_trigger = options.trigger or { type = "mine-entity", entities = { "diamond" } },
		},
	}
	if options.unlock_synthetic then
		technology["diamond-processing"].effects[1].recipe = "synthetic-diamond"
	end
	if options.existing_razi_technology then
		technology["razi-bz-diamond-processing"] = { prerequisites = { "some-other-tech" } }
	end
	if options.no_advanced_technology then
		technology["advanced-material-processing-2"] = nil
	end
	if options.no_low_density_technology then
		technology["low-density-structure"] = nil
	end
	if options.no_laser_technology then
		technology.laser = nil
	end

	local planet = {}
	if not options.no_vulcanus then
		planet.vulcanus = {
			map_gen_settings = {
				autoplace_controls = {
					diamond = {},
					vulcanus_coal = {},
					tungsten_ore = {},
				},
				autoplace_settings = {
					entity = {
						settings = {
							diamond = {},
							["big-volcanic-rock"] = {},
						},
					},
				},
			},
		}
	end

	local raw = {
		recipe = options.no_recipe and {} or { ["synthetic-diamond"] = { enabled = false } },
		technology = technology,
		planet = planet,
		["simple-entity"] = options.no_big_rock and {} or { ["big-volcanic-rock"] = {} },
	}
	local logs = {}
	rawset(_G, "data", {
		raw = raw,
		extend = function(self, prototypes)
			for _, prototype in ipairs(prototypes) do
				self.raw[prototype.type][prototype.name] = prototype
			end
		end,
	})
	rawset(_G, "mods", options.mods or { bzcarbon = "2.0.23", PlanetAthos = "1.1.3" })
	rawset(_G, "log", function(message)
		logs[#logs + 1] = message
	end)

	return { raw = raw, logs = logs }
end

local diamond_processing = require("prototypes.compatibility.bzcarbon.diamond_processing")
local vulcanus_diamond = require("prototypes.compatibility.bzcarbon.vulcanus_diamond")

local world = make_world()
diamond_processing.data_final_fixes()
vulcanus_diamond.data_final_fixes()

local diamond_technology = world.raw.technology["razi-bz-diamond-processing"]
check(diamond_technology ~= nil, "the synthetic-diamond technology is created")
check(diamond_technology.icon == "__bzcarbon__/graphics/icons/diamond.png" and diamond_technology.icon_size == 128,
	"the synthetic-diamond technology uses the BZ diamond icon")
check(#diamond_technology.effects == 1 and diamond_technology.effects[1].type == "unlock-recipe"
	and diamond_technology.effects[1].recipe == "synthetic-diamond", "the new technology unlocks synthetic-diamond")
check(#diamond_technology.prerequisites == 1 and diamond_technology.prerequisites[1] == "advanced-material-processing-2",
	"the new technology requires advanced-material-processing-2")
check(diamond_technology.unit.count == 100 and diamond_technology.unit.time == 15,
	"the new technology has the planned research count and time")
check(#diamond_technology.unit.ingredients == 3
	and diamond_technology.unit.ingredients[1][1] == "automation-science-pack"
	and diamond_technology.unit.ingredients[1][2] == 1
	and diamond_technology.unit.ingredients[2][1] == "logistic-science-pack"
	and diamond_technology.unit.ingredients[2][2] == 1
	and diamond_technology.unit.ingredients[3][1] == "chemical-science-pack"
	and diamond_technology.unit.ingredients[3][2] == 1, "the new technology uses the planned science packs")
check(world.raw.technology["diamond-processing"].effects[1].recipe == "nexus-diamond-recipe",
	"Nexus's diamond-processing technology remains unchanged")
check(world.raw.technology["low-density-structure"].prerequisites[1] == "plastics"
	and world.raw.technology["low-density-structure"].prerequisites[2] == "razi-bz-diamond-processing"
	and world.raw.technology["low-density-structure"].prerequisites[3] == "titanium-processing",
	"low-density-structure changes only diamond-processing and keeps its other prerequisites")
check(world.raw.technology.laser.prerequisites[1] == "military-2"
	and world.raw.technology.laser.prerequisites[2] == "razi-bz-diamond-processing",
	"laser changes only diamond-processing and keeps its other prerequisite")

local trigger = world.raw.technology["diamond-processing-2"].research_trigger
check(trigger.type == "mine-entity" and #trigger.entities == 1 and trigger.entities[1] == "big-volcanic-rock",
	"diamond-processing-2 waits for mining big-volcanic-rock")
local vulcanus = world.raw.planet.vulcanus
check(vulcanus.map_gen_settings.autoplace_controls.diamond == nil
	and vulcanus.map_gen_settings.autoplace_settings.entity.settings.diamond == nil,
	"diamond is removed from Vulcanus autoplace")
check(vulcanus.map_gen_settings.autoplace_controls.vulcanus_coal ~= nil
	and vulcanus.map_gen_settings.autoplace_controls.tungsten_ore ~= nil,
	"neighboring Vulcanus autoplace controls stay")
check(world.logs[1] == "razi-protocol: bz: added razi-bz-diamond-processing to unlock synthetic-diamond",
	"creating the technology is logged")
check(#world.logs == 6, "each prerequisite, trigger and autoplace change is logged")

-- Repeated calls are idempotent and leave one technology and the final prerequisites intact.
diamond_processing.data_final_fixes()
vulcanus_diamond.data_final_fixes()
check(world.raw.technology["razi-bz-diamond-processing"] == diamond_technology,
	"a repeated call does not create another technology")
check(#world.raw.technology["low-density-structure"].prerequisites == 3
	and #world.raw.technology.laser.prerequisites == 2 and #world.logs == 6,
	"a repeated call does not change prerequisites or log extra fixes")

-- A BZ technology that already unlocks the recipe keeps the complete original graph.
world = make_world({ unlock_synthetic = true })
diamond_processing.data_final_fixes()
check(world.raw.technology["razi-bz-diamond-processing"] == nil
	and world.raw.technology["low-density-structure"].prerequisites[2] == "diamond-processing"
	and world.raw.technology.laser.prerequisites[2] == "diamond-processing" and #world.logs == 0,
	"diamond-processing already unlocking synthetic-diamond prevents duplicate technology and prerequisite changes")

-- Existing Razi technology, missing recipe, missing prerequisite technology, and missing mod are safe no-ops.
world = make_world({ existing_razi_technology = true })
diamond_processing.data_final_fixes()
check(world.raw.technology["low-density-structure"].prerequisites[2] == "diamond-processing"
	and #world.logs == 0, "an existing Razi technology is left alone")
world = make_world({ no_recipe = true })
diamond_processing.data_final_fixes()
check(world.raw.technology["razi-bz-diamond-processing"] == nil and #world.logs == 0,
	"the technology is not created without synthetic-diamond")
world = make_world({ no_advanced_technology = true })
diamond_processing.data_final_fixes()
check(world.raw.technology["razi-bz-diamond-processing"] == nil and #world.logs == 0,
	"the technology is not created without advanced-material-processing-2")
world = make_world({ no_low_density_technology = true, no_laser_technology = true })
diamond_processing.data_final_fixes()
check(world.raw.technology["razi-bz-diamond-processing"] ~= nil and #world.logs == 1,
	"missing low-density-structure and laser technologies are skipped")
world = make_world({ mods = {} })
diamond_processing.data_final_fixes()
vulcanus_diamond.data_final_fixes()
vulcanus = world.raw.planet.vulcanus
check(world.raw.technology["razi-bz-diamond-processing"] == nil
	and world.raw.technology["low-density-structure"].prerequisites[2] == "diamond-processing"
	and world.raw.technology["diamond-processing-2"].research_trigger.entities[1] == "diamond"
	and vulcanus.map_gen_settings.autoplace_controls.diamond ~= nil and #world.logs == 0,
	"both modules are inert without bzcarbon")

-- Only the expected mine-entity trigger is replaced, and only when the volcanic rock exists.
world = make_world({ trigger = { type = "craft-item", item = "diamond" } })
vulcanus_diamond.data_final_fixes()
check(world.raw.technology["diamond-processing-2"].research_trigger.type == "craft-item"
	and #world.logs == 2, "a different research trigger is untouched while Vulcanus diamond autoplace is removed")
world = make_world({ no_big_rock = true })
vulcanus_diamond.data_final_fixes()
check(world.raw.technology["diamond-processing-2"].research_trigger.entities[1] == "diamond"
	and #world.logs == 2, "the trigger is unchanged when big-volcanic-rock is absent")
world = make_world({ trigger = { type = "mine-entity", entities = { "diamond", "coal" } } })
vulcanus_diamond.data_final_fixes()
check(world.raw.technology["diamond-processing-2"].research_trigger.entities[2] == "coal"
	and #world.logs == 2, "a mine-entity trigger with additional entities is untouched")

-- PlanetAthos is required before either the trigger or Vulcanus autoplace is changed.
world = make_world({ mods = { bzcarbon = "2.0.23" } })
vulcanus_diamond.data_final_fixes()
vulcanus = world.raw.planet.vulcanus
check(world.raw.technology["diamond-processing-2"].research_trigger.entities[1] == "diamond"
	and vulcanus.map_gen_settings.autoplace_controls.diamond ~= nil
	and vulcanus.map_gen_settings.autoplace_settings.entity.settings.diamond ~= nil and #world.logs == 0,
	"Vulcanus stays unchanged without PlanetAthos")

local function check_locale(path, name, description)
	local file = assert(io.open(path, "r"))
	local contents = file:read("*a")
	file:close()
	check(contents:find("[technology-name]", 1, true) ~= nil and contents:find(name, 1, true) ~= nil,
		path .. " contains the technology name")
	check(contents:find("[technology-description]", 1, true) ~= nil and contents:find(description, 1, true) ~= nil,
		path .. " contains the technology description")
end

check_locale("locale/en/compat.cfg", "razi-bz-diamond-processing=Synthetic diamond",
	"razi-bz-diamond-processing=Grows diamonds from graphite in an electric furnace.")
check_locale("locale/ru/compat.cfg", "razi-bz-diamond-processing=Синтетический алмаз",
	"razi-bz-diamond-processing=Выращивание алмазов из графита в электропечи.")

print("test_bz_diamonds: ok")
