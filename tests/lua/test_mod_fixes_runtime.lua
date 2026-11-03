-- Runtime repairs of other mods, without a Factorio binary: the radiation of Krastorio 2 that hurts the vehicle of a
-- player. Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_mod_fixes_runtime.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local event_names = {
	"on_built_entity", "on_robot_built_entity", "on_entity_cloned", "script_raised_built", "script_raised_revive",
	"on_console_command", "on_player_joined_game", "on_player_removed", "on_player_mined_entity",
	"on_robot_mined_entity", "on_entity_died", "script_raised_destroy", "on_gui_click", "on_gui_text_changed",
	"on_gui_selection_state_changed", "on_gui_closed", "on_research_finished", "on_player_created",
	"on_string_translated", "on_entity_damaged", "on_space_platform_mined_entity"
}
local events = {}
for index, name in ipairs(event_names) do
	events[name] = index
end

local handlers, filters, registrations = {}, {}, {}
local active_mods = {Krastorio2 = "2.1.4"}
local fake_script = {
	active_mods = active_mods,
	on_event = function(id, handler)
		registrations[id] = (registrations[id] or 0) + 1
		handlers[id] = handler
		-- Registering again drops filters, as in the game.
		filters[id] = nil
	end,
	on_nth_tick = function() end,
	on_init = function() end,
	on_load = function() end,
	on_configuration_changed = function() end,
	set_event_filter = function(id, filter)
		check(handlers[id], "A filter set before its registration would be lost")
		filters[id] = filter
	end
}
rawset(_G, "defines", {events = events})
rawset(_G, "script", fake_script)
rawset(_G, "commands", {add_command = function() end})
local logged = {}
rawset(_G, "log", function(message) logged[#logged + 1] = message end)

rawset(_G, "prototypes", {damage = {["kr-radioactive"] = {}}})
rawset(_G, "game", {tick = 0, forces = {}, players = {}, surfaces = {}, get_player = function() return nil end})
-- Loading control.lua runs on every load of a save, where save data is read-only.
local storage_touched
rawset(_G, "storage", setmetatable({}, {
	__index = function() storage_touched = true end,
	__newindex = function() storage_touched = true end
}))

local Events = require("__razi_lib__/runtime/events")
require("control")
check(not storage_touched, "Loading control.lua must not touch save data")
rawset(_G, "storage", {})

-- With Krastorio 2: the event is registered once and filtered.
local damaged = filters[events.on_entity_damaged]
check(registrations[events.on_entity_damaged] == 1, "on_entity_damaged should be registered once")
check(damaged and #damaged == 2 and damaged[1].filter == "vehicle" and damaged[1].mode == nil
	and damaged[2].filter == "damage-type" and damaged[2].type == "kr-radioactive" and damaged[2].mode == "and",
	"on_entity_damaged should see vehicles hit by kr-radioactive only")
-- Radiation: the vehicle gets the damage back.
local function vehicle(health)
	return {valid = true, name = "car", health = health}
end
local car = vehicle(100)
handlers[events.on_entity_damaged]({entity = car, final_damage_amount = 7.25})
check(car.health == 107.25, "A vehicle should get the radiation damage back")
check(#logged == 1 and logged[1]:find("^razi%-protocol: "), "The first return should be logged")
handlers[events.on_entity_damaged]({entity = car, final_damage_amount = 7.25})
check(#logged == 1, "Only the first return is logged")
-- Damage with a shooter or a projectile is a weapon hit and stays.
car = vehicle(100)
handlers[events.on_entity_damaged]({entity = car, final_damage_amount = 9, cause = {valid = true}})
handlers[events.on_entity_damaged]({entity = car, final_damage_amount = 9, source = {valid = true}})
check(car.health == 100, "Damage with a cause or a source should stay")
-- Nothing to return to.
local gone = vehicle(100)
gone.valid = false
handlers[events.on_entity_damaged]({entity = gone, final_damage_amount = 7.25})
check(gone.health == 100, "An invalid entity should be left alone")
local no_health = {valid = true, name = "wagon"}
handlers[events.on_entity_damaged]({entity = no_health, final_damage_amount = 7.25})
check(no_health.health == nil, "An entity without health should be left alone")

-- Without Krastorio 2 nothing is registered or filtered.
local damage = require("scripts.events.damage")
local function wiring()
	local registry = Events.new()
	damage.register(registry)
	return registry
end

rawset(fake_script, "active_mods", {})
check(next(wiring().events) == nil, "Without Krastorio 2 no event should be registered")
filters[events.on_entity_damaged] = nil
damage.set_filters()
check(filters[events.on_entity_damaged] == nil, "Without Krastorio 2 no filter should be set")

-- Krastorio 2 without its damage type.
rawset(fake_script, "active_mods", {Krastorio2 = "2.1.4"})
rawset(_G, "prototypes", {damage = {}})
check(next(wiring().events) == nil, "Without the damage type no event should be registered")
damage.set_filters()
check(filters[events.on_entity_damaged] == nil, "Without the damage type no filter should be set")

-- The damage type without the mod: a stray prototype does not register anything.
rawset(fake_script, "active_mods", {})
rawset(_G, "prototypes", {damage = {["kr-radioactive"] = {}}})
check(next(wiring().events) == nil, "A damage type alone should not register anything")
print("runtime mod fixes: Krastorio 2 radiation passed")
