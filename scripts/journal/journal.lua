-- The Protocol Codex reads research progress from each force.
-- Player storage is just UI preferences, so an older save can reopen it.
--
-- This file is the entry point of the Journal. The code lives in the parts next
-- to it; each part adds its functions to the public table of api.lua, and this
-- file loads them all and returns that table. Factorio forbids require() inside
-- events, so every part is loaded here, at load time.
local M=require("scripts.journal.api")
require("scripts.journal.data")
local story=require("lib.story")
-- The Archive records and the record notices, loaded here for the story.
story.attach(require("scripts.story.records"),
  require("scripts.story.dispatch"))
local themes=require("scripts.journal.themes")
local widgets=require("scripts.journal.widgets")
M.chapter_theme=themes.get
M.chapter_icon=themes.icon

M.FRAME=widgets.FRAME
M.TOP=widgets.TOP
M.TRACKER=widgets.TRACKER

-- The parts, each after the parts it uses.
require("scripts.journal.preferences")
require("scripts.journal.quest_state")
require("scripts.journal.quest_art")
require("scripts.journal.tracker")
require("scripts.journal.archive_view")
require("scripts.journal.dossier")
require("scripts.journal.chapter_cover")
require("scripts.journal.navigator")
require("scripts.journal.window")
require("scripts.journal.reader_update")
require("scripts.journal.refresh")
require("scripts.journal.gui_events")
return M
