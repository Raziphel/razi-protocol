-- Exercise the actual registered Nightmare runtime callbacks, not a copy
-- of the schedule. No Factorio binary required for this focused test.
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(condition, message)
  if not condition then error(message, 2) end
end

local callbacks = {}
local events = {
  on_init = function(_, fn) callbacks.init = fn end,
  on_configuration_changed = function(_, fn) callbacks.changed = fn end,
  on_nth_tick = function(_, period, fn)
    check(period == 3600, "Use Big-Monsters' original hourly polling interval")
    callbacks.tick = fn
  end
}

local calls = {}
rawset(_G, "remote", {
  interfaces = {bigmonster = {create_event = true, create_silo_event = true}},
  call = function(interface, method)
    check(interface == "bigmonster", "Must use Big-Monsters' public remote API")
    calls[#calls + 1] = method
  end
})
rawset(_G, "game", {tick = 900000})
rawset(_G, "storage", {})
rawset(_G, "settings", {startup = {
  ["razi-difficulty-preset"] = {value = "nightmare"}
}, global = {["bm-enable-silo-attack"] = {value = true}}})

local module = require("scripts.events.big_monsters")
module.register(events)
check(callbacks.init and callbacks.changed and callbacks.tick,
  "Nightmare integration must register init, migration, and tick handlers")

callbacks.init()
local initial = storage.razi_big_monsters
check(initial.next_event == game.tick + 5 * 7 * 3600
    and initial.next_silo == game.tick + 5 * 4 * 3600,
  "Nightmare must start a five-day schedule, not spawn immediately")
callbacks.tick({tick = initial.next_silo})
check(#calls == 0, "Do not start an attack before the scheduled check")
callbacks.tick({tick = initial.next_silo + 3600})
check(#calls == 1 and calls[1] == "create_silo_event",
  "Enabled silo attacks must follow the native Big-Monsters interval")
check(storage.razi_big_monsters.next_silo >= initial.next_silo + 3600 + 15 * 3600
    and storage.razi_big_monsters.next_silo <= initial.next_silo + 3600 + 25 * 3600,
  "Silo follow-up must use Big-Monsters' native random interval")
local event_tick = initial.next_event + 3600
callbacks.tick({tick = event_tick})
check(#calls == 2 and calls[2] == "create_event",
  "First normal attack must arrive after five game days")
local follow_up = storage.razi_big_monsters.next_event
check(follow_up >= event_tick + 25 * 3600
    and follow_up <= event_tick + 45 * 3600,
  "Follow-up events must preserve Big-Monsters' random interval")
callbacks.tick({tick = event_tick})
check(#calls == 2, "Polling the same tick cannot create duplicate events")

-- Persisted schedules survive ordinary save loads; a real mod version
-- change starts a new five-day countdown rather than immediately attacking.
game.tick = 1200000
callbacks.changed()
check(storage.razi_big_monsters.next_event == game.tick + 5 * 7 * 3600
  and #calls == 2, "Upgrading an existing Nightmare save must not raid on load")

-- Disabling the silo attack setting must disable ONLY that event type.
settings.global["bm-enable-silo-attack"].value = false
local silo_due = storage.razi_big_monsters.next_silo + 3600
callbacks.tick({tick = silo_due})
check(#calls == 2, "Disabled silo raids must never call the source mod")

-- Other difficulties, including Custom, must never trigger invasions.
for _, mode in ipairs({"normal", "easy", "hard", "custom"}) do
  settings.startup["razi-difficulty-preset"].value = mode
  game.tick = game.tick + 3600
  callbacks.changed()
  callbacks.tick({tick = game.tick + 1000000})
  check(storage.razi_big_monsters == nil and #calls == 2,
    mode .. " must not schedule Big-Monsters events")
end

-- Missing or partially-installed Big-Monsters must never crash or schedule.
settings.startup["razi-difficulty-preset"].value = "nightmare"
remote.interfaces.bigmonster = nil
callbacks.changed()
callbacks.tick({tick = game.tick + 3600})
check(storage.razi_big_monsters == nil and #calls == 2,
  "No events may be scheduled if Big-Monsters is missing")
remote.interfaces.bigmonster = {create_event = true}
callbacks.changed()
callbacks.tick({tick = game.tick + 3600})
check(storage.razi_big_monsters == nil and #calls == 2,
  "A partial remote API must not be called")
remote.interfaces.bigmonster = {create_event = true, create_silo_event = true}
callbacks.tick({tick = game.tick + 3600})
check(storage.razi_big_monsters and #calls == 2,
  "A reinstalled source mod should start a new timer without an immediate attack")

rawset(_G, "settings", nil)
rawset(_G, "remote", nil)
rawset(_G, "game", nil)
rawset(_G, "storage", nil)
print("Nightmare Big-Monsters event schedule passed")
