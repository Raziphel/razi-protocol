---@diagnostic disable: unnecessary-assert, param-type-mismatch, need-check-nil, inject-field
-- Writer mode (scripts/razi_writer.lua, scripts/razi_story.lua): one player
-- sees the story slots while the story is off for everyone else, the text of
-- the repository is never shown to the writer, and the commands work.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,message) if not ok then error(message,2) end end

local story=require("scripts.razi_story")
require("scripts.razi_journal") -- hands the Archive records to the story
local slots=require("scripts.razi_story_slots")
local W=require("tests.lua.journal_window")

-- The first key of a collected string chain, flattened.
local function keys_of(value) return W.flat(W.collect(value)) end

-- Slot text by state.
rawset(_G,"storage",{})
check(not story.enabled() and not story.visible(1) and not story.writer(1),
  "Nobody is a writer by default")
check(story.text(1,"quest-story","first-signal",{"donor.key"})==nil,
  "A slot has no text while the story is off and the mode is off")
check(story.key_tooltip(1,"quest-story","first-signal")==nil,"No key tooltip by default")
story.set_writer(1,"on",true)
check(story.writer(1) and story.visible(1) and not story.visible(2),
  "Writer mode is per player")
check(story.visible({index=1}) and not story.visible({index=2}),
  "A player object works like its index")
local text=story.text(1,"quest-story","first-signal",{"donor.key"})
local flat=keys_of(text)
check(text[1]=="?" and flat["razi-story-quest.first-signal"] and flat["razi-writer.slot"],
  "Writer mode shows the writer's text or a stub")
check(not flat["donor.key"],"Writer mode must never reach the repository text")
check(text[3][1]=="razi-writer.slot" and text[3][2]=="razi-story-quest.first-signal"
  and text[3][4]==tostring(slots.kinds["quest-story"].length),
  "The stub names the slot and its length")
-- A slot that names something in a list falls back to the game's own name.
local title=story.text(1,"quest-title","first-signal",{"plain.name"})
check(title[3][1]=="plain.name","A title slot falls back to the plain name in writer mode")
-- Parameters go to the writer's own text.
check(story.text(1,"welcome","journal",{"donor.key"},"3")[2][2]=="3",
  "Parameters must reach the writer's own text")
check(story.key_tooltip(1,"quest-story","first-signal")==nil,
  "Keys stay hidden until asked for")
story.set_writer(1,"keys",true)
check(story.key_tooltip(1,"quest-story","first-signal")[2]=="razi-story-quest.first-signal",
  "The key tooltip names the slot key")
check(#story.records(1)>0 and #story.records(2)==0 and #story.records()==0,
  "Only the writer sees the Archive records")
check(not story.writer_records(1),"All records are not open by default")
-- The story on for everyone: own text first, then the repository text.
story.configure(true)
text=story.text(2,"quest-story","first-signal",{"donor.key"})
check(text[1]=="?" and text[2][1]=="razi-story-quest.first-signal" and text[3][1]=="donor.key",
  "With the story on a slot shows the writer's text, then the repository text")
story.configure(false)
story.on_removed(1)
check(not story.writer(1),"Leaving a game removes the mode")

-- The window walk.
local ctx=W.setup()
local journal,force,player=ctx.journal,ctx.force,ctx.player
local ALLOWED_OWN="^razi%-story%-"
local function walk()
  local all,p=ctx.open_everything()
  return W.flat(all),p
end
local function authored_leaks(keys)
  local leaked={}
  for _,key in ipairs(W.authored(keys)) do
    -- The Archive tab and its headings are interface, not story text.
    if not key:match(ALLOWED_OWN) and not key:match("^journal%-ui%.") then
      leaked[#leaked+1]=key
    end
  end
  return leaked
end

-- Mode off: as before.
local keys=walk()
check(#authored_leaks(keys)==0 and not keys["razi-writer.slot"],
  "Story text shown with the mode off: "..W.brief(authored_leaks(keys)))

-- Mode on, story off: stubs and own keys, no repository text.
for _,tech in pairs(force.technologies) do tech.researched=false end
storage.razi_writer={[1]={on=true,keys=true,records=true}}
keys=walk()
local leaked=authored_leaks(keys)
check(#leaked==0,"Repository text shown to the writer: "..W.brief(leaked))
for _,wanted in ipairs({"razi-writer.slot","razi-story-quest.first-signal",
  "razi-story-quest-tip.first-signal","razi-story-chapter-summary.calidus",
  "razi-story-chapter-mood.calidus","razi-story-chapter-dispatch.calidus",
  "razi-story-chapter.calidus","razi-story-chapter-star.calidus",
  "razi-story-quest-title.first-signal","razi-story-record.reception",
  "razi-story-record-origin.reception","razi-story-project.platform",
  "razi-writer.key-tooltip","razi-story-quest-charter.vulcanus"}) do
  check(keys[wanted],"Writer mode did not show "..wanted)
end
check(keys["journal-ui.view-archive"],"The Archive tab must exist in writer mode")
local unlocked,total=journal.unlocked_records(force,nil,player)
check(unlocked==total and total>0,"All records must be open with the records option")
storage.razi_writer[1].records=false
unlocked,total=journal.unlocked_records(force,nil,player)
check(unlocked==0 and total>0,"Records follow the quests without the records option")
check(select(1,journal.unlocked_records(force)) == 0 and
  select(2,journal.unlocked_records(force))==0,
  "A player without the mode sees no records")

-- The Convergence victory panel in writer mode.
check(keys["razi-story-finale.won"] and keys["razi-story-finale.archive-message"],
  "The final panel slots must show in writer mode")

-- The commands.
local writer=require("scripts.razi_writer")
local said={}
player.admin=true
player.print=function(message) said[#said+1]=message end
storage.razi_writer=nil
local function run(parameter)
  said={}
  writer.command{player_index=1,parameter=parameter}
  return said[1] and said[1][1]
end
check(run("keys on")=="razi-writer.not-on","Commands need the mode on")
check(run("on")=="razi-writer.mode-on" and story.writer(1),"/razi-writer on")
check(run("keys on")=="razi-writer.keys-on" and story.writer_keys(1),"/razi-writer keys on")
check(run("keys off")=="razi-writer.keys-off" and not story.writer_keys(1),"/razi-writer keys off")
check(run("keys")=="razi-writer.usage","/razi-writer keys needs on or off")
check(run("records")=="razi-writer.records-on" and story.writer_records(1),"/razi-writer records")
check(journal.preferences(1).view=="archive","/razi-writer records opens the Archive")
check(run("records off")=="razi-writer.records-off" and not story.writer_records(1),
  "/razi-writer records off")
check(run("quest nonsense")=="razi-writer.unknown-id","Unknown quest id")
check(run("quest first-signal")==nil and journal.preferences(1).selected=="first-signal"
  and journal.preferences(1).view=="quests","/razi-writer quest opens the quest")
check(run("chapter nonsense")=="razi-writer.unknown-id","Unknown chapter id")
check(run("chapter solaris")==nil and journal.preferences(1).chapter=="solaris"
  and journal.preferences(1).chapter_cover==true,"/razi-writer chapter opens the cover")
check(run("what")=="razi-writer.usage","Unknown command word")
check(run("off")=="razi-writer.mode-off" and not story.writer(1),"/razi-writer off")
player.admin=false
check(run("on")=="razi-writer.admin-only" and not story.writer(1),
  "Only an admin can turn the mode on")
player.admin=true

-- Welcome in writer mode.
local welcome=require("scripts.razi_welcome")
storage.razi_writer={[1]={on=true}}
said={}
welcome.command{player_index=1}
check(#said==8 and said[1][1]=="?" and said[1][2][1]=="razi-story-welcome.header"
  and said[1][3][1]=="razi-writer.slot","The welcome must be slots in writer mode")
check(not keys_of(said[6])["razi-welcome.journal"]
  and said[6][2][2]~=nil,"The writer's journal line gets the unread count")
storage.razi_writer=nil
said={}
welcome.command{player_index=1}
check(#said==4 and said[1][1]=="razi-welcome-plain.header",
  "Without the mode the plain welcome comes back")

print("Razi writer mode: slots, stubs, key tooltips and commands")
