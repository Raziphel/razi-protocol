-- Expedition Chronicle: technology-backed story and shared force timing.
-- Times use simulation ticks, so pausing or closing a save does not inflate results.
local story = require("scripts.journal_story")
local journal = {}

local ROOT = "razi_protocol_chronicle"
local TOGGLE = "razi_chronicle_toggle"
local WINDOW = "razi_chronicle_window"
local CLOSE = "razi_chronicle_close"
local REFRESH = "razi_chronicle_refresh"
local CHAPTER_PREFIX = "razi_chronicle_chapter_"

local function database()
  storage[ROOT] = storage[ROOT] or {forces = {}, selection = {}}
  local db = storage[ROOT]
  db.forces = db.forces or {}
  db.selection = db.selection or {}
  return db
end

local function ledger_for(force)
  local db = database()
  local ledger = db.forces[force.index]
  if not ledger then
    ledger = {chapters = {}, quests = {}, visits = {}, platforms = {}}
    db.forces[force.index] = ledger
  end
  ledger.chapters = ledger.chapters or {}
  ledger.quests = ledger.quests or {}
  ledger.visits = ledger.visits or {}
  ledger.platforms = ledger.platforms or {}
  return ledger
end

local function technology_for(force, names)
  if type(names) == "string" then
    return force.technologies[names]
  end
  if type(names) == "table" then
    for _, name in ipairs(names) do
      local technology = force.technologies[name]
      if technology then return technology end
    end
  end
  return nil
end

local function researched(force, names)
  local technology = technology_for(force, names)
  return technology ~= nil and technology.researched
end

local function can_research(technology)
  if not (technology and technology.valid and technology.enabled) then
    return false
  end
  for _, prerequisite in pairs(technology.prerequisites or {}) do
    if not prerequisite.researched then return false end
  end
  return true
end


local function quest_key(quest)
  return quest.id or quest.tech
end

local function project_technologies(force, quest)
  local result = {}
  for _, name in ipairs(quest.requires or {}) do
    local tech = force.technologies[name]
    if tech then result[#result + 1] = tech end
  end
  return result
end

local function quest_present(force, quest)
  if quest.platform or quest.trip then return true end
  if quest.planet then
    return game.planets[quest.planet] ~= nil
      and (not quest.after or technology_for(force, quest.after) ~= nil)
  end
  if quest.project then
    return #project_technologies(force, quest) >= 2
  end
  return technology_for(force, quest.tech) ~= nil
end

local function quest_finished(force, ledger, quest)
  if quest.platform then return ledger.platforms.first ~= nil end
  if quest.trip then return ledger.platforms.trip ~= nil end
  if quest.planet then
    return ledger.visits[quest.planet] ~= nil
      and (not quest.after or researched(force, quest.after))
  end
  if quest.project then
    local technologies = project_technologies(force, quest)
    if #technologies < 2 then return false end
    for _, technology in ipairs(technologies) do
      if not technology.researched then return false end
    end
    return true
  end
  return researched(force, quest.tech)
end

local function quest_accessible(force, quest, entered)
  if not entered then return false end
  if quest.platform or quest.trip then return true end
  if quest.planet then
    return not quest.after or researched(force, quest.after)
  end
  if quest.project then
    return true -- Projects start with their chapter, never grant new unlocks.
  end
  return can_research(technology_for(force, quest.tech))
end

local function observe_surface(player, imported)
  if not (player and player.valid and player.force and player.force.valid) then return false end
  local surface = player.physical_surface
  local planet = surface and surface.valid and surface.planet
  if not (planet and planet.valid) then return false end
  local visits = ledger_for(player.force).visits
  if visits[planet.name] then return false end
  visits[planet.name] = {tick = game.tick, imported = imported == true}
  return true
end

local function observe_platforms(force, imported)
  local ledger = ledger_for(force)
  if ledger.platforms.first and ledger.platforms.trip then return false end
  local changed = false
  for _, platform in pairs(force.platforms) do
    if platform.valid then
      local hub = platform.hub
      if not ledger.platforms.first and hub and hub.valid then
        ledger.platforms.first = {tick = game.tick, imported = imported == true}
        changed = true
      end
      if not ledger.platforms.trip and platform.completed_trips > 0 then
        ledger.platforms.trip = {tick = game.tick, imported = imported == true}
        changed = true
      end
    end
    if ledger.platforms.first and ledger.platforms.trip then break end
  end
  return changed
end

local function first_observed(record, imported)
  if record.reached_tick == nil then
    record.reached_tick = game.tick
    record.reached_late = imported == true
    return true
  end
  return false
end

local function finish_observed(record, imported)
  if record.completed_tick == nil then
    record.completed_tick = game.tick
    record.completed_before_tracking = imported == true or record.reached_tick == nil
    return true
  end
  return false
end

local function sync_force(force, imported)
  if not (force and force.valid) then return false end
  local ledger = ledger_for(force)
  local changed = observe_platforms(force, imported)
  local announcements = {}

  for _, chapter in ipairs(story) do
    local state = ledger.chapters[chapter.id]
    if not state then
      state = {}
      ledger.chapters[chapter.id] = state
    end

    -- The completed research is authoritative, not the order a player clicks
    -- journal pages. Optional planets cannot stall these story gates.
    local entered = chapter.entry == nil or researched(force, chapter.entry)
    if entered then
      if first_observed(state, imported) then changed = true end
    end
    if researched(force, chapter.finish) then
      if finish_observed(state, imported) then
        changed = true
        if not imported and not state.completed_before_tracking then
          announcements[#announcements + 1] = {
            title = "Chapter complete: " .. chapter.title,
            detail = chapter.outro, chapter = chapter.id
          }
        end
      end
    end

    for _, quest in ipairs(chapter.quests) do
      if quest_present(force, quest) then
        local id = quest_key(quest)
        local quest_state = ledger.quests[id]
        if not quest_state then
          quest_state = {}
          ledger.quests[id] = quest_state
        end
        if quest_accessible(force, quest, entered) then
          -- Already-completed research on an imported save has no reliable
          -- unlock tick. Starting its timer now would invent a zero split.
          local completed = quest_finished(force, ledger, quest)
          if not completed or quest.planet or quest.project then
            if first_observed(quest_state, imported) then changed = true end
          end
        end
        if quest_finished(force, ledger, quest) then
          local visit = quest.planet and ledger.visits[quest.planet]
          local platform = quest.platform and ledger.platforms.first or
            (quest.trip and ledger.platforms.trip)
          if finish_observed(quest_state, imported or
            (visit and visit.imported) or (platform and platform.imported)) then
            changed = true
            if not imported and not quest_state.completed_before_tracking and
              (quest.project or quest.planet or quest.platform or quest.trip or
                quest.tech == chapter.finish) then
              announcements[#announcements + 1] = {
                title = quest.title,
                detail = quest.planet and "Landfall recorded" or
                  (quest.platform and "First operational space platform" or
                  (quest.trip and "First platform voyage complete" or
                  (quest.project and "Interplanetary project complete" or "Research milestone complete"))),
                chapter = chapter.id
              }
            end
          end
        end
      end
    end
  end
  return changed, announcements
end

local function elapsed(ticks)
  if ticks == nil then return "Not recorded" end
  local seconds = math.max(0, math.floor(ticks / 60))
  local hours = math.floor(seconds / 3600)
  local minutes = math.floor((seconds % 3600) / 60)
  return string.format("%02d:%02d:%02d", hours, minutes, seconds % 60)
end

local function status_text(record, finished, is_chapter)
  if not record then return "Not reached yet" end
  if finished and record.completed_before_tracking then
    return "Completed before tracking began | Historical time unavailable"
  end
  if finished and record.completed_tick then
    if record.reached_tick == nil then
      return "Completed | Duration unavailable"
    end
    local duration = elapsed(record.completed_tick - record.reached_tick)
    if record.reached_late then
      return "Completed | Tracked duration: " .. duration ..
        " (journal started mid-" .. (is_chapter and "chapter" or "quest") .. ")"
    end
    return "Reached at " .. elapsed(record.reached_tick) ..
      " | Finished at " .. elapsed(record.completed_tick) ..
      " | Time to beat: " .. duration
  end
  if record.reached_tick then
    if record.reached_late then
      return "In progress | Tracking since journal was enabled: " ..
        elapsed(game.tick - record.reached_tick)
    end
    return "Reached at " .. elapsed(record.reached_tick) ..
      " | In progress: " .. elapsed(game.tick - record.reached_tick)
  end
  return "Not reached yet"
end

-- The gameplay tracker only owns save-state and events. All seven screens,
-- the System Atlas and notifications share the same GUI presentation helpers.
local Chronicle = require("scripts.chronicle_gui")

local function context()
  return {
    db = database,
    ledger_for = ledger_for,
    story = story,
    technology_for = technology_for,
    researched = researched,
    quest_key = quest_key,
    quest_present = quest_present,
    quest_finished = quest_finished,
    project_technologies = project_technologies,
    chapter_available = function(force, chapter)
      return chapter.entry == nil or researched(force, chapter.entry)
    end,
    chapter_completed = function(force, chapter)
      return researched(force, chapter.finish)
    end,
    elapsed = elapsed,
    status_text = status_text,
    sync_force = sync_force
  }
end

local function ensure_toggle(player)
  Chronicle.ensure_toggle(player)
end

local function close_window(player)
  Chronicle.close(player)
end

local function render(player)
  Chronicle.render(player, context())
end

local function open_window(player)
  sync_force(player.force, false)
  Chronicle.open(player, context())
end

local function refresh_force(force)
  for _, player in pairs(force.connected_players) do
    if player.gui.screen[WINDOW] then render(player) end
  end
end

local function post_updates(force, events)
  if not events or #events == 0 then return end
  local last = events[#events]
  local title = #events == 1 and last.title or
    (tostring(#events) .. " new Chronicle milestones")
  local detail = #events == 1 and last.detail or
    ("Latest: " .. last.title)
  for _, player in pairs(force.connected_players) do
    Chronicle.notify(player, context(), title, detail, last.chapter)
  end
end

function journal.on_init()
  database()
  -- on_init also runs when the mod is first installed into an existing save.
  -- Research completed before that instant has no historically valid split.
  local imported = game.tick > 10
  for _, force in pairs(game.forces) do sync_force(force, imported) end
  for _, player in pairs(game.players) do
    observe_surface(player, imported)
    sync_force(player.force, imported)
    ensure_toggle(player)
  end
end

function journal.on_configuration_changed()
  database()
  for _, force in pairs(game.forces) do
    sync_force(force, true)
  end
  for _, player in pairs(game.players) do
    observe_surface(player, true)
    sync_force(player.force, true)
    ensure_toggle(player)
    if player.gui.screen[WINDOW] then
      close_window(player)
      open_window(player)
    end
  end
end

function journal.register_events()
  script.on_event(defines.events.on_player_created, function(event)
    local player = game.get_player(event.player_index)
    ensure_toggle(player)
    if player then
      observe_surface(player, false)
      sync_force(player.force, false)
    end
  end)
  script.on_event(defines.events.on_player_joined_game, function(event)
    local player = game.get_player(event.player_index)
    ensure_toggle(player)
    if player then
      observe_surface(player, false)
      sync_force(player.force, false)
    end
  end)
  script.on_event(defines.events.on_player_changed_surface, function(event)
    local player = game.get_player(event.player_index)
    if player and observe_surface(player, false) then
      local changed, announcements = sync_force(player.force, false)
      if changed then refresh_force(player.force) end
      post_updates(player.force, announcements)
    end
  end)
  script.on_event(defines.events.on_force_created, function(event)
    sync_force(event.force, false)
  end)
  script.on_event(defines.events.on_player_changed_force, function(event)
    local player = game.get_player(event.player_index)
    if player then
      observe_surface(player, false)
      sync_force(player.force, false)
      if player.gui.screen[WINDOW] then render(player) end
    end
  end)
  script.on_event(defines.events.on_forces_merged, function(event)
    local db = database()
    local source = db.forces[event.source_index]
    local destination = ledger_for(event.destination)
    if source then
      for _, kind in ipairs({"chapters", "quests"}) do
        for id, old_record in pairs(source[kind] or {}) do
          local existing = destination[kind][id]
          if not existing or (old_record.completed_tick and not existing.completed_tick) then
            destination[kind][id] = old_record
          end
        end
      end
      for kind, old_platform in pairs(source.platforms or {}) do
        local current = destination.platforms[kind]
        if not current or old_platform.tick < current.tick then
          destination.platforms[kind] = old_platform
        end
      end
      for planet, old_visit in pairs(source.visits or {}) do
        local current = destination.visits[planet]
        if not current or old_visit.tick < current.tick then
          destination.visits[planet] = old_visit
        end
      end
      db.forces[event.source_index] = nil
    end
    sync_force(event.destination, false)
    refresh_force(event.destination)
  end)
  script.on_event(defines.events.on_space_platform_built_entity, function(event)
    local force = event.platform and event.platform.force
    if force and not ledger_for(force).platforms.first then
      local changed, announcements = sync_force(force, false)
      if changed then refresh_force(force) end
      post_updates(force, announcements)
    end
  end)
  script.on_event(defines.events.on_space_platform_changed_state, function(event)
    local force = event.platform and event.platform.force
    if force and not ledger_for(force).platforms.trip then
      local changed, announcements = sync_force(force, false)
      if changed then refresh_force(force) end
      post_updates(force, announcements)
    end
  end)
  script.on_event(defines.events.on_research_started, function(event)
    -- An explicit start captures the beginning of very short techs that can
    -- otherwise finish between five-second polling passes.
    local force = event.research and event.research.force
    if force then
      local changed, announcements = sync_force(force, false)
      if changed then refresh_force(force) end
      post_updates(force, announcements)
    end
  end)
  script.on_event(defines.events.on_research_finished, function(event)
    local force = event.research and event.research.force
    if force then
      local changed, announcements = sync_force(force, false)
      if changed then refresh_force(force) end
      post_updates(force, announcements)
    end
  end)
  script.on_event(defines.events.on_gui_click, function(event)
    local element = event.element
    if not (element and element.valid) then return end
    local player = game.get_player(event.player_index)
    if not player then return end
    if element.name:sub(1, 15) == "razi_chronicle_" then
      Chronicle.click(player, element.name, context())
    end
  end)
  script.on_event(defines.events.on_gui_closed, function(event)
    local element = event.element
    if element and element.valid and element.name == WINDOW then
      local player = game.get_player(event.player_index)
      if player then close_window(player) end
    end
  end)
  -- Slow polling detects newly available technologies, scripted research
  -- unlocks and the special build-triggered transceiver research.
  script.on_nth_tick(120, function()
    Chronicle.expire_toasts(context())
  end)
  script.on_nth_tick(300, function()
    for _, force in pairs(game.forces) do
      -- Only rebuild windows when progress changes. A timed full rerender
      -- resets long chapter scroll positions, so the Refresh button is manual.
      local changed, announcements = sync_force(force, false)
      if changed then refresh_force(force) end
      post_updates(force, announcements)
    end
  end)
end

return journal
