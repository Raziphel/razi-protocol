---@diagnostic disable: need-check-nil, undefined-field, param-type-mismatch
-- Read-only quest progression and missing-content safety regression.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,message) if not ok then error(message,2) end end
local defs=require("scripts.journal.data")
local M=require("scripts.journal.journal")
check(#defs.chapters==19,"Nineteen expedition chapters expected")
check(#defs.quests==230,"Protocol Codex must include 230 source-backed expedition milestones")
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
for _,id in ipairs({"alliance-vesta-magnets","alliance-panglia-bond",
  "alliance-bond-paracelsin","alliance-bond-linox",
  "alliance-pressure-frame","alliance-pressure-vesta"}) do
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
-- K2SO has a craft-triggered Automation Core before native Automation.
-- The Journal must never advertise disabled vanilla research as its opener.
local bootstrap={name="automation",researched=false,enabled=false,
  prototype={hidden=true},prerequisites={{researched=false}}}
local core={name="kr-automation-core",researched=false,enabled=true,
  localised_name="Automation core",prototype={hidden=false},prerequisites={}}
local fresh={technologies={automation=bootstrap,["kr-automation-core"]=core}}
rawset(_G,"settings",{global={
  ["razi-hide-spoilers"]={value=true}
}})
local opener=defs.by_id["first-signal"]
local tech_lookup=require("scripts.journal.quest_state").technology
check(opener.tech=="kr-automation-core" and M.available(fresh,opener),
  "Opening quest must use source-owned K2SO Automation Core")
check(tech_lookup(fresh,opener)==core and M.state(fresh,opener)=="active",
  "Available Automation Core must replace disabled native Automation")
check(M.journal_visible(fresh,opener),
  "Spoiler fog must not conceal the real opening research")
local fresh_view=M.view_status(fresh)
check(fresh_view.total==1 and fresh_view.ready==1,
  "Fresh K2SO save must show one research-ready opening objective")
check(#fresh_view.chapters.calidus.quests==1 and
  fresh_view.chapters.calidus.quests[1].id=="first-signal",
  "Calidus must show the opening mission in the chapter index")
check(M.next_quest(fresh) and M.next_quest(fresh).id=="first-signal",
  "Fresh-save reader must open the Automation Core mission")
core.enabled=false
check(not M.available(fresh,opener) and M.view_status(fresh).total==0,
  "Both disabled research options must be omitted, not called ready")
bootstrap.prototype.hidden=false
bootstrap.enabled=true
bootstrap.prerequisites={}
check(tech_lookup(fresh,opener)==bootstrap and M.state(fresh,opener)=="active",
  "Vanilla Automation must be used when K2SO Core is disabled or absent")
bootstrap.researched=true
check(M.state(fresh,opener)=="complete",
  "Completed fallback research must survive technology substitution")
bootstrap.researched=false
bootstrap.enabled=false
bootstrap.prototype.hidden=true
core.enabled=true
core.prerequisites={{name="iron-handling",researched=false}}
check(M.state(fresh,opener)=="locked" and M.view_status(fresh).ready==0,
  "Unresearched native prerequisites must not count as ready")
core.prerequisites={}
check(M.state(fresh,opener)=="active",
  "Craft-triggered research without prerequisites is genuinely ready")
core.researched=true
check(M.state(fresh,opener)=="complete",
  "K2SO completion must close the same stable quest ID")
core.researched=false
fresh.technologies["kr-automation-core"]=nil
fresh.technologies.automation=nil
check(M.view_status(fresh).total==0,
  "Absent source research must not create fictitious quest completion")
rawset(_G,"settings",nil)
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
  "A real Nauvis factory objective must be ready on a new save")
check(M.state(force,defs.by_id["first-signal"])=="active",
  "The opening Automation quest must be ready on a new save")
check(M.state(force,defs.by_id["green-science"])=="locked",
  "Green science must have meaningful early Journal prerequisites")
-- Hide Spoilers is a shared setting, ON by default in the mod. Preserve
-- already reached quests, but don't expose future dossier titles or details.
rawset(_G,"settings",{global={["razi-hide-spoilers"]={value=true}}})
check(M.hide_spoilers(),"Mod setting must enable the journal spoiler filter")
check(M.journal_visible(force,defs.by_id["first-signal"]),
  "The first available quest should never be hidden")
check(not M.journal_visible(force,defs.by_id["green-science"]),
  "Unreached research must not appear in the Journal")
local hidden=M.view_status(force,M.context(force))
check(hidden.states["green-science"]=="unavailable",
  "Hidden locked chapters must be masked in the navigator")
check(not M.show_in_filter(force,defs.by_id["green-science"],"all"),
  "Searching should not leak hidden research")
rawset(_G,"settings",{global={["razi-hide-spoilers"]={value=false}}})
check(M.journal_visible(force,defs.by_id["green-science"]),
  "Turning off Hide Spoilers must immediately restore preview entries")
rawset(_G,"settings",nil)
-- Older and variant modpacks can omit K2 Electricity/Electronics:
-- such missing research must never become an invisible campaign wall.
local steam_power=force.technologies["steam-power"]
force.technologies["steam-power"]=nil
check(M.state(force,defs.by_id["nauvis-power"])=="unavailable"
  and M.state(force,defs.by_id["nauvis-electronics"])=="active",
  "Missing K2 steam power must not strand Nauvis electronics")
force.technologies["steam-power"]=steam_power
steam_power.enabled=false
check(M.state(force,defs.by_id["nauvis-power"])=="unavailable"
  and M.state(force,defs.by_id["nauvis-electronics"])=="active",
  "Disabled installed research must be skipped without blocking other goals")
steam_power.researched=true
check(M.state(force,defs.by_id["nauvis-power"])=="complete",
  "Researched but now disabled technology must retain its saved completion")
steam_power.researched=false
steam_power.enabled=nil
force.technologies["kr-automation-core"].researched=true
force.technologies.logistics.researched=true
check(M.state(force,defs.by_id["green-science"])=="active",
  "Nauvis green science must follow already researched early machines")
force.technologies["kr-automation-core"].researched=false
force.technologies.logistics.researched=false
-- Legacy save research auto-completes moved milestones; no migration or
-- parallel objective completion flags should be introduced.
force.technologies["steel-processing"].researched=true
check(M.complete(force,defs.by_id["steel"]),
  "Moving Steel to Calidus must preserve historic researched state")
force.technologies["steel-processing"].researched=false
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
  -- Optional milestones are listed in their chapter but not in the campaign total.
  for _,quest in ipairs(group.quests) do
    if not quest.optional then counted=counted+1 end
  end
end
check(counted==view.total,"Chapter totals disagree with the campaign")
-- A disabled upstream alternative disappears instead of creating a
-- phantom objective or blocking the main campaign.
local guarded=force.technologies["razi-network-umbra-pressure-frame"]
force.technologies["razi-network-umbra-pressure-frame"]=nil
check(M.state(force,defs.by_id["alliance-pressure-frame"])=="unavailable",
  "Deep-only trade must not appear in Balanced mode")
force.technologies["razi-network-umbra-pressure-frame"]=guarded
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
force.technologies["discovery-native-igrys"].enabled=false
check(not M.discovery_index(force).igrys,
  "Disabled world-discovery research must not become a valid Journal goal")
force.technologies["discovery-native-igrys"].enabled=nil
local context=M.context(force)
check(M.available(force,defs.by_id["igrys"],context),
  "Side-world discovery should be dynamically indexed")
check(M.state(force,defs.by_id["igrys"],context)=="active",
  "Side-world research must respect the unlocked opening star")
force.technologies["discovery-native-igrys"].researched=true
context=M.context(force)
check(M.state(force,defs.by_id["igrys"],context)=="complete",
  "Side-world quest should complete from the real installed unlock research")
local a,b=M.unlocked_records(force,context) -- luacheck: ignore 411
check(a==0 and b==0,"The Archive must be empty while the story is off")
local story=require("lib.story")
story.configure(true)
a,b=M.unlocked_records(force,context)
check(b==#require("scripts.story.records") and a>=0,
  "Recovered transmission count mismatch")
story.configure(false)
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
  call=function(mod,method,...) -- luacheck: ignore 212
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
check(require("scripts.compatibility.nexus-bosses.trials").open_codex(
  {index=42},"arachnid-queen"),"Native codex cannot open")
check(calls==2,"Codex must open only on explicit user interaction")
rawset(_G,"remote",nil)

local weather=require("scripts.journal.weather_guide")
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
  "Vanilla fallback research must refresh the journal")
check(M.research_affects_journal({name="kr-automation-core"}),
  "K2SO Automation Core completion must refresh the journal")
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
  return _G.next,t,nil
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
-- The Relay Fragments chapter is story only: without the story nobody sees it
-- or counts it, and writer mode still opens it for the one writer.
rawset(_G,"settings",{global={["razi-hide-spoilers"]={value=false}}})
for _,q in ipairs(defs.quests) do
  if q.tech then
    force.technologies[q.tech]={name=q.tech,researched=false,
      prototype={hidden=false},localised_name=q.tech}
  end
end
local fragment=defs.by_id["fragment-1"]
check(fragment and fragment.story_only,"Relay Fragments quests must be story only")
local fragment_count=0
for _,q in ipairs(defs.quests) do
  if q.chapter=="echoes" then
    fragment_count=fragment_count+1
    check(q.story_only,"Every Relay Fragments quest must be story only: "..q.id)
  end
end
check(fragment_count==10,"Ten Relay Fragments quests expected")
local writer={index=7,valid=true,force=force}
local reader={index=8,valid=true,force=force}
rawset(_G,"storage",{razi_writer={[7]={on=true}}})
story.configure(false)
check(not M.available(force,fragment),"Fragments must be hidden while the story is off")
check(M.state(force,fragment)=="unavailable","Hidden fragments report no state")
check(not M.journal_visible(force,fragment),"Hidden fragments are not listed")
local off_view=M.view_status(force)
check(#off_view.chapters.echoes.quests==0 and off_view.chapters.echoes.total==0,
  "The Relay Fragments chapter must be empty while the story is off")
local _,off_total=M.summary(force)
check(off_total==off_view.total,"Totals must agree while the story is off")
check(not M.journal_visible(force,fragment,M.context(force,reader)),
  "A reader without writer mode must not see fragments")
check(M.available(force,fragment,M.context(force,writer)),
  "Writer mode must open fragments while the story is off")
local writer_view=M.view_status(force,M.context(force,writer))
check(#writer_view.chapters.echoes.quests==10,
  "Writer mode must list all ten fragments")
check(M.next_quest(force) and M.next_quest(force).chapter~="echoes",
  "A pinned or suggested quest must never fall on a hidden fragment")
story.configure(true)
check(M.available(force,fragment),"Fragments appear when the story is on")
local on_view=M.view_status(force)
check(#on_view.chapters.echoes.quests==10 and on_view.total==off_view.total+10,
  "The story adds the ten fragments to the totals")
story.configure(false)
rawset(_G,"storage",nil)
print("Expedition Journal: chapters, branches, skipped content and save backfill passed")
