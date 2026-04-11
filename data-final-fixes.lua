require("util")

-- Some compatibility mods make late data-final-fixes tech edits, so replay the
-- progression pass after them to keep the system order authoritative.
package.loaded["prototypes.technology.progression"] = nil
require("prototypes.technology.progression")
require("prototypes.compat.science_tab").data_final_fixes()
