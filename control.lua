local razi_journal = require("scripts.razi_journal")
local platform_projects = require("scripts.razi_platform_projects")
local great_projects = require("scripts.razi_great_projects")
local deep_expedition = require("scripts.razi_deep_space_expedition")
local story_dispatch = require("scripts.razi_story_dispatch")
local spoiler_fog = require("scripts.razi_spoiler_fog")
local razi_safe_cheat = require("scripts.razi_safe_cheat")
local welcome = require("scripts.razi_welcome")
local convergence = require("scripts.razi_convergence")
local convergence_audit = require("scripts.razi_convergence_audit")
local Events = require("__razi_lib__/runtime/events")
local victory_guard = require("scripts.razi_victory_guard")
local quality_asteroids = require("scripts.razi_quality_asteroids")
local pod_receipts = require("scripts.razi_freight_receipts")
local native_pod_trips = require("scripts.razi_native_pod_trips")
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
  local entity=event.entity or event.destination or event.created_entity
  check_entity(entity)
  if entity and entity.valid and entity.name=="razi-archive-relay" then
    razi_journal.refresh_open()
  end
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
  victory_guard.prepare()
  spoiler_fog.sync_all()
  spoiler_fog.defer_all()
  convergence.restore_pending()
  preserve_deep_space_campaign()
  check_existing_transceivers()
  for _,force in pairs(game.forces) do platform_projects.snapshot(force) end
  deep_expedition.observe_connected()
  retire_connected_operations()
  razi_journal.sync_all()
end)
events:on_configuration_changed(function(event)
  victory_guard.prepare()
  spoiler_fog.sync_all()
  spoiler_fog.defer_all()
	convergence.restore_pending()
	preserve_deep_space_campaign()
	check_existing_transceivers()
  for _,force in pairs(game.forces) do platform_projects.snapshot(force) end
  deep_expedition.observe_connected()
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
  -- An unknown source mod may call native victory directly. Official
  -- opt-outs prevent known triggers; this heals a stray state on the
  -- next simulation tick without erasing inherited or Razi victories.
  victory_guard.recover_unexpected()
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
commands.add_command("razi-victory-audit",
  "Display the supported external victory opt-outs and any recovered stray victories.",
  function(event)
    local player=event.player_index and game.get_player(event.player_index)
    if player and not player.admin then
      player.print("[RAZI] This diagnostic requires administrator access.")
      return
    end
    -- An audit is explicitly read-only: do not toggle mod endpoints here.
    local lines={"[RAZI] Only Convergence should set the campaign victory."}
    for _,row in ipairs(victory_guard.inspect()) do
      lines[#lines+1]="  "..row.interface..": "..row.state..
        (row.error and (" ("..row.error..")") or "")
    end
    lines[#lines+1]="  Recovered stray game endings: "..
      tostring(victory_guard.recoveries())
    lines[#lines+1]="  Unmanaged: another mod exposes a victory opt-out,"..
      " but Razi will not call an unverified API."
    lines[#lines+1]="  Note: unknown mods calling game.set_game_state"..
      " directly cannot be universally vetoed."
    local output=table.concat(lines,"\n")
    if player then player.print(output)
    else game.print(output) end
  end)
commands.add_command("razi-audit",
  {"razi-audit.help"},convergence_audit.command)
events:on_nth_tick(6, razi_safe_cheat.tick)
-- No work when the Systems folio is closed; live labels only, no redraw.
events:on_nth_tick(120, function()
  razi_journal.refresh_systems_visible()
  razi_journal.refresh_research_visible()
end)
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


-- Sparse native events record real platform hubs and completed trips.
-- A starter-pack placeholder without a built hub never earns completion.
local function record_platform(event)
  if not (event and event.platform) then return end
  local first=platform_projects.observe(event.platform)
  local major=great_projects.observe(event.platform)
  local visited=deep_expedition.observe_connected(event.platform)
  if first or major or visited then razi_journal.refresh_open() end
end
-- Construction events can fire hundreds of times per platform. Record
-- milestone/Ark state, but do not scan connected player characters on every
-- placed tile. State changes, boarding events and the 300-tick fallback
-- still capture legitimate Deep Space visits.
local function record_platform_construction(event)
  local platform=event and event.platform
  if not platform then return end
  local first=platform_projects.observe(platform)
  local major=great_projects.observe(platform)
  if first or major then razi_journal.refresh_open() end
end
events:on_event(defines.events.on_space_platform_built_entity,
  record_platform_construction)
events:on_event(defines.events.on_space_platform_built_tile,
  record_platform_construction)
events:on_event(defines.events.on_space_platform_changed_state,record_platform)
-- Actual Factorio delivery notifications; this event does NOT identify
-- Orbital Catapult shipments or prove an individual Freight Desk order.
-- A.8 observes Factorio pod origin/delivery using the SAME unit_number
-- only when the runtime exposes one. Never credit a Catapult freight plan.
events:on_event(defines.events.on_cargo_pod_started_ascending,
  native_pod_trips.departed)
events:on_event(defines.events.on_cargo_pod_finished_ascending,
  native_pod_trips.departed)
events:on_event(defines.events.on_cargo_pod_delivered_cargo,function(event)
  pod_receipts.on_delivered(event)
  native_pod_trips.delivered(event)
end)
-- Reconcile arrival events on the existing (infrequent) platform state poll
-- only when a crossing has an outstanding departure record.
events:on_nth_tick(300,function()
  local major=great_projects.flush_pending(game.forces)
  local visited=deep_expedition.observe_connected()
  if major or visited then
    razi_journal.refresh_open()
  end
end)
-- A player physically boarding a parked platform can also count as
-- visiting that location. Remote View never grants the achievement.
events:on_event({
  defines.events.on_player_changed_surface,
  defines.events.on_player_controller_changed
},function(event)
  local player=game.get_player(event.player_index)
  if player and deep_expedition.observe(player) then
    razi_journal.refresh_open()
  end
end)

events:on_event({
  defines.events.on_mined_entity,
  defines.events.on_robot_mined_entity,
  defines.events.on_entity_died,
  defines.events.script_raised_destroy
},function(event)
  local entity=event.entity
  if entity and entity.valid and entity.name=="razi-archive-relay" then
    razi_journal.refresh_open()
  end
end)

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
  platform_projects.forces_merged(event)
  great_projects.forces_merged(event)
  pod_receipts.forces_merged(event)
  native_pod_trips.forces_merged(event)
  deep_expedition.forces_merged(event)
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
  elseif event and (event.setting=="razi-journal-show-button"
    or event.setting=="razi-journal-show-tracker") then
    local player=game.get_player(event.player_index)
    if player then razi_journal.sync(player) end
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
events:on_event(defines.events.on_gui_elem_changed,function(event)
  razi_journal.elem_changed(event)
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
