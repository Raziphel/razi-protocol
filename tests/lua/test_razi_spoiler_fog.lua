-- Research-tree spoiler fog: Razi-only, reversible, no polling.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,message) if not ok then error(message,2) end end
local setup={global={["razi-hide-spoilers"]={value=true}}}
settings=setup
storage={}
local source={name="automation",enabled=true,researched=false,
  visible_when_disabled=true,prerequisites={},successors={}}
local stage={name="razi-stellar-secret",enabled=true,researched=false,
  visible_when_disabled=true,prototype={hidden=false},
  prerequisites={automation=source},successors={}}
local post={name="razi-final-secret",enabled=true,researched=false,
  visible_when_disabled=true,prototype={hidden=false},
  prerequisites={["razi-stellar-secret"]=stage},successors={}}
local foreign={name="foreign-secret",enabled=true,researched=false,
  visible_when_disabled=true,prerequisites={automation=source},successors={}}
local intentionally_disabled={name="razi-source-disabled",enabled=false,
  researched=false,visible_when_disabled=true,
  prerequisites={automation=source},successors={}}
local completed={name="razi-already-done",enabled=true,researched=true,
  visible_when_disabled=true,prerequisites={automation=source},successors={}}
source.successors={stage,foreign,intentionally_disabled}
stage.successors={post}
local force={index=3,technologies={
  automation=source,["razi-stellar-secret"]=stage,
  ["razi-final-secret"]=post,["foreign-secret"]=foreign,
  ["razi-source-disabled"]=intentionally_disabled,
  ["razi-already-done"]=completed}}
game={forces={[3]=force}}
local fog=require("scripts.razi_spoiler_fog")
fog.sync_all()
check(not stage.enabled and not stage.visible_when_disabled,
  "Unresearched future Razi tech must be concealed")
check(not post.enabled,"Multi-level Razi research must remain hidden")
check(foreign.enabled and foreign.visible_when_disabled,
  "Third-party technologies must never be changed")
check(not intentionally_disabled.enabled and
  not intentionally_disabled.visible_when_disabled,
  "Disabled future Razi tech must be concealed without enabling it")
check(completed.enabled,"Completed Razi technology must remain visible")
check(storage.razi_spoiler_technologies[3]["razi-stellar-secret"],
  "Fog ownership must be stored for reversal")
source.researched=true
source.force=force
fog.on_research{research=source}
check(stage.enabled and stage.visible_when_disabled,
  "Research must immediately reveal Razi successors")
check(not post.enabled,"Descendants must remain concealed until their own parent")
check(not intentionally_disabled.enabled,
  "Originally disabled source-owned technology must not be enabled")
stage.researched=true
stage.force=force
fog.on_research{research=stage}
check(post.enabled and post.visible_when_disabled,
  "Second-stage successors must become available")
source.researched=false
stage.researched=false
fog.sync_force(force)
check(not stage.enabled and not post.enabled,
  "Returning to earlier save state should reapply fog")
setup.global["razi-hide-spoilers"].value=false
fog.sync_all()
check(stage.enabled and post.enabled,
  "Turning off spoilers must restore original research enablement")
check(stage.visible_when_disabled and post.visible_when_disabled,
  "Previously saved tech visibility must be restored")
check(foreign.enabled and not intentionally_disabled.enabled,
  "Disabling fog must never modify other mods' progression")
check(not storage.razi_spoiler_technologies[3],
  "Restore must clear only our fog ownership table")
-- Broader future-research concealment is independently reversible.
-- Keep every currently researchable technology and every completed science.
local foreign_parent={name="foreign-parent",researched=false,
  enabled=true,visible_when_disabled=true,prerequisites={},successors={}}
local distant={name="red-science-future",enabled=true,researched=false,
  visible_when_disabled=true,prerequisites={parent=foreign_parent},
  successors={}}
local externally_disabled={name="foreign-disabled-visible",enabled=false,
  researched=false,visible_when_disabled=true,
  prerequisites={parent=foreign_parent},successors={}}
local available={name="foreign-available",enabled=true,researched=false,
  visible_when_disabled=true,prerequisites={},successors={}}
foreign_parent.successors={distant,externally_disabled}
force.technologies[foreign_parent.name]=foreign_parent
force.technologies[distant.name]=distant
force.technologies[externally_disabled.name]=externally_disabled
force.technologies[available.name]=available
setup.global["razi-hide-spoilers"].value=true
setup.global["razi-hide-other-tech-spoilers"]={value=true}
fog.sync_force(force)
check(not distant.enabled and not distant.visible_when_disabled,
  "Extended research setting must hide future third-party technology")
check(not externally_disabled.enabled and not externally_disabled.visible_when_disabled,
  "Disabled but visible red technology must be concealed")
check(available.enabled and available.visible_when_disabled,
  "Currently researchable science must never be hidden")
setup.global["razi-hide-other-tech-spoilers"].value=false
fog.sync_force(force)
check(distant.enabled and distant.visible_when_disabled,
  "Turning off broader fog must restore original external technology")
check(not externally_disabled.enabled and externally_disabled.visible_when_disabled,
  "Reversal must not accidentally enable a disabled third-party technology")
setup.global["razi-hide-other-tech-spoilers"].value=true
fog.sync_force(force)
foreign_parent.researched=true
foreign_parent.force=force
fog.on_research{research=foreign_parent}
check(distant.enabled and distant.visible_when_disabled,
  "Completed prerequisite must immediately reveal future external technology")
check(not externally_disabled.enabled and externally_disabled.visible_when_disabled,
  "Source-mod disabled technology must stay disabled after prerequisites")
setup.global["razi-hide-spoilers"].value=false
fog.sync_force(force)
check(stage.enabled and post.enabled and not intentionally_disabled.enabled,
  "Global switch restores Razi research without breaking intentionally disabled tech")
print("Razi-owned technology spoiler fog and safe restoration passed")
