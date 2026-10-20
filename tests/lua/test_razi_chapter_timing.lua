-- First-clear timestamps use simulation time, are force-scoped and never
-- invent completion times for objectives finished before tracking existed.
package.path="./?.lua;./?/init.lua;"..package.path
storage={}
local clock=require("scripts.razi_chapter_timing")
local function check(value,why) if not value then error(why,2) end end
local quests={
  {id="m1",chapter="calidus",phase="machines"},
  {id="m2",chapter="calidus",phase="machines"},
  {id="g1",chapter="calidus",phase="growth"},
  {id="bonus",chapter="calidus",phase="growth",optional=true},
  {id="next",chapter="solaris"}
}
local finished={}
local function available(_) return true end
local function complete(q) return finished[q.id]==true end
local function scan(force,tick,historical)
  return clock.observe(force,quests,available,complete,historical,tick)
end
local f1={index=1}
check(not scan(f1,0,false),"New game must not record unfinished acts")
finished.m1=true
check(scan(f1,54000,false),"First mission must get an immediate timestamp")
check(clock.get(f1,"milestones","m1")==54000,
  "First mission should store the exact completion tick")
finished.m2=true
check(scan(f1,108000,false),"Chapter 01 act should clear at 30 minutes")
check(clock.get(f1,"phases","machines")==108000,
  "Act clear must record its first exact simulation tick")
check(clock.get(f1,"milestones","m2")==108000,
  "Second mission should store its own completion time")
check(clock.format(clock.get(f1,"phases","machines"))=="00:30",
  "1800 game-seconds must display as 00:30")
check(clock.get(f1,"chapters","calidus")==nil,
  "Do not mark a chapter done while other required acts are pending")
finished.g1=true
check(scan(f1,1296000,false),"Second act and Calidus must clear at 6 hours")
check(clock.format(clock.get(f1,"phases","growth"))=="06:00",
  "Six hours should display as 06:00")
check(clock.get(f1,"chapters","calidus")==1296000,
  "Optional missions must not postpone the primary chapter record")
finished.bonus=true
check(scan(f1,1320000,false),"An optional mission should also receive a time")
check(clock.get(f1,"milestones","bonus")==1320000,
  "Optional milestone must be recorded separately")
check(clock.get(f1,"chapters","calidus")==1296000,
  "Completing an optional mission later cannot change chapter time")
check(not scan(f1,1550000,false),"Repeated status reads should do no writes")
finished.m1=false
check(clock.get(f1,"phases","machines")==108000,
  "Reversed research must not erase a first clear")
check(clock.get(f1,"milestones","m1")==54000,
  "Reversing research must not erase original mission time")
finished.m1=true
check(not scan(f1,1600000,false),"Recompletion must retain the first time")
-- A new force with already-complete research gets a historical unknown.
local f2={index=2}
check(scan(f2,1600000,true),"Pre-tracking achievements need legacy markers")
check(clock.get(f2,"chapters","calidus")==false,
  "Never claim mod-installation time as legacy chapter finish time")
check(clock.get(f2,"milestones","m1")==false,
  "Already-finished missions on an old save must be historical-unknown")
check(not scan(f2,1700000,false),"Historic unknowns must be immutable")
-- Earliest proven timestamp survives force merges; unknown dominates claims.
local f3={index=3}
check(scan(f3,1700000,false),"A third force may earn its own time")
clock.forces_merged{source_index=3,destination=f1}
check(clock.get(f1,"chapters","calidus")==1296000,
  "Later merge must preserve earlier proven clear")
clock.forces_merged{source_index=2,destination=f1}
check(clock.get(f1,"chapters","calidus")==false,
  "A legacy clear must not gain a made-up precise time on merge")
check(clock.get(f1,"milestones","m1")==false,
  "Merging a legacy mission must not invent an exact timestamp")
check(storage.razi_chapter_completion_times[2]==nil,
  "Merged source entry must be deleted")
check(clock.get(f3,"chapters","calidus")==nil,
  "Merged force no longer retains a distinct source record")
print("Razi expedition timing: mission, act, chapter, legacy and force merge checks passed")
