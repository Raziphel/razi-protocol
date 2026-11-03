-- The Journal's per-player preferences: UI state only, kept in storage.
local M=require("scripts.journal.api")
local story=require("lib.story")
local projects=require("scripts.journal.projects")

local function pref(index)
  storage.razi_expedition_journal=storage.razi_expedition_journal or {}
  local value=storage.razi_expedition_journal[index]
  if not value then
    value={selected=nil,pinned=nil,tracker=false,
      chapter=nil,chapter_cover=false,filter="all",view="quests",project="platform",record=nil,query=""}
    storage.razi_expedition_journal[index]=value
  end
  value.filter=value.filter or "all"
  value.view=({quests=true,projects=true,archive=story.visible(index),
    systems=true})[value.view] and value.view or "quests"
  value.project=projects.valid(value.project) and value.project or "platform"
  value.query=value.query or ""
  value.story_unread=value.story_unread or {}
  value.story_alerts=value.story_alerts~=false
  value.archive_filter=({all=true,legacy=true,corporate=true,
    field=true})[value.archive_filter] and value.archive_filter or "all"
  value.chapter_cover=value.chapter_cover==true
  value.goal_expanded=value.goal_expanded==true
  value.reader_focus=value.reader_focus==true
  value.compact_index_open=value.compact_index_open==true
  -- Default to one Journal toolbar. Players can reveal the source buttons
  -- temporarily when they need Planet Express or Nexus native controls.
  value.native_controls_visible=value.native_controls_visible==true
  return value
end
M.preferences=pref

return pref
