local prototype_sanity = {}

local kr_sand = require("prototypes.fixes.Krastorio2-spaced-out.sand_recipe")
local automation_ai_core = require("prototypes.compatibility.Krastorio2-spaced-out.automation_ai_core")
local science_bootstrap = require("prototypes.compatibility.secretas.science_bootstrap")
local glass_craft_triggers = require("prototypes.fixes.planetaris-arig.glass_craft_triggers")
local cactus_mash_seeds = require("prototypes.fixes.planetaris-tellus.cactus_mash_seeds")
local crucible_science_strip = require("prototypes.compatibility.planetaris-hyarion.crucible_science_strip")
local space_telescope_ingredients = require("prototypes.fixes.planet-muluna.space_telescope_ingredients")
local antimatter_deep_space_loop = require("prototypes.compatibility.Krastorio2-spaced-out.antimatter_deep_space_loop")
local pressure_science_prerequisite = require("prototypes.compatibility.planet-crucible.pressure_science_prerequisite")
local late_technology_gate = require("prototypes.compatibility.planet-crucible.late_technology_gate")

prototype_sanity.restore_secretas_science_bootstrap = science_bootstrap.restore_secretas_science_bootstrap

function prototype_sanity.data_final_fixes()
	kr_sand.data_final_fixes()
	automation_ai_core.data_final_fixes()
	science_bootstrap.data_final_fixes()
	glass_craft_triggers.data_final_fixes()
	cactus_mash_seeds.data_final_fixes()
	crucible_science_strip.data_final_fixes()
	space_telescope_ingredients.data_final_fixes()
	antimatter_deep_space_loop.data_final_fixes()
	pressure_science_prerequisite.data_final_fixes()
	late_technology_gate.data_final_fixes()
end

return prototype_sanity
