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
		"sye-calidus", "razi-calidus-drift", "sye-solaris", "sye-nyxaris", "sye-vibrant",
		"sye-vespera", "sye-beetlejuice", "sye-umbra",
		"razi-vespera-belt-inner","razi-vespera-belt-outer",
		"razi-umbra-belt-inner","razi-umbra-belt-outer",
		"asteroid-belt-inner-edge","asteroid-belt-outer-edge",
		"solar-system-edge", "castra", "arig", "hyarion", "tellus",
		"corrundum", "apia-carnova-orbit", "moshine",
		"dea-dia-system-edge", "ribbonia", "paracelsin",
		"secretas", "crucible-orbit", "frozeta"
	}
	local planets = {
		"nauvis", "muluna", "vulcanus", "gleba", "fulgora",
		"panglia", "muria", "aquilo", "rubia", "maraxsis", "cubium",
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
	local original_belt = {
		type="space-connection",
		name="asteroid-belt-inner-edge-asteroid-belt-outer-edge",
		from="asteroid-belt-inner-edge",to="asteroid-belt-outer-edge",
		length=5000,
		asteroid_spawn_definitions={{
			type="asteroid-chunk",asteroid="native-source-belt-ore",
			spawn_points={{distance=0.5,probability=0.2,speed=1}}
		}}
	}
	rawset(_G, "data", mock_data({
		planet = planet_locations,
		["space-location"] = space_locations,
		["space-connection"] = {
			["outdated-cross-shortcut"] = {
				type = "space-connection", name = "outdated-cross-shortcut",
				from = "sye-solaris", to = "sye-vespera"
			},
			["outdated-muria"] = {
				type = "space-connection", name = "outdated-muria",
				from = "sye-vibrant", to = "muria"
			},
			["old-tenebris-link"] = {
				type = "space-connection", name = "old-tenebris-link",
				from = "sye-beetlejuice", to = "tenebris"
			},
            ["old-inner-to-frozen"] = {
                type="space-connection",name="old-inner-to-frozen",
                from="ribbonia",to="paracelsin",length=3000
            },
            ["old-factory-belt-bypass"] = {
                type="space-connection",name="old-factory-belt-bypass",
                from="fulgora",to="paracelsin",length=3000
            },
			["old-direct-aquilo-rubia"] = {
                type="space-connection", from="aquilo", to="rubia",
                asteroid_spawn_definitions={{
                  type="asteroid-chunk", asteroid="obsidiax-asteroid-chunk",
                  spawn_points={{distance=0.45,probability=0.11,speed=2}}
                }}
            },
            ["old-interstar-vesta-secretas"] = {
                type="space-connection", from="vesta", to="secretas",
                length=23000
            },
            ["native-rubia-maraxsis"] = {
                type="space-connection", from="rubia", to="maraxsis",
                length=20000
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
			[original_belt.name] = original_belt,
			["old-belt-shortcut"]={
				type="space-connection",from="fulgora",
				to="asteroid-belt-inner-edge",length=2000
			},
			["old-belt-exit"]={
				type="space-connection",from="asteroid-belt-outer-edge",
				to="aquilo",length=2000
			},
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
	check(routes["outdated-cross-shortcut"] == nil, "Obsolete perimeter route survived")
	check(routes["outdated-muria"] == nil, "Stale Vibrant/Muria route survived")
	check(routes["old-tenebris-link"] == nil, "Stale Beetlejuice/Tenebris route survived")
    check(routes["old-inner-to-frozen"] == nil
      and routes["old-factory-belt-bypass"] == nil,
      "Native Vibrant belt can be bypassed by a same-system source route")
    check(routes["old-direct-aquilo-rubia"] == nil,
      "Vespera belt has a direct bypass")
    check(routes["old-direct-crucible-vesta"] == nil,
      "Umbra belt has a direct bypass")
    check(routes["old-interstar-vesta-secretas"] == nil,
      "Cheap cross-star Vesta/Secretas route bypassed the Umbra belt")
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
	-- Diagonal cross-tier links made the sky map a mesh of crossed lines.
	-- The two branching lanes and native belt gateway provide connectivity.
	for _, pair in ipairs({
		{"sye-solaris","sye-vespera"},
		{"sye-nyxaris","sye-vibrant"},
		{"sye-vibrant","sye-umbra"},
		{"sye-vibrant","sye-vespera"},
		{"sye-vespera","sye-beetlejuice"}
	}) do
		for _, link in pairs(routes) do
			check(not ((link.from == pair[1] and link.to == pair[2])
				or (link.to == pair[1] and link.from == pair[2])),
				"Legacy crossing survived: " .. pair[1] .. "/" .. pair[2])
		end
	end
  -- Eight interstellar routes, not the twelve-line hub-and-ring mesh.
  local required_interstellar = {
    {"sye-calidus","sye-solaris",60000},
    {"sye-calidus","sye-nyxaris",65000},
    {"sye-solaris","sye-nyxaris",82000},
    {"sye-solaris","sye-vibrant",100000},
    {"sye-nyxaris","sye-vespera",90000},
    {"sye-vespera","sye-umbra",120000},
    {"sye-beetlejuice","sye-umbra",150000},
  }
  local allowed_interstellar = {}
  for _, info in ipairs(required_interstellar) do
    local key=info[1].."|"..info[2]
    allowed_interstellar[key]=true
    local name="razi-"..info[1].."-"..info[2]
    local route=routes[name]
    check(route and route.length==info[3] and route.shape=="line",
      "Required constellation corridor missing: "..name)
  end
  local hub={"sye-calidus","sye-solaris","sye-nyxaris",
    "sye-vibrant","sye-vespera","sye-beetlejuice","sye-umbra"}
  local hub_set={}
  for _,name in ipairs(hub) do hub_set[name]=true end
  local count=0
  for _,route in pairs(routes) do
    if hub_set[route.from] and hub_set[route.to] then
      count=count+1
      local k=route.from.."|"..route.to
      check(allowed_interstellar[k],
        "Unwanted hub spoke or ring arc: "..k)
    end
  end
  check(count==7,"Expected seven direct interstellar corridors")
  for name,km in pairs({
    ["razi-nauvis-razi-calidus-drift"]=12000,
    ["razi-razi-calidus-drift-sye-calidus"]=17500,
    ["razi-muluna-sye-calidus"]=14000
  }) do
    local route=routes[name]
    check(route and route.length==km and route.shape=="arc",
      "Calidus freight route missing: "..name)
  end
  check(routes["razi-sye-calidus-sye-vibrant"]==nil,
    "Home system shortcut bypassed the first frontier")
  check(routes["razi-sye-vibrant-sye-beetlejuice"]==nil,
    "A direct route bypasses the native asteroid belt")
  check(routes["razi-ribbonia-asteroid-belt-inner-edge"]~=nil,
    "Missing inner entry to native asteroid belt")
  check(routes["razi-asteroid-belt-outer-edge-paracelsin"]~=nil,
    "Missing outer exit to Paracelsin")

    check(routes["razi-vulcanus-arig"]==nil,
      "Retired crossing line must not appear across Solaris")
    for _, local_link in ipairs({
        {"razi-vulcanus-hyarion",20000},
        {"razi-hyarion-corrundum",22500},
        {"razi-gleba-apia-carnova-orbit",22000},
                {"razi-vulcanus-castra",17500},
        {"razi-arig-hyarion",12000},
        {"razi-gleba-moshine",17000},
        {"razi-moshine-apia-carnova-orbit",12000},
        {"razi-moshine-panglia",25000},
        {"razi-apia-carnova-orbit-panglia",21000},
        {"razi-asteroid-belt-outer-edge-paracelsin",14000},
        {"razi-linox-planet_linox-secretas",22000},
        {"razi-sye-umbra-crucible-orbit",17000}
    }) do
        local connection=routes[local_link[1]]
        check(connection and connection.length==local_link[2],
          "Missing local neighboring-world shuttle: "..local_link[1])
        check(connection.shape=="arc",
          "Neighbor shuttle incorrectly became an interstellar line")
    end
	check(routes["native-crucible-orbit"] == native_crucible, "Crucible's native route removed")
    check(routes["native-rubia-maraxsis"].length == 20000,
      "Maraxsis's native 20,000 km local route was overwritten")
    check(routes["cubium-secretas"].length >= 14000,
      "A legacy 1,000 km route trivializes outer-system travel")
	check(routes["native-dea-dia-internal"] == native_dea_dia, "Dea Dia internal route removed")
	check(routes[original_belt.name]==original_belt,
		"Original AsteroidBelt crossing was replaced or lost")
	check(original_belt.length==5000
		and original_belt.asteroid_spawn_definitions[1].asteroid
		=="native-source-belt-ore",
		"Original source belt length/asteroid loot was changed")
	check(not routes["old-belt-shortcut"] and not routes["old-belt-exit"],
		"Source belt bypass survived outer-tier reconciliation")
	for _,pair in ipairs({
		{"ribbonia","asteroid-belt-inner-edge"},
        {"asteroid-belt-outer-edge","paracelsin"},
		{"asteroid-belt-outer-edge","sye-beetlejuice"}
	}) do
		local present=false
		for _,conn in pairs(routes) do
			if (conn.from==pair[1] and conn.to==pair[2])
				or (conn.from==pair[2] and conn.to==pair[1]) then
				present=true
			end
		end
		check(present,"Missing native-belt chapter link "..pair[1])
	end
	for _,pair in ipairs({
		{"sye-nyxaris","sye-vibrant"},
		{"sye-solaris","sye-vespera"}
	}) do
		for _,conn in pairs(routes) do
			check(not ((conn.from==pair[1] and conn.to==pair[2])
				or (conn.from==pair[2] and conn.to==pair[1])),
				"Diagonal research shortcut appeared")
		end
	end
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
        "razi-sye-calidus-sye-solaris",
        "razi-sye-calidus-sye-nyxaris",
        "razi-sye-solaris-sye-vibrant",
        "razi-sye-nyxaris-sye-vespera",
        "razi-sye-vespera-sye-umbra",
        "razi-sye-solaris-sye-nyxaris",
        "razi-sye-beetlejuice-sye-umbra",
        "razi-sye-vespera-muria",
        "razi-sye-umbra-tenebris",
        "razi-secretas-solar-system-edge",
        "razi-vesta-solar-system-edge"
	}) do
		check(routes[name] ~= nil, "Required route missing: " .. name)
		check(routes[name].icon ~= nil or routes[name].icons ~= nil,
			"Required route has no Factorio 2.1 icon: " .. name)
		check(routes[name].icon_size == 64 or routes[name].icons ~= nil,
			"Required route icon size does not match its PNG: " .. name)
	end

    for _, spec in ipairs({
      {"razi-asteroid-belt-outer-edge-sye-beetlejuice", 85000},
      {"razi-secretas-solar-system-edge", 155000},
      {"razi-vesta-solar-system-edge", 185000}
    }) do
      local link = routes[spec[1]]
      check(link and link.length == spec[2],
        "Cross-system distance violates progressive star map: "..spec[1])
    end
    check(routes["razi-razi-vespera-belt-inner-razi-vespera-belt-outer"].length == 6500,
      "Vespera belt encounter was made longer than intended")
    check(routes["razi-razi-umbra-belt-inner-razi-umbra-belt-outer"].length == 8000,
      "Umbra belt encounter was made longer than intended")
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
		"space-discovery-asteroid-belt",
		"planet-discovery-vulcanus", "planet-discovery-fulgora",
		"planet-discovery-gleba", "planet-discovery-muluna",
		"planet-discovery-castra", "planet-discovery-arig",
		"planet-discovery-hyarion", "planet-discovery-tellus",
		"planet-discovery-corrundum", "planet-discovery-apia-carnova",
		"planet-discovery-moshine", "panglia_planet_discovery_panglia",
		"planet-discovery-ribbonia", "planet-discovery-paracelsin",
		"planet-discovery-muria",
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
	-- The source discovery uses Moshine data cells and a real foundry.
	technologies["panglia_planet_discovery_panglia"].prerequisites = {
		"foundry","agricultural-science-pack","moshine-tech-data-extractor"
	}
	technologies["panglia_planet_discovery_panglia"].unit = {
		count=250,time=60,ingredients={{"datacell-raw-data",1}}
	}
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
	-- The data stage loads helpers from util.lua, but this gate now
	-- implements its checks locally. Test that without mock globals.
	rawset(_G,"science_pack_exists",nil)
	rawset(_G,"add_existing_prerequisites",nil)

	reload("prototypes.technology.seven_systems")
	reload("prototypes.technology.seven_system_gates").data_final_fixes()
	check(technologies["vespera-discovery"] ~= nil, "Vespera gate missing")
	check(technologies["umbra-discovery"] ~= nil, "Umbra gate missing")
	for _,outer in ipairs({"beetlejuice-discovery","umbra-discovery"}) do
		check(list_contains(technologies[outer].prerequisites,
			"space-discovery-asteroid-belt"),
			outer.." does not require original AsteroidBelt exploration")
	end

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
		"Panglia must contribute to Nyxaris mastery")
	-- A third-party discovery may be moved behind its prospective gateway.
	-- In that case, skip the circular prerequisite instead of softlocking
	-- both systems. Ordinary independent worlds remain required.
	local panglia_node=technologies["panglia_planet_discovery_panglia"]
	local original_panglia_parents=panglia_node.prerequisites
	local moved={}
	for _,parent in ipairs(original_panglia_parents) do moved[#moved+1]=parent end
	moved[#moved+1]="vespera-discovery"
	panglia_node.prerequisites=moved
	reload("prototypes.technology.seven_system_gates").data_final_fixes()
	check(not list_contains(technologies["vespera-discovery"].prerequisites,
		"panglia_planet_discovery_panglia"),
		"Gateway research acquired a cycle through optional source research")
	panglia_node.prerequisites=original_panglia_parents
	reload("prototypes.technology.seven_system_gates").data_final_fixes()
	check(list_contains(technologies["vespera-discovery"].prerequisites,
		"panglia_planet_discovery_panglia"),
		"Safe upstream mastery was not restored after a source-mod change")

	local panglia=technologies["panglia_planet_discovery_panglia"]
	check(list_contains(panglia.prerequisites,"planet-discovery-moshine")
	  and list_contains(panglia.prerequisites,"planet-discovery-apia-carnova"),
	  "Panglia must follow Moshine and Apia/Carnova")
	check(list_contains(panglia.prerequisites,"foundry") and
	  panglia.unit.ingredients[1][1]=="datacell-raw-data",
	  "Panglia native data-cell and foundry research was overwritten")
	check(list_contains(vespera.prerequisites, "planet-discovery-apia-carnova"),
		"Vespera unlocked without Nyxaris mastery")
	check(list_contains(technologies["planet-discovery-muria"].prerequisites, "vespera-discovery"),
		"Muria lacks Vespera entry gate")
	check(list_contains(technologies["planet-discovery-tenebris"].prerequisites, "umbra-discovery"),
		"Tenebris lacks Umbra entry gate")
    check(list_contains(technologies["planet-discovery-rubia"].prerequisites,
      "razi-vespera-belt-survey"), "Rubia bypasses its belt survey")
    check(list_contains(technologies["planet-discovery-vesta"].prerequisites,
      "razi-umbra-belt-survey"), "Vesta bypasses its belt survey")
  check(list_contains(technologies["planet-discovery-paracelsin"].prerequisites,
    "space-discovery-asteroid-belt"),"Icy Paracelsin unlocked before the belt")
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
