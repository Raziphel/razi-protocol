-- Rubia's intentionally prerequisite-free ? technology placeholders.
-- Preserve real Rubia science unlocks and reassert display fog after the
-- source mod runs its one-tick technology synchronization.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,msg) if not ok then error(msg,2) end end
settings={global={
 ["razi-hide-spoilers"]={value=true},
 ["razi-hide-other-tech-spoilers"]={value=true}
}}
storage={}
local force={index=7,technologies={}}
local original={name="rubia-science-spread",valid=true,
  researched=false,enabled=false,visible_when_disabled=false,
  prerequisites={},successors={}}
local phantom={name="rubia-unknown-technology-rubia-science-spread",
  valid=true,researched=false,enabled=true,
  visible_when_disabled=false,prerequisites={},successors={}}
local starter={name="red-science-starter",valid=true,researched=false,
  enabled=true,visible_when_disabled=true,prerequisites={},successors={}}
local reached={name="already-done",valid=true,researched=true,
  enabled=true,visible_when_disabled=true,prerequisites={},successors={}}
force.technologies[original.name]=original
force.technologies[phantom.name]=phantom
force.technologies[starter.name]=starter
force.technologies[reached.name]=reached
for _,tech in pairs(force.technologies) do tech.force=force end
game={tick=0,forces={[7]=force}}
local fog=require("scripts.razi_spoiler_fog")
check(fog.is_rubia_placeholder(phantom),"Rubia placeholder prefix is not detected")
check(not fog.is_rubia_placeholder(original),"Rubia's real tech is not a ? marker")
fog.sync_all()
check(not phantom.enabled and not phantom.visible_when_disabled,
 "Rubia's unknown placeholder must be hidden despite no prerequisites")
check(starter.enabled and reached.enabled,
 "Real starter science and researched technology must remain visible")
check(not original.enabled,"Rubia's underlying unavailable tech must remain disabled")
-- Simulate Rubia re-enabling ? during a source sync, after our own hook.
phantom.enabled=true
fog.defer(force)
game.tick=0
fog.flush()
check(phantom.enabled,"Deferred reassertion must not run before its due tick")
game.tick=30
fog.flush()
check(not phantom.enabled and not phantom.visible_when_disabled,
 "Deferred reassertion must hide Rubia's second-wave placeholders")
check(storage.razi_rubia_spoiler_pending==nil,
 "One-time deferred synchronization must fully drain")
-- Source mod legitimately reveals real tech and disables its placeholder.
original.enabled=true
phantom.enabled=false
fog.sync_force(force)
check(not phantom.enabled,
 "Restoring a stale ? marker must never re-enable Rubia's obsolete disguise")
-- Return to a hidden Rubia stage then disable the broader fog independently.
original.enabled=false
phantom.enabled=true
fog.sync_force(force)
check(not phantom.enabled,"Unreached Rubia disguise should be re-hidden")
settings.global["razi-hide-other-tech-spoilers"].value=false
fog.sync_force(force)
check(phantom.enabled,"Turning off only expanded research fog must restore Rubia's marker")
check(starter.enabled and reached.enabled,
 "Source science and completed research must not be affected by settings")
-- Main Hide Spoilers toggled off also restores all managed Rubia rows.
settings.global["razi-hide-other-tech-spoilers"].value=true
fog.sync_force(force)
settings.global["razi-hide-spoilers"].value=false
fog.sync_force(force)
check(phantom.enabled and starter.enabled,
 "Turning off the main spoiler mode must restore original source visibility")
print("Rubia placeholder, source-sync race and reversible research fog passed")
