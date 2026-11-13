-- Repairs of mistakes in other mods that the player would otherwise meet: crashes, wrong values, missing data. One file
-- per repair in prototypes/fixes/<mod>/, each with a data_final_fixes(). A repair changes a
-- value only while it still has the value the source mod wrote, logs every change with "razi-protocol:" and does
-- nothing when the prototype or the mod is absent. The order below is the order of application; the list runs as the last
-- step of data-final-fixes.lua, after every other pass of this mod.
local mod_fixes = {}

local repairs = {
	require("prototypes.fixes.common.removed_vehicle_fields"),
	require("prototypes.fixes.RenaiTransportation.hardcoded_localization"),
	require("prototypes.fixes.Arachnids_enemy.corpse_names"),
	require("prototypes.fixes.Krastorio2.roboport_mode_names"),
	require("prototypes.fixes.apia.refresh_freshness_names"),
	require("prototypes.fixes.moon-eneas.aquilo_data_card"),
	require("prototypes.fixes.pelagos.recipe_gates"),
	require("prototypes.fixes.moon-eneas.recycling_enabled"),
	require("prototypes.fixes.RenaiTransportation.recycling_hidden"),
	require("prototypes.fixes.moon-eneas.pristine_filter"),
	require("prototypes.fixes.moon-eneas.construction_drone"),
	require("prototypes.fixes.Cerys-Moon-of-Fulgora.roboport_pressure"),
	require("prototypes.fixes.Krastorio2.loader_insert_limits"),
	require("prototypes.fixes.planetaris-arig.surface_conditions"),
	require("prototypes.fixes.Krastorio2-spaced-out.void_crushing"),
	require("prototypes.fixes.Krastorio2-spaced-out.piercing_shotgun"),
	require("prototypes.fixes.tenebris-prime.bioluminescent_copies"),
	require("prototypes.fixes.Krastorio2.construction_roboport"),
	require("prototypes.fixes.Krastorio2.artillery_range"),
	require("prototypes.fixes.apia.nutrients_refresh"),
	require("prototypes.fixes.Big-Monsters.boss_spidertrons"),
	require("prototypes.fixes.planetaris-dyes.refined_concrete"),
	require("prototypes.fixes.minimalist-rails.hidden_poles"),
	require("prototypes.fixes.k2so-cubium-compatibility-fork.galvanization_notes"),
	require("prototypes.fixes.xy-k2so-enhancements-nulls-fork.upgrade_chain"),
	require("prototypes.fixes.slp-dyson-sphere-reworked-fork.connector_priority"),
	require("prototypes.fixes.lane-balancers.hidden_splitters"),
	require("prototypes.fixes.Aircraft-space-age.vehicle_fuel"),
	require("prototypes.fixes.planet-muluna.hard_drive_time"),
	require("prototypes.fixes.planetaris-arig.rail_support_description"),
	require("prototypes.fixes.common.factoriopedia_enemies"),
	require("prototypes.fixes.RenaiTransportation.thrower_ranges"),
	require("prototypes.fixes.planet-muluna.burner_roboport_minable"),
	require("prototypes.fixes.common.recycling_sources"),
	require("prototypes.fixes.Mini_Trains.entity_data_items"),
	require("prototypes.fixes.corrundum.bioflux_stack"),
	require("prototypes.fixes.shchierbin.vanadium_acid_steam"),
	require("prototypes.fixes.alchemy-khemia.glyph_smelting_unlock"),
	require("prototypes.fixes.planetaris-tellus.magnesium_productivity"),
	require("prototypes.fixes.flare_stack.flaring_emissions"),
	require("prototypes.fixes.Arcanyx.crushed_creation_unlock"),
	require("prototypes.fixes.plasma_crafter.crushed_ore_melting"),
	require("prototypes.fixes.Voidcraft.crushed_prismite_sand"),
	-- Last: the repairs above may hide technologies too.
	require("prototypes.fixes.common.hidden_prerequisites"),
}

function mod_fixes.data_final_fixes()
	for _, repair in ipairs(repairs) do
		repair.data_final_fixes()
	end
end

return mod_fixes
