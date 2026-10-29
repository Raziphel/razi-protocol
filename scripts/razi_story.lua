-- Single switch for the Expedition Journal storyline.
--
-- The journal, its quests, projects and the Convergence finale are game
-- mechanics. The story layer is prose on top of them: the Archive tab,
-- chapter covers, story paragraphs, record notices, the welcome voice and
-- the Convergence epilogue. While the switch is off none of that is
-- created, called or shown, and the mechanics behave exactly as before.
--
-- Save data is untouched either way. Quest, chapter, act and record IDs stay
-- as they are, and the `story_*` player fields and the `razi_story_*`
-- storage tables are kept, so turning the story on later needs no migration.
--
-- Turn the story on by changing ENABLED below. Factorio forbids require()
-- inside events, so everything the story needs is loaded here, once.
local ENABLED=false

local M={}
local enabled_flag=false
local record_list={}
local dispatch_impl

local EMPTY={}

function M.enabled() return enabled_flag end

-- Archive entries (legacy transmissions plus corporate and field records).
function M.records() return record_list end

-- Record notices in chat. Every call is a no-op while the story is off.
M.dispatch={
  on_research=function(event)
    if dispatch_impl then dispatch_impl.on_research(event) end
  end,
  flush=function()
    if dispatch_impl then dispatch_impl.flush() end
  end,
  forces_merged=function(event)
    if dispatch_impl then dispatch_impl.forces_merged(event) end
  end,
  shipment=function(force,id)
    if dispatch_impl then dispatch_impl.shipment(force,id) end
  end
}

-- Applies the switch. Runs once at load; tests call it to try both states.
function M.configure(value)
  enabled_flag=value==true
  if enabled_flag then
    record_list=require("scripts.razi_journal_records")
    dispatch_impl=require("scripts.razi_story_dispatch")
  else
    record_list=EMPTY
    dispatch_impl=nil
  end
end

M.configure(ENABLED)
return M
