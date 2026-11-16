-- The unlocks and prerequisites the players reported in the wrong order.
local helpers = require("prototypes.fixes.common.progression_helpers")
local technology = helpers.technology
local technology_exists = helpers.technology_exists
local add_prerequisite = helpers.add_prerequisite
local remove_prerequisite = helpers.remove_prerequisite
local recipe_has_ingredient = helpers.recipe_has_ingredient
local add_recipe_unlock = helpers.add_recipe_unlock
local remove_recipe_unlock = helpers.remove_recipe_unlock
local gate_recipe_to_technology = helpers.gate_recipe_to_technology

local unlock_order = {}

function unlock_order.data_final_fixes()
	gate_recipe_to_technology(
		{"kr-sand", "sand"},
		{"kr-stone-processing", "kr-crusher", "sand-processing"},
		{"sand-processing", "crusher"}
	)
	gate_recipe_to_technology(
		{"void-data-disk", "void-data-disk-black-hole"},
		{"black-hole-discovery"},
		{}
	)
	gate_recipe_to_technology(
		{"nexus-stabilization-process"},
		{"promethium-882-research", "planet-discovery-nexus", "planet-nexus-scanning"},
		{}
	)

	local military = technology("military")
	if military and recipe_has_ingredient("slowdown-capsule", "steel-plate") then
		add_prerequisite(military, "steel-processing")
	end

	local captivity = technology("captivity")
	if captivity then
		add_prerequisite(captivity, "gun-turret")
	end

	if technology_exists("carbonic-asteroid-crushing") then
		remove_recipe_unlock("steel-processing", "kr-coke-carbon")
		add_recipe_unlock("carbonic-asteroid-crushing", "kr-coke-carbon")
	end

	local radar = technology("radar")
	if radar then
		add_prerequisite(radar, "electricity")
	end

	local electricity = technology("electricity")
	if electricity then
		remove_prerequisite(electricity, "kr-fuel")
	end

	local fuel_processing = technology("kr-fuel")
	if fuel_processing then
		add_prerequisite(fuel_processing, "electricity")
	end

	local electronics = technology("electronics")
	if electronics then
		add_prerequisite(electronics, "electricity")
		add_recipe_unlock("electronics", "inserter")
		add_recipe_unlock("electronics", "long-handed-inserter")
		add_recipe_unlock("electronics", "kr-loader")
		remove_recipe_unlock("logistics", "inserter")
		remove_recipe_unlock("logistics", "long-handed-inserter")
		remove_recipe_unlock("logistics", "kr-loader")
		remove_recipe_unlock("electricity", "inserter")
	end

	local cube_jelly = technology("cube-jelly")
	if cube_jelly then
		add_prerequisite(cube_jelly, "fast-inserter")
	end

	local solaris = technology("solaris-discovery")
	if solaris then
		add_prerequisite(solaris, "metallurgic-science-pack")
		add_prerequisite(solaris, "electromagnetic-science-pack")
		add_prerequisite(solaris, "agricultural-science-pack")
	end

	for _, technology_name in ipairs({"access-to-sun-orbit"}) do
		local orbit_access = technology(technology_name)
		if orbit_access then
			add_prerequisite(orbit_access, "metallurgic-science-pack")
		end
	end

	for _, technology_name in ipairs({"aircraft-energy-shield", "lex-aircraft-energy-shields"}) do
		local aircraft_shields = technology(technology_name)
		if aircraft_shields then
			add_prerequisite(aircraft_shields, "electromagnetic-science-pack")
		end
	end
end

return unlock_order
