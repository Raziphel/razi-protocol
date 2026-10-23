require("util")
local Collections = require("__razi_lib__/lib/collections")

require("prototypes.compat.lab_cards").data_final_fixes()
require("prototypes.compat.cerys_cards").data_final_fixes()
require("prototypes.compat.moshine_datacells").data_final_fixes()
require("prototypes.technology.progression")
require("prototypes.compat.transceiver_endgame").data_final_fixes()
require("prototypes.compat.nexus_endgame").data_final_fixes()
require("prototypes.compat.science_tab").data_final_fixes()
require("prototypes.compat.renamed_research_triggers").data_final_fixes()
require("prototypes.compat.k2so_tweaks").data_final_fixes()
require("prototypes.compat.maraxsis_k2so_collision").data_final_fixes()
require("prototypes.compat.maraxsis_trench_wind").data_final_fixes()
require("prototypes.compat.progression_polish").data_final_fixes()
require("prototypes.compat.vibrant_discovery_guard").data_final_fixes()
require("prototypes.compat.prototype_identity").data_final_fixes()
require("prototypes.compat.prototype_sanity").data_final_fixes()
require("prototypes.compat.research_data_surfaces").data_final_fixes()
require("prototypes.compat.enemy_planet_pollution").data_final_fixes()
require("prototypes.compat.redundant_progression").data_final_fixes()
require("prototypes.compat.water_loop").data_final_fixes()
require("prototypes.compat.logistics_cleanup").data_final_fixes()
-- Delay Bellicos native reconciliation until AFTER Razi's general galaxy
-- relocation pass. Otherwise source Warden can be moved twice.
require("prototypes.compat.furnace_result_slots").data_final_fixes()

-- Old interstellar shortcuts cut across the revised map.
-- Muria's routes are handled by seven_systems and route_reconcile.
deleteRoute("crucible-maraxsis")
deleteRoute("crucible-orbit-ribbonia")
deleteRoute("moshine-ribbonia")
deleteRoute("igrys-orbit-ribbonia")

deleteRoutesBetween("linox-planet_linox", "ribbonia")
deleteRoutesBetween("linox-planet_linox", "rubia")

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

-- Duplicate lab science inputs are invalid in Factorio 2.1.
for _, lab in pairs(data.raw.lab or {}) do
	if lab.inputs then lab.inputs = Collections.unique(lab.inputs) end
end

require("prototypes.system.route_reconcile").data_final_fixes()

-- Set the campaign gates after the earlier compatibility passes.
require("prototypes.technology.seven_system_gates").data_final_fixes()

-- Transceiver activation opens the Solar System Edge and Deep Space.
-- It is no longer the final campaign victory.
require("prototypes.technology.deep_space_arrival").data_final_fixes()

require("prototypes.technology.campaign_weave").data_final_fixes()

require("prototypes.system.optional_planets").data_final_fixes()
require("prototypes.system.community_expansions").data_final_fixes()
require("prototypes.system.abacayba_integration").data_final_fixes()

require("prototypes.system.asteroid_belt_integration").data_final_fixes()

-- Position the map after optional planets register their orbits.
require("prototypes.system.galaxy_layout").data_final_fixes()
require("prototypes.system.bellicos").data_final_fixes()

require("prototypes.system.planet_descriptions").data_final_fixes()

-- K2SO recipe names must settle before any exchange recipes are built.
require("prototypes.compat.k2so_planet_integration").data_final_fixes()

require("prototypes.compat.k2so_planet_machines").data_final_fixes()

-- Avoid a Linox science requirement on the research needed to reach it.
require("prototypes.compat.linox_science_guard").data_final_fixes()

-- Fix triggers after material and recipe renames are settled.
require("prototypes.compat.renamed_research_triggers").data_final_fixes()

require("prototypes.compat.outer_science_arrival_guard").data_final_fixes()

-- Create the shared components before building their exchange recipes.
require("prototypes.compat.network_components").data_final_fixes()

require("prototypes.compat.planet_production_exchanges").data_final_fixes()

require("prototypes.compat.modded_planet_exchanges").data_final_fixes()

require("prototypes.compat.community_industry_exchanges").data_final_fixes()

require("prototypes.technology.planetary_unification").data_final_fixes()

require("prototypes.technology.galactic_mod_research").data_final_fixes()
require("prototypes.technology.regional_research_bridges").data_final_fixes()
require("prototypes.technology.tech_tree_visibility").data_final_fixes()

require("prototypes.compat.calidus_dyson").data_final_fixes()
require("prototypes.compat.helios_engineering").data_final_fixes()
require("prototypes.compat.helios_structures").data_final_fixes()

require("prototypes.compat.deep_interdependence").data_final_fixes()

require("prototypes.compat.galactic_industry_bridges").data_final_fixes()

-- Optional reciprocal factories for the first two stars and Calidus return routes.
require("prototypes.compat.first_frontier_industry").data_final_fixes()

-- Reciprocal Fulgora, Aquilo, Paracelsin and Rubia manufacturing.
require("prototypes.compat.middle_frontier_industry").data_final_fixes()

require("prototypes.compat.panglia_industry").data_final_fixes()

require("prototypes.compat.network_components").register_premium()

-- Late integration passes may add research requirements after the initial
-- landing checks. Recheck the Linox, Crucible and Vesta arrival chains.
require("prototypes.compat.linox_science_guard").data_final_fixes()
require("prototypes.compat.outer_science_arrival_guard").data_final_fixes()

-- Post-arrival industries may connect the finished planetary supply
-- networks without adding any requirement to a first-visit world gate.
require("prototypes.technology.research_tree_polish").data_final_fixes()

-- Reuse real, optional AAI transmission research in Razi-owned advanced
-- factory projects. AAI retains all transmitters, channels and behavior.
require("prototypes.compat.aai_signal_partnerships").data_final_fixes()

-- A few valid factory researches become later chapter prerequisites.
-- Missing producers and future-gated sources must never become blockers.
require("prototypes.technology.industrial_partnership_gates").data_final_fixes()

-- Reuse native planetary science only for already-accessible Razi
-- industries and only with an obtainable recipe and a matching lab.
require("prototypes.technology.planetary_science_weave").data_final_fixes()

-- Dyson's actual source station IDs can only be resolved after its native
-- technology effects exist. Register those connections first, then let
-- Razi's final authority replace the remaining ordinary source routes.
require("prototypes.compat.calidus_dyson").connect_calidus()

-- Recheck after later research weaving; only Athos-owned cyclic arrows
-- can be removed, leaving unrelated technology prerequisites untouched.
require("prototypes.compat.athos_cycle_guard").repair()
-- Recheck after late source research weaving; no cycles are introduced.
require("prototypes.system.abacayba_integration").gate()

-- One authoritative seven-system graph, after *all* planet modules have run.
-- Native moon links, original belt crossing and special source subsystems
-- have documented exceptions and are never indiscriminately wiped.
require("prototypes.system.route_authority").data_final_fixes()
-- Native Aegis links and asteroid fields settle after the two curated entries.
require("prototypes.system.bellicos").fortify_routes()

-- Harvest-rich native asteroid belts get final source-safe spawn curves only
-- after the approved crossings and route IDs have been reconciled.
require("prototypes.system.belt_expeditions").data_final_fixes()
-- Calibrate severe source-native 1,000 km shortcuts after all map/route
-- reconciliation, before hazard intelligence and quality escalation.
require("prototypes.system.route_distance_balance").data_final_fixes()
-- Harden every native or Razi solar route after route authority runs.
require("prototypes.compat.calidus_dyson").fortify_routes()
-- Only existing source-mod asteroid families are distributed on the final
-- approved routes, before hover analysis and the quality-asteroid proxy.
require("prototypes.system.modded_asteroid_distribution").data_final_fixes()

-- Resolve difficulty stages for ALL finalized connected worlds, including
-- mod-provided outer expeditions with unknown location IDs. This is after
-- authoritative route deletion but before hover tooltips and map artwork.
require("scripts.razi_asteroid_difficulty").prepare_routes(
  data.raw["space-connection"])

-- Razi More Asteroids owns the six material families and K2SO recipes.
-- Reprofile the final surviving RP3 connections, including both Razi belts,
-- before route tooltips and quality-asteroid carrier conversion inspect them.
require("prototypes.system.more_asteroids_integration").data_final_fixes()

require("prototypes.system.route_icons").data_final_fixes()

require("prototypes.system.route_intel").data_final_fixes()

require("prototypes.system.starmap_background").data_final_fixes()

-- Final positions, then Razi's own path-aware visual overlay. All
-- connections are registered before this pass; it never changes travel data.
require("prototypes.system.galaxy_layout").confirm_critical_positions()
-- Last strict Bellicos coordinate pass also corrects late source-type
-- duplicates and matches any PlanetsLib-tagged Aegis art to the positions.
require("prototypes.system.bellicos").reconcile_final_positions()
require("prototypes.system.route_highlights").data_final_fixes()

-- Corrundum Compatibility+ removes an obsolete XY research item after some
-- endgame labs have already registered it as an input.
require("prototypes.compat.corrundum_k2so_lab_inputs").data_final_fixes()

-- Late-stage source recipes and research are final now. Keep optional
-- bulk card manufacture, but tier only the EXISTING source-mod labs.
-- The retired four Razi-created labs are not registered.
require("prototypes.compat.system_card_manufacturing").data_final_fixes()
require("prototypes.compat.system_card_laboratories").data_final_fixes()

-- Post-transceiver endgame: build real freight with native assemblers and labs.
require("prototypes.technology.convergence").data_final_fixes()
-- An independent physical witness network gives the finale its actual burden.
require("prototypes.technology.convergence_witness").data_final_fixes()

-- Last technology pass: distribute selected base/modded unlocks across real
-- planetary science, after all source science, labs and routes have settled.
-- The pass skips incomplete or circular changes instead of forcing them.
require("prototypes.technology.distributed_industry").data_final_fixes()

-- Optional rail and shield tech after all existing laboratories/source
-- research are finalized. Guarded skips avoid unreachable planet science.
require("prototypes.compat.frontier_companions").data_final_fixes()

-- Source Rocket Reusability/K2SO salvage outputs have settled by this pass.
require("prototypes.compat.rocket_salvage").data_final_fixes()

-- Require real Nulla and Athos science for the joint post-arrival
-- recovery charter. No additional laboratory or substitute science pack.
require("prototypes.compat.frontier_recovery").data_final_fixes()

-- Aquilo is reached midway through a much larger modded campaign.
-- Defer only the three vanilla endgame breakthroughs, not cryogenic
-- science, initial planetary survival tools, planet discoveries or recipes.
require("prototypes.technology.aquilo_breakthroughs").data_final_fixes()
-- Final optional arrival pacing after shared research and science integrations.
require("prototypes.compat.planet_arrival_pacing").data_final_fixes()

-- All Razi technology passes have now run. Repeat the narrow Secretas
-- bootstrap repair so a later weave cannot reintroduce the golden/recycler
-- feedback loop; report any remaining independently authored tech cycles.
require("prototypes.compat.prototype_sanity").restore_secretas_science_bootstrap()
require("prototypes.compat.athos_cycle_guard").repair("after-all-razi-technology")

-- Last research compatibility repair: Heat Inserter can inherit a hidden
-- bulk-heat-inserter prerequisite on visible Linox neodymium variants.
-- Restore the accessible native tier without bypassing Linox progression.
require("prototypes.compat.heat_inserter_research").data_final_fixes()

-- Late source mods may leave spawner autoplace tables with no required
-- probability expression. Repair only known optional enemy nests, keeping
-- their existing units and spawn recipes rather than breaking mod startup.
require("prototypes.compat.enemy_autoplace").repair_optional_enemy_autoplace()
-- Final enemy ecology runs after optional enemy packs and all planet
-- prototypes are registered. It never changes already-generated chunks.
require("prototypes.compat.razi_enemy_ecology").data_final_fixes()
-- A curated, explicitly selectable New Game preset; Freeplay remains intact.
require("prototypes.system.razi_map_preset").data_final_fixes()

-- ABSOLUTE LAST ART PASS: Orbital Catapult draws independent red dotted
-- routes into the same starmap atlas. Remove those visuals and leftover
-- Carna/Velora trail sprites after all of Razi's renderers have finished.
-- This NEVER deletes platform routes, catapult transport, or orbit metadata.
require("prototypes.system.starmap_trail_cleanup").data_final_fixes()

-- Dedicated Factorio-style Razi gateway and asteroid-rim markers only.
-- Final cosmetic pass, after all other starmap atlas and route cleanup.
require("prototypes.system.location_icons").data_final_fixes()

-- Final asteroid pass: quality-carrier spawn definitions must be installed
-- AFTER Razi route authority, risk tooltip inspection, and colored overlays.
-- Existing native routes, chunks, and technology requirements stay intact.
require("prototypes.system.quality_asteroids").data_final_fixes()

-- LAST gameplay-prototype pass: opt-in asteroid/weapon UPS experiments.
-- All four are disabled by default, and deliberately occur AFTER quality
-- carriers and custom-asteroid distribution, preserving source recipes,
-- chunks, routes and 1-10 difficulty grades.
require("prototypes.system.asteroid_performance").data_final_fixes()

-- Last compatibility cleanup: remove temporary old lava fields after
-- early-loaded planet mods have used them; no invalid prototype fields
-- may reach the Factorio graphics validator.
require("prototypes.compat.legacy_lava_cleanup").data_final_fixes()

-- Absolute last coordinate pass. Nothing may reposition Aegis nodes after
-- this point, including legacy source-map or visualization modules.
require("prototypes.system.bellicos").reconcile_final_positions()

-- TEMPORARY upstream compatibility patches. Entirely removable:
-- delete temporary/factorio_2_1_22 and this single require.
require("temporary.factorio_2_1_22.loader").data_final_fixes()

-- Adjust required crafts per rocket using source mod silo prototypes, not
-- hardcoded rocket-part recipes or a simulation-time launch controller.
require("prototypes.compat.razi_launch_economy").data_final_fixes()
-- Keep source industries, recipes and defense identities; adjust only
-- supported crafting speeds and wall/gate health at prototype-load time.
require("prototypes.compat.razi_industrial_difficulty").data_final_fixes()

-- Run only after all Razi, partner-mod and temporary recipes have settled.
-- This is a menu-only pass. No recipe is disabled or re-categorized for machines.
require("prototypes.compat.helios_engineering").reinforce_satellites()
require("prototypes.compat.crafting_navigation").data_final_fixes()

-- All source data-updates/final-fixes readers have now used the temporary
-- difficulty-selected values. Put the Lua settings view back exactly as it
-- was, leaving the player's saved foreign settings untouched.
require("prototypes.compat.foreign_difficulty_settings").restore()

-- Numeric options consumed by source mods in their earlier data.lua cannot
-- be reached by the transient settings view. Recreate ONLY their confirmed
-- source cost/yield formulas on their already-built prototypes instead.
require("prototypes.compat.foreign_numeric_stage_effects").data_final_fixes()
-- Same treatment for the native Muluna platform-power-consumption setting:
-- correct scan-power, buffer, charge and source tooltip together.
require("prototypes.compat.muluna_power_difficulty").data_final_fixes()
-- Exact source numeric settings: Balack bio-fabricator speed/pollution,
-- plus optional Promethium Belts research requirement. Never change belt speed.
require("prototypes.compat.biological_machines_difficulty").data_final_fixes()
-- Source XY's optional numerical inflation scale; never enable its toggle.
require("prototypes.compat.xy_inflation_difficulty").data_final_fixes()

-- Repair Crucible's dangling legacy cryogenic recipe after LithiumBattery removes it.
require("prototypes.compat.lithium_crucible_science").data_final_fixes()

-- Final recipe validation: merge duplicate K2SO promethium biter eggs.
require("prototypes.compat.k2so_promethium_ingredients").data_final_fixes()

-- Final integrity guard: late third-party technology passes must not resurrect
-- unlocks or routes for the removed, inaccessible far-side Bellicos stargate.
require("prototypes.system.bellicos").retire_far_gate()
