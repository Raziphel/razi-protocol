-- Difficulty level: from here until Razi's data-final-fixes.lua puts them back, a few numeric settings of Muluna and Rubia have the
-- value of the level for the data-updates.lua and data-final-fixes.lua of those mods (the saved settings are not changed). Normal and
-- Custom write nothing.
require("prototypes.compat.foreign_difficulty_settings").apply()

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

require("prototypes.ui.dyson_stages")
require("prototypes.ui.razi_journal")
require("prototypes.technology.razi_great_projects").data()
require("prototypes.compat.orbital_catapult").data()

-- Factorio runs every data.lua before any data-updates.lua. Razi Protocol requires PlanetAthos, so Athos's
-- data-updates.lua runs before ours, and its recursive GetAllDescendants cannot walk a cyclic prerequisite graph.
-- Break the cycles Athos owns (or the two known bootstrap loops) now, after our technologies are registered.
require("prototypes.compat.athos_cycle_guard").repair("before-athos-data-updates")
