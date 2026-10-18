-- Projects must never reveal the Convergence ahead of its real research.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,message) if not ok then error(message,2) end end
package.loaded["scripts.galactic_dyson"]={stages={}}
package.loaded["scripts.galactic_trade"]={}
package.loaded["scripts.razi_convergence"]={}
package.loaded["scripts.galactic_trade_catalog"]={}
package.loaded["scripts.galactic_dyson_runtime"]={}
package.loaded["scripts.razi_journal_icons"]={}
package.loaded["scripts.razi_journal_frontier"]={}
settings={global={["razi-hide-spoilers"]={value=true}}}
local not_yet={name="razi-preparation",researched=false}
local known={name="razi-done",researched=true}
local force={technologies={
  ["slp-dyson-sphere"]={researched=false,enabled=true,prerequisites={}},
  ["razi-convergence-commission"]={researched=false,enabled=true,
    prerequisites={["razi-preparation"]=not_yet}},
  ["razi-intergalactic-transceiver-signal"]={researched=true,enabled=true,
    prerequisites={["razi-done"]=known}},
  ["razi-frontier-recovery-charter"]={researched=false,enabled=false,
    prerequisites={["razi-preparation"]=not_yet}}
}}
local module=require("scripts.razi_journal_projects")
check(module.visible(force,"dyson"),
  "Reachable Dyson project must remain accessible")
check(not module.visible(force,"convergence"),
  "Convergence should not be revealed before its prerequisites")
check(not module.visible(force,"recovery"),
  "Disabled project research must not reveal hidden content")
check(module.visible(force,"transceiver"),
  "Completed research should remain visible")
check(not module.visible(force,"fake-project"),"Unknown project ID must be rejected")
not_yet.researched=true
check(module.visible(force,"convergence"),
  "The Convergence must be revealed when source prerequisites finish")
settings.global["razi-hide-spoilers"].value=false
check(module.visible(force,"recovery"),
  "Turning off the setting must immediately restore locked project previews")
check(module.visible(force,"cargo"),
  "Spoilers OFF should keep legacy project navigation")
print("Razi Journal project spoiler gates passed")
