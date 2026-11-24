package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local function make_world(options)
	options = options or {}
	local interface = { energy_source = { buffer_capacity = "1TJ" } }
	if options.output_flow_limit ~= nil then
		interface.energy_source.output_flow_limit = options.output_flow_limit
	end
	local logs = {}
	rawset(_G, "data", {
		raw = {
			["electric-energy-interface"] = {
				gr_black_hole_energy = interface,
			},
		},
	})
	rawset(_G, "mods", options.no_mod and {} or { ["248k-Redux"] = "2.1.51" })
	rawset(_G, "log", function(message)
		logs[#logs + 1] = message
	end)
	package.loaded["prototypes.compatibility.248k-Redux.power_caps"] = nil
	return { interface = interface, logs = logs }
end

local power_caps = require("prototypes.compatibility.248k-Redux.power_caps")

-- The missing nested field matches the measured source value and receives the chapter cap.
local world = make_world()
power_caps.data_final_fixes()
check(world.interface.energy_source.output_flow_limit == "3GW", "black-hole output flow is capped at 3GW")
check(world.logs[1] == "razi-protocol: 248k: set gr_black_hole_energy energy_source.output_flow_limit to 3GW",
	"setting the cap is logged")

-- An existing value from another mod is kept and reported.
world = make_world({ output_flow_limit = "4GW" })
power_caps.data_final_fixes()
check(world.interface.energy_source.output_flow_limit == "4GW", "a different output flow is left unchanged")
check(world.logs[1] == "razi-protocol: 248k: gr_black_hole_energy energy_source.output_flow_limit is 4GW, expected nil, left as is",
	"a conflicting output flow is logged")

-- The compatibility pass is inert without 248k.
world = make_world({ no_mod = true })
power_caps.data_final_fixes()
check(world.interface.energy_source.output_flow_limit == nil and #world.logs == 0,
	"without 248k the output flow and logs stay unchanged")

print("test_248k_power_caps: ok")
