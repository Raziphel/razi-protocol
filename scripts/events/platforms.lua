-- Space platforms: real hubs, completed trips and Deep Space visits.
local razi_journal = require("scripts.journal.journal")
local platform_projects = require("scripts.projects.platform_projects")
local great_projects = require("scripts.projects.great_projects")
local deep_expedition = require("scripts.convergence.deep_space_expedition")

local platforms = {}

-- Sparse native events record real platform hubs and completed trips.
-- A starter-pack placeholder without a built hub never earns completion.
local function record_platform(event)
	if not (event and event.platform) then
		return
	end
	local first = platform_projects.observe(event.platform)
	local major = great_projects.observe(event.platform)
	local visited = deep_expedition.observe_connected(event.platform)
	if first or major or visited then
		razi_journal.refresh_open()
	end
end

-- Construction events can fire hundreds of times per platform. Record
-- milestone/Ark state, but do not scan connected player characters on every
-- placed tile. State changes, boarding events and the 300-tick fallback
-- still capture legitimate Deep Space visits.
local function record_platform_construction(event)
	local platform = event and event.platform
	if not platform then
		return
	end
	local first = platform_projects.observe(platform)
	local major = great_projects.observe(platform)
	if first or major then
		razi_journal.refresh_open()
	end
end

function platforms.register(events)
	events:on_event(defines.events.on_space_platform_built_entity, record_platform_construction)
	events:on_event(defines.events.on_space_platform_built_tile, record_platform_construction)
	events:on_event(defines.events.on_space_platform_changed_state, record_platform)
	-- Reconcile platform state on the existing (infrequent) poll.
	events:on_nth_tick(300, function()
		local major = great_projects.flush_pending(game.forces)
		local visited = deep_expedition.observe_connected()
		if major or visited then
			razi_journal.refresh_open()
		end
	end)
	-- A player physically boarding a parked platform can also count as
	-- visiting that location. Remote View never grants the achievement.
	events:on_event({
		defines.events.on_player_changed_surface,
		defines.events.on_player_controller_changed
	}, function(event)
		local player = game.get_player(event.player_index)
		if player and deep_expedition.observe(player) then
			razi_journal.refresh_open()
		end
	end)
end

return platforms
