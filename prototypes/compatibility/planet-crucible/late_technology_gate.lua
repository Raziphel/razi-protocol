-- Late technologies that appeared early in the tree wait for Crucible.
local helpers = require("prototypes.fixes.common.sanity_helpers")
local add_technology_prerequisite_if_present = helpers.add_technology_prerequisite_if_present

local late_technology_gate = {}

function late_technology_gate.data_final_fixes()
	if not technology_exists("planet-crucible-science-pack") then
		return
	end

	-- These branches still appear early in the tech tree because their science
	-- ingredients were compressed or inherited without also pulling in the
	-- explicit late-planet prerequisite that players read from the tree.
	for _, technology_name in ipairs({
		"kr-matter-processing",
		"slp-dyson-sphere",
		"slp-dyson-sphere-grounded",
		"ds-energy-loader-mk2",
		"ds-energy-loader-mk3",
		"muluna-fertilized-greenhouses-vulcanus",
		"foundation",
		"captive-biter-spawner",
		"planet-crucible-lithium-hydride",
		"maraxsis-nuclear-submarine"
	}) do
		add_technology_prerequisite_if_present(technology_name, "planet-crucible-science-pack")
	end
end

return late_technology_gate
