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
		"razi-vespera-belt-inner","razi-vespera-belt-outer",
		"razi-umbra-belt-inner","razi-umbra-belt-outer",
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
			["old-direct-aquilo-rubia"] = {
                type="space-connection", from="aquilo", to="rubia",
                asteroid_spawn_definitions={{
                  type="asteroid-chunk", asteroid="obsidiax-asteroid-chunk",
                  spawn_points={{distance=0.45,probability=0.11,speed=2}}
                }}
            },
            ["old-direct-crucible-vesta"] = {
                type="space-connection", from="crucible-orbit", to="vesta",
                asteroid_spawn_definitions={{
                  type="entity", asteroid="carna-crystal-asteroid",
                  spawn_points={{distance=0.6,probability=0.09,speed=2}}
                }}
            },
            ["native-crucible-orbit"] = native_crucible,
			["native-dea-dia-internal"] = native_dea_dia,
			["razi-cubium-secretas"] = {
				type = "space-connection", name = "razi-cubium-secretas",
				from = "cubium", to = "secretas",
				asteroid_spawn_definitions = {{
					type = "entity", asteroid = "special-mod-asteroid",
					spawn_points = {{distance = 0.4, probability = 0.17, speed = 3}}
				}}
			},
			["cubium-secretas"] = {
				type = "space-connection", name = "cubium-secretas",
				from = "cubium", to = "secretas", length = 1000,
				asteroid_spawn_definitions = {{asteroid = "imersite", type = "asteroid"}}
			}
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
    check(routes["old-direct-aquilo-rubia"] == nil,
      "Vespera belt has a direct bypass")
    check(routes["old-direct-crucible-vesta"] == nil,
      "Umbra belt has a direct bypass")
    for _, crossing in ipairs({
      {"razi-razi-vespera-belt-inner-razi-vespera-belt-outer",
       "obsidiax-asteroid-chunk", 0.11},
      {"razi-razi-umbra-belt-inner-razi-umbra-belt-outer",
       "carna-crystal-asteroid", 0.09}
    }) do
      local connection = routes[crossing[1]]
      check(connection ~= nil, "Belt crossing not linked")
      local found = false
      for _, def in ipairs(connection.asteroid_spawn_definitions or {}) do
        if def.asteroid == crossing[2] then
          found = def.spawn_points[1].probability == crossing[3]
        end
      end
      check(found, "Retired native route lost a modded asteroid resource")
    end
	for _, pair in ipairs({
		{"sye-solaris","sye-vespera"},
		{"sye-nyxaris","sye-vibrant"},
		{"sye-vibrant","sye-umbra"},
		{"sye-vespera","sye-beetlejuice"}
	}) do
		local found = false
		for _, link in pairs(routes) do
			if ((link.from == pair[1] and link.to == pair[2])
				or (link.to == pair[1] and link.from == pair[2]))
				and link.shape == "line" then
				found = true
			end
		end
		check(found, "Missing straight interstellar diagonal " .. pair[1] .. "/" .. pair[2])
	end
	check(routes["native-crucible-orbit"] == native_crucible, "Crucible's native route removed")
	check(routes["native-dea-dia-internal"] == native_dea_dia, "Dea Dia internal route removed")
	check(routes["cubium-secretas"] ~= nil, "Original route name was replaced")
	check(routes["razi-cubium-secretas"] == nil, "Duplicate Razi route was not consolidated")
	local found_extra = false
	for _, asteroid in ipairs(routes["cubium-secretas"].asteroid_spawn_definitions or {}) do
		if asteroid.asteroid == "special-mod-asteroid" then
			found_extra = asteroid.spawn_points[1].probability == 0.17
		end
	end
	check(found_extra, "Duplicate route lost a modded asteroid's native spawn curve")
	local native_asteroids = routes["cubium-secretas"].asteroid_spawn_definitions or {}
	local first_asteroid = native_asteroids[1] or {}
	check(first_asteroid.asteroid == "imersite",
		"Imersite asteroid definitions were lost")
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
		"promethium-science-pack",
        "razi-vespera-belt-survey", "razi-umbra-belt-survey",
		"razi-singularity-theory", "razi-singularity-test-fire",
		"razi-stable-intergalactic-singularity"
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
		target.prerequisites = target.prerequisites or {}
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

	for _, first_star in ipairs({"solaris-discovery","nyxaris-discovery"}) do
		local departure_unlocked = false
		for _, effect in ipairs(technologies[first_star].effects or {}) do
			if effect.type == "unlock-space-location"
				and effect.space_location == "sye-calidus" then
				departure_unlocked = true
			end
		end
		check(departure_unlocked, first_star .. " cannot reach the departure hub")
	end
	local nyxaris = technologies["nyxaris-discovery"] or {prerequisites = {}}
	check(not list_contains(nyxaris.prerequisites, "planet-discovery-corrundum"),
		"Nyxaris still requires Solaris completion")
	local tellus = technologies["planet-discovery-tellus"] or {prerequisites = {}}
	check(list_contains(tellus.prerequisites, "planet-discovery-arig"), "Arig branch missing")
	check(list_contains(tellus.prerequisites, "planet-discovery-hyarion"), "Hyarion branch missing")
	local vespera = technologies["vespera-discovery"] or {prerequisites = {}}
	check(list_contains(vespera.prerequisites, "planet-discovery-corrundum"),
		"Vespera unlocked without Solaris mastery")
	check(list_contains(vespera.prerequisites, "panglia_planet_discovery_panglia"),
		"Vespera unlocked without Nyxaris mastery")
	check(list_contains(technologies["planet-discovery-muria"].prerequisites, "vespera-discovery"),
		"Muria lacks Vespera entry gate")
	check(list_contains(technologies["planet-discovery-tenebris"].prerequisites, "umbra-discovery"),
		"Tenebris lacks Umbra entry gate")
    check(list_contains(technologies["planet-discovery-rubia"].prerequisites,
      "razi-vespera-belt-survey"), "Rubia bypasses its belt survey")
    check(list_contains(technologies["planet-discovery-vesta"].prerequisites,
      "razi-umbra-belt-survey"), "Vesta bypasses its belt survey")
	local edge = technologies["stellar-discovery-solar-system-edge"] or {prerequisites = {}}
	check(list_contains(edge.prerequisites, "razi-outer-frontier-mastery"),
		"Deep Space can bypass outer-system mastery")
	local outer = technologies["razi-outer-frontier-mastery"] or {prerequisites = {}}
	check(list_contains(outer.prerequisites, "planet-discovery-frozeta"),
		"Outer mastery does not require Beetlejuice")
	check(list_contains(outer.prerequisites, "planet-discovery-vesta"),
		"Outer mastery does not require Umbra")
	for _, name in ipairs({
		"razi-singularity-theory",
		"razi-singularity-test-fire",
		"razi-stable-intergalactic-singularity"
	}) do
		local unit = technologies[name].unit
		local found_vespera, found_umbra = false, false
		for _, ingredient in ipairs(unit.ingredients) do
			local ingredient_name = ingredient.name or ingredient[1]
			if ingredient_name == "vespera-tech-card" then found_vespera = true end
			if ingredient_name == "umbra-tech-card" then found_umbra = true end
		end
		check(found_vespera and found_umbra, "Missing final card in " .. name)
	end
end

test_routes()
test_research()
print("Seven-system route and technology fixtures passed")
