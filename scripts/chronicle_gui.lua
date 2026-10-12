-- Expedition Chronicle screen, shared visual system and optional achievement toasts.
-- Rendering is event driven; this file does not alter research or routes.
local theme = require("scripts.chronicle_theme")
local dossiers = require("scripts.chronicle_planets")
local ui = {}
local ROOT = "razi_chronicle_"
local WINDOW = ROOT .. "window"
local TOGGLE = ROOT .. "toggle"
local TOAST = ROOT .. "toast"
local TAB_PREFIX = ROOT .. "tab_"
local CHAPTER_PREFIX = ROOT .. "chapter_"
local FILTER_PREFIX = ROOT .. "filter_"
local PLANET_PREFIX = ROOT .. "planet_"
local TABS = {
  {"overview", "Overview"}, {"missions", "Missions"},
  {"planets", "Planets"}, {"projects", "Projects"},
  {"timeline", "Timeline"}, {"records", "Records"},
  {"atlas", "System Atlas"}
}
local FILTERS = {
  {"all", "All"}, {"ready", "Active"},
  {"done", "Completed"}, {"branch", "Branches"}
}

local function preferences(ctx, player)
  local db = ctx.db()
  db.ui = db.ui or {}
  local state = db.ui[player.index]
  if not state then
    state = {
      tab = "overview",
      chapter = db.selection[player.index] or ctx.story[1].id,
      filter = "all",
      notifications = true
    }
    db.ui[player.index] = state
  end
  if state.notifications == nil then state.notifications = true end
  if not state.tab then state.tab = "overview" end
  if not state.chapter then state.chapter = ctx.story[1].id end
  return state
end

local function chapter_by_id(ctx, id)
  for _, chapter in ipairs(ctx.story) do
    if chapter.id == id then return chapter end
  end
  return ctx.story[1]
end

local function totals(ctx, force, ledger, chapter)
  local done, total = 0, 0
  for _, quest in ipairs(chapter.quests) do
    if ctx.quest_present(force, quest) then
      total = total + 1
      if ctx.quest_finished(force, ledger, quest) then done = done + 1 end
    end
  end
  return done, total
end

local function chapter_state(ctx, force, ledger, chapter)
  local available = ctx.chapter_available(force, chapter)
  local finished = ctx.chapter_completed(force, chapter)
  local record = ledger.chapters[chapter.id]
  return available, finished, record
end

local function display_title(chapter)
  return chapter.title:gsub("^%u+%. ", "")
end

local function chapter_summary(parent, ctx, player, chapter, ledger, wide)
  local force = player.force
  local available, finished, record = chapter_state(ctx, force, ledger, chapter)
  local done, total = totals(ctx, force, ledger, chapter)
  local head = theme.card(parent, {padding = 12})
  local row = theme.row(head, 12)
  theme.chapter_icon(row, chapter.id, 46)
  local stack = theme.column(row, 3)
  theme.heading(stack, chapter.title, chapter.id)
  theme.caption(stack, chapter.subtitle)
  theme.badge(stack, finished and "CHAPTER COMPLETE" or (available and "EXPEDITION ACTIVE" or "NOT YET UNLOCKED"),
    finished and "completed" or (available and "active" or "locked"))
  theme.rule(head)
  theme.progress(head, done, total, wide and 415 or 245)
  theme.caption(head, ctx.status_text(record, finished, true))
  theme.label(head, chapter.intro, {width = wide and 650 or 560})
  if finished then
    theme.rule(head)
    theme.heading(head, "EPILOGUE", chapter.id)
    theme.label(head, chapter.outro, {width = 650})
  end
  return done, total
end

local function mission_status(ctx, force, ledger, quest)
  local finished = ctx.quest_finished(force, ledger, quest)
  local record = ledger.quests[ctx.quest_key(quest)]
  local reached = record and record.reached_tick ~= nil
  return finished, reached, record
end

local function mission_filter(ctx, force, ledger, quest, filter)
  if not ctx.quest_present(force, quest) then return false end
  local finished, started = mission_status(ctx, force, ledger, quest)
  if filter == "done" then return finished end
  if filter == "ready" then return started and not finished end
  if filter == "branch" then return quest.side == true end
  return true
end

local function add_objective_card(parent, ctx, player, chapter, quest, ledger, compact)
  local finished, started, record = mission_status(ctx, player.force, ledger, quest)
  local status, category = theme.status(finished, started)
  local card = theme.card(parent)
  local line = theme.row(card, 8)
  if quest.planet then theme.planet_icon(line, quest.planet, 29) end
  local text = theme.column(line, 3)
  theme.label(text, quest.title, {bold = true, color = theme.tint(chapter.id)})
  local badges = theme.row(text, 4)
  theme.badge(badges, status, category)
  theme.badge(badges, quest.project and "PROJECT" or (quest.planet and "LANDING" or "RESEARCH"),
    quest.project and "project" or (quest.planet and "landing" or "active"))
  if quest.side then theme.badge(badges, "BRANCH", "branch") end
  theme.label(card, quest.story, {width = 650})
  theme.caption(card, ctx.status_text(record, finished, false))

  if quest.project then
    local done, total = 0, 0
    local techs = ctx.project_technologies(player.force, quest)
    for _, tech in ipairs(techs) do if tech.researched then done = done + 1 end end
    theme.progress(card, done, total, 240)
    if quest.route then theme.caption(card, "Interplanetary link: " .. quest.route) end
    if not compact then
      for _, tech in ipairs(techs) do
        theme.label(card, (tech.researched and "[color=green]DONE[/color]  " or "NEEDED  ") ..
          "[technology=" .. tech.name .. "]", {width = 650})
      end
    end
  elseif quest.planet then
    local visit = ledger.visits[quest.planet]
    theme.caption(card, visit and ("First recorded landfall: " ..
      (visit.imported and "historical time unavailable" or ctx.elapsed(visit.tick)))
      or "Landfall pending: visit the planet surface")
    if not compact then
      if quest.after and not ctx.researched(player.force, quest.after) then
        theme.caption(card, "Unlock: [technology=" .. quest.after .. "]")
      end
      theme.button(card, PLANET_PREFIX .. quest.planet, "Inspect planet & routes", false,
        "Open the System Atlas for this world")
    end
  elseif not finished and not compact then
    local tech = ctx.technology_for(player.force, quest.tech)
    if tech then theme.caption(card, "Next research: [technology=" .. tech.name .. "]") end
  end
end

local function overview(parent, ctx, player, chapter, ledger)
  theme.heading(parent, "EXPEDITION COMMAND", chapter.id)
  local completed, available, total = 0, 0, 0
  local quests_completed, quests_total = 0, 0
  for _, node in ipairs(ctx.story) do
    if ctx.chapter_completed(player.force, node) then completed = completed + 1 end
    if ctx.chapter_available(player.force, node) then available = available + 1 end
    local done, count = totals(ctx, player.force, ledger, node)
    quests_completed = quests_completed + done
    quests_total = quests_total + count
    total = total + 1
  end
  local tiles = parent.add{type = "table", column_count = 3}
  tiles.style.horizontal_spacing = 9
  theme.stat(tiles, "Chapters completed", completed .. " / " .. total, theme.colors.done)
  theme.stat(tiles, "Expedition milestones", quests_completed .. " / " .. quests_total, theme.colors.active)
  local visits = 0
  for _ in pairs(ledger.visits or {}) do visits = visits + 1 end
  theme.stat(tiles, "Planets landed", tostring(visits), theme.colors.vibrant)
  theme.heading(parent, "Campaign completion", chapter.id)
  theme.progress(parent, quests_completed, quests_total, 435)
  chapter_summary(parent, ctx, player, chapter, ledger, true)
  theme.heading(parent, "NEXT OBJECTIVES", chapter.id)
  local candidates = 0
  for _, quest in ipairs(chapter.quests) do
    if ctx.quest_present(player.force, quest) and
      not ctx.quest_finished(player.force, ledger, quest) then
      local record = ledger.quests[ctx.quest_key(quest)]
      if record and record.reached_tick then
        add_objective_card(parent, ctx, player, chapter, quest, ledger, true)
        candidates = candidates + 1
      end
      if candidates >= 3 then break end
    end
  end
  if candidates == 0 then
    theme.caption(parent, "No active objectives in this chapter. Try another chapter or the Missions tab.")
  end
end

local function missions(parent, ctx, player, chapter, ledger, state)
  theme.heading(parent, "QUEST LOG  /  " .. chapter.title, chapter.id)
  local done, total = totals(ctx, player.force, ledger, chapter)
  theme.progress(parent, done, total, 410)
  local filters = theme.row(parent, 5)
  for _, spec in ipairs(FILTERS) do
    theme.button(filters, FILTER_PREFIX .. spec[1], spec[2], state.filter == spec[1])
  end
  theme.rule(parent)
  local shown = 0
  for _, quest in ipairs(chapter.quests) do
    if mission_filter(ctx, player.force, ledger, quest, state.filter) then
      add_objective_card(parent, ctx, player, chapter, quest, ledger, false)
      shown = shown + 1
    end
  end
  if shown == 0 then theme.caption(parent, "No missions match this filter.") end
end

local function planet_dossier(parent, ctx, player, chapter, quest, ledger)
  local planet = game.planets[quest.planet]
  if not planet then return end
  local visited = ledger.visits[quest.planet]
  local discovered = not quest.after or ctx.researched(player.force, quest.after)
  local card = theme.card(parent)
  local top = theme.row(card)
  theme.planet_icon(top, quest.planet, 44)
  local stack = theme.column(top, 3)
  theme.heading(stack, quest.planet:gsub("^%l", string.upper):gsub("%-", " "), chapter.id)
  theme.badge(stack, visited and "LANDED" or (discovered and "DISCOVERED" or "UNCHARTED"),
    visited and "completed" or (discovered and "active" or "locked"))
  theme.caption(card, quest.story)
  local info = dossiers[quest.planet]
  if info then
    theme.badge(card, info.role:upper(), "landing", theme.tint(chapter.id))
    theme.caption(card, "Environment: " .. info.hazard)
    theme.caption(card, "Campaign role: " .. info.links)
    if info.science and #info.science > 0 then
      local sciences = theme.column(card, 2)
      theme.heading(sciences, "RELEVANT RESEARCH", chapter.id)
      for _, name in ipairs(info.science) do
        local technology = player.force.technologies[name]
        if technology then
          theme.label(sciences,
            (technology.researched and "[color=green]COMPLETE[/color]  " or "UNRESEARCHED  ") ..
              "[technology=" .. name .. "]", {width=590})
        end
      end
    end
  end
  theme.caption(card, "Discovery: " .. (discovered and "Researched" or "Not researched"))
  theme.caption(card, "First visit: " .. (visited and
    (visited.imported and "Before arrival tracking started" or ctx.elapsed(visited.tick))
    or "Not yet recorded"))
  theme.button(card, PLANET_PREFIX .. quest.planet, "Explore connected routes", false,
    "Show verified route prototypes for this destination")
end

local function planets(parent, ctx, player, chapter, ledger)
  theme.heading(parent, "PLANETARY DOSSIERS", chapter.id)
  theme.caption(parent, "A discovery is not a landing. Dossiers distinguish researched coordinates from a crew actually arriving on the surface.")
  local shown = 0
  for _, quest in ipairs(chapter.quests) do
    if quest.planet and ctx.quest_present(player.force, quest) then
      planet_dossier(parent, ctx, player, chapter, quest, ledger)
      shown = shown + 1
    end
  end
  if shown == 0 then theme.caption(parent, "No planet landfalls are defined for this chapter.") end
end

local function projects(parent, ctx, player, _, ledger)
  theme.heading(parent, "INTERPLANETARY PROJECT BOARD", "solaris")
  theme.caption(parent, "Projects connect existing technologies. They do not add hidden travel locks or change modded science recipes.")
  local count = 0
  for _, chapter in ipairs(ctx.story) do
    local header = false
    for _, quest in ipairs(chapter.quests) do
      if quest.project and ctx.quest_present(player.force, quest) then
        if not header then
          theme.heading(parent, chapter.title, chapter.id)
          header = true
        end
        add_objective_card(parent, ctx, player, chapter, quest, ledger, false)
        count = count + 1
      end
    end
  end
  if count == 0 then theme.caption(parent, "No multi-system research projects are available.") end
end

local function timeline(parent, ctx, player, _, ledger)
  theme.heading(parent, "EXPEDITION TIMELINE", "deep-space")
  theme.caption(parent, "Recorded events are sorted by simulation time. Historical dates from saves played before Chronicle installation cannot be recovered.")
  local events = {}
  local function entry(tick, title, detail, chapter_id)
    if tick then events[#events + 1] = {
      tick = tick, title = title, detail = detail, chapter_id = chapter_id
    } end
  end
  for _, chapter in ipairs(ctx.story) do
    local record = ledger.chapters[chapter.id] or {}
    if record.reached_tick and not record.reached_late then
      entry(record.reached_tick, chapter.title, "Chapter opened", chapter.id)
    end
    if record.completed_tick and not record.completed_before_tracking then
      entry(record.completed_tick, chapter.title, "Chapter complete", chapter.id)
    end
    for _, quest in ipairs(chapter.quests) do
      local state = ledger.quests[ctx.quest_key(quest)]
      if state and state.completed_tick and not state.completed_before_tracking and
        not quest.planet then
        entry(state.completed_tick, quest.title, quest.project and "Project completed" or "Research achieved", chapter.id)
      end
    end
  end
  for planet, visit in pairs(ledger.visits) do
    if not visit.imported then
      entry(visit.tick, planet:gsub("^%l", string.upper), "First landfall", "calidus")
    end
  end
  table.sort(events, function(a, b)
    if a.tick == b.tick then return a.title < b.title end
    return a.tick > b.tick
  end)
  if #events == 0 then theme.caption(parent, "New achievements will appear here as the expedition progresses.") end
  local visible = math.min(#events, 75)
  for i = 1, visible do
    local event = events[i]
    local line = theme.card(parent, {padding = 7})
    local top = theme.row(line)
    theme.badge(top, ctx.elapsed(event.tick), "active", theme.tint(event.chapter_id))
    theme.label(top, event.title, {bold = true})
    theme.caption(line, event.detail)
  end
  if #events > visible then
    theme.caption(parent, tostring(#events - visible) .. " earlier events omitted to keep the timeline responsive.")
  end
end

local function records(parent, ctx, player, _, ledger, state)
  theme.heading(parent, "EXPEDITION RECORDS", "deep-space")
  local finished, quests = 0, 0
  local fastest, slowest, fast_name, slow_name
  local first_landing_tick, first_landing
  for _, chapter in ipairs(ctx.story) do
    local record = ledger.chapters[chapter.id] or {}
    if record.completed_tick and record.reached_tick and
      not record.completed_before_tracking and not record.reached_late then
      local duration = record.completed_tick - record.reached_tick
      if not fastest or duration < fastest then fastest, fast_name = duration, chapter.title end
      if not slowest or duration > slowest then slowest, slow_name = duration, chapter.title end
    end
    for _, quest in ipairs(chapter.quests) do
      if ctx.quest_present(player.force, quest) then
        quests = quests + 1
        if ctx.quest_finished(player.force, ledger, quest) then finished = finished + 1 end
      end
    end
  end
  for planet, visit in pairs(ledger.visits) do
    if not visit.imported and (not first_landing_tick or visit.tick < first_landing_tick) then
      first_landing_tick, first_landing = visit.tick, planet
    end
  end
  local stats = parent.add{type="table", column_count=2}
  stats.style.horizontal_spacing = 10
  theme.stat(stats, "Save simulation age", ctx.elapsed(game.tick), theme.colors.accent)
  theme.stat(stats, "Completed objectives", finished .. " / " .. quests, theme.colors.done)
  theme.stat(stats, "Fastest recorded chapter", fastest and ctx.elapsed(fastest) or "Not recorded", theme.colors.vibrant)
  theme.stat(stats, "Longest recorded chapter", slowest and ctx.elapsed(slowest) or "Not recorded", theme.colors.solaris)
  if fast_name then theme.caption(parent, "Fastest: " .. fast_name) end
  if slow_name then theme.caption(parent, "Longest: " .. slow_name) end
  if first_landing then theme.caption(parent, "First recorded landfall: " .. first_landing .. " at " .. ctx.elapsed(first_landing_tick)) end
  theme.rule(parent)
  theme.heading(parent, "GAMEPLAY SETTINGS", "calidus")
  theme.button(parent, ROOT .. "notifications", state.notifications and
    "Completion popups: ON" or "Completion popups: OFF", false,
    "Toggle the Chronicle's short, non-intrusive expedition popups")
  theme.caption(parent, "These settings only affect your own interface, not other members of your multiplayer force.")
  theme.heading(parent, "CHRONICLE TIMING RULES", "nyxaris")
  theme.caption(parent, "A quest's time to beat starts when the research becomes available, or when a chapter's landing/project objective opens. All times are saved in simulation ticks, not wall time.")
  theme.caption(parent, "Previously completed objectives are acknowledged, but their unknown historical times are never fabricated. For old saves, recorded landfalls may be partial.")
end

local function route_entries(name)
  local routes = {}
  for id, route in pairs(prototypes.space_connection or {}) do
    if route.from.name == name or route.to.name == name then
      local destination = route.from.name == name and route.to.name or route.from.name
      routes[#routes + 1] = {
        id = id, destination = destination, length = route.length
      }
    end
  end
  table.sort(routes, function(a,b)
    if a.destination == b.destination then return a.id < b.id end
    return a.destination < b.destination
  end)
  return routes
end

local function atlas(parent, ctx, player, chapter, ledger, state)
  theme.heading(parent, "SYSTEM ATLAS  /  " .. chapter.title, chapter.id)
  theme.caption(parent, "Live space-connection prototypes from the installed modpack. Connections do not mean the associated research or platform route is already unlocked.")
  local picker = theme.card(parent)
  theme.heading(picker, "Destinations", chapter.id)
  local buttons = picker.add{type="table", column_count=3}
  buttons.style.horizontal_spacing = 7
  local selection = state.planet
  local first
  for _, quest in ipairs(chapter.quests) do
    if quest.planet and game.planets[quest.planet] then
      if not first then first = quest.planet end
      theme.button(buttons, ROOT .. "atlas_" .. quest.planet, quest.planet, selection == quest.planet)
    end
  end
  if not selection or not game.planets[selection] then selection = first end
  if not selection then
    theme.caption(parent, "No atlas destinations in this chapter. Select a different chapter.")
    return
  end
  state.planet = selection
  local dossier = theme.card(parent)
  local header = theme.row(dossier)
  theme.planet_icon(header, selection, 56)
  theme.heading(header, selection:gsub("^%l", string.upper):gsub("%-", " "), chapter.id)
  local visited = ledger.visits[selection]
  theme.badge(dossier, visited and "SURFACE VISITED" or "SURFACE UNVISITED",
    visited and "completed" or "locked")
  local info = dossiers[selection]
  if info then
    theme.caption(dossier, "Speciality: " .. info.role)
    theme.caption(dossier, "Hazards: " .. info.hazard)
    theme.caption(dossier, info.links)
  end
  local orbiting = game.planets[selection].get_space_platforms(player.force)
  theme.caption(dossier, tostring(#orbiting) .. " friendly space platforms in orbit")
  local routes = route_entries(selection)
  theme.caption(dossier, tostring(#routes) .. " defined space connections")
  if #routes == 0 then theme.caption(dossier, "No route prototypes connect to this destination.") end
  for _, route in ipairs(routes) do
    local card = theme.card(dossier, {padding=6})
    local head = theme.row(card)
    local sprite = "space-location/" .. route.destination
    if helpers and helpers.is_valid_sprite_path and helpers.is_valid_sprite_path(sprite) then
      theme.planet_icon(head, route.destination, 25)
    end
    theme.label(head, route.destination:gsub("%-", " "), {bold=true})
    theme.caption(card, "Connection: " .. route.id ..
      (route.length and (" | " .. tostring(route.length) .. " km") or ""))
  end
end

function ui.ensure_toggle(player)
  if not (player and player.valid) then return end
  local current = player.gui.top[TOGGLE]
  if current and current.valid and current.type == "sprite-button" then return end
  if current and current.valid then current.destroy() end
  player.gui.top.add{
    type = "sprite-button",
    name = TOGGLE,
    sprite = "item/calidus-tech-card",
    style = "slot_button",
    tooltip = "Razi Protocol | Expedition Chronicle"
  }
end

function ui.close(player)
  local frame = player.gui.screen[WINDOW]
  if frame and frame.valid then
    if player.opened == frame then player.opened = nil end
    if frame.valid then frame.destroy() end
  end
end

function ui.render(player, ctx)
  local frame = player.gui.screen[WINDOW]
  if not (frame and frame.valid) then return end
  local body = frame[ROOT .. "body"]
  local navigation = frame[ROOT .. "navigation"]
  if not (body and navigation) then return end
  local state = preferences(ctx, player)
  local chapter = chapter_by_id(ctx, state.chapter)
  state.chapter = chapter.id
  local ledger = ctx.ledger_for(player.force)
  local sidebar = body[ROOT .. "sidebar"]
  local main = body[ROOT .. "main"]
  sidebar.clear()
  main.clear()
  navigation.clear()

  for _, tab in ipairs(TABS) do
    theme.button(navigation, TAB_PREFIX .. tab[1], tab[2], state.tab == tab[1])
  end
  theme.heading(sidebar, "STAR SYSTEMS", chapter.id)
  theme.caption(sidebar, "Force: " .. player.force.name)
  theme.rule(sidebar)
  for _, node in ipairs(ctx.story) do
    local done, count = totals(ctx, player.force, ledger, node)
    local available = ctx.chapter_available(player.force, node)
    local completed = ctx.chapter_completed(player.force, node)
    local entry = theme.card(sidebar, {padding=6})
    local header = theme.row(entry, 6)
    theme.chapter_icon(header, node.id, 25)
    theme.button(header, CHAPTER_PREFIX .. node.id,
      (completed and "OK " or (available and "> " or "? ")) .. display_title(node),
      chapter.id == node.id)
    local progress = entry.add{type="progressbar", value=done / math.max(1, count)}
  progress.style.width = 130
  progress.style.height = 10
  theme.caption(entry, done .. " of " .. count .. " missions")
  end
  theme.rule(sidebar)
  theme.caption(sidebar, "Save: " .. ctx.elapsed(game.tick))
  theme.caption(sidebar, "Times are shared with your force.")

  if state.tab == "missions" then
    missions(main, ctx, player, chapter, ledger, state)
  elseif state.tab == "planets" then
    planets(main, ctx, player, chapter, ledger)
  elseif state.tab == "projects" then
    projects(main, ctx, player, chapter, ledger)
  elseif state.tab == "timeline" then
    timeline(main, ctx, player, chapter, ledger)
  elseif state.tab == "records" then
    records(main, ctx, player, chapter, ledger, state)
  elseif state.tab == "atlas" then
    atlas(main, ctx, player, chapter, ledger, state)
  else
    overview(main, ctx, player, chapter, ledger)
  end
end

function ui.open(player, ctx)
  ui.ensure_toggle(player)
  if player.gui.screen[WINDOW] then
    ui.close(player)
    return
  end
  local frame = player.gui.screen.add{
    type = "frame",
    name = WINDOW,
    direction = "vertical"
  }
  frame.auto_center = true
  local available_width = math.floor(player.display_resolution.width / player.display_scale)
  local available_height = math.floor(player.display_resolution.height / player.display_scale)
  local width = math.max(675, math.min(1110, available_width - 65))
  local height = math.max(400, math.min(760, available_height - 100))
  frame.style.width = width
  local heading = theme.row(frame, 7)
  heading.drag_target = frame
  theme.chapter_icon(heading, "calidus", 34)
  local title = heading.add{type="label", caption="RAZI PROTOCOL  /  EXPEDITION CHRONICLE", style="frame_title"}
  title.drag_target = frame
  local filler = heading.add{type="empty-widget", style="draggable_space_header"}
  filler.style.horizontally_stretchable = true
  filler.style.height = 28
  filler.drag_target = frame
  theme.button(heading, ROOT .. "refresh", "Refresh", false, "Update the Chronicle without closing the window")
  theme.button(heading, ROOT .. "close", "X", false, "Close Chronicle")
  local navigation = theme.row(frame, 4)
  navigation.name = ROOT .. "navigation"
  navigation.style.horizontally_stretchable = true

  local body = frame.add{type="flow", name=ROOT .. "body", direction="horizontal"}
  body.style.horizontally_stretchable = true
  local sidebar = body.add{type="scroll-pane", name=ROOT .. "sidebar", direction="vertical"}
  sidebar.style.width = math.max(190, math.floor(width * 0.245))
  sidebar.style.height = height - 105
  sidebar.style.padding = 7
  local main = body.add{type="scroll-pane", name=ROOT .. "main", direction="vertical"}
  main.style.width = width - math.max(190, math.floor(width * 0.245)) - 36
  main.style.height = height - 105
  main.style.padding = 8
  player.opened = frame
  ui.render(player, ctx)
end

function ui.click(player, name, ctx)
  local state = preferences(ctx, player)
  if name == TOGGLE then
    ui.open(player, ctx)
    return true
  elseif name == ROOT .. "close" then
    ui.close(player)
    return true
  elseif name == ROOT .. "refresh" then
    ctx.sync_force(player.force, false)
    ui.render(player, ctx)
    return true
  elseif name == ROOT .. "notifications" then
    state.notifications = not state.notifications
    ui.render(player, ctx)
    return true
  elseif name == ROOT .. "toast_close" then
    local toast = player.gui.screen[TOAST]
    if toast then toast.destroy() end
    return true
  elseif name:sub(1, #TAB_PREFIX) == TAB_PREFIX then
    local tab = name:sub(#TAB_PREFIX + 1)
    for _, spec in ipairs(TABS) do
      if spec[1] == tab then state.tab = tab; ui.render(player, ctx); return true end
    end
  elseif name:sub(1, #CHAPTER_PREFIX) == CHAPTER_PREFIX then
    local id = name:sub(#CHAPTER_PREFIX + 1)
    for _, chapter in ipairs(ctx.story) do
      if chapter.id == id then
        state.chapter = id
        ctx.db().selection[player.index] = id
        state.planet = nil
        ui.render(player, ctx)
        return true
      end
    end
  elseif name:sub(1, #FILTER_PREFIX) == FILTER_PREFIX then
    for _, filter in ipairs(FILTERS) do
      if filter[1] == name:sub(#FILTER_PREFIX + 1) then
        state.filter = filter[1]
        ui.render(player, ctx)
        return true
      end
    end
  elseif name:sub(1, #PLANET_PREFIX) == PLANET_PREFIX then
    local planet = name:sub(#PLANET_PREFIX + 1)
    if game.planets[planet] then
      state.planet = planet
      state.tab = "atlas"
      ui.render(player, ctx)
      return true
    end
  elseif name:sub(1, #(ROOT .. "atlas_")) == ROOT .. "atlas_" then
    local planet = name:sub(#(ROOT .. "atlas_") + 1)
    if game.planets[planet] then
      state.planet = planet
      ui.render(player, ctx)
      return true
    end
  end
  return false
end

function ui.notify(player, ctx, title, detail, chapter_id)
  local state = preferences(ctx, player)
  if not state.notifications then return end
  local existing = player.gui.screen[TOAST]
  if existing then existing.destroy() end
  local toast = player.gui.screen.add{type="frame", name=TOAST, direction="vertical"}
  toast.style.width = 355
  toast.style.padding = 12
  local resolution = player.display_resolution
  local scale = player.display_scale
  toast.location = {
    x = math.max(0, math.floor(resolution.width / scale) - 390),
    y = 85
  }
  local header = theme.row(toast, 7)
  theme.chapter_icon(header, chapter_id, 28)
  theme.heading(header, "EXPEDITION UPDATE", chapter_id)
  theme.label(toast, title, {bold=true, color=theme.tint(chapter_id), width=325})
  theme.caption(toast, detail)
  theme.button(toast, ROOT .. "toast_close", "Dismiss", false)
  local db = ctx.db()
  db.toast_expiry = db.toast_expiry or {}
  db.toast_expiry[player.index] = game.tick + 420
end

function ui.expire_toasts(ctx)
  local db = ctx.db()
  if not db.toast_expiry then return end
  for index, expire in pairs(db.toast_expiry) do
    if game.tick >= expire then
      local player = game.get_player(index)
      if player and player.valid then
        local toast = player.gui.screen[TOAST]
        if toast then toast.destroy() end
      end
      db.toast_expiry[index] = nil
    end
  end
end

return ui
