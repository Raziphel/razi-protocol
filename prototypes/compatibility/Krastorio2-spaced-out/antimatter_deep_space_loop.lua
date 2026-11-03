-- The K2 antimatter technologies do not wait for the Deep Space card that waits for them.
local helpers = require("prototypes.fixes.common.sanity_helpers")
local replace_technology_ingredient_if_present = helpers.replace_technology_ingredient_if_present

local antimatter_deep_space_loop = {}

function antimatter_deep_space_loop.data_final_fixes()
	-- Deep Space Tech Card is the post-promethium bridge. If another compat pass
	-- swaps it into the antimatter K2 chain, the card's own unlock route circles
	-- back through antimatter progression. Keep those K2 late techs on
	-- `promethium-science-pack` instead.
	for _, technology_name in ipairs({
		"kr-antimatter-reactor",
		"kr-antimatter-ammo",
		"kr-antimatter-reactor-equipment",
		"kr-intergalactic-transceiver"
	}) do
		replace_technology_ingredient_if_present(technology_name, "deep-space-tech-card", "promethium-science-pack")
	end
end

return antimatter_deep_space_loop
