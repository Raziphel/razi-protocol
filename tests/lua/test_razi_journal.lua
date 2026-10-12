-- Read-only quest progression and missing-content safety regression.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,message) if not ok then error(message,2) end end
local defs=require("scripts.razi_journal_data")
local M=require("scripts.razi_journal")
check(#defs.chapters==17,"Seventeen Razi expedition chapters expected")
check(#defs.quests==186,"Razi Expedition Journal should include 186 milestones")
local seen={}
for _,chapter in ipairs(defs.chapters) do
  seen[chapter.id]=true
end
local quest_ids={}
for _,q in ipairs(defs.quests) do
  check(not quest_ids[q.id],"Duplicate quest ID "..q.id)
  check(seen[q.chapter],"Unknown quest chapter "..q.chapter)
  quest_ids[q.id]=true
  check((type(q.tech)=="string" and q.tech~="")
    or (type(q.world)=="string" and q.world~=""),
    "Invalid source research or world-discovery goal")
end
for _,q in ipairs(defs.quests) do
  for _,req in ipairs(q.requires) do
    check(quest_ids[req],"Unregistered prerequisite "..req)
  end
end
local force={technologies={}}
for _,q in ipairs(defs.quests) do
  if q.tech then
    force.technologies[q.tech]={name=q.tech,researched=false,
      prototype={hidden=false},localised_name=q.tech}
  end
end
local start=M.summary(force)
local complete,total,active=M.summary(force)
check(start==0 and total==186-15-9 and active>=1,
  "At least both initial factory/opening branches must be listed")
local a=defs.by_id["solaris-gate"]
local b=defs.by_id["nyxaris-gate"]
force.technologies["space-science-pack"].researched=true
check(M.state(force,a)=="active" and M.state(force,b)=="active",
  "Parallel opening worlds must never block each other")
force.technologies["solaris-discovery"].researched=true
check(M.state(force,a)=="complete" and M.state(force,b)=="active",
  "Research status should be shared by force and independent by branch")
-- Side-world quests find the actual unlock-space-location research effect.
force.technologies["discovery-native-igrys"]={
  name="discovery-native-igrys",researched=false,
  prototype={hidden=false,effects={{
    type="unlock-space-location",space_location="igrys"
  }}}
}
local context=M.context(force)
check(M.available(force,defs.by_id["igrys"],context),
  "Side-world discovery should be dynamically indexed")
check(M.state(force,defs.by_id["igrys"],context)=="active",
  "Side-world research must respect the unlocked opening star")
force.technologies["discovery-native-igrys"].researched=true
context=M.context(force)
check(M.state(force,defs.by_id["igrys"],context)=="complete",
  "Side-world quest should complete from the real installed unlock research")
local a,b=M.unlocked_records(force,context)
check(b==15 and a>=0,"Recovered transmission count mismatch")
check(not M.show_in_filter(force,defs.by_id["igrys"],"ready",context)
  and M.show_in_filter(force,defs.by_id["igrys"],"done",context),
  "Quest status filtering is inconsistent")
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
-- Native per-force boss victories, not a researched stage, complete fights.
local boss=defs.by_id["nexus-arachnid-queen"]
check(M.state(force,boss)=="unavailable",
  "Boss quest should not pretend to have victories without the source API")
force.name="player"
local calls=0
rawset(_G,"remote",{
  interfaces={["nexus-bosses"]={get_state=true,open_codex=true}},
  call=function(mod,method,...)
    check(mod=="nexus-bosses","Unexpected remote mod")
    calls=calls+1
    if method=="get_state" then
      return {defeated={player={["arachnid-queen"]=true}}}
    end
    check(method=="open_codex","Journal must not call source debug actions")
    return true
  end
})
local ctx=M.context(force)
check(calls==1,"Nexus snapshot must be read once per view")
check(M.complete(force,boss,ctx),"Native boss victory not detected")
check(not M.complete(force,defs.by_id["nexus-watcher"],ctx),
  "One boss victory should not complete its whole circle")
check(calls==1,"Repeated quest status must reuse the snapshot")
check(require("scripts.razi_nexus_trials").open_codex(
  {index=42},"arachnid-queen"),"Native codex cannot open")
check(calls==2,"Codex must open only on explicit user interaction")
rawset(_G,"remote",nil)

local weather=require("scripts.razi_weather_guide")
rawset(_G,"script",{active_mods={
  ["celestial-weather-additions-updated"]="1.3.1"
}})
rawset(_G,"settings",{startup={
  ["shibadisaster-cwa-enable-muria-changes"]={value=true},
  ["shibadisaster-cwa-enable-paracelsin-changes"]={value=false}
}})
local muria=weather.for_quest(defs.by_id["muria"])
local para=weather.for_quest(defs.by_id["paracelsin"])
check(muria and muria.world=="muria" and muria.enabled,
  "Enabled Muria weather should appear in field guide")
check(para and para.world=="paracelsin" and not para.enabled,
  "Paracelsin winter should show the source's disabled setting")
script.active_mods={}
check(weather.for_quest(defs.by_id["muria"])==nil,
  "Weather must not appear if the add-on is missing")
rawset(_G,"script",nil)
rawset(_G,"settings",nil)
rawset(_G,"game",{connected_players={},forces={player=force}})
for _=1,500 do
  M.on_research({research={force=force},by_script=true})
end
check(storage.razi_journal_pending_forces.player,
  "Scripted research storms should collapse into one pending force refresh")
M.flush_research_refreshes()
check(not storage.razi_journal_pending_forces,
  "Deferred journal refreshes should be consumed together")
M.on_removed(42)
check(not storage.razi_expedition_journal[42],
  "Deleted player preferences were not cleaned")
print("Expedition Journal: chapters, branches, skipped content and save backfill passed")
