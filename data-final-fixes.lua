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

deleteRoute("crucible-maraxsis") -- FUCK THIS ROUTE JESUS CHRIST.
deleteRoute("crucible-orbit-ribbonia") -- AND FUCK YOU 2
deleteRoute("moshine-ribbonia") -- AND FUCK YOU 3
deleteRoute("igrys-orbit-ribbonia") -- AND FUCK YOU 4
-- Muria's orbit and routes are owned by seven_systems.lua and the final
-- route_reconcile.lua pass; do not destroy and rebuild its links here.

deleteRoutesBetween("linox-planet_linox", "ribbonia")
deleteRoutesBetween("linox-planet_linox", "rubia")
deleteRoute("sye-vibrant-shchierbin")
deleteRoutesBetween("sye-vibrant", "shchierbin")

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

-- Reconcile the final route network after every source compatibility pass.
require("prototypes.system.route_reconcile").data_final_fixes()

-- The final campaign gates must override earlier source compatibility rules.
require("prototypes.technology.seven_system_gates").data_final_fixes()
-- Small home-system salvage stop, available after early space science.
require("prototypes.system.calidus_expansion").data_final_fixes()

-- Weave the seven-system planet discoveries through upstream research.
require("prototypes.technology.campaign_weave").data_final_fixes()

-- Optional planet destinations: native science retained, chapter travel attached.
require("prototypes.system.optional_planets").data_final_fixes()
require("prototypes.system.community_expansions").data_final_fixes()

-- Center the native belt artwork on Vibrant's sun, with waypoints
-- anchored to the surviving root star. Keep original asteroid hazards.
require("prototypes.system.asteroid_belt_integration").data_final_fixes()

-- Apply our approved star/planet coordinates last, after optional orbits.
-- Keep this explicit in the data-stage entrypoint so it cannot be skipped.
require("prototypes.system.galaxy_layout").data_final_fixes()

-- Restore each source planet's original description and append Razi expedition context.
require("prototypes.system.planet_descriptions").data_final_fixes()

-- The final K2SO pass reconciles planet recipes and integrates research data
-- into system cards after all source compatibility and layout passes.
require("prototypes.compat.k2so_planet_integration").data_final_fixes()

-- Restore equivalent baseline crafting on K2SO upgrades after all planetary
-- recipe-category rewrites, and anchor late K2 technologies to their worlds.
require("prototypes.compat.k2so_planet_machines").data_final_fixes()

-- Linox can optionally inject its own science into pre-Linox Aquilo research.
-- Keep the outer system reachable without weakening post-arrival hard mode.
require("prototypes.compat.linox_science_guard").data_final_fixes()

-- Scan one final time after K2SO's legacy-item material reconciliation so
-- craft-item and craft-fluid triggers cannot remain on removed recipe outputs.
require("prototypes.compat.renamed_research_triggers").data_final_fixes()

-- Ensure Crucible/Vesta science cannot be needed to discover their own worlds.
require("prototypes.compat.outer_science_arrival_guard").data_final_fixes()

-- Higher-efficiency, nonmandatory industry exchanges between source planets.
-- Add only after all K2SO items, recipes, and research data are reconciled.
require("prototypes.compat.planet_production_exchanges").data_final_fixes()

-- Additional cross-mod industrial exchanges use their source mods' true
-- producer research and preserve specialist surface/crafting restrictions.
require("prototypes.compat.modded_planet_exchanges").data_final_fixes()

-- Source-derived optional high-end exchanges for Ferrum, Wit and Balack.
-- Native recipes and science production are never rewritten.
require("prototypes.compat.community_industry_exchanges").data_final_fixes()

-- Bring source-native planetary discoveries together at the final
-- singularity without introducing early scientific softlocks.
require("prototypes.technology.planetary_unification").data_final_fixes()

-- Keep required cross-planet logistics and defense technologies aligned
-- with Razi's actual chapter discoveries. Source recipes stay unchanged.
require("prototypes.technology.galactic_mod_research").data_final_fixes()
-- Bridge source-native science discoveries between existing stars.
-- Cycle guarded and never inserts source recipes or science cost multipliers.
require("prototypes.technology.regional_research_bridges").data_final_fixes()
-- Highlight Razi's main research chapters using the engine's native
-- "Show only essential technologies" research filter.
require("prototypes.technology.tech_tree_visibility").data_final_fixes()

-- Extra optional trade networks only in Deep interdependence mode.
require("prototypes.compat.deep_interdependence").data_final_fixes()

-- Multi-world shipping and manufacturing rewards. Optional bonuses only;
-- leave native recipes, discoveries, and production chains untouched.
require("prototypes.compat.galactic_industry_bridges").data_final_fixes()

-- Space Age assigns connection defaults before this stage. Repair only routes
-- still lacking icon data after every Razi and compatibility route exists.
require("prototypes.system.route_icons").data_final_fixes()

-- Final native tooltip fields for all surviving route prototypes.
require("prototypes.system.route_intel").data_final_fixes()

-- Insert Razi's original galaxy sky and system halos behind route guides.
require("prototypes.system.starmap_background").data_final_fixes()

-- Final cosmetic-only starmap pass, after every connection and orbit has settled.
require("prototypes.system.route_highlights").data_final_fixes()
