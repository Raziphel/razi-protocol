local transceiver_endgame = {}

local icon = "__Krastorio2Assets__/technologies/intergalactic-transceiver.png"

-- The ingredients are filled in data-final-fixes (prototypes/compat/transceiver_endgame.lua):
-- the system tech cards do not exist yet at this stage.
local function make_transceiver_technology(name, prerequisites, count, effects)
	return {
		type = "technology",
		name = name,
		localised_name = {"technology-name." .. name},
		icon = icon,
		icon_size = 256,
		essential = true,
		prerequisites = prerequisites,
		effects = effects or {},
		unit = {
			count = count,
			time = 60,
			ingredients = {}
		}
	}
end

-- Our version of Extended Endgame: the transceiver tech gives you the theory,
-- but these staged tests prove the singularity is stable before the recipe opens.
data:extend({
	make_transceiver_technology(
		"razi-singularity-theory",
		{"kr-intergalactic-transceiver"},
		5000
	),
	make_transceiver_technology(
		"razi-singularity-test-fire",
		{"razi-singularity-theory"},
		7500
	),
	make_transceiver_technology(
		"razi-stable-intergalactic-singularity",
		{"razi-singularity-test-fire"},
		10000,
		{
			{type = "unlock-recipe", recipe = "kr-intergalactic-transceiver"}
		}
	)
})

return transceiver_endgame
