---@diagnostic disable: missing-fields
-- Every route end pulls a platform without thrust (prototypes/world/routes/route_drift.lua), on a mocked data.raw.
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local logged = 0
rawset(_G, "log", function(_) logged = logged + 1 end)

local raw = {
	planet = {nauvis = {gravity_pull = 10}, vulcanus = {gravity_pull = 10}, maraxsis = {}},
	["space-location"] = {
		["sye-solaris"] = {}, ["sye-vibrant"] = {gravity_pull = 0},
		["solar-system-edge"] = {gravity_pull = -10}, ["not-on-a-route"] = {}
	},
	["space-connection"] = {
		["razi-sye-solaris-sye-vibrant"] = {from = "sye-solaris", to = "sye-vibrant", length = 100000},
		["razi-sye-solaris-vulcanus"] = {from = "sye-solaris", to = "vulcanus", length = 18000},
		["nauvis-maraxsis"] = {from = "nauvis", to = "maraxsis", length = 15000},
		["edge-route"] = {from = "solar-system-edge", to = "nauvis", length = 100000},
		["missing-end"] = {from = "nauvis", to = "removed-location", length = 1000}
	}
}
rawset(_G, "data", {raw = raw})

local drift = require("prototypes.world.routes.route_drift")
check(drift.data_final_fixes() == 3, "Expected three route ends to get a pull")
check(raw["space-location"]["sye-solaris"].gravity_pull == 10, "A star system without a pull still stops platforms")
check(raw["space-location"]["sye-vibrant"].gravity_pull == 10, "A zero pull was left in place")
check(raw.planet.maraxsis.gravity_pull == 10, "A planet without a pull was skipped")
check(raw.planet.vulcanus.gravity_pull == 10, "An existing pull was changed")
check(raw["space-location"]["solar-system-edge"].gravity_pull == -10, "The negative pull of the edge was changed")
check(raw["space-location"]["not-on-a-route"].gravity_pull == nil, "A location off every route was changed")
check(logged == 3, "Each change must be logged")
check(drift.data_final_fixes() == 0, "A second pass changed something")

local f = assert(io.open("data-final-fixes.lua", "r"))
local source = f:read("*a")
f:close()
local highlights = assert(source:find('require("prototypes.world.routes.route_highlights").data_final_fixes()', 1, true))
local pulls = assert(source:find('require("prototypes.world.routes.route_drift").data_final_fixes()', 1, true))
check(pulls > highlights, "Route pulls must run after the final route passes")
print("Route ends pull platforms without thrust")
