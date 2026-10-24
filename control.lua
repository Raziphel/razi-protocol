local Events = require("__razi_lib__/runtime/events")
local razi_safe_cheat = require("scripts.razi_safe_cheat")
local razi_prepared_2x = require("scripts.razi_prepared_2x")
local quality_asteroids = require("scripts.razi_quality_asteroids")
local voidcraft_variants = require("scripts.compat.voidcraft_variants")
local enemy_surfaces = require("scripts.razi_enemy_surfaces")

local events = Events.new()
local transceiver_gate_technology = "razi-intergalactic-transceiver-signal"
local active_transceiver_name = "kr-activated-intergalactic-transceiver"
local transceiver_build_events = {
	defines.events.on_built_entity,
	defines.events.on_robot_built_entity,
	defines.events.on_entity_cloned,
	defines.events.script_raised_built,
	defines.events.script_raised_revive
}
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
		local technology = force.technologies[transceiver_gate_technology]
		-- Most forces already have the gate. Skip even the O(1) count
		-- after research, including the 10-minute safeguard poll.
		if technology and not technology.researched
			and force.get_entity_count(active_transceiver_name) > 0 then
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
events:on_init(check_existing_transceivers)
-- Surfaces that exist already get the switched-off nests of their planet for their new chunks.
events:on_init(enemy_surfaces.apply)
events:on_configuration_changed(function(event)
	check_existing_transceivers()
	enemy_surfaces.apply()
	repair_nexus_technology_visibility(event)
	razi_prepared_2x.on_configuration_changed(event)
end)
events:on_nth_tick(600, check_existing_transceivers)
events:on_event(transceiver_build_events, on_entity_built)

-- Spread debug research across ticks instead of freezing the whole modpack.
commands.add_command("razi-cheat", {"razi-cheat.help"}, razi_safe_cheat.command)
-- Exits at once while no staged research is running.
events:on_nth_tick(6, razi_safe_cheat.tick)
-- Only the quality carrier asteroids raise this effect: no scanning and no ticking.
events:on_event(defines.events.on_script_trigger_effect, quality_asteroids.on_script_trigger_effect)
-- /cheat is a built-in command and cannot be replaced. This notification
-- runs only if the engine gets far enough to emit its console event.
events:on_event(defines.events.on_console_command, razi_safe_cheat.warn_builtin)
events:on_event(defines.events.on_player_joined_game, function(event)
	razi_safe_cheat.admin_tip(game.get_player(event.player_index))
end)
events:on_event(defines.events.on_player_removed, function(event)
	razi_safe_cheat.on_player_removed(event.player_index)
end)

-- Voidcraft 2.11.1 hands the unlock of its recipe variants to this interface instead of walking every recipe on each research.
voidcraft_variants.register()

events:install()

-- Filters must be set after the registration they belong to. They apply to
-- every handler on these events, so a feature that needs other built
-- entities must widen this filter rather than add its own registration.
local transceiver_filter = {{filter = "name", name = active_transceiver_name}}
for _, event_id in ipairs(transceiver_build_events) do
	script.set_event_filter(event_id, transceiver_filter)
end
