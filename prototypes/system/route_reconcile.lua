-- The last word on Razi-owned routes. This must run after source mod fixes.
-- Preserve native intra-system routes (especially Apia, Crucible and Bellicos).
local route_reconcile = {}
local hazard_profiles = require("prototypes.system.asteroid_profiles")

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
	rubia = "vespera", maraxsis = "vespera",
	-- Beetlejuice and Umbra.
	["sye-beetlejuice"] = "beetlejuice", cubium = "beetlejuice",
	["linox-planet_linox"] = "beetlejuice", secretas = "beetlejuice",
	frozeta = "beetlejuice",
	["sye-umbra"] = "umbra", tenebris = "umbra",
	["crucible-orbit"] = "umbra", crucible = "umbra", vesta = "umbra",
	["solar-system-edge"] = "deep-space"
}

local route_specifications = {
	-- Parallel chapter entrances and neighbor-system crosslinks.
	{"sye-calidus", "sye-solaris", 60000, "first_crossing"},
	{"sye-calidus", "sye-nyxaris", 65000, "first_crossing"},
	{"sye-solaris", "sye-nyxaris", 32000, "frontier_crosslink"},
	{"sye-solaris", "sye-vibrant", 95000, "middle_crossing"},
	{"sye-nyxaris", "sye-vespera", 95000, "middle_crossing"},
	{"sye-vibrant", "sye-vespera", 38000, "middle_crosslink"},
	{"sye-vibrant", "sye-beetlejuice", 130000, "outer_crossing"},
	{"sye-vespera", "sye-umbra", 130000, "outer_crossing"},
	{"sye-beetlejuice", "sye-umbra", 45000, "outer_crosslink"},
	-- Solaris's twin opening branches.
	{"sye-solaris", "vulcanus", 18000, "industrial"},
	{"sye-solaris", "castra", 12000, "industrial"},
	{"castra", "arig", 15000, "industrial"},
	{"castra", "hyarion", 15000, "industrial"},
	{"arig", "tellus", 16500, "industrial_deep"},
	{"hyarion", "tellus", 16500, "industrial_deep"},
	{"tellus", "corrundum", 18000, "industrial_deep"},
	-- Nyxaris. Optional Dea Dia keeps its own native internal network.
	{"sye-nyxaris", "gleba", 18000, "biological"},
	{"sye-nyxaris", "apia-carnova-orbit", 17000, "biological"},
	{"sye-nyxaris", "moshine", 18000, "biological"},
	{"sye-nyxaris", "panglia", 18000, "biological_deep"},
	{"panglia", "pelagos", 16000, "biological_deep"},
	{"sye-nyxaris", "dea-dia-system-edge", 20000, "biological_deep"},
	-- Vibrant's chemistry strand.
	{"sye-vibrant", "fulgora", 17000, "electrical"},
	{"fulgora", "ribbonia", 17500, "electrical"},
	{"sye-vibrant", "ribbonia", 17000, "electrical"},
	{"ribbonia", "paracelsin", 18000, "chemistry"},
	{"paracelsin", "shchierbin", 18000, "chemistry_deep"},
	-- Vespera's extreme-environment strand.
	{"sye-vespera", "muria", 19000, "cryogenic"},
	{"muria", "aquilo", 22000, "cryogenic"},
	{"aquilo", "rubia", 24000, "cryogenic_deep"},
	{"rubia", "maraxsis", 24000, "cryogenic_deep"},
	-- Beetlejuice's remote industrial strand.
	{"sye-beetlejuice", "cubium", 18000, "outer_industry"},
	{"cubium", "linox-planet_linox", 17000, "outer_industry"},
	{"cubium", "secretas", 19000, "outer_industry_deep"},
	{"secretas", "frozeta", 10500, "outer_industry_deep"},
	-- Umbra's extreme sciences. Crucible's native orbital link stays intact.
	{"sye-umbra", "tenebris", 18000, "outer_void"},
	{"tenebris", "crucible-orbit", 20000, "outer_void"},
	{"crucible-orbit", "vesta", 18000, "outer_void_deep"},
	{"vesta", "secretas", 23000, "outer_crosslink"},
	-- The outer branches converge at the conventional Deep Space edge.
	{"secretas", "solar-system-edge", 75000, "deep_edge"},
	{"vesta", "solar-system-edge", 75000, "deep_edge"}
}

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

function route_reconcile.data_final_fixes()
	local routes = data.raw["space-connection"] or {}

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
			local keep_name = routes[route_name] and route_name or nil

			-- Prefer the source's existing name: external compatibility modules
			-- refer to names such as "secretas-frozeta" to augment asteroid
			-- definitions. Only introduce razi-* when no source route exists.
			if not keep_name then
				for name, connection in pairs(routes) do
					if key_for(connection.from, connection.to) == pair then
						keep_name = name
						break
					end
				end
			end
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
				route.from, route.to, route.length = from, to, length
				hazard_profiles.apply(route, hazard)
			else
				data:extend({
					{
						type = "space-connection",
						name = route_name,
						from = from,
						to = to,
						length = length,
						asteroid_spawn_definitions = hazard_profiles.create(hazard)
					}
				})
			end
		end
	end
end

return route_reconcile
