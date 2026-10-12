-- Read-only quest progression and missing-content safety regression.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,message) if not ok then error(message,2) end end
local defs=require("scripts.razi_journal_data")
local M=require("scripts.razi_journal")
check(#defs.chapters==10,"The seven-star quest chapters were lost")
check(#defs.quests==54,"Razi Expedition Journal should include 54 milestones")
local seen={}
for _,chapter in ipairs(defs.chapters) do
  seen[chapter.id]=true
end
local quest_ids={}
for _,q in ipairs(defs.quests) do
  check(not quest_ids[q.id],"Duplicate quest ID "..q.id)
  check(seen[q.chapter],"Unknown quest chapter "..q.chapter)
  quest_ids[q.id]=true
  check(type(q.tech)=="string" and q.tech~="","Invalid research goal")
end
for _,q in ipairs(defs.quests) do
  for _,req in ipairs(q.requires) do
    check(quest_ids[req],"Unregistered prerequisite "..req)
  end
end
local force={technologies={}}
for _,q in ipairs(defs.quests) do
  force.technologies[q.tech]={name=q.tech,researched=false,
    prototype={hidden=false},localised_name=q.tech}
end
local start=M.summary(force)
local complete,total,active=M.summary(force)
check(start==0 and total==54 and active>=1,
  "At least both initial factory/opening branches must be listed")
local a=defs.by_id["solaris-gate"]
local b=defs.by_id["nyxaris-gate"]
force.technologies["space-science-pack"].researched=true
check(M.state(force,a)=="active" and M.state(force,b)=="active",
  "Parallel opening worlds must never block each other")
force.technologies["solaris-discovery"].researched=true
check(M.state(force,a)=="complete" and M.state(force,b)=="active",
  "Research status should be shared by force and independent by branch")
-- Missing/hidden source technologies skip safely instead of creating a
-- phantom chain prerequisite for unrelated quests.
force.technologies["planet-discovery-arig"]=nil
check(M.state(force,defs.by_id.arig)=="unavailable",
  "Missing source mod goals should not display an impossible quest")
force.technologies["planet-discovery-tellus"].researched=false
force.technologies["planet-discovery-hyarion"].researched=true
check(M.state(force,defs.by_id.tellus)=="active",
  "Missing optional prerequisite must be safely ignored")
local saved=force.technologies["razi-stable-intergalactic-singularity"]
saved.researched=true
check(M.state(force,defs.by_id["stable-singularity"])=="complete",
  "Already researched milestones must backfill on old saves")
local next=M.next_quest(force)
check(next and M.state(force,next)=="active",
  "Journal should suggest a real active milestone")
rawset(_G,"storage",{})
local p=M.preferences(42)
p.selected="stable-singularity"
check(M.preferences(42).selected=="stable-singularity",
  "Player preferences are not persistent")
M.on_removed(42)
check(not storage.razi_expedition_journal[42],
  "Deleted player preferences were not cleaned")
print("Expedition Journal: chapters, branches, skipped content and save backfill passed")
