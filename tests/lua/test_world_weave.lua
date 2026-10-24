---@diagnostic disable: missing-fields
-- Installed worlds are researched before the gateways of the next system (regional_research_bridges.lua):
-- which gateway takes which world, what stays out, and when a world is skipped to avoid a cycle.
-- Run from the mod root:
--   lua5.2 tests/lua/test_world_weave.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local logged = {}
rawset(_G, "log", function(text) logged[#logged + 1] = text end)

local function tech(parents, effects, packs)
	local ingredients = {}
	for _, pack in ipairs(packs or {"space-science-pack"}) do
		ingredients[#ingredients + 1] = {pack, 1}
	end
	return {prerequisites = parents or {}, effects = effects or {}, unit = {count = 100, time = 30, ingredients = ingredients}}
end
local function unlock(world, parents, packs)
	return tech(parents, {{type = "unlock-space-location", space_location = world}}, packs)
end
local function recipe(name, enabled, ingredients)
	local list = {}
	for _, ingredient in ipairs(ingredients or {}) do
		list[#list + 1] = {type = "item", name = ingredient, amount = 1}
	end
	return {type = "recipe", name = name, enabled = enabled, ingredients = list,
		results = {{type = "item", name = name, amount = 1}}}
end

local function build()
	local techs = {
		["solaris-discovery"] = tech(), ["nyxaris-discovery"] = tech(),
		["vibrant-discovery"] = tech({"solaris-discovery", "nyxaris-discovery"}, nil, {"nyxaris-tech-card"}),
		["vespera-discovery"] = tech({"solaris-discovery", "nyxaris-discovery"}, nil, {"nyxaris-tech-card"}),
		["beetlejuice-discovery"] = tech({"vibrant-discovery", "vespera-discovery"}),
		["umbra-discovery"] = tech({"vibrant-discovery", "vespera-discovery"}),
		["razi-outer-frontier-mastery"] = tech({"beetlejuice-discovery", "umbra-discovery"}),
		-- first systems
		["planet-discovery-pelagos"] = unlock("pelagos", {"nyxaris-discovery"}),
		["planet-discovery-terrapalus"] = unlock("terrapalus", {"nyxaris-discovery"}),
		-- Dea Dia's pack is in the Nyxaris card, which the Vibrant discovery takes: already on the path
		["planet-discovery-dea-dia"] = unlock("planet-dea-dia", {"nyxaris-discovery"}),
		["thermodynamic-science-pack"] = tech({"planet-discovery-dea-dia"},
			{{type = "unlock-recipe", recipe = "thermodynamic-science-pack"}}),
		["thermodynamic-user"] = tech({}, nil, {"thermodynamic-science-pack"}),
		-- second systems
		["planet-discovery-shchierbin"] = unlock("shchierbin", {"vibrant-discovery"}),
		["planet-discovery-athos"] = unlock("athos", {"vespera-discovery"}),
		-- third systems
		["planet-discovery-ferrum"] = unlock("ferrum", {"beetlejuice-discovery"}),
		["planet-discovery-obsidiax"] = unlock("obsidiax", {"umbra-discovery"}),
		["discovery-bellicos"] = unlock("bellicos-orbit", {"beetlejuice-discovery"}),
		-- Balack waits for Ferrum's pack, which waits for Beetlejuice
		["ferrum-robotics-science-pack"] = tech({"planet-discovery-ferrum"}),
		["bm-planet-discovery-balack"] = unlock("bm-balack", {"ferrum-robotics-science-pack"}),
		-- the final technology; carries the packs used above so that they count as packs
		["razi-stable-intergalactic-singularity"] = tech({"razi-outer-frontier-mastery"})
	}
	local planets = {}
	for _, world in ipairs({"pelagos", "terrapalus", "planet-dea-dia", "shchierbin", "athos", "ferrum", "obsidiax",
		"bm-balack"}) do
		planets[world] = {name = world}
	end
	rawset(_G, "data", {raw = {technology = techs, planet = planets,
		["space-location"] = {["bellicos-orbit"] = {name = "bellicos-orbit"}},
		recipe = {["nyxaris-tech-card"] = recipe("nyxaris-tech-card", true, {"thermodynamic-science-pack"}),
			["thermodynamic-science-pack"] = recipe("thermodynamic-science-pack", false, {})}}})
	rawset(_G, "settings", {startup = {}})
	return techs
end

local function requires(techs, node, parent)
	for _, name in ipairs(techs[node].prerequisites) do
		if name == parent then
			return true
		end
	end
	return false
end

rawset(_G, "mods", {})
local weave = require("prototypes.technology.regional_research_bridges")

-- the phases follow the roster: worlds of two systems, one pair of gateways
local function phase_of(gate)
	for _, phase in ipairs(weave.phases) do
		for _, name in ipairs(phase.gates) do
			if name == gate then
				return phase
			end
		end
	end
	error("no stage opens with " .. gate)
end
local function has(list, wanted)
	for _, name in ipairs(list) do
		if name == wanted then
			return true
		end
	end
	return false
end
check(#weave.phases == 3, "three stages: the first, the middle and the outer systems")
check(has(phase_of("vibrant-discovery").worlds, "pelagos") and has(phase_of("vibrant-discovery").worlds, "terrapalus")
	and has(phase_of("vibrant-discovery").worlds, "planet-dea-dia") and has(phase_of("vibrant-discovery").worlds, "igrys"),
	"worlds of Solaris and Nyxaris go before Vibrant and Vespera")
check(has(phase_of("umbra-discovery").worlds, "shchierbin") and has(phase_of("umbra-discovery").worlds, "cerys"),
	"worlds of Vibrant and Vespera go before Beetlejuice and Umbra")
check(has(phase_of("razi-outer-frontier-mastery").worlds, "ferrum")
	and has(phase_of("razi-outer-frontier-mastery").worlds, "bellicos-orbit"),
	"worlds of Beetlejuice and Umbra, and Bellicos, go before the mastery")
check(not has(phase_of("umbra-discovery").worlds, "bm-balack"), "Balack is an exception and stays out")
check(#phase_of("razi-outer-frontier-mastery").gates == 1, "the mastery is a single node")

local techs = build()
weave.data_final_fixes()
for _, gate in ipairs({"vibrant-discovery", "vespera-discovery"}) do
	check(requires(techs, gate, "planet-discovery-pelagos") and requires(techs, gate, "planet-discovery-terrapalus"),
		gate .. " must wait for the installed worlds of the first systems")
	check(not requires(techs, gate, "planet-discovery-shchierbin"), gate .. " must not wait for a later world")
end
check(not requires(techs, "vespera-discovery", "planet-discovery-dea-dia"),
	"Dea Dia is on the path through the Nyxaris card and needs no link of its own")
for _, gate in ipairs({"beetlejuice-discovery", "umbra-discovery"}) do
	check(requires(techs, gate, "planet-discovery-shchierbin") and requires(techs, gate, "planet-discovery-athos"),
		gate .. " must wait for the installed worlds of the second systems")
	check(not requires(techs, gate, "planet-discovery-ferrum"), gate .. " must not wait for a world behind it")
end
check(requires(techs, "razi-outer-frontier-mastery", "planet-discovery-ferrum")
	and requires(techs, "razi-outer-frontier-mastery", "planet-discovery-obsidiax")
	and requires(techs, "razi-outer-frontier-mastery", "discovery-bellicos"),
	"the mastery must wait for the installed worlds of the outer systems")
check(not requires(techs, "beetlejuice-discovery", "bm-planet-discovery-balack")
	and not requires(techs, "razi-outer-frontier-mastery", "bm-planet-discovery-balack"), "Balack stays out")
check(#techs["vibrant-discovery"].prerequisites == 4 and #techs["razi-outer-frontier-mastery"].prerequisites == 5,
	"a gateway got a prerequisite it did not need")

-- a second run changes nothing
local before = #techs["beetlejuice-discovery"].prerequisites
weave.data_final_fixes()
check(#techs["beetlejuice-discovery"].prerequisites == before, "the weave added a link twice")

-- planetary interdependence off: no world is woven
techs = build()
rawset(_G, "settings", {startup = {["razi-planetary-interdependence"] = {value = "off"}}})
weave.data_final_fixes()
check(#techs["vibrant-discovery"].prerequisites == 2 and #techs["razi-outer-frontier-mastery"].prerequisites == 2,
	"with interdependence off the worlds must stay out of the gateways")
rawset(_G, "settings", {startup = {}})

-- a world whose research needs the gateway through a pack that a pack recipe takes is skipped, and logged:
-- the outer pack is made from a late pack, which is unlocked by a technology behind Beetlejuice
techs = build()
techs["late-pack-research"] = tech({"beetlejuice-discovery"}, {{type = "unlock-recipe", recipe = "late-pack"}})
techs["outer-pack-research"] = tech({"vespera-discovery"}, {{type = "unlock-recipe", recipe = "outer-pack"}})
techs["pack-user"] = tech({}, nil, {"late-pack", "outer-pack"})
techs["planet-discovery-athos"] = unlock("athos", {"vespera-discovery"}, {"outer-pack"})
data.raw.recipe["late-pack"] = recipe("late-pack", false, {})
data.raw.recipe["outer-pack"] = recipe("outer-pack", false, {"late-pack"})
logged = {}
weave.data_final_fixes()
check(not requires(techs, "beetlejuice-discovery", "planet-discovery-athos"),
	"a world whose science needs a pack made behind the gateway must be skipped")
check(requires(techs, "beetlejuice-discovery", "planet-discovery-shchierbin"), "the other worlds are still woven")
local reported = false
for _, line in ipairs(logged) do
	reported = reported or (line:find("athos", 1, true) and line:find("not woven", 1, true)) and true
end
check(reported, "the skipped world must be reported in the log")

-- the same world is woven when the late pack comes from an early technology
techs = build()
techs["late-pack-research"] = tech({"vespera-discovery"}, {{type = "unlock-recipe", recipe = "late-pack"}})
techs["outer-pack-research"] = tech({"vespera-discovery"}, {{type = "unlock-recipe", recipe = "outer-pack"}})
techs["pack-user"] = tech({}, nil, {"late-pack", "outer-pack"})
techs["planet-discovery-athos"] = unlock("athos", {"vespera-discovery"}, {"outer-pack"})
data.raw.recipe["late-pack"] = recipe("late-pack", false, {})
data.raw.recipe["outer-pack"] = recipe("outer-pack", false, {"late-pack"})
weave.data_final_fixes()
check(requires(techs, "beetlejuice-discovery", "planet-discovery-athos"), "a world with early packs must be woven")

-- a world that needs the gateway itself is skipped
techs = build()
techs["planet-discovery-athos"] = unlock("athos", {"beetlejuice-discovery"})
weave.data_final_fixes()
check(not requires(techs, "beetlejuice-discovery", "planet-discovery-athos"), "a world behind the gateway stays out")

print("test_world_weave: ok")
