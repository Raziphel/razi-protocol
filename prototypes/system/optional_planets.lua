-- Additional independent planet mods join Razi's seven-system campaign.
-- Keep their native science, entities, surfaces and research chains intact.
-- No planet added here is required to reach Deep Space.
local optional_planets = {}
local asteroid_util = require("__space-age__.prototypes.planet.asteroid-spawn-definitions")

-- Mod ID, planet prototype, host star, transit hub, native discovery gate,
-- orbital radius/orientation, and local route length.
-- Rabbasca is a moon of Gleba: preserve its actual moon orbit and native
-- Gleba connection, as well as its special bunnyhop/rocket limitations.
local additions = {
	{"Igrys", "igrys", "solaris", "sye-solaris", "solaris-discovery",
		24, 0.78, 17000},
	{"foliax", "foliax", "nyxaris", "sye-nyxaris", "nyxaris-discovery",
		30, 0.68, 18500},
	{"obsidiax", "obsidiax", "vespera", "sye-vespera", "vespera-discovery",
		32, 0.77, 21000},
	{"carna", "carna", "umbra", "sye-umbra", "umbra-discovery",
		29, 0.61, 20500},
	{"PlanetAthos", "athos", "solaris", "sye-solaris", "solaris-discovery",
		31, 0.90, 19000},
	{"planet-rabbasca", "rabbasca", "nyxaris", "gleba",
		"planet-discovery-gleba", nil, nil, 13000}
}

local home_systems = {
	nauvis = "calidus", vulcanus = "solaris", fulgora = "vibrant",
	gleba = "nyxaris", aquilo = "vespera",
	["sye-calidus"] = "calidus", ["sye-solaris"] = "solaris",
	["sye-nyxaris"] = "nyxaris", ["sye-vibrant"] = "vibrant",
	["sye-vespera"] = "vespera", ["sye-beetlejuice"] = "beetlejuice",
	["sye-umbra"] = "umbra", ["solar-system-edge"] = "deep-space"
}

local function get_location(name)
	return (data.raw.planet and data.raw.planet[name])
		or (data.raw["space-location"] and data.raw["space-location"][name])
end

local function pair_key(a, b)
	if a > b then a, b = b, a end
	return a .. "|" .. b
end

local function has_prerequisite(tech_name, desired, visited)
	if tech_name == desired then return true end
	visited = visited or {}
	if visited[tech_name] then return false end
	visited[tech_name] = true
	local tech = data.raw.technology and data.raw.technology[tech_name]
	if not tech then return false end
	for _, prerequisite in ipairs(tech.prerequisites or {}) do
		if has_prerequisite(prerequisite, desired, visited) then
			return true
		end
	end
	return false
end

local function gate_discovery(location_name, host_gate)
	local technology = data.raw.technology or {}
	if not technology[host_gate] then return end

	-- Discover the correct source-mod technology by its native unlock effect.
	-- This preserves the original research cost, trigger and other effects.
	for tech_name, tech in pairs(technology) do
		for _, effect in ipairs(tech.effects or {}) do
			if effect.type == "unlock-space-location" and
				effect.space_location == location_name then
				-- Guard against accidentally introducing a prerequisite cycle.
				if not has_prerequisite(host_gate, tech_name) and
					not has_prerequisite(tech_name, host_gate) then
					tech.prerequisites = tech.prerequisites or {}
					tech.prerequisites[#tech.prerequisites + 1] = host_gate
				end
			end
		end
	end
end

local function attach_route(location_name, hub, length, system)
	local routes = data.raw["space-connection"] or {}
	local wanted = pair_key(location_name, hub)
	-- Maintain the mod's original connection name and asteroid definitions
	-- when its endpoints already match our chosen location/host pair.
	for _, connection in pairs(routes) do
		if pair_key(connection.from, connection.to) == wanted then
			return
		end
	end

	local source = asteroid_util.nauvis_fulgora
	if system == "umbra" or system == "vespera" then
		source = asteroid_util.fulgora_aquilo or source
	end
	data:extend({{
		type = "space-connection",
		name = "razi-optional-" .. location_name .. "-" .. hub,
		from = hub,
		to = location_name,
		length = length,
		asteroid_spawn_definitions = asteroid_util.spawn_definitions(source)
	}})
end

local function remove_cross_system_routes(location_name, system)
	local routes = data.raw["space-connection"] or {}
	for name, connection in pairs(routes) do
		local other
		if connection.from == location_name then other = connection.to end
		if connection.to == location_name then other = connection.from end
		-- Only reconcile known core-system endpoints. Never touch special
		-- source-mod stargates, sister moons, or unidentified transit routes.
		if other and home_systems[other] and home_systems[other] ~= system then
			routes[name] = nil
		end
	end
end

function optional_planets.data_final_fixes()
	for _, addition in ipairs(additions) do
		local mod_name, location_name, host_system, hub, gate, radius, orientation, length =
			addition[1], addition[2], addition[3], addition[4], addition[5],
			addition[6], addition[7], addition[8]
		local planet = data.raw.planet and data.raw.planet[location_name]
		if mods[mod_name] and planet and get_location(hub) then
			-- Keep Rabbasca's moon-of-Gleba identity, plus native landing rules.
			-- The other planets adopt their chosen system's orbital family.
			if radius and data.raw["space-location"] and
				data.raw["space-location"][host_system] then
				PlanetsLib:update({{
					type = "planet",
					name = location_name,
					orbit = {
						parent = {type = "space-location", name = host_system},
						distance = radius,
						orientation = orientation
					}
				}})
			end
			gate_discovery(location_name, gate)
			if location_name ~= "rabbasca" then
				remove_cross_system_routes(location_name, host_system)
			end
			attach_route(location_name, hub, length, host_system)
		end
	end
end

return optional_planets
