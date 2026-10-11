-- The last word on Razi-owned routes. Run after all source mod fixes.
-- Preserve native intra-system routes (especially Apia, Crucible and Bellicos).
-- Interstellar graph: Calidus opens two branches, each advances through
-- midgame and outer systems, with only one first and one outer crosslink.
local route_reconcile = {}
local hazard_profiles = require("prototypes.system.asteroid_profiles")
local route_icons = require("prototypes.system.route_icons")

local membership = {
	-- Main game and Calidus.
	nauvis = "calidus", muluna = "calidus", eneas = "calidus",
	["sye-calidus"] = "calidus",
	vulcanus = "solaris",
	gleba = "nyxaris", rabbasca = "nyxaris",
	fulgora = "vibrant", cerys = "vibrant",
	-- Solaris and Nyxaris.
	["sye-solaris"] = "solaris", castra = "solaris", arig = "solaris",
	hyarion = "solaris", tellus = "solaris", corrundum = "solaris",
	["sye-nyxaris"] = "nyxaris", ["apia-carnova-orbit"] = "nyxaris",
	moshine = "nyxaris", panglia = "nyxaris", pelagos = "nyxaris",
	-- Vibrant, Vespera.
	["sye-vibrant"] = "vibrant", ribbonia = "vibrant",
	paracelsin = "vibrant", shchierbin = "vibrant",
	["sye-vespera"] = "vespera", muria = "vespera", aquilo = "vespera",
	["razi-vespera-belt-inner"] = "vespera",
	["razi-vespera-belt-outer"] = "vespera",
	rubia = "vespera", maraxsis = "vespera",
	-- Beetlejuice and Umbra.
	["sye-beetlejuice"] = "beetlejuice", cubium = "beetlejuice",
	["linox-planet_linox"] = "beetlejuice", secretas = "beetlejuice",
	frozeta = "beetlejuice",
	-- The required upstream AsteroidBelt remains a science gate for both
	-- outer discoveries; new Calidus spokes retain the original tech gates.
	["asteroid-belt-inner-edge"] = "mid-outer-belt",
	["asteroid-belt-outer-edge"] = "mid-outer-belt",
	["sye-umbra"] = "umbra", tenebris = "umbra",
	["razi-umbra-belt-inner"] = "umbra",
	["razi-umbra-belt-outer"] = "umbra",
	["crucible-orbit"] = "umbra", crucible = "umbra", vesta = "umbra",
	["solar-system-edge"] = "deep-space"
}

local route_specifications = {
  -- Two carefully staged expedition branches; do not redraw a web of
  -- redundant Calidus spokes. The fixed hexagonal star art stays unchanged.
  -- Research unlocks each destination hub independently of the visual path.
  {"nauvis", "sye-calidus", 25000, "starter"},
  {"sye-calidus", "sye-solaris", 60000, "first_crossing"},
  {"sye-calidus", "sye-nyxaris", 65000, "first_crossing"},
  -- After the two first-frontier discoveries, each strand continues
  -- outward to its own middle system rather than through Calidus.
  {"sye-solaris", "sye-vibrant", 100000, "middle_crosslink"},
  {"sye-nyxaris", "sye-vespera", 90000, "middle_crosslink"},
  -- Outer systems remain locked behind their original science requirements,
  -- especially space-discovery-asteroid-belt.
  {"sye-vespera", "sye-umbra", 120000, "outer_crosslink"},
  -- Only two meaningful lateral connections: a first-tier cargo bridge
  -- and a late-game crosslink. They avoid diagonals through Calidus.
  {"sye-solaris", "sye-nyxaris", 82000, "frontier_crosslink"},
  {"sye-beetlejuice", "sye-umbra", 150000, "outer_ring_crosslink"},
  -- The 5,000 km source-owned AsteroidBelt is a mandatory science step.
  -- Keep its source asteroids, route names and original loot untouched.
  {"ribbonia", "asteroid-belt-inner-edge", 24000, "chemistry_deep"},
  {"asteroid-belt-outer-edge", "shchierbin", 16000, "chemistry_deep"},
  {"asteroid-belt-outer-edge", "sye-beetlejuice", 85000, "outer_crossing"},
	-- Solaris's twin opening branches.
	{"sye-solaris", "vulcanus", 18000, "industrial"},
	{"sye-solaris", "castra", 21000, "industrial"},
	{"castra", "arig", 18000, "industrial"},
	{"castra", "hyarion", 22000, "industrial"},
	{"arig", "tellus", 16500, "industrial_deep"},
	{"hyarion", "tellus", 16500, "industrial_deep"},
	{"tellus", "corrundum", 18000, "industrial_deep"},
	-- Nyxaris. Optional Dea Dia keeps its own native internal network.
	{"sye-nyxaris", "gleba", 18000, "biological"},
	{"sye-nyxaris", "apia-carnova-orbit", 23000, "biological"},
	{"sye-nyxaris", "moshine", 22000, "biological"},
	{"sye-nyxaris", "panglia", 24000, "biological_deep"},
	{"panglia", "pelagos", 16000, "biological_deep"},
	{"sye-nyxaris", "dea-dia-system-edge", 20000, "biological_deep"},
	-- Vibrant's chemistry strand.
	{"sye-vibrant", "fulgora", 17000, "electrical"},
	{"fulgora", "ribbonia", 19500, "electrical"},
	{"sye-vibrant", "ribbonia", 23500, "electrical"},
	-- Frozen Paracelsin lies beyond the native AsteroidBelt crossing.
	{"shchierbin", "paracelsin", 22000, "chemistry_deep"},
	-- Vespera's extreme-environment strand.
	{"sye-vespera", "muria", 19000, "cryogenic"},
	{"muria", "aquilo", 22000, "cryogenic"},
	{"aquilo", "razi-vespera-belt-inner", 10500, "belt_vespera_approach"},
	{"razi-vespera-belt-inner", "razi-vespera-belt-outer", 6500, "belt_vespera_crossing"},
	{"razi-vespera-belt-outer", "rubia", 10500, "belt_vespera_departure"},
	{"rubia", "maraxsis", 24000, "cryogenic_deep"},
	-- Beetlejuice's remote industrial strand.
	{"sye-beetlejuice", "cubium", 18000, "outer_industry"},
	{"cubium", "linox-planet_linox", 17000, "outer_industry"},
	{"cubium", "secretas", 23000, "outer_industry_deep"},
	{"secretas", "frozeta", 10500, "outer_industry_deep"},
	-- Umbra's extreme sciences. Crucible's native orbital link stays intact.
	{"sye-umbra", "tenebris", 18000, "outer_void"},
	{"tenebris", "crucible-orbit", 20000, "outer_void"},
	{"crucible-orbit", "razi-umbra-belt-inner", 10000, "belt_umbra_approach"},
	{"razi-umbra-belt-inner", "razi-umbra-belt-outer", 8000, "belt_umbra_crossing"},
	{"razi-umbra-belt-outer", "vesta", 11000, "belt_umbra_departure"},
	-- The outer branches converge at the conventional Deep Space edge.
	{"secretas", "solar-system-edge", 155000, "deep_edge"},
	{"vesta", "solar-system-edge", 185000, "deep_edge"}
}

-- Paths replaced by physical belt detours. Retain original modded
-- asteroid-resource entries on the new dangerous central crossing.
local retired_belts = {
  {"aquilo", "rubia", "razi-vespera-belt-inner", "razi-vespera-belt-outer"},
  {"crucible-orbit", "vesta", "razi-umbra-belt-inner", "razi-umbra-belt-outer"}
}

local calidus_locations = {"nauvis", "muluna", "eneas", "sye-calidus"}

local function has_endpoint(name)
	return (data.raw.planet and data.raw.planet[name])
		or (data.raw["space-location"] and data.raw["space-location"][name])
end

local function key_for(a, b)
	if a > b then
		a, b = b, a
	end
	return a .. "|" .. b
end

local allowed = {}
for _, specification in ipairs(route_specifications) do
	allowed[key_for(specification[1], specification[2])] = true
end
-- Source authors sometimes tune travel time for a planet's own route.
-- Respect those values if they are near the new system's intended range,
-- rather than overwriting a native 20,000 km crossing with an arbitrary
-- round number. Very short/long legacy routes are bounded to stop moving
-- planets between stars from creating a 1,000 km interplanetary shortcut.
local function balanced_length(name, actual, planned, from, to)
	if not name or name:sub(1, 5) == "razi-" then return planned end
	if membership[from] ~= membership[to] then return planned end
	if type(actual) ~= "number" or actual <= 0 then return planned end
	local minimum = math.floor(planned * 0.75 / 500 + 0.5) * 500
	local maximum = math.floor(planned * 1.35 / 500 + 0.5) * 500
	return math.max(minimum, math.min(maximum, math.floor(actual + 0.5)))
end


function route_reconcile.data_final_fixes()
	local routes = data.raw["space-connection"] or {}
	local rescued = {}

	-- Remove only the two direct journeys now replaced by real belt hops.
	-- This must happen before new routes are created or the old connection
	-- would bypass the whole encounter.
	for _, old in ipairs(retired_belts) do
		if has_endpoint(old[3]) and has_endpoint(old[4]) then
			local obsolete = key_for(old[1], old[2])
			local destination = key_for(old[3], old[4])
			local preserved = {asteroid_spawn_definitions = {}}
			for name, connection in pairs(routes) do
				if key_for(connection.from, connection.to) == obsolete then
					hazard_profiles.preserve_custom(preserved, connection)
					routes[name] = nil
				end
			end
			rescued[destination] = preserved
		end
	end

	-- Stop cross-chapter shortcuts injected by dependencies, without deleting
	-- a single native route inside a chapter or unmanaged optional subsystem.
	for name, connection in pairs(routes) do
		local from_system = membership[connection.from]
		local to_system = membership[connection.to]
		if from_system and to_system and from_system ~= to_system then
			if not allowed[key_for(connection.from, connection.to)] then
				routes[name] = nil
			end
		end
	end

	for _, specification in ipairs(route_specifications) do
		local from, to, length, hazard = specification[1], specification[2], specification[3], specification[4]
		if has_endpoint(from) and has_endpoint(to) then
			local pair = key_for(from, to)
			local route_name = "razi-" .. from .. "-" .. to
			-- Choose source names first, deterministically; other mods may
			-- patch their asteroid tables by the original connection name.
			local matches = {}
			for name, connection in pairs(routes) do
				if key_for(connection.from, connection.to) == pair then
					matches[#matches + 1] = name
				end
			end
			table.sort(matches, function(a, b)
				local a_razi, b_razi = a:sub(1, 5) == "razi-", b:sub(1, 5) == "razi-"
				if a_razi ~= b_razi then return not a_razi end
				return a < b
			end)
			local keep_name = matches[1]

			for name, connection in pairs(routes) do
				if name ~= keep_name and key_for(connection.from, connection.to) == pair then
					if keep_name then
						hazard_profiles.preserve_custom(routes[keep_name], connection)
					end
					routes[name] = nil
				end
			end

			local route = keep_name and routes[keep_name]
			if route then
				route.from, route.to = from, to
				route.length = balanced_length(keep_name, route.length, length, from, to)
				if membership[from] and membership[to]
					and membership[from] ~= membership[to] then
					route.shape = "line"
				end
				hazard_profiles.apply(route, hazard)
				route_icons.assign(route, hazard)
			else
				local connection = route_icons.assign({
						type = "space-connection",
						name = route_name,
						from = from,
						to = to,
						length = length,
						shape = (membership[from] and membership[to]
                            and membership[from] ~= membership[to]) and "line" or "arc",
                        asteroid_spawn_definitions = hazard_profiles.create(hazard)
					}, hazard)
				data:extend({connection})
			end
		end
	end

	-- Save custom chunks from the two retired direct routes after constructing
	-- the replacement crossings. Never change their source spawn curves.
	for _, connection in pairs(routes) do
		local retained = rescued[key_for(connection.from, connection.to)]
		if retained then hazard_profiles.preserve_custom(connection, retained) end
	end

	-- No medium, big or huge vanilla asteroids anywhere *inside* Calidus.
	-- Cover source mod moon connections and parked platforms as well as the
	-- Razi-managed Nauvis launch route. Modded asteroids remain untouched.
	for _, location_name in ipairs(calidus_locations) do
		local location = (data.raw.planet and data.raw.planet[location_name])
			or (data.raw["space-location"] and data.raw["space-location"][location_name])
		if location then hazard_profiles.cap_sizes(location, "small") end
	end
	for _, connection in pairs(routes) do
		if membership[connection.from] == "calidus"
			and membership[connection.to] == "calidus" then
			hazard_profiles.cap_sizes(connection, "small")
		end
	end
end

return route_reconcile
