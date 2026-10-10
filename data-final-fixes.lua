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

-- Weave the seven-system planet discoveries through upstream research.
require("prototypes.technology.campaign_weave").data_final_fixes()

-- Optional planet destinations: native science retained, chapter travel attached.
require("prototypes.system.optional_planets").data_final_fixes()

-- Apply our approved star/planet coordinates last, after optional orbits.
-- Keep this explicit in the data-stage entrypoint so it cannot be skipped.
require("prototypes.system.galaxy_layout").data_final_fixes()

-- Restore each source planet's original description and append Razi expedition context.
require("prototypes.system.planet_descriptions").data_final_fixes()
