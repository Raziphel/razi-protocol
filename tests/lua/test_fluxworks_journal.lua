-- Run from repository root:
--   lua tests/lua/test_fluxworks_journal.lua
-- A minimal test of optional chapter registration, not the Factorio GUI.
local function find_chapter(defs,id)
  for _,chapter in ipairs(defs.chapters) do
    if chapter.id==id then return chapter end
  end
end

_G.script={active_mods={}}
local without=dofile("scripts/razi_journal_data.lua")
assert(not find_chapter(without,"fluxworks"),"FluxWorks chapter shown without mod")
assert(not without.by_id["flux-calidus"],"FluxWorks quest shown without mod")

script.active_mods.FluxWorks="0.2.14"
local with=dofile("scripts/razi_journal_data.lua")
assert(find_chapter(with,"fluxworks"),"FluxWorks chapter not registered")
local systems={"calidus","solaris","nyxaris","vibrant",
  "vespera","beetlejuice","umbra"}
local registered=0
for _,system in ipairs(systems) do
  local quest=assert(with.by_id["flux-"..system],
    "Missing FluxWorks system quest: "..system)
  assert(quest.chapter=="fluxworks")
  assert(quest.tech=="razi-fw-"..system.."-industry")
  assert(quest.site and #quest.requires>0)
  registered=registered+1
end
assert(registered==7)
assert(#with.quests==#without.quests+7)
assert(#with.chapters==#without.chapters+1)
assert(with.by_id["first-signal"],"Existing quest ID unexpectedly changed")
print("Razi FluxWorks journal: conditional chapter and seven objectives OK")
