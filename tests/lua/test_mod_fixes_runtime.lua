-- Runtime repairs of other mods, without a Factorio binary: the radiation of Krastorio 2 that hurts the vehicle of a
-- player, and the lamp that Cerys leaves behind a radiative tower. Run from the mod root with the library bootstrap:
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
local active_mods = {Krastorio2 = "2.1.4", ["Cerys-Moon-of-Fulgora"] = "4.25.0"}
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

local towers = {["cerys-fulgoran-radiative-tower"] = {}, ["cerys-radiative-heater"] = {}}
rawset(_G, "prototypes", {damage = {["kr-radioactive"] = {}}, entity = towers})
rawset(_G, "game", {tick = 0, forces = {}, players = {}, surfaces = {}, get_player = function() return nil end})
-- Loading control.lua runs on every load of a save, where save data is read-only.
local storage_touched
rawset(_G, "storage", setmetatable({}, {
	__index = function() storage_touched = true end,
	__newindex = function() storage_touched = true end
}))

require("control")
check(not storage_touched, "Loading control.lua must not touch save data")
rawset(_G, "storage", {})

local function names(filter)
	local found = {}
	for _, entry in ipairs(filter) do
		found[#found + 1] = entry.name
	end
	return table.concat(found, ",")
end

-- With both mods: each event is registered once and filtered.
local damaged = filters[events.on_entity_damaged]
check(registrations[events.on_entity_damaged] == 1, "on_entity_damaged should be registered once")
check(damaged and #damaged == 2 and damaged[1].filter == "vehicle" and damaged[1].mode == nil
	and damaged[2].filter == "damage-type" and damaged[2].type == "kr-radioactive" and damaged[2].mode == "and",
	"on_entity_damaged should see vehicles hit by kr-radioactive only")
for _, id in ipairs({events.on_player_mined_entity, events.on_robot_mined_entity, events.on_entity_died,
	events.script_raised_destroy}) do
	check(registrations[id] == 1, "Each removal event should be registered once")
	check(filters[id] and #filters[id] == 3 and filters[id][1].name == "razi-archive-relay"
		and names(filters[id]) == "razi-archive-relay,cerys-fulgoran-radiative-tower,cerys-radiative-heater",
		"Removal events should be filtered by the relay and the two towers")
end
check(registrations[events.on_space_platform_mined_entity] == 1
	and names(filters[events.on_space_platform_mined_entity]) == "cerys-fulgoran-radiative-tower,cerys-radiative-heater",
	"The platform mining event should be filtered by the two towers")

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

-- Lamp: it goes with its tower, other lamps stay.
local function lamp(name)
	local self = {name = name, destroyed = false}
	self.destroy = function() self.destroyed = true end
	return self
end
local searches = {}
local near = {lamp("radiative-tower-lamp-7"), lamp("small-lamp"), lamp("radiative-tower-lamp-12")}
local function tower(name)
	return {valid = true, name = name, position = {x = 4, y = 5}, surface = {
		find_entities_filtered = function(filter)
			searches[#searches + 1] = filter
			return near
		end
	}}
end
for _, name in ipairs({"cerys-fulgoran-radiative-tower", "cerys-radiative-heater"}) do
	for _, id in ipairs({events.on_player_mined_entity, events.on_robot_mined_entity, events.on_entity_died,
		events.script_raised_destroy, events.on_space_platform_mined_entity}) do
		near = {lamp("radiative-tower-lamp-7"), lamp("small-lamp"), lamp("radiative-tower-lamp-12")}
		searches = {}
		logged = {}
		handlers[id]({entity = tower(name)})
		check(#searches == 1 and searches[1].type == "lamp" and searches[1].radius == 1
			and searches[1].position.x == 4 and searches[1].position.y == 5, "The lamp should be searched within a tile")
		check(near[1].destroyed and near[3].destroyed, "The lamps of the tower should be destroyed")
		check(not near[2].destroyed, "Another lamp should stay")
		check(#logged == 2, "Each removed lamp should be logged")
	end
end
-- The relay and an invalid tower are not towers.
searches = {}
handlers[events.on_entity_died]({entity = {valid = true, name = "razi-archive-relay", position = {x = 0, y = 0},
	surface = {find_entities_filtered = function(filter) searches[#searches + 1] = filter; return {} end}}})
handlers[events.on_entity_died]({entity = {valid = false, name = "cerys-radiative-heater"}})
handlers[events.on_entity_died]({})
check(#searches == 0, "Only a valid tower starts a search")

-- Without the mods nothing is registered for them.
local Events = require("__razi_lib__/runtime/events")
local entities = require("scripts.events.entities")
local damage = require("scripts.events.damage")
local function wiring()
	local registry = Events.new()
	damage.register(registry)
	entities.register(registry)
	for id in pairs(registry.events) do
		check(id ~= events.on_entity_damaged and id ~= events.on_space_platform_mined_entity,
			"Event " .. id .. " should stay free")
	end
	return registry
end
local function reset_filters()
	for id in pairs(filters) do
		filters[id] = nil
	end
	for _, id in ipairs({events.on_entity_damaged, events.on_space_platform_mined_entity,
		events.on_player_mined_entity, events.on_entity_died}) do
		handlers[id] = handlers[id] or function() end
	end
end

rawset(fake_script, "active_mods", {})
reset_filters()
local registry = wiring()
check(#registry.events[events.on_entity_died] == 1, "Without Cerys the relay is the only remover")
damage.set_filters()
entities.set_filters()
check(filters[events.on_entity_damaged] == nil and filters[events.on_space_platform_mined_entity] == nil,
	"Without the mods no filter is set for them")
check(#filters[events.on_entity_died] == 1 and filters[events.on_entity_died][1].name == "razi-archive-relay",
	"Without Cerys the removal filter is the relay alone")

-- Krastorio2 without its damage type, Cerys without its towers.
rawset(fake_script, "active_mods", {Krastorio2 = "2.1.4", ["Cerys-Moon-of-Fulgora"] = "4.25.0"})
rawset(_G, "prototypes", {damage = {}, entity = {}})
reset_filters()
wiring()
damage.set_filters()
entities.set_filters()
check(filters[events.on_entity_damaged] == nil and filters[events.on_space_platform_mined_entity] == nil
	and #filters[events.on_entity_died] == 1, "Missing prototypes should switch the repairs off")

-- Prototypes without the mods: a stray prototype does not register anything.
rawset(fake_script, "active_mods", {})
rawset(_G, "prototypes", {damage = {["kr-radioactive"] = {}}, entity = towers})
reset_filters()
wiring()
print("runtime mod fixes: Krastorio 2 radiation and Cerys tower lamp passed")
