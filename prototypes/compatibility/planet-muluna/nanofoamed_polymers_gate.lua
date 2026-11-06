-- Muluna's green plastic research waits for a few planetary breakthroughs, not for its own planet alone.
local helpers = require("prototypes.fixes.common.progression_helpers")
local technology = helpers.technology
local add_prerequisite = helpers.add_prerequisite
local science_ingredients = helpers.science_ingredients

local nanofoamed_polymers_gate = {}

function nanofoamed_polymers_gate.data_final_fixes()
	local green_plastic = technology("muluna-nanofoamed-polymers")
	if not green_plastic then
		return
	end

	-- Muluna wants this after a few planetary breakthroughs. Keep the list
	-- readable, but do not let it become a same-planet early unlock.
	green_plastic.enabled = true
	green_plastic.visible_when_disabled = nil
	green_plastic.prerequisites = {"space-science-pack"}
	add_prerequisite(green_plastic, "planet-discovery-muluna")
	add_prerequisite(green_plastic, "metallurgic-science-pack")
	add_prerequisite(green_plastic, "electromagnetic-science-pack")
	add_prerequisite(green_plastic, "agricultural-science-pack")

	local ingredients = science_ingredients({
		"automation-science-pack",
		"logistic-science-pack",
		"chemical-science-pack",
		"production-science-pack",
		"utility-science-pack",
		"space-science-pack",
		"metallurgic-science-pack",
		"electromagnetic-science-pack",
		"agricultural-science-pack"
	})

	if #ingredients > 0 then
		green_plastic.research_trigger = nil
		green_plastic.unit = {
			count = 1000,
			time = 60,
			ingredients = ingredients
		}
	end

end

return nanofoamed_polymers_gate
