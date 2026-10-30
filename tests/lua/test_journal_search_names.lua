---@diagnostic disable: unnecessary-assert, param-type-mismatch, need-check-nil, inject-field, missing-fields, undefined-field
-- Journal search by translated names: the case folding, the per-player
-- request cache, the answers of on_string_translated and the match itself.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,message) if not ok then error(message,2) end end

local W=require("tests.lua.journal_window")
local ctx=W.setup()
local journal,defs,player=ctx.journal,ctx.defs,ctx.player
local names=require("scripts.razi_journal_search_names")

-- Cyrillic and Latin-1 capitals fold like ASCII ones; Ё becomes е.
check(names.fold("Наувис ЁЖ")=="наувис еж","Cyrillic capitals should fold")
check(names.fold("ÉCLAIR")=="éclair","Latin-1 capitals should fold")
check(names.fold("×Ö")=="×ö","The multiplication sign must stay as it is")
check(names.fold("oil-processing_x")=="oil processing x","Dashes become spaces")
check(names.fold("ёж")==names.fold("ЕЖ"),"Ё, ё and е should compare equal")

-- A connected player gets one request per quest, once per locale.
local requested=0
local sent
local next_id=100
player.connected=true
player.locale="ru"
function player.request_translations(list)
  requested=requested+1
  sent=list
  local ids={}
  for index=1,#list do next_id=next_id+1;ids[index]=next_id end
  return ids
end
names.request(player,defs.quests,defs.quest_title)
local entry=storage.razi_journal_search_names[1]
check(requested==1 and #sent==#defs.quests,"Every quest should be requested once")
local count=0
for _ in pairs(entry.pending) do count=count+1 end
check(count==#defs.quests,"Every request should wait for its answer")
check(sent[1][1]=="" and sent[1][2][1]=="?","Parts should be wrapped so a missing key gives nothing")
names.request(player,defs.quests,defs.quest_title)
check(requested==1,"The same locale must not be requested again")
player.locale="en"
names.request(player,defs.quests,defs.quest_title)
check(requested==2,"Another locale should be requested again")
local offline_requests=requested
player.connected=false
player.locale="de"
names.request(player,defs.quests,defs.quest_title)
check(requested==offline_requests,"A disconnected player gets no request")
player.connected=true

-- Answers fill the names; the last one reports that the player is done.
local pending={}
for id,quest_id in pairs(storage.razi_journal_search_names[1].pending) do
  pending[#pending+1]={id=id,quest=quest_id}
end
check(names.on_string_translated({player_index=1,id=1,result="x"})==nil,
  "An unknown request id should be ignored")
check(names.on_string_translated({player_index=2,id=pending[1].id,result="x"})==nil,
  "Another player's answer should be ignored")
local last
for index,item in ipairs(pending) do
  last=names.on_string_translated({player_index=1,id=item.id,
    result=item.quest=="first-signal" and "Автоматизация" or "",
    translated=index%2==0})
  check(index==#pending or not last,"Only the last answer should finish the request")
end
check(last==true,"The last answer should report that the names are ready")
check(names.names(1)["first-signal"]=="автоматизация","The answer should be stored folded")

-- The match: ids as before, plus the translated names.
local quest=defs.by_id["first-signal"]
check(journal.matches_query(quest,"automation"),"Search by id must keep working")
check(not journal.matches_query(quest,"автоматизация"),"A name is unknown before it is translated")
check(journal.matches_query(quest,"автоматизация",names.names(1)),"Search by translated name")
check(journal.matches_query(quest,"АВТОМАТИЗАЦИЯ",{["first-signal"]="автоматизация"}),"Search ignores case")
check(not journal.matches_query(quest,"вулкан",names.names(1)),"Search excludes other names")

names.reset()
check(names.names(1)==nil and storage.razi_journal_search_names==nil,"Reset should clear the cache")
print("journal search names ok")
