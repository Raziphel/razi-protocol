-- Expedition Chronicle: technology-backed story and shared force timing.
-- Times use simulation ticks, so pausing or closing a save does not inflate results.
local story = require("scripts.journal_story")
local journal = {}

local ROOT = "razi_protocol_chronicle"
local TOGGLE = "razi_chronicle_toggle"
local WINDOW = "razi_chronicle_window"
local CLOSE = "razi_chronicle_close"
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
    ledger = {chapters = {}, quests = {}}
    db.forces[force.index] = ledger
  end
  ledger.chapters = ledger.chapters or {}
  ledger.quests = ledger.quests or {}
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

local function first_observed(record, key, imported)
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
  local changed = false

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
      if first_observed(state, "entry", imported) then changed = true end
    end
    if researched(force, chapter.finish) then
      if finish_observed(state, imported) then changed = true end
    end

    for _, quest in ipairs(chapter.quests) do
      local technology = technology_for(force, quest.tech)
      if technology then
        local quest_state = ledger.quests[quest.tech]
        if not quest_state then
          quest_state = {}
          ledger.quests[quest.tech] = quest_state
        end
        if technology.researched then
          -- A technology already finished when the mod is installed has no
          -- knowable historical finish tick. Never fabricate a split time.
          if not imported and entered and quest_state.reached_tick == nil then
            if first_observed(quest_state, "quest", false) then changed = true end
          end
          if finish_observed(quest_state, imported) then changed = true end
        elseif entered and can_research(technology) then
          if first_observed(quest_state, "quest", imported) then changed = true end
        end
      end
    end
  end
  return changed
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

local function ensure_toggle(player)
  if not (player and player.valid) then return end
  if not player.gui.top[TOGGLE] then
    player.gui.top.add{
      type = "button",
      name = TOGGLE,
      caption = "Expedition Chronicle",
      tooltip = "Razi Protocol story, quests, chapter progress and completion times"
    }
  end
end

local function close_window(player)
  local frame = player.gui.screen[WINDOW]
  if frame and frame.valid then
    if player.opened == frame then player.opened = nil end
    if frame.valid then frame.destroy() end
  end
end

local function add_wrapped(parent, caption, width)
  local label = parent.add{type = "label", caption = caption}
  label.style.single_line = false
  label.style.maximal_width = width or 630
  return label
end

local function chapter_available(force, chapter)
  return chapter.entry == nil or researched(force, chapter.entry)
end

local function chapter_completed(force, chapter)
  return researched(force, chapter.finish)
end

local function show_chapter(player, chapter, sidebar, detail, ledger)
  local force = player.force
  local selected_id = database().selection[player.index]
  local selected = selected_id == chapter.id
  local reached = chapter_available(force, chapter)
  local beaten = chapter_completed(force, chapter)
  local state = ledger.chapters[chapter.id]

  local prefix = beaten and "[DONE] " or (reached and "[OPEN] " or "[LOCKED] ")
  local button = sidebar.add{
    type = "button",
    name = CHAPTER_PREFIX .. chapter.id,
    caption = prefix .. chapter.title
  }
  button.style.minimal_width = 255
  if selected then button.enabled = false end
  if not selected then return end

  add_wrapped(detail, chapter.title, 650)
  add_wrapped(detail, chapter.subtitle, 650)
  add_wrapped(detail, beaten and "CHAPTER COMPLETE" or (reached and "CHAPTER ACTIVE" or "CHAPTER LOCKED"), 650)
  add_wrapped(detail, status_text(state, beaten, true), 650)
  detail.add{type = "line"}
  add_wrapped(detail, chapter.intro, 650)
  detail.add{type = "line"}

  local counted, witnessed = 0, 0
  for _, quest in ipairs(chapter.quests) do
    if technology_for(force, quest.tech) then
      counted = counted + 1
      if researched(force, quest.tech) then witnessed = witnessed + 1 end
    end
  end
  add_wrapped(detail, "Recorded milestones: " .. witnessed .. " / " .. counted ..
    " | The chapter's exit research determines chapter completion.", 650)

  for _, quest in ipairs(chapter.quests) do
    local technology = technology_for(force, quest.tech)
    if technology then
      local quest_state = ledger.quests[quest.tech]
      local complete = technology.researched
      local started = quest_state and quest_state.reached_tick ~= nil
      local mark = complete and "[DONE] " or (started and "[ACTIVE] " or "[LOCKED] ")
      local card = detail.add{type = "frame", direction = "vertical"}
      add_wrapped(card, mark .. quest.title .. (quest.side and " | Side expedition" or ""), 620)
      add_wrapped(card, quest.story, 620)
      add_wrapped(card, status_text(quest_state, complete, false), 620)
      if not complete then
        add_wrapped(card, "Research goal: [technology=" .. technology.name .. "]", 620)
      end
    end
  end

  if beaten then
    detail.add{type = "line"}
    add_wrapped(detail, "CHAPTER EPILOGUE", 650)
    add_wrapped(detail, chapter.outro, 650)
  elseif not reached then
    add_wrapped(detail, "The previous main expedition must open this chapter. Side expeditions are recorded independently.", 650)
  end
end

local function render(player)
  local frame = player.gui.screen[WINDOW]
  if not (frame and frame.valid) then return end
  local columns = frame["razi_chronicle_columns"]
  if not (columns and columns.valid) then return end
  local sidebar = columns["razi_chronicle_sidebar"]
  local detail = columns["razi_chronicle_detail"]
  sidebar.clear()
  detail.clear()

  local selection = database().selection
  if not selection[player.index] then selection[player.index] = story[1].id end
  local valid_selection = false
  for _, chapter in ipairs(story) do
    if chapter.id == selection[player.index] then valid_selection = true end
  end
  if not valid_selection then selection[player.index] = story[1].id end

  local ledger = ledger_for(player.force)
  add_wrapped(sidebar, "Shared progress: " .. player.force.name, 260)
  add_wrapped(sidebar, "Save playtime: " .. elapsed(game.tick), 260)
  sidebar.add{type = "line"}
  for _, chapter in ipairs(story) do
    show_chapter(player, chapter, sidebar, detail, ledger)
  end
  add_wrapped(sidebar, "Clock: HH:MM:SS of active simulation time. Times are shared by your force.", 260)
end

local function open_window(player)
  ensure_toggle(player)
  if player.gui.screen[WINDOW] then
    close_window(player)
    return
  end
  sync_force(player.force, false)
  local frame = player.gui.screen.add{
    type = "frame",
    name = WINDOW,
    direction = "vertical"
  }
  frame.auto_center = true
  local header = frame.add{type = "flow", direction = "horizontal"}
  header.drag_target = frame
  local title = header.add{
    type = "label",
    caption = "RAZI PROTOCOL | Expedition Chronicle",
    style = "frame_title"
  }
  title.drag_target = frame
  local drag = header.add{type = "empty-widget", style = "draggable_space_header"}
  drag.style.horizontally_stretchable = true
  drag.style.height = 28
  drag.drag_target = frame
  header.add{type = "button", name = CLOSE, caption = "X", tooltip = "Close chronicle"}
  local columns = frame.add{
    type = "flow",
    name = "razi_chronicle_columns",
    direction = "horizontal"
  }
  local sidebar = columns.add{
    type = "scroll-pane",
    name = "razi_chronicle_sidebar",
    direction = "vertical"
  }
  sidebar.style.minimal_width = 265
  sidebar.style.maximal_height = 650
  local detail = columns.add{
    type = "scroll-pane",
    name = "razi_chronicle_detail",
    direction = "vertical"
  }
  detail.style.minimal_width = 680
  detail.style.maximal_height = 650
  player.opened = frame
  render(player)
end

local function refresh_force(force)
  for _, player in pairs(force.connected_players) do
    if player.gui.screen[WINDOW] then render(player) end
  end
end

function journal.on_init()
  database()
  -- on_init also runs when the mod is first installed into an existing save.
  -- Research completed before that instant has no historically valid split.
  local imported = game.tick > 10
  for _, force in pairs(game.forces) do
    sync_force(force, imported)
  end
  for _, player in pairs(game.players) do ensure_toggle(player) end
end

function journal.on_configuration_changed()
  database()
  for _, force in pairs(game.forces) do
    sync_force(force, true)
  end
  for _, player in pairs(game.players) do
    ensure_toggle(player)
    if player.gui.screen[WINDOW] then render(player) end
  end
end

function journal.register_events()
  script.on_event(defines.events.on_player_created, function(event)
    ensure_toggle(game.get_player(event.player_index))
  end)
  script.on_event(defines.events.on_player_joined_game, function(event)
    ensure_toggle(game.get_player(event.player_index))
  end)
  script.on_event(defines.events.on_force_created, function(event)
    sync_force(event.force, false)
  end)
  script.on_event(defines.events.on_research_finished, function(event)
    local force = event.research and event.research.force
    if force and sync_force(force, false) then refresh_force(force) end
  end)
  script.on_event(defines.events.on_gui_click, function(event)
    local element = event.element
    if not (element and element.valid) then return end
    local player = game.get_player(event.player_index)
    if not player then return end
    if element.name == TOGGLE then
      open_window(player)
    elseif element.name == CLOSE then
      close_window(player)
    elseif string.sub(element.name, 1, #CHAPTER_PREFIX) == CHAPTER_PREFIX then
      local id = string.sub(element.name, #CHAPTER_PREFIX + 1)
      for _, chapter in ipairs(story) do
        if chapter.id == id then
          database().selection[player.index] = id
          render(player)
          break
        end
      end
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
  script.on_nth_tick(300, function()
    for _, force in pairs(game.forces) do
      if sync_force(force, false) then refresh_force(force) end
    end
  end)
end

return journal
