-- Standalone regression test from the repository root:
--   lua tests/journal_volumes_test.lua
-- No Factorio engine required; all milestones use the actual authored catalog.
package.path="./?.lua;./?/init.lua;"..package.path
local volumes=require("scripts.journal.volumes")
local defs=require("scripts.journal.data")
local acts=require("scripts.journal.acts")
local timing=require("scripts.journal.chapter_timing")

assert(#volumes.volumes==5,"expected five volumes")
assert(#defs.chapters==42,"expected 42 chapters")
assert(#defs.quests==230,"milestone list changed unexpectedly")
local expected={7,10,14,6,5}
local chapter_count=0
for i,volume in ipairs(volumes.volumes) do
  assert(#volume.chapters==expected[i],"wrong number of chapters in "..volume.id)
  for _,chapter in ipairs(volume.chapters) do
    chapter_count=chapter_count+1
    assert(volumes.by_chapter[chapter.id]==chapter)
    assert(chapter.volume==volume.id)
    assert(chapter.theme and chapter.title and chapter.intro)
  end
end
assert(chapter_count==42)
local seen,by_chapter={},{}
for _,quest in ipairs(defs.quests) do
  assert(not seen[quest.id],"duplicate milestone ID: "..quest.id)
  seen[quest.id]=true
  assert(quest.legacy_chapter,"legacy identity lost: "..quest.id)
  assert(quest.chapter==volumes.assignment[quest.id],
    "moved to wrong chapter: "..quest.id)
  assert(volumes.by_chapter[quest.chapter],"unknown chapter: "..quest.id)
  by_chapter[quest.chapter]=(by_chapter[quest.chapter] or 0)+1
  for _,id in ipairs(quest.requires or {}) do
    -- Required IDs are references, not separately tracked campaign objects.
    -- They are checked after the complete catalog is built.
    assert(type(id)=="string")
  end
  assert(acts.for_quest(quest),"lost original act for "..quest.id)
end
for id in pairs(volumes.assignment) do
  assert(seen[id],"catalog references a nonexistent quest: "..id)
end
for _,chapter in ipairs(defs.chapters) do
  assert((by_chapter[chapter.id] or 0)>0,"empty chapter: "..chapter.id)
end
for _,quest in ipairs(defs.quests) do
  for _,id in ipairs(quest.requires or {}) do
    assert(seen[id],"broken prerequisite from "..quest.id.." to "..id)
  end
end

-- Old IDs in per-player chapter preferences resolve to the chosen milestone,
-- rather than resetting a player's selected chapter to the start.
assert(volumes.resolve_chapter("calidus",defs.by_id["nyxaris-gate"])
  =="nyxaris-discovery")
assert(volumes.resolve_chapter("sciences",defs.by_id["metallurgic"])
  =="vulcanus")
assert(volumes.resolve_chapter("fleet")=="orbital-construction")
assert(volumes.resolve_chapter("vibrant-discovery")=="vibrant-discovery")
assert(volumes.resolve_chapter("not-a-chapter")==nil)

-- Old act storage keys are immutable even though new chapter IDs differ.
assert(acts.for_quest(defs.by_id["first-signal"]).key=="machines")
assert(acts.for_quest(defs.by_id["interplanetary-trade"]).key=="network:trade")
assert(acts.for_quest(defs.by_id["nexus-arachnid-queen"]).key=="deepworks:trials")

-- Upgraded saves retain historic chapter/act/milestone records.
-- Newly created chapter records are historical (unknown timestamp), never
-- stamped with the time the mod was installed.
storage={razi_chapter_completion_times={
  [1]={chapters={calidus=900},phases={machines=600},
    milestones={["first-signal"]=500}}
}}
local force={index=1}
local sample={}
for _,quest in ipairs(defs.quests) do
  if quest.chapter=="first-signal" then sample[#sample+1]=quest end
end
assert(#sample==5)
timing.observe(force,sample,function() return true end,
  function() return true end,true,2000,
  function(quest) return acts.for_quest(quest).key end)
assert(timing.get(force,"chapters","calidus")==900)
assert(timing.get(force,"chapters","first-signal")==false)
assert(timing.get(force,"phases","machines")==600)
assert(timing.get(force,"milestones","first-signal")==500)
-- A fully known 3.x milestone history can establish an authentic completion
-- time for a newly split chapter. Use the final required milestone's time.
local old={}
for index,quest in ipairs(sample) do old[quest.id]=100*index end
storage.razi_chapter_completion_times[2]={
  chapters={calidus=650},phases={},milestones=old}
local force2={index=2}
timing.observe(force2,sample,function() return true end,
  function() return true end,true,2000,
  function(quest) return acts.for_quest(quest).key end)
assert(timing.get(force2,"chapters","first-signal")==500)
assert(timing.get(force2,"chapters","calidus")==650)
-- A save with partly unknown history which finishes a chapter only after
-- the update gets the genuine NEW completion time, not an invented old one.
local later={}
for _,quest in ipairs(sample) do
  if quest.id~="nauvis-radar" then later[quest.id]=false end
end
storage.razi_chapter_completion_times[3]={
  chapters={},phases={},milestones=later}
local force3={index=3}
timing.observe(force3,sample,function() return true end,
  function(quest) return quest.id~="nauvis-radar" end,true,2000,
  function(quest) return acts.for_quest(quest).key end)
assert(timing.get(force3,"chapters","first-signal")==nil)
timing.observe(force3,sample,function() return true end,
  function() return true end,false,2500,
  function(quest) return acts.for_quest(quest).key end)
assert(timing.get(force3,"chapters","first-signal")==2500)
print("journal_volumes_test: OK (5 volumes, 42 chapters, 230 objectives)")
