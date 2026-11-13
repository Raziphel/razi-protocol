-- Route icon requirements and ownership preservation without Factorio.
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(condition, message)
	if not condition then error(message, 2) end
end

local external_icon = "__external__/graphics/owned.png"
local external_layers = {{icon = "__external__/graphics/layer.png", icon_size = 32}}
package.loaded["prototypes.world.routes.route_reconcile"] = {
	membership = {
		nauvis = "calidus", muluna = "calidus",
		["sye-solaris"] = "solaris", ["sye-nyxaris"] = "nyxaris",
		arig = "solaris", hyarion = "solaris",
		["sye-vibrant"] = "vibrant", ribbonia = "vibrant",
		secretas = "beetlejuice", ["solar-system-edge"] = "deep-space"
	}
}
rawset(_G, "data", {raw = {['space-connection'] = {
	planetary = {from = "nauvis", to = "muluna", length = 15000},
	interstellar = {from = "sye-solaris", to = "sye-nyxaris", shape = "line"},
	local_line = {from = "arig", to = "hyarion", length = 15000, shape = "line"},
	cross_system_arc = {from = "arig", to = "ribbonia", shape = "arc"},
	asteroid = {from = "razi-umbra-belt-inner", to = "razi-umbra-belt-outer"},
	deep = {from = "secretas", to = "solar-system-edge", length = 155000},
	external = {icon = external_icon, icon_size = 128},
	layered = {icons = external_layers}
}}})

package.loaded["prototypes.world.routes.route_icons"] = nil
local route_icons = require("prototypes.world.routes.route_icons")
route_icons.data_final_fixes()
local routes = data.raw["space-connection"]

for name, route in pairs(routes) do
	check(route.icon or route.icons, "Missing required icon declaration: " .. name)
end
check(routes.planetary.icon == route_icons.icons.planetary, "Wrong planetary icon")
check(routes.interstellar.icon == route_icons.icons.interstellar, "Wrong interstellar icon")
check(routes.local_line.icon == route_icons.icons.planetary,
	"An intra-system line must not receive the interstellar icon")
check(routes.cross_system_arc.icon == route_icons.icons.interstellar,
	"A cross-system route must receive the interstellar icon regardless of shape")
check(routes.asteroid.icon == route_icons.icons.asteroid, "Wrong asteroid crossing icon")
check(routes.deep.icon == route_icons.icons.deep_space, "Wrong deep-space icon")
check(routes.planetary.icon_size == 64, "Route icon_size does not match the PNG")
check(routes.external.icon == external_icon and routes.external.icon_size == 128,
	"Existing external icon metadata was overwritten")
check(routes.layered.icons == external_layers and routes.layered.icon == nil,
	"Existing external layered icons were overwritten")

local first = routes.interstellar.icon
route_icons.data_final_fixes()
check(routes.interstellar.icon == first, "Route icon assignment is not idempotent")

print("route icon regression fixtures passed")
