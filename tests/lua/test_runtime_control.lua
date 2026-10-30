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
	on_player_removed = 8,
	on_player_mined_entity = 9,
	on_robot_mined_entity = 10,
	on_entity_died = 11,
	script_raised_destroy = 12,
	on_gui_click = 13,
	on_gui_text_changed = 14,
	on_gui_selection_state_changed = 15,
	on_gui_closed = 16,
	on_research_finished = 17,
	on_player_created = 18
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
local force_count = 0
local function force(name, gate_researched, transceivers)
	force_count = force_count + 1
	local self = {name = name, valid = true, index = force_count}
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
-- One surface whose planet switches the Arachnid nest off: init and configuration changes put that into the surface.
local surface_writes = 0
local surface_settings = {autoplace_settings = {entity = {settings = {}}}}
local surface = {name = "nauvis", planet = {prototype = {map_gen_settings = {autoplace_settings = {entity = {settings = {
	["arachnid-spawner-unitspawner"] = {frequency = 0, size = 0, richness = 0}}}}}}}}
setmetatable(surface, {
	__index = function(_, key) if key == "map_gen_settings" then return surface_settings end end,
	__newindex = function(_, key, value) if key == "map_gen_settings" then surface_writes = surface_writes + 1; surface_settings = value end end
})
rawset(_G, "game", {tick = 0, forces = forces, players = {}, surfaces = {nauvis = surface}, get_player = function() return nil end})
-- Loading control.lua runs on every load of a save, where save data is read-only:
-- nothing may read or write it before a lifecycle or game event.
local storage_touched
rawset(_G, "storage", setmetatable({}, {
	__index = function() storage_touched = true end,
	__newindex = function() storage_touched = true end
}))

require("control")

check(not storage_touched, "Loading control.lua must not touch save data")
rawset(_G, "storage", {})

-- One registration per event, filtered to the active transceiver and the Archive relay.
for _, id in ipairs({events.on_built_entity, events.on_robot_built_entity, events.on_entity_cloned,
	events.script_raised_built, events.script_raised_revive}) do
	check(registrations[id] == 1, "Each build event should be registered once")
	local filter = filters[id]
	check(filter and #filter == 2 and filter[1].filter == "name"
		and filter[1].name == "kr-activated-intergalactic-transceiver"
		and filter[2].filter == "name" and filter[2].name == "razi-archive-relay",
		"Build events should be filtered by the transceiver and relay names")
end
-- Removal events only matter for the Archive relay.
for _, id in ipairs({events.on_player_mined_entity, events.on_robot_mined_entity,
	events.on_entity_died, events.script_raised_destroy}) do
	check(registrations[id] == 1, "Each removal event should be registered once")
	local filter = filters[id]
	check(filter and #filter == 1 and filter[1].name == "razi-archive-relay",
		"Removal events should be filtered by the relay name")
end
check(registrations[events.on_console_command] == 1 and registrations[events.on_player_joined_game] == 1
	and registrations[events.on_player_removed] == 1, "The cheat helpers should be wired")
check(nth[600] and nth[6], "The transceiver poll and the staged research tick should be registered")
-- The Journal, Projects and Convergence are wired once each.
for _, id in ipairs({events.on_gui_click, events.on_gui_text_changed, events.on_gui_selection_state_changed,
	events.on_gui_closed, events.on_research_finished, events.on_player_created}) do
	check(registrations[id] == 1, "Each Journal event should be registered once")
end
check(handlers["razi-journal-toggle"], "The Journal hotkey should be wired")
check(nth[30] and nth[60] and nth[120] and nth[300], "The Journal and Convergence ticks should be registered")
for _, name in ipairs({"razi-welcome", "razi-audit", "razi-victory-audit"}) do
	check(registered_commands[name], "/" .. name .. " should be registered")
end
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

-- Surfaces that exist get the nests their planet switches off, once (the second call finds nothing to change).
local arachnid_entry = surface_settings.autoplace_settings.entity.settings["arachnid-spawner-unitspawner"] or {}
check(surface_writes == 1 and arachnid_entry.frequency == 0, "Init should switch the planet's nests off on an existing surface")
lifecycle.changed({mod_changes = {}})
check(surface_writes == 1, "A configuration change finds nothing more to switch off")
surface_settings.autoplace_settings.entity.settings["arachnid-spawner-unitspawner"] = nil
lifecycle.changed({mod_changes = {}})
check(surface_writes == 2, "A configuration change puts a missing entry back")

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
