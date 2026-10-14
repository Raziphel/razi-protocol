-- Writes a local Journal snapshot for the optional Discord companion.
-- Factorio Lua cannot connect to Discord IPC or start a local program.
local M={}
local journal=require("scripts.razi_journal")
local definitions=require("scripts.razi_journal_data")
local catalog=require("scripts.galactic_catalog")
local FILE="razi-presence/state.json"
M.FILE=FILE
M.SCHEMA=1
local function allowed(player)
  local controls=player and player.mod_settings
  local enabled=controls and controls["razi-discord-presence-enabled"]
  return enabled and enabled.value==true
end
local function pretty(value)
  local text=tostring(value or "Unknown"):gsub("[-_]"," ")
  return (text:gsub("^%l",string.upper))
end
local function chapter_number(id)
  for i,chapter in ipairs(definitions.chapters) do
    if chapter.id==id then return i end
  end
  return 1
end
-- Translation lives in storage as plain strings only. No LuaPlayer,
-- LuaTechnology or other non-serializable objects are stored between ticks.
local function translated(player,chapter,quest)
  if not quest then return pretty(chapter),"Campaign complete" end
  storage.razi_presence_translations=storage.razi_presence_translations or {}
  storage.razi_presence_pending=storage.razi_presence_pending or {}
  local cached=storage.razi_presence_translations[player.index] or {}
  storage.razi_presence_translations[player.index]=cached
  local key=chapter.."|"..quest.id
  if type(cached[key])=="string" then
    local a,b=cached[key]:match("^(.-)@@@(.*)$")
    if a and b then return a,b end
  end
  if cached[key]==nil then
    local id=player.request_translation({"",
      {"journal-chapter."..chapter},"@@@",{"journal-title."..quest.id}})
    if id then
      cached[key]=false -- queued or attempted; do not spam requests.
      storage.razi_presence_pending[id]={index=player.index,key=key}
    end
  end
  return pretty(chapter),pretty(quest.id)
end
function M.on_string_translated(event)
  local pending=storage.razi_presence_pending
  local request=pending and pending[event.id]
  if not request then return end
  pending[event.id]=nil
  if event.translated and type(event.result)=="string" then
    local cache=storage.razi_presence_translations
      and storage.razi_presence_translations[request.index]
    if cache then cache[request.key]=event.result end
  end
end
local function goal(player,context)
  local p=storage.razi_expedition_journal
    and storage.razi_expedition_journal[player.index] or {}
  local function active(id)
    local quest=id and definitions.by_id[id]
    return quest and journal.state(player.force,quest,context)=="active"
      and quest or nil
  end
  -- The pinned field objective is always the first choice, followed by
  -- the active selection and then the real next actionable quest.
  local quest=p.tracker and active(p.pinned) or nil
  quest=quest or active(p.selected) or journal.next_quest(player.force,context)
  if quest and journal.state(player.force,quest,context)~="active" then
    quest=nil
  end
  return quest
end
function M.payload(player,context)
  if not allowed(player) then return nil end
  context=context or journal.context(player.force)
  local quest=goal(player,context)
  local chapter=quest and quest.chapter or "finale"
  local chapter_title,quest_title=translated(player,chapter,quest)
  local completed,total=journal.summary(player.force,context)
  local in_chapter,chapter_total=0,0
  for _,item in ipairs(definitions.quests) do
    if item.chapter==chapter and journal.available(player.force,item,context) then
      chapter_total=chapter_total+1
      if journal.complete(player.force,item,context) then
        in_chapter=in_chapter+1
      end
    end
  end
  local surface=player.physical_surface
  local planet=surface and surface.planet
  local platform=surface and surface.platform
  local location=planet and planet.name
    or (platform and platform.name) or "Space"
  local region=planet and catalog.system(planet.name) or "space"
  local session=storage.razi_presence_session
    and storage.razi_presence_session[player.index]
  if not session then
    storage.razi_presence_session=storage.razi_presence_session or {}
    session=game.ticks_played
    storage.razi_presence_session[player.index]=session
  end
  local controls=player.mod_settings
  local show_quest=controls["razi-discord-presence-show-quest"]
  local show_location=controls["razi-discord-presence-show-location"]
  return {
    schema=M.SCHEMA,enabled=true,pack="Razi Protocol",
    chapter=chapter,chapter_number=chapter_number(chapter),
    chapter_title=chapter_title,
    quest=show_quest and show_quest.value and quest_title or "",
    quest_id=show_quest and show_quest.value and quest and quest.id or "",
    completed=completed,total=total,
    chapter_completed=in_chapter,chapter_total=chapter_total,
    location=show_location and show_location.value and location or "",
    region=show_location and show_location.value and region or "",
    multiplayer=game.is_multiplayer(),
    elapsed_ticks=math.max(0,game.ticks_played-session)
  }
end
function M.write()
  local contexts={}
  for _,player in pairs(game.connected_players or {}) do
    if allowed(player) then
      local force=player.force
      local context=contexts[force.index]
      if not context then
        context=journal.context(force)
        contexts[force.index]=context
      end
      local payload=M.payload(player,context)
      if payload then
        -- for_player targets only the local client in multiplayer. Do NOT
        -- create a shared file containing every player's private state.
        helpers.write_file(FILE,helpers.table_to_json(payload),
          false,player.index)
      end
    end
  end
end
function M.on_setting_changed(event)
  if not event.player_index or not event.setting
    or not event.setting:find("^razi%-discord%-presence%-") then return end
  local player=game.get_player(event.player_index)
  if not player then return end
  if not allowed(player) then
    -- Tell the desktop helper to clear the activity promptly.
    helpers.write_file(FILE,helpers.table_to_json({
      schema=M.SCHEMA,enabled=false}),false,player.index)
    if storage.razi_presence_session then
      storage.razi_presence_session[player.index]=nil
    end
  else
    M.write()
  end
end
function M.on_player_removed(event)
  local index=event.player_index
  for _,key in ipairs({"razi_presence_session",
    "razi_presence_translations"}) do
    if storage[key] then storage[key][index]=nil end
  end
  if storage.razi_presence_pending then
    for id,pending in pairs(storage.razi_presence_pending) do
      if pending.index==index then storage.razi_presence_pending[id]=nil end
    end
  end
end
return M
