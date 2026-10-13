-- Deterministic, in-memory Codex guidance regression.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,message) if not ok then error(message,2) end end
local guidance=require("scripts.razi_journal_guidance")
local states={
  ["solaris-gate"]="active",["nyxaris-gate"]="active",
  fulgora="active",aquilo="active",crucible="active",
  muria="active",vesta="locked",["umbra-belt"]="active"
}
local prereq={name="crucible-pressure-research",researched=false,
  localised_name="Crucible pressure science"}
local techs={
  ["solaris-discovery"]={name="solaris-discovery",enabled=true,
    researched=false,prerequisites={}},
  ["nyxaris-discovery"]={name="nyxaris-discovery",enabled=true,
    researched=false,prerequisites={}},
  ["planet-discovery-fulgora"]={name="planet-discovery-fulgora",
    enabled=true,researched=false,prerequisites={}},
  ["planet-discovery-aquilo"]={name="planet-discovery-aquilo",
    enabled=true,researched=false,prerequisites={}},
  ["planet-discovery-crucible"]={name="planet-discovery-crucible",
    enabled=true,researched=false,prerequisites={prereq}},
  ["planet-discovery-muria"]={name="planet-discovery-muria",
    enabled=false,researched=false,prerequisites={}},
  ["planet-discovery-vesta"]={name="planet-discovery-vesta",
    enabled=true,researched=false,prerequisites={}},
  ["razi-umbra-belt-survey"]={name="razi-umbra-belt-survey",
    enabled=false,researched=false,prerequisites={}}
}
local function lookup(quest) return techs[quest.tech] end
local initial=guidance.plan(states,lookup)
check(initial.primary and initial.primary.kind=="ready",
  "Primary suggestion should require currently researchable native technology")
check(#initial.selected==3,"Three separate recommendations are expected")
local chapters={}
for _,entry in ipairs(initial.selected) do
  check(not chapters[entry.chapter],
    "Parallel recommendations should cover different active chapters")
  chapters[entry.chapter]=true
  check(entry.tech.enabled~=false and #entry.tech_blockers==0,
    "Disabled or research-blocked technologies must not be called ready")
end
check(initial.ready_count==4,"Native readiness should not count disabled technology")
check(initial.blocker and initial.blocker.quest.id=="crucible",
  "A concrete native technology blocker should outrank a disabled side world")
check(initial.blocker.kind=="research-blocked"
  and initial.blocker.tech_blockers[1]==prereq,
  "The spotlight must preserve real missing native technology")
check(states["vesta"]=="locked" and techs["planet-discovery-vesta"].researched==false,
  "Guide must never change quest states or research")
local repeat_plan=guidance.plan(states,lookup)
check(initial.primary.quest.id==repeat_plan.primary.quest.id,
  "Recommendations must not depend on Lua table hash iteration order")
local none=guidance.plan({},lookup)
check(not none.primary and not none.blocker and none.ready_count==0,
  "Missing optional content should not create phantom recommendations")
local story=guidance.plan({
  ["solaris-gate"]="locked",["space-science"]="active"
},function(quest)
  if quest.id=="solaris-gate" then
    return {name="solaris-discovery",enabled=true,prerequisites={}}
  end
  return {name=quest.tech,enabled=false,prerequisites={}}
end)
check(story.blocker and story.blocker.quest.id=="solaris-gate"
  and story.blocker.kind=="campaign-blocked"
  and story.blocker.quest_blockers[1]=="space-science",
  "Campaign blockers must name the missing Codex milestone")
local all_done=guidance.plan({
  ["solaris-gate"]="complete",["nyxaris-gate"]="complete"
},lookup)
check(not all_done.primary,"Completed milestones must not be recommended")
print("Codex guidance: research readiness, branch diversity, native and story blockers passed")
