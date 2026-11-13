---@diagnostic disable: missing-fields, assign-type-mismatch, need-check-nil, param-type-mismatch, undefined-field
-- Solar Halo next to the Dyson sphere (prototypes/compatibility/Solar-Halo/solar_halo.lua) on mocked prototypes:
-- the route moves from Vulcanus to the inner Dyson orbit, the discovery follows it, the pack simulation is hidden.
-- Run from the mod root:
--   lua5.2 tests/lua/test_solar_halo.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local function world(dyson)
	local technology = {
		["halo-discovery-solar"] = {prerequisites = {"space-science-pack"}},
		["halo-compute"] = {prerequisites = {"halo-discovery-solar"}},
		["halo-sim"] = {prerequisites = {"halo-compute"}, effects = {{type = "unlock-recipe", recipe = "halo-automation-science-pack"}}},
		["halo-sim-cryogenic-science-pack"] = {prerequisites = {"halo-sim"},
			effects = {{type = "unlock-recipe", recipe = "halo-cryogenic-science-pack"}}},
		["halo-simple"] = {prerequisites = {"halo-sim", "halo-compute"}},
		["solaris-discovery"] = {prerequisites = {}},
	}
	if dyson then
		technology["slp-solar-system-sun2"] = {effects = {{type = "unlock-space-location", space_location = "slp-solar-system-sun2"}}}
	end
	rawset(_G, "data", {
		raw = {
			technology = technology,
			recipe = {
				["halo-automation-science-pack"] = {},
				["halo-cryogenic-science-pack"] = {},
			},
			["space-location"] = {
				["halo-solar-orbit"] = {},
				["sye-calidus"] = {},
				["slp-solar-system-sun2"] = dyson and {} or nil,
			},
			planet = {vulcanus = {}},
			["space-connection"] = {
				["vulcanus-solar"] = {name = "vulcanus-solar", from = "vulcanus", to = "halo-solar-orbit", length = 77000,
					asteroid_spawn_definitions = {{asteroid = "halo-flare"}}},
			},
		},
		extend = function(self, list)
			for _, p in ipairs(list) do
				self.raw[p.type][p.name] = p
			end
		end,
	})
	rawset(_G, "mods", {["Solar-Halo"] = "1.2.3", ["slp-dyson-sphere-reworked-fork"] = dyson and "1.0.0" or nil})
	rawset(_G, "log", function() end)
	package.loaded["prototypes.compatibility.Solar-Halo.solar_halo"] = nil
	package.loaded["prototypes.world.routes.route_icons"] = {assign = function(route) return route end}
	return require("prototypes.compatibility.Solar-Halo.solar_halo")
end

-- with the Dyson sphere
local solar_halo = world(true)
solar_halo.data_final_fixes()
local raw = data.raw
check(raw["space-connection"]["vulcanus-solar"] == nil, "the Vulcanus route is gone")
local lane = raw["space-connection"]["razi-halo-solar-lane"]
check(lane and lane.from == "slp-solar-system-sun2" and lane.to == "halo-solar-orbit" and lane.length == 10000,
	"the route starts at the inner Dyson orbit")
check(lane.asteroid_spawn_definitions[1].asteroid == "halo-flare", "the flares stay on the route")
check(raw.technology["halo-discovery-solar"].prerequisites[1] == "slp-solar-system-sun2", "discovery after the inner orbit")
check(raw.technology["halo-sim"].hidden and raw.technology["halo-sim-cryogenic-science-pack"].hidden, "simulation hidden")
check(raw.recipe["halo-cryogenic-science-pack"].hidden, "simulated pack recipe hidden")
check(not raw.technology["halo-compute"].hidden, "the computers stay")
local simple = raw.technology["halo-simple"].prerequisites
check(#simple == 1 and simple[1] == "halo-compute", "no technology keeps a hidden prerequisite")

-- twice: nothing more happens
solar_halo.data_final_fixes()
local lanes = 0
for _, route in pairs(raw["space-connection"]) do
	if route.to == "halo-solar-orbit" then lanes = lanes + 1 end
end
check(lanes == 1, "one route to the Halo orbit")

-- without the Dyson sphere
solar_halo = world(false)
solar_halo.data_final_fixes()
check(data.raw["space-connection"]["razi-halo-solar-lane"].from == "sye-calidus", "without the sphere: from Calidus")
check(data.raw.technology["halo-discovery-solar"].prerequisites[1] == "solaris-discovery", "without the sphere: after Solaris")

-- a changed discovery is left alone
solar_halo = world(true)
data.raw.technology["halo-discovery-solar"].prerequisites = {"planet-discovery-vulcanus"}
solar_halo.data_final_fixes()
check(data.raw.technology["halo-discovery-solar"].prerequisites[1] == "planet-discovery-vulcanus", "own prerequisites kept")

print("test_solar_halo: ok")
