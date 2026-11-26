---@diagnostic disable: lowercase-global, missing-fields
-- Checks that the Smart Inserters panel is hidden on Vehicle Wagon 2 loading ramps.
-- Run from the mod root with the library bootstrap: tests/run.sh
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local registrations = {}
rawset(_G, "defines", { events = { on_gui_opened = 41 } })
---@type table
local fake_script = { active_mods = { Smart_Inserters = "2.1.0", VehicleWagon2 = "4.2.3" } }
rawset(_G, "script", fake_script)
rawset(_G, "game", { get_player = function(index) return players and players[index] end })

local ramp = require("scripts.compatibility.Smart_Inserters.vehicle_wagon_ramp")
local events = {
	on_event = function(_, event_id, handler)
		registrations[#registrations + 1] = { event_id = event_id, handler = handler }
	end,
}

ramp.register(events)
check(#registrations == 1 and registrations[1].event_id == defines.events.on_gui_opened,
	"both mods should register the GUI-opened handler")
check(registrations[1].handler == ramp.on_gui_opened, "the loading-ramp handler was not registered")

fake_script.active_mods.VehicleWagon2 = nil
ramp.register(events)
fake_script.active_mods.VehicleWagon2 = "4.2.3"
fake_script.active_mods.Smart_Inserters = nil
ramp.register(events)
check(#registrations == 1, "the GUI handler should require both mods")
fake_script.active_mods.Smart_Inserters = "2.1.0"

local panel = { valid = true, visible = true }
players = { [1] = { gui = { relative = { smart_inserters = panel } } } }
ramp.on_gui_opened({ player_index = 1, entity = { valid = true, name = "loading-ramp" } })
check(panel.visible == false, "Smart Inserters panel should be hidden on the loading ramp")

panel.visible = true
ramp.on_gui_opened({ player_index = 1, entity = { valid = true, name = "fast-inserter" } })
check(panel.visible == true, "the panel should stay visible on other inserters")

check(pcall(ramp.on_gui_opened, { player_index = 1 }), "missing event.entity should be ignored")
check(pcall(ramp.on_gui_opened, { player_index = 1, entity = { valid = false, name = "loading-ramp" } }),
	"invalid entities should be ignored")
players[2] = { gui = { relative = {} } }
check(pcall(ramp.on_gui_opened, { player_index = 2, entity = { valid = true, name = "loading-ramp" } }),
	"a missing Smart Inserters panel should be ignored")

print("test_smart_inserters_ramp: ok")
