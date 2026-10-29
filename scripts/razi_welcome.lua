-- One compact, localized welcome per player. Optional new-map console
-- cleanup is a one-shot: Factorio does NOT let us selectively delete
-- another mod's messages. Never clear console on an existing save.
local story=require("scripts.razi_story")
local M={}
local WAIT=180
local NEW_MAP_LIMIT=600
local function state()
  storage.razi_welcome=storage.razi_welcome or {seen={},pending={}}
  local s=storage.razi_welcome
  s.seen=s.seen or {}
  s.pending=s.pending or {}
  return s
end
local function option(player,name)
  local per=settings and settings.get_player_settings
    and settings.get_player_settings(player)
  local value=per and per[name]
  return value and value.value~=false or not value
end
-- The briefing never previews a future system. Every status line is
-- derived from research that the player's force has already completed.
local function researched(player,name)
  local force=player and player.force
  local tech=force and force.technologies and force.technologies[name]
  return tech and tech.researched==true or false
end
function M.signal(player)
  if researched(player,"razi-convergence-commission") then
    return "status-commission"
  elseif researched(player,"interplanetary-trade-logistics") then
    return "status-network"
  elseif researched(player,"space-platform") then
    return "status-flight"
  elseif researched(player,"automation") then
    return "status-local"
  end
  return "status-initial"
end
-- Render the actual current map spoiler option. Never claim the
-- research tree is hidden after the player turns it off.
function M.spoiler_status()
  local setting=settings and settings.global
    and settings.global["razi-hide-spoilers"]
  return setting and setting.value==false and "spoilers-off"
    or "spoilers-on"
end
-- Immediate assignment follows existing force research. None of the
-- priority lines name an undiscovered world or expose finale answers.
function M.priority(player)
  return M.signal(player):gsub("^status%-","priority-")
end
local function unread_count(index)
  local state=storage.razi_expedition_journal
    and storage.razi_expedition_journal[index]
  local count=0
  for _ in pairs(state and state.story_unread or {}) do
    count=count+1
  end
  return count
end
-- Text version of the briefing. `seen` stores the version a player has read,
-- so a player who only saw the plain text still gets the story briefing
-- once it is switched on. Older saves hold `true`, which was the story text.
local PLAIN_VERSION=1
local STORY_VERSION=2
local function version()
  return story.enabled() and STORY_VERSION or PLAIN_VERSION
end
local function has_seen(s,index)
  local seen=s.seen[index]
  if seen==true then seen=STORY_VERSION end
  return type(seen)=="number" and seen>=version()
end
function M.help()
  return story.enabled() and {"razi-welcome.command-help"}
    or {"razi-welcome-plain.command-help"}
end
local function plain_briefing(player)
  player.print({"razi-welcome-plain.header"})
  player.print({"razi-welcome-plain.journal",
    {"razi-welcome-plain."..M.spoiler_status()}})
  player.print({"razi-welcome-plain.links"})
  if player.admin then player.print({"razi-welcome-plain.admin"}) end
end
local function briefing(player)
  if not story.enabled() then return plain_briefing(player) end
  player.print({"razi-welcome.header"})
  player.print({"razi-welcome.identification"})
  player.print({"razi-welcome."..M.signal(player)})
  player.print({"razi-welcome.intro"})
  player.print({"razi-welcome."..M.priority(player)})
  player.print({"razi-welcome.journal",
    tostring(unread_count(player.index)),
    {"razi-welcome."..M.spoiler_status()}})
  player.print({"razi-welcome.links"})
  if player.admin then player.print({"razi-welcome.admin"}) end
end
function M.deliver(player,early)
  if not (player and player.valid) then return end
  local s=state()
  if has_seen(s,player.index) then return end
  s.seen[player.index]=version()
  s.pending[player.index]=nil
  -- This API clears all chat lines, not only third-party startup banners.
  -- Never use it after the first ten seconds of a newly created map.
  if early and game.tick<=NEW_MAP_LIMIT
    and option(player,"razi-clean-startup-chat")
    and player.clear_console then
    player.clear_console()
  end
  if not option(player,"razi-show-welcome") then return end
  briefing(player)
end
local function greet(player)
  if not (player and player.valid) then return end
  local s=state()
  if has_seen(s,player.index) or s.pending[player.index] then return end
  if game.tick<=NEW_MAP_LIMIT then
    s.pending[player.index]={tick=game.tick+WAIT,early=true}
  else
    M.deliver(player,false)
  end
end
M.on_player_created=greet
M.on_player_joined=greet
function M.flush()
  if not storage.razi_welcome then return end
  local s=state()
  for index,job in pairs(s.pending) do
    if game.tick>=job.tick then
      local player=game.get_player(index)
      if player and player.valid and player.connected~=false then
        M.deliver(player,job.early)
      elseif not player or not player.valid then
        s.pending[index]=nil
      end
    end
  end
end
function M.on_player_removed(index)
  if not storage.razi_welcome then return end
  local s=state()
  s.seen[index]=nil
  s.pending[index]=nil
end
function M.command(event)
  if not (event and event.player_index) then return end
  local player=game.get_player(event.player_index)
  if not (player and player.valid) then return end
  -- Explicit opt-in for existing saves: the automatic startup-only cleanup
  -- can never be replayed after the first ten seconds. Players may clear
  -- their own current chat by typing /razi-welcome clear.
  local parameter=(event.parameter or ""):match("^%s*(.-)%s*$"):lower()
  if parameter=="clear" and player.clear_console then
    player.clear_console()
  end
  briefing(player)
end
return M
