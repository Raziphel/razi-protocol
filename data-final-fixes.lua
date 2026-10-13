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
require("prototypes.system.bellicos").data_final_fixes()
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
	if lab.inputs then
		local unique_inputs = {}
		for _, input in ipairs(lab.inputs) do
			Collections.append_unique(unique_inputs, input)
		end
		lab.inputs = unique_inputs
	end
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

require("prototypes.system.asteroid_belt_integration").data_final_fixes()

-- Position the map after optional planets register their orbits.
require("prototypes.system.galaxy_layout").data_final_fixes()

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

-- One authoritative seven-system graph, after *all* planet modules have run.
-- Native moon links, original belt crossing and special source subsystems
-- have documented exceptions and are never indiscriminately wiped.
require("prototypes.system.route_authority").data_final_fixes()

require("prototypes.system.route_icons").data_final_fixes()

require("prototypes.system.route_intel").data_final_fixes()

require("prototypes.system.starmap_background").data_final_fixes()

-- FluxWorks is an optional factory expansion. Run after chapter/route gates so
-- its manufacturing options cannot redefine the campaign progression.
require("prototypes.compat.fluxworks").data_final_fixes()
-- Optional industrial projects with their own Codex milestones; never gate routes.
require("prototypes.compat.fluxworks_specializations").data_final_fixes()
-- Optional paired workshops require BOTH regional industry milestones.
require("prototypes.compat.fluxworks_industry_exchanges").data_final_fixes()
-- Collapse only prerequisite arrows already implied by other research paths.
require("prototypes.compat.fluxworks_research_clarity").data_final_fixes()
-- Ease selected specialist machinery research tolls without altering any
-- prerequisites, science packs, planet discovery, or standalone FluxWorks.
require("prototypes.compat.fluxworks_machine_pacing").data_final_fixes()

-- Final positions, then Razi's own path-aware visual overlay. All
-- connections are registered before this pass; it never changes travel data.
require("prototypes.system.galaxy_layout").confirm_critical_positions()
require("prototypes.system.route_highlights").data_final_fixes()

-- Corrundum Compatibility+ removes an obsolete XY research item after some
-- endgame labs have already registered it as an input.
require("prototypes.compat.corrundum_k2so_lab_inputs").data_final_fixes()

-- Late-stage source recipes and research are final now. Keep optional
-- bulk card manufacture, but tier only the EXISTING source-mod labs.
-- The retired four Razi-created labs are not registered.
require("prototypes.compat.system_card_manufacturing").data_final_fixes()
require("prototypes.compat.system_card_laboratories").data_final_fixes()
