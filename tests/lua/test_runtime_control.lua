-- control.lua wiring on the RAZI Library event registry, without a Factorio binary.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_runtime_control.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local events = {
	on_built_entity = 1,
	on_robot_built_entity = 2,
	on_entity_cloned = 3,
	script_raised_built = 4,
	script_raised_revive = 5,
	on_console_command = 6,
	on_player_joined_game = 7,
	on_player_removed = 8
}
local handlers, nth, filters, registrations = {}, {}, {}, {}
local lifecycle = {}
local active_mods = {}
local fake_script = {
	active_mods = active_mods,
	on_event = function(id, handler)
		registrations[id] = (registrations[id] or 0) + 1
		handlers[id] = handler
		-- Registering again drops filters, as in the game.
		filters[id] = nil
	end,
	on_nth_tick = function(interval, handler) nth[interval] = handler end,
	on_init = function(handler) lifecycle.init = handler end,
	on_load = function(handler) lifecycle.load = handler end,
	on_configuration_changed = function(handler) lifecycle.changed = handler end,
	set_event_filter = function(id, filter)
		check(handlers[id], "A filter set before its registration would be lost")
		filters[id] = filter
	end
}
local registered_commands = {}
rawset(_G, "defines", {events = events})
rawset(_G, "script", fake_script)
rawset(_G, "commands", {add_command = function(name, help, handler)
	registered_commands[name] = {help = help, handler = handler}
end})
rawset(_G, "storage", {})
rawset(_G, "log", function(_) end)

local function technology(researched, enabled, prototype)
	return {researched = researched, enabled = enabled,
		prototype = prototype or {enabled = true, hidden = false}}
end

local counted = {}
local function force(name, gate_researched, transceivers)
	local self = {name = name, valid = true}
	self.technologies = {
		["razi-intergalactic-transceiver-signal"] = technology(gate_researched, gate_researched),
		["element882"] = technology(false, false),
		["atomacer"] = technology(false, false, {enabled = true, hidden = true}),
		["omega-train"] = technology(true, true)
	}
	self.get_entity_count = function(entity_name)
		counted[name] = (counted[name] or 0) + 1
		check(entity_name == "kr-activated-intergalactic-transceiver", "Only the active transceiver is counted")
		return transceivers
	end
	return self
end

local forces = {
	player = force("player", false, 1),
	enemy = force("enemy", false, 0),
	done = force("done", true, 1)
}
rawset(_G, "game", {tick = 0, forces = forces, get_player = function() return nil end})

require("control")

-- One registration per event, filtered to the active transceiver.
for _, id in ipairs({events.on_built_entity, events.on_robot_built_entity, events.on_entity_cloned,
	events.script_raised_built, events.script_raised_revive}) do
	check(registrations[id] == 1, "Each build event should be registered once")
	local filter = filters[id]
	check(filter and #filter == 1 and filter[1].filter == "name"
		and filter[1].name == "kr-activated-intergalactic-transceiver",
		"Build events should be filtered by the transceiver name")
end
check(registrations[events.on_console_command] == 1 and registrations[events.on_player_joined_game] == 1
	and registrations[events.on_player_removed] == 1, "The cheat helpers should be wired")
check(nth[600] and nth[6], "The transceiver poll and the staged research tick should be registered")
check(registered_commands["razi-cheat"] and registered_commands["razi-cheat"].help[1] == "razi-cheat.help",
	"/razi-cheat should be registered with localized help")
check(lifecycle.init and lifecycle.changed and not lifecycle.load, "Only init and configuration hooks are needed")

-- The gate opens for a force that owns an active transceiver; researched forces are skipped.
lifecycle.init()
local gate = "razi-intergalactic-transceiver-signal"
check(forces.player.technologies[gate].researched and forces.player.technologies[gate].enabled,
	"A force with an active transceiver should get the gate")
check(not forces.enemy.technologies[gate].researched, "A force without a transceiver keeps the gate closed")
check(not counted.done, "A force with the gate already researched should not be counted")

-- A build event opens the gate as well.
forces.enemy.technologies[gate] = technology(false, false)
handlers[events.script_raised_built]({entity = {valid = true, name = "kr-activated-intergalactic-transceiver",
	force = forces.enemy}})
check(forces.enemy.technologies[gate].researched, "Building the active transceiver should open the gate")

-- The Nexus repair runs only when Nexus itself changes.
active_mods["Nexus-Updated"] = "1.4.2"
lifecycle.changed({mod_changes = {["razi-protocol"] = {old_version = "2.1.5", new_version = "2.1.6"}}})
check(not forces.player.technologies["element882"].enabled, "A Razi-only update must not touch Nexus gates")
lifecycle.changed({mod_changes = {["Nexus-Updated"] = {old_version = "1.4.1", new_version = "1.4.2"}}})
check(forces.player.technologies["element882"].enabled, "A Nexus update should re-enable its hidden-by-migration gates")
check(not forces.player.technologies["atomacer"].enabled, "Hidden prototypes must stay disabled")

active_mods["Nexus-Updated"] = nil
forces.enemy.technologies["element882"] = technology(false, false)
lifecycle.changed({mod_changes = {["Nexus-Updated"] = {old_version = "1.4.2"}}})
check(not forces.enemy.technologies["element882"].enabled, "Removing Nexus must not enable anything")
print("runtime control: registry wiring, transceiver gate and the Nexus repair passed")
