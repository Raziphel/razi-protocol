-- Runs on top of the base config of GreenTech-Solutions/factorio-mod-tools (lua/luacheckrc.lua), which sets
-- std = "lua52", the Factorio globals and allow_defined_top: add to its tables here.

-- PlanetsLib (a dependency) sets it in its data stage
read_globals[#read_globals + 1] = "PlanetsLib"
-- prototypes/compat/k2so_tweaks.lua sets it for xy-k2so-enhancements, which reads it as a global
globals[#globals + 1] = "sounds"
