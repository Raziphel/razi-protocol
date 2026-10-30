package.path="./?.lua;./?/init.lua;"..package.path
local function check(v,msg) if not v then error(msg,2) end end
for _,n in ipairs({"scripts.galactic_dyson",
"scripts.razi_convergence",
"scripts.galactic_dyson_runtime","scripts.razi_journal_icons"}) do
  package.loaded[n]={stages={}}
end
package.loaded["scripts.razi_journal_data"]={quests={},by_id={}}
storage={}
settings={global={["razi-hide-spoilers"]={value=true}}}
local waiting={researched=false}
local f={index=5,platforms={},technologies={
  ["slp-dyson-sphere"]={researched=false,enabled=true,prerequisites={}},
  ["razi-convergence-commission"]={researched=false,enabled=true,prerequisites={waiting}},
  ["razi-intergalactic-transceiver-signal"]={researched=true,enabled=true,prerequisites={}}
}}
local p=require("scripts.razi_journal_projects")
check(p.visible(f,"platform"),"First project must always be visible")
check(not p.visible(f,"voyage"),"First voyage requires a built platform")
check(p.visible(f,"dyson") and p.visible(f,"transceiver"),"Unblocked projects visible")
check(not p.visible(f,"convergence"),"Finale still spoiler gated")
check(not p.valid("cargo") and not p.valid("recovery"),"Ledgers are not Projects")
f.platforms[1]={valid=true,hub={valid=true},force=f,name="One",
  scheduled_for_deletion=0,completed_trips=0}
check(p.visible(f,"voyage"),"Completed first platform reveals First Voyage")
waiting.researched=true
check(p.visible(f,"convergence"),"Research should reveal the finale")
settings.global["razi-hide-spoilers"].value=false
check(not p.visible(f,"cargo") and not p.visible(f,"recovery"),"Old project IDs retired")
print("Project spoiler gates passed")
