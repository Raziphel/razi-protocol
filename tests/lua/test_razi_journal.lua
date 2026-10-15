-- Read-only quest progression and missing-content safety regression.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,message) if not ok then error(message,2) end end
local defs=require("scripts.razi_journal_data")
local M=require("scripts.razi_journal")
check(#defs.chapters==18,"Eighteen Protocol Codex chapters expected")
check(#defs.quests==234,"Protocol Codex must include both core worlds and their recovery science")
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
-- Industry missions are tied to existing optional research, not new
-- recipe-count flags, planets or scripted completion conditions.
for _,id in ipairs({"alliance-optical-coils","alliance-vesta-magnets",
  "alliance-aquilo-outer","alliance-panglia-bond",
  "alliance-bond-paracelsin","alliance-bond-linox",
  "alliance-pressure-frame","alliance-pressure-vesta",
  "alliance-pressure-aquilo"}) do
  local quest=defs.by_id[id]
  check(quest and quest.chapter=="alliances" and quest.site,
    "Industrial partnership missing prototype-backed guidance: "..id)
end
local force={technologies={}}
for _,q in ipairs(defs.quests) do
  if q.tech then
    force.technologies[q.tech]={name=q.tech,researched=false,
      prototype={hidden=false},localised_name=q.tech}
  end
end
-- Column budgets remain inside the game display at different UI scales.
for _,screen in ipairs({
  {width=1920,height=1080,scale=1},
  {width=1920,height=1080,scale=1.25},
  {width=1600,height=900,scale=1.5},
  {width=1280,height=720,scale=1},
  {width=1024,height=768,scale=1},
}) do
  local d=M.layout(screen,screen.scale)
  check(d.width <= math.max(420,math.floor(screen.width/screen.scale)-52),
    "Journal window exceeds the player's display")
  check(d.rail+d.reader+43==d.width,
    "Journal reading columns have a broken width budget")
  check(d.body>0 and d.body<d.height,
    "Journal needs positive content height")
  check(d.reader>=190,"Journal reading width is too narrow")
end
local start=M.summary(force)
local complete,total,active=M.summary(force)
check(start==0 and total>0 and active>=1,
  "At least both initial factory/opening branches must be listed")
-- One campaign pass should calculate each quest exactly once while still
-- matching the public summary and the individual mission states.
local original_state=M.state
local evaluations=0
M.state=function(...)
  evaluations=evaluations+1
  return original_state(...)
end
local view=M.view_status(force,M.context(force))
M.state=original_state
check(evaluations==#defs.quests,
  "Codex redraw must not rescan the quest list for every chapter")
check(view.done==complete and view.total==total and view.ready==active,
  "One-pass Codex counts differ from the campaign summary")
local counted=0
for _,chapter in ipairs(defs.chapters) do
  local group=view.chapters[chapter.id]
  check(group and group.total>=group.completed,
    "Chapter status lost a research milestone")
  counted=counted+group.total
end
check(counted==view.total,"Chapter totals disagree with the campaign")
-- A disabled upstream alternative disappears instead of creating a
-- phantom objective or blocking the main campaign.
local guarded=force.technologies["razi-network-aquilo-outer-controllers"]
force.technologies["razi-network-aquilo-outer-controllers"]=nil
check(M.state(force,defs.by_id["alliance-aquilo-outer"])=="unavailable",
  "Deep-only trade must not appear in Balanced mode")
force.technologies["razi-network-aquilo-outer-controllers"]=guarded
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
local guide=M.guidance(force,M.context(force))
check(guide.primary and next.id==guide.primary.quest.id,
  "Next milestone action and priority navigator must agree")
check(not guide.primary.disabled and #guide.primary.tech_blockers==0,
  "Research-blocked objectives must not be labeled research-ready")
for _,candidate in ipairs(guide.selected) do
  check(M.state(force,candidate.quest)=="active",
    "Priorities must be actual available campaign objectives")
end
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
rawset(_G,"game",{tick=0,connected_players={},forces={player=force}})
check(M.research_affects_journal({name="automation"}),
  "Direct quest research must refresh the journal")
check(M.research_affects_journal({name="native-igrys",prototype={effects={{
  type="unlock-space-location",space_location="igrys"
}}}}),"Native world-unlock research must refresh the journal")
check(not M.research_affects_journal({name="unrelated",prototype={effects={{
  type="unlock-recipe",recipe="iron-plate"
}}}}),"Unrelated research must not repaint the journal")
storage.razi_journal_pending_forces=nil
M.on_research({research={name="unrelated",force=force}})
check(not storage.razi_journal_pending_forces,
  "Unrelated research must not schedule a journal refresh")
-- Single research completes promptly on the next maintenance tick.
M.on_research({research={name="automation",force=force}})
check(storage.razi_journal_pending_forces.player.count==1,
  "A normal research completion must schedule a refresh")
M.flush_research_refreshes()
check(not storage.razi_journal_pending_forces,
  "Ordinary research should refresh without a burst delay")
for i=1,1000 do
  -- /cheat may generate non-script-marked events; BOTH kinds must batch.
  M.on_research({research={name="automation",force=force},
    by_script=i%2==0})
end
M.on_research({research={name="native-igrys",force=force,
  prototype={effects={{type="unlock-space-location",space_location="igrys"}}}},
  by_script=true})
check(storage.razi_journal_pending_forces.player,
  "All research storms should collapse into one pending force refresh")
local count=0
for _ in pairs(storage.razi_journal_pending_forces) do count=count+1 end
check(count==1,"A bulk unlock must schedule only one force refresh")
check(storage.razi_journal_pending_forces.player.count==12,
  "A research storm must cap its per-force event counter")
M.flush_research_refreshes()
check(storage.razi_journal_pending_forces.player,
  "Bulk research must not redraw the Codex while events are arriving")
game.tick=179
M.flush_research_refreshes()
check(storage.razi_journal_pending_forces.player,
  "Burst cooldown completed too early")
game.tick=180
M.flush_research_refreshes()
check(not storage.razi_journal_pending_forces,
  "A quiet bulk unlock must refresh and clear its pending work")
-- Saved games from an earlier build may have a boolean pending marker.
storage.razi_journal_pending_forces={player=true}
M.flush_research_refreshes()
check(not storage.razi_journal_pending_forces,
  "Legacy pending markers must remain compatible")
M.on_removed(42)
check(not storage.razi_expedition_journal[42],
  "Deleted player preferences were not cleaned")
-- Prototype research effects are static. The index is built once, while
-- researched flags are still read live from each force.
local catalog_scans=0
local static_techs=setmetatable({
  ["discovery-native-igrys"]={hidden=false,effects={{
    type="unlock-space-location",space_location="igrys"
  }}}
},{__pairs=function(t)
  catalog_scans=catalog_scans+1
  return next,t,nil
end})
rawset(_G,"prototypes",{technology=static_techs})
local first_index=M.discovery_index(force)
local second_index=M.discovery_index(force)
check(catalog_scans==1 and first_index.igrys and second_index.igrys,
  "Research unlock prototypes were rescanned on each Codex refresh")
force.technologies["discovery-native-igrys"].researched=false
check(not M.discovery_index(force).igrys.researched,
  "Indexed unlocks must still report current research status")
force.technologies["discovery-native-igrys"].researched=true
check(M.discovery_index(force).igrys.researched,
  "The Codex should follow new research without refreshing its catalog")
rawset(_G,"prototypes",nil)
print("Expedition Journal: chapters, branches, skipped content and save backfill passed")
