-- A platform without thrust drifts to the nearer end of its route, at a speed set by that end's gravity_pull (10 on
-- the base game planets). A location without gravity_pull never pulls, so a platform that runs out of fuel next to it
-- stops for good: the star systems, the belt edges and some locations of other mods have none. Every route end
-- without a pull gets the pull of a base planet. A route between two such ends keeps its travel speed, since the pull
-- of the start is subtracted and the pull of the destination added. Negative pulls (the solar system edge) stay.
local route_drift = {}

route_drift.gravity_pull = 10

local function location(name)
	if type(name) ~= "string" then
		return nil
	end
	return (data.raw.planet or {})[name] or (data.raw["space-location"] or {})[name]
end

-- Returns the number of locations changed.
function route_drift.data_final_fixes()
	local count = 0
	local names = {}
	for _, route in pairs(data.raw["space-connection"] or {}) do
		names[#names + 1] = route.from
		names[#names + 1] = route.to
	end
	for _, name in ipairs(names) do
		local place = location(name)
		if place and (place.gravity_pull == nil or place.gravity_pull == 0) then
			place.gravity_pull = route_drift.gravity_pull
			count = count + 1
			log("razi-protocol: " .. name .. ": gravity_pull " .. route_drift.gravity_pull
				.. ", so platforms without thrust drift to it")
		end
	end
	return count
end

return route_drift
