-- The last word on Razi-owned routes. This must run after source mod fixes.
-- Preserve native intra-system routes (especially Apia, Crucible and Bellicos).
local route_reconcile = {}
local asteroid_util = require("__space-age__.prototypes.planet.asteroid-spawn-definitions")

local membership = {
	-- Main game and Calidus.
	nauvis = "calidus", vulcanus = "calidus", fulgora = "calidus",
	gleba = "calidus", muluna = "calidus",
	["sye-calidus"] = "calidus", cerys = "calidus", eneas = "calidus",
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
	{"sye-calidus", "sye-solaris", 60000, "medium"},
	{"sye-calidus", "sye-nyxaris", 65000, "medium"},
	{"sye-solaris", "sye-nyxaris", 32000, "medium"},
	{"sye-solaris", "sye-vibrant", 95000, "medium"},
	{"sye-nyxaris", "sye-vespera", 95000, "medium"},
	{"sye-vibrant", "sye-vespera", 38000, "medium"},
	{"sye-vibrant", "sye-beetlejuice", 130000, "outer"},
	{"sye-vespera", "sye-umbra", 130000, "outer"},
	{"sye-beetlejuice", "sye-umbra", 45000, "outer"},
	-- Solaris's twin opening branches.
	{"sye-solaris", "castra", 12000, "early"},
	{"castra", "arig", 15000, "early"},
	{"castra", "hyarion", 15000, "early"},
	{"arig", "tellus", 16500, "early"},
	{"hyarion", "tellus", 16500, "early"},
	{"tellus", "corrundum", 18000, "early"},
	-- Nyxaris. Optional Dea Dia keeps its own native internal network.
	{"sye-nyxaris", "apia-carnova-orbit", 17000, "early"},
	{"sye-nyxaris", "moshine", 18000, "early"},
	{"sye-nyxaris", "panglia", 18000, "early"},
	{"panglia", "pelagos", 16000, "early"},
	{"sye-nyxaris", "dea-dia-system-edge", 20000, "early"},
	-- Vibrant's chemistry strand.
	{"sye-vibrant", "ribbonia", 17000, "medium"},
	{"ribbonia", "paracelsin", 18000, "medium"},
	{"paracelsin", "shchierbin", 18000, "medium"},
	-- Vespera's extreme-environment strand.
	{"sye-vespera", "muria", 19000, "medium"},
	{"muria", "aquilo", 22000, "medium"},
	{"aquilo", "rubia", 24000, "medium"},
	{"rubia", "maraxsis", 24000, "medium"},
	-- Beetlejuice's remote industrial strand.
	{"sye-beetlejuice", "cubium", 18000, "outer"},
	{"cubium", "linox-planet_linox", 17000, "outer"},
	{"cubium", "secretas", 19000, "outer"},
	{"secretas", "frozeta", 10500, "outer"},
	-- Umbra's extreme sciences. Crucible's native orbital link stays intact.
	{"sye-umbra", "tenebris", 18000, "outer"},
	{"tenebris", "crucible-orbit", 20000, "outer"},
	{"crucible-orbit", "vesta", 18000, "outer"},
	{"vesta", "secretas", 23000, "outer"},
	-- The outer branches converge at the conventional Deep Space edge.
	{"secretas", "solar-system-edge", 75000, "edge"},
	{"vesta", "solar-system-edge", 75000, "edge"}
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

local function asteroid_definitions(kind)
	local source = asteroid_util.nauvis_fulgora
	if kind == "outer" then
		source = asteroid_util.fulgora_aquilo or source
	elseif kind == "edge" then
		source = asteroid_util.aquilo_solar_system_edge or source
	elseif kind == "medium" then
		source = asteroid_util.gleba_aquilo or source
	end
	return asteroid_util.spawn_definitions(source)
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
					routes[name] = nil
				end
			end

			local route = keep_name and routes[keep_name]
			if route then
				route.from, route.to, route.length = from, to, length
				-- Keep source / Imersite additions intact. Supply the chapter
				-- hazard only when the upstream route has none of its own.
				if not route.asteroid_spawn_definitions or #route.asteroid_spawn_definitions == 0 then
					route.asteroid_spawn_definitions = asteroid_definitions(hazard)
				end
			else
				data:extend({
					{
						type = "space-connection",
						name = route_name,
						from = from,
						to = to,
						length = length,
						asteroid_spawn_definitions = asteroid_definitions(hazard)
					}
				})
			end
		end
	end
end

return route_reconcile
