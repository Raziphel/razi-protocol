---@diagnostic disable: lowercase-global
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local function same(left, right)
	if type(left) ~= type(right) then
		return false
	end
	if type(left) ~= "table" then
		return left == right
	end
	for key, value in pairs(left) do
		if not same(value, right[key]) then
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

local function has_log(logs, message)
	for _, line in ipairs(logs) do
		if line == message then
			return true
		end
	end
	return false
end

local function copy(value)
	if type(value) ~= "table" then
		return value
	end
	local result = {}
	for key, item in pairs(value) do
		result[key] = copy(item)
	end
	return result
end

local DISCOVERY_RECIPES = {
	"lindomanium", "joaonium", "eltonium", "beninium", "omni-seed", "organic-fluid",
	"berengotengo-juice", "berengotengo-oil", "berengotengo-gas", "berengotengo-pulp",
	"berengotengo-refined", "berengotengo-refined-processing",
}

local SYNTHESIS_RECIPES = {
	"lava-from-mancha", "aquilo-from-vitu", "advanced-coal-synthesis", "omni-solid-fuel",
	"omni-holmium-plate", "biofix", "biofix-to-bioflux", "omni-carbon-fiber", "omni-synthesis",
	"promethium-asteroid-reprocessing", "advanced-promethium-asteroid-reprocessing",
}

local SCIENCE_RECIPES = {
	"advanced-automation-science", "advanced-logistic-science", "advanced-chemical-science",
	"advanced-military-science", "advanced-utility-science", "advanced-production-science",
	"advanced-space-science", "advanced-metallurgic-science", "advanced-electromagnetic-science",
	"advanced-agricultural-science", "advanced-cryogenic-science", "advanced-promethium-science",
	"dr-albieri-pentapod-cloning", "dr-albieri-biter-cloning", "dr-albieri-fish-cloning",
}

local module_name = "prototypes.compatibility.omni.omni"

local function unlock(name)
	return {type = "unlock-recipe", recipe = name}
end

local function source_effects(include_unknown)
	local effects = {{type = "unlock-space-location", space_location = "OMNI"}}
	for _, name in ipairs({"lindomanium", "joaonium", "eltonium", "beninium"}) do
		effects[#effects + 1] = unlock(name)
	end
	for _, name in ipairs(SCIENCE_RECIPES) do
		effects[#effects + 1] = unlock(name)
	end
	for _, name in ipairs({"omni-seed", "organic-fluid", "berengotengo-juice", "berengotengo-oil",
		"berengotengo-juice", "berengotengo-oil", "berengotengo-gas", "berengotengo-pulp",
		"berengotengo-refined", "berengotengo-refined-processing"}) do
		effects[#effects + 1] = unlock(name)
	end
	for _, name in ipairs(SYNTHESIS_RECIPES) do
		effects[#effects + 1] = unlock(name)
	end
	if include_unknown then
		effects[#effects + 1] = unlock("unknown-omni-recipe")
	end
	return effects
end

---@param options? table
---@return table, table, string[], table, table
local function install(options)
	options = options or {}
	local logs = {}
	local raw = {
		planet = {OMNI = {surface_properties = {}}},
		technology = {},
		recipe = {},
	}
	if not options.no_route then
		raw["space-connection"] = {
			["solar-system-edge-OMNI"] = {length = options.route_length or 10000},
		}
	end
	for _, name in ipairs(DISCOVERY_RECIPES) do
		raw.recipe[name] = {}
	end
	for _, name in ipairs(SYNTHESIS_RECIPES) do
		raw.recipe[name] = {}
	end
	if not options.missing_science then
		for _, name in ipairs(SCIENCE_RECIPES) do
			raw.recipe[name] = {}
		end
	end
	if options.include_unknown then
		raw.recipe["unknown-omni-recipe"] = {}
	end
	raw.recipe["advanced-coal-synthesis"].surface_conditions = {
		{property = "cerys-ambient-radiation", max = 300},
	}
	raw.technology["planet-discovery-OMNI"] = {
		icons = {{icon = "omni.png", icon_size = 64, tint = {r = 0.2, g = 0.4, b = 0.6}}},
		icon_size = 256,
		prerequisites = {"promethium-science-pack"},
		effects = source_effects(options.include_unknown),
		unit = {
			count = 1000000,
			time = 15,
			ingredients = {{"automation-science-pack", 1}, {"promethium-science-pack", 1}},
		},
	}
	local original_ingredients = copy(raw.technology["planet-discovery-OMNI"].unit.ingredients)
	local original_effects = copy(raw.technology["planet-discovery-OMNI"].effects)
	rawset(_G, "data", {
		raw = raw,
		extend = function(_, prototypes)
			for _, prototype in ipairs(prototypes) do
				raw[prototype.type] = raw[prototype.type] or {}
				raw[prototype.type][prototype.name] = prototype
			end
		end,
	})
	rawset(_G, "mods", options.no_mod and {} or {omni = "0.1.8"})
	rawset(_G, "log", function(message)
		logs[#logs + 1] = message
	end)
	rawset(_G, "PlanetsLib", {
		restrict_to_planet = function(recipe, planet)
			check(planet == "OMNI", "only OMNI is a valid restriction target")
			recipe.surface_conditions = recipe.surface_conditions or {}
			recipe.surface_conditions[#recipe.surface_conditions + 1] = {
				property = "PlanetsLib-is-OMNI", min = 1, max = 1,
			}
		end,
	})
	package.loaded[module_name] = nil
	return require(module_name), raw, logs, original_ingredients, original_effects
end

local function unlocked(technology)
	local names = {}
	for _, effect in ipairs(technology.effects or {}) do
		if effect.type == "unlock-recipe" then
			names[#names + 1] = effect.recipe
		end
	end
	return names
end

local omni, raw, logs, original_ingredients = install()
omni.data()

local discovery = raw.technology["planet-discovery-OMNI"]
local discovery_unlocked = {"lindomanium", "joaonium", "eltonium", "beninium", "omni-seed", "organic-fluid",
	"berengotengo-juice", "berengotengo-oil", "berengotengo-gas", "berengotengo-pulp",
	"berengotengo-refined", "berengotengo-refined-processing"}
check(#discovery_unlocked == 12 and same(unlocked(discovery), discovery_unlocked),
	"the discovery keeps the location and exactly the twelve resource recipes without duplicate unlocks")
check(discovery.effects[1].type == "unlock-space-location" and discovery.effects[1].space_location == "OMNI",
	"the OMNI location stays unlocked by the discovery")
check(discovery.unit.count == 2000 and discovery.unit.time == 60,
	"the discovery costs 2,000 units at 60 seconds")

local synthesis = raw.technology["razi-omni-synthesis"]
local expected_synthesis = {
	"lava-from-mancha", "aquilo-from-vitu", "advanced-coal-synthesis", "omni-solid-fuel",
	"omni-holmium-plate", "biofix", "biofix-to-bioflux", "omni-carbon-fiber", "omni-synthesis",
	"promethium-asteroid-reprocessing", "advanced-promethium-asteroid-reprocessing",
}
check(synthesis and same(unlocked(synthesis), expected_synthesis),
	"the synthesis research opens its eleven recipes in source order")
check(synthesis.unit.count == 1000 and synthesis.unit.time == 60
	and same(synthesis.prerequisites, {"planet-discovery-OMNI"}),
	"the synthesis research has its cost and discovery prerequisite")
check(same(synthesis.unit.ingredients, original_ingredients) and synthesis.unit.ingredients ~= original_ingredients
	and synthesis.unit.ingredients[1] ~= original_ingredients[1],
	"the synthesis research receives a deep copy of the discovery ingredients")
check(same(synthesis.icons, discovery.icons) and synthesis.icons ~= discovery.icons
	and synthesis.icons[1] ~= discovery.icons[1] and synthesis.icon_size == discovery.icon_size,
	"the synthesis research receives a deep copy of the discovery icon")

local science = raw.technology["razi-omni-science"]
check(science and same(unlocked(science), SCIENCE_RECIPES),
	"the science research opens twelve science recipes and three cloning recipes in source order")
check(science.unit.count == 1500 and science.unit.time == 60
	and same(science.prerequisites, {"planet-discovery-OMNI"}),
	"the science research has its cost and discovery prerequisite")
check(same(science.unit.ingredients, original_ingredients)
	and science.unit.ingredients ~= discovery.unit.ingredients,
	"the science research has independent copies of the discovery ingredients")

local restricted_count = 0
for _, name in ipairs(SCIENCE_RECIPES) do
	local condition = raw.recipe[name].surface_conditions and raw.recipe[name].surface_conditions[1]
	check(condition and condition.property == "PlanetsLib-is-OMNI" and condition.min == 1 and condition.max == 1,
		name .. " is restricted to OMNI")
	restricted_count = restricted_count + 1
end
for _, name in ipairs(SYNTHESIS_RECIPES) do
	if name ~= "biofix" then
		local conditions = raw.recipe[name].surface_conditions or {}
		local found = false
		for _, condition in ipairs(conditions) do
			if condition.property == "PlanetsLib-is-OMNI" and condition.min == 1 and condition.max == 1 then
				found = true
			end
		end
		check(found, name .. " is restricted to OMNI")
		restricted_count = restricted_count + 1
	end
end
check(restricted_count == 25, "exactly 25 science and resource synthesis recipes are restricted")
check(raw.recipe["advanced-coal-synthesis"].surface_conditions[1].property == "cerys-ambient-radiation",
	"the existing Cerys condition is preserved")
for _, name in ipairs(DISCOVERY_RECIPES) do
	local conditions = raw.recipe[name].surface_conditions or {}
	for _, condition in ipairs(conditions) do
		check(condition.property ~= "PlanetsLib-is-OMNI", name .. " stays available off OMNI")
	end
end
check(raw.recipe.biofix.surface_conditions == nil, "biofix stays available off OMNI")
check(has_log(logs, "razi-protocol: omni: planet-discovery-OMNI costs 2000 units of 60 s (was 1000000 of 15 s)"),
	"the changed discovery cost is logged")
check(has_log(logs, "razi-protocol: omni: razi-omni-synthesis unlocks 11 recipes")
	and has_log(logs, "razi-protocol: omni: razi-omni-science unlocks 15 recipes")
	and has_log(logs, "razi-protocol: omni: 25 recipes work only on OMNI"),
	"technology and surface-condition changes are logged")

omni, raw, logs = install({include_unknown = true})
omni.data()
local unknown_unlocked = unlocked(raw.technology["planet-discovery-OMNI"])
local known_unlocked = {}
for index = 1, #discovery_unlocked do
	known_unlocked[index] = unknown_unlocked[index]
end
check(#unknown_unlocked == 13 and same(known_unlocked, discovery_unlocked)
	and unknown_unlocked[13] == "unknown-omni-recipe",
	"an unknown recipe stays in the discovery")
check(has_log(logs, "razi-protocol: omni: planet-discovery-OMNI keeps the unknown recipe unknown-omni-recipe"),
	"an unknown recipe left in the discovery is logged")

omni, raw, logs = install({missing_science = true})
omni.data()
check(raw.technology["razi-omni-science"] == nil,
	"a research is not created when none of its recipes exists")
check(#logs == 3,
	"known recipes missing from the prototypes are not reported as unknown")

omni, raw, logs = install({no_mod = true})
local before = copy(raw)
omni.data()
check(same(raw, before) and #logs == 0, "the data pass is silent and inert without omni")

omni, raw, logs = install()
raw.planet = nil
before = copy(raw)
omni.data()
check(same(raw, before) and #logs == 0, "the data pass is silent and inert without the OMNI planet")

omni, raw, logs = install()
omni.data_final_fixes()
check(raw["space-connection"]["solar-system-edge-OMNI"].length == 300000,
	"the 10,000 km OMNI route is extended to 300,000 km")
check(has_log(logs, "razi-protocol: omni: solar-system-edge-OMNI is 300000 km (was 10000)"),
	"the extended OMNI route is logged")

omni, raw, logs = install({route_length = 50000})
omni.data_final_fixes()
check(raw["space-connection"]["solar-system-edge-OMNI"].length == 50000,
	"a non-source OMNI route length stays unchanged")
check(has_log(logs, "razi-protocol: omni: solar-system-edge-OMNI is 50000 km, expected 10000, left as is"),
	"an unexpected OMNI route length is logged")

omni, raw, logs = install({no_route = true})
omni.data_final_fixes()
check(raw["space-connection"] == nil and #logs == 0,
	"the route pass is silent and inert when the OMNI route is absent")

omni, raw, logs = install({no_mod = true})
omni.data_final_fixes()
check(#logs == 0 and raw["space-connection"]["solar-system-edge-OMNI"].length == 10000,
	"the route pass is silent and inert without omni")

omni, raw, logs = install()
raw.planet = nil
omni.data_final_fixes()
check(#logs == 0 and raw["space-connection"]["solar-system-edge-OMNI"].length == 10000,
	"the route pass is silent and inert without the OMNI planet")

print("test_omni: ok")
