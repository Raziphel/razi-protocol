---@diagnostic disable: missing-fields, need-check-nil, assign-type-mismatch
-- Guarded 2.1 optional planet admission without loading external mods.
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(condition, message)
	if not condition then error(message, 2) end
end
local function mock_data(raw)
	return {
		raw = raw,
		extend = function(self, prototypes)
			for _, prototype in ipairs(prototypes) do
				self.raw[prototype.type] = self.raw[prototype.type] or {}
				self.raw[prototype.type][prototype.name] = prototype
			end
		end
	}
end

local function run_fixture(enabled, cycle)
	local planet_names = {
		"igrys", "rabbasca", "foliax", "obsidiax", "carna", "athos"
	}
	local planets = {gleba = {}}
	for _, name in ipairs(planet_names) do planets[name] = {name = name} end
	local hubs = {
		["sye-solaris"] = {}, ["sye-nyxaris"] = {},
		["sye-vespera"] = {}, ["sye-umbra"] = {},
		solaris = {}, nyxaris = {}, vespera = {}, umbra = {}
	}
	local techs = {
		["solaris-discovery"] = {prerequisites = {}},
		["nyxaris-discovery"] = {prerequisites = {}},
		["vespera-discovery"] = {prerequisites = {}},
		["umbra-discovery"] = {prerequisites = {}},
		["planet-discovery-gleba"] = {prerequisites = {}}
	}
	for _, name in ipairs(planet_names) do
		techs["planet-discovery-" .. name] = {
			prerequisites = {"existing-source-dependency"},
			effects = {
				{type = "unlock-space-location", space_location = name},
				{type = "unlock-recipe", recipe = name .. "-science"}
			}
		}
	end
	if cycle then
		techs["umbra-discovery"].prerequisites = {"planet-discovery-carna"}
	end
	local original_moon = {name = "rabbasca", orbit = {
		parent = {type = "planet", name = "gleba"}, distance = 4
	}}
	planets.rabbasca = original_moon
	local native_moon = {from = "gleba", to = "rabbasca", length = 9000}
	local unknown_carna = {from = "carna", to = "carna-special-vault"}
	local routes = {
		["gleba-rabbasca"] = native_moon,
		["carna-special-link"] = unknown_carna,
		["vulcanus-to-igrys"] = {from = "vulcanus", to = "igrys"},
		["gleba-to-igrys"] = {from = "gleba", to = "igrys"}
	}
	rawset(_G, "data", mock_data({
		planet = planets, ["space-location"] = hubs,
		["space-connection"] = routes, technology = techs
	}))
	rawset(_G, "mods", enabled)
	local recolored = {}
	rawset(_G, "PlanetsLib", {
		update = function(_, updates)
			for _, item in ipairs(updates) do
				recolored[item.name] = true
				planets[item.name].orbit = item.orbit
			end
		end
	})
	package.loaded["__space-age__.prototypes.planet.asteroid-spawn-definitions"] = {
		nauvis_fulgora = {}, fulgora_aquilo = {},
		spawn_definitions = function() return {{type = "asteroid"}} end
	}
	package.loaded["prototypes.system.optional_planets"] = nil
	local integration = require("prototypes.system.optional_planets")
	integration.data_final_fixes()
	return integration, planets, routes, techs, recolored, original_moon, native_moon, unknown_carna
end

local enabled = {
	Igrys = "1.5.40", ["planet-rabbasca"] = "0.22.4",
	foliax = "2.0.40", obsidiax = "1.0.29",
	carna = "0.3.22", PlanetAthos = "1.1.2"
}
local integration, planets, routes, techs, moved, moon, native_moon, special =
	run_fixture(enabled, false)

check(planets.igrys.orbit.parent.name == "solaris", "Igrys didn't join Solaris")
check(planets.foliax.orbit.parent.name == "nyxaris", "Foliax didn't join Nyxaris")
check(planets.obsidiax.orbit.parent.name == "vespera", "Obsidiax didn't join Vespera")
check(planets.carna.orbit.parent.name == "umbra", "Carna didn't join Umbra")
check(planets.athos.orbit.parent.name == "solaris", "Athos didn't join Solaris")
check(not moved.rabbasca and planets.rabbasca == moon, "Rabbasca lost native moon orbit")
check(routes["gleba-rabbasca"] == native_moon, "Rabbasca native connection removed")
check(routes["carna-special-link"] == special, "Source-owned special route removed")
check(routes["vulcanus-to-igrys"] ~= nil,
	"Solaris's native Vulcanus/Igrys connection was removed")
check(not routes["gleba-to-igrys"],
	"Nyxaris/Gleba bypassed the optional Solaris discovery gate")

for _, pair in ipairs({
	{"igrys", "sye-solaris", "solaris-discovery"},
	{"foliax", "sye-nyxaris", "nyxaris-discovery"},
	{"obsidiax", "sye-vespera", "vespera-discovery"},
	{"carna", "sye-umbra", "umbra-discovery"},
	{"athos", "sye-solaris", "solaris-discovery"}
}) do
	local name, hub, gate = pair[1], pair[2], pair[3]
	check(routes["razi-optional-" .. name .. "-" .. hub] ~= nil, name .. " route missing")
	local found = false
	for _, p in ipairs(techs["planet-discovery-" .. name].prerequisites) do
		if p == gate then found = true end
	end
	check(found, name .. " didn't get its star discovery gate")
end

local count_before = 0
for _ in pairs(routes) do count_before = count_before + 1 end
integration.data_final_fixes()
local count_after = 0
for _ in pairs(routes) do count_after = count_after + 1 end
check(count_before == count_after, "Duplicate optional routes on repeated load")

local _, _, absent_routes, absent_techs, absent_updates =
	run_fixture({}, false)
check(not absent_routes["razi-optional-igrys-sye-solaris"], "Disabled Igrys route added")
check(not absent_updates.igrys, "Disabled Igrys was reparented")
check(#absent_techs["planet-discovery-igrys"].prerequisites == 1,
	"Disabled Igrys was research-gated")

local _, _, _, cycle_techs = run_fixture(enabled, true)
check(#cycle_techs["planet-discovery-carna"].prerequisites == 1,
	"Optional planet admission introduced a research cycle")

print("Six optional-planet admission fixtures passed")
