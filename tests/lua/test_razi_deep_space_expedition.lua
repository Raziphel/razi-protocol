-- Contract: Convergence requires REAL crewed visits to all installed
-- connected Deep Space destinations, with no research or autopilot bypass.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(value,why) if not value then error(why,2) end end
storage={}
defines={controllers={remote=9}}
game={tick=100,connected_players={}}
local endpoints={
 "solar-system-edge","nexus","shattered-planet",
 "black-hole-approach","black-hole","oort-cloud","sol",
 "skewer_shattered_planet","skewer_lost_beyond",
 "razi-deep-space-edge"
}
prototypes={space_location={},space_connection={}}
for _,id in ipairs(endpoints) do
 prototypes.space_location[id]={name=id,localised_name=id,hidden=false}
end
prototypes.space_location["point-warden"]={name="point-warden",hidden=false}
prototypes.space_location["aegis-inner-edge"]={
 name="aegis-inner-edge",hidden=true}
local connections={
 {"solar-system-edge","nexus"},{"solar-system-edge","shattered-planet"},
 {"solar-system-edge","black-hole-approach"},
 {"black-hole-approach","black-hole"},
 {"nexus","oort-cloud"},{"oort-cloud","sol"},
 {"shattered-planet","skewer_shattered_planet"},
 {"skewer_shattered_planet","skewer_lost_beyond"},
 {"solar-system-edge","razi-deep-space-edge"},
 {"solar-system-edge","aegis-inner-edge"}
}
for i,pair in ipairs(connections) do
 prototypes.space_connection[i]={from=pair[1],to=pair[2]}
end
local m=require("scripts.razi_deep_space_expedition")
local f1={index=1}
local craft={valid=true,hub={valid=true},force=f1,
 name="Witness Ark",completed_trips=4,
 space_location={name="solar-system-edge"},scheduled_for_deletion=0}
local pilot={name="Pioneer",valid=true,force=f1,controller_type=1,
 character={valid=true,surface={platform=craft}}}
game.connected_players={pilot}
local done,total,stops,chart=m.status(f1)
check(chart and total==#endpoints and done==0,
 "All ten real connected stops, including optional branches, must be required")
check(not m.observe({valid=true,force=f1,character=nil}),
 "Uncrewed travel must not record")
pilot.controller_type=9
check(not m.observe(pilot),"Remote View must not record an arrival")
pilot.controller_type=1
craft.completed_trips=0
check(not m.observe(pilot),"A stationary never-traveled platform cannot prove arrival")
craft.completed_trips=4
check(m.observe(pilot),"Physical Solar System Edge crew arrival must count")
check(not m.observe(pilot),"A repeated observation cannot count twice")
craft.space_location={name="point-warden"}
check(not m.observe(pilot),"Optional orphaned targets are not requirements")
craft.space_location={name="aegis-inner-edge"}
check(not m.observe(pilot),"Hidden chart markers do not count")
craft.space_location={name="nexus"}
check(m.observe(pilot),"First real Nexus expedition must record")
local f2={index=2}
local other={valid=true,force=f1,name="Teammate",controller_type=1,
 character={valid=true,surface={platform=craft}}}
for _,id in ipairs(endpoints) do
 craft.space_location={name=id}
 if id~="solar-system-edge" and id~="nexus" then
  check(m.observe(other),"Team members can complete remaining stop: "..id)
 end
end
done,total,stops,chart=m.status(f1)
check(done==total and total==#endpoints,
 "All installed connected destinations must be visited")
for _,row in ipairs(stops) do
 check(row.visited,"Every required destination must have a permanent crew record")
end
check(m.status(f2)==0,"Independent force must not inherit visits")
m.forces_merged{source_index=1,destination=f2}
check(select(1,m.status(f2))==#endpoints,
 "Merging multiplayer forces retains all expedition receipts")
check(storage.razi_deep_space_visits[1]==nil,
 "Source force expedition record must be removed after merge")
craft.valid=false
check(select(1,m.status(f2))==#endpoints,
 "Destroying a previously visited ship must not erase the expedition history")
print("Deep Space expedition: chart eligibility, crew, optional routes, remote view, force merge passed")
