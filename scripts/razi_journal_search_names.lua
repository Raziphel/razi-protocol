-- Journal search by the names a player sees. The game translates the names
-- (only for a connected player, in that player's locale), so the result is
-- cached per player and the search falls back to ids until it arrives.
local story=require("scripts.razi_story")
local M={}

-- Lower case that also covers Cyrillic and Latin-1 letters (string.lower
-- is ASCII only); Ё folds into е, "-" and "_" into spaces.
function M.fold(text)
  text=text:gsub("\208\129","\208\181"):gsub("\209\145","\208\181")
  text=text:gsub("\208([\144-\175])",function(byte)
    local code=byte:byte()+32
    if code<192 then return "\208"..string.char(code) end
    return "\209"..string.char(code-64)
  end)
  text=text:gsub("\195([\128-\158])",function(byte)
    if byte=="\151" then return nil end
    return "\195"..string.char(byte:byte()+32)
  end)
  return (text:lower():gsub("[-_]"," "))
end

function M.corpus(quest)
  return M.fold(quest.id.." "..quest.chapter.." "..(quest.tech or "")
    .." "..(quest.world or "").." "..(quest.site or "")
    .." "..(quest.recipe or "").." "..(quest.machine or ""))
end

local function entry_of(player_index)
  local all=storage.razi_journal_search_names
  return all and all[player_index]
end

function M.names(player_index)
  local entry=entry_of(player_index)
  return entry and entry.names
end

local function lookup(kind,name)
  local list=prototypes and prototypes[kind]
  local proto=list and name and list[name]
  return proto and proto.localised_name
end

-- One string per quest; a missing key gives an empty part, not "Unknown key".
local function quest_string(quest,player,title_fn)
  local text={""}
  local function add(part)
    if not part then return end
    if #text>1 then text[#text+1]=" " end
    text[#text+1]={"?",part,""}
  end
  add(title_fn(quest,player))
  add({"journal-chapter."..quest.chapter})
  add(lookup("technology",quest.tech))
  add(quest.world and {"space-location-name."..quest.world})
  add(lookup("recipe",quest.recipe))
  add(lookup("entity",quest.machine) or lookup("item",quest.machine))
  return text
end

function M.request(player,quests,title_fn)
  if not (player and player.valid and player.connected) then return end
  local stamp=player.locale.."|"..(story.writer(player) and "writer" or "plain")
  storage.razi_journal_search_names=storage.razi_journal_search_names or {}
  local all=storage.razi_journal_search_names
  local entry=all[player.index]
  if entry and entry.stamp==stamp then return end
  entry={stamp=stamp,names={},pending={}}
  all[player.index]=entry
  local strings,ids={},{}
  for _,quest in ipairs(quests) do
    strings[#strings+1]=quest_string(quest,player,title_fn)
    ids[#ids+1]=quest.id
  end
  local requests=player.request_translations(strings)
  for index,request in ipairs(requests or {}) do
    entry.pending[request]=ids[index]
  end
end

-- Returns true when the last answer for the player has arrived.
function M.on_string_translated(event)
  local entry=entry_of(event.player_index)
  local quest_id=entry and entry.pending[event.id]
  if not quest_id then return end
  entry.names[quest_id]=M.fold(event.result or "")
  entry.pending[event.id]=nil
  return next(entry.pending)==nil
end

function M.reset()
  storage.razi_journal_search_names=nil
end

return M
