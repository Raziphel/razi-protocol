-- /razi-writer: writer mode for the storyline (see scripts/razi_story.lua).
-- Admin only. The mode is per player and needs no restart.
--
--   /razi-writer on|off          the mode
--   /razi-writer keys on|off     the slot key in the tooltip of each text
--   /razi-writer quest <id>      open the journal on a quest
--   /razi-writer chapter <id>    open the journal on a chapter cover
--   /razi-writer records [off]   open every Archive record, studied or not
local story=require("scripts.razi_story")
local journal=require("scripts.razi_journal")

local M={}

local function say(player,key,...)
  player.print({"razi-writer."..key,...})
end

-- "on", "off" or nil for anything else.
local function switch(word)
  if word=="on" then return true end
  if word=="off" then return false end
  return nil
end

function M.command(event)
  local player=event and event.player_index and game.get_player(event.player_index)
  if not (player and player.valid) then return end
  if not player.admin then return say(player,"admin-only") end
  local first,rest=(event.parameter or ""):lower():match("^%s*(%S*)%s*(.-)%s*$")
  local index=player.index

  local value=switch(first)
  if value~=nil then
    story.set_writer(index,"on",value)
    say(player,value and "mode-on" or "mode-off")
    journal.draw(player)
    return
  end

  if not story.writer(player) then return say(player,"not-on") end

  if first=="keys" then
    value=switch(rest)
    if value==nil then return say(player,"usage") end
    story.set_writer(index,"keys",value)
    say(player,value and "keys-on" or "keys-off")
    journal.draw(player)
  elseif first=="records" then
    value=switch(rest)
    if rest~="" and value==nil then return say(player,"usage") end
    value=value~=false
    story.set_writer(index,"records",value)
    say(player,value and "records-on" or "records-off")
    if value then journal.open_archive(player) else journal.draw(player) end
  elseif first=="quest" then
    if rest=="" or not journal.quest_by_id(rest) then
      return say(player,"unknown-id",rest)
    end
    if not journal.open_quest(player,rest) then
      return say(player,"quest-hidden",rest)
    end
  elseif first=="chapter" then
    if not journal.open_chapter(player,rest) then
      return say(player,"unknown-id",rest)
    end
  else
    say(player,"usage")
  end
end

return M
