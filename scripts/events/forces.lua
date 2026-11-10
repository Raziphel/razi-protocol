-- Research and forces: concealed future technologies, Journal and story progress.
local razi_journal = require("scripts.journal.journal")
local platform_projects = require("scripts.projects.platform_projects")
local great_projects = require("scripts.projects.great_projects")
local deep_expedition = require("scripts.convergence.deep_space_expedition")
local story = require("lib.story")
local story_dispatch = story.dispatch
local spoiler_fog = require("scripts.journal.spoiler_fog")
local convergence = require("scripts.convergence.convergence")

local forces = {}

function forces.register(events)
	events:on_event(defines.events.on_research_finished, function(event)
		spoiler_fog.on_research(event)
		razi_journal.on_research(event)
		story_dispatch.on_research(event)
	end)
	events:on_event(defines.events.on_research_reversed, function(event)
		spoiler_fog.sync_force(event.research.force)
		spoiler_fog.defer(event.research.force)
	end)
	events:on_event(defines.events.on_technology_effects_reset, function()
		-- Rubia may reset its own placeholder technologies in this event,
		-- sometimes one tick later; recheck only those on the existing timer.
		spoiler_fog.defer_all()
	end)
	events:on_event(defines.events.on_forces_merged, function(event)
		platform_projects.forces_merged(event)
		great_projects.forces_merged(event)
		deep_expedition.forces_merged(event)
		convergence.forces_merged(event)
		story_dispatch.forces_merged(event)
		spoiler_fog.on_forces_merged(event)
		razi_journal.forces_merged(event)
	end)
	-- Razi-owned future techs are concealed per-force; gameplay progression
	-- remains based on the original technology prerequisites and research.
	events:on_event(defines.events.on_force_created, function(event)
		if event and event.force then
			spoiler_fog.sync_force(event.force)
			razi_journal.record_chapter_completions(event.force, (game.tick or 0) > 0)
		end
	end)
end

return forces
