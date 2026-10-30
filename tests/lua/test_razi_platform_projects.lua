package.path="./?.lua;./?/init.lua;"..package.path
local function check(v,msg) if not v then error(msg,2) end end
storage={}
local m=require("scripts.razi_platform_projects")
local f={index=1,platforms={}}
check(not m.snapshot(f).platform,"Empty force must not complete a project")
local ghost={valid=true,hub=nil,force=f,name="Blueprint",scheduled_for_deletion=0,completed_trips=0}
f.platforms[1]=ghost
check(not m.observe(ghost) and not m.snapshot(f).platform,"Starter-pack placeholder is not built")
local ship={valid=true,hub={valid=true},force=f,name="Pioneer",scheduled_for_deletion=0,completed_trips=0}
f.platforms[2]=ship
check(m.observe(ship),"Hub creation must complete First Platform")
check(not m.observe(ship),"Events must not award milestones twice")
local built=m.snapshot(f)
check(built.platform and not built.voyage and built.first_name=="Pioneer","Hub is not a voyage")
ship.completed_trips=1
check(m.observe(ship),"First engine-recorded trip must complete First Voyage")
check(m.snapshot(f).voyage_name=="Pioneer","Trip name must remain accurate")
f.platforms={}
check(m.snapshot(f).platform and m.snapshot(f).voyage,"Destruction cannot erase earned milestones")
local dest={index=2,platforms={}}
m.forces_merged{source_index=1,destination=dest}
check(m.snapshot(dest).voyage and m.snapshot(dest).platform,"Merge must preserve milestones")
check(storage.razi_project_milestones[1]==nil,"Merge must remove source record")
local old={index=3,platforms={{valid=true,hub={valid=true},force=nil,
  name="Veteran",scheduled_for_deletion=0,completed_trips=3}}}
check(m.snapshot(old).platform and m.snapshot(old).voyage,"Old saves backfill from live trips")
local deleting={index=4,platforms={{valid=true,hub={valid=true},force=nil,
  name="Retiring",scheduled_for_deletion=100,completed_trips=3}}}
check(not m.snapshot(deleting).platform,"Pending deletion cannot grant a milestone")
print("Physical project milestones passed")
