-- Seven-system route and research fixtures without a running Factorio client.
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(condition, message)
	if not condition then
		error(message, 2)
	end
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

local function reload(module)
	package.loaded[module] = nil
	return require(module)
end

local function test_routes()
	local places = {
		"sye-calidus", "sye-solaris", "sye-nyxaris", "sye-vibrant",
		"sye-vespera", "sye-beetlejuice", "sye-umbra",
		"solar-system-edge", "castra", "arig", "hyarion", "tellus",
		"corrundum", "apia-carnova-orbit", "moshine", "panglia",
		"dea-dia-system-edge", "ribbonia", "paracelsin", "shchierbin",
		"secretas", "crucible-orbit", "frozeta"
	}
	local planets = {
		"nauvis", "muria", "aquilo", "rubia", "maraxsis", "cubium",
		"tenebris", "crucible", "vesta", "linox-planet_linox"
	}
	local space_locations = {}
	local planet_locations = {}
	for _, name in ipairs(places) do
		space_locations[name] = {name = name}
	end
	for _, name in ipairs(planets) do
		planet_locations[name] = {name = name}
	end

	local native_crucible = {
		type = "space-connection", name = "native-crucible-orbit",
		from = "crucible-orbit", to = "crucible", length = 2000
	}
	local native_dea_dia = {
		type = "space-connection", name = "native-dea-dia-internal",
		from = "dea-dia-system-edge", to = "lemures", length = 1500
	}
	rawset(_G, "data", mock_data({
		planet = planet_locations,
		["space-location"] = space_locations,
		["space-connection"] = {
			["outdated-cross-shortcut"] = {
				type = "space-connection", name = "outdated-cross-shortcut",
				from = "sye-calidus", to = "sye-vibrant"
			},
			["outdated-muria"] = {
				type = "space-connection", name = "outdated-muria",
				from = "sye-vibrant", to = "muria"
			},
			["old-tenebris-link"] = {
				type = "space-connection", name = "old-tenebris-link",
				from = "sye-beetlejuice", to = "tenebris"
			},
			["native-crucible-orbit"] = native_crucible,
			["native-dea-dia-internal"] = native_dea_dia
		}
	}))
	local spawn_module = "__space-age__.prototypes.planet.asteroid-spawn-definitions"
	package.loaded[spawn_module] = {
		nauvis_fulgora = {}, fulgora_aquilo = {}, gleba_aquilo = {},
		aquilo_solar_system_edge = {},
		spawn_definitions = function() return {} end
	}

	local reconciliation = reload("prototypes.system.route_reconcile")
	reconciliation.data_final_fixes()
	local routes = data.raw["space-connection"]
	check(routes["outdated-cross-shortcut"] == nil, "Calidus bypass survived")
	check(routes["outdated-muria"] == nil, "Stale Vibrant/Muria route survived")
	check(routes["old-tenebris-link"] == nil, "Stale Beetlejuice/Tenebris route survived")
	check(routes["native-crucible-orbit"] == native_crucible, "Crucible's native route removed")
	check(routes["native-dea-dia-internal"] == native_dea_dia, "Dea Dia internal route removed")
	for _, name in ipairs({
		"razi-sye-calidus-sye-nyxaris",
		"razi-sye-solaris-sye-vibrant",
		"razi-sye-nyxaris-sye-vespera",
		"razi-sye-vespera-muria",
		"razi-sye-umbra-tenebris",
		"razi-secretas-solar-system-edge",
		"razi-vesta-solar-system-edge"
	}) do
		check(routes[name] ~= nil, "Required route missing: " .. name)
	end

	local before = 0
	for _ in pairs(routes) do before = before + 1 end
	reconciliation.data_final_fixes()
	local after = 0
	for _ in pairs(routes) do after = after + 1 end
	check(before == after, "Route reconciliation is not idempotent")
end

local function list_contains(values, wanted)
	for _, value in ipairs(values or {}) do
		if value == wanted then return true end
	end
	return false
end

local function test_research()
	local technology_names = {
		"solaris-discovery", "nyxaris-discovery", "vibrant-discovery",
		"beetlejuice-discovery", "stellar-discovery-solar-system-edge",
		"planet-discovery-vulcanus", "planet-discovery-fulgora",
		"planet-discovery-gleba", "planet-discovery-muluna",
		"planet-discovery-castra", "planet-discovery-arig",
		"planet-discovery-hyarion", "planet-discovery-tellus",
		"planet-discovery-corrundum", "planet-discovery-apia-carnova",
		"planet-discovery-moshine", "panglia_planet_discovery_panglia",
		"planet-discovery-ribbonia", "planet-discovery-paracelsin",
		"planet-discovery-shchierbin", "planet-discovery-muria",
		"planet-discovery-aquilo", "planet-discovery-rubia",
		"planet-discovery-maraxsis", "planet-discovery-cubium",
		"planet-discovery-secretas", "planet-discovery-frozeta",
		"planet-discovery-tenebris", "planet-discovery-crucible",
		"planet-discovery-vesta", "linox-technology_planet-discovery-linox",
		"promethium-science-pack"
	}
	local technologies = {}
	for _, name in ipairs(technology_names) do
		technologies[name] = {
			type = "technology", name = name,
			prerequisites = {},
			unit = {count = 100, time = 30, ingredients = {{"space-science-pack", 1}}}
		}
	end
	local cards = {
		"calidus-tech-card", "solaris-tech-card", "nyxaris-tech-card",
		"vibrant-tech-card", "vespera-tech-card", "beetlejuice-tech-card",
		"umbra-tech-card"
	}
	local tools = {}
	for _, card in ipairs(cards) do tools[card] = {name = card} end
	rawset(_G, "data", mock_data({
		technology = technologies,
		tool = tools,
		["space-location"] = {}
	}))
	rawset(_G, "science_pack_exists", function(name)
		return data.raw.tool[name] ~= nil
	end)
	rawset(_G, "add_existing_prerequisites", function(name, candidates)
		local target = data.raw.technology[name]
		if not target then return end
		for _, candidate in ipairs(candidates) do
			if data.raw.technology[candidate]
				and not list_contains(target.prerequisites, candidate) then
				target.prerequisites[#target.prerequisites + 1] = candidate
			end
		end
	end)

	reload("prototypes.technology.seven_systems")
	reload("prototypes.technology.seven_system_gates").data_final_fixes()
	check(technologies["vespera-discovery"] ~= nil, "Vespera gate missing")
	check(technologies["umbra-discovery"] ~= nil, "Umbra gate missing")

	local nyxaris = technologies["nyxaris-discovery"]
	check(not list_contains(nyxaris.prerequisites, "planet-discovery-corrundum"),
		"Nyxaris still requires Solaris completion")
	local tellus = technologies["planet-discovery-tellus"]
	check(list_contains(tellus.prerequisites, "planet-discovery-arig"), "Arig branch missing")
	check(list_contains(tellus.prerequisites, "planet-discovery-hyarion"), "Hyarion branch missing")
	local vespera = technologies["vespera-discovery"]
	check(list_contains(vespera.prerequisites, "planet-discovery-corrundum"),
		"Vespera unlocked without Solaris mastery")
	check(list_contains(vespera.prerequisites, "panglia_planet_discovery_panglia"),
		"Vespera unlocked without Nyxaris mastery")
	check(list_contains(technologies["planet-discovery-muria"].prerequisites, "vespera-discovery"),
		"Muria lacks Vespera entry gate")
	check(list_contains(technologies["planet-discovery-tenebris"].prerequisites, "umbra-discovery"),
		"Tenebris lacks Umbra entry gate")
	local edge = technologies["stellar-discovery-solar-system-edge"]
	check(list_contains(edge.prerequisites, "razi-outer-frontier-mastery"),
		"Deep Space can bypass outer-system mastery")
	local outer = technologies["razi-outer-frontier-mastery"]
	check(list_contains(outer.prerequisites, "planet-discovery-frozeta"),
		"Outer mastery does not require Beetlejuice")
	check(list_contains(outer.prerequisites, "planet-discovery-vesta"),
		"Outer mastery does not require Umbra")
end

test_routes()
test_research()
print("Seven-system route and technology fixtures passed")
