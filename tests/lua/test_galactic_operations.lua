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
local one,page,count=ui.page_slice(rows,1,16)
check(#one==16 and one[1].id==1 and count==7 and page==1,"First page")
local last,p=ui.page_slice(rows,7,16)
check(#last==5 and last[1].id==97 and p==7,"Last page")
local overflow,clamped=ui.page_slice(rows,600,16)
check(#overflow==5 and clamped==7,"Overflow clamp")
local empty,index,pages=ui.page_slice({},10,16)
check(#empty==0 and index==1 and pages==1,"Empty page")
-- High DPI and narrow screens must never require a fixed 460px UI.
for _,case in ipairs({
  {1920,1080,1,false},{1280,720,1.5,true},
  {1024,768,1.5,true},{900,600,1.25,true},
  {2560,1440,1.5,false}
}) do
  local layout=ui.layout({width=case[1],height=case[2]},case[3])
  check(layout.compact==case[4],"Wrong narrow-screen command layout")
  check(layout.width<=(case[1]/case[3])-20,
    "Operations panel would overflow the display")
  check(layout.card_width<layout.width,
    "Directory card would overflow the operations panel")
  check(layout.list_height>0 and layout.inspector_height>0,
    "The directory or inspector lost its scroll height")
end
check(ui.search_matches({
  name="panglia",group="nyxaris",display_search="Jardin du Temps"}, "jardin"),
  "Visible translated planet names should be searchable")
check(ui.search_matches({
  name="panglia",group="nyxaris",display_search="Jardin du Temps"}, "pangl"),
  "Internal planet IDs should remain searchable")
check(ui.search_matches({
  name="cargo hauler",group="vespera",location_search="aquilo"}, "aquilo"),
  "Fleet search must include destination names")
check(not ui.search_matches({
  name="panglia",group="nyxaris",display_search="Jardin du Temps"}, "crucible"),
  "Unrelated planets must not match")
rawset(_G,"storage",{razigui={
  [1]={translation_pending={[42]="panglia"},translations={},
    translation_requested={panglia=true}}
}})
ui.on_string_translated({player_index=1,id=42,translated=true,
  result="Jardin du Temps"})
check(storage.razigui[1].translations.panglia=="jardin du temps"
  and not storage.razigui[1].translation_pending[42]
  and storage.razigui[1].translation_dirty,
  "Translation handler must cache resolved player-local search text")
ui.on_string_translated({player_index=1,id=13,translated=true,
  result="Some other mod's translation"})
check(not storage.razigui[1].translations.other,
  "Unrelated translation requests must not mutate Galactic Operations")

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
-- The 30-tick map check should not keep rewriting an unchanged position.
local moves=0
local anchor=setmetatable({valid=true},{
  __index=function(t,key)
    if key=="location" then return rawget(t,"_location") end
  end,
  __newindex=function(t,key,value)
    if key=="location" then
      moves=moves+1
      rawset(t,"_location",value)
    else rawset(t,key,value) end
  end
})
local map_player={
  valid=true,connected=true,controller_type=1,render_mode=1,
  display_scale=1,display_resolution={width=1920,height=1080},
  gui={screen={razi_ops_map_anchor=anchor}}
}
ui.sync_map_button(map_player)
ui.sync_map_button(map_player)
check(moves==1,"Steady map button location was written every poll")
map_player.display_resolution.width=1600
ui.sync_map_button(map_player)
check(moves==2 and anchor.location.x==1356,
  "Map button must move when the player's resolution changes")
print("Galactic Operations selection and map visibility fixtures passed")

local campaign=require("scripts.galactic_campaign")
local trade=require("scripts.galactic_trade")
check(#campaign.systems==8,"Seven-system campaign UI lost a chapter")
local first,second={name="x",researched=true},{name="y",researched=false}
local finished,total,pending=campaign.progress({technologies={x=first,y=second}},
  {"x","y","not-installed"})
check(finished==1 and total==2 and #pending==1 and pending[1]==second,
  "Campaign UI should only count existing native discoveries")
local blocked,n=campaign.blockers({prerequisites={first,second}},3)
check(n==1 and blocked[1].name=="y","Real technology prerequisites missing")
local summary=trade.summary({platforms={},technologies={
  ["interplanetary-trade-logistics"]={researched=true}}})
check(summary.unlocked and summary.ships==0 and summary.unscheduled==0,
  "Cargo trade readiness should be read-only and safe on empty worlds")

-- Newly required world identities must match route and campaign chapter maps.
for _,value in ipairs({
 {"muluna","calidus"},{"velora","nyxaris"},{"ferrum","vibrant"},
 {"khemia","vibrant"},{"obsidiax","vespera"},
 {"bm-balack","vespera"},{"carna","umbra"},{"arcanyx","umbra"}
}) do
 check(catalog.system(value[1])==value[2],
   "New required-world catalogue mismatch: "..value[1])
end
local index=campaign.discovery_index({technologies={
 some={name="some",prototype={effects={{
  type="unlock-space-location",space_location="cerys"}}}},
 another={name="another",prototype={effects={{
  type="unlock-space-location",space_location="muluna"}}}}
}})
check(index.vibrant[1]=="some" and index.calidus[1]=="another",
  "Campaign did not discover native moon research dynamically")
