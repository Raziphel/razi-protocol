require "prototypes.system.calidus"
require("prototypes.system.bellicos").data()
require "prototypes.system.eneas"
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

-- Factorio runs every data.lua before any data-updates.lua. Razi Protocol requires PlanetAthos, so Athos's
-- data-updates.lua runs before ours, and its recursive GetAllDescendants cannot walk a cyclic prerequisite graph.
-- Break the cycles Athos owns (or the two known bootstrap loops) now, after our technologies are registered.
require("prototypes.compat.athos_cycle_guard").repair("before-athos-data-updates")
