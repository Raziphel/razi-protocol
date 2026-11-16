-- The order of the technologies the players reported out of place in the technology menu.
local helpers = require("prototypes.fixes.common.progression_helpers")
local set_order_if_present = helpers.set_order_if_present

local technology_order = {}

function technology_order.data_final_fixes()
	for technology_name, order in pairs({
		["sand-processing"] = "a-b[sand-processing]",
		["glass-processing"] = "a-c[glass-processing]",
		["electricity"] = "a-d[electricity]",
		["electronics"] = "a-e[electronics]",
		["logistics"] = "a-f[logistics]",
		["fast-inserter"] = "a-g[fast-inserter]",
		["military"] = "a-h[military]",
		["radar"] = "a-i[radar]",
		["kr-fuel"] = "a-j[fuel-processing]",
		["planet-discovery-cubium"] = "ez-a[cubium]",
		["cube-jelly"] = "ez-b[cube-jelly]",
		["cube-mastery-1"] = "ez-c[cube-mastery-1]",
		["planet-discovery-nexus"] = "fa-a[nexus-discovery]",
		["promethium-882-research"] = "fa-b[promethium-882]",
		["advanced-magnetic-shielding"] = "fa-c[advanced-magnetic-shielding]",
		["advanced-stable-electronic"] = "fa-d[advanced-stable-electronic]",
		["advanced-stronger-armor"] = "fa-e[advanced-stronger-armor]",
		["black-hole-discovery"] = "fz-a[black-hole-discovery]"
	}) do
		set_order_if_present(technology_name, order)
	end
end

return technology_order
