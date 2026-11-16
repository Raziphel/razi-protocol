-- The Journal: periodic upkeep, hotkey, settings and GUI events.
local razi_journal = require("scripts.journal.journal")
local search_names = require("scripts.journal.search_names")
local story = require("lib.story")
local story_dispatch = story.dispatch
local spoiler_fog = require("scripts.journal.spoiler_fog")
local welcome = require("scripts.story.welcome")
local victory_guard = require("scripts.convergence.victory_guard")

local journal = {}

function journal.register(events)
	events:on_nth_tick(600, function()
		-- Other mods may restore their win triggers during a save migration.
		victory_guard.enforce()
		-- Repaint only an open Nexus Journal or pinned boss objective. Native
		-- Nexus Bosses remains the only authority for all nine victories.
		razi_journal.refresh_nexus_visible()
		razi_journal.refresh_chapter_completions()
	end)
	-- No work when the Systems folio is closed; live labels only, no redraw.
	events:on_nth_tick(120, function()
		razi_journal.refresh_systems_visible()
		razi_journal.refresh_research_visible()
	end)
	events:on_nth_tick(30, function()
		if storage.razi_archive_relay_refresh_pending then
			razi_journal.refresh_open()
			storage.razi_archive_relay_refresh_pending = nil
		end
		razi_journal.flush_research_refreshes()
		story_dispatch.flush()
		welcome.flush()
		spoiler_fog.flush()
	end)

	events:on_event("razi-journal-toggle", function(event)
		local player = game.get_player(event.player_index)
		if player then
			razi_journal.toggle(player)
		end
	end)
	events:on_event(defines.events.on_runtime_mod_setting_changed, function(event)
		if event and (event.setting == "razi-hide-spoilers" or event.setting == "razi-hide-other-tech-spoilers") then
			spoiler_fog.sync_all()
			spoiler_fog.defer_all()
			if event.setting == "razi-hide-spoilers" then
				razi_journal.refresh_open()
			end
		elseif event and (event.setting == "razi-journal-show-button" or event.setting == "razi-journal-show-tracker") then
			local player = game.get_player(event.player_index)
			if player then
				razi_journal.sync(player)
			end
		end
	end)
	events:on_event(defines.events.on_gui_click, function(event)
		razi_journal.gui_click(event)
	end)
	events:on_event(defines.events.on_gui_text_changed, function(event)
		razi_journal.text_changed(event)
	end)
	events:on_event(defines.events.on_string_translated, function(event)
		if search_names.on_string_translated(event) then
			razi_journal.search_names_ready(event.player_index)
		end
	end)
	events:on_event(defines.events.on_gui_selection_state_changed, function(event)
		razi_journal.selection_changed(event)
	end)
	events:on_event(defines.events.on_gui_elem_changed, function(event)
		razi_journal.elem_changed(event)
	end)
	events:on_event(defines.events.on_gui_closed, function(event)
		razi_journal.gui_closed(event)
	end)
	events:on_event({
		defines.events.on_player_display_resolution_changed,
		defines.events.on_player_display_scale_changed
	}, function(event)
		razi_journal.on_display_changed(event)
	end)
end

return journal
