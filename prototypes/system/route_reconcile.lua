-- Final route pass, after the individual planet and star-system mods.
-- Keep local planet connections while cleaning up the interstellar graph.
local route_reconcile = {}
local hazard_profiles = require("prototypes.system.asteroid_profiles")
local route_icons = require("prototypes.system.route_icons")
local layout = require("prototypes.system.galaxy_layout")

local membership = {
	-- Main game and Calidus.
	nauvis = "calidus", muluna = "calidus", ["alchemy-planet"] = "vibrant",
	["sye-calidus"] = "calidus",
	vulcanus = "solaris",
	gleba = "nyxaris", rabbasca = "nyxaris",
	fulgora = "vibrant", cerys = "vibrant",
	-- Solaris and Nyxaris.
	["sye-solaris"] = "solaris", castra = "solaris", arig = "solaris", igrys = "solaris",
	hyarion = "solaris", tellus = "solaris", corrundum = "solaris",
	["sye-nyxaris"] = "nyxaris", ["apia-carnova-orbit"] = "nyxaris",
	moshine = "nyxaris", panglia = "nyxaris", pelagos = "nyxaris",
	-- Vibrant, Vespera.
	["sye-vibrant"] = "vibrant", ribbonia = "vibrant",
	paracelsin = "vibrant",
	["sye-vespera"] = "vespera", muria = "vespera", aquilo = "vespera",
	["razi-vespera-belt-inner"] = "vespera",
	["razi-vespera-belt-outer"] = "vespera",
	rubia = "vespera", maraxsis = "vespera",
	-- Beetlejuice and Umbra.
	["sye-beetlejuice"] = "beetlejuice", cubium = "beetlejuice",
	["linox-planet_linox"] = "beetlejuice", secretas = "beetlejuice",
	frozeta = "beetlejuice",
	-- Razi's Vibrant metallic belt remains a science gate for both outer
	-- discoveries. Its edge-to-edge crossing remains a physical part of the travel graph.
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
  -- Direct home-system departure; Muluna retains its native lunar route.
  {"nauvis", "sye-calidus", 25000, "starter"},
  {"muluna", "sye-calidus", 14000, "starter"},
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
  -- The Razi-owned 5,000 km Vibrant belt is a mandatory science step.
  -- Preserve its legacy connection ID and Razi-owned asteroid loot.
  {"ribbonia", "asteroid-belt-inner-edge", 24000, "chemistry_deep"},
  {"asteroid-belt-outer-edge", "sye-beetlejuice", 85000, "outer_crossing"},
  -- Solaris stays compact: the inner industry arc and a separate Igrys
  -- expedition spur both depart from the western hub. No giant top chord
  -- between distant outer worlds; research gates remain source-owned.
  {"sye-solaris", "vulcanus", 18000, "industrial"},
  {"sye-solaris", "igrys", 26500, "industrial_deep"},
  {"vulcanus", "castra", 17500, "industrial"},
  {"castra", "arig", 16000, "industrial"},
  {"arig", "hyarion", 12000, "industrial_deep"},
  {"hyarion", "tellus", 16500, "industrial_deep"},
  {"tellus", "corrundum", 18000, "industrial_deep"},
  -- Igrys is served directly from the Slip Stream. An extra long outer
  -- Corrundum-Igrys chord made this small system look artificially ringed.
	-- Nyxaris neighbors can exchange biological supplies directly instead
	-- of routing every load through their distant slipstream hub.
	{"gleba", "moshine", 17000, "biological"},
	{"gleba", "apia-carnova-orbit", 22000, "biological"},
	{"moshine", "apia-carnova-orbit", 12000, "biological"},
	-- Post-Moshine data expedition: direct route plus an Apia cargo leg.
	{"moshine", "panglia", 25000, "biological_deep"},
	{"apia-carnova-orbit", "panglia", 21000, "biological_deep"},
	-- Nyxaris. Optional Dea Dia keeps its own native internal network.
	{"sye-nyxaris", "gleba", 18000, "biological"},
	{"sye-nyxaris", "moshine", 22000, "biological"},
	{"moshine", "pelagos", 16000, "biological_deep"},
	-- Optional oceanic freight return once both local destinations are known.
	{"panglia", "pelagos", 20000, "biological_deep"},
	{"sye-nyxaris", "dea-dia-system-edge", 20000, "biological_deep"},
	-- Vibrant's chemistry strand.
	{"sye-vibrant", "fulgora", 17000, "electrical"},
	{"fulgora", "ribbonia", 19500, "electrical"},
	{"sye-vibrant", "ribbonia", 23500, "electrical"},
	-- Frozen Paracelsin lies beyond the native AsteroidBelt crossing.
	-- A post-crossing outer-side return leg. It never connects an inner
	-- Vibrant world directly to an outer one.
	{"asteroid-belt-outer-edge", "paracelsin", 14000, "chemistry_deep"},
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
	-- Linox and Secretas are neighbors in the same researched outer tier.
	-- Their return shuttle avoids another trip back through Cubium.
	{"linox-planet_linox", "secretas", 22000, "outer_industry_deep"},
	-- Umbra's extreme sciences. Crucible's native orbital link stays intact.
	-- Keep the critical inner-rim / outer-rim transit untouched.
	{"sye-umbra", "crucible-orbit", 17000, "outer_void"},
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

local calidus_locations = {"nauvis", "muluna", "sye-calidus"}

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

-- Remove obsolete Drift endpoints left by earlier development saves. Native
-- Nauvis/Muluna and Dyson routes must survive this local retirement.
local function clean_calidus_routes(routes)
  local moon_link=false
  for _,route in pairs(routes) do
    if route.from and route.to and
        key_for(route.from,route.to)==key_for("nauvis","muluna") then
      moon_link=true
      break
    end
  end
  local removed=0
  for name,route in pairs(routes) do
    if route.from=="razi-calidus-drift" or route.to=="razi-calidus-drift"
      or (moon_link and name=="razi-muluna-sye-calidus"
        and route.from=="muluna" and route.to=="sye-calidus") then
      routes[name]=nil
      removed=removed+1
    end
  end
  return removed,moon_link
end

-- Razi's first-party Vibrant belt is a true inner/outer boundary at Vibrant.
-- Some dependencies add old same-system shortcuts in their final-fixes;
-- remove ONLY crossings between Razi's known inner and outer locations.
-- Never remove the one Razi-owned edge-to-edge connection, even on repeated
-- reconciliation. Optional source moons within the inner region stay inside.
local vibrant_inner = {
  ["sye-vibrant"]=true, fulgora=true, ribbonia=true, cerys=true,
  ["asteroid-belt-inner-edge"]=true
}
local vibrant_outer = {
  paracelsin=true, ["asteroid-belt-outer-edge"]=true
}
-- Localized obstacle fields; the first Calidus routes remain untouched.
local route_fields={
  ["sye-solaris|sye-vibrant"]=1.50,
  ["sye-nyxaris|sye-vespera"]=1.48,
  ["sye-beetlejuice|sye-umbra"]=1.68,
  ["secretas|solar-system-edge"]=1.85
}
local function field_strength(a,b)
  return route_fields[key_for(a,b)]
end
local function bypasses_vibrant_belt(a,b)
  if key_for(a,b)==key_for("asteroid-belt-inner-edge","asteroid-belt-outer-edge") then
    return false
  end
  return (vibrant_inner[a] and vibrant_outer[b])
      or (vibrant_inner[b] and vibrant_outer[a])
end

local allowed = {}
for _, specification in ipairs(route_specifications) do
	allowed[key_for(specification[1], specification[2])] = true
end
-- A late authority pass owns the final permitted topology after optional
-- planet/Dyson integration. Export immutable-by-convention catalog data, not
-- an additional premature cleanup in this earlier reconciliation stage.
route_reconcile.membership=membership
route_reconcile.allowed_pairs=allowed
route_reconcile.specifications=route_specifications
route_reconcile.pair_key=key_for
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


-- Factorio 2.1.20 added arc centres for space connections. On newer
-- clients our local routes can curve around their own relocated star.
-- Older 2.1 clients and source-authored origins are left untouched.
local function supports_regional_arcs()
  local v=mods and mods.base
  if type(v)~="string" then return false end
  local a,b,c=v:match("^(%d+)%.(%d+)%.(%d+)")
  a,b,c=tonumber(a),tonumber(b),tonumber(c)
  return a and (a>2 or a==2 and (b>1 or b==1 and c>=20)) or false
end
local function regional_origin(from,to,shape)
  if shape~="arc" or not supports_regional_arcs() then return nil end
  local system=membership[from]
  if not system or system~=membership[to]
    or system=="calidus" or system=="mid-outer-belt" then return nil end
  local x,y=layout.anchor_position(system)
  if not x or not y then return nil end
  return {x=x,y=y}
end

route_reconcile.regional_origin=regional_origin

function route_reconcile.data_final_fixes()
	local routes = data.raw["space-connection"] or {}
	local rescued = {}
	-- Remove any legacy Drift routes before indexing the live galaxy.
	clean_calidus_routes(routes)

  -- Previous Razi-owned connections were also authored in Solaris's data
  -- stage. Drop only those specific old IDs with their expected endpoints;
  -- preserve source-mod routes, custom asteroid definitions and other worlds.
  local retired_solaris={
    ["sye-solaris-castra"]={"sye-solaris","castra"},
    ["castra-hyarion"]={"castra","hyarion"},
    ["hyarion-corrundum"]={"hyarion","corrundum"},
    ["razi-sye-solaris-castra"]={"sye-solaris","castra"},
    ["razi-castra-hyarion"]={"castra","hyarion"},
    ["razi-vulcanus-hyarion"]={"vulcanus","hyarion"},
    ["razi-hyarion-corrundum"]={"hyarion","corrundum"},
    ["razi-vulcanus-arig"]={"vulcanus","arig"},
    ["razi-corrundum-igrys"]={"corrundum","igrys"}
  }
  for name,endpoints in pairs(retired_solaris) do
    local old=routes[name]
    if old and old.from and old.to and
      key_for(old.from,old.to)==key_for(endpoints[1],endpoints[2]) then
      routes[name]=nil
    end
  end

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

	-- Stop unmanaged interstellar shortcuts and old intra-Vibrant routes
	-- that would bypass the required original AsteroidBelt.
	-- Do not prune ordinary native same-system connections, special moons,
	-- optional integrations, or the native inner-to-outer belt crossing.
	for name, connection in pairs(routes) do
		local from_system = membership[connection.from]
		local to_system = membership[connection.to]
		if bypasses_vibrant_belt(connection.from, connection.to)
			or (from_system and to_system and from_system ~= to_system
				and not allowed[key_for(connection.from, connection.to)]) then
			routes[name] = nil
		end
	end

	-- Make a one-pass, final-stage route index after bypass removal instead
	-- of scanning every space connection twice for every authored corridor.
	-- Buckets preserve *all* duplicate names so native asteroid data can
	-- still be rescued before redundant links are removed.
	local routes_by_pair = {}
	for name, connection in pairs(routes) do
		local pair = key_for(connection.from, connection.to)
		local matches = routes_by_pair[pair]
		if not matches then matches = {}; routes_by_pair[pair] = matches end
		matches[#matches + 1] = name
	end

	for _, specification in ipairs(route_specifications) do
		local from, to, length, hazard = specification[1], specification[2], specification[3], specification[4]
		if has_endpoint(from) and has_endpoint(to) then
			local pair = key_for(from, to)
			local route_name = "razi-" .. from .. "-" .. to
			-- Preserve the original source-first sorting and all asteroid merges.
			local matches = routes_by_pair[pair] or {}
			table.sort(matches, function(a, b)
				local a_razi, b_razi = a:sub(1, 5) == "razi-", b:sub(1, 5) == "razi-"
				if a_razi ~= b_razi then return not a_razi end
				return a < b
			end)
			local keep_name = matches[1]
			for i = 2, #matches do
				local name = matches[i]
				local connection = routes[name]
				if connection then
					if keep_name then
						hazard_profiles.preserve_custom(routes[keep_name], connection)
					end
					routes[name] = nil
				end
			end
			if keep_name then routes_by_pair[pair] = {keep_name} end

			local route = keep_name and routes[keep_name]
			if route then
				route.from, route.to = from, to
				route.length = balanced_length(keep_name, route.length, length, from, to)
        local solaris_local=membership[from]=="solaris"
          and membership[to]=="solaris"
        -- Local Solaris logistics are direct chords between their actual
        -- endpoints. Source-provided default arcs were circling empty space,
        -- obscuring planets, and sweeping across the neighboring systems.
        -- A straight chord also works on older Factorio 2.1 clients.
        if solaris_local then
          route.shape="line"
          route.origin=nil
        elseif membership[from] and membership[to]
          and membership[from]~=membership[to] then
          route.shape="line"
        end
				hazard_profiles.apply(route, hazard)
				local strength=field_strength(from,to)
				if strength then hazard_profiles.apply_field(route,strength) end
				if membership[from]=="calidus" and membership[to]=="calidus"
					and keep_name:sub(1,5)=="razi-" then
					route.shape="line"
					route.origin=nil
        elseif solaris_local then
          route.origin=nil
				elseif route.origin==nil then
					route.origin=regional_origin(from,to,route.shape)
				end
				route_icons.assign(route, hazard)
			else
				local connection = route_icons.assign({
						type = "space-connection",
						name = route_name,
						from = from,
						to = to,
						length = length,
						shape = (membership[from] and membership[to]
                            and (membership[from] ~= membership[to]
                              or membership[from]=="calidus"
                              or membership[from]=="solaris")) and "line" or "arc",
                        asteroid_spawn_definitions = hazard_profiles.create(hazard)
					}, hazard)
				local strength=field_strength(from,to)
				if strength then hazard_profiles.apply_field(connection,strength) end
				connection.origin=regional_origin(from,to,connection.shape)
				data:extend({connection})
				routes_by_pair[pair] = {route_name}
			end
		end
	end

	-- Drop the Razi moon-to-hub fallback if the actual source moon already
	-- connects to Nauvis. This keeps one route to each Calidus branch.
	local removed,moon_link=clean_calidus_routes(routes)
	if type(log)=="function" then
		log("[Razi Protocol/Calidus] Simplified local route graph; "..
		  removed.." redundant freight links, native lunar access="..
		  tostring(moon_link))
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
