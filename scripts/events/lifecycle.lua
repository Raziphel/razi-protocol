-- Save lifecycle: what runs when a game starts and when mods or their versions change.
local entities = require("scripts.events.entities")
local razi_prepared_2x = require("scripts.migration.prepared_2x")
local enemy_surfaces = require("scripts.enemies.surfaces")
local razi_journal = require("scripts.journal.journal")
local search_names = require("scripts.journal.search_names")
local platform_projects = require("scripts.projects.platform_projects")
local deep_expedition = require("scripts.convergence.deep_space_expedition")
local spoiler_fog = require("scripts.journal.spoiler_fog")
local convergence = require("scripts.convergence.convergence")
local victory_guard = require("scripts.convergence.victory_guard")
local nexus_technology_visibility = require("scripts.compatibility.Nexus-Updated.technology_visibility")

local infinite_research = require("scripts.research.infinite_research")

local lifecycle = {}

-- The Journal reads research and the state of the force; its own tables in
-- storage are created here and in the handlers that need them, never in on_load.
local function prepare_journal_state()
	victory_guard.prepare()
	spoiler_fog.sync_all()
	spoiler_fog.defer_all()
	convergence.restore_pending()
	-- Other mods may restore their win triggers during a save migration.
	victory_guard.enforce()
end

local function start_journal()
	for _, force in pairs(game.forces) do
		platform_projects.snapshot(force)
	end
	deep_expedition.observe_connected()
	razi_journal.initialize_chapter_completions()
	razi_journal.sync_all()
end

function lifecycle.register(events)
	events:on_init(prepare_journal_state)
	events:on_init(entities.check_existing_transceivers)
	-- Surfaces that exist already get the switched-off nests of their planet for their new chunks.
	events:on_init(enemy_surfaces.apply)
	events:on_init(start_journal)
	events:on_init(infinite_research.sync_all)
	events:on_configuration_changed(function(event)
		prepare_journal_state()
		entities.check_existing_transceivers()
		enemy_surfaces.apply()
		for _, force in pairs(game.forces) do
			platform_projects.snapshot(force)
		end
		deep_expedition.observe_connected()
		-- Existing saves may have researched older Convergence stages before
		-- their new manufacturing unlocks were introduced.
		if event and event.mod_changes and event.mod_changes["razi-protocol"] then
			for _, force in pairs(game.forces) do
				convergence.repair_recipe_unlocks(force)
			end
		end
		nexus_technology_visibility.repair(event)
		razi_prepared_2x.on_configuration_changed(event)
		-- Names may have changed with the mods; the journal asks again when drawn.
		search_names.reset()
		infinite_research.sync_all()
		razi_journal.initialize_chapter_completions()
		razi_journal.sync_all()
	end)
end

return lifecycle
