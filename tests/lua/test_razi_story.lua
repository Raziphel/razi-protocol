-- The storyline switch is inert until the optional record layer is enabled.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,message) if not ok then error(message,2) end end

local story=require("scripts.razi_story")
check(story.enabled()==false,"The story must ship switched off")
check(#story.records()==0,"No archive records while the story is off")
story.dispatch.on_research{research={name="automation"}}
story.dispatch.flush()
story.dispatch.forces_merged{source_index=1,destination_index=2}
story.dispatch.shipment({index=1},"victory")
check(rawget(_G,"storage")==nil,
 "Story notifications must not allocate save data while disabled")
check(package.loaded["scripts.razi_story_dispatch"]==nil
  and package.loaded["scripts.razi_journal_records"]==nil,
 "Story modules must not be loaded while the story is off")

story.configure(true)
check(story.enabled() and #story.records()>0,
 "Enabling the story must load its records and dispatch layer")
check(package.loaded["scripts.razi_story_dispatch"]
  and package.loaded["scripts.razi_journal_records"],
 "Enabling the story must make its runtime layer available")
story.configure(false)
check(not story.enabled() and #story.records()==0,
 "Disabling the story must hide its record layer again")
print("Razi story switch: disabled and enabled runtime layers passed")
