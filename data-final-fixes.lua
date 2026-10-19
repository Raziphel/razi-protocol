require("util")
local Collections = require("__razi_lib__/lib/collections")

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
require("prototypes.compat.k2so_tech_card_cooling").data_final_fixes()
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
-- Final, visual-only regrouping; source ingredients and machines stay intact.
require("prototypes.compat.crafting_navigation").data_final_fixes()
require("prototypes.system.bellicos").data_final_fixes()
require("prototypes.compat.furnace_result_slots").data_final_fixes()
require("prototypes.compat.eneas_gantry").data_final_fixes()
require("prototypes.compat.variant_surface_conditions").data_final_fixes()

deleteRoute("crucible-maraxsis") -- FUCK THIS ROUTE JESUS CHRIST.
deleteRoute("crucible-orbit-ribbonia") -- AND FUCK YOU 2
deleteRoute("moshine-ribbonia") -- AND FUCK YOU 3
deleteRoute("igrys-orbit-ribbonia") -- AND FUCK YOU 4
deleteRoute("sye-vibrant-muria")
deleteRoutesBetween("sye-vibrant", "muria")

-- Muria has changed its stock connections across releases, and compatibility
-- mods may add more during later data stages. Razi Protocol deliberately places
-- Muria in the Vibrant system with Aquilo as its sole route.
if mods["Muria"] then
	local unwanted_muria_routes = {}
	for name, connection in pairs(data.raw["space-connection"] or {}) do
		if name ~= "muria-aquilo" and (connection.from == "muria" or connection.to == "muria") then
			unwanted_muria_routes[#unwanted_muria_routes + 1] = name
		end
	end
	for _, name in ipairs(unwanted_muria_routes) do
		deleteRoute(name)
	end
end

deleteRoutesBetween("linox-planet_linox", "ribbonia")
deleteRoutesBetween("linox-planet_linox", "rubia")
deleteRoute("sye-vibrant-shchierbin")
deleteRoutesBetween("sye-vibrant", "shchierbin")

require("prototypes.compat.imersite_aquilo_routes").data_final_fixes()

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

-- Star map layout: six systems around Calidus, Deep Space to the north. Visual only (orbits, origins, ring drawing);
-- routes and unlocks are not touched. Nothing after this moves an orbit.
require("prototypes.system.galaxy_layout").data_final_fixes()

-- Transceiver activation opens the Solar System Edge and Deep Space.
-- Runs after the system cards (lab_cards) and the transceiver unlocks exist and after the
-- other compatibility passes have settled the prerequisites, before the lab inputs are deduplicated.
require("prototypes.technology.deep_space_arrival").data_final_fixes()

-- Make sure every system card in the price of the new gates is unlocked before the gate.
require("prototypes.technology.seven_systems").data_final_fixes()

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

-- Re-assert Khemia's position in case a compatibility pass above moved it.
require("prototypes.system.galaxy_layout").confirm_critical_positions()

-- Corrundum Compatibility+ removes an obsolete XY research item after some
-- endgame labs have already registered it as an input.
require("prototypes.compat.corrundum_k2so_lab_inputs").data_final_fixes()

-- Temporary, Factorio 2.1.22: old prototype fields of mods that are not updated yet. Runs last.
require("prototypes.compat.factorio_2_1_22").data_final_fixes()
