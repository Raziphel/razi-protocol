package.path="./?.lua;./?/init.lua;"..package.path
package.loaded["scripts.razi_journal_data"]={quests={},by_id={}}
local projects=require("scripts.razi_journal_projects")
local tracker=require("scripts.razi_platform_projects")
local original=require
require=function(name) error("Illegal GUI-time require: "..name,2) end
storage={}
local force={index=7,platforms={},technologies={}}
local ok,err=pcall(function()
  assert(projects.valid("platform") and projects.valid("voyage"))
  assert(not projects.valid("cargo") and not projects.valid("recovery"))
  assert(projects.visible(force,"platform"))
  local ship={valid=true,hub={valid=true},force=force,name="Anvil",
    scheduled_for_deletion=0,completed_trips=0}
  force.platforms[1]=ship
  assert(tracker.observe(ship))
  assert(projects.visible(force,"voyage"))
  ship.completed_trips=1
  assert(tracker.observe(ship) and tracker.snapshot(force).voyage)
end)
require=original
if not ok then error(err) end
print("Projects runtime require guard passed")
