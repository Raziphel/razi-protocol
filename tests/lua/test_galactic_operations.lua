-- Pure regression checks for gigantic campaign lists and UI lifecycle.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(v,msg) if not v then error(msg,2) end end
local catalog=require("scripts.galactic_catalog")
check(catalog.system("nauvis")=="calidus","Nauvis in wrong group")
check(catalog.system("razi-calidus-drift")=="calidus",
  "Drift should be discoverable in the Calidus Atlas")
check(catalog.system("sye-vespera")=="vespera","Vespera slipstream misplaced")
check(catalog.system("crucible-orbit")=="umbra","Crucible misplaced")
check(catalog.system("asteroid-belt-inner-edge")=="vibrant","Belt misplaced")
check(catalog.system("unknown-mod-planet")=="unassigned","Unknown mod hidden")
local ui=require("scripts.galactic_operations")
local rows={}
for i=1,101 do rows[i]={id=i} end
local one,page,count=ui.page_slice(rows,1,22)
check(#one==22 and one[1].id==1 and count==5 and page==1,"First page")
local last,p=ui.page_slice(rows,5,22)
check(#last==13 and last[1].id==89 and p==5,"Last page")
local overflow,clamped=ui.page_slice(rows,600,22)
check(#overflow==13 and clamped==5,"Overflow clamp")
local empty,index,pages=ui.page_slice({},10,22)
check(#empty==0 and index==1 and pages==1,"Empty page")
rawset(_G,"defines",{controllers={remote=1,character=2},
  render_mode={game=0,chart=1,chart_zoomed_in=2}})
local mock={valid=true,connected=true,controller_type=1,render_mode=1}
check(ui.in_map_view(mock),"Remote chart should show the map button")
mock.render_mode=2
check(ui.in_map_view(mock),"Zoomed chart should still show the map button")
mock.render_mode=0
check(not ui.in_map_view(mock),"Normal factory play must hide the map button")
mock.render_mode=1
mock.controller_type=2
check(not ui.in_map_view(mock),"Non-remote controller must not display button")
mock.controller_type=1
mock.connected=false
check(not ui.in_map_view(mock),"Disconnected player must not display button")
print("Galactic Operations selection and map visibility fixtures passed")
