-- Big-Monsters' bm-event-days is runtime-global and cannot be assigned by
-- another mod. Its setting stays pinned to zero (native scheduler disabled),
-- while Nightmare runs the same five-day cadence through its public API.
-- This keeps every other difficulty entirely free of surprise invasions.
local M = {}

local HOUR_TICKS = 60 * 60
local NIGHTMARE_DAYS = 5
local EVENT_TICKS = NIGHTMARE_DAYS * 7 * HOUR_TICKS
local SILO_TICKS = NIGHTMARE_DAYS * 4 * HOUR_TICKS

local function nightmare()
  local startup = settings and settings.startup
  local selection = startup and startup["razi-difficulty-preset"]
  return selection and selection.value == "nightmare"
end

local function available()
  local interfaces = remote and remote.interfaces
  local api = interfaces and interfaces.bigmonster
  return api and api.create_event and api.create_silo_event
end

local function silo_enabled()
  local global = settings and settings.global
  local option = global and global["bm-enable-silo-attack"]
  return option and option.value == true
end

local function new_schedule(tick)
  return {
    next_event = tick + EVENT_TICKS,
    next_silo = tick + SILO_TICKS
  }
end

-- Called only when creating a new game or loading a changed mod set.
-- A version update starts a fresh countdown instead of immediately attacking
-- a player whose save already has more than five days of playtime.
function M.prepare()
  if nightmare() and available() then
    storage.razi_big_monsters = new_schedule(game.tick)
  else
    storage.razi_big_monsters = nil
  end
end

function M.tick(event)
  if not nightmare() or not available() then
    storage.razi_big_monsters = nil
    return
  end
  local schedule = storage.razi_big_monsters
  if not schedule then
    schedule = new_schedule(event.tick)
    storage.razi_big_monsters = schedule
  end

  -- Mirror the original mod's hourly check and its random interval after
  -- each attack. Do not fire a backlog after a paused/unloaded save.
  if event.tick > schedule.next_event then
    remote.call("bigmonster", "create_event")
    schedule.next_event = event.tick
      + NIGHTMARE_DAYS * (7 + math.random(-2, 2)) * HOUR_TICKS
  end
  if event.tick > schedule.next_silo and silo_enabled() then
    remote.call("bigmonster", "create_silo_event")
    schedule.next_silo = event.tick
      + NIGHTMARE_DAYS * (7 + math.random(-4, -2)) * HOUR_TICKS
  end
end

function M.register(events)
  events:on_init(M.prepare)
  events:on_configuration_changed(M.prepare)
  events:on_nth_tick(HOUR_TICKS, M.tick)
end

return M
