require("util")

require("prototypes.compat.lab_cards").data_final_fixes()
require("prototypes.compat.cerys_cards").data_final_fixes()
package.loaded["prototypes.technology.progression"] = nil
require("prototypes.technology.progression")
require("prototypes.compat.transceiver_endgame").data_final_fixes()
require("prototypes.compat.nexus_endgame").data_final_fixes()
require("prototypes.compat.science_tab").data_final_fixes()
require("prototypes.compat.k2so_tweaks").data_final_fixes()
require("prototypes.compat.maraxsis_k2so_collision").data_final_fixes()
require("prototypes.compat.progression_polish").data_final_fixes()
require("prototypes.compat.vibrant_discovery_guard").data_final_fixes()
require("prototypes.compat.prototype_identity").data_final_fixes()
require("prototypes.compat.prototype_sanity").data_final_fixes()
require("prototypes.compat.redundant_progression").data_final_fixes()
require("prototypes.compat.logistics_cleanup").data_final_fixes()

deleteRoute("crucible-maraxsis") -- FUCK THIS ROUTE JESUS CHRIST.
deleteRoute("crucible-orbit-ribbonia") -- AND FUCK YOU 2
deleteRoute("moshine-ribbonia") -- AND FUCK YOU 3
deleteRoute("igrys-orbit-ribbonia") -- AND FUCK YOU 4
