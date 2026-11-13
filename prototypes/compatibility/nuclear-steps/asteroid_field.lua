-- Nuclear Steps (Neomorphos, optional) as a side trip from Gleba.
-- Nuclear Steps 0.3.4 places its bodies by their distance from the star (prototypes/space-locations/space-locations.lua:
-- 15-16, 47-48, 62-63, 110-111, 123-124). In this galaxy that is north of Calidus, between Calidus and Beetlejuice, and
-- its only entry, gleba-to-asteroid-0 (:133-164), crossed Calidus and was repriced to 104 000 km
-- (prototypes/world/routes/route_distance_balance.lua). Here the asteroid field orbits Gleba, in the free space
-- between Nyxaris and Solaris, and the bodies behind it keep the author's layout at three quarters of its size, so the
-- black hole (magnitude 10) keeps clear of the field. The bodies are found by the routes from the asteroid field, not
-- by name: the author plans to merge and rename them.
-- The route from Gleba is a side route of route_authority.lua; the discoveries and packs stay off the required path
-- (prototypes/world/systems/optional_worlds.lua).
local M = {}

M.ENTRY = "asteroid-0"
M.HUB = "gleba"
M.RADIUS = 30
M.TURN = 0.34
M.SCALE = 0.75

local function location(name)
	local planet = (data.raw.planet or {})[name]
	if planet then return planet, "planet" end
	local place = (data.raw["space-location"] or {})[name]
	if place then return place, "space-location" end
	return nil, nil
end

-- Position on the star map of a body that is still placed from the star, as Nuclear Steps places them.
-- nil for a body that already orbits something else: another mod or this one has placed it.
---@return number?, number?
local function from_star(body)
	local parent = body.orbit and body.orbit.parent
	if parent and parent.name ~= "star" then return nil, nil end
	local distance, turn = body.distance, body.orientation
	if type(distance) ~= "number" or type(turn) ~= "number" then return nil, nil end
	local theta = 2 * math.pi * turn
	local x, y = distance * math.sin(theta), -distance * math.cos(theta)
	local origin = body.origin
	if type(origin) == "table" then
		x = x + (origin.x or origin[1] or 0)
		y = y + (origin.y or origin[2] or 0)
	end
	return x, y
end

-- The bodies reached from the asteroid field without passing Gleba, and placed from the star, sorted.
---@return string[]
function M.bodies()
	local anchored = {}
	for _, anchor in ipairs(require("prototypes.world.starmap.galaxy_anchors").anchors) do
		anchored[anchor[2]] = true
	end
	local found, queue = {[M.ENTRY] = true}, {M.ENTRY}
	local index = 1
	while queue[index] do
		local name = queue[index]
		index = index + 1
		for _, route in pairs(data.raw["space-connection"] or {}) do
			local other = (route.from == name and route.to) or (route.to == name and route.from) or nil
			if other and not found[other] and other ~= M.HUB and not anchored[other] then
				local body = location(other)
				if body and from_star(body) then
					found[other] = true
					queue[#queue + 1] = other
				end
			end
		end
	end
	found[M.ENTRY] = nil
	local names = {}
	for name in pairs(found) do names[#names + 1] = name end
	table.sort(names)
	return names
end

-- The orbits to give: the asteroid field around Gleba, every other body around the asteroid field.
---@return table[]? updates in PlanetsLib:update form, the asteroid field first
function M.plan()
	if not (mods and mods["nuclear-steps"]) then return nil end
	local entry, entry_type = location(M.ENTRY)
	local _, hub_type = location(M.HUB)
	if not (entry and hub_type) then return nil end
	local ex, ey = from_star(entry)
	if not (ex and ey) then
		log("razi-protocol: Nuclear Steps: " .. M.ENTRY .. " already orbits something else, left in place")
		return nil
	end
	local updates = {{type = entry_type, name = M.ENTRY,
		orbit = {parent = {type = hub_type, name = M.HUB}, distance = M.RADIUS, orientation = M.TURN}}}
	for _, name in ipairs(M.bodies()) do
		local body, kind = location(name)
		local x, y = from_star(body)
		local dx, dy = (x or ex) - ex, (y or ey) - ey
		dx, dy = dx * M.SCALE, dy * M.SCALE
		local distance = math.sqrt(dx * dx + dy * dy)
		if distance > 0 then
			local turn = (math.atan2(dx, -dy) / (2 * math.pi)) % 1
			updates[#updates + 1] = {type = kind, name = name,
				orbit = {parent = {type = entry_type, name = M.ENTRY}, distance = distance, orientation = turn}}
		end
	end
	return updates
end

-- data-updates, after galaxy_layout.lua has placed Gleba and before PlanetsLib draws the star map.
function M.data_updates()
	local updates = M.plan()
	if not updates then return end
	PlanetsLib:update(updates)
	log(string.format("razi-protocol: Nuclear Steps: %s orbits %s at %g, %d bodies behind it at %g of their size",
		M.ENTRY, M.HUB, M.RADIUS, #updates - 1, M.SCALE))
end

return M
