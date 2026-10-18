local razi_journal = require("scripts.razi_journal")
local story_dispatch = require("scripts.razi_story_dispatch")
local spoiler_fog = require("scripts.razi_spoiler_fog")
local razi_safe_cheat = require("scripts.razi_safe_cheat")
local welcome = require("scripts.razi_welcome")
local convergence = require("scripts.razi_convergence")
local convergence_audit = require("scripts.razi_convergence_audit")
local Events = require("__razi_lib__/runtime/events")
local victory_guard = require("scripts.razi_victory_guard")
local quality_asteroids = require("scripts.razi_quality_asteroids")
local events = Events.new()
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
		local technology=force.technologies[transceiver_gate_technology]
		-- Most forces already have the gate. Avoid even an O(1) count
		-- after research, including the 10-minute safeguard poll.
		if technology and not technology.researched
			and force.get_entity_count(active_transceiver_name)>0 then
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

-- K2SO's native transceiver may also declare victory when activated.
-- Razi uses that same activation to unlock Deep Space instead. Suppress
-- only the source victory, never its charge or entity-conversion logic.
local function retire_operations(player)
  if not (player and player.valid) then return end
  for _,name in ipairs({"razi_galactic_operations","razi_ops_map_anchor"}) do
    local old=player.gui.screen[name]
    if old and old.valid then old.destroy() end
  end
end
local function retire_connected_operations()
  for _,player in pairs(game.connected_players or {}) do retire_operations(player) end
end
local function preserve_deep_space_campaign()
  return victory_guard.enforce()
end

-- K2SO raises a build event when the charged transceiver becomes the active one.
-- The periodic check covers old saves and any weird script ordering.
events:on_init(function()
  spoiler_fog.sync_all()
  spoiler_fog.defer_all()
  convergence.restore_pending()
  preserve_deep_space_campaign()
  check_existing_transceivers()
  retire_connected_operations()
  razi_journal.sync_all()
end)
events:on_configuration_changed(function(event)
  spoiler_fog.sync_all()
  spoiler_fog.defer_all()
	convergence.restore_pending()
	preserve_deep_space_campaign()
	check_existing_transceivers()
	-- Existing saves may have researched older Convergence stages before
	-- their new manufacturing unlocks were introduced.
	if event and event.mod_changes
	  and event.mod_changes["razi-protocol"] then
		for _,force in pairs(game.forces) do
			convergence.repair_recipe_unlocks(force)
		end
	end
	repair_nexus_technology_visibility(event)
  retire_connected_operations()
  razi_journal.sync_all()
end)
-- An idle Convergence has no pending work. Active force transmissions
-- advance once per second and only redraw their open final panels.
events:on_nth_tick(60,function(event)
  local changed=convergence.advance(event.tick)
  if changed then
    for _,index in ipairs(changed) do
      local force=game.forces[index]
      if force then razi_journal.refresh_convergence(force) end
    end
  end
end)
-- Spread debug research across ticks instead of freezing the whole modpack.
commands.add_command("razi-cheat",
  {"razi-cheat.help"},
  razi_safe_cheat.command)
commands.add_command("razi-welcome",
  {"razi-welcome.command-help"},welcome.command)
-- Explicit diagnostic only. Never scans recipes, labs or source mods on ticks.
commands.add_command("razi-audit",
  {"razi-audit.help"},convergence_audit.command)
events:on_nth_tick(6, razi_safe_cheat.tick)
events:on_nth_tick(600, function()
  -- Other mods may restore their win triggers during a save migration.
  -- Three small optional remote checks every ten seconds, no world scans.
  preserve_deep_space_campaign()
  check_existing_transceivers()
  -- Repaint only an open Nexus Journal or pinned boss objective. Native
  -- Nexus Bosses remains the only authority for all nine victories.
  razi_journal.refresh_nexus_visible()
end)
events:on_nth_tick(30, function()
  razi_journal.flush_research_refreshes()
  story_dispatch.flush()
  welcome.flush()
  spoiler_fog.flush()
end)
events:on_event({
	defines.events.on_built_entity,
	defines.events.on_robot_built_entity,
	defines.events.on_entity_cloned,
	defines.events.script_raised_built,
	defines.events.script_raised_revive
}, on_entity_built)


-- The old Galactic Operations hotkey now opens the Journal's Projects view.
-- Keep the existing input identifier so player key bindings survive.
events:on_event("razi-journal-toggle",function(event)
  local player=game.get_player(event.player_index)
  if player then razi_journal.toggle(player) end
end)
events:on_event(defines.events.on_research_finished,function(event)
  spoiler_fog.on_research(event)
  razi_journal.on_research(event)
  story_dispatch.on_research(event)
end)
events:on_event(defines.events.on_research_reversed,function(event)
  spoiler_fog.sync_force(event.research.force)
  spoiler_fog.defer(event.research.force)
end)
events:on_event(defines.events.on_technology_effects_reset,function()
  -- Rubia may reset its own placeholder technologies in this event,
  -- sometimes one tick later; recheck only those on the existing timer.
  spoiler_fog.defer_all()
end)
events:on_event(defines.events.on_forces_merged,function(event)
  convergence.forces_merged(event)
  story_dispatch.forces_merged(event)
  spoiler_fog.on_forces_merged(event)
end)
-- Razi-owned future techs are concealed per-force; gameplay progression
-- remains based on the original technology prerequisites and research.
events:on_event(defines.events.on_force_created,function(event)
  if event and event.force then spoiler_fog.sync_force(event.force) end
end)
events:on_event(defines.events.on_runtime_mod_setting_changed,function(event)
  if event and (event.setting=="razi-hide-spoilers"
    or event.setting=="razi-hide-other-tech-spoilers") then
    spoiler_fog.sync_all()
    spoiler_fog.defer_all()
    if event.setting=="razi-hide-spoilers" then
      razi_journal.refresh_open()
    end
  end
end)
-- Only carrier asteroid creation events do work; no per-tick asteroid scan.
events:on_event(defines.events.on_script_trigger_effect,
  quality_asteroids.on_script_trigger_effect)
-- /cheat is a built-in command and cannot be replaced. This notification
-- runs only if the engine gets far enough to emit its console event.
events:on_event(defines.events.on_console_command,razi_safe_cheat.warn_builtin)

events:on_event("razi-galactic-operations-input",function(event)
  local player=game.get_player(event.player_index)
  if player then razi_journal.open_project(player) end
end)
events:on_event(defines.events.on_player_joined_game,function(event)
  local player=game.get_player(event.player_index)
  if player then
    retire_operations(player)
    razi_journal.sync(player)
    welcome.on_player_joined(player)
  end
end)
events:on_event(defines.events.on_player_created,function(event)
  local player=game.get_player(event.player_index)
  if player then
    retire_operations(player)
    razi_journal.sync(player)
    welcome.on_player_created(player)
  end
end)
events:on_event(defines.events.on_gui_click,function(event)
  razi_journal.gui_click(event)
end)
events:on_event(defines.events.on_gui_text_changed,function(event)
  razi_journal.text_changed(event)
end)
events:on_event(defines.events.on_gui_selection_state_changed,function(event)
  razi_journal.selection_changed(event)
end)
events:on_event(defines.events.on_gui_closed,function(event)
  razi_journal.gui_closed(event)
end)
events:on_event(defines.events.on_player_display_resolution_changed,function(event)
  razi_journal.on_display_changed(event)
end)
events:on_event(defines.events.on_player_display_scale_changed,function(event)
  razi_journal.on_display_changed(event)
end)
events:on_event(defines.events.on_player_removed,function(event)
  razi_journal.on_removed(event.player_index)
  razi_safe_cheat.on_player_removed(event.player_index)
  welcome.on_player_removed(event.player_index)
end)

events:install()
