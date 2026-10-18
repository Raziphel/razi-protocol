-- One compact, localized welcome per player. Optional new-map console
-- cleanup is a one-shot: Factorio does NOT let us selectively delete
-- another mod's messages. Never clear console on an existing save.
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
function M.deliver(player,early)
  if not (player and player.valid) then return end
  local s=state()
  if s.seen[player.index] then return end
  s.seen[player.index]=true
  s.pending[player.index]=nil
  -- This API clears all chat lines, not only third-party startup banners.
  -- Never use it after the first ten seconds of a newly created map.
  if early and game.tick<=NEW_MAP_LIMIT
    and option(player,"razi-clean-startup-chat")
    and player.clear_console then
    player.clear_console()
  end
  if not option(player,"razi-show-welcome") then return end
  player.print({"razi-welcome.header"})
  player.print({"razi-welcome.intro"})
  player.print({"razi-welcome.journal"})
  player.print({"razi-welcome.links"})
  if player.admin then player.print({"razi-welcome.admin"}) end
end
local function greet(player)
  if not (player and player.valid) then return end
  local s=state()
  if s.seen[player.index] or s.pending[player.index] then return end
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
  player.print({"razi-welcome.header"})
  player.print({"razi-welcome.intro"})
  player.print({"razi-welcome.journal"})
  player.print({"razi-welcome.links"})
  if player.admin then player.print({"razi-welcome.admin"}) end
end
return M
