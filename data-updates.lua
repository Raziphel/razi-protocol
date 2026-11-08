
require("prototypes.compatibility.Arachnids_enemy.arachnids_enemy")
require("prototypes.compatibility.ArmouredBiters21Compat.armoured_biters")
require("prototypes.compatibility.Cold_biters.cold_biters")
require("prototypes.compatibility.Explosive_biters.explosive_biters")
require("prototypes.compatibility.Toxic_biters.toxic_biters")
-- Run source shims before the optional mods' data-final-fixes scripts.
require("prototypes.fixes.nulla.nulla_guard").data_updates()
require("prototypes.fixes.PlanetAthos.athos_cycle_guard").repair()
require("prototypes.compatibility.science-tab.science_tab").data_updates()
require("prototypes.fixes.common.k2so_tweaks").data_updates()
-- Module Category Defaults reads its list of ordinary categories in its own data-final-fixes.
require("prototypes.fixes.Voidcraft.module_category_defaults").data_updates()

require("prototypes.fixes.tenebris-prime.bioluminescent_references").data_updates()

-- Star images are rendered and sprite_only parents deleted during PlanetsLib
-- data-final-fixes. Position them BEFORE that irreversible rendering pass.
require("prototypes.world.systems.calidus_sun").data_updates()
require("prototypes.world.systems.abacayba_integration").data_updates()
require("prototypes.world.starmap.galaxy_layout").data_updates()
-- Source starfields must be positioned before PlanetsLib's irreversible
-- sprite-only star cleanup; the Aegis and pulsar orbit artwork is kept.
require("prototypes.world.systems.bellicos").data_updates()
