local galactic_operations = require("scripts.galactic_operations")
local razi_journal = require("scripts.razi_journal")
local razi_discord_presence = require("scripts.razi_discord_presence")
local transceiver_gate_technology = "razi-intergalactic-transceiver-signal"
local active_transceiver_name = "kr-activated-intergalactic-transceiver"
local nexus_visibility_technologies = {
	"element882",
	"ionit-liquefaction",
	"atomacer",
	"matter-stabilization",
	"rare-metal-refining",
	"nexus-sand-processing",
	"promethium-882-research",
	"diamond-processing",
	"omega-components",
	"singularity-crystal-assembling",
	"photon-electronics",
	"antimatter-science-pack",
	"antimatter-produktion",
	"photon-stream-thruster",
	"warp-drive-engine",
	"fusion-power-mk2",
	"photon-enrichment-chamber-mk2",
	"omega-substation",
	"omega-tank",
	"omega-accumulator",
	"omega-beacon",
	"zero-point-energy-engine-core",
	"zero-point-energy-engine-injector-left",
	"zero-point-energy-engine-injector-up",
	"zero-point-energy-engine-injector-right",
	"zpe-core-limit-1",
	"zpe-core-limit-2",
	"zpe-core-limit-3",
	"planet-nexus-scanning",
	"advanced-magnetic-shielding",
	"advanced-stable-electronic",
	"advanced-stronger-armor",
	"planet-discovery-nexus",
	"rare-element-productivity",
	"high-energetic-photonen-fluid-productivity",
	"photonen-energy-fluid-productivity",
	"zpe-core-efficiency",
	"omega-module-mk1",
	"omega-module-mk2",
	"omega-module-mk3",
	"omega-module-mk4",
	"omega-quality-module",
	"starmap-mapping",
	"warp-drive-frame",
	"exotic-matter-containment-fields-generator",
	"gravity-fields-generator",
	"antimatter-containment-fields-generator",
	"singularity-core",
	"omega-stacking-stage1",
	"omega-stacking-stage2",
	"omega-stacking-stage3",
	"omega-stacking-stage4",
	"omega-accumulator-upgrade1",
	"omega-accumulator-upgrade2",
	"omega-train",
	"nexus-storm-prediction"
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

local function check_existing_transceivers()
	if not game then
		return
	end

	-- get_entity_count is O(1): the engine keeps the counts, so no surface search.
	for _, force in pairs(game.forces) do
		if force.get_entity_count(active_transceiver_name) > 0 then
			unlock_transceiver_gate(force)
		end
	end
end

local function repair_nexus_technology_visibility(event)
	-- Repair the legacy Nexus migration only when Nexus itself changes.
	-- A normal Razi update or another mod's configuration change must not
	-- override technology gates deliberately disabled by another mod.
	local changes = event and event.mod_changes
	if not (changes and (changes["Nexus"] or changes["Nexus-Updated"])) then
		return
	end

	if not (script.active_mods["Nexus"] or script.active_mods["Nexus-Updated"]) then
		return
	end

	for _, force in pairs(game.forces) do
		for _, technology_name in ipairs(nexus_visibility_technologies) do
			local technology = force.technologies[technology_name]
			local prototype = technology and technology.prototype
			-- Respect disable/hidden flags from the final loaded prototypes.
			if technology and not technology.researched and not technology.enabled
				and prototype and prototype.enabled and not prototype.hidden then
				technology.enabled = true
			end
		end
	end
end

local function on_entity_built(event)
	check_entity(event.entity or event.destination or event.created_entity)
end

-- K2SO raises a build event when the charged transceiver becomes the active one.
-- The periodic check covers old saves and any weird script ordering.
script.on_init(function()
  check_existing_transceivers()
  galactic_operations.sync_all_map_buttons()
  razi_journal.sync_all()
end)
script.on_configuration_changed(function(event)
	check_existing_transceivers()
	repair_nexus_technology_visibility(event)
  galactic_operations.sync_all_map_buttons()
  razi_journal.sync_all()
end)
-- Export at most once per 15 game seconds; disabled players do no work.
script.on_nth_tick(900, razi_discord_presence.write)
script.on_event(defines.events.on_string_translated,function(event)
  razi_discord_presence.on_string_translated(event)
  galactic_operations.on_string_translated(event)
end)
script.on_event(defines.events.on_runtime_mod_setting_changed,
  razi_discord_presence.on_setting_changed)

script.on_nth_tick(600, function()
  check_existing_transceivers()
  -- Repaint only an open Nexus Journal or pinned boss objective. Native
  -- Nexus Bosses remains the only authority for all nine victories.
  razi_journal.refresh_nexus_visible()
end)
-- The engine has no starmap-open event. Check only the small per-player
-- render/controller state twice per second; never enumerate planets here.
script.on_nth_tick(30, function(event)
  galactic_operations.sync_all_map_buttons(event)
  razi_journal.flush_research_refreshes()
end)
script.on_event({
	defines.events.on_built_entity,
	defines.events.on_robot_built_entity,
	defines.events.on_entity_cloned,
	defines.events.script_raised_built,
	defines.events.script_raised_revive
}, on_entity_built)


-- Galactic Operations is launched from its floating map button.
-- The optional Ctrl+Shift+G input works only while viewing the map.
script.on_event("razi-journal-toggle",function(event)
  local player=game.get_player(event.player_index)
  if player then razi_journal.toggle(player) end
end)
script.on_event(defines.events.on_research_finished,razi_journal.on_research)

script.on_event("razi-galactic-operations-input",function(event)
  local player=game.get_player(event.player_index)
  if player then galactic_operations.toggle(player) end
end)
script.on_event(defines.events.on_player_controller_changed,
  galactic_operations.map_context_changed)
script.on_event(defines.events.on_player_joined_game,function(event)
  galactic_operations.map_context_changed(event)
  local player=game.get_player(event.player_index)
  if player then razi_journal.sync(player) end
end)
script.on_event(defines.events.on_player_created,function(event)
  galactic_operations.map_context_changed(event)
  local player=game.get_player(event.player_index)
  if player then razi_journal.sync(player) end
end)
script.on_event(defines.events.on_gui_click,function(event)
  galactic_operations.gui_click(event)
  razi_journal.gui_click(event)
end)
script.on_event(defines.events.on_gui_text_changed,function(event)
  galactic_operations.text_changed(event)
  razi_journal.text_changed(event)
end)
script.on_event(defines.events.on_gui_selection_state_changed,function(event)
  galactic_operations.selection_changed(event)
  razi_journal.selection_changed(event)
end)
script.on_event(defines.events.on_gui_checked_state_changed,
  galactic_operations.checkbox_changed)
script.on_event(defines.events.on_gui_closed,function(event)
  galactic_operations.gui_closed(event)
  razi_journal.gui_closed(event)
end)
script.on_event(defines.events.on_player_display_resolution_changed,function(event)
  galactic_operations.on_display_changed(event)
  razi_journal.on_display_changed(event)
end)
script.on_event(defines.events.on_player_display_scale_changed,function(event)
  galactic_operations.on_display_changed(event)
  razi_journal.on_display_changed(event)
end)
script.on_event(defines.events.on_player_removed,function(event)
  galactic_operations.on_removed(event)
  razi_journal.on_removed(event.player_index)
  razi_discord_presence.on_player_removed(event)
end)
