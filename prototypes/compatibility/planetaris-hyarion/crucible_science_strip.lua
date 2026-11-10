-- Hyarion's refraction chain stays a Solaris-tier step.
local helpers = require("prototypes.fixes.common.sanity_helpers")
local remove_ingredient_if_present = helpers.remove_ingredient_if_present
local remove_technology_ingredient_if_present = helpers.remove_technology_ingredient_if_present

local crucible_science_strip = {}

function crucible_science_strip.data_final_fixes()
	-- Hyarion's K2SO refraction chain is a Solaris-tier step. Crucible's
	-- broad data-updates sweep adds its science to any technology with the
	-- three inner-planet packs, which incorrectly drags this branch into
	-- Beetlejuice. Strip those late-added packs back out of the affected
	-- Hyarion techs and the K2SO research-data alias that players see.
	local hyarion_refraction_techs = {
		"planetaris-refraction-science-pack",
		"planetaris-particle-manipulation",
		"planetaris-beryllium-processing",
		"planetaris-space-facilities-1",
		"planetaris-zero-grav-accumulator",
		"planetaris-bismuth-processing",
		"planetaris-electromagnetic-radar"
	}
	local crucible_pack_aliases = {
		"planet-crucible-science-pack",
		"high-pressure-pack",
		"high-pressure-science-pack"
	}

	for _, ingredient_name_to_remove in ipairs(crucible_pack_aliases) do
		remove_ingredient_if_present("refraction-research-data", ingredient_name_to_remove)
		remove_ingredient_if_present("kr-refraction-research-data", ingredient_name_to_remove)

		for _, technology_name in ipairs(hyarion_refraction_techs) do
			remove_technology_ingredient_if_present(technology_name, ingredient_name_to_remove)
		end
	end
end

return crucible_science_strip
