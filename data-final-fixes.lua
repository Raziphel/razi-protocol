require("util")
local Collections = require("__razi_lib__/lib/collections")

require("prototypes.compat.removed_fuel_category").data_final_fixes()
require("prototypes.compat.lab_cards").data_final_fixes()
require("prototypes.compat.cerys_cards").data_final_fixes()
require("prototypes.compat.moshine_datacells").data_final_fixes()
require("prototypes.compat.tenebris_void_towers").data_final_fixes()
require("prototypes.technology.progression")
require("prototypes.compat.transceiver_endgame").data_final_fixes()
require("prototypes.compat.nexus_endgame").data_final_fixes()
require("prototypes.compat.nexus_hyarion_conditions").data_final_fixes()
require("prototypes.compat.science_tab").data_final_fixes()
require("prototypes.compat.renamed_research_triggers").data_final_fixes()
require("prototypes.compat.k2so_tweaks").data_final_fixes()
require("prototypes.compat.skewer_shattered_unlocks").data_final_fixes()
require("prototypes.compat.k2so_tech_card_cooling").data_final_fixes()
require("prototypes.compat.maraxsis_k2so_collision").data_final_fixes()
require("prototypes.compat.maraxsis_trench_wind").data_final_fixes()
require("prototypes.compat.progression_polish").data_final_fixes()
require("prototypes.compat.vibrant_discovery_guard").data_final_fixes()
require("prototypes.compat.prototype_identity").data_final_fixes()
require("prototypes.compat.prototype_sanity").data_final_fixes()
require("prototypes.compat.research_data_surfaces").data_final_fixes()
require("prototypes.compat.enemy_homes").data_final_fixes()
require("prototypes.compat.enemy_planet_pollution").data_final_fixes()
require("prototypes.compat.redundant_progression").data_final_fixes()
require("prototypes.compat.water_loop").data_final_fixes()
require("prototypes.compat.logistics_cleanup").data_final_fixes()
require("prototypes.compat.furnace_result_slots").data_final_fixes()
require("prototypes.compat.eneas_gantry").data_final_fixes()
require("prototypes.compat.variant_surface_conditions").data_final_fixes()

-- Old interstellar shortcuts cut across the revised map.
-- Muria's routes are handled by seven_systems and route_reconcile.
deleteRoute("crucible-maraxsis")
deleteRoute("crucible-orbit-ribbonia")
deleteRoute("moshine-ribbonia")
deleteRoute("igrys-orbit-ribbonia")

deleteRoutesBetween("linox-planet_linox", "ribbonia")
deleteRoutesBetween("linox-planet_linox", "rubia")

-- Razi's own route network: planned routes, lengths, asteroid profiles and danger levels.
require("prototypes.system.route_reconcile").data_final_fixes()

local ribbonia = data.raw.planet and data.raw.planet["ribbonia"]
if ribbonia then
	ribbonia.starmap_icon = "__ribbonia__/graphics/starmap/ribbonia2048.png"
	ribbonia.starmap_icon_size = 2048
end

local default_sprites = data.raw["utility-sprites"] and data.raw["utility-sprites"]["default"]
local starmap_star = default_sprites and default_sprites["starmap_star"]
if starmap_star and starmap_star.layers then
	for index = #starmap_star.layers, 1, -1 do
		local layer = starmap_star.layers[index]
		if layer and layer.filename == "__ribbonia__/graphics/starmap/ribbonia2048.png" then
			table.remove(starmap_star.layers, index)
		end
	end
end

-- Additional planet mods join their star systems and local hubs. Runs after the route
-- reconciler and before the layout, which positions the orbits they register.
require("prototypes.system.optional_planets").data_final_fixes()
require("prototypes.system.community_expansions").data_final_fixes()
require("prototypes.system.abacayba_integration").data_final_fixes()

-- Vibrant's belt rims sit on the western edge of the system; place them before the layout reads the orbits.
require("prototypes.system.asteroid_belt_integration").data_final_fixes()

-- Star map layout: six systems around Calidus, Deep Space to the north. Visual only (orbits, origins, ring drawing);
-- routes and unlocks are not touched. Only the Bellicos expedition is reconciled after it.
require("prototypes.system.galaxy_layout").data_final_fixes()

-- Bellicos reconciles its native positions after the general layout pass, so the
-- Aegis expedition is not moved twice.
require("prototypes.system.bellicos").data_final_fixes()

-- Expedition briefings are appended to the final set of planet and location descriptions.
require("prototypes.system.planet_descriptions").data_final_fixes()

-- K2SO material names and research data settle before the gates read the system cards.
require("prototypes.compat.k2so_planet_integration").data_final_fixes()
-- The integration renames recipe products; repoint the research triggers that still name the old ones.
require("prototypes.compat.renamed_research_triggers").data_final_fixes()

-- Set the campaign gates after the earlier compatibility passes: each system's discovery follows the
-- previous tier and costs its cards.
require("prototypes.technology.seven_system_gates").data_final_fixes()
-- Ferrum's robotics science and magnets stay out of the research that Ferrum itself needs; otherwise the next pass takes
-- two packs out of the Vibrant card to break a cycle, and the cryogenic plant waits for the planet.
require("prototypes.compat.ferrum_progression_guard").data_final_fixes()
-- The stack inserter, the toolbelt equipment and the two belt capacity technologies are taken off Gleba's science and carbon fiber
-- research; before the gate links, which would tie a technology priced in agricultural science to the pack.
require("prototypes.technology.nauvis_comforts").data_final_fixes()
require("prototypes.technology.system_gate_links").data_final_fixes()

-- Transceiver activation opens the Solar System Edge and Deep Space.
-- Runs after the system cards (lab_cards) and the transceiver unlocks exist and after the
-- other compatibility passes have settled the prerequisites, before the lab inputs are deduplicated.
require("prototypes.technology.deep_space_arrival").data_final_fixes()

-- Make sure every system card in the price of the new gates is unlocked before the gate.
require("prototypes.technology.seven_systems").data_final_fixes()

-- Planet branches of one system require each other's science. After the gates and their links, so the
-- opening choices of every system stay free.
require("prototypes.technology.campaign_weave").data_final_fixes()

-- Linox, Crucible and Vesta must not need their own late science to be reached; the weave above adds
-- ancestors, so the arrival chains are cleaned after it.
require("prototypes.compat.linox_science_guard").data_final_fixes()
require("prototypes.compat.outer_science_arrival_guard").data_final_fixes()

-- Interplanetary exchanges: the shared components first, then the exchange
-- recipes that consume them (K2SO recipe names are settled by now).
require("prototypes.compat.network_components").data_final_fixes()
require("prototypes.compat.planet_production_exchanges").data_final_fixes()
require("prototypes.compat.modded_planet_exchanges").data_final_fixes()

-- Handoffs between neighbouring systems, then placement of two mod technologies, then the tech tree filter.
require("prototypes.technology.regional_research_bridges").data_final_fixes()
require("prototypes.technology.galactic_mod_research").data_final_fixes()
require("prototypes.compat.orbital_catapult").data_final_fixes()

-- Recheck after the research weaving above; only Athos-owned cyclic arrows (and the known bootstrap loops) are removed.
require("prototypes.compat.athos_cycle_guard").repair()
require("prototypes.technology.tech_tree_visibility").data_final_fixes()
require("prototypes.compat.calidus_dyson").data_final_fixes()

-- Castra's exchange, then the exchanges that return component cargo; they run
-- after the other research passes so that the research links see the final tree.
require("prototypes.compat.first_frontier_industry").data_final_fixes()
require("prototypes.compat.network_components").register_premium()

-- Move Aquilo's foundation, fusion-reactor and legendary-quality research behind later milestones.
-- Runs after every pass that edits technology prerequisites (including the seven-systems gates, so
-- the cycle check sees the final graph) and before the lab inputs are deduplicated.
require("prototypes.technology.aquilo_breakthroughs").data_final_fixes()
-- Final optional arrival pacing after shared research and science integrations.
require("prototypes.compat.planet_arrival_pacing").data_final_fixes()

-- The bridges and the staged Aquilo upgrades add prerequisites after the first pass of the arrival
-- guards; repeat them so the final prerequisite graph is clean.
require("prototypes.compat.linox_science_guard").data_final_fixes()
require("prototypes.compat.outer_science_arrival_guard").data_final_fixes()

-- All technology passes have run; report any cycle that is left and remove only the ones Athos owns.
require("prototypes.compat.athos_cycle_guard").repair("after-all-razi-technology")

-- Planet packs frequently append their science inputs without checking whether
-- another compatibility pass already added the same pack. Duplicate lab inputs
-- are invalid in Factorio 2.1, so normalize them after every Razi compatibility
-- module has finished.
for _, lab in pairs(data.raw.lab or {}) do
	if lab.inputs then
		local unique_inputs = {}
		for _, input in ipairs(lab.inputs) do
			Collections.append_unique(unique_inputs, input)
		end
		lab.inputs = unique_inputs
	end
end

-- Recheck Abacayba's discovery gate after the late research passes; no cycles are introduced.
require("prototypes.system.abacayba_integration").gate()

-- One authoritative seven-system graph, after all planet modules have run.
-- Native moon links, the original belt crossing and special source subsystems
-- have documented exceptions and are never indiscriminately wiped.
require("prototypes.system.route_authority").data_final_fixes()
require("prototypes.compat.calidus_dyson").connect_calidus()
-- Native Aegis links and asteroid fields settle after the two curated entries.
require("prototypes.system.bellicos").fortify_routes()

-- Harvest-rich native asteroid belts get final spawn curves only after the approved crossings
-- and route IDs have been reconciled.
require("prototypes.system.belt_expeditions").data_final_fixes()

-- Imersite-Asteroids' belt on routes to Aquilo: after the last route deletion.
require("prototypes.compat.imersite_aquilo_routes").data_final_fixes()

-- Calibrate severe source-native 1,000 km shortcuts after the route reconciliation.
require("prototypes.system.route_distance_balance").data_final_fixes()
-- Only existing source-mod asteroid families are distributed on the final approved routes.
require("prototypes.system.modded_asteroid_distribution").data_final_fixes()
-- Guard against later integrations adding a second named connection between
-- the same Aegis waypoints before route colouring and hazard inspection.
require("prototypes.system.bellicos").dedupe_internal_routes()

-- Resolve difficulty stages for all finalized connected worlds, including
-- mod-provided outer expeditions with unknown location IDs.
require("scripts.razi_asteroid_difficulty").prepare_routes(data.raw["space-connection"])

-- Razi More Asteroids owns the eight material families and K2SO recipes.
-- Reprofile the final surviving RP3 connections, including both Razi belts,
-- before route tooltips and quality-asteroid carrier conversion inspect them.
require("prototypes.system.more_asteroids_integration").data_final_fixes()

require("prototypes.system.route_icons").data_final_fixes()

-- Route tooltips and the star map backdrop read the final routes and orbits.
require("prototypes.system.route_intel").data_final_fixes()
require("prototypes.system.starmap_background").data_final_fixes()

-- Re-assert Khemia's position in case a compatibility pass above moved it.
require("prototypes.system.galaxy_layout").confirm_critical_positions()

-- Colored route lines follow the final positions; they never change travel data.
require("prototypes.system.route_highlights").data_final_fixes()

-- Corrundum Compatibility+ removes an obsolete XY research item after some
-- endgame labs have already registered it as an input.
require("prototypes.compat.corrundum_k2so_lab_inputs").data_final_fixes()
require("prototypes.compat.corrundum_compat_plus").data_final_fixes()

-- Late-stage source recipes and research are final now. Keep optional bulk card manufacture,
-- then tier the system cards across the EXISTING laboratories of other mods (no new labs).
require("prototypes.compat.system_card_manufacturing").data_final_fixes()
require("prototypes.compat.system_card_laboratories").data_final_fixes()

require("prototypes.technology.convergence").data_final_fixes()
require("prototypes.technology.convergence_witness").data_final_fixes()

-- Optional, off by default: a few robot and nuclear technologies (and Planet Express' trade research) are tied to the
-- science of the first planets. Runs after every research and lab pass, so the lab check sees the final labs.
require("prototypes.technology.distributed_industry").data_final_fixes()

-- Last starmap art passes: drop stray trail sprites left by other mods, then
-- put Razi's gate and belt-rim markers on top.
require("prototypes.system.starmap_trail_cleanup").data_final_fixes()
require("prototypes.system.location_icons").data_final_fixes()

-- Optional, off by default: hostile asteroids on the routes can spawn with quality. Runs after every
-- route and spawn-table edit so the carriers replace the final hostile entries. Resource chunks are untouched.
require("prototypes.system.quality_asteroids").data_final_fixes()

-- Optional, off by default: asteroid and weapon effect reductions. After the quality carriers so their
-- spawn scripts are left alone.
require("prototypes.system.asteroid_performance").data_final_fixes()

-- Carna's spire marker is taken off the copies other mods make of it (Tenebris Prime, Rabbasca). After every pass that could
-- copy or add a prototype, as the last edit of created_effect.
require("prototypes.compat.carna_spire_copies").data_final_fixes()

-- The deep mines and the entropic creation of Iridescent Industry and Arcanyx make ore out of nothing on any surface; Arcanyx's
-- keep-Voidcraft-on-Arcanyx condition does not reach them. After every pass that could add a recipe, before the menu pass.
require("prototypes.compat.arcanyx_from_nothing").data_final_fixes()

-- Lithium Battery (7.5.0 and older) deletes two recipe copies that Planet Crucible's productivity technologies still list, and
-- doubles a biter egg of the promethium research data with Maraxsis, in the research data and in the copy that 7.5.1 keeps.
-- After every pass that could add a recipe effect or ingredient, before the menu pass.
require("prototypes.compat.lithium_battery").data_final_fixes()

-- The stack inserter and the toolbelt equipment, which technology/nauvis_comforts.lua researches on Nauvis, are made of low density
-- structure and plastic instead of Gleba's carbon fiber and jelly; their recycling and crushing return the same. After every pass that
-- could copy these recipes, before the menu pass.
require("prototypes.compat.nauvis_comfort_recipes").data_final_fixes()

-- Razi Rocket Reusability: three optional bulk tiers of rocket chunk processing. They copy the final results of
-- rocket-chunk-processing (the mod loads before Razi, so its Krastorio 2 Spaced Out pass has run) and the research price of
-- remnant-beacon. The copies take the already normalized native recipe, so running after the passes above is safe; before the menu pass.
require("prototypes.compat.rocket_salvage").data_final_fixes()

-- Final integrity guard: late third-party technology passes must not resurrect
-- unlocks or routes for the removed, inaccessible far-side Bellicos stargate.
require("prototypes.system.bellicos").retire_far_gate()
require("prototypes.system.bellicos").dedupe_internal_routes()

-- Difficulty level: rocket parts per launch on every rocket silo, crafting speed of the machines and furnaces players build, and
-- health of walls and gates, from the values the source mods defined. Normal (x1) writes nothing. Nothing after this adds a
-- machine, silo or wall; the menu pass below only reads them.
require("prototypes.compat.razi_launch_economy").data_final_fixes()
require("prototypes.compat.razi_industrial_difficulty").data_final_fixes()

-- Run only after all Razi, partner-mod and temporary recipes have settled.
-- This is a menu-only pass. No recipe is disabled or re-categorized for machines.
require("prototypes.compat.crafting_navigation").data_final_fixes()

-- Difficulty level, settings of other mods: every reader after Razi's data.lua has seen the values of the level, so the saved values
-- come back now. Then the finished prototypes of the settings that Muluna, Cerys and Biological Machines read in their own data.lua
-- are scaled from the saved value to the value of the level. Normal and Custom write nothing.
require("prototypes.compat.foreign_difficulty_settings").restore()
require("prototypes.compat.foreign_numeric_stage_effects").data_final_fixes()
require("prototypes.compat.muluna_power_difficulty").data_final_fixes()
require("prototypes.compat.biological_machines_difficulty").data_final_fixes()

-- New Game map profiles and the global map settings of the difficulty level (evolution, expansion, pollution, raids, spoilage,
-- research price, ore controls of every planet). Normal writes nothing. After every pass that adds or edits a planet or a control,
-- so no planet escapes the scaling and no later pass sees half-scaled controls.
require("prototypes.system.razi_map_preset").data_final_fixes()
