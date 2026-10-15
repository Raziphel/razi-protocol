-- The Projects tab is rendered after Factorio finishes loading control.lua.
-- Runtime require() crashes the game, so block it while evaluating status.
package.path="./?.lua;./?/init.lua;"..package.path
local check=function(ok,msg) if not ok then error(msg,2) end end
rawset(_G,"prototypes",{technology={
  ["source-particulate-research"]={effects={{
    type="unlock-recipe",recipe="particulate-science-pack"
  }}}
}})
local projects=require("scripts.razi_journal_projects")
local real_require=require
require=function(name) error("Illegal runtime require: "..name,2) end
local research={
  ["source-particulate-research"]={researched=true},
  ["electromagnetic-robotics"]={researched=true},
  ["robotic-science-pack"]={researched=true},
  ["razi-frontier-recovery-charter"]={researched=true},
  ["discovered-athos"]={researched=true,prototype={effects={{
    type="unlock-space-location",space_location="athos"
  }}}},
  ["discovered-nulla"]={researched=true,prototype={effects={{
    type="unlock-space-location",space_location="nulla"
  }}}}
}
local ok,done,total=pcall(projects.recovery_status,{technologies=research})
require=real_require
check(ok,"Projects runtime must never invoke require()")
check(done==6 and total==6,"All source-owned Frontier Recovery milestones must remain visible")
print("Projects GUI late-require regression passed")
