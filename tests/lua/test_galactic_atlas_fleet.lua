-- Pure cases for weighted, unlocked-only atlas route planning.
package.path="./?.lua;./?/init.lua;"..package.path
local A=require("scripts.galactic_atlas")
local function check(v,m) if not v then error(m,2) end end
rawset(_G,"prototypes",{space_location={
  a={name="a"},b={name="b"},c={name="c"},x={name="x",hidden=true}
}})
local force={
  is_space_location_unlocked=function(id) return id~="x" end
}
local edges={
  {from={name="a"},to={name="b"},length=100},
  {from={name="b"},to={name="c"},length=30},
  {from={name="a"},to={name="c"},length=200},
  {from={name="a"},to={name="x"},length=1},
  {from={name="x"},to={name="c"},length=1}
}
local path,cost=A.shortest_path(force,"a","c",edges)
check(path and #path==3 and path[2]=="b" and cost==130,
  "Atlas must choose the shortest actual listed distance")
local direct,zero=A.shortest_path(force,"a","a",edges)
check(#direct==1 and zero==0,"Origin path not handled")
check(A.shortest_path(force,"a","x",edges)==nil,
  "Hidden/locked planet must not be used as transit shortcut")
force.technologies={
  ["planet-c"]={name="planet-c",prototype={effects={{
    type="unlock-space-location",space_location="c"}}},
    prerequisites={a={name="a",researched=true},
      b={name="b",researched=false}}}
}
local unlock=A.unlock_research(force,"c")
check(#unlock==1 and #unlock[1].missing==1
  and unlock[1].missing[1].name=="b",
  "Atlas must report unresearched native prerequisite")
local largest,count=A.asteroid_profile({
  {asteroid="small-metallic-asteroid"},
  {asteroid="huge-oxide-asteroid"},
  {asteroid="small-metallic-asteroid"}
})
check(largest=="huge" and count==2,
  "Atlas asteroid labels should come from distinct declared types")
local unknown=A.asteroid_profile({{asteroid="custom-oddity"}})
check(unknown=="unlisted",
  "Unknown modded asteroid must not be assigned an invented risk rating")
local Fleet=require("scripts.galactic_fleet")
local ship={
  hub={valid=true},space_location={name="a"},space_connection=nil,
  schedule={records={{station="a"}}},damaged_tiles={{damage=1}},
  can_leave_current_location=function() return false end,
  paused=false,speed=1.5,weight=123,distance=nil,completed_trips=4
}
local report=Fleet.snapshot(ship)
check(report.held and report.damage==1 and report.warning_count==2,
  "Fleet warnings must include real damage and cargo departure hold")
ship.space_connection={from={name="a"},to={name="b"}}
ship.distance=0.25
report=Fleet.snapshot(ship)
check(not report.held and report.progress==25 and report.warning_count==1,
  "Travelling craft must not carry a parked-delivery hold")
print("Galactic Atlas and Fleet Operations 2.0 regression fixtures passed")
