-- Solar Halo (Deluxev2, optional) next to the Dyson sphere at Calidus. Solar Halo 1.2.3 reaches its solar orbit by a
-- route from Vulcanus (space/data.lua:113-120; Razi Protocol keeps it at 77 000 km, Vulcanus lies in Solaris) and
-- opens it right after space science (technology/data.lua:35). Here:
--   * the route comes from the inner Dyson orbit (without the Dyson sphere: from the Calidus hub), 10 000 km, and keeps
--     the solar flares of the old route;
--   * the discovery follows the inner Dyson orbit (without the sphere: Solaris discovery);
--   * the simulation of science packs (halo-sim and halo-sim-*: a supercomputer turns compute into any science pack
--     of the pack, cryogenic and promethium included) is hidden: science packs come from their planets in Razi
--     Protocol. Solar Halo has no setting for it (PR ackeri/Solar-Halo#8 is open).
-- The station, the computers, the charged electrolyte and the charged modules stay as Solar Halo made them.
local dyson = require("prototypes.compatibility.slp-dyson-sphere-reworked-fork.calidus_dyson")

local solar_halo = {}

solar_halo.ORBIT = "halo-solar-orbit"
solar_halo.DISCOVERY = "halo-discovery-solar"
solar_halo.OLD_ROUTE = "vulcanus-solar"
solar_halo.ROUTE = "razi-halo-solar-lane"
solar_halo.LENGTH = 10000
solar_halo.SIMULATION = "halo-sim"

local function location(id)
	return (data.raw.planet or {})[id] or (data.raw["space-location"] or {})[id]
end

local function technology(id)
	return (data.raw.technology or {})[id]
end

local function active(id)
	local t = technology(id)
	return t ~= nil and t.hidden ~= true and t.enabled ~= false
end

-- Where the Halo route starts and which research opens it.
---@return string? from, string? gate
function solar_halo.anchor()
	if mods and mods["slp-dyson-sphere-reworked-fork"] and active("slp-solar-system-sun2") then
		local inner = dyson.destination("slp-solar-system-sun2")
		if inner then
			return inner, "slp-solar-system-sun2"
		end
	end
	if location("sye-calidus") and active("solaris-discovery") then
		return "sye-calidus", "solaris-discovery"
	end
	return nil, nil
end

local function move_route(from)
	local routes = data.raw["space-connection"] or {}
	local old = routes[solar_halo.OLD_ROUTE]
	if old and old.to == solar_halo.ORBIT then
		routes[solar_halo.OLD_ROUTE] = nil
		log("razi-protocol: Solar Halo: removed " .. solar_halo.OLD_ROUTE .. " (" .. tostring(old.length) .. " km)")
	end
	for _, route in pairs(routes) do
		if (route.from == from and route.to == solar_halo.ORBIT) or (route.to == from and route.from == solar_halo.ORBIT) then
			return
		end
	end
	local route = {
		type = "space-connection",
		name = solar_halo.ROUTE,
		subgroup = old and old.subgroup or "planet-connections",
		order = old and old.order or "ab",
		from = from,
		to = solar_halo.ORBIT,
		length = solar_halo.LENGTH,
		asteroid_spawn_definitions = old and old.asteroid_spawn_definitions or {},
	}
	require("prototypes.world.routes.route_icons").assign(route, "starter")
	data:extend({route})
	log("razi-protocol: Solar Halo: " .. from .. " -> " .. solar_halo.ORBIT .. ", " .. solar_halo.LENGTH .. " km")
end

local function gate_discovery(gate)
	local discovery = technology(solar_halo.DISCOVERY)
	local prerequisites = discovery and discovery.prerequisites
	if prerequisites and #prerequisites == 1 and prerequisites[1] == "space-science-pack" then
		discovery.prerequisites = {gate}
		log("razi-protocol: Solar Halo: " .. solar_halo.DISCOVERY .. " follows " .. gate)
	end
end

local function is_simulation(name)
	return name == solar_halo.SIMULATION or name:sub(1, #solar_halo.SIMULATION + 1) == solar_halo.SIMULATION .. "-"
end

---@return integer hidden technologies
local function hide_simulation()
	local technologies = data.raw.technology or {}
	local recipes = data.raw.recipe or {}
	local hidden = 0
	for name, t in pairs(technologies) do
		if is_simulation(name) and t.hidden ~= true then
			t.hidden = true
			t.enabled = false
			for _, effect in ipairs(t.effects or {}) do
				local recipe = effect.type == "unlock-recipe" and recipes[effect.recipe]
				if recipe then
					recipe.hidden = true
					recipe.enabled = false
				end
			end
			hidden = hidden + 1
		end
	end
	-- nothing outside the simulation may keep a hidden technology as a prerequisite
	for name, t in pairs(technologies) do
		if not is_simulation(name) and t.prerequisites then
			for i = #t.prerequisites, 1, -1 do
				if is_simulation(t.prerequisites[i]) then
					table.remove(t.prerequisites, i)
				end
			end
		end
	end
	if hidden > 0 then
		log("razi-protocol: Solar Halo: " .. hidden .. " science pack simulation technologies hidden")
	end
	return hidden
end

-- After route_authority and the Calidus Dyson spoke (data-final-fixes.lua).
function solar_halo.data_final_fixes()
	if not (mods and mods["Solar-Halo"] and location(solar_halo.ORBIT)) then
		return
	end
	local from, gate = solar_halo.anchor()
	if from and gate then
		move_route(from)
		gate_discovery(gate)
	end
	hide_simulation()
end

return solar_halo
