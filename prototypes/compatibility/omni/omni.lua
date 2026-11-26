-- omni 0.1.8 opens its planet and all 38 recipes with one research of 1 000 000 units of every science pack
-- (omni/prototypes/technology.lua:1-197, omni/settings.lua:2-10), and none of its recipes has a surface condition
-- (omni/prototypes/recipe.lua). The planet keeps its discovery with the fluids and the berengotengo chain; the resource
-- synthesis and the science pack and cloning recipes get a research each, and the recipes that make vanilla resources and
-- science packs work only on OMNI. Pressure and gravity cannot single out OMNI: Biological Machines Balack has the same
-- 1500 and 15. This runs in data so later recipe copies (Igrys enhanced science packs,
-- Igrys/Scripts/Recipes/EnhancedSciencePacks.lua:12-53) inherit the surface condition.
local DISCOVERY = "planet-discovery-OMNI"
local SYNTHESIS = "razi-omni-synthesis"
local SCIENCE = "razi-omni-science"
local PLANET = "OMNI"
local ROUTE = "solar-system-edge-OMNI"

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

local PLANET_ONLY_RECIPES = {}
for _, name in ipairs(SCIENCE_RECIPES) do
	PLANET_ONLY_RECIPES[#PLANET_ONLY_RECIPES + 1] = name
end
for _, name in ipairs(SYNTHESIS_RECIPES) do
	if name ~= "biofix" then
		PLANET_ONLY_RECIPES[#PLANET_ONLY_RECIPES + 1] = name
	end
end

local function active()
	return mods and mods["omni"] and data and data.raw
		and type(data.raw.planet) == "table" and data.raw.planet[PLANET]
end

local function deep_copy(value)
	if type(value) ~= "table" then
		return value
	end

	local copy = {}
	for key, item in pairs(value) do
		copy[deep_copy(key)] = deep_copy(item)
	end
	return copy
end

local function recipe_lookup(names)
	local lookup = {}
	for _, name in ipairs(names) do
		lookup[name] = true
	end
	return lookup
end

local discovery_lookup = recipe_lookup(DISCOVERY_RECIPES)
local synthesis_lookup = recipe_lookup(SYNTHESIS_RECIPES)
local science_lookup = recipe_lookup(SCIENCE_RECIPES)

---@param name string
---@param discovery table
---@param effects table
---@param count integer
local function new_technology(name, discovery, effects, count)
	local technology = {
		type = "technology",
		name = name,
		prerequisites = {DISCOVERY},
		effects = effects,
		unit = {
			count = count,
			time = 60,
			ingredients = deep_copy(discovery.unit.ingredients),
		},
	}

	if type(discovery.icons) == "table" then
		technology.icons = deep_copy(discovery.icons)
		technology.icon_size = discovery.icon_size
	elseif discovery.icon ~= nil then
		technology.icon = discovery.icon
		technology.icon_size = discovery.icon_size
	end

	data:extend({technology})
end

local function data_stage()
	if not active() then
		return
	end

	local raw = data.raw
	local discovery = raw.technology and raw.technology[DISCOVERY]
	if type(discovery) ~= "table" or type(discovery.effects) ~= "table"
		or type(discovery.unit) ~= "table" or type(discovery.unit.ingredients) ~= "table" then
		return
	end

	local synthesis_effects = {}
	local science_effects = {}
	local discovery_effects = {}
	local seen_recipes = {}
	for _, effect in ipairs(discovery.effects) do
		if effect.type == "unlock-recipe" and type(effect.recipe) == "string" then
			local name = effect.recipe
			if not seen_recipes[name] then
				seen_recipes[name] = true
				local recipe_exists = raw.recipe and type(raw.recipe[name]) == "table"
				if recipe_exists and synthesis_lookup[name] then
					synthesis_effects[#synthesis_effects + 1] = effect
				elseif recipe_exists and science_lookup[name] then
					science_effects[#science_effects + 1] = effect
				else
					discovery_effects[#discovery_effects + 1] = effect
					if not discovery_lookup[name] and not synthesis_lookup[name] and not science_lookup[name] then
						log("razi-protocol: omni: planet-discovery-OMNI keeps the unknown recipe " .. name)
					end
				end
			end
		else
			discovery_effects[#discovery_effects + 1] = effect
		end
	end

	local old_count = discovery.unit.count
	local old_time = discovery.unit.time
	discovery.effects = discovery_effects
	discovery.unit.count = 2000
	discovery.unit.time = 60
	log("razi-protocol: omni: planet-discovery-OMNI costs 2000 units of 60 s (was "
		.. tostring(old_count) .. " of " .. tostring(old_time) .. " s)")

	local researches = {
		{name = SYNTHESIS, effects = synthesis_effects, count = 1000},
		{name = SCIENCE, effects = science_effects, count = 1500},
	}
	for _, research in ipairs(researches) do
		if #research.effects > 0 then
			new_technology(research.name, discovery, research.effects, research.count)
			log("razi-protocol: omni: " .. research.name .. " unlocks " .. #research.effects .. " recipes")
		end
	end

	local restricted = 0
	for _, name in ipairs(PLANET_ONLY_RECIPES) do
		local recipe = raw.recipe and raw.recipe[name]
		if type(recipe) == "table" then
			PlanetsLib.restrict_to_planet(recipe, PLANET)
			restricted = restricted + 1
		end
	end
	log("razi-protocol: omni: " .. restricted .. " recipes work only on OMNI")
end

---@class OmniCompatibilityModule
---@field DISCOVERY string
---@field SYNTHESIS string
---@field SCIENCE string
---@field PLANET string
---@field ROUTE string
---@field data fun()
---@field data_final_fixes fun()
local function data_final_fixes()
	if not active() then
		return
	end

	local route = data.raw["space-connection"] and data.raw["space-connection"][ROUTE]
	if type(route) ~= "table" then
		return
	end

	if route.length == 10000 then
		route.length = 300000
		log("razi-protocol: omni: solar-system-edge-OMNI is 300000 km (was 10000)")
	else
		log("razi-protocol: omni: solar-system-edge-OMNI is " .. tostring(route.length)
			.. " km, expected 10000, left as is")
	end
end

local omni = {
	DISCOVERY = DISCOVERY,
	SYNTHESIS = SYNTHESIS,
	SCIENCE = SCIENCE,
	PLANET = PLANET,
	ROUTE = ROUTE,
	data = data_stage,
	data_final_fixes = data_final_fixes,
}

return omni
