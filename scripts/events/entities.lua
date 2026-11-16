-- Built and removed entities: the active transceiver opens the transceiver gate, the Archive relay refreshes the Journal,
-- a removed Cerys radiative tower takes its lamp with it.
local razi_journal = require("scripts.journal.journal")
local cerys_tower_lamp = require("scripts.compatibility.Cerys-Moon-of-Fulgora.tower_lamp")

local entities = {}

local transceiver_gate_technology = "razi-intergalactic-transceiver-signal"
local active_transceiver_name = "kr-activated-intergalactic-transceiver"
local archive_relay_name = "razi-archive-relay"
local relay_refresh_pending = "razi_archive_relay_refresh_pending"
local transceiver_build_events = {
	defines.events.on_built_entity,
	defines.events.on_robot_built_entity,
	defines.events.on_entity_cloned,
	defines.events.script_raised_built,
	defines.events.script_raised_revive
}
local relay_removed_events = {
	defines.events.on_player_mined_entity,
	defines.events.on_robot_mined_entity,
	defines.events.on_entity_died,
	defines.events.script_raised_destroy
}

local function unlock_transceiver_gate(force)
	if not (force and force.valid) then
		return
	end

	local technology = force.technologies[transceiver_gate_technology]
	if technology and not technology.researched then
		technology.enabled = true
		technology.researched = true
	end
end

local function check_entity(entity)
	if entity and entity.valid and entity.name == active_transceiver_name then
		unlock_transceiver_gate(entity.force)
	end
end

function entities.check_existing_transceivers()
	if not game then
		return
	end

	-- get_entity_count is O(1): the engine keeps the counts, so no surface search.
	for _, force in pairs(game.forces) do
		local technology = force.technologies[transceiver_gate_technology]
		-- Most forces already have the gate. Skip even the O(1) count
		-- after research, including the 10-minute safeguard poll.
		if technology and not technology.researched
			and force.get_entity_count(active_transceiver_name) > 0 then
			unlock_transceiver_gate(force)
		end
	end
end

local function on_entity_built(event)
	local entity = event.entity or event.destination or event.created_entity
	check_entity(entity)
	if entity and entity.valid and entity.name == archive_relay_name then
		razi_journal.refresh_open()
	end
end

local function on_archive_relay_removed(event)
	local entity = event.entity
	if entity and entity.valid and entity.name == archive_relay_name then
		storage[relay_refresh_pending] = true
	end
end

function entities.register(events)
	-- K2SO raises a build event when the charged transceiver becomes the active one.
	-- The periodic check covers old saves and any weird script ordering.
	events:on_nth_tick(600, entities.check_existing_transceivers)
	events:on_event(transceiver_build_events, on_entity_built)
	events:on_event(relay_removed_events, on_archive_relay_removed)
	-- Without Cerys no tower filters exist and nothing is registered.
	if #cerys_tower_lamp.filters() > 0 then
		events:on_event(relay_removed_events, cerys_tower_lamp.on_tower_removed)
		events:on_event(defines.events.on_space_platform_mined_entity, cerys_tower_lamp.on_tower_removed)
	end
end

-- Filters must be set after the registration they belong to. They apply to
-- every handler on these events, so a feature that needs other built
-- entities must widen this filter rather than add its own registration.
function entities.set_filters()
	local build_filter = {
		{filter = "name", name = active_transceiver_name},
		{filter = "name", name = archive_relay_name}
	}
	for _, event_id in ipairs(transceiver_build_events) do
		script.set_event_filter(event_id, build_filter)
	end
	local relay_filter = {{filter = "name", name = archive_relay_name}}
	local tower_filters = cerys_tower_lamp.filters()
	for _, tower_filter in ipairs(tower_filters) do
		relay_filter[#relay_filter + 1] = tower_filter
	end
	for _, event_id in ipairs(relay_removed_events) do
		script.set_event_filter(event_id, relay_filter)
	end
	if #tower_filters > 0 then
		script.set_event_filter(defines.events.on_space_platform_mined_entity, tower_filters)
	end
end

return entities
