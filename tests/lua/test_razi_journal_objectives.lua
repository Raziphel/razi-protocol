-- Truthful, fully source-derived Mission Plan regression.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(value,message) if not value then error(message,2) end end
local plans=require("scripts.razi_journal_objectives")
local required={
  {name="stone",localised_name="Stone science",researched=true},
  {name="steel",localised_name="Steel processing",researched=false},
}
local native={name="space-platform",localised_name="Space Platform",
  researched=false,enabled=true,prerequisites=required}
local state={first=true,second=false,secret=false}
local callbacks={
  available=function(id)return id~="gone" end,
  visible=function(id)return id~="secret" end,
  complete=function(id)return state[id] end,
  quest_for_tech=function(id)return id=="steel" and "steel" or nil end,
  current_research={name="space-platform"},research_progress=.38
}
local quest={id="platform",tech="space-platform",
  requires={"first","second","gone","secret"}}
local snapshot=plans.snapshot(quest,native,"active",callbacks)
check(snapshot.requirements==4 and snapshot.satisfied==2,
  "Only installed and visible campaign and technology prerequisites count")
check(#snapshot.rows==5 and snapshot.rows[#snapshot.rows].kind=="goal",
  "Final completion criterion must appear after all source requirements")
check(snapshot.rows[1].done and not snapshot.rows[2].done,
  "Real campaign prerequisite status should be carried through")
check(snapshot.next_step.id=="second",
  "The very next missing milestone must come first")
check(snapshot.research_percent==38,
  "Actual ongoing research progress should be shown")
local short=plans.visible_rows(snapshot,false,2)
check(#short==2 and not short[1].done and not short[2].done,
  "Collapsed checklists show unmet blockers rather than arbitrary achievements")
check(#plans.visible_rows(snapshot,true)==5,
  "Expanded checklist must not silently truncate required milestones")
local done=plans.snapshot(quest,
  {name="space-platform",researched=true,enabled=true,
   prerequisites={{name="steel",researched=true}}},
  "complete",callbacks)
check(done.finished and done.next_step~=nil,
  "Inconsistent fixture can still have unmet source campaign prerequisites")
check(done.research_percent==nil,
  "Completed technologies should not show a fictitious research countdown")
local boss=plans.snapshot({id="nexus-queen",boss="queen"},
  {name="boss-unlock",researched=true,prerequisites={}}, "active",{})
check(boss.kind=="boss" and boss.requirements==0 and
  boss.rows[#boss.rows].name[1]=="nexus-bosses.boss-queen",
  "Native Nexus victories must be the boss completion condition")
local cargo=plans.snapshot({id="stage-3",convergence="third"},
  {name="razi-convergence",researched=false,
   prerequisites={{name="unlocked",researched=false}}},"active",{})
check(cargo.kind=="delivery" and cargo.requirements==0,
  "Convergence mandates must not masquerade as technology research")
local final=plans.snapshot({id="victory",convergence="victory"},
 nil,"complete",{})
check(final.kind=="transmission" and final.finished,
  "Final transmission must be sourced from the real Convergence victory")
local world=plans.snapshot({id="sea",world="maraxsis"},native,"active",{})
check(world.kind=="discovery",
  "World discovery objectives must name research access, not fake travel")
print("Mission Plan snapshots, visibility, progress and native sources: OK")
