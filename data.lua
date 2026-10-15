require "prototypes.system.calidus"
require("prototypes.system.bellicos").data()
require "prototypes.system.solaris"
require "prototypes.system.nyxaris"
require "prototypes.system.vibrant"
require "prototypes.system.beetlejuice"
require "prototypes.system.linox"
require "prototypes.system.deep_space"
require("prototypes.compat.k2so_tweaks").data()
require "prototypes.system.seven_systems"
require "prototypes.system.asteroid_belts"
require "prototypes.technology"
require "prototypes.technology.asteroid_belts"

require("prototypes.ui.galactic_operations")
require("prototypes.ui.dyson_stages")
require("prototypes.ui.razi_journal")

-- Register source-declared catapult link prototypes at the DATA stage.
-- The source author reads these in final-fixes. The opt-in is OFF by default.
require("prototypes.compat.orbital_catapult").data()

-- CRITICAL LOAD-ORDER SAFEGUARD: Factorio runs *all* data.lua scripts
-- before any mod's data-updates.lua. Since Razi requires PlanetAthos,
-- Athos's data-updates.lua always executes before Razi's data-updates.lua.
-- Its recursively implemented GetAllDescendants cannot traverse a cyclic
-- prerequisite graph. Repair confirmed Athos-owned cycles NOW, after Razi's
-- data-stage technologies have been registered but before Athos traverses.
-- Keep later passes for changes introduced by other mods in subsequent stages.
require("prototypes.compat.athos_cycle_guard").repair("before-athos-data-updates")
