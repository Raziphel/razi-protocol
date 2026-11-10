-- Factorio 2.1 requires every space-connection to expose icon data. Space Age
-- supplies defaults during data-updates, but Razi and compatibility routes can
-- be created later in data-final-fixes. Keep that late-stage repair here and
-- never overwrite artwork already owned by a source mod.
local route_icons = {}

local icon_size = 64
local icons = {
	planetary = "__razi-protocol__/graphics/icons/routes/planetary-route.png",
	interstellar = "__razi-protocol__/graphics/icons/routes/interstellar-route.png",
	asteroid = "__razi-protocol__/graphics/icons/routes/asteroid-route.png",
	deep_space = "__razi-protocol__/graphics/icons/routes/deep-space-route.png"
}

local function has_icon(connection)
	return connection.icon ~= nil
		or (type(connection.icons) == "table" and next(connection.icons) ~= nil)
end

local function contains(value, fragment)
	return type(value) == "string" and value:find(fragment, 1, true) ~= nil
end

local function classify(connection, profile)
	if contains(profile, "belt_")
		or contains(connection.from, "-belt-")
		or contains(connection.to, "-belt-") then
		return "asteroid"
	end

	if contains(profile, "deep_edge")
		or contains(connection.from, "solar-system-edge")
		or contains(connection.to, "solar-system-edge")
		or contains(connection.from, "black-hole")
		or contains(connection.to, "black-hole")
		or contains(connection.from, "oort-cloud")
		or contains(connection.to, "oort-cloud")
		or contains(connection.from, "nexus")
		or contains(connection.to, "nexus")
		or (type(connection.length) == "number" and connection.length >= 150000) then
		return "deep_space"
	end

	if connection.shape == "line"
		or contains(profile, "crossing")
		or contains(profile, "crosslink") then
		return "interstellar"
	end

	return "planetary"
end

function route_icons.assign(connection, profile)
	if not connection or has_icon(connection) then return connection end
	local family = classify(connection, profile)
	connection.icon = icons[family]
	connection.icon_size = icon_size
	return connection
end

function route_icons.data_final_fixes()
	-- This is intentionally the final prototype pass. It covers early Razi
	-- routes, dynamically reconciled routes, and late compatibility routes.
	-- External routes keep their own icon/icons declarations byte-for-byte.
	for _, connection in pairs(data.raw["space-connection"] or {}) do
		route_icons.assign(connection)
	end
end

route_icons.icons = icons
route_icons.icon_size = icon_size

return route_icons
