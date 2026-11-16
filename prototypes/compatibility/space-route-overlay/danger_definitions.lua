-- Space Route Overlay (Valent125) draws routes as dotted lines on the star map. It runs in its data-final-fixes, after
-- Razi Protocol ((?) razi-protocol in its info.json), and reads the final positions and routes. A route that carries a
-- SRO_connections_definition is drawn by that definition instead of Space Route Overlay's own colours by asteroid size
-- (render-connection-overlay.lua:256-260 and, in its library mode, :292-298 in 0.3.6); the style names the dot sprite
-- graphics/dot-<style>.png, and dot-rp1 ... dot-rp10 follow the colours of the route levels.
--
-- In danger mode every route gets the style of its level 1-10, the one in the route tooltip, so the map shows one
-- scale; Razi Protocol draws no ribbons of its own while Space Route Overlay is on. The shape is left out: Space Route
-- Overlay takes it from the route. Its own settings (dot scale, line style, library mode) stay the player's.
local danger_definitions = {}

local MAX_LEVEL = 10

-- Space Route Overlay 0.3.6 draws these Aegis routes from its own list (render-connection-overlay.lua:221-235) unless
-- its library mode is on, and a definition on the route would add a second line on top. They keep its Aegis art.
local OWN_ROUTES = {
	["aegis-stargate-connection"] = true,
	["aegis-outer-inner-connection"] = true,
	["aegis-inner-edge-alke"] = true,
	["aegis-outer-warden-connection"] = true,
	["aegis-inner-warden-connection"] = true,
	["aegis-bellicos-connection"] = true,
}

---@return boolean
local function library_mode()
	local setting = settings and settings.startup and settings.startup["SRO-use-as-library"]
	return setting ~= nil and setting.value == true
end

---@param level number?
---@return string
function danger_definitions.style(level)
	local n = math.floor(tonumber(level) or 1)
	return "rp" .. math.max(1, math.min(MAX_LEVEL, n))
end

-- owner is route_highlights (route_color_level gives the level of the route tooltip).
---@return integer count of routes handed to Space Route Overlay
function danger_definitions.data_final_fixes(owner)
	local count = 0
	local own = not library_mode() and mods and mods["bellicos-and-aegis"] and OWN_ROUTES or {}
	for name, route in pairs(data.raw["space-connection"] or {}) do
		if not own[name] then
			local connection = route --[[@as table]]
			connection.SRO_connections_definition = {name = name, style = danger_definitions.style(owner.route_color_level(route))}
			count = count + 1
		end
	end
	log("razi-protocol: Space Route Overlay draws " .. count .. " routes in the colours of their levels 1-10")
	return count
end

return danger_definitions
