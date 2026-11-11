-- Difficulty level: from here until Razi's data-final-fixes.lua puts them back, a few numeric settings of Muluna and Rubia have the
-- value of the level for the data-updates.lua and data-final-fixes.lua of those mods (the saved settings are not changed). Normal and
-- Custom write nothing.
require("prototypes.difficulty.foreign_difficulty_settings").apply()

require "prototypes.world.systems.calidus"
require("prototypes.world.systems.bellicos").data()
require "prototypes.world.systems.eneas"
require "prototypes.world.systems.solaris"
require "prototypes.world.systems.nyxaris"
require "prototypes.world.systems.vibrant"
require "prototypes.world.systems.beetlejuice"
require "prototypes.world.systems.linox"
require "prototypes.world.systems.deep_space"
require("prototypes.fixes.common.k2so_tweaks").data()
require "prototypes.world.systems.seven_systems"
require "prototypes.world.asteroids.asteroid_belts"
require "prototypes.technology.load"
require "prototypes.technology.systems.asteroid_belts"

require("prototypes.ui.dyson_stages")
require("prototypes.ui.journal")
require("prototypes.industry.great_projects").data()
require("prototypes.compatibility.orbital-cannon.orbital_catapult").data()

-- Factorio runs every data.lua before any data-updates.lua. Razi Protocol requires PlanetAthos, so Athos's
-- data-updates.lua runs before ours, and its recursive GetAllDescendants cannot walk a cyclic prerequisite graph.
-- Break the cycles Athos owns (or the two known bootstrap loops) now, after our technologies are registered.
require("prototypes.fixes.PlanetAthos.athos_cycle_guard").repair("before-athos-data-updates")

-- nexus-bosses loads before Nexus, which lists it as an optional dependency, and so before us. Its prototypes must see our
-- final enemies and the final technologies of Nexus: the last step of our data-final-fixes makes them, and this mod-data
-- tells its own data-final-fixes not to.
if mods["nexus-bosses"] then
  data:extend({{type = "mod-data", name = "nexus-bosses-late", data = {mod = "razi-protocol"}}})
end
