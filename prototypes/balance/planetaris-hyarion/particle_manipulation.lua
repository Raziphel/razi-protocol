local particle_manipulation = {}

-- 1. The particle manipulator of Hyarion has three reversible pairs without loss: 1 calcite <-> 2 quartz, 3 coal <->
--    5 stone, 2 sapphire <-> 5 sulfur. Productivity is off on them, quality is not, so running a pair back and forth
--    with quality modules raises the quality of the material for free (the recycler loses 75 % for the same). The six
--    recipes take no quality. The coal <-> carbon pair loses a third each way and keeps it.
--
-- 2. Carbon nanotubes from the chemical plant (planetaris-carbon-nanotube) became a bulk intermediate (lasers,
--    rockets, science), but the recipe takes no productivity modules while the manipulator version does. It takes
--    productivity.
local lossless = {
	"planetaris-calcite-particle-manipulation", "planetaris-raw-quartz-particle-manipulation",
	"planetaris-coal-to-stone-particle-manipulation", "planetaris-stone-to-coal-particle-manipulation",
	"planetaris-sapphire-to-sulfur-particle-manipulation", "planetaris-sulfur-to-sapphire-particle-manipulation",
}

function particle_manipulation.data_final_fixes()
	for _, name in ipairs(lossless) do
		local recipe = data.raw.recipe[name]
		if recipe and recipe.allow_quality ~= false then
			recipe.allow_quality = false
			log("razi-protocol: " .. name .. " takes no quality")
		end
	end

	local nanotube = data.raw.recipe["planetaris-carbon-nanotube"]
	if nanotube and not nanotube.allow_productivity then
		nanotube.allow_productivity = true
		log("razi-protocol: planetaris-carbon-nanotube takes productivity")
	end
end

return particle_manipulation
