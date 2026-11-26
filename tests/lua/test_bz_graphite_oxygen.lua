---@diagnostic disable: missing-fields, need-check-nil, inject-field, undefined-field
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local function make_graphite_world(options)
	options = options or {}
	local raw = {
		item = { ["flake-graphite"] = {}, graphite = {} },
		["recipe-category"] = options.no_crushing and {} or { ["kr-crushing"] = {} },
		recipe = {
			graphite = {
				ingredients = { { type = "item", name = "carbon", amount = 4 } },
				results = { { type = "item", name = "graphite", amount = 1 } },
			},
		},
		technology = {
			["graphite-processing"] = {
				effects = { { type = "unlock-recipe", recipe = "graphite" } },
			},
		},
	}
	if options.no_flake then
		raw.item["flake-graphite"] = nil
	end
	if options.no_graphite then
		raw.item.graphite = nil
	end
	if options.no_technology then
		raw.technology["graphite-processing"] = nil
	end
	if options.other_conversion then
		raw.recipe["existing-flake-graphite"] = {
			ingredients = { { type = "item", name = "flake-graphite", amount = 1 } },
			results = { { type = "item", name = "graphite", amount = 1 } },
		}
	end
	if options.non_bz_conversions then
		raw.recipe["enriched-graphite"] = {
			ingredients = {
				{ type = "item", name = "flake-graphite", amount = 1 },
				{ type = "fluid", name = "water", amount = 10 },
				{ type = "fluid", name = "kr-hydrogen-chloride", amount = 10 },
			},
			results = {
				{ type = "item", name = "graphite", amount = 1 },
				{ type = "fluid", name = "kr-dirty-water", amount = 10 },
			},
		}
		raw.recipe["planetaris-flake-graphite"] = {
			ingredients = { { type = "item", name = "flake-graphite", amount = 1 } },
			results = {
				{ type = "item", name = "graphite", amount = 1 },
				{ type = "item", name = "coal", amount = 1 },
			},
		}
	end

	local logs = {}
	rawset(_G, "mods", options.no_bzcarbon and {} or { bzcarbon = "2.0.23" })
	rawset(_G, "log", function(message)
		logs[#logs + 1] = message
	end)
	rawset(_G, "data", {
		raw = raw,
		extend = function(_, prototypes)
			for _, prototype in ipairs(prototypes) do
				raw[prototype.type][prototype.name] = prototype
			end
		end,
	})
	return { raw = raw, logs = logs }
end

local function unlock_count(effects, recipe_name)
	local count = 0
	for _, effect in ipairs(effects or {}) do
		if effect.type == "unlock-recipe" and effect.recipe == recipe_name then
			count = count + 1
		end
	end
	return count
end

local flake_graphite = require("prototypes.compatibility.bzcarbon.flake_graphite")
local graphite_prerequisites = require("prototypes.compatibility.bzcarbon.graphite_prerequisites")
local oxygen = require("prototypes.compatibility.bzcarbon.oxygen")

local world = make_graphite_world()
flake_graphite.data_final_fixes()
local recipe = world.raw.recipe["razi-bz-graphite-from-flake"]
check(recipe ~= nil, "a graphite-from-flake recipe is created")
check(recipe.localised_name[1] == "item-name.graphite" and recipe.categories[1] == "kr-crushing"
	and recipe.subgroup == "raw-material" and recipe.order == "d[graphite]", "recipe identity and category fields match")
check(recipe.enabled == false and recipe.auto_recycle == false and recipe.allow_productivity == true
	and recipe.energy_required == 0.25, "recipe processing fields match")
check(recipe.ingredients[1].name == "flake-graphite" and recipe.ingredients[1].amount == 1
	and recipe.results[1].name == "graphite" and recipe.results[1].amount == 1, "recipe converts one flake into one graphite")
check(recipe.icons[1].icon == "__bzcarbon__/graphics/icons/graphite.png"
	and recipe.icons[2].icon == "__bzcarbon__/graphics/icons/flake-graphite.png"
	and recipe.icons[2].scale == 0.125 and recipe.icons[2].shift[1] == -8 and recipe.icons[2].shift[2] == -8,
	"recipe uses the planned graphite and flake icons")
local effects = world.raw.technology["graphite-processing"].effects
check(unlock_count(effects, "razi-bz-graphite-from-flake") == 1 and #effects == 2,
	"graphite-processing unlocks the new recipe while keeping existing effects")
check(#world.logs == 1, "the new graphite recipe unlock is logged")
flake_graphite.data_final_fixes()
check(unlock_count(effects, "razi-bz-graphite-from-flake") == 1 and #world.logs == 1,
	"a repeated run does not duplicate the recipe unlock or log")

world = make_graphite_world({ other_conversion = true })
flake_graphite.data_final_fixes()
check(world.raw.recipe["razi-bz-graphite-from-flake"] == nil
	and unlock_count(world.raw.technology["graphite-processing"].effects, "razi-bz-graphite-from-flake") == 0
	and #world.logs == 0, "an existing one-to-one flake-to-graphite recipe is left alone")

world = make_graphite_world({ non_bz_conversions = true })
flake_graphite.data_final_fixes()
check(world.raw.recipe["razi-bz-graphite-from-flake"] ~= nil
	and unlock_count(world.raw.technology["graphite-processing"].effects, "razi-bz-graphite-from-flake") == 1
	and #world.logs == 1, "enriched and planetaris flake recipes do not block the fallback")

world = make_graphite_world({ no_crushing = true })
flake_graphite.data_final_fixes()
check(world.raw.recipe["razi-bz-graphite-from-flake"] == nil and #world.logs == 0,
	"the recipe is skipped when kr-crushing is absent")

for _, options in ipairs({
	{ no_bzcarbon = true },
	{ no_flake = true },
	{ no_graphite = true },
	{ no_technology = true },
}) do
	world = make_graphite_world(options)
	flake_graphite.data_final_fixes()
	check(world.raw.recipe["razi-bz-graphite-from-flake"] == nil and #world.logs == 0,
		"the recipe is skipped when a required mod or prototype is absent")
end

local function make_technology_world(no_bzcarbon)
	local technologies = {
		electronics = { prerequisites = { "automation", "graphite-processing", "logistics" } },
		["steel-processing"] = { prerequisites = { "automation", "graphite-processing" } },
		unrelated = { prerequisites = { "graphite-processing", "other" } },
	}
	local logs = {}
	rawset(_G, "mods", no_bzcarbon and {} or { bzcarbon = "2.0.23" })
	rawset(_G, "log", function(message)
		logs[#logs + 1] = message
	end)
	rawset(_G, "data", { raw = { technology = technologies } })
	return { technologies = technologies, logs = logs }
end

world = make_technology_world()
graphite_prerequisites.data_final_fixes()
check(table.concat(world.technologies.electronics.prerequisites, ",") == "automation,logistics",
	"electronics loses only graphite-processing")
check(table.concat(world.technologies["steel-processing"].prerequisites, ",") == "automation",
	"steel-processing loses only graphite-processing")
check(table.concat(world.technologies.unrelated.prerequisites, ",") == "graphite-processing,other",
	"other technologies keep their prerequisites")
check(#world.logs == 2, "each removed prerequisite is logged")

world = make_technology_world(true)
graphite_prerequisites.data_final_fixes()
check(world.technologies.electronics.prerequisites[2] == "graphite-processing" and #world.logs == 0,
	"without bzcarbon the technology tree is unchanged")

local function make_oxygen_world(options)
	options = options or {}
	local surface_properties = {
		vulcanus = { oxygen = 12 },
		fulgora = { oxygen = 15 },
		gleba = { oxygen = options.gleba_value or 30 },
		aquilo = { oxygen = 10 },
		nauvis = { oxygen = 21 },
	}
	local raw = {
		["surface-property"] = options.no_oxygen and {} or {
			oxygen = {
				default_value = options.default_value or 19,
				order = options.order,
				localised_unit_key = options.localised_unit_key,
			},
		},
		planet = {
			vulcanus = { surface_properties = surface_properties.vulcanus },
			fulgora = { surface_properties = surface_properties.fulgora },
			gleba = { surface_properties = surface_properties.gleba },
			aquilo = { surface_properties = surface_properties.aquilo },
			nauvis = { surface_properties = surface_properties.nauvis },
		},
		surface = {
			["space-platform"] = { surface_properties = { oxygen = 0 } },
		},
	}
	local installed_mods = options.no_bzcarbon and {} or { bzcarbon = "2.0.23" }
	if not options.no_planetslib then
		installed_mods.PlanetsLib = "2.5.3"
	end
	local startup = { ["PlanetsLib-enable-oxygen"] = { value = options.enabled ~= false } }
	local current_settings
	if not options.no_settings then
		current_settings = { startup = startup }
	end
	local logs = {}
	rawset(_G, "mods", installed_mods)
	rawset(_G, "settings", current_settings)
	rawset(_G, "log", function(message)
		logs[#logs + 1] = message
	end)
	rawset(_G, "data", { raw = raw })
	return { raw = raw, logs = logs }
end

world = make_oxygen_world()
oxygen.data_updates()
local oxygen_property = world.raw["surface-property"].oxygen
check(oxygen_property.default_value == 21 and oxygen_property.order == "z[gas]a"
	and oxygen_property.localised_unit_key == "surface-property-unit.percentage",
	"the bzcarbon oxygen prototype is restored to PlanetsLib values")
check(world.raw.planet.vulcanus.surface_properties.oxygen == 3
	and world.raw.planet.fulgora.surface_properties.oxygen == 20
	and world.raw.planet.gleba.surface_properties.oxygen == 35
	and world.raw.planet.aquilo.surface_properties.oxygen == 15,
	"the four bzcarbon oxygen planet values are restored")
check(world.raw.planet.nauvis.surface_properties.oxygen == 21, "matching Nauvis oxygen stays unchanged")
check(world.raw.surface["space-platform"].surface_properties.oxygen == 0,
	"matching space-platform oxygen stays unchanged")
check(#world.logs == 5, "the oxygen prototype and each changed planet are logged")

world = make_oxygen_world({ gleba_value = 40 })
oxygen.data_updates()
check(world.raw.planet.gleba.surface_properties.oxygen == 40,
	"a planet value that does not match bzcarbon is preserved")

world = make_oxygen_world({ default_value = 21 })
oxygen.data_updates()
check(world.raw["surface-property"].oxygen.default_value == 21
	and world.raw["surface-property"].oxygen.order == nil
	and world.raw["surface-property"].oxygen.localised_unit_key == nil,
	"an oxygen prototype that does not match bzcarbon is preserved")

for _, options in ipairs({
	{ enabled = false },
	{ no_settings = true },
	{ no_bzcarbon = true },
	{ no_planetslib = true },
	{ no_oxygen = true },
}) do
	world = make_oxygen_world(options)
	local property = world.raw["surface-property"].oxygen
	local original_default = property and property.default_value
	oxygen.data_updates()
	check((not property or property.default_value == original_default)
		and world.raw.planet.vulcanus.surface_properties.oxygen == 12
		and #world.logs == 0, "oxygen is unchanged unless its mod, setting, and prototype are present")
end

print("test_bz_graphite_oxygen: ok")
