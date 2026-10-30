---@diagnostic disable: unnecessary-assert, param-type-mismatch, need-check-nil
-- The storyline switch (scripts/razi_story.lua): with the story off nothing
-- story-related is created, called or shown, and the mechanics still work.
-- With the story on the original behaviour is unchanged.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,message) if not ok then error(message,2) end end

local story=require("scripts.razi_story")
check(story.enabled()==false,"The story must ship switched off")
check(#story.records()==0,"No archive records while the story is off")
-- Notices are no-ops even without any game state.
story.dispatch.on_research{research={name="automation"}}
story.dispatch.flush()
story.dispatch.forces_merged{source_index=1,destination_index=2}
story.dispatch.shipment({index=1},"victory")
check(rawget(_G,"storage")==nil,"Record notices touched save data while off")
check(story.text(nil,"quest-story","first-signal",{"x"})==nil,
  "A story slot must have no text while the story is off")

-- Minimal GUI mock and the walk through every window are shared.
local W=require("tests.lua.journal_window")
local ctx=W.setup()
-- The journal loads the records and the notices either way (Factorio forbids
-- require() in events); the switch and writer mode decide what a player sees.
check(package.loaded["scripts.razi_story_dispatch"]~=nil
  and package.loaded["scripts.razi_journal_records"]~=nil,
  "Story modules must be loaded even while the story is off")
local projects,journal,force=ctx.projects,ctx.journal,ctx.force
local function open_everything()
  local all,p=ctx.open_everything()
  return W.flat(all),p
end

-- Story off.
local keys,p=open_everything()
check(p.project~="array","Archive Array must not be reachable while off")
check(projects.valid("array")==false and projects.valid("convergence"),
  "Archive Array project exists only with the story")
local leaked=W.authored(keys)
check(#leaked==0,"Story text shown while off: "..W.brief(leaked))
check(keys["technology-name.automation"] and keys["journal-chapter.calidus"],
  "Quest names (the technology's own) and chapter names must stay while off")
check(not keys["journal-title.first-signal"],
  "Authored quest titles must not be shown while off")
check(not keys["journal-tip.first-signal"],"Field notes must not be shown while off")
-- The field assignment keeps its navigation; only the charter text is story.
check(keys["journal-ui.field-assignment-followups"]
  or keys["journal-ui.field-assignment-project"],
  "Field assignment links must stay while the story is off")
check(keys["journal-ui.field-assignment-advisory"]
  and not keys["razi-planet-charter.vulcanus"],
  "Field assignment shows no charter text while off")
-- A boss is named by Nexus Bosses, with the plain name as fallback.
local boss=ctx.defs.quest_title(ctx.defs.by_id["nexus-watcher"])
check(boss[1]=="?" and boss[2][1]=="nexus-bosses.boss-watcher"
  and boss[3][1]=="journal-plain-title.nexus-watcher",
  "Boss titles must start with the nexus-bosses name")
check(keys["razi-story-off.convergence-won"]
  and keys["razi-story-off.convergence-archive-message"]
  and keys["razi-story-off.transmission-stage"],
  "Plain Convergence texts must replace the story ones while off")
-- A saved Archive view falls back to the quest list.
p.view="archive"
check(journal.preferences(1).view=="quests","Saved Archive view must fall back")
journal.preferences(1).story_unread["corp-welcome"]=true
journal.gui_click{player_index=1,element={valid=true,
  tags={razi_journal_action="view",id="archive"}}}
check(journal.preferences(1).view=="quests","Archive tab must not open while off")
check(journal.preferences(1).story_unread["corp-welcome"],
  "Unread markers are save data and must be kept")
local unlocked,total=journal.unlocked_records(force)
check(unlocked==0 and total==0,"No archive records while off")

-- Story on: the original windows come back.
story.configure(true)
check(story.enabled() and #story.records()>0,"Story did not switch on")
check(projects.valid("array"),"Archive Array project missing with the story")
keys=open_everything()
check(keys["journal-story.first-signal"] and keys["journal-mood.calidus"],
  "Story paragraphs must be shown with the story on")
check(keys["journal-chapter-summary.calidus"] and keys["journal-ui.project-context-platform"],
  "Chapter cover and project context must be shown with the story on")
check(keys["journal-ui.view-archive"],"Archive tab must exist with the story on")
check(keys["razi-planet-charter.vulcanus"]
  and keys["journal-ui.field-assignment-followups"],
  "Planet charters must be shown with the story on")
check(keys["journal-title.first-signal"] and keys["journal-tip.first-signal"],
  "Authored titles and field notes must be shown with the story on")
check(keys["razi-ops.convergence-blackbox-1"]
  and keys["razi-ops.convergence-transmission-dyson"],
  "Convergence story text must be shown with the story on")
story.configure(false)
check(not story.enabled() and #story.records()==0,"Story did not switch off")
-- Every plain-text key used by the scripts is defined in the plain locale.
local function read(path)
  local file=assert(io.open(path,"r"))
  local text=file:read("*a")
  file:close()
  return text
end
local locale=read("locale/en/razi_story_off.cfg")
local function defined(section,key)
  local start=locale:find("["..section.."]",1,true)
  if not start then return false end
  local nextsection=locale:find("\n%[",start+1) or #locale
  return locale:sub(start,nextsection):find("\n"..key.."=",1,true)~=nil
end
for _,path in ipairs({"scripts/razi_welcome.lua","scripts/razi_convergence.lua"}) do
  local source=read(path)
  for section,key in source:gmatch('"(razi%-welcome%-plain)%.([%w%-]+)"') do
    check(defined(section,key),path..": missing plain key "..section.."."..key)
  end
  for section,key in source:gmatch('"(razi%-story%-off)%.([%w%-]+)"') do
    check(defined(section,key),path..": missing plain key "..section.."."..key)
  end
end
for _,key in ipairs({"convergence-victory-title","convergence-victory-message",
  "convergence-victory-stellar","convergence-victory-industry",
  "convergence-victory-deep","convergence-victory-resonance",
  "convergence-victory-ignition","convergence-victory-final",
  "spoilers-on","spoilers-off"}) do
  check(defined(key:match("^spoilers") and "razi-welcome-plain" or "razi-story-off",key),
    "Missing plain locale key "..key)
end
-- Shipping with the story on loads razi_story_dispatch from inside the quest
-- data module's require chain; that must not recurse.
do
  local names={"scripts.razi_story","scripts.razi_story_dispatch",
    "scripts.razi_journal_data","scripts.razi_journal_records"}
  local saved={}
  for _,name in ipairs(names) do saved[name]=package.loaded[name];package.loaded[name]=nil end
  local source=assert(io.open("scripts/razi_story.lua","r")):read("*a")
  local patched,count=source:gsub("local ENABLED=false","local ENABLED=true")
  check(count==1,"Story switch declaration not found")
  package.preload["scripts.razi_story"]=assert(load(patched,"@scripts/razi_story.lua"))
  local ok,loaded=pcall(require,"scripts.razi_journal_data")
  package.preload["scripts.razi_story"]=nil
  ---@type table
  local fresh=package.loaded["scripts.razi_story"]
  ---@type table
  local title=ok and loaded.quest_title(loaded.by_id["first-signal"]) or {}
  for _,name in ipairs(names) do package.loaded[name]=saved[name] end
  check(ok,"Loading the quest data with the story on failed: "..tostring(loaded))
  check(fresh.enabled() and title[1]=="?","Quest titles must fall back with the story on")
end
print("Razi story switch: off hides every story surface, on restores them")
