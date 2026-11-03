local latent_recovery_quality = {}

-- Cubium's microcube cycle is a reversible pair that loses nothing: cube-jelly turns an energized microcube into jelly
-- and a dormant one (ignored by productivity), cubic-latent-recovery turns 50 dormant ones into 49 and an energized
-- one. Both allow quality and the cube smasher has five slots, so the pair raises the quality of the microcube for
-- free (the recycler loses 75 % for the same). The recovery takes no quality (the same rule as the Hyarion particle
-- manipulator, prototypes/balance/planetaris-hyarion/particle_manipulation.lua).
function latent_recovery_quality.data_final_fixes()
	local recipe = data.raw.recipe["cubic-latent-recovery"]

	if recipe and recipe.allow_quality ~= false then
		recipe.allow_quality = false
		log("razi-protocol: cubic-latent-recovery takes no quality")
	end
end

return latent_recovery_quality
