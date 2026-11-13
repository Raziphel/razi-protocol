---@diagnostic disable: missing-fields, assign-type-mismatch, need-check-nil, param-type-mismatch, undefined-field
-- Space Route Overlay gets a SRO_connections_definition with the level style rp1-rp10 on every route
-- (prototypes/compatibility/space-route-overlay/danger_definitions.lua).
-- Run from the mod root:
--   lua5.2 tests/lua/test_space_route_overlay.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

rawset(_G, "log", function() end)
rawset(_G, "data", {raw = {
	["space-connection"] = {
		["a-b"] = {name = "a-b", from = "a", to = "b", level = 3},
		["b-c"] = {name = "b-c", from = "b", to = "c", level = 12},
		["c-d"] = {name = "c-d", from = "c", to = "d", level = 0},
		["aegis-bellicos-connection"] = {name = "aegis-bellicos-connection", from = "x", to = "y", level = 7},
	},
	["utility-sprites"] = {default = {starmap_star = {layers = {{filename = "__core__/graphics/icons/starmap-star.png"}}}}},
}})

local definitions = require("prototypes.compatibility.space-route-overlay.danger_definitions")

check(definitions.style(1) == "rp1" and definitions.style(10) == "rp10", "levels 1 and 10")
check(definitions.style(0) == "rp1" and definitions.style(14) == "rp10" and definitions.style(nil) == "rp1", "clamped")
check(definitions.style(4.6) == "rp4", "fraction rounds down")

local owner = {route_color_level = function(route) return route.level end}
local routes = data.raw["space-connection"]
local startup = {}
rawset(_G, "settings", {startup = startup})
rawset(_G, "mods", {["bellicos-and-aegis"] = "0.4.7"})
local count = definitions.data_final_fixes(owner)
check(count == 3, "three routes handed over, got " .. count)
check(routes["aegis-bellicos-connection"].SRO_connections_definition == nil, "Aegis routes keep the art of Space Route Overlay")
check(routes["a-b"].SRO_connections_definition.style == "rp3", "level 3")
check(routes["b-c"].SRO_connections_definition.style == "rp10", "level above 10")
check(routes["c-d"].SRO_connections_definition.name == "c-d", "definition names its route")
check(routes["a-b"].SRO_connections_definition.shape == nil, "shape comes from the route")

-- in library mode Space Route Overlay draws only definitions, so the Aegis routes get one too
startup["SRO-use-as-library"] = {value = true}
check(definitions.data_final_fixes(owner) == 4, "library mode: every route")
check(routes["aegis-bellicos-connection"].SRO_connections_definition.style == "rp7", "library mode: Aegis level")

print("test_space_route_overlay: ok")
