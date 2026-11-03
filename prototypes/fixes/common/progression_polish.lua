local progression_polish = {}

local nanofoamed_polymers_gate = require("prototypes.compatibility.planet-muluna.nanofoamed_polymers_gate")
local long_stack_inserter = require("prototypes.fixes.rubia.long_stack_inserter")
local singularity_card_gate = require("prototypes.compatibility.Krastorio2-spaced-out.singularity_card_gate")
local matter_research_data_surface = require("prototypes.compatibility.Krastorio2-spaced-out.matter_research_data_surface")
local bootstrap_machines = require("prototypes.compatibility.Nexus-Updated.bootstrap_machines")
local far_space_belts = require("prototypes.compatibility.Imersite-Asteroids.far_space_belts")
local sand_progression = require("prototypes.compatibility.Krastorio2-spaced-out.sand_progression")
local technology_order = require("prototypes.fixes.common.technology_order")
local unlock_order = require("prototypes.fixes.common.unlock_order")

function progression_polish.data_final_fixes()
	nanofoamed_polymers_gate.data_final_fixes()
	long_stack_inserter.data_final_fixes()
	singularity_card_gate.data_final_fixes()
	matter_research_data_surface.data_final_fixes()
	bootstrap_machines.data_final_fixes()
	far_space_belts.data_final_fixes()
	sand_progression.data_final_fixes()
	technology_order.data_final_fixes()
	unlock_order.data_final_fixes()
end

return progression_polish
