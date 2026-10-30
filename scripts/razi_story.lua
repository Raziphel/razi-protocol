-- Single switch for the Expedition Journal storyline, and the writer mode.
--
-- The journal, its quests, projects and the Convergence finale are game
-- mechanics. The story layer is prose on top of them: the Archive tab,
-- chapter covers, story paragraphs, record notices, the welcome voice and
-- the Convergence epilogue. While the switch is off none of that is shown
-- to a player, and the mechanics behave exactly as before.
--
-- Save data is untouched either way. Quest, chapter, act and record IDs stay
-- as they are, and the `story_*` player fields and the `razi_story_*`
-- storage tables are kept, so turning the story on later needs no migration.
--
-- Turn the story on for everyone by changing ENABLED below.
--
-- Writer mode shows the story layer to one player. An admin switches it on
-- with /razi-writer (scripts/razi_writer.lua). In it every text slot shows
-- the text from locale/en/story-*.cfg, or a stub with the slot's key where
-- there is none; the text that came with the repository is never shown.
-- Mode state is `storage.razi_writer[player_index]` = {on, keys, records}.
--
-- Factorio forbids require() inside events, so the story modules are loaded
-- once at load time, whether or not the story is on: scripts/razi_journal.lua
-- loads them and hands them over with attach(). They need the quest data,
-- which needs this module, so this module cannot load them itself.
local ENABLED=false

local M={}
local slots=require("scripts.razi_story_slots")
local enabled_flag=false
local record_list={}
local dispatch_impl

local EMPTY={}

-- The story is on for everyone.
function M.enabled() return enabled_flag end

local function state(player)
  local index=type(player)=="table" and player.index or player
  local all=rawget(_G,"storage") and storage.razi_writer
  return index and all and all[index] or nil
end

-- Writer mode is on for this player (a player object or a player index).
function M.writer(player)
  local mode=state(player)
  return mode~=nil and mode.on==true
end

-- Whether this player sees the story layer. Without a player: the story is on.
function M.visible(player)
  return enabled_flag or M.writer(player)
end

-- Writer mode shows the slot key in the tooltip of the text.
function M.writer_keys(player)
  local mode=state(player)
  return mode~=nil and mode.on==true and mode.keys==true
end

-- Writer mode opens every Archive record, studied or not.
function M.writer_records(player)
  local mode=state(player)
  return mode~=nil and mode.on==true and mode.records==true
end

-- Changes one field of the mode: "on", "keys" or "records".
function M.set_writer(player_index,field,value)
  storage.razi_writer=storage.razi_writer or {}
  local mode=storage.razi_writer[player_index]
  if not mode then
    mode={}
    storage.razi_writer[player_index]=mode
  end
  mode[field]=value==true
end

function M.on_removed(player_index)
  if rawget(_G,"storage") and storage.razi_writer then
    storage.razi_writer[player_index]=nil
  end
end

-- The text of one slot, as a localised string, or nil where it is not shown.
-- `kind` and `id` name the slot (scripts/razi_story_slots.lua), `donor_key`
-- is the localised string the story shows when the repository text is on.
-- Extra arguments go to the writer's own text as __1__, __2__.
--   writer mode: the writer's text, else a stub that names the slot;
--   story on:    the writer's text, else the repository text;
--   otherwise:   nil.
function M.text(player,kind,id,donor_key,...)
  local slot=slots.kinds[kind]
  if not slot then return nil end
  local own={slots.key(kind,id),...}
  if M.writer(player) then
    -- A slot that names something in a list falls back to the game's own name.
    if slot.stub==false then return {"?",own,donor_key} end
    return {"?",own,{"razi-writer.slot",own[1],slot.where,tostring(slot.length)}}
  elseif enabled_flag then
    return {"?",own,donor_key}
  end
  return nil
end

-- The tooltip that shows the slot key, or nil when the writer did not ask.
function M.key_tooltip(player,kind,id)
  if not M.writer_keys(player) then return nil end
  return {"razi-writer.key-tooltip",slots.key(kind,id)}
end

-- Archive entries (legacy transmissions plus corporate and field records)
-- for this player: none while the story layer is hidden from them.
function M.records(player)
  if M.visible(player) then return record_list end
  return EMPTY
end

-- Record notices in chat go to the whole force, so writer mode does not turn
-- them on. Every call is a no-op while the story is off.
M.dispatch={
  on_research=function(event)
    if enabled_flag and dispatch_impl then dispatch_impl.on_research(event) end
  end,
  flush=function()
    if enabled_flag and dispatch_impl then dispatch_impl.flush() end
  end,
  forces_merged=function(event)
    if enabled_flag and dispatch_impl then dispatch_impl.forces_merged(event) end
  end,
  shipment=function(force,id)
    if enabled_flag and dispatch_impl then dispatch_impl.shipment(force,id) end
  end
}

-- Hands over the Archive records and the record notices.
function M.attach(records,dispatch)
  record_list=records
  dispatch_impl=dispatch
end

-- Applies the switch. Runs once at load; tests call it to try both states.
function M.configure(value)
  enabled_flag=value==true
end

M.configure(ENABLED)
return M
